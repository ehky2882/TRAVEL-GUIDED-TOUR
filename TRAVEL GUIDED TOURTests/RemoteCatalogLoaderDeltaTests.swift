import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// The loader's delta path. `CatalogDeltaMergeTests` covers the merge itself;
/// this covers *when* the loader is willing to use it — which is the half that
/// carries the safety rules from `docs/delta-catalog-fetch-design.md` § Phase 2.
///
/// 🔴 The through-line of every test here: the delta path is an optimisation on
/// top of a full download that already works. Every doubt must end in that
/// download, never in a half-applied catalogue.
final class RemoteCatalogLoaderDeltaTests: XCTestCase {

    private static let testVersion = "test-build"
    private var emptyBundle: Bundle { Bundle(for: RemoteCatalogLoaderDeltaTests.self) }

    // MARK: - Helpers

    private func makeTempDir() -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// A catalogue in the on-the-wire shape, written straight to the cache as
    /// raw bytes — which is how the loader stores it in production.
    private func catalogJSON(tourTitles: [String]) -> Data {
        let tours = tourTitles.enumerated().map { i, title -> [String: Any] in
            ["id": "0000000\(i)-0000-4000-8000-00000000000\(i)",
             "title": title,
             "shortDescription": "s",
             "longDescription": "l",
             "makerId": "11111111-1111-1111-1111-111111111111",
             "heroImageURL": "https://example.test/h.webp",
             "kind": "single",
             "stops": [],
             "totalDurationSeconds": 0,
             "centroidLatitude": 1.0,
             "centroidLongitude": 2.0,
             "primaryCategory": "history",
             "tags": [],
             // Non-optional on `Tour` with no default, so a fixture without it
             // decodes to zero tours and every assertion here becomes vacuous.
             "priceUSD": 0]
        }
        return try! JSONSerialization.data(withJSONObject: [
            "makers": [["id": "11111111-1111-1111-1111-111111111111",
                        "displayName": "Maker", "bio": "b"]],
            "tours": tours,
        ])
    }

    private func seed(_ dir: URL,
                      catalog: Data,
                      appVersion: String? = testVersion,
                      rev: Int64? = nil,
                      token: String? = nil) throws {
        try catalog.write(to: dir.appendingPathComponent("Tours.cache.json"))
        if let appVersion {
            try appVersion.write(to: dir.appendingPathComponent("Tours.cache.version"),
                                 atomically: true, encoding: .utf8)
        }
        if let rev {
            try String(rev).write(to: dir.appendingPathComponent("Tours.cache.rev"),
                                  atomically: true, encoding: .utf8)
        }
        if let token {
            try token.write(to: dir.appendingPathComponent("Tours.cache.catalogVersion"),
                            atomically: true, encoding: .utf8)
        }
    }

    private func storedRev(in dir: URL) -> String? {
        try? String(contentsOf: dir.appendingPathComponent("Tours.cache.rev"), encoding: .utf8)
    }

    private func cachedTitles(in dir: URL) -> [String] {
        guard let data = try? Data(contentsOf: dir.appendingPathComponent("Tours.cache.json")),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tours = object["tours"] as? [[String: Any]] else { return [] }
        return tours.compactMap { $0["title"] as? String }
    }

    /// Always says the catalogue changed, so the loader gets past the version
    /// probe and reaches the delta path.
    private struct ChangedProbe: CatalogVersionProbing {
        let token: String
        func fetchVersion() async throws -> String { token }
    }

    private actor StubDelta: CatalogDeltaFetching {
        private let result: Result<Data, Error>
        private(set) var cursors: [Int64] = []

        init(result: Result<Data, Error>) { self.result = result }

        func fetchDelta(since rev: Int64) async throws -> Data {
            cursors.append(rev)
            return try result.get()
        }
        func recorded() -> [Int64] { cursors }
    }

    private struct FailingFetcher: CatalogFetching {
        func fetchData(from url: URL) async throws -> Data { throw URLError(.notConnectedToInternet) }
    }

    private struct FixedFetcher: CatalogFetching {
        let data: Data
        func fetchData(from url: URL) async throws -> Data { data }
    }

