import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// Covers the rule that decides whether a link pin's embedded player has come
/// up, and the copy shown when it has not.
///
/// The bug: a link pin is an embed — the bytes stream from TikTok, Instagram
/// or YouTube and are never held by us — so on a network where those hosts are
/// unreachable (mainland China blocks all three) the player simply never
/// loaded. `LinkEmbedView` paints its box black so a white flash does not read
/// as breakage, which meant the failure rendered as **a black rectangle,
/// forever**, with no message, no retry and no hint that the network rather
/// than the app was the problem.
///
/// It could not be caught the obvious way. The shell is handed to WebKit with
/// `loadHTMLString`, so the main frame never touches the network and
/// `WKNavigationDelegate`'s failure callbacks cannot fire for a blocked
/// player; the player itself is in a cross-origin iframe we may not script.
/// Failure is therefore inferred from the absence of the iframe's own `load`
/// within a deadline — which is a guess, and the tests below are mostly about
/// making that guess safe to be wrong about.
final class LinkEmbedFailureTests: XCTestCase {

    // MARK: - The transition table

    func test_deadlineExpiringWhileLoading_isTheFailureSignal() {
        XCTAssertEqual(LinkEmbedLoadRule.nextState(.loading, on: .deadlineExpired), .failed)
    }

    func test_frameLoaded_isSuccessFromLoading() {
        XCTAssertEqual(LinkEmbedLoadRule.nextState(.loading, on: .frameLoaded), .loaded)
    }

    /// 🔴 THE ONE THAT MAKES THE DEADLINE SAFE. The message is an overlay above
    /// a player that is still mounted and still loading, so a slow-but-working
    /// network that beats the deadline by arriving late must be able to clear
    /// it. Without this, choosing the deadline a second too short would strand
    /// a viewer on an error message with a working video behind it.
    func test_aLatePlayerClearsTheMessage() {
        XCTAssertEqual(LinkEmbedLoadRule.nextState(.failed, on: .frameLoaded), .loaded)
    }

    /// 🔴 A deadline that outlived the load it was measuring must not be able
    /// to knock out a player that has since come up.
    func test_staleDeadlineCannotUnseatALoadedPlayer() {
        XCTAssertEqual(LinkEmbedLoadRule.nextState(.loaded, on: .deadlineExpired), .loaded)
    }

    /// ...nor re-fail an already-failed one into anything else.
    func test_deadlineIsIdempotentOnFailure() {
        XCTAssertEqual(LinkEmbedLoadRule.nextState(.failed, on: .deadlineExpired), .failed)
    }

    /// A retry has to clear the message, or the button does nothing visible
    /// for twelve seconds and reads as broken.
    func test_retryReturnsToLoading() {
        XCTAssertEqual(LinkEmbedLoadRule.nextState(.failed, on: .loadStarted), .loading)
        XCTAssertEqual(LinkEmbedLoadRule.nextState(.loaded, on: .loadStarted), .loading)
    }

    func test_explicitErrorsFail() {
        XCTAssertEqual(LinkEmbedLoadRule.nextState(.loading, on: .frameError), .failed)
        XCTAssertEqual(LinkEmbedLoadRule.nextState(.loading, on: .mainFrameFailed), .failed)
    }

    /// The table is total: no state/event pair may be undefined, and only the
    /// three failure events may ever produce `.failed`.
    func test_tableIsTotal_andOnlyFailureEventsCanFail() {
        let states: [LinkEmbedLoadState] = [.loading, .loaded, .failed]
        let events: [LinkEmbedLoadEvent] = [
            .loadStarted, .frameLoaded, .frameError, .deadlineExpired, .mainFrameFailed
        ]
        for state in states {
            for event in events {
                let next = LinkEmbedLoadRule.nextState(state, on: event)
                if next == .failed {
                    XCTAssertTrue(
                        event == .frameError || event == .mainFrameFailed
                            || (event == .deadlineExpired && state != .loaded),
                        "\(event) from \(state) must not produce a failure")
                }
            }
        }
    }

