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

    // MARK: - Drift correction (two-tier: ignore / glide / snap)

    private func correction(current: Double, target: Double) -> GroupDriftCorrection {
        GroupListenCoordinator.correction(
            current: current, target: target,
            deadZone: 0.15, hardSeekThreshold: 2.0, fullTrimDrift: 1.0
        )
    }

    func test_correction_insideDeadZone_doesNothing() {
        XCTAssertEqual(correction(current: 10.0, target: 10.0), .inSync)
        XCTAssertEqual(correction(current: 10.0, target: 10.1), .inSync)   // behind by 0.1
        XCTAssertEqual(correction(current: 10.0, target: 9.9), .inSync)    // ahead by 0.1
    }

    func test_correction_largeDrift_snaps() {
        XCTAssertEqual(correction(current: 10.0, target: 12.0), .seek)   // exactly at threshold
        XCTAssertEqual(correction(current: 10.0, target: 20.0), .seek)
        XCTAssertEqual(correction(current: 20.0, target: 10.0), .seek)   // symmetric
    }

    func test_correction_behindLeader_speedsUp() {
        guard case .trim(let m) = correction(current: 10.0, target: 10.5) else {
            return XCTFail("expected a trim")
        }
        XCTAssertGreaterThan(m, 1.0, "behind the leader → must play faster to catch up")
        XCTAssertLessThanOrEqual(m, AudioPlayerService.maxSyncTrim)
    }

    func test_correction_aheadOfLeader_slowsDown() {
        guard case .trim(let m) = correction(current: 10.5, target: 10.0) else {
            return XCTFail("expected a trim")
        }
        XCTAssertLessThan(m, 1.0, "ahead of the leader → must play slower to fall back")
        XCTAssertGreaterThanOrEqual(m, AudioPlayerService.minSyncTrim)
    }

    func test_correction_trimScalesWithDrift_andStaysInAudibleBounds() {
        guard case .trim(let small) = correction(current: 10.0, target: 10.3),
              case .trim(let large) = correction(current: 10.0, target: 11.0) else {
            return XCTFail("expected trims")
        }
        XCTAssertLessThan(small, large, "a bigger gap should pull harder")
        // Never exceed the inaudible band, in either direction.
        for target in stride(from: 8.2, through: 11.8, by: 0.2) {
            if case .trim(let m) = correction(current: 10.0, target: target) {
                XCTAssertGreaterThanOrEqual(m, AudioPlayerService.minSyncTrim)
                XCTAssertLessThanOrEqual(m, AudioPlayerService.maxSyncTrim)
            }
        }
    }

    func test_syncTrimBounds_areNarrowEnoughToBeInaudible() {
        // Guards the tuning itself: a trim beyond ~5% is audible on speech.
        XCTAssertLessThanOrEqual(AudioPlayerService.maxSyncTrim, 1.05)
        XCTAssertGreaterThanOrEqual(AudioPlayerService.minSyncTrim, 0.95)
        // Symmetric around 1.0 so catching up and falling back feel the same.
        XCTAssertEqual(AudioPlayerService.maxSyncTrim - 1.0,
                       1.0 - AudioPlayerService.minSyncTrim, accuracy: 0.0001)
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
