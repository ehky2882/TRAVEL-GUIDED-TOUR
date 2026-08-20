import Foundation
import MapKit
import CoreLocation
import Observation

/// A single autocomplete suggestion for a place — lightweight: just the
/// title/subtitle strings MapKit's completer streams as the user types,
/// plus the underlying `MKLocalSearchCompletion` so a tap can resolve it
/// to a coordinate later. No region here on purpose — resolving the
/// coordinate is the expensive step and is deferred until selection.
struct PlaceSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let completion: MKLocalSearchCompletion
}

/// A resolved place — everything a caller might need after a tap: where it
/// is, how far out to frame it, and what it's called. The Search tab only
/// wants the region; the create wizard also needs the locality, to fill in
/// the tour's city without asking the maker to type it twice.
struct ResolvedPlace {
    let coordinate: CLLocationCoordinate2D
    let region: MKCoordinateRegion
    /// The place's own name, when it has one distinct from the address.
    let name: String?
    /// Town or city.
    let locality: String?
    let country: String?
}

/// Search-as-you-type place lookup backed by `MKLocalSearchCompleter`.
///
/// **Why the completer instead of `MKLocalSearch` per keystroke:** the
/// completer is Apple's purpose-built autocompletion engine — it streams
/// cheap title/subtitle suggestions almost instantly as the query
/// fragment changes, rather than running a full local-search network
/// round-trip on every character (which commonly takes 0.5–1.5s and was
/// the source of the typing lag). The expensive `MKLocalSearch` resolve,
/// which yields the actual coordinate/region the map flies to, now runs
/// **once — only when the user taps a suggestion**. Type-ahead feels
/// live; the network cost moves to selection-time.
///
/// Apple's service is hit directly — no third-party deps, no Atlas
/// backend — consistent with the app's existing MapKit/CoreLocation use.
/// Not `@MainActor`-annotated: `MKLocalSearchCompleter` already delivers
/// its delegate callbacks on the main thread, and every call site (the
/// SwiftUI view) is main-isolated — so the observable state is only ever
/// touched on main. Keeping the class non-isolated avoids the delegate
/// conformance crossing an actor boundary.
@Observable
final class PlaceSearchService: NSObject, MKLocalSearchCompleterDelegate {
    private(set) var suggestions: [PlaceSuggestion] = []
    /// True while a non-empty query fragment is outstanding but the
    /// completer hasn't returned yet — lets the UI hold the results view
    /// instead of flashing the no-results empty state mid-type.
    private(set) var isSearching = false

    /// Cap on how many place rows we surface, so the Places section
    /// doesn't dwarf the tour/maker results below it.
    private let maxResults: Int

    private let completer = MKLocalSearchCompleter()

    /// Bias results toward a part of the world — used by the create
    /// wizard, where "the old custom house" means the one in the city the
    /// maker just chose, not the nearest one to wherever they're sitting.
    /// Setting it re-runs the current query so the list updates in place.
    /// Set it before the next query — callers change it when the chosen city
    /// changes, and clear the field at the same time, so there is nothing
    /// outstanding to re-run.
    var regionBias: MKCoordinateRegion? {
        didSet {
            guard let regionBias else { return }
            completer.region = regionBias
        }
    }

    /// POI categories that count as a "notable place" worth flying the
    /// map to — cultural / civic / nature / venue landmarks. Restaurants,
    /// shops, and other businesses are excluded so place search reads as
    /// "take me to a city / neighborhood / landmark", not a Yelp list.
    /// Deliberately tighter than the map's orientation allowlist
    /// (`HomeMapSection.tourPOI`): no transit / hotels / parking / EV /
    /// ATMs here — those are useful to *see* on the map but aren't search
    /// destinations.
    private static let landmarkCategories: [MKPointOfInterestCategory] = [
        // Cultural / civic landmarks
        .landmark, .museum, .nationalMonument, .library, .castle, .fortress,
        // Performance + venues
        .theater, .movieTheater, .musicVenue, .stadium,
        // Family / educational attractions
        .aquarium, .planetarium, .zoo, .amusementPark,
        // Nature + open space
        .park, .nationalPark, .beach, .marina,
        // Civic anchor
        .university
    ]