    /// Long enough that a normal player handshake cannot lose the race, which
    /// is the only direction that costs a viewer anything real.
    func test_deadlineIsGenerous() {
        XCTAssertGreaterThanOrEqual(LinkEmbedLoadRule.deadline, 8)
    }

    // MARK: - The shell's own reporting channel

    /// The positive signal is relayed by our own shell, so the shell must
    /// actually carry the listener and address the handler the coordinator
    /// registered. A typo here is invisible: every player would simply time
    /// out and every pin would show the failure message.
    func test_shellRelaysTheIframeLoadEvent() {
        let embed = URL(string: "https://www.tiktok.com/player/v1/123")!
        let html = LinkEmbedView.shell(embed)
        XCTAssertTrue(html.contains("messageHandlers.\(LinkEmbedView.messageHandlerName)"))
        XCTAssertTrue(html.contains("addEventListener('load'"))
        XCTAssertTrue(html.contains("id=\"p\""))
    }

    func test_messageBodiesMapToEvents() {
        XCTAssertEqual(LinkEmbedView.loadEvent(forMessageBody: "loaded"), .frameLoaded)
        XCTAssertEqual(LinkEmbedView.loadEvent(forMessageBody: "error"), .frameError)
    }

    /// ⚠️ An unrecognised body is ignored, not treated as a failure. A future
    /// message added to this channel must not be able to blank out a working
    /// player on builds that predate it.
    func test_unknownMessageBodyIsIgnored() {
        XCTAssertNil(LinkEmbedView.loadEvent(forMessageBody: "something-else"))
        XCTAssertNil(LinkEmbedView.loadEvent(forMessageBody: 42))
    }

    // MARK: - What the viewer is told

    func test_copyNamesThePlatformTheVideoActuallyComesFrom() {
        XCTAssertTrue(LinkSource.tiktok.unreachableHeadline.contains("TIKTOK"))
        XCTAssertTrue(LinkSource.instagram.unreachableHeadline.contains("INSTAGRAM"))
        XCTAssertTrue(LinkSource.youtube.unreachableHeadline.contains("YOUTUBE"))
        XCTAssertTrue(LinkSource.tiktok.unreachableDetail.contains("TikTok"))
    }

    /// 🔴 `.other` is reached exactly when `LinkSource.from` did not recognise
    /// the host — so naming any platform there would be a guess presented to
    /// the viewer as fact.
    func test_unknownSourceNamesNoPlatform() {
        for text in [LinkSource.other.unreachableHeadline, LinkSource.other.unreachableDetail] {
            XCTAssertFalse(text.lowercased().contains("tiktok"))
            XCTAssertFalse(text.lowercased().contains("instagram"))
            XCTAssertFalse(text.lowercased().contains("youtube"))
        }
    }

    /// 🔴 We observe a player that did not load. We do NOT know why — a country
    /// or network that blocks the platform, captive-portal wifi, a post gone
    /// private, the platform itself down. Stating a cause we cannot verify is
    /// the same failure mode this project has paid for repeatedly elsewhere.
    func test_copyDoesNotAssertACauseItCannotKnow() {
        for source in [LinkSource.tiktok, .instagram, .youtube, .other] {
            let text = (source.unreachableHeadline + " " + source.unreachableDetail).lowercased()
            XCTAssertTrue(text.contains("can't be reached") || text.contains("wouldn't load"))
            XCTAssertFalse(text.contains("is blocked"))
        }
    }

    /// The one thing a viewer in this situation can actually act on: a tour
    /// they downloaded before arriving still plays, because a downloaded tour
    /// is ours and on their disk. Worth saying, so say it.
    func test_copyPointsAtTheThingThatStillWorks() {
        XCTAssertTrue(LinkSource.tiktok.unreachableDetail.contains("Downloaded tours"))
    }
}
