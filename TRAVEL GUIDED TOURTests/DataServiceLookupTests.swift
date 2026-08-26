import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// `DataService`'s `by id` lookups are backed by dictionaries rather than
/// linear scans, because they are read per row on every body evaluation from
/// the mini-player, the Home drawer and every list row in Library — over a
/// 1,400-tour catalog a scan each made those screens visibly slow.
///
/// The risk indexing introduces is **staleness**: an index that isn't rebuilt
/// when the catalog changes returns nil for a row plainly on screen, which
/// would look like missing content rather than a bug. Most of what follows
/// pins exactly that — that every path which mutates the catalog rebuilds the
/// indexes with it.
@MainActor
final class DataServiceLookupTests: XCTestCase {

    // MARK: - Helpers

    private var emptyBundle: Bundle { Bundle(for: DataServiceLookupTests.self) }

    private struct StubFetcher: CatalogFetching {
        let payload: Data?
        func fetchData(from url: URL) async throws -> Data {
            guard let payload else { throw URLError(.notConnectedToInternet) }
            return payload
        }
    }

    private func makeTempDir() -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Builds a `DataService` whose local catalog is `data` and whose network
    /// refresh returns `remote` (or fails, when nil). `autoRefresh` is off so
    /// loading stays deterministic — tests call `refresh()` themselves.
    private func makeService(local: ToursData, remote: ToursData? = nil) throws -> DataService {
        let dir = makeTempDir()
        let version = "test-build"
        try JSONEncoder().encode(local)
            .write(to: dir.appendingPathComponent("Tours.cache.json"))
        try version.write(to: dir.appendingPathComponent("Tours.cache.version"),
                          atomically: true, encoding: .utf8)
        let payload = try remote.map { try JSONEncoder().encode($0) }
        let loader = RemoteCatalogLoader(fetcher: StubFetcher(payload: payload),
                                         bundle: emptyBundle,
                                         cacheDirectory: dir,
                                         appVersion: version)
        return DataService(loader: loader, autoRefresh: false)
    }

    private func place(named name: String, tourIds: [UUID]) -> Place {
        Place(id: UUID(),
              name: name,
              description: nil,
              latitude: 40.7484,
              longitude: -73.9857,
              city: "New York",
              address: nil,
              heroImageURL: nil,
              additionalImageURLs: nil,
              tourIds: tourIds)
    }

    // MARK: - Lookups resolve

    func test_lookups_resolveEveryEntityInTheLoadedCatalog() throws {
        let maker = TestFixtures.makeMaker(displayName: "Atlas Studio NYC")
        let a = TestFixtures.makeTour(title: "A", makerId: maker.id)
        let b = TestFixtures.makeTour(title: "B", makerId: maker.id)
        let site = place(named: "Dam Square", tourIds: [a.id, b.id])
        let service = try makeService(
            local: ToursData(makers: [maker], tours: [a, b], places: [site])
        )

        XCTAssertEqual(service.tour(by: a.id)?.title, "A")
        XCTAssertEqual(service.tour(by: b.id)?.title, "B")
        XCTAssertEqual(service.maker(by: maker.id)?.displayName, "Atlas Studio NYC")
        XCTAssertEqual(service.maker(for: a)?.id, maker.id)
        XCTAssertEqual(service.place(by: site.id)?.name, "Dam Square")
        // A tour's place still resolves through the tour→place index.
        XCTAssertEqual(service.place(forTourId: b.id)?.id, site.id)
    }

    func test_unknownIds_returnNil() throws {
        let service = try makeService(
            local: ToursData(makers: [TestFixtures.makeMaker()],
                             tours: [TestFixtures.makeTour()])
        )

        XCTAssertNil(service.tour(by: UUID()))
        XCTAssertNil(service.maker(by: UUID()))
        XCTAssertNil(service.place(by: UUID()))
        XCTAssertNil(service.place(forTourId: UUID()))
    }

    // MARK: - Map marker cache

