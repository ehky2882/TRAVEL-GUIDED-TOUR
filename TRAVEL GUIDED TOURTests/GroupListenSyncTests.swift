import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// Unit coverage for the Group Listen (aka "SharePlay") sync engine.
///
/// The feature is fundamentally **device-only** — real MultipeerConnectivity
/// discovery, two accounts, and audio playback can't run in the simulator or a
/// test host, which is why several real defects shipped unverified. The response
/// isn't "test the radios" (you can't); it's to **extract every playback-sync
/// decision into a pure, side-effect-free function** and pin the tricky ones
/// here. These are exactly the calls that were silently wrong on device:
/// intro-vs-stop resolution, stale-leader (epoch) filtering, and drift
/// correction. See `GroupListenCoordinator`'s "Pure sync decisions" section.
final class GroupListenSyncTests: XCTestCase {

    private let tourId = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    private let leaderId = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

    private func state(
        stopIndex: Int = 0,
        isIntro: Bool = false,
        isPlaying: Bool = true,
        position: Double = 0,
        rate: Float = 1.0,
        epoch: Int = 1
    ) -> GroupPlaybackState {
        GroupPlaybackState(
            tourId: tourId,
            stopIndex: stopIndex,
            isIntro: isIntro,
            isPlaying: isPlaying,
            positionSeconds: position,
            rate: rate,
            leaderId: leaderId,
            sessionEpoch: epoch,
            sentAt: Date(timeIntervalSinceReferenceDate: 0)
        )
    }

    // MARK: - Epoch filtering (fixes the "connected but never mirrors" bug)

    func test_shouldApply_adoptsEqualOrNewerEpoch_ignoresStale() {
        XCTAssertTrue(GroupListenCoordinator.shouldApply(incomingEpoch: 1, localEpoch: 0))
        XCTAssertTrue(GroupListenCoordinator.shouldApply(incomingEpoch: 1, localEpoch: 1))
        XCTAssertTrue(GroupListenCoordinator.shouldApply(incomingEpoch: 5, localEpoch: 2))
        // A former leader (high local epoch) joining a fresh leader must NOT
        // ignore it — this is why the coordinator resets epoch to 0 on join.
        XCTAssertFalse(GroupListenCoordinator.shouldApply(incomingEpoch: 1, localEpoch: 2))
    }

    // MARK: - Intro vs stop resolution (fixes the intro-desync bug)

    func test_resolvedTargetIndex_normalStopInRange() {
        XCTAssertEqual(
            GroupListenCoordinator.resolvedTargetIndex(state: state(stopIndex: 2), stopCount: 5, hasIntro: false),
            2
        )
    }

    func test_resolvedTargetIndex_stopOutOfRangeIsNil() {
        XCTAssertNil(
            GroupListenCoordinator.resolvedTargetIndex(state: state(stopIndex: 9), stopCount: 5, hasIntro: false)
        )
        XCTAssertNil(
            GroupListenCoordinator.resolvedTargetIndex(state: state(stopIndex: 0), stopCount: 0, hasIntro: false)
        )
    }

    func test_resolvedTargetIndex_introMapsToSentinel_whenTourHasIntro() {
        XCTAssertEqual(
            GroupListenCoordinator.resolvedTargetIndex(state: state(isIntro: true), stopCount: 3, hasIntro: true),
            GroupListenCoordinator.introIndex
        )
    }

    func test_resolvedTargetIndex_introFlagButNoIntroAudioIsNil() {
        // Defensive: an intro flag on a tour that has no intro clip must resolve
        // to nil (bail), not silently play stop 0 over the leader's intro.
        XCTAssertNil(
            GroupListenCoordinator.resolvedTargetIndex(state: state(isIntro: true), stopCount: 3, hasIntro: false)
        )
    }

    func test_introIndex_isDistinctFromEveryValidStopIndex() {
        // The sentinel must never collide with a real (0-based) stop index.
        XCTAssertTrue(GroupListenCoordinator.introIndex < 0)
    }

    // MARK: - Drift correction

    func test_shouldCorrectDrift_onlyBeyondThreshold() {
        let t = 1.25
        XCTAssertFalse(GroupListenCoordinator.shouldCorrectDrift(current: 10.0, target: 10.0, threshold: t))
        XCTAssertFalse(GroupListenCoordinator.shouldCorrectDrift(current: 10.0, target: 11.0, threshold: t)) // 1.0 < 1.25
        XCTAssertFalse(GroupListenCoordinator.shouldCorrectDrift(current: 10.0, target: 11.25, threshold: t)) // exactly at → no
        XCTAssertTrue(GroupListenCoordinator.shouldCorrectDrift(current: 10.0, target: 12.0, threshold: t))  // 2.0 > 1.25
        XCTAssertTrue(GroupListenCoordinator.shouldCorrectDrift(current: 20.0, target: 10.0, threshold: t))  // symmetric
    }

    // MARK: - Join code

    func test_makeCode_hasFixedLengthFromUnambiguousAlphabet() {
        let allowed = Set(GroupListenCoordinator.codeAlphabet)
        // Ambiguous glyphs must be excluded so a code read aloud can't be mistyped.
        for bad in "O0I1" { XCTAssertFalse(allowed.contains(bad), "\(bad) should not be in the code alphabet") }
        for _ in 0..<200 {
            let code = GroupListenCoordinator.makeCode()
            XCTAssertEqual(code.count, GroupListenCoordinator.codeLength)
            XCTAssertTrue(code.allSatisfy { allowed.contains($0) }, "unexpected char in \(code)")
        }
    }

    // MARK: - Wire format

    func test_playbackState_codableRoundTrip() throws {
        let original = state(stopIndex: 3, isIntro: true, isPlaying: false, position: 42.5, rate: 1.5, epoch: 7)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(GroupPlaybackState.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func test_playbackState_decodesLegacyPayloadMissingIsIntro() throws {
        // A payload without `isIntro` (older shape) must still decode, defaulting
        // to false — so the field can evolve without breaking wire compatibility.
        var dict = try JSONSerialization.jsonObject(
            with: JSONEncoder().encode(state(isIntro: true)), options: []
        ) as! [String: Any]
        dict.removeValue(forKey: "isIntro")
        let trimmed = try JSONSerialization.data(withJSONObject: dict, options: [])
        let decoded = try JSONDecoder().decode(GroupPlaybackState.self, from: trimmed)
        XCTAssertFalse(decoded.isIntro)
    }

    // MARK: - Connection status

    func test_connectionStatus_equatableIncludingFailureMessage() {
        XCTAssertEqual(GroupConnectionStatus.searching, .searching)
        XCTAssertEqual(GroupConnectionStatus.failed("x"), .failed("x"))
        XCTAssertNotEqual(GroupConnectionStatus.failed("x"), .failed("y"))
        XCTAssertNotEqual(GroupConnectionStatus.searching, .connected)
    }
}
