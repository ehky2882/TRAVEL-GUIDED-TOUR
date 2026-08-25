import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// Pins `SearchView.SearchResults` — the type that exists to stop one search
/// being run many times.
///
/// WHY THIS FILE EXISTS
/// --------------------
/// Owner, 2026-08-21: *"search today is AWFUL. Very laggy."* It was, and the
/// cause was not the matching — it was how often the matching ran.
/// `filteredTours` scans all 1,418 tours, and a SwiftUI computed property is
/// re-evaluated at **every reference**. `resultsList` referenced it three
/// times, one of them inside its own `ForEach`:
///
///     ForEach(filteredTours) { tour in
///         if tour.id != filteredTours.last?.id { Divider() }   // ← per row
///     }
///
/// So the cost was (results + 3) full catalog scans per body evaluation.
/// Typing `"b"` matches 1,416 tours: 1,419 scans, ~2 million tour comparisons,
/// for a single keystroke — worst on the FIRST character typed, which is
/// exactly when a user notices a field going dead.
///
/// The fix is to derive once in `contentArea` and pass this value down. These
/// tests cover the contract that makes that safe; the "only once" part is
/// structural — `resultsList` takes a `SearchResults` and has no access to the
/// computed properties at all.
///
/// ⚠️ If a future change reads `filteredTours` from inside a `ForEach` again,
/// nothing here will fail. Grep for its references instead: it should appear
/// exactly once in the whole file, at the construction site.
final class SearchResultsTests: XCTestCase {

    private func tours(_ n: Int) -> [Tour] {
        (0..<n).map { TestFixtures.makeTour(title: "Tour \($0)") }
    }

    private func makers(_ n: Int) -> [Maker] {
        (0..<n).map {
            TestFixtures.makeMaker(id: UUID(), displayName: "Maker \($0)")
        }
    }

    // MARK: - The cap

    func test_underCap_keepsEveryTour() {
        let all = tours(12)
        let results = SearchView.SearchResults(makers: [], tours: all, cap: 50)

        XCTAssertEqual(results.tours.count, 12)
        XCTAssertEqual(results.totalTours, 12)
        XCTAssertFalse(results.isTruncated,
                       "12 results under a cap of 50 is not truncated")
    }

    func test_overCap_truncatesAndRemembersTheRealTotal() {
        let results = SearchView.SearchResults(makers: [], tours: tours(1416), cap: 50)

        XCTAssertEqual(results.tours.count, 50, "only the cap is rendered")
        XCTAssertEqual(results.totalTours, 1416,
                       "the real total survives, so the footer can be honest")
        XCTAssertTrue(results.isTruncated)
    }

    func test_exactlyAtCap_isNotTruncated() {
        // Off-by-one guard: 50 of 50 must not claim to be hiding anything.
        let results = SearchView.SearchResults(makers: [], tours: tours(50), cap: 50)

        XCTAssertEqual(results.tours.count, 50)
        XCTAssertFalse(results.isTruncated)
    }

    /// 🔴 The cap keeps the BEST results, not an arbitrary 50.
    ///
    /// `filteredTours` returns tours already ranked title → category → maker →
    /// tag → description, so truncating from the front would throw away every
    /// title match. This asserts prefix semantics, not just a count.
    func test_cap_keepsTheHighestRankedResults() {
        let all = tours(200)
        let results = SearchView.SearchResults(makers: [], tours: all, cap: 50)

        XCTAssertEqual(results.tours.map(\.id), all.prefix(50).map(\.id),
                       "the cap must take the leading (best-ranked) results")
    }

    // MARK: - Empty state

    func test_isEmpty_onlyWhenBothAreEmpty() {
        XCTAssertTrue(
            SearchView.SearchResults(makers: [], tours: [], cap: 50).isEmpty)

        XCTAssertFalse(
            SearchView.SearchResults(makers: makers(1), tours: [], cap: 50).isEmpty,
            "a maker match alone is still a result — the empty state must not show")

        XCTAssertFalse(
            SearchView.SearchResults(makers: [], tours: tours(1), cap: 50).isEmpty)
    }

    // MARK: - Makers

    func test_makers_areNotCapped() {
        // 31 makers catalog-wide, so every match fits. Capping them would hide
        // a creator the user typed the name of.
        let all = makers(31)
        let results = SearchView.SearchResults(makers: all, tours: [], cap: 50)

        XCTAssertEqual(results.makers.count, 31)
    }

    // MARK: - Degenerate inputs

    func test_zeroCap_yieldsNoToursButKeepsTheTotal() {
        let results = SearchView.SearchResults(makers: [], tours: tours(10), cap: 0)

        XCTAssertTrue(results.tours.isEmpty)
        XCTAssertEqual(results.totalTours, 10)
        XCTAssertTrue(results.isTruncated)
    }

    func test_resultCap_isPositive() {
        XCTAssertGreaterThan(SearchView.resultCap, 0,
                             "a non-positive cap would render no tours at all")
    }
}
