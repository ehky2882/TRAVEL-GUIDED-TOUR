import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// The rule these pin: a photograph already on the phone should be drawn when
/// the network cannot be reached, rather than thrown away because iOS could not
/// revalidate it with a server that is not there.
final class OfflineImageFallbackTests: XCTestCase {

    private var cache: URLCache!
    private var directory: URL!

    override func setUpWithError() throws {
        // Never `URLCache.shared` — that is process-wide state a test has no
        // business mutating.
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        cache = URLCache(memoryCapacity: 1_000_000, diskCapacity: 5_000_000, directory: directory)
    }

    override func tearDownWithError() throws {
        cache.removeAllCachedResponses()
        cache = nil
        try? FileManager.default.removeItem(at: directory)
        directory = nil
    }

    private func store(_ body: Data, for url: URL, cacheControl: String?) {
        var headers = ["Content-Type": "image/webp"]
        headers["Cache-Control"] = cacheControl
        let response = HTTPURLResponse(
            url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers
        )!
        cache.storeCachedResponse(
            CachedURLResponse(response: response, data: body),
            for: URLRequest(url: url)
        )
    }

    // MARK: - Reading what we already have

    func test_returnsTheStoredBytesForAKnownURL() {
        let url = URL(string: "https://example.com/hero.webp")!
        store(Data("photograph".utf8), for: url, cacheControl: "max-age=600")
        XCTAssertEqual(
            OfflineImageFallback.cachedData(for: url, in: cache),
            Data("photograph".utf8)
        )
    }

    /// The whole point: gh-pages says `max-age=600`, so after ten minutes iOS
    /// will not use these bytes without asking a server first. Underground
    /// there is no server — and the bytes are still perfectly good.
    func test_ignoresFreshnessEntirely_evenForAnAlreadyExpiredResponse() {
        let url = URL(string: "https://example.com/stale.webp")!
        store(Data("photograph".utf8), for: url, cacheControl: "max-age=0")
        XCTAssertNotNil(OfflineImageFallback.cachedData(for: url, in: cache))
    }

    func test_returnsNothingForAURLNeverFetched() {
        store(Data("photograph".utf8), for: URL(string: "https://example.com/a.webp")!,
              cacheControl: "max-age=600")
        XCTAssertNil(
            OfflineImageFallback.cachedData(for: URL(string: "https://example.com/b.webp")!, in: cache)
        )
    }

    func test_returnsNothingOnceTheCacheIsCleared() {
        let url = URL(string: "https://example.com/hero.webp")!
        store(Data("photograph".utf8), for: url, cacheControl: "max-age=600")
        cache.removeAllCachedResponses()
        XCTAssertNil(OfflineImageFallback.cachedData(for: url, in: cache))
    }

    #if canImport(UIKit)
    func test_undecodableBytesAreNotAnImage() {
        let url = URL(string: "https://example.com/broken.webp")!
        store(Data("not an image".utf8), for: url, cacheControl: "max-age=600")
        XCTAssertNotNil(OfflineImageFallback.cachedData(for: url, in: cache))
        XCTAssertNil(OfflineImageFallback.cachedImage(for: url, in: cache))
    }
    #endif

    // MARK: - When it is worth looking

    func test_aDeadNetworkIsWorthFallingBackOn() {
        for code in [
            NSURLErrorNotConnectedToInternet,
            NSURLErrorTimedOut,
            NSURLErrorNetworkConnectionLost,
            NSURLErrorCannotConnectToHost,
            NSURLErrorDataNotAllowed,
        ] {
            let error = NSError(domain: NSURLErrorDomain, code: code)
            XCTAssertTrue(
                OfflineImageFallback.isWorthFallingBack(after: error),
                "URL error \(code) should consult the cache"
            )
        }
    }

    /// A view scrolled off screen cancels its own fetch. Nobody is waiting on
    /// a photograph for a screen that has gone.
    func test_cancellationIsNotWorthFallingBackOn() {
        XCTAssertFalse(OfflineImageFallback.isWorthFallingBack(after: CancellationError()))
        XCTAssertFalse(OfflineImageFallback.isWorthFallingBack(
            after: NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled)
        ))
    }

    func test_anUnrecognisedErrorStillConsultsTheCache() {
        // Better a photograph we have than a grey box, for an error we did not
        // anticipate.
        XCTAssertTrue(OfflineImageFallback.isWorthFallingBack(
            after: NSError(domain: "SomeOtherDomain", code: 42)
        ))
    }
}
