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
                            sharedState.visibleRegion = region
                            withAnimation(.easeInOut(duration: 0.3)) {
                                sharedState.isMapMoving = false
                            }
                        },
                        onCameraMoving: {
                            guard mapInteractionEnabled, !sharedState.isMapMoving else { return }
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                sharedState.isMapMoving = true
                                if sheetDetent != .peek {
                                    sheetDetent = .peek
                                }
                            }
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

                        CategoryChipRow(
                            availableCategories: TourCategory.allCases,
                            selectedCategory: $sharedState.selectedCategory
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
                        // Visible only at peek. At medium / large the
                        // drawer covers enough of the map that the
                        // controls would crowd it. Also hidden while
                        // the map is moving (clean panning UX); fades
                        // back when the camera settles.
                        .opacity(sheetDetent != .peek || sharedState.isMapMoving ? 0 : 1)
                        .animation(.easeInOut(duration: 0.5), value: sharedState.isMapMoving)
                        .animation(.easeInOut(duration: 0.3), value: sheetDetent)
                        .allowsHitTesting(sheetDetent == .peek && !sharedState.isMapMoving)
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

    /// Bundles the current placecard tour + its anchor coordinate into
    /// the value `HomeMapSection` consumes. Erased to `AnyView` to
    /// keep the map section unaware of the concrete placecard type.
    private var placecardAnchor: PlacecardAnchor? {
        guard let tour = sharedState.placecardTour,
              let coordinate = sharedState.placecardCoordinate else {
            return nil
        }
        let card = PlacecardView(
            tour: tour,
            maker: dataService.maker(for: tour),
            distanceText: distanceText(for: tour),
            onTap: {
                tourPresenter.present(tour)
            }
        )
        return PlacecardAnchor(coordinate: coordinate, view: AnyView(card))
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

    /// Tours after the category-chip filter is applied. Fed to the
    /// map's pin set. The drawer's filtered list is computed in
    /// `HomeDrawerContent` from the same `sharedState.selectedCategory`.
    private var filteredTours: [Tour] {
        guard let selectedCategory = sharedState.selectedCategory else {
            return dataService.tours
        }
        return dataService.tours.filter { $0.primaryCategory == selectedCategory }
    }

    private func distanceText(for tour: Tour) -> String? {
        guard let user = locationManager.userLocation else { return nil }
        return AtlasFormatters.distanceAway(meters: tour.distance(from: user))
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
