import XCTest
import AVFoundation
import UIKit
@testable import TRAVEL_GUIDED_TOUR

/// Covers the three pure rules behind the fullscreen video viewer: what shape
/// a clip is, how far to rotate it, and how big the content stack is once
/// rotated.
///
/// The app is portrait-locked, and rotation here turns the **video**, never
/// the app — `Info.plist` is a ceiling, and the viewer presents from the
/// secondary window whose *scene* is shared with the main window, so a real
/// rotation would turn the map and drawer behind the video too.
///
/// ⚠️ Rotation itself is device-only: the simulator rotates the *interface*,
/// which is precisely the thing this design does not do. These tests pin the
/// arithmetic so the on-device check is only ever confirming the feel.
@MainActor
final class FullscreenVideoRulesTests: XCTestCase {

    // MARK: - Shape, read from the display size

    /// 🔴 The trap this exists for. Phone-shot video is commonly stored
    /// 1920x1080 with a 90 degree `preferredTransform` — it is a VERTICAL
    /// clip. Reading `naturalSize` alone calls it landscape and rotates it
    /// exactly the wrong way.
    func testPortraitClipStoredLandscapeWithRotationTransformIsNotLandscape() {
        let stored = CGSize(width: 1920, height: 1080)
        let quarterTurn = CGAffineTransform(rotationAngle: .pi / 2)
        XCTAssertFalse(
            FullscreenVideoView.isLandscape(naturalSize: stored, preferredTransform: quarterTurn),
            "1920x1080 with a 90 degree transform displays as 1080x1920 — vertical"
        )
    }

    func testLandscapeClipWithIdentityTransformIsLandscape() {
        XCTAssertTrue(
            FullscreenVideoView.isLandscape(
                naturalSize: CGSize(width: 1920, height: 1080),
                preferredTransform: .identity
            )
        )
    }

    /// The catalogue's own vertical stand-in: 1080x1920, no transform.
    func testVerticalClipWithIdentityTransformIsNotLandscape() {
        XCTAssertFalse(
            FullscreenVideoView.isLandscape(
                naturalSize: CGSize(width: 1080, height: 1920),
                preferredTransform: .identity
            )
        )
    }

    /// A landscape clip stored upright with a compensating transform is still
    /// landscape once displayed — the mirror of the first case.
    func testLandscapeClipStoredPortraitWithRotationTransformIsLandscape() {
        XCTAssertTrue(
            FullscreenVideoView.isLandscape(
                naturalSize: CGSize(width: 1080, height: 1920),
                preferredTransform: CGAffineTransform(rotationAngle: .pi / 2)
            )
        )
    }

    /// Square has nothing to gain from turning, so it counts as not-landscape
    /// and stays upright.
    func testSquareClipIsNotLandscape() {
        XCTAssertFalse(
            FullscreenVideoView.isLandscape(
                naturalSize: CGSize(width: 1080, height: 1080),
                preferredTransform: .identity
            )
        )
    }

    /// A 180 degree transform flips signs; the shape must survive that.
    func testHalfTurnTransformKeepsShape() {
        XCTAssertTrue(
            FullscreenVideoView.isLandscape(
                naturalSize: CGSize(width: 1920, height: 1080),
                preferredTransform: CGAffineTransform(rotationAngle: .pi)
            ),
            "a half turn leaves a landscape clip landscape, only mirrored"
        )
    }

    // MARK: - Rotation

    /// 🔴 Vertical clips NEVER rotate. 9:16 is already 393x699 upright —
    /// turning it sideways makes it smaller. Same as TikTok, Reels and Shorts.
    func testVerticalClipNeverRotatesInAnyOrientation() {
        for device: UIDeviceOrientation in [.portrait, .portraitUpsideDown, .landscapeLeft, .landscapeRight, .faceUp, .faceDown, .unknown] {
            XCTAssertEqual(
                FullscreenVideoView.rotationDegrees(clipIsLandscape: false, device: device),
                0,
                "vertical clip must stay upright in \(device.rawValue)"
            )
        }
    }

    /// Held upright, a landscape clip stays upright — otherwise the viewer
    /// would open sideways on a phone nobody has turned.
    func testLandscapeClipUprightWhilePhoneIsPortrait() {
        XCTAssertEqual(
            FullscreenVideoView.rotationDegrees(clipIsLandscape: true, device: .portrait),
            0
        )
    }

    /// Signs, which are easy to invert. `UIDeviceOrientation.landscapeLeft` is
    /// the device held with the home button on the RIGHT — turned
    /// anticlockwise — so the content rotates +90 (clockwise) to stand up.
    func testLandscapeClipRotatesClockwiseWhenDeviceTurnedAnticlockwise() {
        XCTAssertEqual(
            FullscreenVideoView.rotationDegrees(clipIsLandscape: true, device: .landscapeLeft),
            90
        )
    }

