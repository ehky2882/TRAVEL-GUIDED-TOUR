import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// The one rule for what "saved" means and what a bookmark tap does.
///
/// These pin the consolidation: saving a tour and putting it in a list are the
/// same act, Liked is just the default list, and a tour in several lists is
/// never silently removed from one the user didn't name.
final class SaveStateTests: XCTestCase {

    private let listA = UUID()
    private let listB = UUID()

    // MARK: - isSaved

    func test_isSaved_falseWhenInNothing() {
        XCTAssertFalse(SaveState.isSaved(isLiked: false, listIds: []))
    }

    func test_isSaved_trueWhenOnlyInLiked() {
        XCTAssertTrue(SaveState.isSaved(isLiked: true, listIds: []))
    }

    /// The case the old split got wrong: a tour filed straight into a named
    /// list never counted as saved, so its bookmark read empty.
    func test_isSaved_trueWhenOnlyInANamedList() {
        XCTAssertTrue(SaveState.isSaved(isLiked: false, listIds: [listA]))
    }

    func test_isSaved_trueWhenInBoth() {
        XCTAssertTrue(SaveState.isSaved(isLiked: true, listIds: [listA]))
    }

    // MARK: - placeCount

    func test_placeCount_countsLikedAsAPlace() {
        XCTAssertEqual(SaveState.placeCount(isLiked: false, listIds: []), 0)
        XCTAssertEqual(SaveState.placeCount(isLiked: true, listIds: []), 1)
        XCTAssertEqual(SaveState.placeCount(isLiked: false, listIds: [listA]), 1)
        XCTAssertEqual(SaveState.placeCount(isLiked: true, listIds: [listA, listB]), 3)
    }

    // MARK: - tapAction
    //
    // The tap is ADD-ONLY. It saves into Liked when the tour is in nothing,
    // and otherwise opens the sheet — it never un-saves, even from a single
    // list, because the same gesture that filed a tour shouldn't also be the
    // one that throws it away.

    func test_tap_onUnsavedTour_savesIntoLiked() {
        XCTAssertEqual(SaveState.tapAction(isLiked: false, listIds: []), .addToLiked)
    }

    func test_tap_whenOnlyInLiked_opensTheSheetRatherThanUnsaving() {
        XCTAssertEqual(SaveState.tapAction(isLiked: true, listIds: []), .chooseLists)
    }

    func test_tap_whenInExactlyOneNamedList_opensTheSheetRatherThanRemoving() {
        XCTAssertEqual(SaveState.tapAction(isLiked: false, listIds: [listA]), .chooseLists)
    }

    func test_tap_whenInLikedAndAList_opensTheSheet() {
        XCTAssertEqual(SaveState.tapAction(isLiked: true, listIds: [listA]), .chooseLists)
    }

    func test_tap_whenInManyPlaces_opensTheSheet() {
        XCTAssertEqual(SaveState.tapAction(isLiked: true, listIds: [listA, listB]), .chooseLists)
    }

    /// A tap can never be the thing that removes a save.
    func test_tap_neverUnsaves() {
        let saved: [(Bool, Set<UUID>)] = [
            (true, []), (false, [listA]), (true, [listA]), (false, [listA, listB]),
        ]
        for (liked, lists) in saved {
            XCTAssertEqual(SaveState.tapAction(isLiked: liked, listIds: lists), .chooseLists)
        }
    }

    // MARK: - Signed-out parity

    /// Signed out there are no named lists, so saving still works with no
    /// account: the first tap files into Liked. The second opens the sheet,
    /// where Liked is the only row — so un-saving stays possible offline.
    func test_signedOut_firstTapSavesToLiked_secondOpensTheSheet() {
        XCTAssertFalse(SaveState.isSaved(isLiked: false, listIds: []))
        XCTAssertEqual(SaveState.tapAction(isLiked: false, listIds: []), .addToLiked)

        XCTAssertTrue(SaveState.isSaved(isLiked: true, listIds: []))
        XCTAssertEqual(SaveState.tapAction(isLiked: true, listIds: []), .chooseLists)
    }
}
