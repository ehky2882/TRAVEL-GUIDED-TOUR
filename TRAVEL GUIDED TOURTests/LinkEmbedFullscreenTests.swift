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
}