    func testLandscapeClipRotatesAnticlockwiseWhenDeviceTurnedClockwise() {
        XCTAssertEqual(
            FullscreenVideoView.rotationDegrees(clipIsLandscape: true, device: .landscapeRight),
            -90
        )
    }

    /// The two landscape orientations must be opposite, or the picture is
    /// upside down in one of them.
    func testTheTwoLandscapeOrientationsAreOpposite() {
        let left = FullscreenVideoView.rotationDegrees(clipIsLandscape: true, device: .landscapeLeft)
        let right = FullscreenVideoView.rotationDegrees(clipIsLandscape: true, device: .landscapeRight)
        XCTAssertEqual(left, -right)
        XCTAssertNotEqual(left, 0)
    }

    /// Face-up, face-down and unknown carry no heading. They must not rotate
    /// anything — a phone laid flat on a table should not flip the picture.
    func testOrientationsWithNoHeadingDoNotRotate() {
        for device: UIDeviceOrientation in [.faceUp, .faceDown, .unknown, .portraitUpsideDown] {
            XCTAssertEqual(
                FullscreenVideoView.rotationDegrees(clipIsLandscape: true, device: device),
                0,
                "\(device.rawValue) carries no usable heading"
            )
        }
    }

    // MARK: - Content sizing

    /// Unrotated, the stack is just the screen.
    func testContentSizeMatchesScreenWhenNotRotated() {
        let screen = CGSize(width: 393, height: 852)
        XCTAssertEqual(FullscreenVideoView.contentSize(screen: screen, rotationDegrees: 0), screen)
    }

    /// Rotated, it takes the screen's dimensions swapped, so the picture fills
    /// the long axis: 852x393 on a 393x852 screen. That is the 2.3x gain over
    /// the 345x259 carousel box that makes rotation worth doing for landscape.
    func testContentSizeSwapsWhenRotated() {
        let screen = CGSize(width: 393, height: 852)
        for angle in [90.0, -90.0] {
            XCTAssertEqual(
                FullscreenVideoView.contentSize(screen: screen, rotationDegrees: angle),
                CGSize(width: 852, height: 393),
                "rotated content lays out along the screen's long axis"
            )
        }
    }

    /// The rotated stack must be strictly larger than the carousel box it came
    /// from, or the whole feature buys nothing.
    func testRotatedLandscapeBeatsTheCarouselBox() {
        let screen = CGSize(width: 393, height: 852)
        let rotated = FullscreenVideoView.contentSize(screen: screen, rotationDegrees: 90)
        // The carousel hero box is 345 wide (393 less two 24pt gutters) at the
        // 4:3 ratio the image pipeline uses.
        let carousel = CGSize(width: 345, height: 345 * 3 / 4)
        XCTAssertGreaterThan(rotated.width * rotated.height, carousel.width * carousel.height)
    }

    // MARK: - Narration handoff

    /// 🔴 The silent path is live today and must keep working: a clip with no
    /// audio track never touches the narration, which keeps playing while the
    /// clip runs as moving imagery — exactly like a photo.
    func testSilentClipNeverTakesNarrationOver() {
        XCTAssertFalse(
            FullscreenVideoView.shouldTakeOverNarration(
                clipHasAudio: false, narrationIsPlaying: true, alreadyOwesResume: false
            )
        )
    }

    /// A clip with sound pauses a playing narration.
    func testClipWithAudioTakesOverPlayingNarration() {
        XCTAssertTrue(
            FullscreenVideoView.shouldTakeOverNarration(
                clipHasAudio: true, narrationIsPlaying: true, alreadyOwesResume: false
            )
        )
    }

    /// A tour the user paused themselves must not be restarted on their
    /// behalf — there is nothing to take over, so nothing is owed back.
    func testDoesNotTakeOverNarrationThatIsNotPlaying() {
        XCTAssertFalse(
            FullscreenVideoView.shouldTakeOverNarration(
                clipHasAudio: true, narrationIsPlaying: false, alreadyOwesResume: false
            )
        )
    }

    /// Idempotent: the debt is taken once. The inline view hands its debt over
    /// on expand, so the fullscreen view can open already owing a resume and
    /// must not pause a second time.
    func testDoesNotTakeOverTwiceWhenDebtAlreadyOwed() {
        XCTAssertFalse(
            FullscreenVideoView.shouldTakeOverNarration(
                clipHasAudio: true, narrationIsPlaying: true, alreadyOwesResume: true
            )
        )
    }