    /// Defaults are the Search tab's behaviour: addresses cover cities /
    /// neighborhoods / regions ("London", "Brooklyn"), points of interest
    /// cover named landmarks, and the POI half is narrowed to landmark
    /// categories so restaurants and shops don't clutter place results.
    ///
    /// The create wizard overrides all three — see `.cities` and `.venues`.
    init(
        resultTypes: MKLocalSearchCompleter.ResultType = [.address, .pointOfInterest],
        pointOfInterestFilter: MKPointOfInterestFilter? = nil,
        maxResults: Int = 4
    ) {
        self.maxResults = maxResults
        super.init()
        completer.delegate = self
        completer.resultTypes = resultTypes
        completer.pointOfInterestFilter = pointOfInterestFilter
            ?? MKPointOfInterestFilter(including: Self.landmarkCategories)
    }

    /// Towns, cities and regions only — no venues. What the wizard's
    /// "city & country" field needs.
    static func cities() -> PlaceSearchService {
        PlaceSearchService(resultTypes: [.address], maxResults: 5)
    }

    /// Anywhere a tour could be made about, which is a far wider net than
    /// the Search tab casts: a third of the catalogue is cafés, bars and
    /// restaurants, so the landmark-only filter would hide most of what a
    /// maker is standing in front of.
    static func venues() -> PlaceSearchService {
        PlaceSearchService(
            resultTypes: [.pointOfInterest, .address],
            pointOfInterestFilter: .includingAll,
            maxResults: 5
        )
    }

    /// Update the live query. The completer streams matches to the
    /// delegate as the fragment changes; an empty fragment clears
    /// everything immediately.
    func search(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            clear()
            return
        }
        isSearching = true
        completer.queryFragment = trimmed
    }

    /// Resolve a tapped suggestion into a map region via a single
    /// `MKLocalSearch`. Returns nil if the lookup fails or carries no
    /// coordinate.
    func resolve(_ suggestion: PlaceSuggestion) async -> MKCoordinateRegion? {
        await resolveDetails(suggestion)?.region
    }

    /// The same lookup, keeping what the place *is* as well as where it is.
    /// One network call either way — `resolve` is this with the extras
    /// thrown away.
    func resolveDetails(_ suggestion: PlaceSuggestion) async -> ResolvedPlace? {
        let request = MKLocalSearch.Request(completion: suggestion.completion)
        guard let item = try? await MKLocalSearch(request: request).start().mapItems.first else {
            return nil
        }
        let placemark = item.placemark
        return ResolvedPlace(
            coordinate: placemark.coordinate,
            region: Self.region(for: item),
            name: item.name,
            locality: placemark.locality ?? placemark.subAdministrativeArea,
            country: placemark.country
        )
    }

    /// Drop any pending query + results — e.g. when the user clears the
    /// field or leaves the Search screen.
    func clear() {
        completer.queryFragment = ""
        isSearching = false
        suggestions = []
    }

    // MARK: - MKLocalSearchCompleterDelegate

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        suggestions = completer.results
            .prefix(maxResults)
            .map { PlaceSuggestion(title: $0.title, subtitle: $0.subtitle, completion: $0) }
        isSearching = false
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        suggestions = []
        isSearching = false
    }

    // MARK: - Region derivation

    /// Derive the camera region from a resolved map item: use the
    /// placemark's own `CLCircularRegion` radius when present (so a city
    /// zooms to city level and a single landmark zooms in tight),
    /// clamped to a sane min/max, with a fixed fallback otherwise.
    private static func region(for item: MKMapItem) -> MKCoordinateRegion {
        let placemark = item.placemark
        let coordinate = placemark.coordinate
        if let circular = placemark.region as? CLCircularRegion {
            // Diameter ≈ radius × 2, padded a touch so the feature isn't
            // flush against the screen edges. Clamp so a tiny POI isn't
            // absurdly zoomed-in and a country isn't zoomed-out past use.
            let meters = min(max(circular.radius * 2.2, 1_000), 50_000)
            return MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: meters,
                longitudinalMeters: meters
            )
        }
        return MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 8_000,
            longitudinalMeters: 8_000
        )
    }
}
