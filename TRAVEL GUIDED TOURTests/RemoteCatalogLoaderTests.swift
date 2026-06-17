import XCTest
@testable import TRAVEL_GUIDED_TOUR

final class RemoteCatalogLoaderTests: XCTestCase {

    // MARK: - Helpers

    /// A bundle guaranteed to NOT contain a `Tours.json` resource, so the
    /// bundle fallback path resolves to nil in tests (lets us isolate the
    /// cache-vs-bundle priority deterministically).
    private var emptyBundle: Bundle { Bundle(for: RemoteCatalogLoaderTests.self) }

    private struct StubFetcher: CatalogFetching {
        let result: Result<Data, Error>
        func fetchData(from url: URL) async throws -> Data {
            try result.get()
        }
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

    private func seedCache(_ data: ToursData, in dir: URL) throws {
        let encoded = try JSONEncoder().encode(data)
        try encoded.write(to: dir.appendingPathComponent("Tours.cache.json"))
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
                                         cacheDirectory: dir)

        let local = loader.loadLocal()

        XCTAssertEqual(local?.tours.first?.title, "Cached Tour")
    }

    func test_loadLocal_returnsNil_whenNoCacheAndNoBundleResource() {
        let loader = RemoteCatalogLoader(fetcher: StubFetcher(result: .success(Data())),
                                         bundle: emptyBundle,
                                         cacheDirectory: makeTempDir())

        XCTAssertNil(loader.loadLocal())
    }

    // MARK: - refresh

    func test_refresh_returnsAndCachesCatalog_onValidResponse() async throws {
        let dir = makeTempDir()
        let payload = try JSONEncoder().encode(catalog(titled: "Network Tour"))
        let loader = RemoteCatalogLoader(fetcher: StubFetcher(result: .success(payload)),
                                         bundle: emptyBundle,
                                         cacheDirectory: dir)

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
                                         cacheDirectory: dir)

        let fresh = await loader.refresh()

        XCTAssertNil(fresh)
        XCTAssertFalse(cacheExists(in: dir))
    }

    func test_refresh_returnsNil_andDoesNotCache_onUndecodableData() async {
        let dir = makeTempDir()
        let loader = RemoteCatalogLoader(fetcher: StubFetcher(result: .success(Data("not json".utf8))),
                                         bundle: emptyBundle,
                                         cacheDirectory: dir)

        let fresh = await loader.refresh()

        XCTAssertNil(fresh)
        XCTAssertFalse(cacheExists(in: dir))
    }

    // MARK: - DataService integration

    func test_dataService_loadsLocalCatalog_withoutAutoRefresh() throws {
        let dir = makeTempDir()
        try seedCache(catalog(titled: "Seeded Tour"), in: dir)
        let loader = RemoteCatalogLoader(fetcher: StubFetcher(result: .success(Data())),
                                         bundle: emptyBundle,
                                         cacheDirectory: dir)

        let service = DataService(loader: loader, autoRefresh: false)

        XCTAssertEqual(service.tours.first?.title, "Seeded Tour")
        XCTAssertEqual(service.makers.count, 1)
    }

    func test_dataService_refresh_appliesNetworkCatalog() async throws {
        let dir = makeTempDir()
        let payload = try JSONEncoder().encode(catalog(titled: "Fresh Tour"))
        let loader = RemoteCatalogLoader(fetcher: StubFetcher(result: .success(payload)),
                                         bundle: emptyBundle,
                                         cacheDirectory: dir)
        // No local copy and no auto-refresh → starts empty.
        let service = DataService(loader: loader, autoRefresh: false)
        XCTAssertTrue(service.tours.isEmpty)

        await service.refresh()

        XCTAssertEqual(service.tours.first?.title, "Fresh Tour")
    }
}
