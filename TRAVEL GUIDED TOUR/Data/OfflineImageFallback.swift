import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// The photograph we already have, when the request for it fails.
///
/// 🔴 A FAILED REQUEST DOES NOT MEAN WE DO NOT HAVE THE PHOTOGRAPH. `App.init`
/// gives `URLCache.shared` **200 MB of disk**, so a photograph the user has
/// scrolled past before is on the phone — but **GitHub Pages serves images with
/// `Cache-Control: max-age=600`**, so ten minutes later iOS must revalidate
/// with the server before it will use those bytes. With no signal there is no
/// server, the request fails, and the photograph goes undrawn while sitting in
/// the cache. That is precisely what the owner hit on the Underground
/// (2026-08-23): *"it loaded right away but the images did not load."*
///
/// So the failure path asks the cache directly, which no freshness rule stands
/// in front of.
///
/// ⚠️ THIS MUST STAY TIED TO AN ACTUAL FAILED REQUEST. The shortcut that looks
/// equivalent — giving the request `.returnCacheDataElseLoad` — is worse: it
/// prefers the stored copy even on a perfect connection, so a photograph we
/// later **replace** never updates. The catalogue does replace them (the
/// Thyssen-Bornemisza hero was the wrong building for a month; Milan's castle
/// hero was swapped for the facade its script describes), and those corrections
/// have to reach people. Owner accepted the narrow trade-off — offline you may
/// see a superseded photograph until you are back on signal — on that basis.
enum OfflineImageFallback {

    /// The cached bytes for a URL, ignoring freshness entirely.
    ///
    /// `cache` is injectable so tests can use their own rather than the shared
    /// one — `URLCache.shared` is process-wide state that a test has no
    /// business mutating.
    static func cachedData(for url: URL, in cache: URLCache = .shared) -> Data? {
        cache.cachedResponse(for: URLRequest(url: url))?.data
    }

    #if canImport(UIKit)
    /// The cached photograph for a URL, or nil if we have never successfully
    /// fetched it (in which case there is genuinely nothing to draw).
    static func cachedImage(for url: URL, in cache: URLCache = .shared) -> UIImage? {
        guard let data = cachedData(for: url, in: cache) else { return nil }
        return UIImage(data: data)
    }
    #endif

    /// Whether a thrown error is worth consulting the cache over.
    ///
    /// ⚠️ Cancellation is not. A view scrolled off screen cancels its own
    /// fetch, and there is no user waiting on a photograph to put on a screen
    /// that has gone — reading the cache there is work nobody asked for, on
    /// every row of a fast scroll.
    static func isWorthFallingBack(after error: Error) -> Bool {
        if error is CancellationError { return false }
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCancelled {
            return false
        }
        return true
    }
}
