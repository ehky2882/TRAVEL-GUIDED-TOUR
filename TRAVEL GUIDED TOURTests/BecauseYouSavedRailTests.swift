import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// The "More like what you saved" rail.
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

    /// - Parameter savedSet: everything saved, from BOTH stores. Defaults to
    ///   the seed list, which is what a caller with only Liked would pass.
    private func rails(
        _ tours: [Tour],
        saved: [UUID],
        savedSet: Set<UUID>? = nil,
        related: @escaping (Tour) -> [Tour]
    ) -> [HomeRail] {
        HomeRailsViewModel.rails(
            tours: tours,
            recentlyViewedIds: [],
            userLocation: nil,
            visibleRegion: nil,
            savedTourIds: saved,
            savedTourIdSet: savedSet ?? Set(saved),
            relatedTours: related
        )
    }

    private func savedRail(_ rails: [HomeRail]) -> HomeRail? {
        rails.first { $0.id == HomeRailsViewModel.savedRailID }
    }

    // MARK: - It appears, and names the right tour

    func testSeedsFromTheMostRecentlySavedTourThatHasSuggestions() {
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
        XCTAssertEqual(rail?.title, "More like what you saved")
        // ⚠️ The heading no longer names the seed, so the seed's identity is
        // only observable through WHICH suggestions came back. That is the
        // thing worth asserting anyway.
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
        XCTAssertEqual(savedRail(result)?.tours.map(\.title), ["Balfron Tower"],
                       "it should have fallen through to the seed that has neighbours")
    }

    // MARK: - 🔴 The bug the owner found on build 169

    /// A tour filed into a NAMED LIST is saved just as much as a Liked one —
    /// `SaveState`: "a tour is saved when it belongs to at least one list".
    /// The first version of this rail read `LibraryStore` alone, so someone who
    /// files tours into lists saw no rail at all, which is exactly what
    /// happened on a real phone.
    func testSeedsFromATourSavedOnlyInANamedList() {
        let seed = tour("Trellick Tower")
        let suggestion = tour("Balfron Tower")
        let result = rails(
            [seed, suggestion],
            // Nothing in Liked; the seed comes from the list store.
            saved: [seed.id],
            savedSet: [seed.id],
            related: { $0.id == seed.id ? [suggestion] : [] }
        )
        XCTAssertEqual(savedRail(result)?.tours.map(\.title), ["Balfron Tower"],
                       "a tour saved only in a named list must still seed the rail")
    }

    /// The other half of the same mistake: the exclusion must span both stores,
    /// or the rail suggests a tour the user already keeps in a list.
    func testExcludesASuggestionSavedOnlyInANamedList() {
        let seed = tour("Trellick Tower")
        let inAList = tour("Balfron Tower")
        let result = rails(
            [seed, inAList],
            saved: [seed.id],                       // only the seed is a candidate seed
            savedSet: [seed.id, inAList.id],        // but BOTH are saved somewhere
            related: { $0.id == seed.id ? [inAList] : [] }
        )
        XCTAssertNil(savedRail(result), "it suggested something already saved in a list")
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
        XCTAssertEqual(savedRail(result)?.tours.map(\.title), ["Balfron Tower"],
                       "a saved id with no matching tour must be skipped, not fatal")
    }
}
