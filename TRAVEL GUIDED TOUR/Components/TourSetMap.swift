import CoreLocation
import MapKit
import SwiftUI

/// A set of tours on a map, with everything that has to come with it.
///
/// Lifted out of `MakerView` on 2026-08-19, when the list page needed the same
/// thing. It is not just the map: it is the map **plus** the camera, the
/// "Show all" re-frame, and the stacked place cards a pin needs when zooming
/// can't split it. That last part is 140 lines and five pieces of state, and
/// copying it would have been the third hand-maintained copy of a map idiom in
/// this app — the mistake `MapPins` and `MapClustering` were extracted to stop.
///
/// 🔴 **The stacked cards are load-bearing, not polish.** Markers are bucketed
/// by grid cell, so two tours on an *identical* coordinate share a cell at
/// every zoom: `zoomIn` on that pin is an infinite no-op and the tap is simply
/// swallowed — no card, no error, nothing in a log. That shipped once, on 24
/// pins, and was invisible to every check we run (see CLAUDE.md, session 93).
/// Any surface plotting a set of tours inherits it, which is why this component
/// exists rather than a bare map.
///
/// The caller supplies the horizontal inset — the gutters either side are where
/// a drag scrolls the page instead of panning the map.
struct TourSetMap: View {
    let tours: [Tour]
    /// Sites whose tours collapse into one pin. Pass `dataService.places` so
    /// this map draws what the home map draws for the same catalog.
    let places: [Place]
    /// The maker to name on a tour's place card. A maker page passes its own;
    /// a list holds tours by several people, so it looks each one up.
    let makerForTour: (Tour) -> Maker?
    /// Where to open when there is nothing to plot. A maker with no tours yet
    /// gets the world; a caller may prefer somewhere else.
    var emptyRegion: MKCoordinateRegion = MakerMapSection.worldRegion
    /// Header text for a given tour count. Stated above the map, with the
    /// re-frame control opposite.
    var countLabel: (Int) -> String = { count in
        switch count {
        case 0: return "No tours on the map yet"
        case 1: return "1 tour on the map"
        default: return "\(count) tours on the map"
        }
    }
    let onOpenTour: (UUID) -> Void
    let onOpenPlace: (Place) -> Void

    @Environment(LocationManager.self) private var locationManager
    /// Optional so a preview — which wires no layers — still renders. Nil hides
    /// the expand control rather than drawing one that cannot act.
    @Environment(MapExpander.self) private var mapExpander: MapExpander?

