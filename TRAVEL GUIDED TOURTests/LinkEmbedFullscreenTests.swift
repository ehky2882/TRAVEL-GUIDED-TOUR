import XCTest
import WebKit
@testable import TRAVEL_GUIDED_TOUR

/// Covers the rule that decides whether a link pin's embedded player has the
/// bottom module withdrawn.
///
/// The bug: TikTok and YouTube pins render the platform's own player in a
/// `WKWebView`, and its fullscreen control puts that player into element
/// fullscreen **in the main window** — while the mini-player and tab bar live
/// in a separate `PassThroughWindow` one level above it. The module therefore
/// painted across the bottom of a "fullscreen" video. Nothing in
/// `LinkEmbedView` had ever observed `fullscreenState`.
///
/// `withdrawsBottomModule(for:)` is the extracted, pure half of the fix, so
/// the mapping can be pinned without a live `WKWebView` or a window scene.
@MainActor
final class LinkEmbedFullscreenTests: XCTestCase {

    func test_inFullscreen_withdrawsModule() {
        XCTAssertTrue(LinkEmbedView.withdrawsBottomModule(for: .inFullscreen))
    }

    func test_notInFullscreen_keepsModule() {
        XCTAssertFalse(LinkEmbedView.withdrawsBottomModule(for: .notInFullscreen))
    }

    /// The module has to be gone BEFORE the player finishes growing, or the
    /// bars are painted across the opening frames of the animation — the bug
    /// in miniature.
    func test_enteringFullscreen_withdrawsModuleAlready() {
        XCTAssertTrue(LinkEmbedView.withdrawsBottomModule(for: .enteringFullscreen))
    }

    /// ...and may only come back once it has finished shrinking, for the same
    /// reason at the other end.
    func test_exitingFullscreen_restoresModuleAlready() {
        XCTAssertFalse(LinkEmbedView.withdrawsBottomModule(for: .exitingFullscreen))
    }

    /// 🔴 The asymmetry that matters. The two failure directions are not
    /// equal: painting the bars over a fullscreen video is a cosmetic defect,
    /// while failing to bring them back loses the tab bar and the mini-player
    /// for the rest of the session with no way to get them back. Every state
    /// this rule does not recognise must therefore resolve to "show them".
    func test_everyRecognisedState_isTotal_andDefaultsToShowing() {
        let known: [WKWebView.FullscreenState] = [
            .enteringFullscreen, .inFullscreen, .exitingFullscreen, .notInFullscreen
        ]
        // Every state the rule withdraws for is one of the two fullscreen ones;
        // nothing else may ever withdraw.
        for state in known where LinkEmbedView.withdrawsBottomModule(for: state) {
            XCTAssertTrue(state == .enteringFullscreen || state == .inFullscreen)
        }
        // And the pair that must restore genuinely does, so a future state
        // added by WebKit lands on the safe side via `@unknown default`.
        XCTAssertFalse(LinkEmbedView.withdrawsBottomModule(for: .exitingFullscreen))
        XCTAssertFalse(LinkEmbedView.withdrawsBottomModule(for: .notInFullscreen))
    }

    // MARK: - The restore-on-disappear race (the half #611 shipped without)

    /// 🔴 THE REGRESSION THIS PINS. `onDisappear` does not mean "this page
    /// went away" — SwiftUI fires it for a page that is merely **covered**, and
    /// entering element fullscreen covers the tour page. #611 restored the
    /// module there unconditionally, so whenever that restore landed after the
    /// embed's one-runloop-turn-late hide, the bars came straight back on top
    /// of the fullscreen video: the very bug #611 set out to fix, reappearing
    /// intermittently once the main thread was busy enough to lose the race.
    ///
    /// `MakerView` already carries the identical guard for the identical reason
    /// (a `fullScreenCover` firing `onDisappear` on the wizard's covered page).
    func test_moduleAlreadyWithdrawn_doesNotRestoreOnDisappear() {
        XCTAssertFalse(
            TourDetailView.restoresBottomModuleOnDisappear(moduleHidden: true)
        )
    }

    /// The ordinary path, and the one that must never regress: a page closing
    /// with nothing withdrawn still restores. That call is a no-op today, but it
    /// is the belt that makes a missed hide free rather than permanent.
    func test_moduleVisible_restoresOnDisappear() {
        XCTAssertTrue(
            TourDetailView.restoresBottomModuleOnDisappear(moduleHidden: false)
        )
    }

    /// The two halves compose: whatever the embed reports, the page's
    /// `onDisappear` must never be the thing that undoes an active withdrawal.
    /// Written as the full round trip so a future change to either rule alone
    /// fails here rather than on a phone.
    func test_everyFullscreenState_thatWithdraws_suppressesTheDisappearRestore() {
        let states: [WKWebView.FullscreenState] = [
            .enteringFullscreen, .inFullscreen, .exitingFullscreen, .notInFullscreen
        ]
        for state in states {
            let withdrawn = LinkEmbedView.withdrawsBottomModule(for: state)
            XCTAssertEqual(
                TourDetailView.restoresBottomModuleOnDisappear(moduleHidden: withdrawn),
                !withdrawn,
                "state \(state) must suppress the restore exactly when it withdraws"
            )
        }
    }

    // MARK: - The window route (what actually fires on TikTok/YouTube)

    private static let screen = CGSize(width: 393, height: 852)

    /// 🔴 THE ONE THAT MUST NEVER REGRESS. Hiding the module makes its own
    /// window post `didBecomeHidden`; if that counted as "left fullscreen" the
    /// restore would undo the hide immediately, every time, forever.
    func test_ourOwnModuleWindow_isNeverTreatedAsVideoFullscreen() {
        XCTAssertFalse(LinkEmbedView.isVideoFullscreenWindow(
            className: "PassThroughWindow",
            isOurModuleWindow: true,
            size: Self.screen,
            screen: Self.screen
        ))
    }

    /// The keyboard gets a full-size window too. Typing in the search field
    /// must not read as a video going fullscreen.
    func test_keyboardWindow_isNotVideoFullscreen() {
        for name in ["UIRemoteKeyboardWindow", "UITextEffectsWindow"] {
            XCTAssertFalse(LinkEmbedView.isVideoFullscreenWindow(
                className: name,
                isOurModuleWindow: false,
                size: Self.screen,
                screen: Self.screen
            ), "\(name) must not count")
        }
    }

    func test_fullScreenForeignWindow_isVideoFullscreen() {
        XCTAssertTrue(LinkEmbedView.isVideoFullscreenWindow(
            className: "UIWindow",
            isOurModuleWindow: false,
            size: Self.screen,
            screen: Self.screen
        ))
    }

    /// A small transient window is not a video. The threshold is deliberately
    /// generous (90%) because a fullscreen video window can be inset slightly.
    func test_smallWindow_isNotVideoFullscreen() {
        XCTAssertFalse(LinkEmbedView.isVideoFullscreenWindow(
            className: "UIWindow",
            isOurModuleWindow: false,
            size: CGSize(width: 393, height: 300),
            screen: Self.screen
        ))
    }

    /// A zero-sized screen must not divide the world into "everything counts".
    func test_degenerateScreen_isNotVideoFullscreen() {
        XCTAssertFalse(LinkEmbedView.isVideoFullscreenWindow(
            className: "UIWindow",
            isOurModuleWindow: false,
            size: Self.screen,
            screen: .zero
        ))
    }
}
