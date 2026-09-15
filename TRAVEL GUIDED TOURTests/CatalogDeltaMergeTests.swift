import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// `CatalogDeltaMerge` is pure, so it is tested directly rather than through
/// the loader. The loader's own guards are covered in
/// `RemoteCatalogLoaderDeltaTests`.
final class CatalogDeltaMergeTests: XCTestCase {

    // MARK: - Helpers

    private func json(_ object: [String: Any]) -> Data {
        try! JSONSerialization.data(withJSONObject: object)
    }

    private func object(_ data: Data) -> [String: Any] {
        try! JSONSerialization.jsonObject(with: data) as! [String: Any]
    }

    private func ids(_ data: Data, _ section: String) -> [String] {
        (object(data)[section] as? [[String: Any]] ?? []).compactMap { $0["id"] as? String }
    }

    private func cachedCatalog() -> Data {
        json([
            "makers": [["id": "m1", "displayName": "One"]],
            "tours": [["id": "t1", "title": "Alpha"],
                      ["id": "t2", "title": "Beta"],
                      ["id": "t3", "title": "Gamma"]],
            "linkPins": [["id": "p1", "title": "Pin"]],
            "places": [["id": "pl1", "name": "Place"]],
        ])
    }

    // MARK: - The merge itself

    func testReplacesByIDInPlaceKeepingOrder() throws {
        let delta = json(["rev": 42, "tours": [["id": "t2", "title": "Beta EDITED"]]])
        let result = try CatalogDeltaMerge.merge(cached: cachedCatalog(), delta: delta)

        XCTAssertEqual(ids(result.data, "tours"), ["t1", "t2", "t3"],
                       "a replacement must not reorder the catalogue")
        let tours = object(result.data)["tours"] as! [[String: Any]]
        XCTAssertEqual(tours[1]["title"] as? String, "Beta EDITED")
        XCTAssertEqual(result.rev, 42)
        XCTAssertEqual(result.applied, 1)
    }

    func testAppendsUnknownIDs() throws {
        let delta = json(["rev": 43, "tours": [["id": "t4", "title": "Delta"]]])
        let result = try CatalogDeltaMerge.merge(cached: cachedCatalog(), delta: delta)
        XCTAssertEqual(ids(result.data, "tours"), ["t1", "t2", "t3", "t4"])
    }

    func testRemovedIDsAreDropped() throws {
        let delta = json(["rev": 44, "removedIds": ["t2"]])
        let result = try CatalogDeltaMerge.merge(cached: cachedCatalog(), delta: delta)
        XCTAssertEqual(ids(result.data, "tours"), ["t1", "t3"])
        XCTAssertEqual(result.removed, 1)
    }

    /// 🔴 The reason this merges raw JSON instead of `ToursData`.
    ///
    /// A key the current build does not model must survive a merge untouched.
    /// Decoding to `ToursData` and re-encoding would delete it, and nothing
    /// would report that it had gone — which is precisely how `places`,
    /// `priceTier` and `isPrivate` disappeared for 14 hours on 2026-08-19.
    func testKeysThisBuildDoesNotModelSurvive() throws {
        let cached = json([
            "makers": [],
            "tours": [["id": "t1", "title": "Alpha", "aFieldFromTheFuture": "keep me"],
                      ["id": "t2", "title": "Beta", "aFieldFromTheFuture": "me too"]],
        ])
        let delta = json(["rev": 7, "tours": [["id": "t2", "title": "Beta EDITED",
                                               "aFieldFromTheFuture": "still here"]]])
        let result = try CatalogDeltaMerge.merge(cached: cached, delta: delta)
        let tours = object(result.data)["tours"] as! [[String: Any]]

        XCTAssertEqual(tours[0]["aFieldFromTheFuture"] as? String, "keep me",
                       "an untouched row must keep every key it had")
        XCTAssertEqual(tours[1]["aFieldFromTheFuture"] as? String, "still here",
                       "a replaced row must keep whatever the SERVER sent for it")
    }

    /// ⚠️ Pin ids are UPPERCASE in `Tours.json` and lowercase out of Postgres
    /// (CLAUDE.md). A case-sensitive match would not error — it would append a
    /// duplicate of every pin on every merge, forever.
    func testIDMatchingIsCaseInsensitive() throws {
        let cached = json(["makers": [], "tours": [["id": "ABC-123", "title": "Alpha"]]])
        let delta = json(["rev": 9, "tours": [["id": "abc-123", "title": "Alpha EDITED"]]])
        let result = try CatalogDeltaMerge.merge(cached: cached, delta: delta)

        let tours = object(result.data)["tours"] as! [[String: Any]]
        XCTAssertEqual(tours.count, 1, "a case difference must not duplicate the row")
        XCTAssertEqual(tours[0]["title"] as? String, "Alpha EDITED")
    }

