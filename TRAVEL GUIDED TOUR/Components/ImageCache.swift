#if canImport(UIKit)
import UIKit

/// In-memory image cache backed by `NSCache`. Survives `LazyVStack`
/// cell recycling — unlike `AsyncImage`, which restarts the fetch
/// every time the containing view is recreated. `NSCache` evicts
/// automatically under memory pressure, so this never needs manual
/// trimming beyond the user-facing "Clear Cache" action.
final class ImageCache {
    static let shared = ImageCache()

    private let cache: NSCache<NSString, UIImage> = {
        let c = NSCache<NSString, UIImage>()
        c.countLimit = 150
        c.totalCostLimit = 50 * 1024 * 1024
        return c
    }()

    private init() {}

    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url.absoluteString as NSString)
    }

    func store(_ image: UIImage, for url: URL) {
        // Cost = decoded pixel buffer bytes so totalCostLimit reflects
        // real RAM usage rather than the much-smaller compressed size.
        let cost = Int(image.size.width * image.scale * image.size.height * image.scale) * 4
        cache.setObject(image, forKey: url.absoluteString as NSString, cost: cost)
    }

    func clear() {
        cache.removeAllObjects()
    }
}
#endif
