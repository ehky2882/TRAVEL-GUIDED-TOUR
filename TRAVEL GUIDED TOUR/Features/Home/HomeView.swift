import SwiftUI
import MapKit
import CoreLocation
import UIKit

/// Map-dominant home screen — AllTrails-style.
///
/// **Layout:**
///   - `ZStack`: map fills the entire background; floating search bar
///     + filter chip row at the top; map control buttons over the
///     bottom edge.
///   - The bottom drawer (filter results / tour list) is NOT rendered
///     here — `ContentView` hosts it via a `BottomSheet` z-stacked on
///     top of the mini-player + tab bar. Shared state between the map
///     and the drawer (selected category, placecard tour, visible
///     region, drag offset) lives in `HomeSharedState`, injected via
///     `@Environment`.
struct HomeView: View {
    @Environment(DataService.self) private var dataService
    @Environment(LocationManager.self) private var locationManager
    @Environment(HomeSharedState.self) private var sharedState
    @Environment(TourPresenter.self) private var tourPresenter

    /// Drawer detent — owned by `ContentView` so it persists across
    /// tab switches and so the drawer (also at `ContentView`) and the
    /// map controls below can read it from the same source.
    @Binding var sheetDetent: BottomSheetDetent

    /// True when Home is the active tab. `ContentView` keeps `HomeView`
    /// mounted across tab switches (so the map isn't rebuilt on return)
    /// and passes `false` here while Home is hidden. Used to short-circuit
    /// camera-change side-effects so a late map settle frame — e.g. a
    /// recenter animation that finishes just after the user tabs to
    /// Library — can't retract the drawer or mutate shared map state while
    /// Home is off-screen. (Gestures are already blocked upstream via
    /// `allowsHitTesting(false)`; this covers programmatic camera flights.)
    let isActive: Bool

