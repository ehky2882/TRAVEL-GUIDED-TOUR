import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// The "Because you saved …" rail.
///
/// ⚠️ MOST OF THIS FILE IS ABOUT THE RAIL **NOT** APPEARING. A personalised
/// rail that shows up empty, or under a heading naming a tour whose
/// suggestions were all filtered away, is worse than no rail — it reads as a
/// bug on the first screen of the app. The happy path is one test; the silences
/// are the rest.
final class BecauseYouSavedRailTests: XCTestCase {

    private func tour(_ title: String) -> Tour {
        TestFixtures.makeTour(title: title)
    }

    private func rails(
        _ tours: [Tour],
        saved: [UUID],
        related: @escaping (Tour) -> [Tour]
    ) -> [HomeRail] {
        HomeRailsViewModel.rails(
            tours: tours,
            recentlyViewedIds: [],
            userLocation: nil,
            visibleRegion: nil,
            savedTourIds: saved,
            relatedTours: related
        )
    }

    private func savedRail(_ rails: [HomeRail]) -> HomeRail? {
        rails.first { $0.id.hasPrefix("becauseYouSaved.") }
    }

    // MARK: - It appears, and names the right tour

    func testNamesTheMostRecentlySavedTourThatHasSuggestions() {
        let seed = tour("Trellick Tower")
        let older = tour("Something Saved Long Ago")
        let suggestion = tour("Balfron Tower")
        let result = rails(
            [seed, older, suggestion],
            // Most recent first, which is the contract the call site honours.
            saved: [seed.id, older.id],
            related: { $0.id == seed.id ? [suggestion] : [] }
        )
        let rail = savedRail(result)
        XCTAssertEqual(rail?.title, "Because you saved Trellick Tower")
        XCTAssertEqual(rail?.tours.map(\.title), ["Balfron Tower"])
    }

    /// 🔴 The seed with no neighbours must not produce an empty rail — it must
    /// be skipped so a later saved tour can seed one instead.
    func testFallsPastASeedWithNoSuggestions() {
        let barren = tour("Nothing Relates To This")
        let seed = tour("Trellick Tower")
        let suggestion = tour("Balfron Tower")
        let result = rails(
            [barren, seed, suggestion],
            saved: [barren.id, seed.id],
            related: { $0.id == seed.id ? [suggestion] : [] }
        )
        XCTAssertEqual(savedRail(result)?.title, "Because you saved Trellick Tower")
    }

    // MARK: - 🔴 It stays away

    func testAbsentWhenNothingIsSaved() {
        // Hoisted out of the closure: calling the helper inside one would need
        // an explicit `self`, which says nothing useful here.
        let suggestion = tour("B")
        let result = rails([tour("A")], saved: [], related: { _ in [suggestion] })
        XCTAssertNil(savedRail(result))
    }

    func testAbsentWhenNoSavedTourHasSuggestions() {
        let a = tour("A"), b = tour("B")
        let result = rails([a, b], saved: [a.id, b.id], related: { _ in [] })
        XCTAssertNil(savedRail(result))
    }

    /// Suggesting something already saved is the rail telling you about a tour
    /// you already have — and if that is all it has, it should say nothing.
    func testExcludesToursAlreadySavedAndVanishesIfThatEmptiesIt() {
        let seed = tour("Trellick Tower")
        let alsoSaved = tour("Balfron Tower")
        let result = rails(
            [seed, alsoSaved],
            saved: [seed.id, alsoSaved.id],
            related: { $0.id == seed.id ? [alsoSaved] : [] }
        )
        XCTAssertNil(savedRail(result))
    }

    /// The caller may not pass a resolver at all — every existing call site
    /// does exactly that, and must keep working untouched.
    func testAbsentWhenNoResolverIsProvided() {
        let a = tour("A")
        let result = HomeRailsViewModel.rails(
            tours: [a], recentlyViewedIds: [], userLocation: nil, visibleRegion: nil,
            savedTourIds: [a.id]
        )
        XCTAssertNil(savedRail(result))
    }

    func testASavedIdMissingFromTheCatalogIsSkippedNotCrashed() {
        let seed = tour("Trellick Tower")
        let suggestion = tour("Balfron Tower")
        let result = rails(
            [seed, suggestion],
            saved: [UUID(), seed.id],          // a stale id from an older catalogue
            related: { $0.id == seed.id ? [suggestion] : [] }
        )
        XCTAssertEqual(savedRail(result)?.title, "Because you saved Trellick Tower")
    }
}
