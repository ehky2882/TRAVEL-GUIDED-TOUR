import CoreLocation
import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// The sort shared by the maker page and the place page.
///
/// The load-bearing property is **stability**. `Array.sorted` is not stable,
/// and a place's tours almost always share a publication date exactly, so an
/// unstable sort would discard `Place.ranked`'s tiebreaks the moment the page
/// ordered by its own default — see `PlaceRankingTests` for what those
/// tiebreaks are and why they matter.
final class AtlasTourSortTests: XCTestCase {

    private func sorted(
        _ tours: [Tour],
        by criterion: AtlasTourSort,
        ascending: Bool,
        from location: CLLocation? = nil
    ) -> [String] {
        AtlasTourSort.sorted(tours, by: criterion, ascending: ascending, from: location)
            .map(\.title)
    }

    // MARK: - Stability

    func test_tiedTours_keepTheOrderTheyArrivedIn() {
        // Every tour published in the same city batch — the real catalog case.
        let incoming = ["Ranked first", "Ranked second", "Ranked third"].map {
            TestFixtures.makeTour(title: $0, createdAt: "2026-08-18")
        }

        XCTAssertEqual(
            sorted(incoming, by: .dateAdded, ascending: false),
            ["Ranked first", "Ranked second", "Ranked third"]
        )
        // …and in the other direction too: a tie is a tie, not a reversal.
        XCTAssertEqual(
            sorted(incoming, by: .dateAdded, ascending: true),
            ["Ranked first", "Ranked second", "Ranked third"]
        )
    }

    func test_noLocationFix_leavesDistanceOrderExactlyAsItCame() {
        let incoming = ["B", "A", "C"].map { TestFixtures.makeTour(title: $0) }
        XCTAssertEqual(sorted(incoming, by: .distance, ascending: true), ["B", "A", "C"])
    }

    // MARK: - The criteria

    func test_name_sortsBothWays_caseInsensitively() {
        let tours = ["banana", "Apple", "cherry"].map { TestFixtures.makeTour(title: $0) }
        XCTAssertEqual(sorted(tours, by: .name, ascending: true), ["Apple", "banana", "cherry"])
        XCTAssertEqual(sorted(tours, by: .name, ascending: false), ["cherry", "banana", "Apple"])
    }

    func test_duration_sortsBothWays() {
        // stopCount drives totalDurationSeconds in the fixture.
        let short = TestFixtures.makeTour(title: "Short", stopCount: 1)
        let long = TestFixtures.makeTour(title: "Long", stopCount: 3)
        XCTAssertEqual(sorted([long, short], by: .duration, ascending: true), ["Short", "Long"])
        XCTAssertEqual(sorted([short, long], by: .duration, ascending: false), ["Long", "Short"])
    }

    func test_dateAdded_sortsBothWays() {
        let older = TestFixtures.makeTour(title: "Older", createdAt: "2024-01-01")
        let newer = TestFixtures.makeTour(title: "Newer", createdAt: "2026-01-01")
        XCTAssertEqual(sorted([older, newer], by: .dateAdded, ascending: false), ["Newer", "Older"])
        XCTAssertEqual(sorted([newer, older], by: .dateAdded, ascending: true), ["Older", "Newer"])
    }

    /// An unknown date is not an old one, so it sorts last whichever way the
    /// reader has pointed the list.
    func test_aTourWithNoDate_sortsLast_inBothDirections() {
        let dated = TestFixtures.makeTour(title: "Dated", createdAt: "2026-01-01")
        let undated = TestFixtures.makeTour(title: "Undated", createdAt: nil)

        XCTAssertEqual(sorted([undated, dated], by: .dateAdded, ascending: false), ["Dated", "Undated"])
        XCTAssertEqual(sorted([undated, dated], by: .dateAdded, ascending: true), ["Dated", "Undated"])
    }

    func test_distance_sortsBothWays_fromTheReader() {
        let here = CLLocation(latitude: 40.7484, longitude: -73.9857)
        let near = TestFixtures.makeTour(title: "Near", latitude: 40.7485, longitude: -73.9857)
        let far = TestFixtures.makeTour(title: "Far", latitude: 40.8484, longitude: -73.9857)

        XCTAssertEqual(sorted([far, near], by: .distance, ascending: true, from: here), ["Near", "Far"])
        XCTAssertEqual(sorted([near, far], by: .distance, ascending: false, from: here), ["Far", "Near"])
    }

    // MARK: - Sorting something richer than a Tour

    /// The list page carries `(item, tour)` pairs, because a row needs the
    /// curator's note as well as the tour. Same comparator, same stability.
    func test_sortingPairs_ordersByTheirTour_andStaysStable() {
        struct Pair { let note: String; let tour: Tour }
        let pairs = [
            Pair(note: "first note", tour: TestFixtures.makeTour(title: "B", createdAt: "2026-08-18")),
            Pair(note: "second note", tour: TestFixtures.makeTour(title: "A", createdAt: "2026-08-18")),
            Pair(note: "third note", tour: TestFixtures.makeTour(title: "C", createdAt: "2026-08-18"))
        ]

        let byName = AtlasTourSort.sorted(
            pairs, by: .name, ascending: true, from: nil, tour: \.tour
        )
        XCTAssertEqual(byName.map(\.tour.title), ["A", "B", "C"])
        XCTAssertEqual(byName.map(\.note), ["second note", "first note", "third note"],
                       "the note must travel with its tour")

        // Every date ties, so the curator's arrangement survives untouched.
        let byDate = AtlasTourSort.sorted(
            pairs, by: .dateAdded, ascending: false, from: nil, tour: \.tour
        )
        XCTAssertEqual(byDate.map(\.tour.title), ["B", "A", "C"])
    }

    // MARK: - The menu's own rules

    func test_dateAdded_opensNewestFirst_everythingElseAscending() {
        XCTAssertFalse(AtlasTourSort.dateAdded.defaultAscending)
        for criterion in [AtlasTourSort.name, .duration, .distance] {
            XCTAssertTrue(criterion.defaultAscending, "\(criterion) should open ascending")
        }
    }

    func test_labels_readInTheReadersWords_notAscendingDescending() {
        XCTAssertEqual(AtlasTourSort.name.label(ascending: true), "A–Z")
        XCTAssertEqual(AtlasTourSort.name.label(ascending: false), "Z–A")
        XCTAssertEqual(AtlasTourSort.dateAdded.label(ascending: false), "Newest")
        XCTAssertEqual(AtlasTourSort.duration.label(ascending: true), "Shortest")
        XCTAssertEqual(AtlasTourSort.distance.label(ascending: true), "Nearest")
    }
}
