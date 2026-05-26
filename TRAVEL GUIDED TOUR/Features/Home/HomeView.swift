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

    /// True while the map camera is in motion. Retracts the drawer to
    /// peek and fades the recenter button while the user is panning,
    /// then clears when the camera settles.
    @State private var isMapMoving = false
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
    /// Loaded Look Around scene for the current map center, or `nil`
    /// when the center has no Look Around coverage. Probed
    /// asynchronously on every settled camera change so the Look
    /// Around button's disabled state reflects current coverage.
    @State private var lookAroundScene: MKLookAroundScene?
    /// Drives the sheet that presents `LookAroundView`. Held as a Bool
    /// so dismissing the sheet doesn't clear `lookAroundScene` (which
    /// would disable the button until the next probe completes).
    @State private var isShowingLookAround = false
    /// Most recently probed center — used to debounce probes when the
    /// camera reports many `.onEnd` events with the same center.
    @State private var lastProbedCenter: CLLocationCoordinate2D?
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            // Fallback start (NYC) — overridden on first appear if
            // the user has granted location.
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
                                isMapMoving = false
                            }
                            probeLookAround(at: region.center)
                        },
                        onCameraMoving: {
                            guard mapInteractionEnabled, !isMapMoving else { return }
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                isMapMoving = true
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
                            .padding(.horizontal, AtlasSpacing.lg)

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
                        .opacity(sheetDetent != .peek || isMapMoving ? 0 : 1)
                        .animation(.easeInOut(duration: 0.5), value: isMapMoving)
                        .animation(.easeInOut(duration: 0.3), value: sheetDetent)
                        .allowsHitTesting(sheetDetent == .peek && !isMapMoving)
                }
                .toolbar(.hidden, for: .navigationBar)
                .task {
                    try? await Task.sleep(for: .seconds(1))
                    mapInteractionEnabled = true
                }
            }
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
        case .large:  baseHeight = geo.size.height - AtlasSpacing.sm - floatingIslandHeight
        }
        return max(peekHeight, baseHeight - sharedState.sheetDragOffset)
    }

    // MARK: - Map control buttons

    /// Standard zoom span the recenter button snaps to — roughly
    /// 0.005° ≈ 555m N-S / ~420m E-W at NYC latitude, i.e. a few
    /// city blocks across.
    private static let recenterSpan = MKCoordinateSpan(
        latitudeDelta: 0.005,
        longitudeDelta: 0.005
    )

    private var mapControlStack: some View {
        VStack(spacing: AtlasSpacing.sm) {
            MapControlButton(systemImage: "binoculars.fill", isEnabled: lookAroundScene != nil) {
                guard lookAroundScene != nil else { return }
                isShowingLookAround = true
            }
            .accessibilityLabel(lookAroundScene != nil ? "Look Around" : "Look Around not available here")

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
        .sheet(isPresented: $isShowingLookAround) {
            if let scene = lookAroundScene {
                LookAroundView(scene: scene)
                    .ignoresSafeArea()
            }
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

    /// Async-probe Look Around coverage at `coordinate`. Cached on
    /// `lastProbedCenter` so quick successive `.onEnd` events with
    /// the same center don't fire a new request.
    private func probeLookAround(at coordinate: CLLocationCoordinate2D) {
        if let last = lastProbedCenter,
           abs(last.latitude - coordinate.latitude) < 1e-6,
           abs(last.longitude - coordinate.longitude) < 1e-6 {
            return
        }
        lastProbedCenter = coordinate
        Task {
            let request = MKLookAroundSceneRequest(coordinate: coordinate)
            let scene = try? await request.scene
            await MainActor.run {
                if let current = lastProbedCenter,
                   abs(current.latitude - coordinate.latitude) < 1e-6,
                   abs(current.longitude - coordinate.longitude) < 1e-6 {
                    lookAroundScene = scene
                }
            }
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
