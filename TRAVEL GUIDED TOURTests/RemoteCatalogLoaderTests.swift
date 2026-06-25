import XCTest
@testable import TRAVEL_GUIDED_TOUR

final class RemoteCatalogLoaderTests: XCTestCase {

    /// App-version stamp used by tests that expect a cache hit. The loader is
    /// constructed with the same value so the version-match check passes.
    private static let testVersion = "test-build"

    // MARK: - Helpers

    /// A bundle guaranteed to NOT contain a `Tours.json` resource, so the
    /// bundle fallback path resolves to nil in tests (lets us isolate the
    /// cache-vs-bundle priority deterministically).
    private var emptyBundle: Bundle { Bundle(for: RemoteCatalogLoaderTests.self) }

    /// Always returns / throws the same result.
    private struct StubFetcher: CatalogFetching {
        let result: Result<Data, Error>
        func fetchData(from url: URL) async throws -> Data {
            try result.get()
        }
    }

    /// Fails the first `failures` calls with `error`, then returns `success`.
    /// Counts every call so tests can assert how many attempts were made.
    private actor SequenceFetcher: CatalogFetching {
        private var remainingFailures: Int
        private let error: Error
        private let success: Data
        private(set) var callCount = 0

        init(failures: Int, error: Error, success: Data) {
            self.remainingFailures = failures
            self.error = error
            self.success = success
        }

        func fetchData(from url: URL) async throws -> Data {
            callCount += 1
            if remainingFailures > 0 {
                remainingFailures -= 1
                throw error
            }
            return success
        }
    }

    /// Zero-delay retry policy so retry tests don't pay real backoff sleeps.
    private func fastRetry(maxAttempts: Int) -> CatalogRetryPolicy {
        CatalogRetryPolicy(maxAttempts: maxAttempts, baseDelay: 0, jitter: 0)
    }

    private func makeTempDir() -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func catalog(titled title: String) -> ToursData {
        ToursData(makers: [TestFixtures.makeMaker()],
                  tours: [TestFixtures.makeTour(title: title)])
    }

    /// Seeds the on-disk cache, optionally stamping it with `version`. Pass
    /// `version: nil` to simulate a legacy cache written before version stamps.
    private func seedCache(_ data: ToursData,
                           in dir: URL,
                           version: String? = RemoteCatalogLoaderTests.testVersion) throws {
        let encoded = try JSONEncoder().encode(data)
        try encoded.write(to: dir.appendingPathComponent("Tours.cache.json"))
        if let version {
            try version.write(to: dir.appendingPathComponent("Tours.cache.version"),
                              atomically: true, encoding: .utf8)
        }
    }

    private func cacheExists(in dir: URL) -> Bool {
        FileManager.default.fileExists(atPath: dir.appendingPathComponent("Tours.cache.json").path)
    }

    // MARK: - loadLocal

    func test_loadLocal_returnsCachedCatalog_whenPresent() throws {
        let dir = makeTempDir()
        try seedCache(catalog(titled: "Cached Tour"), in: dir)
        let loader = RemoteCatalogLoader(fetcher: StubFetcher(result: .success(Data())),
                                         bundle: emptyBundle,
                                         cacheDirectory: dir,
                                         appVersion: Self.testVersion)

        let local = loader.loadLocal()

        XCTAssertEqual(local?.tours.first?.title, "Cached Tour")
    }

    func test_loadLocal_returnsNil_whenNoCacheAndNoBundleResource() {
        let loader = RemoteCatalogLoader(fetcher: StubFetcher(result: .success(Data())),
                                         bundle: emptyBundle,
                                         cacheDirectory: makeTempDir(),
                                         appVersion: Self.testVersion)

        XCTAssertNil(loader.loadLocal())
    }

    // MARK: - Version-stamped cache invalidation

    func test_loadLocal_discardsCache_whenAppVersionDiffers() throws {
        let dir = makeTempDir()
        // Cache stamped with the OLD build; loader runs as a NEW build.
        try seedCache(catalog(titled: "Stale Tour"), in: dir, version: "old-build")
        let loader = RemoteCatalogLoader(fetcher: StubFetcher(result: .success(Data())),
                                         bundle: emptyBundle,
                                         cacheDirectory: dir,
                                         appVersion: "new-build")

        // emptyBundle has no Tours.json, so once the stale cache is discarded
        // there is no fallback → nil (a real app would seed from its bundle).
        XCTAssertNil(loader.loadLocal())
        // The stale cache file is purged, not just ignored.
        XCTAssertFalse(cacheExists(in: dir))
    }

