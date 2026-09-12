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

    /// Answers with a fixed token (or throws), counting calls so tests can
    /// assert the probe ran — and that the big fetch did not.
    private actor StubVersionProbe: CatalogVersionProbing {
        private let result: Result<String, Error>
        private(set) var callCount = 0

        init(_ result: Result<String, Error>) { self.result = result }

        func fetchVersion() async throws -> String {
            callCount += 1
            return try result.get()
        }
    }

    /// Writes the catalog-version sidecar the loader compares the probe against.
    private func seedCatalogVersion(_ token: String, in dir: URL) throws {
        try token.write(to: dir.appendingPathComponent("Tours.cache.catalogVersion"),
                        atomically: true, encoding: .utf8)
    }

    private func storedCatalogVersion(in dir: URL) -> String? {
        try? String(contentsOf: dir.appendingPathComponent("Tours.cache.catalogVersion"),
                    encoding: .utf8)
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

    // MARK: - Multi-source fallback (Supabase → gh-pages)

    func test_refresh_fallsBackToSecondSource_whenFirstFails() async throws {
        let dir = makeTempDir()
        let fallbackPayload = try JSONEncoder().encode(catalog(titled: "Fallback Tour"))
        // Primary source: a clean 4xx (not retryable) → exhausted in one try.
        let primary = CatalogSource(
            fetcher: StubFetcher(result: .failure(CatalogFetchError.httpStatus(500))),
            url: URL(string: "https://primary.example/rpc")!)
        let fallback = CatalogSource(
            fetcher: StubFetcher(result: .success(fallbackPayload)),
            url: URL(string: "https://fallback.example/Tours.json")!)
        let loader = RemoteCatalogLoader(sources: [primary, fallback],
                                         bundle: emptyBundle,
                                         cacheDirectory: dir,
                                         retryPolicy: .none,
                                         appVersion: Self.testVersion)

        let fresh = await loader.refresh()

        XCTAssertEqual(fresh?.tours.first?.title, "Fallback Tour",
                       "When the primary source fails, the fallback is used")
        XCTAssertTrue(cacheExists(in: dir))
    }

    func test_refresh_usesFirstSource_andSkipsRest_whenItSucceeds() async throws {
        let dir = makeTempDir()
        let primaryPayload = try JSONEncoder().encode(catalog(titled: "Primary Tour"))
        let primary = CatalogSource(
            fetcher: StubFetcher(result: .success(primaryPayload)),
            url: URL(string: "https://primary.example/rpc")!)
        // Fallback counts calls so we can assert it was never reached.
        let fallbackFetcher = SequenceFetcher(failures: 0,
                                              error: URLError(.timedOut),
                                              success: Data())
        let fallback = CatalogSource(fetcher: fallbackFetcher,
                                     url: URL(string: "https://fallback.example/Tours.json")!)
        let loader = RemoteCatalogLoader(sources: [primary, fallback],
                                         bundle: emptyBundle,
                                         cacheDirectory: dir,
                                         retryPolicy: .none,
                                         appVersion: Self.testVersion)

        let fresh = await loader.refresh()

        XCTAssertEqual(fresh?.tours.first?.title, "Primary Tour")
        let fallbackCalls = await fallbackFetcher.callCount
        XCTAssertEqual(fallbackCalls, 0, "The fallback is not touched once the primary succeeds")
    }

    func test_refresh_returnsNil_whenAllSourcesFail() async throws {
        let dir = makeTempDir()
        try seedCache(catalog(titled: "Good Local"), in: dir)
        let s1 = CatalogSource(
            fetcher: StubFetcher(result: .failure(URLError(.timedOut))),
            url: URL(string: "https://primary.example/rpc")!)
        let s2 = CatalogSource(
            fetcher: StubFetcher(result: .failure(URLError(.notConnectedToInternet))),
            url: URL(string: "https://fallback.example/Tours.json")!)
        let loader = RemoteCatalogLoader(sources: [s1, s2],
                                         bundle: emptyBundle,
                                         cacheDirectory: dir,
                                         retryPolicy: .none,
                                         appVersion: Self.testVersion)

        let fresh = await loader.refresh()

        XCTAssertNil(fresh)
        // The good local copy survives a total network failure.
        XCTAssertEqual(loader.loadLocal()?.tours.first?.title, "Good Local")
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

    // MARK: - Catalog version check (ask 34 bytes before downloading 3.4 MB)

    func test_refresh_skipsFetch_whenServerVersionMatchesCachedVersion() async throws {
        let dir = makeTempDir()
        try seedCache(catalog(titled: "Already Current"), in: dir)
        try seedCatalogVersion("2026-09-09T02:39:52.269656+00:00", in: dir)
        // If this fetcher is ever called the test fails on the call count, and
        // the payload it would return is deliberately a different catalog.
        let otherPayload = try JSONEncoder().encode(catalog(titled: "Downloaded"))
        let fetcher = SequenceFetcher(failures: 0,
                                      error: URLError(.timedOut),
                                      success: otherPayload)
        let probe = StubVersionProbe(.success("2026-09-09T02:39:52.269656+00:00"))
        let loader = RemoteCatalogLoader(
            sources: [CatalogSource(fetcher: fetcher,
                                    url: URL(string: "https://primary.example/rpc")!,
                                    versionProbe: probe)],
            bundle: emptyBundle,
            cacheDirectory: dir,
            retryPolicy: .none,
            appVersion: Self.testVersion)

        let fresh = await loader.refresh()

        XCTAssertEqual(fresh?.tours.first?.title, "Already Current",
                       "The cached catalog is returned, not a download")
        let probeCalls = await probe.callCount
        XCTAssertEqual(probeCalls, 1)
        let fetchCalls = await fetcher.callCount
        XCTAssertEqual(fetchCalls, 0, "A matching version must skip the catalog fetch entirely")
    }

    func test_refresh_downloads_whenVersionMatchesButCacheIsMissing() async throws {
        let dir = makeTempDir()
        // Version sidecar present, catalog cache absent — a matching token with
        // nothing to show must still download, or the app renders nothing.
        try seedCatalogVersion("v1", in: dir)
        let payload = try JSONEncoder().encode(catalog(titled: "Downloaded"))
        let fetcher = SequenceFetcher(failures: 0, error: URLError(.timedOut), success: payload)
        let loader = RemoteCatalogLoader(
            sources: [CatalogSource(fetcher: fetcher,
                                    url: URL(string: "https://primary.example/rpc")!,
                                    versionProbe: StubVersionProbe(.success("v1")))],
            bundle: emptyBundle,
            cacheDirectory: dir,
            retryPolicy: .none,
            appVersion: Self.testVersion)

        let fresh = await loader.refresh()

        XCTAssertEqual(fresh?.tours.first?.title, "Downloaded")
        let fetchCalls = await fetcher.callCount
        XCTAssertEqual(fetchCalls, 1)
    }

    func test_refresh_downloads_whenVersionMatchesButCacheIsCorrupt() async throws {
        let dir = makeTempDir()
        try Data("{ not json".utf8).write(to: dir.appendingPathComponent("Tours.cache.json"))
        try Self.testVersion.write(to: dir.appendingPathComponent("Tours.cache.version"),
                                   atomically: true, encoding: .utf8)
        try seedCatalogVersion("v1", in: dir)
        let payload = try JSONEncoder().encode(catalog(titled: "Downloaded"))
        let loader = RemoteCatalogLoader(
            sources: [CatalogSource(fetcher: StubFetcher(result: .success(payload)),
                                    url: URL(string: "https://primary.example/rpc")!,
                                    versionProbe: StubVersionProbe(.success("v1")))],
            bundle: emptyBundle,
            cacheDirectory: dir,
            retryPolicy: .none,
            appVersion: Self.testVersion)

        let fresh = await loader.refresh()

        XCTAssertEqual(fresh?.tours.first?.title, "Downloaded",
                       "An unreadable cache must download despite a matching version")
    }

    func test_refresh_downloadsAndStoresVersion_whenVersionDiffers() async throws {
        let dir = makeTempDir()
        try seedCache(catalog(titled: "Stale Local"), in: dir)
        try seedCatalogVersion("v1", in: dir)
        let payload = try JSONEncoder().encode(catalog(titled: "New Content"))
        let loader = RemoteCatalogLoader(
            sources: [CatalogSource(fetcher: StubFetcher(result: .success(payload)),
                                    url: URL(string: "https://primary.example/rpc")!,
                                    versionProbe: StubVersionProbe(.success("v2")))],
            bundle: emptyBundle,
            cacheDirectory: dir,
            retryPolicy: .none,
            appVersion: Self.testVersion)

        let fresh = await loader.refresh()

        XCTAssertEqual(fresh?.tours.first?.title, "New Content")
        XCTAssertEqual(storedCatalogVersion(in: dir), "v2",
                       "The new version is stamped on the catalog we actually decoded")
    }

    func test_refresh_downloads_whenProbeFails() async throws {
        let dir = makeTempDir()
        try seedCache(catalog(titled: "Stale Local"), in: dir)
        try seedCatalogVersion("v1", in: dir)
        let payload = try JSONEncoder().encode(catalog(titled: "New Content"))
        let fetcher = SequenceFetcher(failures: 0, error: URLError(.timedOut), success: payload)
        let loader = RemoteCatalogLoader(
            sources: [CatalogSource(fetcher: fetcher,
                                    url: URL(string: "https://primary.example/rpc")!,
                                    versionProbe: StubVersionProbe(.failure(URLError(.timedOut))))],
            bundle: emptyBundle,
            cacheDirectory: dir,
            retryPolicy: .none,
            appVersion: Self.testVersion)

        let fresh = await loader.refresh()

        XCTAssertEqual(fresh?.tours.first?.title, "New Content",
                       "A failed probe must fail TOWARD downloading — never block content")
        let fetchCalls = await fetcher.callCount
        XCTAssertEqual(fetchCalls, 1)
        XCTAssertNil(storedCatalogVersion(in: dir),
                     "With no answer from the probe, no version is claimed for the new cache")
    }

    func test_refresh_doesNotAdvanceStoredVersion_whenDownloadFails() async throws {
        let dir = makeTempDir()
        try seedCache(catalog(titled: "Good Local"), in: dir)
        try seedCatalogVersion("v1", in: dir)
        let loader = RemoteCatalogLoader(
            sources: [CatalogSource(fetcher: StubFetcher(result: .failure(URLError(.timedOut))),
                                    url: URL(string: "https://primary.example/rpc")!,
                                    versionProbe: StubVersionProbe(.success("v2")))],
            bundle: emptyBundle,
            cacheDirectory: dir,
            retryPolicy: .none,
            appVersion: Self.testVersion)

        let fresh = await loader.refresh()

        XCTAssertNil(fresh)
        XCTAssertEqual(storedCatalogVersion(in: dir), "v1",
                       "A version we never successfully downloaded must not be recorded")
        XCTAssertEqual(loader.loadLocal()?.tours.first?.title, "Good Local")
    }

    func test_refresh_fallsBackToMirror_andClearsStoredVersion_whenSupabaseIsDown() async throws {
        let dir = makeTempDir()
        try seedCache(catalog(titled: "Stale Local"), in: dir)
        try seedCatalogVersion("v1", in: dir)
        let mirrorPayload = try JSONEncoder().encode(catalog(titled: "Mirror Tour"))
        let primary = CatalogSource(
            fetcher: StubFetcher(result: .failure(CatalogFetchError.httpStatus(503))),
            url: URL(string: "https://primary.example/rpc")!,
            versionProbe: StubVersionProbe(.failure(URLError(.cannotConnectToHost))))
        // The gh-pages mirror publishes no version — it has no probe.
        let mirror = CatalogSource(fetcher: StubFetcher(result: .success(mirrorPayload)),
                                   url: URL(string: "https://fallback.example/Tours.json")!)
        let loader = RemoteCatalogLoader(sources: [primary, mirror],
                                         bundle: emptyBundle,
                                         cacheDirectory: dir,
                                         retryPolicy: .none,
                                         appVersion: Self.testVersion)

        let fresh = await loader.refresh()

        XCTAssertEqual(fresh?.tours.first?.title, "Mirror Tour", "The mirror path is unchanged")
        XCTAssertNil(storedCatalogVersion(in: dir),
                     "The mirror's copy must not inherit Supabase's token, or a later probe " +
                     "would match it and pin the app to the mirror's content")
    }

    func test_refresh_skipsMirror_whenSupabaseSaysWeAreCurrent() async throws {
        let dir = makeTempDir()
        try seedCache(catalog(titled: "Already Current"), in: dir)
        try seedCatalogVersion("v1", in: dir)
        let primary = CatalogSource(
            fetcher: StubFetcher(result: .success(Data())),
            url: URL(string: "https://primary.example/rpc")!,
            versionProbe: StubVersionProbe(.success("v1")))
        let mirrorFetcher = SequenceFetcher(failures: 0, error: URLError(.timedOut), success: Data())
        let mirror = CatalogSource(fetcher: mirrorFetcher,
                                   url: URL(string: "https://fallback.example/Tours.json")!)
        let loader = RemoteCatalogLoader(sources: [primary, mirror],
                                         bundle: emptyBundle,
                                         cacheDirectory: dir,
                                         retryPolicy: .none,
                                         appVersion: Self.testVersion)

        let fresh = await loader.refresh()

        XCTAssertEqual(fresh?.tours.first?.title, "Already Current")
        let mirrorCalls = await mirrorFetcher.callCount
        XCTAssertEqual(mirrorCalls, 0,
                       "\"Up to date\" must stop the source chain — falling through would " +
                       "download the whole mirror to learn what we already knew")
    }
}
