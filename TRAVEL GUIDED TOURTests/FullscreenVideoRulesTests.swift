import XCTest
import AVFoundation
import UIKit
import SwiftUI
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
            aspectRatio: 9.0 / 16.0,
            sourceFrame: CGRect(x: 24, y: 180, width: 345, height: 345),
            tourId: nil
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
                aspectRatio: 9.0 / 16.0,
                sourceFrame: .zero,
                tourId: nil
            )
        }
        XCTAssertNotEqual(make(), make())
    }

    // MARK: - The expand transform

    private let thumb = CGRect(x: 24, y: 180, width: 345, height: 345)
    private let screen = CGRect(x: 0, y: 0, width: 393, height: 852)
    private let vertical: CGFloat = 9.0 / 16.0

    /// 🔴 The point of the whole transform: at progress 0 it reproduces the
    /// carousel thumbnail exactly — which now FILLS its box, cropping the clip.
    /// So the picture must be scaled to COVER the box, and the mask must be
    /// the box, which is what does the cropping.
    func testAtProgressZeroItReproducesTheFilledThumbnail() {
        let z = FullscreenVideoView.expandTransform(
            source: thumb, full: screen, aspectRatio: vertical, progress: 0
        )
        let screenPicture = FullscreenVideoView.aspectFitRect(aspectRatio: vertical, in: screen)
        let drawnWidth = screenPicture.width * z.scale
        let drawnHeight = screenPicture.height * z.scale
        // Covers the box on BOTH axes — that is what "fill" means.
        XCTAssertGreaterThanOrEqual(drawnWidth, thumb.width - 0.01)
        XCTAssertGreaterThanOrEqual(drawnHeight, thumb.height - 0.01)
        // ...and touches it on at least one, so it is not scaled up further
        // than filling requires.
        let touches = abs(drawnWidth - thumb.width) < 0.01 || abs(drawnHeight - thumb.height) < 0.01
        XCTAssertTrue(touches, "fill must be the tightest cover, not an arbitrary overscale")
        // The window onto it is exactly the thumbnail's box.
        XCTAssertEqual(z.mask.minX, thumb.minX, accuracy: 0.01)
        XCTAssertEqual(z.mask.width, thumb.width, accuracy: 0.01)
        XCTAssertEqual(z.mask.height, thumb.height, accuracy: 0.01)
        XCTAssertEqual(z.centre.x, thumb.midX, accuracy: 0.01)
        XCTAssertEqual(z.centre.y, thumb.midY, accuracy: 0.01)
    }

    /// A vertical clip filling a square box is cropped top and bottom — the
    /// crop the expand then reveals.
    func testAVerticalClipIsCroppedVerticallyInTheSquareThumbnail() {
        let z = FullscreenVideoView.expandTransform(
            source: thumb, full: screen, aspectRatio: vertical, progress: 0
        )
        let screenPicture = FullscreenVideoView.aspectFitRect(aspectRatio: vertical, in: screen)
        XCTAssertGreaterThan(screenPicture.height * z.scale, thumb.height,
                             "taller than the window, so top and bottom are cut")
        XCTAssertEqual(screenPicture.width * z.scale, thumb.width, accuracy: 0.01,
                       "and exactly as wide, so the sides are flush")
    }

    /// The same must hold the other way round: a landscape clip filling a
    /// square box is cropped left and right.
    func testALandscapeClipIsCroppedHorizontallyInTheSquareThumbnail() {
        let wide: CGFloat = 16.0 / 9.0
        let z = FullscreenVideoView.expandTransform(
            source: thumb, full: screen, aspectRatio: wide, progress: 0
        )
        let screenPicture = FullscreenVideoView.aspectFitRect(aspectRatio: wide, in: screen)
        XCTAssertGreaterThan(screenPicture.width * z.scale, thumb.width)
        XCTAssertEqual(screenPicture.height * z.scale, thumb.height, accuracy: 0.01)
    }

    /// The mask opens all the way out, so nothing stays cropped at the end.
    func testTheMaskOpensToTheWholeScreen() {
        let z = FullscreenVideoView.expandTransform(
            source: thumb, full: screen, aspectRatio: vertical, progress: 1
        )
        XCTAssertEqual(z.mask, screen)
        XCTAssertEqual(z.scale, 1, accuracy: 0.0001)
    }

    /// Which axis the bars land on depends on the clip AND the box, not the
    /// clip alone — a 16:9 clip is width-limited in a square box but
    /// height-limited in a 2:1 box, which is wider than the clip.
    func testAspectFitPicksTheLimitingAxisFromBothShapes() {
        let square = CGRect(x: 0, y: 0, width: 400, height: 400)
        let wideInSquare = FullscreenVideoView.aspectFitRect(aspectRatio: 16.0 / 9.0, in: square)
        XCTAssertEqual(wideInSquare.width, 400, accuracy: 0.01, "width-limited in a square box")
        XCTAssertEqual(wideInSquare.height, 225, accuracy: 0.01)

        let veryWideBox = CGRect(x: 0, y: 0, width: 400, height: 200) // 2:1, wider than 16:9
        let wideInWider = FullscreenVideoView.aspectFitRect(aspectRatio: 16.0 / 9.0, in: veryWideBox)
        XCTAssertEqual(wideInWider.height, 200, accuracy: 0.01, "height-limited when the box is wider still")
        XCTAssertLessThan(wideInWider.width, 400)

        // A vertical clip in a wide box: bars down the sides.
        let tall = FullscreenVideoView.aspectFitRect(aspectRatio: 9.0 / 16.0, in: veryWideBox)
        XCTAssertEqual(tall.height, 200, accuracy: 0.01)
        XCTAssertEqual(tall.width, 112.5, accuracy: 0.01)
    }

    /// The fit never exceeds its box on either axis, whatever the shapes.
    func testAspectFitNeverOverflowsItsBox() {
        let box = CGRect(x: 10, y: 20, width: 345, height: 345)
        for ratio in [0.4, 0.5625, 0.75, 1.0, 1.333, 1.778, 2.35] {
            let r = FullscreenVideoView.aspectFitRect(aspectRatio: CGFloat(ratio), in: box)
            XCTAssertLessThanOrEqual(r.width, box.width + 0.01, "ratio \(ratio)")
            XCTAssertLessThanOrEqual(r.height, box.height + 0.01, "ratio \(ratio)")
            XCTAssertEqual(r.midX, box.midX, accuracy: 0.01, "centred, ratio \(ratio)")
            XCTAssertEqual(r.midY, box.midY, accuracy: 0.01, "centred, ratio \(ratio)")
        }
    }

    /// At the end it is the screen, untransformed.
    func testAtProgressOneTheContentFillsTheScreen() {
        let z = FullscreenVideoView.expandTransform(source: thumb, full: screen, aspectRatio: vertical, progress: 1)
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
            let z = FullscreenVideoView.expandTransform(source: thumb, full: screen, aspectRatio: vertical, progress: p)
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
            let s = FullscreenVideoView.expandTransform(source: thumb, full: screen, aspectRatio: vertical, progress: p).scale
            XCTAssertGreaterThanOrEqual(s, last)
            last = s
        }
    }

    /// Progress outside 0...1 is clamped, so a spring overshoot cannot push
    /// the picture past the screen or invert it.
    func testProgressIsClamped() {
        let under = FullscreenVideoView.expandTransform(source: thumb, full: screen, aspectRatio: vertical, progress: -0.5)
        let zero = FullscreenVideoView.expandTransform(source: thumb, full: screen, aspectRatio: vertical, progress: 0)
        XCTAssertEqual(under.scale, zero.scale, accuracy: 0.0001)
        let over = FullscreenVideoView.expandTransform(source: thumb, full: screen, aspectRatio: vertical, progress: 1.5)
        XCTAssertEqual(over.scale, 1, accuracy: 0.0001)
    }

    /// An unmeasured thumbnail degrades to the picture simply being there,
    /// full size — never to a zero-sized view.
    func testUnmeasuredSourceFallsBackToFullScreen() {
        let z = FullscreenVideoView.expandTransform(source: .zero, full: screen, aspectRatio: vertical, progress: 0)
        XCTAssertEqual(z.scale, 1, accuracy: 0.0001)
        XCTAssertEqual(z.centre.x, screen.midX, accuracy: 0.01)
    }

    // MARK: - Control insets

    private var phoneSafeArea: UIEdgeInsets {
        UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0)
    }

    /// 🔴 Unrotated, the row must land where `TourDetailView.chromeRow` lands:
    /// that row sits inside the safe area with `sm` above it, so a 44pt button
    /// centres at `safeTop + sm + 22`. Owner direction — the X, bookmark and
    /// `…` sit where they sit on the tour page.
    func testUnrotatedInsetsPutTheRowWhereTheTourPagePutsIt() {
        let i = FullscreenVideoView.controlInsets(rotated: false, safeArea: phoneSafeArea)
        XCTAssertEqual(i.top, 59 + AtlasSpacing.sm, accuracy: 0.01)
        XCTAssertEqual(i.leading, AtlasSpacing.lg, accuracy: 0.01)
        XCTAssertEqual(i.trailing, AtlasSpacing.lg, accuracy: 0.01)
        // The button's centre, which is the thing that has to match.
        let centreY = i.top + AtlasChromeButton.diameter / 2
        XCTAssertEqual(centreY, 59 + AtlasSpacing.sm + 22, accuracy: 0.01)
    }

    /// ...and clear of the Dynamic Island, which is the failure this replaced:
    /// a bare 24pt inset centred the close button at y=46, inside the cutout,
    /// where the system takes the touch.
    func testUnrotatedRowClearsTheDynamicIsland() {
        let i = FullscreenVideoView.controlInsets(rotated: false, safeArea: phoneSafeArea)
        XCTAssertGreaterThan(i.top, phoneSafeArea.top, "the row starts below the cutout")
    }

    /// Rotated, the insets go uniform: the controls ride inside the rotated
    /// stack, so the island can be along any edge relative to them and a 24pt
    /// side inset would put a control straight back under it.
    func testRotatedInsetsAreUniformAndClearTheIslandOnEveryEdge() {
        let i = FullscreenVideoView.controlInsets(rotated: true, safeArea: phoneSafeArea)
        XCTAssertEqual(i.top, i.leading, accuracy: 0.01)
        XCTAssertEqual(i.leading, i.bottom, accuracy: 0.01)
        XCTAssertEqual(i.bottom, i.trailing, accuracy: 0.01)
        XCTAssertGreaterThanOrEqual(i.top, phoneSafeArea.top)
    }

    /// A device with no insets at all still gets a sane margin rather than
    /// controls flush against the glass.
    func testInsetsNeverCollapseToZero() {
        for rotated in [false, true] {
            let i = FullscreenVideoView.controlInsets(rotated: rotated, safeArea: .zero)
            XCTAssertGreaterThan(i.top, 0)
            XCTAssertGreaterThan(i.leading, 0)
            XCTAssertGreaterThan(i.bottom, 0)
            XCTAssertGreaterThan(i.trailing, 0)
        }
    }
}