    /// 🔴 THE CACHED MARKERS MUST EQUAL WHAT THE MAP USED TO BUILD ITSELF.
    ///
    /// `HomeMapSection` rebuilt every pin through a computed property, so a
    /// full pass over the catalog ran again in the frame where a camera fly
    /// settles. Markers cannot change unless the catalog does, so they are
    /// built once — and this pins that the cached set is identical to the
    /// live call it replaced.
    func test_stopMarkers_matchTheLiveBuild() throws {
        let maker = TestFixtures.makeMaker()
        let a = TestFixtures.makeTour(title: "A", makerId: maker.id)
        let b = TestFixtures.makeTour(title: "B", makerId: maker.id)
        let c = TestFixtures.makeTour(title: "C", makerId: maker.id)
        let site = place(named: "Dam Square", tourIds: [a.id, b.id])
        let service = try makeService(
            local: ToursData(makers: [maker], tours: [a, b, c], places: [site])
        )

        // ⚠️ NOT `XCTAssertEqual` on the arrays. `StopMarker.==` compares ONLY
        // `id` (see MapClustering), so an array comparison would pass even if
        // every coordinate, title and place count were wrong — a test that
        // looks strong and asserts almost nothing. Compare the fields the map
        // actually draws.
        let cached = service.stopMarkers
        let live = MapMarkers.markers(for: service.tours, places: service.places)

        XCTAssertEqual(cached.count, live.count)
        for (got, want) in zip(cached, live) {
            XCTAssertEqual(got.id, want.id)
            XCTAssertEqual(got.tourId, want.tourId)
            XCTAssertEqual(got.title, want.title)
            XCTAssertEqual(got.coordinate.latitude, want.coordinate.latitude, accuracy: 1e-9)
            XCTAssertEqual(got.coordinate.longitude, want.coordinate.longitude, accuracy: 1e-9)
            XCTAssertEqual(got.placeId, want.placeId)
            XCTAssertEqual(got.placeTourCount, want.placeTourCount)
        }
    }

    /// ⚠️ The rule the cache must not be allowed to break: a place collapses
    /// into ONE pin only when two or more of its tours are present. That is
    /// why `HomeView` passes the cache only when no filter is active — with a
    /// filter on, which pins exist genuinely differs, so the map rebuilds.
    /// This pins the collapsing rule itself, so a future "just filter the
    /// cached markers instead" cannot pass unnoticed.
    func test_stopMarkers_collapseAPlaceOnlyWhenTwoOfItsToursArePresent() throws {
        let maker = TestFixtures.makeMaker()
        let a = TestFixtures.makeTour(title: "A", makerId: maker.id)
        let b = TestFixtures.makeTour(title: "B", makerId: maker.id)
        let both = place(named: "Both", tourIds: [a.id, b.id])
        let lonely = place(named: "Lonely", tourIds: [a.id])

        let collapsed = try makeService(
            local: ToursData(makers: [maker], tours: [a, b], places: [both])
        )
        XCTAssertEqual(collapsed.stopMarkers.filter(\.isPlace).count, 1,
                       "two tours at one site collapse into a single place pin")

        let notCollapsed = try makeService(
            local: ToursData(makers: [maker], tours: [a, b], places: [lonely])
        )
        XCTAssertEqual(notCollapsed.stopMarkers.filter(\.isPlace).count, 0,
                       "a place holding one present tour must NOT collapse")
    }

    /// Same staleness risk as every other index here: a refresh must rebuild
    /// the markers, or the map draws pins for a catalog that is gone.
    func test_stopMarkers_rebuildOnRefresh() async throws {
        let maker = TestFixtures.makeMaker()
        let before = TestFixtures.makeTour(title: "Before", makerId: maker.id)
        let service = try makeService(
            local: ToursData(makers: [maker], tours: [before]),
            remote: ToursData(makers: [maker], tours: [
                before, TestFixtures.makeTour(title: "After", makerId: maker.id)
            ])
        )

        XCTAssertEqual(service.stopMarkers.count, 1)
        await service.refresh()
        XCTAssertEqual(service.stopMarkers.count, 2,
                       "the marker cache must follow the catalog")
    }

    // MARK: - Tag index

