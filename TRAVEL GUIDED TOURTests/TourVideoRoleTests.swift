import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// Covers `TourVideoRole` and the rule that keeps a narration clip on the
/// tour's audio clock.
///
/// The distinction exists because the app could not previously tell a piece
/// of b-roll from a clip that IS the tour, so a video and the play bar
/// behaved as two unrelated things (owner, 2026-08-24: *"the scrubber in the
/// play button still doesnt match the video time"*).
@MainActor
final class TourVideoRoleTests: XCTestCase {

    // MARK: - The role itself

    /// 🔴 Absent means `gallery`. Every tour authored before the role existed
    /// must keep behaving exactly as it did — that is what makes this
    /// additive rather than a migration of the whole catalogue.
    func testAbsentRoleDecodesAsNilAndCallersTreatItAsGallery() throws {
        let json = """
        { "videoRole": null }
        """.data(using: .utf8)!
        struct Probe: Codable { let videoRole: TourVideoRole? }
        let probe = try JSONDecoder().decode(Probe.self, from: json)
        XCTAssertNil(probe.videoRole)
        XCTAssertEqual(probe.videoRole ?? .gallery, .gallery)
    }

    /// The wire values are what the catalog and the SQL column carry, so they
    /// are part of the contract, not an implementation detail.
    func testWireValuesAreStable() {
        XCTAssertEqual(TourVideoRole.gallery.rawValue, "gallery")
        XCTAssertEqual(TourVideoRole.narration.rawValue, "narration")
        XCTAssertEqual(TourVideoRole(rawValue: "narration"), .narration)
        XCTAssertNil(TourVideoRole(rawValue: "primary"), "unknown values must not silently map")
    }

    // MARK: - Following the narration

    /// In sync, nothing happens — a seek costs a stutter, so it has to be
    /// worth it.
    func testNoResyncWhenAlreadyInSync() {
        XCTAssertFalse(GalleryVideoView.shouldResync(audioTime: 10.0, videoTime: 10.0))
        XCTAssertFalse(GalleryVideoView.shouldResync(audioTime: 10.0, videoTime: 10.1))
    }

    /// Drifting either way is a resync — the picture can lag the sound or
    /// lead it, and both read as broken lip-sync.
    func testResyncsWhenDriftedInEitherDirection() {
        XCTAssertTrue(GalleryVideoView.shouldResync(audioTime: 10.0, videoTime: 9.0),
                      "picture behind the sound")
        XCTAssertTrue(GalleryVideoView.shouldResync(audioTime: 10.0, videoTime: 11.0),
                      "picture ahead of the sound")
    }

    /// The boundary is the tolerance, not a hand-tuned constant somewhere
    /// else — and it is much tighter than Group Listen's, because both ends
    /// are on the same device off the same clock rather than two phones over
    /// a network.
    func testToleranceIsTheBoundary() {
        let t = GalleryVideoView.followTolerance
        XCTAssertFalse(GalleryVideoView.shouldResync(audioTime: 10, videoTime: 10 + t / 2))
        XCTAssertTrue(GalleryVideoView.shouldResync(audioTime: 10, videoTime: 10 + t * 2))
        XCTAssertLessThan(t, 1.0, "tight enough that visible lip-sync error triggers a catch-up")
        XCTAssertGreaterThan(t, 0, "but not so tight it seeks every frame")
    }

    /// A custom tolerance is honoured, so the rule can be reasoned about at
    /// other thresholds without editing it.
    func testExplicitToleranceIsUsed() {
        XCTAssertFalse(GalleryVideoView.shouldResync(audioTime: 10, videoTime: 12, tolerance: 5))
        XCTAssertTrue(GalleryVideoView.shouldResync(audioTime: 10, videoTime: 12, tolerance: 1))
    }
}