    func test_loadLocal_discardsCache_whenVersionStampMissing() throws {
        let dir = makeTempDir()
        // Legacy cache written by a pre-stamp build (the 47→48 case).
        try seedCache(catalog(titled: "Legacy Tour"), in: dir, version: nil)
        let loader = RemoteCatalogLoader(fetcher: StubFetcher(result: .success(Data())),
                                         bundle: emptyBundle,
                                         cacheDirectory: dir,
                                         appVersion: Self.testVersion)

        XCTAssertNil(loader.loadLocal())
        XCTAssertFalse(cacheExists(in: dir))
    }

    func test_loadLocal_keepsCache_whenAppVersionMatches() throws {
        let dir = makeTempDir()
        try seedCache(catalog(titled: "Matching Tour"), in: dir, version: Self.testVersion)
        let loader = RemoteCatalogLoader(fetcher: StubFetcher(result: .success(Data())),
                                         bundle: emptyBundle,
                                         cacheDirectory: dir,
                                         appVersion: Self.testVersion)

        XCTAssertEqual(loader.loadLocal()?.tours.first?.title, "Matching Tour")
        XCTAssertTrue(cacheExists(in: dir))
    }

    // MARK: - refresh (success / caching)

    func test_refresh_returnsAndCachesCatalog_onValidResponse() async throws {
        let dir = makeTempDir()
        let payload = try JSONEncoder().encode(catalog(titled: "Network Tour"))
        let loader = RemoteCatalogLoader(fetcher: StubFetcher(result: .success(payload)),
                                         bundle: emptyBundle,
                                         cacheDirectory: dir,
                                         appVersion: Self.testVersion)

        let fresh = await loader.refresh()

        XCTAssertEqual(fresh?.tours.first?.title, "Network Tour")
        // The fetched catalog is now cached and read back by loadLocal.
        XCTAssertTrue(cacheExists(in: dir))
        XCTAssertEqual(loader.loadLocal()?.tours.first?.title, "Network Tour")
    }

    func test_refresh_returnsNil_andDoesNotCache_onFetchError() async {
        let dir = makeTempDir()
        let loader = RemoteCatalogLoader(fetcher: StubFetcher(result: .failure(URLError(.notConnectedToInternet))),
                                         bundle: emptyBundle,
                                         cacheDirectory: dir,
                                         retryPolicy: .none,
                                         appVersion: Self.testVersion)

        let fresh = await loader.refresh()

        XCTAssertNil(fresh)
        XCTAssertFalse(cacheExists(in: dir))
    }

    func test_refresh_returnsNil_andDoesNotCache_onUndecodableData() async {
        let dir = makeTempDir()
        let loader = RemoteCatalogLoader(fetcher: StubFetcher(result: .success(Data("not json".utf8))),
                                         bundle: emptyBundle,
                                         cacheDirectory: dir,
                                         retryPolicy: .none,
                                         appVersion: Self.testVersion)

        let fresh = await loader.refresh()

        XCTAssertNil(fresh)
        XCTAssertFalse(cacheExists(in: dir))
    }

    // MARK: - refresh (retry + backoff)

    func test_refresh_succeeds_afterTransientFailures() async throws {
        let dir = makeTempDir()
        let payload = try JSONEncoder().encode(catalog(titled: "Eventual Tour"))
        let fetcher = SequenceFetcher(failures: 2,
                                      error: URLError(.timedOut),
                                      success: payload)
        let loader = RemoteCatalogLoader(fetcher: fetcher,
                                         bundle: emptyBundle,
                                         cacheDirectory: dir,
                                         retryPolicy: fastRetry(maxAttempts: 3),
                                         appVersion: Self.testVersion)

        let fresh = await loader.refresh()

        XCTAssertEqual(fresh?.tours.first?.title, "Eventual Tour")
        let calls = await fetcher.callCount
        XCTAssertEqual(calls, 3, "Should fail twice then succeed on the third attempt")
        XCTAssertTrue(cacheExists(in: dir))
    }

    func test_refresh_givesUpAfterMaxAttempts_andLeavesLocalIntact() async throws {
        let dir = makeTempDir()
        try seedCache(catalog(titled: "Good Local"), in: dir)
        let fetcher = SequenceFetcher(failures: .max,
                                      error: URLError(.timedOut),
                                      success: Data())
        let loader = RemoteCatalogLoader(fetcher: fetcher,
                                         bundle: emptyBundle,
                                         cacheDirectory: dir,
                                         retryPolicy: fastRetry(maxAttempts: 3),
                                         appVersion: Self.testVersion)

        let fresh = await loader.refresh()

        XCTAssertNil(fresh)
        let calls = await fetcher.callCount
        XCTAssertEqual(calls, 3, "Should try exactly maxAttempts times before giving up")
        // The good local copy is preserved — never clobbered on failure.
        XCTAssertEqual(loader.loadLocal()?.tours.first?.title, "Good Local")
    }

