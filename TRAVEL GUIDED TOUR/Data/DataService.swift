import Foundation
import Observation
import CoreLocation

@Observable
final class DataService {
    private(set) var tours: [Tour] = []
    private(set) var makers: [Maker] = []

    private let loader: RemoteCatalogLoader

    /// Minimum spacing between foreground-triggered refreshes — re-opening the
    /// app within this window won't refetch (the cold-launch / previous refresh
    /// is still fresh enough).
    private let foregroundRefreshInterval: TimeInterval

    /// When the most recent refresh *started*. Drives the foreground debounce.
    private var lastRefreshStarted: Date?
    /// Guards against two refreshes running at once (e.g. the cold-launch
    /// refresh still in flight when the first `.active` scene phase fires).
    private var isRefreshing = false

    /// - Parameters:
    ///   - loader: catalog source (local cache/bundle + network refresh).
    ///   - autoRefresh: when true (production), kicks off a background network
    ///     refresh on init. Tests pass false to keep loading deterministic.
    ///   - foregroundRefreshInterval: debounce window for `refreshOnForeground`.
    init(loader: RemoteCatalogLoader = RemoteCatalogLoader(),
         autoRefresh: Bool = true,
         foregroundRefreshInterval: TimeInterval = 60) {
        self.loader = loader
        self.foregroundRefreshInterval = foregroundRefreshInterval
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
    /// The in-flight guard means overlapping calls collapse into one fetch.
    /// - Parameter startedAt: timestamp recorded as this refresh's start; used
    ///   by the foreground debounce (injectable for deterministic tests).
    @MainActor
    func refresh(startedAt: Date = Date()) async {
        if isRefreshing { return }
        isRefreshing = true
        lastRefreshStarted = startedAt
        defer { isRefreshing = false }

        guard let fresh = await loader.refresh() else { return }
        self.tours = fresh.tours
        self.makers = fresh.makers
    }

    /// Re-run the network refresh when the app returns to the foreground.
    /// Debounced so simply reopening the app within `foregroundRefreshInterval`
    /// of the last refresh — or while one is already in flight — is a no-op.
    /// This is what lets new content appear on a plain relaunch, no force-quit.
    /// - Parameter now: current time (injectable for deterministic tests).
    @MainActor
    func refreshOnForeground(now: Date = Date()) async {
        if let last = lastRefreshStarted,
           now.timeIntervalSince(last) < foregroundRefreshInterval {
            return
        }
        await refresh(startedAt: now)
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