    private func loader(dir: URL,
                        fetcher: CatalogFetching,
                        probe: CatalogVersionProbing?,
                        delta: CatalogDeltaFetching?) -> RemoteCatalogLoader {
        RemoteCatalogLoader(
            sources: [CatalogSource(fetcher: fetcher,
                                    url: RemoteCatalogLoader.remoteURL,
                                    versionProbe: probe,
                                    deltaFetcher: delta)],
            bundle: emptyBundle,
            cacheDirectory: dir,
            retryPolicy: CatalogRetryPolicy(maxAttempts: 1, baseDelay: 0, jitter: 0),
            appVersion: Self.testVersion)
    }

    // MARK: - The happy path

    func testAppliesADeltaAndAdvancesTheCursor() async throws {
        let dir = makeTempDir()
        try seed(dir, catalog: catalogJSON(tourTitles: ["Alpha", "Beta"]),
                 rev: 10, token: "old-token")

        let delta = try! JSONSerialization.data(withJSONObject: [
            "rev": 25,
            "refreshedAt": "2026-09-15T00:00:00+00:00",
            "tours": [["id": "00000001-0000-4000-8000-000000000001",
                       "title": "Beta EDITED",
                       "shortDescription": "s", "longDescription": "l",
                       "makerId": "11111111-1111-1111-1111-111111111111",
                       "heroImageURL": "https://example.test/h.webp",
                       "kind": "single", "stops": [], "totalDurationSeconds": 0,
                       "centroidLatitude": 1.0, "centroidLongitude": 2.0,
                       "primaryCategory": "history", "tags": [], "priceUSD": 0]],
        ])

        // The full fetcher FAILS, so a pass here can only have come from the
        // delta path — there is no way to accidentally credit a download.
        let sut = loader(dir: dir, fetcher: FailingFetcher(),
                         probe: ChangedProbe(token: "new-token"),
                         delta: StubDelta(result: .success(delta)))

        let result = await sut.refresh()
        XCTAssertEqual(result?.tours.count, 2)
        XCTAssertTrue(cachedTitles(in: dir).contains("Beta EDITED"))
        XCTAssertEqual(storedRev(in: dir), "25", "the cursor must advance to the server's")
    }

    func testAsksForTheCursorItHolds() async throws {
        let dir = makeTempDir()
        try seed(dir, catalog: catalogJSON(tourTitles: ["Alpha"]), rev: 77, token: "old")
        let stub = StubDelta(result: .success(
            try! JSONSerialization.data(withJSONObject: ["rev": 78])))

        let sut = loader(dir: dir, fetcher: FailingFetcher(),
                         probe: ChangedProbe(token: "new"), delta: stub)
        _ = await sut.refresh()
        let asked = await stub.recorded()
        XCTAssertEqual(asked.first, 77)
    }

    // MARK: - Any doubt → full download

    func testWithoutAStoredCursorItDownloadsInFull() async throws {
        let dir = makeTempDir()
        // Cache present, but no rev sidecar — there is nothing to be a delta
        // *since*, so the only correct answer is the whole catalogue.
        try seed(dir, catalog: catalogJSON(tourTitles: ["Alpha"]), rev: nil, token: "old")
        let stub = StubDelta(result: .success(
            try! JSONSerialization.data(withJSONObject: ["rev": 5])))

        let sut = loader(dir: dir, fetcher: FixedFetcher(data: catalogJSON(tourTitles: ["Full", "Download"])),
                         probe: ChangedProbe(token: "new"), delta: stub)
        let result = await sut.refresh()

        XCTAssertEqual(result?.tours.count, 2)
        XCTAssertEqual(Set(cachedTitles(in: dir)), ["Full", "Download"])
    }