    func test_refresh_doesNotRetry_onClean4xx() async {
        let dir = makeTempDir()
        let fetcher = SequenceFetcher(failures: .max,
                                      error: CatalogFetchError.httpStatus(404),
                                      success: Data())
        let loader = RemoteCatalogLoader(fetcher: fetcher,
                                         bundle: emptyBundle,
                                         cacheDirectory: dir,
                                         retryPolicy: fastRetry(maxAttempts: 3),
                                         appVersion: Self.testVersion)

        let fresh = await loader.refresh()

        XCTAssertNil(fresh)
        let calls = await fetcher.callCount
        XCTAssertEqual(calls, 1, "A clean 4xx is not transient — give up immediately")
    }

    func test_refresh_retries_onServerError() async throws {
        let dir = makeTempDir()
        let payload = try JSONEncoder().encode(catalog(titled: "Recovered Tour"))
        let fetcher = SequenceFetcher(failures: 2,
                                      error: CatalogFetchError.httpStatus(503),
                                      success: payload)
        let loader = RemoteCatalogLoader(fetcher: fetcher,
                                         bundle: emptyBundle,
                                         cacheDirectory: dir,
                                         retryPolicy: fastRetry(maxAttempts: 3),
                                         appVersion: Self.testVersion)

        let fresh = await loader.refresh()

        XCTAssertEqual(fresh?.tours.first?.title, "Recovered Tour")
        let calls = await fetcher.callCount
        XCTAssertEqual(calls, 3, "5xx is transient — retry until it recovers")
    }

    // MARK: - DataService integration

    func test_dataService_loadsLocalCatalog_withoutAutoRefresh() throws {
        let dir = makeTempDir()
        try seedCache(catalog(titled: "Seeded Tour"), in: dir)
        let loader = RemoteCatalogLoader(fetcher: StubFetcher(result: .success(Data())),
                                         bundle: emptyBundle,
                                         cacheDirectory: dir,
                                         appVersion: Self.testVersion)

        let service = DataService(loader: loader, autoRefresh: false)

        XCTAssertEqual(service.tours.first?.title, "Seeded Tour")
        XCTAssertEqual(service.makers.count, 1)
    }

    func test_dataService_refresh_appliesNetworkCatalog() async throws {
        let dir = makeTempDir()
        let payload = try JSONEncoder().encode(catalog(titled: "Fresh Tour"))
        let loader = RemoteCatalogLoader(fetcher: StubFetcher(result: .success(payload)),
                                         bundle: emptyBundle,
                                         cacheDirectory: dir,
                                         appVersion: Self.testVersion)
        // No local copy and no auto-refresh → starts empty.
        let service = DataService(loader: loader, autoRefresh: false)
        XCTAssertTrue(service.tours.isEmpty)

        await service.refresh()

        XCTAssertEqual(service.tours.first?.title, "Fresh Tour")
    }

    // MARK: - DataService foreground-refresh debounce

    func test_refreshOnForeground_debouncesWithinInterval() async throws {
        let dir = makeTempDir()
        let payload = try JSONEncoder().encode(catalog(titled: "Foreground Tour"))
        let fetcher = SequenceFetcher(failures: 0,
                                      error: URLError(.timedOut),
                                      success: payload)
        let loader = RemoteCatalogLoader(fetcher: fetcher,
                                         bundle: emptyBundle,
                                         cacheDirectory: dir,
                                         appVersion: Self.testVersion)
        let service = DataService(loader: loader,
                                  autoRefresh: false,
                                  foregroundRefreshInterval: 60)

        let t0 = Date(timeIntervalSince1970: 1000)
        await service.refreshOnForeground(now: t0)                         // runs → fetch #1
        await service.refreshOnForeground(now: t0.addingTimeInterval(30))  // debounced
        await service.refreshOnForeground(now: t0.addingTimeInterval(90))  // runs → fetch #2

        let calls = await fetcher.callCount
        XCTAssertEqual(calls, 2, "Refresh within the interval is debounced; past it runs again")
        XCTAssertEqual(service.tours.first?.title, "Foreground Tour")
    }
}