    /// The handover carries the debt across, which is what stops the narration
    /// playing behind the video: the inline view clears its own flag as it
    /// builds this, so all three of its `resumeNarrationIfNeeded()` call sites
    /// become no-ops and the fullscreen view owes the resume instead.
    func testRequestCarriesTheNarrationDebt() {
        let req = FullscreenVideoRequest(
            urlString: "https://example.com/clip.mp4",
            startSeconds: 4.5,
            hasAudio: true,
            didPauseNarration: true,
            isLandscape: false,
            sourceFrame: CGRect(x: 24, y: 180, width: 345, height: 345)
        )
        XCTAssertTrue(req.didPauseNarration)
        XCTAssertEqual(req.startSeconds, 4.5, accuracy: 0.001)
        XCTAssertTrue(req.hasAudio)
    }

    /// Two requests for the same clip are distinct, so re-expanding after a
    /// dismiss presents again rather than being swallowed as "no change".
    func testTwoRequestsForTheSameClipAreDistinct() {
        func make() -> FullscreenVideoRequest {
            FullscreenVideoRequest(
                urlString: "https://example.com/clip.mp4",
                startSeconds: 0, hasAudio: true,
                didPauseNarration: false, isLandscape: false,
                sourceFrame: .zero
            )
        }
        XCTAssertNotEqual(make(), make())
    }

    // MARK: - The expand transform

    private let thumb = CGRect(x: 24, y: 180, width: 345, height: 345)
    private let screen = CGRect(x: 0, y: 0, width: 393, height: 852)

    /// At the start the content sits on the thumbnail, fitted inside it.
    func testAtProgressZeroTheContentSitsOnTheThumbnail() {
        let z = FullscreenVideoView.expandTransform(source: thumb, full: screen, progress: 0)
        XCTAssertEqual(z.centre.x, thumb.midX, accuracy: 0.01)
        XCTAssertEqual(z.centre.y, thumb.midY, accuracy: 0.01)
        // Fitted, so it never exceeds the box on either axis.
        XCTAssertLessThanOrEqual(screen.width * z.scale, thumb.width + 0.01)
        XCTAssertLessThanOrEqual(screen.height * z.scale, thumb.height + 0.01)
    }

    /// At the end it is the screen, untransformed.
    func testAtProgressOneTheContentFillsTheScreen() {
        let z = FullscreenVideoView.expandTransform(source: thumb, full: screen, progress: 1)
        XCTAssertEqual(z.scale, 1, accuracy: 0.0001)
        XCTAssertEqual(z.centre.x, screen.midX, accuracy: 0.01)
        XCTAssertEqual(z.centre.y, screen.midY, accuracy: 0.01)
    }

    /// 🔴 The scale is a single number, so the picture cannot squash on the
    /// way. Matching the thumbnail's box exactly would need one scale per
    /// axis; that distortion runs for the whole flight and is far worse than a
    /// few points of misalignment at the start.
    func testScaleIsUniformSoThePictureCannotDistort() {
        for p in stride(from: 0.0, through: 1.0, by: 0.1) {
            let z = FullscreenVideoView.expandTransform(source: thumb, full: screen, progress: p)
            let w = screen.width * z.scale
            let h = screen.height * z.scale
            XCTAssertEqual(w / h, screen.width / screen.height, accuracy: 0.0001,
                           "aspect must hold at progress \(p)")
        }
    }

    /// Growth is monotonic — no dip on the way out.
    func testScaleGrowsMonotonically() {
        var last: CGFloat = -1
        for p in stride(from: 0.0, through: 1.0, by: 0.05) {
            let s = FullscreenVideoView.expandTransform(source: thumb, full: screen, progress: p).scale
            XCTAssertGreaterThanOrEqual(s, last)
            last = s
        }
    }

    /// Progress outside 0...1 is clamped, so a spring overshoot cannot push
    /// the picture past the screen or invert it.
    func testProgressIsClamped() {
        let under = FullscreenVideoView.expandTransform(source: thumb, full: screen, progress: -0.5)
        let zero = FullscreenVideoView.expandTransform(source: thumb, full: screen, progress: 0)
        XCTAssertEqual(under.scale, zero.scale, accuracy: 0.0001)
        let over = FullscreenVideoView.expandTransform(source: thumb, full: screen, progress: 1.5)
        XCTAssertEqual(over.scale, 1, accuracy: 0.0001)
    }

    /// An unmeasured thumbnail degrades to the picture simply being there,
    /// full size — never to a zero-sized view.
    func testUnmeasuredSourceFallsBackToFullScreen() {
        let z = FullscreenVideoView.expandTransform(source: .zero, full: screen, progress: 0)
        XCTAssertEqual(z.scale, 1, accuracy: 0.0001)
        XCTAssertEqual(z.centre.x, screen.midX, accuracy: 0.01)
    }
}
