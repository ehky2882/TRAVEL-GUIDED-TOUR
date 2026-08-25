import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// A link pin stands for someone else's post. These pin the two rules that
/// decide whether it is safe: which platform a URL belongs to, and which
/// player to embed for it.
final class LinkPinTests: XCTestCase {

    // MARK: - Platform matching

    /// 🔴 The bug this exists for. The first version asked whether the host's
    /// labels *contained* "tiktok", so `tiktok.evil.com` matched and would have
    /// rendered a pin captioned "OPEN IN TIKTOK" whose embed and whose tap both
    /// went to someone else's server. Only the registrable domain may decide.
    func test_platform_rejectsALookAlikeSubdomain() {
        XCTAssertEqual(LinkSource.from(urlString: "https://tiktok.evil.com/@a/video/1"), .other)
        XCTAssertEqual(LinkSource.from(urlString: "https://nottiktok.com/@a/video/1"), .other)
        XCTAssertEqual(LinkSource.from(urlString: "https://youtube.attacker.net/watch?v=x"), .other)
    }

    func test_platform_matchesTheRealHostsIncludingPrefixes() {
        XCTAssertEqual(LinkSource.from(urlString: "https://www.tiktok.com/@a/video/1"), .tiktok)
        XCTAssertEqual(LinkSource.from(urlString: "https://tiktok.com/@a/video/1"), .tiktok)
        XCTAssertEqual(LinkSource.from(urlString: "https://m.tiktok.com/@a/video/1"), .tiktok)
        XCTAssertEqual(LinkSource.from(urlString: "https://www.youtube.com/watch?v=x"), .youtube)
        XCTAssertEqual(LinkSource.from(urlString: "https://youtu.be/x"), .youtube)
        XCTAssertEqual(LinkSource.from(urlString: "https://www.instagram.com/reel/x/"), .instagram)
    }

    func test_platform_isOtherForRubbish() {
        XCTAssertEqual(LinkSource.from(urlString: "not a url"), .other)
        XCTAssertEqual(LinkSource.from(urlString: "https://localhost/x"), .other)
    }

    // MARK: - Embed URL

    /// TikTok publishes `player/v1/{id}`, which needs no key — verified live
    /// 2026-08-24 (HTTP 200 unauthenticated). It is what lets the post play
    /// inside Atlas rather than throwing the viewer out to another app.
    func test_embed_tiktokUsesThePlayerEndpoint() {
        let url = LinkSource.embedURL(for: "https://www.tiktok.com/@tiktok/video/7106594312292453675")
        XCTAssertEqual(url?.absoluteString,
                       "https://www.tiktok.com/player/v1/7106594312292453675?music_info=1&description=1&rel=0")
    }

    /// The handle, the sound and the caption stay switched on. They are the
    /// platform's own credit to the creator, and stripping them to make the
    /// pin look native would pass someone's work off as ours.
    func test_embed_tiktokKeepsTheCreatorCredit() {
        let url = LinkSource.embedURL(for: "https://www.tiktok.com/@a/video/123")!
        XCTAssertTrue(url.absoluteString.contains("music_info=1"))
        XCTAssertTrue(url.absoluteString.contains("description=1"))
    }

    /// A non-numeric id is not a video id — refuse rather than build a URL
    /// that 404s inside a webview with no way for the viewer to tell why.
    func test_embed_tiktokRefusesANonNumericId() {
        XCTAssertNil(LinkSource.embedURL(for: "https://www.tiktok.com/@a/video/abc"))
        XCTAssertNil(LinkSource.embedURL(for: "https://www.tiktok.com/@a/video/"))
        XCTAssertNil(LinkSource.embedURL(for: "https://www.tiktok.com/@a"))
    }