    /// Guards against the map firing camera events during initial
    /// render. Set to true 1 s after the view appears — enough time
    /// for the map's first tile load / settle cycle to complete so
    /// those events don't retract the drawer before the user touches
    /// anything. onEnd-based approach was unreliable because onEnd
    /// fires immediately on first render, making the guard useless.
    @State private var mapInteractionEnabled = false
    /// Active map type. Cycled / picked by the map-mode selector
    /// button. Standard is the default — same as Apple Maps.
    @State private var mapMode: MapMode = .standard
    /// True once the first non-nil `userLocation` reading has been
    /// used to recenter the camera. Guards against re-snapping the
    /// camera to the user after they've panned away — only the very
    /// first location reading triggers a recenter.
    @State private var didCenterOnUser = false
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            // Fallback when location permission is denied or no
            // reading has arrived yet. The first non-nil userLocation
            // reading replaces this via `centerOnUserIfNeeded`.
            center: CLLocationCoordinate2D(latitude: 40.7484, longitude: -73.9857),
            span: MKCoordinateSpan(latitudeDelta: 0.18, longitudeDelta: 0.18)
        )
    )
    /// Shows the "No Atlas tours here yet" hint after a place search
    /// flies the camera to an area with no tour pins. Cleared by a map
    /// tap or after a fixed timeout.
    @State private var showNoToursOverlay = false
    /// Bumped each time the hint is shown so a stale auto-dismiss timer
    /// from an earlier fly-to can't hide a newer hint.
    @State private var showOverlayToken = 0
    /// Set when a place-search fly-to is in flight; consumed once the
    /// camera settles so the no-tours check runs against the region the
    /// user actually landed on (not the mid-animation frames).
    @State private var pendingArrivalRegion: MKCoordinateRegion? = nil

    /// Peek-detent height. Sized to fit the drag handle (~16pt) + the
    /// centered header line (~30pt) with some breathing room — and
    /// nothing more. Must match `HomeDrawerContent.peekHeight`.
    private let peekHeight: CGFloat = 80

    /// Exact pixel height of the mini-player + tab bar stack at the
    /// bottom of the screen. Fed to the map control button stack's
    /// bottom offset so the buttons sit a fixed distance above the
    /// drawer's top edge in every detent.
    private var floatingIslandHeight: CGFloat {
        AtlasBottomModule.height(extendsToScreenEdges: false)
    }

    /// Isolated holder for the map's live camera, written from the map
    /// section's `onCameraInfoChanged` callback. Lives in its own
    /// `@Observable` so the ~60/sec updates during a rotate gesture
    /// re-render ONLY the leaf `MapCompassButton` (the sole reader of
    /// `.heading`), never `HomeView`'s body. `HomeView` writes to it
    /// but never reads it, so the per-frame writes don't invalidate
    /// this view.
    @State private var compassModel = MapCompassModel()

    var body: some View {
        // NavigationStack wraps the map layout so SearchBar's push
        // to `SearchView` still works. Tour detail no longer pushes
        // here — it comes up via `TourPresenter` as a sheet at the
        // `ContentView` level. The nav bar is hidden; the floating
        // search bar + filter chips replace it.
        @Bindable var sharedState = sharedState
        return NavigationStack {
            GeometryReader { geo in
                ZStack(alignment: .top) {
                    HomeMapSection(
                        tours: filteredTours,
                        userLocation: locationManager.userLocation,
                        userHeading: locationManager.heading,
                        selectedTourId: sharedState.placecardTour?.id,
                        cameraPosition: $cameraPosition,
                        mapMode: mapMode,
                        onCameraChanged: { region in
                            guard isActive else { return }
                            sharedState.visibleRegion = region
                            withAnimation(.easeInOut(duration: 0.3)) {
                                sharedState.isMapMoving = false
                            }
                            evaluatePlaceArrival(settledRegion: region)
                        },
                        onCameraMoving: {
                            guard isActive, mapInteractionEnabled, !sharedState.isMapMoving else { return }
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                sharedState.isMapMoving = true
                                if sheetDetent != .peek {
                                    sheetDetent = .peek
                                }
                            }
                        },
                        onCameraInfoChanged: { camera in
                            // Write-only into the isolated model — does
                            // NOT invalidate HomeView (it never reads
                            // the model). Only `MapCompassButton`
                            // re-renders, per frame, off `.heading`.
                            compassModel.camera = camera
                        },
                        onPinTapped: { tourId, coordinate in
                            guard let tour = dataService.tour(by: tourId) else { return }
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                sharedState.placecardTour = tour
                                sharedState.placecardCoordinate = coordinate
                            }
                            // Recenter the map on the tapped pin's
                            // coordinate so the pin (and the
                            // placecard that rises above it) sit at
                            // the screen's geometric center. Preserve
                            // the current zoom span so the action
                            // reads as a pan, not a zoom.
                            let span = sharedState.visibleRegion?.span
                                ?? Self.recenterSpan
                            withAnimation(.easeInOut(duration: 0.35)) {
                                cameraPosition = .region(MKCoordinateRegion(
                                    center: coordinate,
                                    span: span
                                ))
                            }
                        },
                        onMapTapped: {
                            if showNoToursOverlay {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showNoToursOverlay = false
                                }
                            }
                            guard sharedState.placecardTour != nil else { return }
                            withAnimation(.easeInOut(duration: 0.2)) {
                                sharedState.placecardTour = nil
                                sharedState.placecardCoordinate = nil
                            }
                        },
                        placecard: placecardAnchor
                    )
                    .ignoresSafeArea()

                    VStack(spacing: AtlasSpacing.sm) {
                        SearchBar()
                            .padding(.horizontal, AtlasSpacing.md)
                            // Retract the drawer to `.peek` when the
                            // user opens search from `.medium` or
                            // `.large` — without this the SearchView
                            // pushes on top of a fully-expanded drawer
                            // and the user has to swipe down again
                            // to get the map back when they pop
                            // (owner request, 2026-06-04).
                            // `.simultaneousGesture` runs alongside
                            // the NavigationLink's tap so the push
                            // still fires.
                            .simultaneousGesture(
                                TapGesture().onEnded {
                                    guard sheetDetent != .peek else { return }
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        sheetDetent = .peek
                                    }
                                }
                            )

                        TagFilterChipRow(
                            selectedTags: $sharedState.selectedTags,
                            walksOnly: $sharedState.walksOnly
                        )
                    }
                    .padding(.top, AtlasSpacing.sm)

                    // Map-control button stack anchored to bottom-leading,
                    // padded up by the drawer's *current* visible height
                    // (read off `sharedState.sheetDragOffset` so it stays
                    // glued during the drag, not just after release).
                    mapControlStack
                        .padding(.leading, AtlasSpacing.md)
                        .padding(.bottom, drawerVisibleHeight(in: geo) + floatingIslandHeight + AtlasSpacing.sm)
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: .bottomLeading
                        )
                        // Match the drawer's coordinate space — the
                        // drawer ignores the bottom safe area, so the
                        // button stack must too or the padding math is
                        // off by the home-indicator inset.
                        .ignoresSafeArea(.container, edges: .bottom)
                        // Fade out as the drawer rises off peek (not a
                        // binary flip) so the buttons start dissolving
                        // the instant the drawer moves — tracking the
                        // drag 1:1, fully gone by the medium detent.
                        // Also hidden while the map is moving (clean
                        // panning UX); fades back when the camera
                        // settles. Interactive only at peek.
                        .opacity(mapControlsOpacity(in: geo))
                        .animation(.easeInOut(duration: 0.4), value: sharedState.isMapMoving)
                        .allowsHitTesting(sheetDetent == .peek && !sharedState.isMapMoving)

                    // Compass — trailing edge, bottom-aligned with the
                    // recenter button (same bottom-padding formula as
                    // the control stack). The button manages its own
                    // appear-when-rotated visibility and live needle
                    // rotation off the isolated `compassModel`, so this
                    // positioning wrapper does NOT read the heading and
                    // therefore doesn't re-render per frame. Unlike the
                    // control stack it stays visible while the map is
                    // moving — rotation happens mid-gesture, which is
                    // exactly when the compass is needed.
                    MapCompassButton(
                        model: compassModel,
                        isAtPeek: sheetDetent == .peek,
                        onTap: resetMapToNorth
                    )
                        .padding(.trailing, AtlasSpacing.md)
                        .padding(.bottom, drawerVisibleHeight(in: geo) + floatingIslandHeight + AtlasSpacing.sm)
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: .bottomTrailing
                        )
                        .ignoresSafeArea(.container, edges: .bottom)

                    // Transient hint shown when a place search lands on
                    // an area with no Atlas tours. Non-interactive so a
                    // tap underneath still dismisses it. The pill is
                    // padded down from the top and placed in a top-
                    // aligned full-size frame; the transition is a plain
                    // opacity fade (a `.move` here would slide the
                    // full-height frame off-screen).
                }
                // Place-search "no tours here" hint. Attached as an
                // `.overlay` (not a ZStack child) so it composites above
                // the UIKit-backed `Map` — a conditionally-inserted
                // ZStack *sibling* of the map did not paint at all.
                // Non-interactive so a tap underneath dismisses it.
                // NOTE: in the iOS *simulator* the pill can appear a few
                // seconds late on the first fly to a far, uncached region
                // — MKMapView's tile streaming starves SwiftUI layer
                // compositing there. On device (Metal compositor) it
                // shows promptly; verify on a real device / TestFlight.
                .overlay(alignment: .top) {
                    if showNoToursOverlay {
                        noToursOverlay
                            .padding(.top, geo.size.height * 0.16)
                            .allowsHitTesting(false)
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
                .task {
                    try? await Task.sleep(for: .seconds(1))
                    mapInteractionEnabled = true
                }
                // First non-nil reading after launch recenters the
                // camera on the user (item #1). After that the user
                // owns the camera — pan, zoom, and the recenter
                // button take over.
                .onAppear { centerOnUserIfNeeded() }
                .onChange(of: locationManager.userLocation) { _, _ in
                    centerOnUserIfNeeded()
                }
                // A place tapped in SearchView arrives here as a
                // one-shot request: fly the camera there.
                .onChange(of: sharedState.pendingMapMove) { _, move in
                    guard let move else { return }
                    flyTo(move.region)
                }
            }
        }
    }

    /// Recenter the camera on the user's current location, but only
    /// once per launch — subsequent location updates don't snatch the
    /// camera back from the user's pans.
    private func centerOnUserIfNeeded() {
        guard !didCenterOnUser,
              let user = locationManager.userLocation else { return }
        didCenterOnUser = true
        let region = MKCoordinateRegion(
            center: user.coordinate,
            span: Self.initialUserSpan
        )
        withAnimation(.easeInOut(duration: 0.6)) {
            cameraPosition = .region(region)
        }
    }

    /// Glide the camera to a region requested by a place search. Clears
    /// the one-shot request, retracts the drawer + any open placecard so
    /// the destination isn't hidden, and arms the no-tours check for
    /// when the camera settles. Doesn't touch the recenter / pin-tap /
    /// startup paths — it's a parallel, additive camera driver.
    private func flyTo(_ region: MKCoordinateRegion) {
        sharedState.pendingMapMove = nil
        showNoToursOverlay = false
        sharedState.placecardTour = nil
        sharedState.placecardCoordinate = nil
        if sheetDetent != .peek {
            withAnimation(.easeInOut(duration: 0.25)) { sheetDetent = .peek }
        }
        pendingArrivalRegion = region
        withAnimation(.easeInOut(duration: 0.6)) {
            cameraPosition = .region(region)
        }
    }

    /// When the camera settles after a place-search fly-to, show the
    /// "No Atlas tours here yet" hint if the destination has no tour
    /// pins in view. Guarded by `pendingArrivalRegion` so it fires once
    /// per fly-to and never on ordinary pans. Uses the actual settled
    /// region so the check matches what the user sees.
    private func evaluatePlaceArrival(settledRegion: MKCoordinateRegion) {
        guard pendingArrivalRegion != nil else { return }
        pendingArrivalRegion = nil
        guard !MapRegionGeometry.anyStop(of: dataService.tours, inside: settledRegion) else { return }
        showOverlayToken += 1
        let token = showOverlayToken
        // Shown without an insertion animation — a fade transition is
        // starved by the map's continuous render transactions while the
        // destination's tiles stream in.
        showNoToursOverlay = true
        // Fixed-duration hint. We deliberately DON'T dismiss on camera
        // movement: a streaming vector map keeps emitting settle frames
        // for seconds after a fly-to, which would clear the hint almost
        // immediately. A tap on the map dismisses it early (onMapTapped);
        // otherwise it fades after the timeout. The token guards against
        // a stale timer from an earlier fly-to hiding a newer hint.
        Task {
            try? await Task.sleep(for: .seconds(6))
            if showNoToursOverlay, token == showOverlayToken {
                showNoToursOverlay = false
            }
        }
    }

    /// Pill shown over the map when a place search lands somewhere with
    /// no Atlas tours. Same `secondaryBackground` chrome as the rest of
    /// the floating UI; caption typography.
    private var noToursOverlay: some View {
        HStack(spacing: AtlasSpacing.sm) {
            Image(systemName: "mappin.slash")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.secondaryText)

            VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                Text("No Dozents here yet")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.primaryText)
                Text("Check back soon — we're always adding new places.")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
            }
        }
        .padding(.horizontal, AtlasSpacing.md)
        .padding(.vertical, AtlasSpacing.sm)
        .background(AtlasColors.secondaryBackground, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
        .padding(.horizontal, AtlasSpacing.lg)
    }

    /// Bundles the current placecard tour + its anchor coordinate into
    /// the value `HomeMapSection` consumes. Erased to `AnyView` to
    /// keep the map section unaware of the concrete placecard type.
    private var placecardAnchor: PlacecardAnchor? {
        guard let tour = sharedState.placecardTour,
              let coordinate = sharedState.placecardCoordinate else {
            return nil
        }
        // Standardize the placecard at 2/3 of the device's screen
        // width so the card reads as the same visual proportion of
        // the map across every iPhone size. Falls back to a sensible
        // fixed width if no window scene is available (test / preview
        // contexts). Wider would feel more like an overlay sheet;
        // narrower would cramp the 64pt hero next to the 2-line
        // ALL CAPS title.
        let card = PlacecardView(
            tour: tour,
            maker: dataService.maker(for: tour),
            distanceText: distanceText(for: tour),
            onTap: {
                tourPresenter.present(tour)
            }
        )
        .frame(width: Self.placecardWidth)
        return PlacecardAnchor(coordinate: coordinate, view: AnyView(card))
    }

    /// Opacity for the floating map controls (map-mode + recenter),
    /// faded against the drawer's rise off peek so they dissolve as
    /// the drawer moves rather than flipping off at the first detent
    /// boundary. 1 at peek, linearly → 0 by the medium height; 0 while
    /// the map is panning. Reads `drawerVisibleHeight`, which folds in
    /// the live `sheetDragOffset`, so the fade tracks the finger and
    /// the release-snap animates it (the snap mutates offset/detent
    /// inside BottomSheet's `withAnimation`).
    private func mapControlsOpacity(in geo: GeometryProxy) -> CGFloat {
        if sharedState.isMapMoving { return 0 }
        let visible = drawerVisibleHeight(in: geo)
        let mediumBase = geo.size.height * 0.5
        let progress = min(1, max(0, (visible - peekHeight) / max(1, mediumBase - peekHeight)))
        return 1 - progress
    }

    /// Mirrors the height formula `BottomSheet` and `HomeDrawerContent`
    /// use so the map control buttons can sit at a fixed offset above
    /// the drawer's top edge — including DURING the drag.
    private func drawerVisibleHeight(in geo: GeometryProxy) -> CGFloat {
        let baseHeight: CGFloat
        switch sheetDetent {
        case .peek:   baseHeight = peekHeight
        case .medium: baseHeight = geo.size.height * 0.5
        case .large:
            // Mirrors BottomSheet.heightForDetent(.large) — subtract
            // the search/chips block + small buffer (matching
            // ContentView's topReservedHeight) so the map controls
            // don't think the drawer is taller than it actually is.
            // Safe-area top is NOT added — see the matching note in
            // BottomSheet.heightForDetent for why.
            let topGap = AtlasSpacing.searchAndChipsBlockHeight + AtlasSpacing.sm
            baseHeight = geo.size.height - topGap - floatingIslandHeight
        }
        return max(peekHeight, baseHeight - sharedState.sheetDragOffset)
    }

    // MARK: - Map control buttons

    /// Standard zoom span the recenter button snaps to — roughly
    /// 0.02° ≈ 2.2 km N-S / ~1.7 km E-W at NYC latitude, i.e. a
    /// neighborhood-scale view that puts the user dot plus several
    /// surrounding blocks (and any nearby tour pins) in frame. The
    /// previous tighter 0.005° zoom dropped the user onto a few-
    /// block view that hid most pins on real-device review.
    private static let recenterSpan = MKCoordinateSpan(
        latitudeDelta: 0.02,
        longitudeDelta: 0.02
    )

    /// Wider zoom span used on first appear only, so the user sees
    /// nearby tours across multiple neighborhoods instead of being
    /// dropped at a few-block zoom that hides most pins. ~0.1° is
    /// roughly 11 km N-S / ~8.5 km E-W at NYC latitude — about the
    /// full length of Manhattan island.
    private static let initialUserSpan = MKCoordinateSpan(
        latitudeDelta: 0.1,
        longitudeDelta: 0.1
    )

    /// Standardized placecard width — 2/3 of the active scene's screen
    /// width so the card reads as the same visual proportion of the
    /// map across every iPhone size. Falls back to a sensible fixed
    /// width if there's no active window scene (test / preview
    /// contexts).
    private static var placecardWidth: CGFloat {
        let screenWidth = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })?
            .screen.bounds.width
        return (screenWidth ?? 390) * 2.0 / 3.0
    }

    /// Snap the map back to true north. Builds an explicit north-up
    /// `MapCamera` from the current centre + distance (captured live
    /// in `compassModel.camera`) rather than re-setting `.region(_:)`.
    /// A `.region` reset can be silently ignored — `MapCameraPosition`
    /// comparison treats it as unchanged because a region doesn't
    /// carry heading, so SwiftUI never pushes the rotation back to 0.
    /// A `.camera` with heading 0 differs from the current (rotated)
    /// camera, so the update actually lands.
    private func resetMapToNorth() {
        guard let current = compassModel.camera else { return }
        let northUp = MapCamera(
            centerCoordinate: current.centerCoordinate,
            distance: current.distance,
            heading: 0,
            pitch: 0
        )
        withAnimation(.easeInOut(duration: 0.4)) {
            cameraPosition = .camera(northUp)
        }
    }

    private var mapControlStack: some View {
        VStack(spacing: AtlasSpacing.sm) {
            Menu {
                Picker("Map type", selection: $mapMode) {
                    ForEach(MapMode.allCases) { mode in
                        Label(mode.title, systemImage: mode.iconName).tag(mode)
                    }
                }
            } label: {
                MapControlButtonLabel(systemImage: mapMode.iconName)
            }
            .accessibilityLabel("Map type — \(mapMode.title)")

            MapControlButton(systemImage: "location.fill") {
                recenterOnUser()
            }
            .accessibilityLabel("Recenter on my location")
        }
    }

    /// Single-action recenter: snap the camera to the user's current
    /// location at the standard zoom, 2D, North-up. `.region(...)`
    /// sets a non-tilted, north-aligned camera by default.
    private func recenterOnUser() {
        guard let user = locationManager.userLocation else { return }
        let region = MKCoordinateRegion(
            center: user.coordinate,
            span: Self.recenterSpan
        )
        withAnimation(.easeInOut(duration: 0.8)) {
            cameraPosition = .region(region)
        }
    }

    // MARK: - Derived

    /// Tours after the filter-chip selection is applied. Fed to the
    /// map's pin set. The drawer's filtered results list is computed in
    /// `HomeDrawerContent` from the same `sharedState` filter state.
    /// Combines per D6 (OR within a facet, AND across) plus the "Walks"
    /// format filter (§1.6).
    private var filteredTours: [Tour] {
        guard sharedState.hasActiveFilters else { return dataService.tours }
        return dataService.tours.filter { tour in
            if sharedState.walksOnly && tour.kind != .multiStop { return false }
            return Tag.matches(tourTags: Set(tour.tags), selection: sharedState.selectedTags)
        }
    }

    private func distanceText(for tour: Tour) -> String? {
        guard let user = locationManager.userLocation else { return nil }
        return AtlasFormatters.distanceAway(meters: tour.distance(from: user))
    }
}