    /// 🔴 THE TAG INDEX MUST RETURN EXACTLY WHAT THE OLD FILTER RETURNED.
    ///
    /// The home drawer's thirteen curated shelves used to `filter` the whole
    /// catalog per shelf, on every render — ~39,000 catalog passes in the one
    /// frame where a fly to a searched place settles and everything
    /// re-derives. Membership cannot change without
    /// the catalog changing, so it is indexed. The risk that swap introduces
    /// is a shelf quietly listing different tours, or the same tours in a
    /// different order, so both are pinned here against the filter it replaced.
    func test_toursByTag_matchesTheFilterItReplaced_inCatalogOrder() throws {
        let maker = TestFixtures.makeMaker()
        let first  = TestFixtures.makeTour(title: "First",  makerId: maker.id,
                                           tags: ["Tower", "Art"])
        let other  = TestFixtures.makeTour(title: "Other",  makerId: maker.id,
                                           tags: ["Food"])
        let second = TestFixtures.makeTour(title: "Second", makerId: maker.id,
                                           tags: ["Art"])
        let all = [first, other, second]
        let service = try makeService(local: ToursData(makers: [maker], tours: all))

        for tag in ["Tower", "Art", "Food", "Nonexistent"] {
            XCTAssertEqual(
                service.tours(taggedWith: tag).map(\.title),
                all.filter { $0.tags.contains(tag) }.map(\.title),
                "shelf \"\(tag)\" must match the filter it replaced, in catalog order"
            )
        }
    }

    /// A tour carrying the same tag twice in authored data must appear on that
    /// shelf once. The old `filter` could not duplicate a tour; an index that
    /// appends per tag can.
    func test_toursByTag_doesNotDuplicateATourWithARepeatedTag() throws {
        let maker = TestFixtures.makeMaker()
        let tour = TestFixtures.makeTour(title: "Twice", makerId: maker.id,
                                         tags: ["Art", "Art"])
        let service = try makeService(local: ToursData(makers: [maker], tours: [tour]))

        XCTAssertEqual(service.tours(taggedWith: "Art").map(\.title), ["Twice"])
    }

    /// The staleness risk indexing always carries: a refresh that changes the
    /// catalog must rebuild this index with it, or a shelf renders tours the
    /// catalog no longer has.
    func test_toursByTag_rebuildsOnRefresh() async throws {
        let maker = TestFixtures.makeMaker()
        let before = TestFixtures.makeTour(title: "Before", makerId: maker.id, tags: ["Art"])
        let after  = TestFixtures.makeTour(title: "After",  makerId: maker.id, tags: ["Art"])
        let service = try makeService(
            local: ToursData(makers: [maker], tours: [before]),
            remote: ToursData(makers: [maker], tours: [after])
        )

        XCTAssertEqual(service.tours(taggedWith: "Art").map(\.title), ["Before"])
        await service.refresh()
        XCTAssertEqual(service.tours(taggedWith: "Art").map(\.title), ["After"],
                       "the index must follow the catalog, not outlive it")
    }

    /// The index handed to `HomeRailsViewModel` must agree with the accessor —
    /// they are two doors onto the same data and the shelves read the dict.
    func test_toursByTagIndex_agreesWithTheAccessor() throws {
        let maker = TestFixtures.makeMaker()
        let a = TestFixtures.makeTour(title: "A", makerId: maker.id, tags: ["Tower"])
        let b = TestFixtures.makeTour(title: "B", makerId: maker.id, tags: ["Tower", "Art"])
        let service = try makeService(local: ToursData(makers: [maker], tours: [a, b]))

        for tag in ["Tower", "Art"] {
            XCTAssertEqual(service.toursByTagIndex[tag]?.map(\.title),
                           service.tours(taggedWith: tag).map(\.title))
        }
    }

    /// `tours(by:)` is read by the maker page and by every followed-maker row
    /// in Library just to count. It must keep returning **catalog order**, not
    /// whatever a dictionary happened to hold.
    func test_toursByMaker_returnsOnlyThatMakersTours_inCatalogOrder() throws {
        let nyc = TestFixtures.makeMaker(id: UUID(), displayName: "NYC")
        let ldn = TestFixtures.makeMaker(id: UUID(), displayName: "LDN")
        let first = TestFixtures.makeTour(title: "First", makerId: nyc.id)
        let other = TestFixtures.makeTour(title: "Other", makerId: ldn.id)
        let second = TestFixtures.makeTour(title: "Second", makerId: nyc.id)
        let service = try makeService(
            local: ToursData(makers: [nyc, ldn], tours: [first, other, second])
        )

        XCTAssertEqual(service.tours(by: nyc).map(\.title), ["First", "Second"])
        XCTAssertEqual(service.tours(by: ldn).map(\.title), ["Other"])
    }

