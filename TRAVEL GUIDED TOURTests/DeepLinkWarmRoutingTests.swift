import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// Covers `DeepLink.needsClearing`, the decision a link that arrives while
/// the app is already running makes before it presents: does whatever is on
/// screen have to come down first, or would the new page land on top anyway?
/// (Owner report, 2026-11-27: tour and creator links did nothing when DOZENT
/// was already open.)
final class DeepLinkWarmRoutingTests: XCTestCase {

    private let tourA = UUID(uuidString: "17050c9f-27a2-45e2-9e69-3ae9528c66c9")!
    private let tourB = UUID(uuidString: "00000000-0000-0000-0000-0000000000b0")!
    private let makerA = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private let placeA = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    private let listA = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!

    // MARK: - Nothing in the way

    func test_nothingOpen_needsNoClearing() {
        let screen = DeepLinkScreenState()
        XCTAssertFalse(DeepLink.tour(tourA).needsClearing(screen))
        XCTAssertFalse(DeepLink.maker(makerA).needsClearing(screen))
        XCTAssertFalse(DeepLink.place(placeA).needsClearing(screen))
        XCTAssertFalse(DeepLink.list(listA).needsClearing(screen))
    }

    func test_samePageAlreadyShowing_needsNoClearing() {
        XCTAssertFalse(DeepLink.tour(tourA).needsClearing(.init(tourId: tourA)))
        XCTAssertFalse(DeepLink.maker(makerA).needsClearing(.init(makerId: makerA)))
        XCTAssertFalse(DeepLink.place(placeA).needsClearing(.init(placeId: placeA)))
        let listTarget = TourListTarget.list(id: listA, preloaded: nil).id
        XCTAssertFalse(DeepLink.list(listA).needsClearing(.init(listTargetId: listTarget)))
    }

    // MARK: - Something in the way

    func test_differentTourOpen_needsClearing() {
        XCTAssertTrue(DeepLink.tour(tourA).needsClearing(.init(tourId: tourB)))
    }

    func test_creatorLink_overOpenTour_needsClearing() {
        XCTAssertTrue(DeepLink.maker(makerA).needsClearing(.init(tourId: tourA)))
    }

    func test_tourLink_overOpenCreator_needsClearing() {
        XCTAssertTrue(DeepLink.tour(tourA).needsClearing(.init(makerId: makerA)))
    }

    /// The link's own page is open, but another layer sits over it, so it is
    /// not what the user is looking at.
    func test_samePageUnderAnotherLayer_needsClearing() {
        XCTAssertTrue(DeepLink.tour(tourA).needsClearing(.init(tourId: tourA, makerId: makerA)))
    }

    func test_fullPlayerUp_needsClearing_evenWithNothingElseOpen() {
        XCTAssertTrue(DeepLink.tour(tourA).needsClearing(.init(fullPlayerUp: true)))
        XCTAssertTrue(DeepLink.maker(makerA).needsClearing(.init(makerId: makerA, fullPlayerUp: true)))
    }

    // MARK: - Group Listen

    /// A join code opens no page, so it never takes the user's screen away.
    func test_groupJoin_neverClears() {
        let busy = DeepLinkScreenState(tourId: tourA, makerId: makerA, fullPlayerUp: true)
        XCTAssertFalse(DeepLink.group("K7QP2").needsClearing(busy))
    }
}
