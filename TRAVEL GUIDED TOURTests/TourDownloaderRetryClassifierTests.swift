import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// Covers `TourDownloader.isTransientNetworkError(_:)` — the pure
/// classifier that gates the retry-with-backoff path (audit P3-4).
/// The retry orchestration itself depends on real URLSession behavior
/// and is left to manual / device testing during M-qa.
final class TourDownloaderRetryClassifierTests: XCTestCase {

    private func urlError(_ code: Int) -> NSError {
        NSError(domain: NSURLErrorDomain, code: code, userInfo: nil)
    }

    // MARK: - Transient cases

    func test_timedOut_isTransient() {
        XCTAssertTrue(TourDownloader.isTransientNetworkError(urlError(NSURLErrorTimedOut)))
    }

    func test_networkConnectionLost_isTransient() {
        XCTAssertTrue(TourDownloader.isTransientNetworkError(urlError(NSURLErrorNetworkConnectionLost)))
    }

    func test_notConnectedToInternet_isTransient() {
        XCTAssertTrue(TourDownloader.isTransientNetworkError(urlError(NSURLErrorNotConnectedToInternet)))
    }

    func test_dnsLookupFailed_isTransient() {
        XCTAssertTrue(TourDownloader.isTransientNetworkError(urlError(NSURLErrorDNSLookupFailed)))
    }

    func test_cannotConnectToHost_isTransient() {
        XCTAssertTrue(TourDownloader.isTransientNetworkError(urlError(NSURLErrorCannotConnectToHost)))
    }

    // MARK: - Terminal cases

    func test_badURL_isNotTransient() {
        XCTAssertFalse(TourDownloader.isTransientNetworkError(urlError(NSURLErrorBadURL)))
    }

    func test_unsupportedURL_isNotTransient() {
        XCTAssertFalse(TourDownloader.isTransientNetworkError(urlError(NSURLErrorUnsupportedURL)))
    }

    func test_cancelled_isNotTransient() {
        // Cancelled is filtered out by the caller, but we don't want
        // it classified as transient either — cancelling would
        // retry the cancelled download, which is the opposite of
        // what the user asked for.
        XCTAssertFalse(TourDownloader.isTransientNetworkError(urlError(NSURLErrorCancelled)))
    }

    func test_nonURLErrorDomain_isNotTransient() {
        let other = NSError(domain: NSCocoaErrorDomain, code: NSURLErrorTimedOut, userInfo: nil)
        XCTAssertFalse(TourDownloader.isTransientNetworkError(other))
    }
}