    func test_toursByMaker_isEmpty_forAMakerWithNoTours() throws {
        let lonely = TestFixtures.makeMaker(id: UUID(), displayName: "No tours yet")
        let service = try makeService(
            local: ToursData(makers: [lonely], tours: [])
        )

        XCTAssertEqual(service.tours(by: lonely).count, 0)
    }

    // MARK: - Indexes stay in step with the catalog

    /// The trap indexing introduces: a network refresh replaces the catalog, so
    /// the indexes must be rebuilt with it. Stale ones would keep answering for
    /// the *previous* catalog — a tour that has gone would still resolve, and a
    /// newly published one would read as missing.
    func test_refresh_rebuildsIndexes_forTheNewCatalog() async throws {
        let maker = TestFixtures.makeMaker()
        let old = TestFixtures.makeTour(title: "Old", makerId: maker.id)
        let new = TestFixtures.makeTour(title: "New", makerId: maker.id)
        let service = try makeService(
            local: ToursData(makers: [maker], tours: [old]),
            remote: ToursData(makers: [maker], tours: [new])
        )
        XCTAssertNotNil(service.tour(by: old.id))

        await service.refresh()

        XCTAssertEqual(service.tour(by: new.id)?.title, "New")
        XCTAssertNil(service.tour(by: old.id), "a dropped tour must stop resolving")
        XCTAssertEqual(service.tours(by: maker).map(\.title), ["New"])
    }

    func test_refresh_rebuildsPlaceIndexes() async throws {
        let maker = TestFixtures.makeMaker()
        let a = TestFixtures.makeTour(title: "A", makerId: maker.id)
        let b = TestFixtures.makeTour(title: "B", makerId: maker.id)
        let before = place(named: "Before", tourIds: [a.id])
        let after = place(named: "After", tourIds: [a.id, b.id])
        let service = try makeService(
            local: ToursData(makers: [maker], tours: [a, b], places: [before]),
            remote: ToursData(makers: [maker], tours: [a, b], places: [after])
        )
        XCTAssertNil(service.place(forTourId: b.id))

        await service.refresh()

        XCTAssertNil(service.place(by: before.id))
        XCTAssertEqual(service.place(by: after.id)?.name, "After")
        XCTAssertEqual(service.place(forTourId: b.id)?.id, after.id)
    }

    /// `applyLocalMaker` is how a creator's just-saved profile edit reaches the
    /// public maker page before the next catalog refresh. It mutates `makers`,
    /// so it has to refresh the maker index too — otherwise the page would go
    /// on showing the old name it was patched to replace.
    func test_applyLocalMaker_updatesAnExistingMakerInTheIndex() throws {
        let maker = TestFixtures.makeMaker(displayName: "Old name")
        let service = try makeService(
            local: ToursData(makers: [maker], tours: [])
        )

        service.applyLocalMaker(TestFixtures.makeMaker(id: maker.id, displayName: "New name"))

        XCTAssertEqual(service.maker(by: maker.id)?.displayName, "New name")
        XCTAssertEqual(service.makers.count, 1)
    }

    func test_applyLocalMaker_addsABrandNewMakerToTheIndex() throws {
        let existing = TestFixtures.makeMaker(id: UUID(), displayName: "Existing")
        let service = try makeService(
            local: ToursData(makers: [existing], tours: [])
        )
        let fresh = TestFixtures.makeMaker(id: UUID(), displayName: "Fresh")

        service.applyLocalMaker(fresh)

        XCTAssertEqual(service.maker(by: fresh.id)?.displayName, "Fresh")
        XCTAssertEqual(service.maker(by: existing.id)?.displayName, "Existing")
    }

    /// A failed refresh must leave both the catalog and its indexes untouched —
    /// the offline case, where the local copy is all the user has.
    func test_failedRefresh_leavesIndexesIntact() async throws {
        let maker = TestFixtures.makeMaker()
        let tour = TestFixtures.makeTour(title: "Local", makerId: maker.id)
        let service = try makeService(
            local: ToursData(makers: [maker], tours: [tour]),
            remote: nil
        )

        await service.refresh()

        XCTAssertEqual(service.tour(by: tour.id)?.title, "Local")
        XCTAssertEqual(service.tours(by: maker).count, 1)
    }
}
