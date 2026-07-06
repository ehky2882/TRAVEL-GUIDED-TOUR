#if canImport(UIKit)
import UIKit
import CryptoKit

/// In-memory image cache backed by `NSCache`. Survives `LazyVStack`
/// cell recycling — unlike `AsyncImage`, which restarts the fetch
/// every time the containing view is recreated. `NSCache` evicts
/// automatically under memory pressure, so this never needs manual
/// trimming beyond the user-facing "Clear Cache" action.
///
/// **Avatar disk layer.** Hero images survive relaunch via `URLCache` (see the
/// app init), but avatars need to render on the *very first frame* — a memory
/// miss on cold launch would flash the coloured monogram before the async load
/// returns. So avatars additionally get a small on-disk copy that
/// `diskBackedImage(for:)` reads **synchronously** (avatars are tiny + few, so
/// this is cheap to do in a view initializer). This makes an own-profile /
/// Library / Search avatar a frame-zero hit after the first ever load, even
/// after a relaunch or a memory-pressure eviction.
final class ImageCache {
    static let shared = ImageCache()

    private let cache: NSCache<NSString, UIImage> = {
        let c = NSCache<NSString, UIImage>()
        c.countLimit = 150
        c.totalCostLimit = 50 * 1024 * 1024
        return c
    }()

    /// Directory holding persisted avatar bytes. `nil` only if Caches is
    /// somehow unavailable (then the disk layer degrades to memory-only).
    private let avatarDir: URL?

    /// `directory` is injectable so tests can point at a throwaway temp dir;
    /// the app uses `Caches/AvatarCache`.
    init(directory: URL? = nil) {
        let fm = FileManager.default
        let dir = directory
            ?? fm.urls(for: .cachesDirectory, in: .userDomainMask).first?
                .appendingPathComponent("AvatarCache", isDirectory: true)
        if let dir {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        avatarDir = dir
    }

    // MARK: - Memory (used by hero images + existing callers; unchanged)

    func image(for url: URL) -> UIImage? {
        cache.object(forKey: key(url))
    }

    func store(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: key(url), cost: cost(image))
    }

    // MARK: - Disk-backed avatars

    /// Memory hit, else a synchronous disk hit (decoded + promoted back into
    /// memory), else `nil`. Memory is always checked first, so this is a strict
    /// superset of `image(for:)` — the existing no-flash-on-tab-switch path
    /// (memory hit at view init) is preserved exactly.
    func diskBackedImage(for url: URL) -> UIImage? {
        if let hit = cache.object(forKey: key(url)) { return hit }
        guard let file = avatarFile(for: url),
              let data = try? Data(contentsOf: file),
              let image = UIImage(data: data) else { return nil }
        cache.setObject(image, forKey: key(url), cost: cost(image))
        return image
    }

    /// Store in memory AND write the bytes to disk so the avatar survives
    /// relaunch / eviction. Prefer the original downloaded `data` (no re-encode);
    /// fall back to a JPEG render if it isn't available.
    func storeToDisk(_ image: UIImage, data: Data?, for url: URL) {
        cache.setObject(image, forKey: key(url), cost: cost(image))
        guard let file = avatarFile(for: url) else { return }
        guard let bytes = data ?? image.jpegData(compressionQuality: 0.9) else { return }
        try? bytes.write(to: file, options: .atomic)
    }

    func clear() {
        cache.removeAllObjects()
        // Also wipe persisted avatars so "Clear Cache" is honest.
        if let dir = avatarDir {
            let fm = FileManager.default
            try? fm.removeItem(at: dir)
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }

    // MARK: - Helpers

    private func key(_ url: URL) -> NSString { url.absoluteString as NSString }

    private func cost(_ image: UIImage) -> Int {
        // Decoded pixel-buffer bytes so totalCostLimit reflects real RAM usage
        // rather than the much-smaller compressed size.
        Int(image.size.width * image.scale * image.size.height * image.scale) * 4
    }

    /// A stable, filename-safe path for a URL's on-disk avatar copy. SHA-256 of
    /// the absolute string — deterministic across launches (unlike `hashValue`).
    private func avatarFile(for url: URL) -> URL? {
        guard let dir = avatarDir else { return nil }
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        let name = digest.map { String(format: "%02x", $0) }.joined()
        return dir.appendingPathComponent(name)
    }
}
#endif
