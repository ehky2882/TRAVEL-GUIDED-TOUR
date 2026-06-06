import Foundation
import MapKit
import CoreLocation
import Observation

/// A single place match from Apple's `MKLocalSearch`, reduced to just
/// what the Search UI + Home map need: a display name, a one-line
/// subtitle, and the `MKCoordinateRegion` to glide the map camera to.
struct PlaceResult: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let region: MKCoordinateRegion
}

/// Debounced wrapper around `MKLocalSearch` for the "search the map,
/// not just the catalog" feature. As the user types, it asks Apple's
/// geocoder for matching places (cities, neighborhoods, landmarks) and
/// publishes up to `maxResults` of them so `SearchView` can show a
/// Places section. Tapping a result flies the Home map there.
///
/// Apple's service is hit directly — no third-party deps, no Atlas
/// backend — consistent with the app's existing MapKit/CoreLocation
/// usage. Each keystroke cancels the previous in-flight lookup and
/// restarts a short debounce so we don't fire a request per character
/// or trip MKLocalSearch's rate limiter.
@MainActor
@Observable
final class PlaceSearchService {
    private(set) var results: [PlaceResult] = []
    private(set) var isSearching = false

    /// Cap on how many place rows we surface. Keeps the Places section
    /// from dwarfing the tour/maker results below it.
    private let maxResults = 4
    /// Debounce window — long enough to coalesce fast typing, short
    /// enough to feel live.
    private let debounce: Duration = .milliseconds(300)

    private var searchTask: Task<Void, Never>?

    /// Kick off a (debounced) place lookup for `query`. An empty or
    /// whitespace-only query clears results immediately.
    func search(_ query: String) {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            isSearching = false
            results = []
            return
        }

        isSearching = true
        searchTask = Task { [maxResults, debounce] in
            try? await Task.sleep(for: debounce)
            if Task.isCancelled { return }

            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = trimmed
            // Addresses cover cities / neighborhoods / regions
            // ("London", "Brooklyn"); points of interest cover named
            // landmarks ("Eiffel Tower"). Both resolve to a place the
            // camera can fly to.
            request.resultTypes = [.address, .pointOfInterest]

            let response = try? await MKLocalSearch(request: request).start()
            if Task.isCancelled { return }

            results = (response?.mapItems ?? [])
                .prefix(maxResults)
                .map(PlaceResult.init(from:))
            isSearching = false
        }
    }

    /// Drop any pending lookup and clear results — e.g. when the user
    /// clears the field or leaves the Search screen.
    func clear() {
        searchTask?.cancel()
        isSearching = false
        results = []
    }
}

private extension PlaceResult {
    /// Reduce an `MKMapItem` to the fields the UI needs. The region is
    /// derived from the placemark's own `CLCircularRegion` radius when
    /// present (so a city zooms to city level and a single landmark
    /// zooms in tight), clamped to a sane min/max, with a fixed
    /// fallback when the placemark carries no region.
    init(from item: MKMapItem) {
        let placemark = item.placemark
        let resolvedName = item.name
            ?? placemark.name
            ?? placemark.locality
            ?? "Unknown place"

        // Subtitle: locality / state / country, dropping any part that
        // just repeats the name. e.g. London → "England, United Kingdom".
        let subtitleParts = [placemark.locality, placemark.administrativeArea, placemark.country]
            .compactMap { $0 }
            .filter { $0 != resolvedName }
        let resolvedSubtitle = subtitleParts.joined(separator: ", ")

        let coordinate = placemark.coordinate
        let resolvedRegion: MKCoordinateRegion
        if let circular = placemark.region as? CLCircularRegion {
            // Diameter ≈ radius × 2, padded a touch so the feature
            // isn't flush against the screen edges. Clamp so a tiny POI
            // isn't absurdly zoomed-in and a country isn't zoomed-out
            // past usefulness.
            let meters = min(max(circular.radius * 2.2, 1_000), 50_000)
            resolvedRegion = MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: meters,
                longitudinalMeters: meters
            )
        } else {
            resolvedRegion = MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 8_000,
                longitudinalMeters: 8_000
            )
        }

        self.init(name: resolvedName, subtitle: resolvedSubtitle, region: resolvedRegion)
    }
}