// MARK: - Compass

/// Isolated holder for the map's live camera. Separated into its own
/// `@Observable` so the leaf `MapCompassButton` (the only view that
/// reads `heading`) is the only thing SwiftUI invalidates when the
/// camera changes ~60×/sec during a rotate gesture. The host
/// `HomeView` writes to it but never reads it, so the per-frame
/// writes don't ripple into a full `HomeView` body re-evaluation.
@MainActor
@Observable
final class MapCompassModel {
    /// Latest camera reported by the map. `nil` until the first
    /// camera-change frame fires.
    var camera: MapCamera?

    /// Camera heading in degrees clockwise from true north (0 when no
    /// camera yet).
    var heading: CLLocationDirection { camera?.heading ?? 0 }
}

/// Two-tone compass needle: a red half pointing north over a grey
/// half pointing south, the pair rotated by `-heading` so the red
/// always points to true north as the map turns underneath. Drawn
/// with a `Triangle` so it reads as a proper compass needle rather
/// than a generic arrow glyph.
private struct CompassNeedle: View {
    var body: some View {
        VStack(spacing: 0) {
            Triangle()
                .fill(Color.red)
                .frame(width: 7, height: 9)
            Triangle()
                .fill(AtlasColors.tertiaryText)
                .rotationEffect(.degrees(180))
                .frame(width: 7, height: 9)
        }
    }
}