    func testACacheFromAnotherAppBuildIsNotMergedInto() async throws {
        let dir = makeTempDir()
        try seed(dir, catalog: catalogJSON(tourTitles: ["Alpha"]),
                 appVersion: "some-older-build", rev: 10, token: "old")
        let sut = loader(dir: dir,
                         fetcher: FixedFetcher(data: catalogJSON(tourTitles: ["Fresh"])),
                         probe: ChangedProbe(token: "new"),
                         delta: StubDelta(result: .success(
                            try! JSONSerialization.data(withJSONObject: ["rev": 11]))))
        let result = await sut.refresh()
        XCTAssertEqual(result?.tours.first?.title, "Fresh")
    }

    func testAFailedDeltaFetchFallsBackToTheFullDownload() async throws {
        let dir = makeTempDir()
        try seed(dir, catalog: catalogJSON(tourTitles: ["Alpha"]), rev: 10, token: "old")
        let sut = loader(dir: dir,
                         fetcher: FixedFetcher(data: catalogJSON(tourTitles: ["Fallback"])),
                         probe: ChangedProbe(token: "new"),
                         delta: StubDelta(result: .failure(CatalogFetchError.httpStatus(404))))
        let result = await sut.refresh()
        XCTAssertEqual(result?.tours.first?.title, "Fallback",
                       "a 404 means the RPC is not deployed; that must be invisible to the user")
    }

    func testAnUnmergeableDeltaFallsBackAndLeavesTheCursorAlone() async throws {
        let dir = makeTempDir()
        try seed(dir, catalog: catalogJSON(tourTitles: ["Alpha"]), rev: 10, token: "old")
        // No `rev` in the envelope — the merge refuses it.
        let bad = try! JSONSerialization.data(withJSONObject: ["tours": []])
        let sut = loader(dir: dir,
                         fetcher: FailingFetcher(),
                         probe: ChangedProbe(token: "new"),
                         delta: StubDelta(result: .success(bad)))

        _ = await sut.refresh()
        XCTAssertEqual(storedRev(in: dir), "10",
                       "a merge that did not complete must never advance the cursor")
        XCTAssertEqual(cachedTitles(in: dir), ["Alpha"],
                       "and must leave the cache exactly as it was")
    }

    func testGarbageDeltaBytesDoNotTouchTheCache() async throws {
        let dir = makeTempDir()
        try seed(dir, catalog: catalogJSON(tourTitles: ["Alpha"]), rev: 10, token: "old")
        let sut = loader(dir: dir, fetcher: FailingFetcher(),
                         probe: ChangedProbe(token: "new"),
                         delta: StubDelta(result: .success(Data("<html>nope</html>".utf8))))
        _ = await sut.refresh()
        XCTAssertEqual(storedRev(in: dir), "10")
        XCTAssertEqual(cachedTitles(in: dir), ["Alpha"])
    }

    // MARK: - The cursor and the full download

    /// ⚠️ A full download must CLEAR a cursor it cannot vouch for. Left behind,
    /// it would make the next refresh ask for "everything since N" against a
    /// cache that is not at N, and the rows in between would never arrive.
    func testAFullDownloadFromASourceWithNoDeltaClearsTheCursor() async throws {
        let dir = makeTempDir()
        try seed(dir, catalog: catalogJSON(tourTitles: ["Alpha"]), rev: 10, token: "old")
        let sut = loader(dir: dir,
                         fetcher: FixedFetcher(data: catalogJSON(tourTitles: ["Mirror"])),
                         probe: nil,
                         delta: nil)
        _ = await sut.refresh()
        XCTAssertNil(storedRev(in: dir),
                     "the gh-pages mirror publishes no cursor, so none may be kept")
    }

    /// A full download from a source that DOES offer deltas establishes the
    /// cursor, or the delta path could never engage at all.
    func testAFullDownloadEstablishesTheCursorForNextTime() async throws {
        let dir = makeTempDir()
        let head = try! JSONSerialization.data(withJSONObject: ["rev": 500, "tours": []])
        let sut = loader(dir: dir,
                         fetcher: FixedFetcher(data: catalogJSON(tourTitles: ["First"])),
                         probe: ChangedProbe(token: "t"),
                         delta: StubDelta(result: .success(head)))
        _ = await sut.refresh()
        XCTAssertEqual(storedRev(in: dir), "500")
    }
}