    /// Framed once to fit the whole set, then left alone so a pan survives a
    /// tab switch.
    @State private var camera: MapCameraPosition = .automatic
    @State private var selectedTourId: UUID?
    /// Tours behind a tapped pin that zooming can't split, plus where it sits.
    /// A list because such a pin stands for more than one tour. Empty means no
    /// card is showing.
    @State private var placecardTours: [Tour] = []
    @State private var placecardCoordinate: CLLocationCoordinate2D?
    /// The span the map was at when the stack opened, so dismissing and
    /// re-tapping doesn't creep the zoom.
    @State private var spanBeforePlacecard: MKCoordinateSpan?

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            HStack(spacing: AtlasSpacing.md) {
                Text(countLabel(tours.count))
                    .font(AtlasTypography.caption)
                    .textCase(.uppercase)
                    .foregroundStyle(AtlasColors.tertiaryText)
                Spacer()
                // Re-frame after panning away. Borrowed from tour detail, where
                // GET DIRECTIONS sits in this same slot.
                if !tours.isEmpty {
                    Button("Show all") { frameWholeMap() }
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.mapPin)
                }
            }
            .padding(.top, AtlasSpacing.md)

            // Rendered even with nothing to plot: a real map reads as "nothing
            // here yet" far better than a grey box does, and it is the same map
            // that appears once there is something on it.
            MakerMapSection(
                tours: tours,
                places: places,
                userLocation: locationManager.userLocation,
                selectedTourId: selectedTourId,
                cameraPosition: $camera,
                // The map frames itself on first appear — it has to set the
                // camera and its clustering region in the same breath, so it
                // owns both.
                initialRegion: initialRegion,
                onPinTapped: { tourId, _ in
                    dismissPlacecard()
                    selectedTourId = tourId
                    onOpenTour(tourId)
                },
                onPlaceTapped: { placeId, _ in
                    guard let place = places.first(where: { $0.id == placeId }) else { return }
                    dismissPlacecard()
                    selectedTourId = nil
                    onOpenPlace(place)
                },
                onClusterTapped: { tourIds, coordinate in
                    showPlacecards(for: tourIds, at: coordinate)
                },
                onMapTapped: {
                    selectedTourId = nil
                    dismissPlacecard()
                },
                placecard: placecardAnchor
            )
            .atlasHeroSizing(nil)
            // Take the whole set to the Home map.
            //
            // ⚠️ NO CARD, and that is the owner's call (2026-08-30). A creator
            // page or a list holds many tours across many cities and has no
            // single subject — raising one tour's card would single it out for
            // no reason. What you get is the picture `SHOW ALL` gives, on the
            // map you can browse on from. Hidden when there is nothing to
            // frame, so an empty creator page shows no control at all.
            .atlasMapExpandControl(isVisible: canExpand) {
                mapExpander?.expand(framing: tours)
            }
        }
    }

    /// Whether expanding can do anything: something to frame, something wired
    /// to frame it with, and nothing already using the top-trailing corner.
    ///
    /// ⚠️ The placecard clause is why this is not just a nil check. A stack
    /// anchored to a pin at `pinFraction` grows *upwards*, so it lands in the
    /// corner the expand control occupies — and while a card is up, expanding
    /// is not what the reader is doing anyway.
    private var canExpand: Bool {
        mapExpander != nil
            && placecardTours.isEmpty
            && MapExpander.regionFraming(tours) != nil
    }

    private var initialRegion: MKCoordinateRegion {
        tours.isEmpty ? emptyRegion : MakerMapSection.initialRegion(for: tours)
    }

    /// Frame the whole set. Tours across continents give a world view, which is
    /// the honest picture of them.
    private func frameWholeMap() {
        // An open stack is anchored to one pin at one zoom; re-framing the
        // whole map would leave it floating over unrelated ground.
        dismissPlacecard()
        withAnimation(.easeInOut(duration: 0.35)) { camera = .region(initialRegion) }
    }

    // MARK: - Doubled-up pins

    /// One place card per tour behind a pin zooming can't split — a walk
    /// starting at a landmark that also has its own single-stop tour puts two
    /// tours on one coordinate. Owner direction 2026-08-17: match the home
    /// map's treatment rather than inventing a second idiom.
    private func showPlacecards(for tourIds: [UUID], at coordinate: CLLocationCoordinate2D) {
        var seen = Set<UUID>()
        let hits = tourIds
            .compactMap { id in tours.first { $0.id == id } }
            .filter { seen.insert($0.id).inserted }
        guard !hits.isEmpty else { return }

        selectedTourId = nil
        let span = spanBeforePlacecard ?? camera.region?.span ?? Self.fallbackSpan
        spanBeforePlacecard = span

        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            placecardTours = hits
            placecardCoordinate = coordinate
        }
        // Sit the pin low in the frame rather than dead centre. This map is
        // only hero-sized and a stack of cards is most of it, so a plain
        // recentre would push the top card off the map.
        withAnimation(.easeInOut(duration: 0.35)) {
            camera = .region(
                MapClustering.region(anchoring: coordinate, at: Self.pinFraction, span: span)
            )
        }
    }

    private func dismissPlacecard() {
        guard !placecardTours.isEmpty else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            placecardTours = []
            placecardCoordinate = nil
        }
        spanBeforePlacecard = nil
    }

    /// The stack rendered above the tapped pin. Same component and width as the
    /// home map, so the two read as one system.
    private var placecardAnchor: PlacecardAnchor? {
        guard !placecardTours.isEmpty, let coordinate = placecardCoordinate else { return nil }

        let shown = Array(placecardTours.prefix(Self.maxStacked))
        let stack = VStack(spacing: AtlasSpacing.xs) {
            ForEach(shown) { tour in
                PlacecardView(
                    tour: tour,
                    maker: makerForTour(tour),
                    distanceText: distanceText(for: tour),
                    onTap: {
                        dismissPlacecard()
                        selectedTourId = tour.id
                        onOpenTour(tour.id)
                    }
                )
            }
        }
        .frame(width: PlacecardView.standardWidth)
        return PlacecardAnchor(coordinate: coordinate, view: AnyView(stack))
    }

    private func distanceText(for tour: Tour) -> String? {
        guard let location = locationManager.userLocation else { return nil }
        return AtlasFormatters.distanceAway(meters: tour.distance(from: location))
    }

    /// How far down the map the tapped pin sits while its stack is open. Two
    /// cards plus their gap and the pin clearance come to roughly 178pt; at
    /// 0.72 of a hero-sized map there is room above the pin for the stack on
    /// the smallest iPhone.
    private static let pinFraction: Double = 0.72

    /// Used only if the camera somehow has no region yet — roughly
    /// neighbourhood level, matching the cluster-framing floor.
    private static let fallbackSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)

    /// Cap on the stack so it can't outgrow the map. The deepest coincident
    /// group in the catalog is two; more than three on a map this size would
    /// need a different answer altogether.
    private static let maxStacked = 3
}