/// A simple upward-pointing triangle (apex at top-centre, base at
/// the bottom).
private struct Triangle: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// Circular compass button matching `MapControlButtonLabel`'s style,
/// placed by `HomeView` on the trailing edge opposite the recenter
/// button. Shows only while the map is rotated off true north; the
/// red needle counter-rotates so it always points north. Tapping it
/// snaps the camera back to north.
///
/// Replaces Apple's `MapCompass(scope:)`, whose external-placement
/// scope binding renders a zero-size view on iOS 26 (verified — even
/// forced visible with `.mapControlVisibility(.visible)` it never
/// paints, so the framework's only working compass slot is the fixed
/// top-trailing one, under the search bar + chips).
private struct MapCompassButton: View {
    let model: MapCompassModel
    /// Drawer is at peek — the compass is only interactive then, to
    /// match the recenter button's gating (at medium / large the
    /// drawer covers the controls strip).
    let isAtPeek: Bool
    let onTap: () -> Void

    /// Heading magnitude (degrees) below which the map counts as "at
    /// north" and the compass hides. A small dead zone keeps it from
    /// flickering as the camera settles onto exactly 0.
    private static let deadZoneDegrees: Double = 1.0

    /// True when the map is rotated far enough off north to warrant
    /// showing the compass. Sign-agnostic so 1° and 359° both count.
    private var isOffNorth: Bool {
        let m = abs(model.heading.truncatingRemainder(dividingBy: 360))
        return min(m, 360 - m) >= Self.deadZoneDegrees
    }

    var body: some View {
        Button(action: onTap) {
            CompassNeedle()
                // Counter-rotate by the heading so the red half tracks
                // true north live as the map turns. No animation here —
                // a 1:1 mirror of the camera reads as "reacting to the
                // rotation" rather than lagging behind it.
                .rotationEffect(.degrees(-model.heading))
                .frame(width: 44, height: 44)
                .background(AtlasColors.secondaryBackground)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.12), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Compass — reset to north")
        .opacity(isOffNorth ? 1 : 0)
        .animation(.easeInOut(duration: 0.3), value: isOffNorth)
        .allowsHitTesting(isOffNorth && isAtPeek)
    }
}

/// The three Apple-Maps map types Atlas exposes via the map-mode
/// selector. `iconName` is the SF Symbol shown on the selector button
/// when this mode is active.
enum MapMode: String, CaseIterable, Identifiable {
    case standard, hybrid, imagery

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standard: return "Standard"
        case .hybrid:   return "Hybrid"
        case .imagery:  return "Satellite"
        }
    }

    var iconName: String {
        switch self {
        case .standard: return "map"
        case .hybrid:   return "map.fill"
        case .imagery:  return "globe.americas.fill"
        }
    }
}
