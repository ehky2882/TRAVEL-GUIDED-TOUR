import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// The Dozents list is the one panel whose contents are a *decision* rather
/// than a layout — what an empty box shows differs by panel, and a selected
/// Dozent must survive both. `FilterPanelRules` exists so those rules can be
/// checked without a screen.
final class FilterPanelRulesTests: XCTestCase {

    /// 20 Dozents, the first busiest: `M00` has 20 pins, `M19` has 1.
    private func fixture(_ count: Int = 20) -> ([Maker], [UUID: Int]) {
        var makers: [Maker] = []
        var counts: [UUID: Int] = [:]
        for i in 0..<count {
            let maker = TestFixtures.makeMaker(id: UUID(), displayName: String(format: "M%02d", i))
            makers.append(maker)
            counts[maker.id] = count - i
        }
        return (makers, counts)
    }

    private func listed(
        _ makers: [Maker],
        _ counts: [UUID: Int],
        query: String = "",
        selected: Set<UUID> = [],
        lists: Bool = true
    ) -> [String] {
        FilterPanelRules.listedMakers(
            makers, query: query, selected: selected, counts: counts, showsUnsearchedList: lists
        ).map(\.displayName)
    }

    // MARK: - What an empty box shows

    func test_ownPanel_emptyBox_listsTheBusiestTwelveInOrder() {
        let (makers, counts) = fixture()
        let names = listed(makers, counts)
        XCTAssertEqual(names.count, FilterPanelRules.unsearchedLimit)
        XCTAssertEqual(names.first, "M00", "Busiest first")
        XCTAssertEqual(names.last, "M11")
    }

    /// The All panel shows the field and nothing else — twelve avatar rows
    /// there pushed the Tags section off the screen (owner, on device).
    func test_allPanel_emptyBox_listsNothing() {
        let (makers, counts) = fixture()
        XCTAssertEqual(listed(makers, counts, lists: false), [])
    }

    // MARK: - 🔴 A switched-on filter is never hidden

    func test_selectedDozentOutsideTheBusiestTwelve_isStillListed() {
        let (makers, counts) = fixture()
        let quiet = makers[18]                       // 2 pins — nowhere near the top
        let names = listed(makers, counts, selected: [quiet.id])
        XCTAssertTrue(names.contains(quiet.displayName),
                      "Hiding it would leave no way to switch it off but guessing the name")
        XCTAssertEqual(names.count, FilterPanelRules.unsearchedLimit + 1)
        XCTAssertEqual(names.last, quiet.displayName, "Added back in rank order, not pinned to the top")
    }

    func test_allPanel_emptyBox_stillListsASelectedDozent() {
        let (makers, counts) = fixture()
        let chosen = makers[7]
        XCTAssertEqual(listed(makers, counts, selected: [chosen.id], lists: false),
                       [chosen.displayName])
    }

    func test_alreadyListedSelection_isNotDuplicated() {
        let (makers, counts) = fixture()
        let busiest = makers[0]
        let names = listed(makers, counts, selected: [busiest.id])
        XCTAssertEqual(names.count, FilterPanelRules.unsearchedLimit)
        XCTAssertEqual(names.filter { $0 == busiest.displayName }.count, 1)
    }

    // MARK: - Typing

    /// A search that stopped at the busiest twelve would be a search that lies,
    /// so typing reaches every Dozent.
    func test_typing_searchesPastTheOpeningTwelve() {
        let (makers, counts) = fixture()
        XCTAssertEqual(listed(makers, counts, query: "M19"), ["M19"])
    }

    func test_searchIsCaseInsensitiveAndTrimmed() {
        var (makers, counts) = fixture(3)
        let odd = TestFixtures.makeMaker(id: UUID(), displayName: "Studio Gang")
        makers.append(odd)
        counts[odd.id] = 5
        XCTAssertEqual(listed(makers, counts, query: "  gang "), ["Studio Gang"])
    }

    func test_aSelectedNonMatchIsNotForcedIntoSearchResults() {
        let (makers, counts) = fixture()
        let names = listed(makers, counts, query: "M19", selected: [makers[0].id])
        XCTAssertEqual(names, ["M19"], "Searching answers the search, not the selection")
    }

    func test_searchResultsAreCapped() {
        let (makers, counts) = fixture(40)
        XCTAssertEqual(listed(makers, counts, query: "M").count, FilterPanelRules.searchedLimit)
    }

    // MARK: - Order

    func test_tiesFallBackToTheAlphabet() {
        let a = TestFixtures.makeMaker(id: UUID(), displayName: "Zed")
        let b = TestFixtures.makeMaker(id: UUID(), displayName: "Ada")
        let counts = [a.id: 4, b.id: 4]
        XCTAssertEqual(listed([a, b], counts), ["Ada", "Zed"])
    }
}