    func testAllFourSectionsMerge() throws {
        let delta = json([
            "rev": 50,
            "tours": [["id": "t9", "title": "New tour"]],
            "linkPins": [["id": "p9", "title": "New pin"]],
            "makers": [["id": "m9", "displayName": "New maker"]],
            "places": [["id": "pl9", "name": "New place"]],
        ])
        let result = try CatalogDeltaMerge.merge(cached: cachedCatalog(), delta: delta)
        XCTAssertEqual(ids(result.data, "tours"), ["t1", "t2", "t3", "t9"])
        XCTAssertEqual(ids(result.data, "linkPins"), ["p1", "p9"])
        XCTAssertEqual(ids(result.data, "makers"), ["m1", "m9"])
        XCTAssertEqual(ids(result.data, "places"), ["pl1", "pl9"])
        XCTAssertEqual(result.applied, 4)
    }

    /// A catalogue published before the link-pin split has no `linkPins` key.
    /// An empty delta must not invent one.
    func testAbsentSectionIsNotCreatedByAnEmptyDelta() throws {
        let cached = json(["makers": [], "tours": [["id": "t1", "title": "Alpha"]]])
        let delta = json(["rev": 3, "tours": [], "linkPins": []])
        let result = try CatalogDeltaMerge.merge(cached: cached, delta: delta)
        XCTAssertNil(object(result.data)["linkPins"],
                     "an empty delta must not change the catalogue's shape")
    }

    func testEmptyDeltaChangesNothingButStillCarriesTheCursor() throws {
        let delta = json(["rev": 99, "tours": [], "linkPins": [],
                          "makers": [], "places": [], "removedIds": []])
        let result = try CatalogDeltaMerge.merge(cached: cachedCatalog(), delta: delta)
        XCTAssertEqual(result.applied, 0)
        XCTAssertEqual(result.removed, 0)
        XCTAssertEqual(result.rev, 99)
        XCTAssertEqual(ids(result.data, "tours"), ["t1", "t2", "t3"])
    }

    func testRefreshedAtIsCarriedThrough() throws {
        let delta = json(["rev": 12, "refreshedAt": "2026-09-14T20:25:43.016106+00:00"])
        let result = try CatalogDeltaMerge.merge(cached: cachedCatalog(), delta: delta)
        XCTAssertEqual(result.refreshedAt, "2026-09-14T20:25:43.016106+00:00")
    }

    // MARK: - Refusals
    //
    // Each of these must THROW rather than merge something approximate. The
    // caller's rule is "any doubt → full download", and a merge that guesses is
    // worse than one that gives up: the full download always works.

    func testMissingRevThrows() {
        let delta = json(["tours": [["id": "t1", "title": "x"]]])
        XCTAssertThrowsError(try CatalogDeltaMerge.merge(cached: cachedCatalog(), delta: delta)) {
            XCTAssertEqual($0 as? CatalogDeltaMerge.Failure, .missingRev)
        }
    }

    func testSectionThatIsNotAnArrayThrows() {
        let delta = json(["rev": 1, "tours": ["unexpected": "shape"]])
        XCTAssertThrowsError(try CatalogDeltaMerge.merge(cached: cachedCatalog(), delta: delta)) {
            XCTAssertEqual($0 as? CatalogDeltaMerge.Failure, .sectionNotAnArray("tours"))
        }
    }

    func testElementWithoutAnIDThrows() {
        let delta = json(["rev": 1, "tours": [["title": "no id here"]]])
        XCTAssertThrowsError(try CatalogDeltaMerge.merge(cached: cachedCatalog(), delta: delta)) {
            XCTAssertEqual($0 as? CatalogDeltaMerge.Failure, .elementWithoutID("tours"))
        }
    }

    func testNonObjectPayloadsThrow() {
        let array = Data("[1,2,3]".utf8)
        XCTAssertThrowsError(try CatalogDeltaMerge.merge(cached: array,
                                                         delta: json(["rev": 1]))) {
            XCTAssertEqual($0 as? CatalogDeltaMerge.Failure, .cachedNotAnObject)
        }
        XCTAssertThrowsError(try CatalogDeltaMerge.merge(cached: cachedCatalog(),
                                                         delta: array)) {
            XCTAssertEqual($0 as? CatalogDeltaMerge.Failure, .deltaNotAnObject)
        }
    }

    func testGarbageBytesThrowRatherThanCrash() {
        let garbage = Data("not json at all".utf8)
        XCTAssertThrowsError(try CatalogDeltaMerge.merge(cached: cachedCatalog(), delta: garbage))
    }

    /// The merged bytes must still decode as a catalogue — the whole exchange is
    /// pointless if they do not.
    func testMergedBytesDecodeAsToursData() throws {
        let cached = json([
            "makers": [["id": "11111111-1111-1111-1111-111111111111",
                        "displayName": "Maker", "bio": "b"]],
            "tours": [],
        ])
        let delta = json(["rev": 5, "makers": [["id": "11111111-1111-1111-1111-111111111111",
                                                "displayName": "Renamed", "bio": "b"]]])
        let result = try CatalogDeltaMerge.merge(cached: cached, delta: delta)
        let decoded = try JSONDecoder().decode(ToursData.self, from: result.data)
        XCTAssertEqual(decoded.makers.first?.displayName, "Renamed")
        XCTAssertTrue(decoded.losses.isEmpty)
    }
}
