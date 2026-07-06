#if canImport(UIKit)
import XCTest
import UIKit
@testable import TRAVEL_GUIDED_TOUR

/// Tests for the avatar disk layer that keeps a maker's photo from flashing the
/// coloured monogram on cold launch — `diskBackedImage(for:)` must render the
/// persisted avatar even with a fresh (relaunched) in-memory cache.
final class ImageCacheDiskTests: XCTestCase {

    private var dir: URL!

    override func setUp() {
        super.setUp()
        dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ImageCacheDiskTests.\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: dir)
        dir = nil
        super.tearDown()
    }

    private func swatch(_ color: UIColor = .systemBlue) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).image { ctx in
            color.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }
    }

    private let url = URL(string: "https://example.test/avatar/abc.jpg")!

    // MARK: - Memory-first (preserves the #326 no-flash-on-tab-switch path)

    func testMemoryStoreIsReturnedByDiskBackedImage() {
        let cache = ImageCache(directory: dir)
        cache.store(swatch(), for: url)
        // A pure in-memory store (no disk write) must still be a hit — disk is
        // only a *fallback*, memory is checked first.
        XCTAssertNotNil(cache.diskBackedImage(for: url))
    }

    func testUnknownUrlIsNil() {
        let cache = ImageCache(directory: dir)
        XCTAssertNil(cache.diskBackedImage(for: url))
    }

    // MARK: - Disk round-trip (survives "relaunch")

    func testStoreToDiskSurvivesAFreshCache() {
        // Persist with one instance…
        ImageCache(directory: dir).storeToDisk(swatch(), data: nil, for: url)

        // …and read with a brand-new instance whose in-memory NSCache is empty
        // but which shares the same on-disk directory (models a cold launch).
        let reborn = ImageCache(directory: dir)
        XCTAssertNotNil(reborn.diskBackedImage(for: url),
                        "avatar should render frame-zero from disk after relaunch")
    }

    func testStoreToDiskPromotesBackIntoMemory() {
        ImageCache(directory: dir).storeToDisk(swatch(), data: nil, for: url)
        let reborn = ImageCache(directory: dir)
        // First read comes from disk; it should also seed memory so repeat reads
        // in the same session don't touch the filesystem again.
        _ = reborn.diskBackedImage(for: url)
        XCTAssertNotNil(reborn.image(for: url))
    }

    func testOriginalDataIsPreferredOverReencode() {
        let data = swatch(.systemRed).pngData()
        ImageCache(directory: dir).storeToDisk(swatch(.systemRed), data: data, for: url)
        XCTAssertNotNil(ImageCache(directory: dir).diskBackedImage(for: url))
    }

    // MARK: - Clear wipes disk too

    func testClearRemovesPersistedAvatars() {
        let cache = ImageCache(directory: dir)
        cache.storeToDisk(swatch(), data: nil, for: url)
        cache.clear()
        // Fresh instance (empty memory) must no longer find it on disk.
        XCTAssertNil(ImageCache(directory: dir).diskBackedImage(for: url))
    }
}
#endif
