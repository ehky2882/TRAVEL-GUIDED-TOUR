import Foundation
import Observation
import CoreLocation

@Observable
final class DataService {
    private(set) var tours: [Tour] = []
    private(set) var makers: [Maker] = []

    private let loader: RemoteCatalogLoader

    /// - Parameters:
    ///   - loader: catalog source (local cache/bundle + network refresh).
    ///   - autoRefresh: when true (production), kicks off a background network
    ///     refresh on init. Tests pass false to keep loading deterministic.
    init(loader: RemoteCatalogLoader = RemoteCatalogLoader(), autoRefresh: Bool = true) {
        self.loader = loader
        // 1. Load the immediately-available local catalog (cache → bundle)
        //    synchronously so the UI has data at first frame and offline works
        //    exactly as before.
        if let local = loader.loadLocal() {
            tours = local.tours
            makers = local.makers
        }
        // 2. Refresh from the network in the background. On success it
        //    overwrites the cache and updates the published catalog so views
        //    react live; any failure leaves the local copy untouched.
        if autoRefresh {
            Task { await refresh() }
        }
    }

    /// Fetches the latest catalog and applies it on the main actor if it
    /// succeeds. Safe to call anytime; a network/decode failure is a no-op.
    func refresh() async {
        guard let fresh = await loader.refresh() else { return }
        await MainActor.run {
            self.tours = fresh.tours
            self.makers = fresh.makers
        }
    }

    func tour(by id: UUID) -> Tour? {
        tours.first { $0.id == id }
    }

    func maker(by id: UUID) -> Maker? {
        makers.first { $0.id == id }
    }

    func maker(for tour: Tour) -> Maker? {
        maker(by: tour.makerId)
    }

    func tours(by maker: Maker) -> [Tour] {
        tours.filter { $0.makerId == maker.id }
    }

    func tours(in category: TourCategory) -> [Tour] {
        tours.filter { $0.primaryCategory == category }
    }

    func toursNearby(_ location: CLLocation, limit: Int = 10) -> [Tour] {
        tours
            .sorted { $0.distance(from: location) < $1.distance(from: location) }
            .prefix(limit)
            .map { $0 }
    }
}
