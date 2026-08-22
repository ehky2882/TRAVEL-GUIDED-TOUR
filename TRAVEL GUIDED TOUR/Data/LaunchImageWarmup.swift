import Foundation
import CoreLocation
import MapKit
import Observation
#if canImport(UIKit)
import UIKit
#endif

/// Pulls the first screenful of card photos into the image cache **during the
/// splash**, so the drawer arrives complete rather than filling in afterwards.
///
/// Owner decision 2026-08-22: *"I want ready including photos."* The catalog was
/// already gated on — every title, distance and count is real before anything
/// animates — but hero images were not, so a cold launch showed cards that
/// arrived and then populated. This closes that.
///
/// ⚠️ **Bounded, always.** A slow or dead network must cost a fixed amount of
/// launch time and no more, so the warmup reports itself ready when its own
/// deadline passes whether or not the fetches finished. `LaunchGate.ceiling` is
/// the backstop behind that. Photos are worth waiting a moment for; they are
/// not worth an app that won't open.
@MainActor
@Observable
final class LaunchImageWarmup {
    /// True once the first screenful is cached, or the deadline passed.
    private(set) var isReady = false
    /// Whether `start` has already run. The gate polls, so this is what keeps
    /// it from kicking off a fetch ten times a second.
    private var hasStarted = false

    /// How many cards deep to warm.
    ///
    /// The drawer opens at its mid detent, which shows roughly the first rail
    /// and the top of the second. Eight covers what is on screen plus a card of
    /// horizontal scroll, without turning the launch into a download of the
    /// whole catalog.
    static let count = 8

    /// Longest the launch will wait for photos.
    static let deadline: TimeInterval = 1.2

    /// Begin warming. Safe to call repeatedly; only the first call does work.
    ///
    /// The rails are computed with the app's own `HomeRailsViewModel.rails`
    /// rather than a guess at what the drawer shows — so if the shelves are
    /// ever reordered, the warmup follows automatically instead of prefetching
    /// photos nobody is about to see.
    func start(
        tours: [Tour],
        libraryEntries: [LibraryEntry],
        recentlyViewedIds: [UUID],
        userLocation: CLLocation?
    ) {
        guard !hasStarted else { return }
        hasStarted = true

        let rails = HomeRailsViewModel.rails(
            tours: tours,
            libraryEntries: libraryEntries,
            recentlyViewedIds: recentlyViewedIds,
            userLocation: userLocation,
            // No settled region yet at launch — the map has not reported one.
            // The rails fall back to their own ordering, which is what the
            // drawer will render on its first frame too.
            visibleRegion: nil
        )
        let urls = Self.warmupURLs(rails: rails)
        guard !urls.isEmpty else {
            isReady = true
            return
        }

        Task { @MainActor in
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    try? await Task.sleep(for: .seconds(Self.deadline))
                }
                group.addTask {
                    await Self.prefetch(urls)
                }
                // Whichever finishes first wins: the photos are in, or we have
                // waited long enough. The loser keeps running harmlessly — a
                // fetch that lands late still populates the cache, it just
                // doesn't hold the launch.
                _ = await group.next()
                group.cancelAll()
            }
            isReady = true
        }
    }

    /// The hero URLs worth warming, in the order they'll be seen.
    ///
    /// Pure, so the selection is testable without a network: deduplicated
    /// (rails overlap — the same tour appears in several shelves), capped, and
    /// filtered to what actually parses as a URL.
    nonisolated static func warmupURLs(rails: [HomeRail], limit: Int = count) -> [URL] {
        var seen = Set<String>()
        var out: [URL] = []
        for rail in rails {
            for tour in rail.tours {
                let name = tour.heroImageURL
                guard !name.isEmpty, !seen.contains(name) else { continue }
                seen.insert(name)
                guard let url = URL(string: name) else { continue }
                out.append(url)
                if out.count >= limit { return out }
            }
        }
        return out
    }

    /// Fetch and cache, concurrently. Anything already cached is skipped, which
    /// is why a warm launch costs nothing at all here.
    nonisolated static func prefetch(_ urls: [URL]) async {
        #if canImport(UIKit)
        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask {
                    if ImageCache.shared.image(for: url) != nil { return }
                    guard let (data, _) = try? await URLSession.shared.data(from: url),
                          let image = UIImage(data: data) else { return }
                    ImageCache.shared.store(image, for: url)
                }
            }
        }
        #endif
    }
}