    func test_embed_youtubeHandlesAllThreeURLShapes() {
        XCTAssertEqual(LinkSource.embedURL(for: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")?.absoluteString,
                       "https://www.youtube.com/embed/dQw4w9WgXcQ?playsinline=1&rel=0")
        XCTAssertEqual(LinkSource.embedURL(for: "https://www.youtube.com/shorts/abc123")?.absoluteString,
                       "https://www.youtube.com/embed/abc123?playsinline=1&rel=0")
        XCTAssertEqual(LinkSource.embedURL(for: "https://youtu.be/xyz789")?.absoluteString,
                       "https://www.youtube.com/embed/xyz789?playsinline=1&rel=0")
    }

    /// `playsinline` is not cosmetic: without it iOS hands playback to the
    /// fullscreen system player, which is exactly the "thrown out of the app"
    /// behaviour the embed exists to avoid.
    func test_embed_youtubeAlwaysAsksForInlinePlayback() {
        let url = LinkSource.embedURL(for: "https://www.youtube.com/shorts/abc")!
        XCTAssertTrue(url.absoluteString.contains("playsinline=1"))
    }

    func test_embed_instagramHandlesPostsAndReels() {
        XCTAssertEqual(LinkSource.embedURL(for: "https://www.instagram.com/p/CODE123/")?.absoluteString,
                       "https://www.instagram.com/p/CODE123/embed")
        XCTAssertEqual(LinkSource.embedURL(for: "https://www.instagram.com/reel/CODE456/")?.absoluteString,
                       "https://www.instagram.com/reel/CODE456/embed")
    }

    /// A look-alike must not merely fail to match — it must produce no embed
    /// at all, so nothing hostile is ever loaded into the webview.
    func test_embed_isNilForAnUnknownHost() {
        XCTAssertNil(LinkSource.embedURL(for: "https://example.com/video/123"))
        XCTAssertNil(LinkSource.embedURL(for: "https://tiktok.evil.com/@a/video/123"))
    }

    // MARK: - The tour's own view of itself

    func test_tour_exposesLinkStateOnlyForALinkPin() {
        let link = TestFixtures.makeTour(
            kind: .link,
            sourceURL: "https://www.tiktok.com/@a/video/123",
            sourceAuthor: "@a"
        )
        XCTAssertTrue(link.isLink)
        XCTAssertEqual(link.linkSource, .tiktok)
        XCTAssertNotNil(link.linkEmbedURL)

        // An ordinary tour must never present as a link pin, even if a stray
        // sourceURL somehow reached it — `isLink` is keyed on kind alone.
        let ordinary = TestFixtures.makeTour(kind: .single,
                                             sourceURL: "https://www.tiktok.com/@a/video/123")
        XCTAssertFalse(ordinary.isLink)
        XCTAssertNil(ordinary.linkSource)
        XCTAssertNil(ordinary.linkEmbedURL)
    }

    /// Vertical posts get a vertical box. Letterboxing a Reel into 16:9 wastes
    /// most of the frame — the same fault the fullscreen video viewer was
    /// built to fix (PR #571).
    func test_embedAspect_isVerticalForTikTokAndReels() {
        XCTAssertEqual(LinkSource.tiktok.embedAspectRatio, 9.0 / 16.0, accuracy: 0.0001)
        XCTAssertEqual(LinkSource.instagram.embedAspectRatio, 9.0 / 16.0, accuracy: 0.0001)
        XCTAssertEqual(LinkSource.youtube.embedAspectRatio, 16.0 / 9.0, accuracy: 0.0001)
    }

    // MARK: - Shorts are vertical, ordinary YouTube videos are not

    /// 🔴 A YouTube **Short** is 9:16, exactly like a TikTok. The shape used to
    /// come from the platform alone, so a Short was framed in the 16:9 box that
    /// suits an ordinary video and its picture filled only `(9/16)^2 = 31.6%`
    /// of the width — YouTube padding the rest with a blurred, stretched copy
    /// of the frame and clipping its own title overlay. Confirmed on screen.
    func test_embedAspect_youtubeShortIsVertical() {
        XCTAssertEqual(LinkSource.embedAspectRatio(for: "https://www.youtube.com/shorts/kSBYbyN17qo"),
                       9.0 / 16.0, accuracy: 0.0001)
    }

    /// The other half of that rule, and the regression that would matter most:
    /// an ordinary video must stay landscape.
    func test_embedAspect_youtubeWatchStaysLandscape() {
        XCTAssertEqual(LinkSource.embedAspectRatio(for: "https://www.youtube.com/watch?v=jNQXAC9IVRw"),
                       16.0 / 9.0, accuracy: 0.0001)
        XCTAssertEqual(LinkSource.embedAspectRatio(for: "https://youtu.be/jNQXAC9IVRw"),
                       16.0 / 9.0, accuracy: 0.0001)
    }

    /// TikTok is unaffected by routing the shape through the URL.
    func test_embedAspect_tiktokUnchangedThroughURLPath() {
        XCTAssertEqual(LinkSource.embedAspectRatio(for: "https://www.tiktok.com/@tiktok/video/7106594312292453675"),
                       9.0 / 16.0, accuracy: 0.0001)
    }

    /// ⚠️ "shorts" is matched as a whole path component, so a channel or video
    /// whose slug merely *starts with* those letters is not mistaken for one.
    /// Same discipline as the registrable-domain fix above.
    func test_isYouTubeShort_matchesWholePathComponentOnly() {
        XCTAssertTrue(LinkSource.isYouTubeShort("https://www.youtube.com/shorts/abc123"))
        XCTAssertFalse(LinkSource.isYouTubeShort("https://www.youtube.com/shortsxyz/abc123"))
        XCTAssertFalse(LinkSource.isYouTubeShort("https://www.youtube.com/watch?v=shorts"))
        XCTAssertFalse(LinkSource.isYouTubeShort("https://www.tiktok.com/@a/video/1"))
    }

    // MARK: - The iframe shell

    /// The shell must actually carry the player it was handed, or the box
    /// renders empty and the failure looks like a dead network.
    func test_shell_embedsTheGivenPlayerURL() {
        let embed = URL(string: "https://www.youtube.com/embed/ID?playsinline=1&rel=0")!
        let html = LinkEmbedView.shell(embed)
        XCTAssertTrue(html.contains("<iframe"))
        XCTAssertTrue(html.contains("https://www.youtube.com/embed/ID?playsinline=1&amp;rel=0"))
        XCTAssertNotNil(LinkEmbedView.embedOrigin)
    }

    /// ⚠️ The shell interpolates a URL into an HTML attribute, which nothing
    /// did before it existed. Nothing hostile can reach it today — every embed
    /// URL is built from a validated id — but the escape is what keeps that
    /// true if a future derivation is looser.
    func test_htmlAttributeEscaped_closesTheAttributeInjectionRoute() {
        let nasty = #"https://x.test/a"onload="alert(1)"#
        let out = LinkEmbedView.htmlAttributeEscaped(nasty)
        XCTAssertFalse(out.contains("\""), "a raw quote would end the src attribute early")
        XCTAssertTrue(out.contains("&quot;"))
        XCTAssertEqual(LinkEmbedView.htmlAttributeEscaped("<b>"), "&lt;b&gt;")
    }

    /// `&` is escaped first, or every escape introduced after it is escaped a
    /// second time and the src arrives as visible `&amp;quot;`.
    func test_htmlAttributeEscaped_doesNotDoubleEscapeAmpersands() {
        XCTAssertEqual(LinkEmbedView.htmlAttributeEscaped("a&b"), "a&amp;b")
        XCTAssertEqual(LinkEmbedView.htmlAttributeEscaped("a\"b"), "a&quot;b")
    }

}
