import Foundation
import CryptoKit

/// Where a downloaded tour's photographs can be found on disk.
///
/// A tour downloaded for offline keeps its photographs beside its audio, in
/// `Documents/atlas-tours/<tourId>/` — **not** in `URLCache` or `ImageCache`.
/// Both of those are caches in the real sense: the system evicts them under
/// pressure, and Settings has a Clear Cache button that empties them. Neither
/// should be able to strip the pictures off a tour the user deliberately saved
/// for a journey with no signal.
///
/// 🔴 THE LOOKUP HAS TO WORK FROM A URL ALONE, because that is all a view
/// showing a photograph has. `HeroImageView` is handed an image URL and knows
/// nothing about which tour it belongs to — so the files are named after a
/// hash of their own URL, and this index maps that name back to the file.
///
/// Kept as a shared instance rather than an `@Environment` value on purpose:
/// `HeroImageView` renders inside the UIKit slide-up layers too, which do not
/// inherit the SwiftUI environment, and a missing injection there would show
/// as *photographs silently absent offline on exactly the screen that matters*
/// — the tour you are standing in front of.
///
/// ⚠️ Deliberately NOT `@MainActor`. `TourDownloader` is not actor-isolated —
/// it is a `URLSessionDownloadDelegate` whose callbacks happen to arrive on
/// the main queue — so main-actor isolation here would not compile at its call
/// sites, and `MainActor.assumeIsolated` would be an assertion about someone
/// else's threading. A lock is the honest guarantee: the reads are a
/// dictionary lookup and the writes happen a handful of times per download.
final class DownloadedImageIndex: @unchecked Sendable {
    static let shared = DownloadedImageIndex()

    /// Base name (no extension) → the file on disk. Guarded by `lock`.
    private var files: [String: URL] = [:]
    private let lock = NSLock()

    init() {}

    /// The on-disk base name for a remote image URL. Stable across launches
    /// and independent of the tour, so `TourDownloader` can write a file the
    /// index can later find with nothing but the URL.
    ///
    /// The `img-` prefix keeps these clear of the audio files in the same
    /// folder, which are named `intro` and stop UUIDs.
    static func baseName(for url: URL) -> String {
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return "img-" + hex.prefix(16)
    }

    /// The downloaded copy of this image, or nil if no downloaded tour holds
    /// one. Cheap enough to call from a view.
    func file(for url: URL) -> URL? {
        let name = Self.baseName(for: url)
        lock.lock(); defer { lock.unlock() }
        return files[name]
    }

    /// Record every `img-*` file in a downloaded tour's folder.
    func register(folder: URL) {
        guard let entries = try? FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: nil
        ) else { return }
        lock.lock(); defer { lock.unlock() }
        for entry in entries {
            let base = entry.deletingPathExtension().lastPathComponent
            guard base.hasPrefix("img-") else { continue }
            files[base] = entry
        }
    }

    /// Drop everything a folder contributed — call when a download is deleted,
    /// so a stale path can never be handed to a view.
    ///
    /// ⚠️ Compares by folder rather than re-deriving names: the tour is gone
    /// from disk by the time this runs, so there is nothing left to enumerate.
    func forget(folder: URL) {
        let prefix = folder.standardizedFileURL.path
        lock.lock(); defer { lock.unlock() }
        files = files.filter { !$0.value.standardizedFileURL.path.hasPrefix(prefix) }
    }
}
