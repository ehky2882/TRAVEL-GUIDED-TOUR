import Foundation
import Observation
import CoreLocation

@Observable
final class DataService {
    private(set) var tours: [Tour] = []
    private(set) var makers: [Maker] = []
    /// Sites carrying more than one tour. Empty for any catalog published
    /// before the place layer, which is why every reader must treat "no place"
    /// as the normal case rather than an error.
    private(set) var places: [Place] = []

    // MARK: - Lookup indexes
    //
    // Every `by id` accessor below is read **per row, per body evaluation**,
    // from ~20 call sites — the always-mounted mini-player, the Home drawer's
    // continue-listening row, and every list row in Library. A linear
    // `first { $0.id == id }` over a 1,418-tour catalog turns each of those
    // into thousands of UUID comparisons, and Library alone runs dozens per
    // frame (`savedTours` is a compactMap of scans, a maker row's tour count
    // is a full filter, a place row resolves its ranked tours three times).
    //
    // These dictionaries make all of it O(1). They are rebuilt only when the
    // catalog itself changes — a launch, a refresh, or a local maker patch —
    // so keeping them in step costs nothing on the read path.
    //
    // **Anything that mutates `tours` / `makers` / `places` must go through
    // `applyCatalog`, `applyMakers` or `setPlaces`**, or the indexes go stale
    // and lookups start returning nil for rows that are plainly on screen.
    private var tourById: [UUID: Tour] = [:]
    private var makerById: [UUID: Maker] = [:]
    private var placeById: [UUID: Place] = [:]
    /// Maker id → that maker's tours, in catalog order. Backs `tours(by:)`,
    /// which the maker page renders from and every followed-maker row calls
    /// just to count.
    private var toursByMakerId: [UUID: [Tour]] = [:]
    /// Tour id → its place. Built once whenever `places` changes, because the
    /// map asks this per pin and a linear scan per marker would be quadratic
    /// over a 1,418-tour catalog.
    private var placeByTourId: [UUID: Place] = [:]

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
            applyCatalog(tours: local.tours, makers: local.makers, places: local.places ?? [])
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
        applyCatalog(tours: fresh.tours, makers: fresh.makers, places: fresh.places ?? [])
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

    /// Patch a single maker into the in-memory catalog immediately (replace by
    /// id, or append if new). Lets a creator's just-saved profile edit show on
    /// the public maker page right away instead of waiting for the next catalog
    /// refresh — the persisted `makers` row is already updated, so the next real
    /// `get_catalog` fetch stays consistent with this.
    @MainActor
    func applyLocalMaker(_ maker: Maker) {
        var updated = makers
        if let i = updated.firstIndex(where: { $0.id == maker.id }) {
            updated[i] = maker
        } else {
            updated.append(maker)
        }
        applyMakers(updated)
    }

    // MARK: - Applying catalog state

    /// The one door through which the whole catalog changes. Publishes the new
    /// arrays and rebuilds every lookup index in the same step, so the two can
    /// never disagree.
    private func applyCatalog(tours newTours: [Tour], makers newMakers: [Maker], places newPlaces: [Place]) {
        tours = newTours
        var byId: [UUID: Tour] = [:]
        byId.reserveCapacity(newTours.count)
        var byMaker: [UUID: [Tour]] = [:]
        for tour in newTours {
            byId[tour.id] = tour
            byMaker[tour.makerId, default: []].append(tour)
        }
        tourById = byId
        toursByMakerId = byMaker

        applyMakers(newMakers)
        setPlaces(newPlaces)
    }

    private func applyMakers(_ newMakers: [Maker]) {
        makers = newMakers
        var byId: [UUID: Maker] = [:]
        byId.reserveCapacity(newMakers.count)
        for maker in newMakers { byId[maker.id] = maker }
        makerById = byId
    }

    private func setPlaces(_ newPlaces: [Place]) {
        places = newPlaces
        var byId: [UUID: Place] = [:]
        var byTour: [UUID: Place] = [:]
        for place in newPlaces {
            byId[place.id] = place
            for tourId in place.tourIds { byTour[tourId] = place }
        }
        placeById = byId
        placeByTourId = byTour
    }

    // MARK: - Lookups

    func place(by id: UUID) -> Place? {
        placeById[id]
    }

    /// The place a tour belongs to, or nil — which is the ordinary case: only
    /// tours sharing a coordinate with another tour have one.
    func place(forTourId id: UUID) -> Place? {
        placeByTourId[id]
    }

    /// A place's tours in display order (`Place.ranked`). Silently drops ids
    /// the catalog no longer carries, so a stale place can't produce a hole.
    func rankedTours(at place: Place) -> [Tour] {
        Place.ranked(place.tourIds.compactMap { tour(by: $0) })
    }

    func tour(by id: UUID) -> Tour? {
        tourById[id]
    }

    func maker(by id: UUID) -> Maker? {
        makerById[id]
    }

    func maker(for tour: Tour) -> Maker? {
        maker(by: tour.makerId)
    }

    func tours(by maker: Maker) -> [Tour] {
        toursByMakerId[maker.id] ?? []
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
