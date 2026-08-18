import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// `Place.ranked` decides what a place page shows first. Owner decision
/// 2026-08-18 was "newest first", explicitly provisional — but newest alone
/// does not order the real catalog, because both tours at a place are almost
/// always published in the same city batch and their dates tie exactly (22 of
/// the 24 places today). These tests pin the tiebreaks that make the order
/// deterministic rather than incidental.
final class PlaceRankingTests: XCTestCase {

    private func tour(
        _ title: String,
        created: String?,
        kind: TourKind = .single
    ) -> Tour {
        TestFixtures.makeTour(title: title, kind: kind, createdAt: created)
    }

    func test_newestFirst() {
        let older = tour("OLDER", created: "2026-01-01")
        let newer = tour("NEWER", created: "2026-08-01")
        XCTAssertEqual(Place.ranked([older, newer]).map(\.title), ["NEWER", "OLDER"])
    }

    /// The case that actually occurs: same batch, same date.
    func test_sameDate_singleStopBeatsWalk() {
        let walk = tour("A WALK", created: "2026-07-28", kind: .multiStop)
        let single = tour("THE LANDMARK", created: "2026-07-28", kind: .single)
        XCTAssertEqual(
            Place.ranked([walk, single]).map(\.title),
            ["THE LANDMARK", "A WALK"],
            "someone standing at the landmark wants the tour about it first"
        )
    }

    /// Order must not depend on the order the array happened to arrive in.
    func test_sameDate_resultIsIndependentOfInputOrder() {
        let walk = tour("A WALK", created: "2026-07-28", kind: .multiStop)
        let single = tour("THE LANDMARK", created: "2026-07-28", kind: .single)
        XCTAssertEqual(Place.ranked([walk, single]).map(\.title),
                       Place.ranked([single, walk]).map(\.title))
    }

    func test_sameDateSameKind_fallsBackToTitle() {
        let b = tour("BRAVO", created: "2026-07-28")
        let a = tour("ALPHA", created: "2026-07-28")
        XCTAssertEqual(Place.ranked([b, a]).map(\.title), ["ALPHA", "BRAVO"])
    }

    /// A tour with no date sorts last rather than winning by accident — an
    /// absent `createdAt` is unknown, not new.
    func test_missingDateSortsLast() {
        let dated = tour("DATED", created: "2026-01-01")
        let undated = tour("UNDATED", created: nil)
        XCTAssertEqual(Place.ranked([undated, dated]).map(\.title), ["DATED", "UNDATED"])
    }

    func test_emptyAndSingleInputsAreSafe() {
        XCTAssertTrue(Place.ranked([]).isEmpty)
        XCTAssertEqual(Place.ranked([tour("ONE", created: nil)]).map(\.title), ["ONE"])
    }
}
