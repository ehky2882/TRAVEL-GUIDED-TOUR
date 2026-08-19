import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// Pins the create wizard's step gating.
///
/// This is the class of bug nothing else here can catch: every rule below is
/// invisible to the Tours.json validator, to the duplicate checker, and to the
/// compiler. Get one wrong and a maker taps through five screens to a tour that
/// cannot be submitted, with a dimmed button and no explanation.
final class TourWizardRulesTests: XCTestCase {

    /// A state that satisfies every step, so each test can break exactly one
    /// thing and assert that it — and only it — is what blocks.
    private func completeState() -> TourWizardState {
        TourWizardState(
            hasCoordinate: true,
            title: "The Old Custom House",
            shortDescription: "Where the river paid its dues.",
            tags: ["Notable Building", "Commerce"],
            hasCoverPhoto: true,
            audioDurationSeconds: 154,
            audioUpload: .idle,
            draftExists: true
        )
    }

    func test_completeState_canLeaveEveryStep() {
        let state = completeState()
        for step in TourWizardStep.allCases {
            XCTAssertTrue(TourWizardRules.canAdvance(from: step, state: state),
                          "\(step.label) should not block a complete tour")
            XCTAssertNil(TourWizardRules.blockingReason(for: step, state: state))
        }
    }

    // MARK: - Location

    func test_location_needsAPin() {
        var state = completeState()
        state.hasCoordinate = false
        XCTAssertFalse(TourWizardRules.canAdvance(from: .location, state: state))
        XCTAssertEqual(TourWizardRules.blockingReason(for: .location, state: state),
                       "Pan the map to put the pin where the tour begins.")
    }

    // MARK: - Details

    func test_details_needsATitle() {
        var state = completeState()
        state.title = "   "
        XCTAssertFalse(TourWizardRules.canAdvance(from: .details, state: state))
        XCTAssertEqual(TourWizardRules.blockingReason(for: .details, state: state),
                       "A title is needed.")
    }

    func test_details_needsAShortDescription() {
        var state = completeState()
        state.shortDescription = ""
        XCTAssertFalse(TourWizardRules.canAdvance(from: .details, state: state))
    }

    /// Whitespace is not a description — the trim is the point.
    func test_details_whitespaceOnlyFieldsDoNotCount() {
        var state = completeState()
        state.shortDescription = "\n  \t "
        XCTAssertFalse(TourWizardRules.canAdvance(from: .details, state: state))
    }

    /// Tags are NOT required (owner decision, 2026-08-19). They decide where a
    /// tour surfaces, not whether it works, so an untagged tour must still be
    /// able to leave this step — it is simply harder to find.
    func test_details_tagsAreNeverRequired() {
        var state = completeState()

        state.tags = []
        XCTAssertTrue(TourWizardRules.canAdvance(from: .details, state: state))
        XCTAssertNil(TourWizardRules.blockingReason(for: .details, state: state))

        state.tags = ["Notable Building"]          // place type only
        XCTAssertTrue(TourWizardRules.canAdvance(from: .details, state: state))

        state.tags = ["Commerce"]                  // theme only
        XCTAssertTrue(TourWizardRules.canAdvance(from: .details, state: state))

        state.tags = ["Baroque", "Hidden Gem"]     // optional facets only
        XCTAssertTrue(TourWizardRules.canAdvance(from: .details, state: state))
    }

    /// An untagged tour can be submitted, not merely advanced past.
    func test_review_untaggedTourCanStillBeSubmitted() {
        var state = completeState()
        state.tags = []
        XCTAssertTrue(TourWizardRules.canAdvance(from: .review, state: state))
    }

    /// The title rule is reported before the description rule, so the hint
    /// names the first thing to fix rather than the last.
    func test_details_reportsTheFirstMissingFieldOnly() {
        var state = completeState()
        state.title = ""
        state.shortDescription = ""
        XCTAssertEqual(TourWizardRules.blockingReason(for: .details, state: state),
                       "A title is needed.")
    }

    // MARK: - Photos + audio

    func test_photos_needsACover() {
        var state = completeState()
        state.hasCoverPhoto = false
        XCTAssertFalse(TourWizardRules.canAdvance(from: .photos, state: state))
    }

    func test_audio_needsNarration() {
        var state = completeState()
        state.audioDurationSeconds = 0
        XCTAssertFalse(TourWizardRules.canAdvance(from: .audio, state: state))
    }

    // MARK: - Review

    /// The whole point of reporting upload state upward: you may *read* Review
    /// while narration uploads, but you may not submit.
    func test_review_blockedWhileTheUploadIsInFlight() {
        var state = completeState()
        state.audioUpload = .uploading(0.62)
        XCTAssertFalse(TourWizardRules.canAdvance(from: .review, state: state))
        XCTAssertEqual(TourWizardRules.blockingReason(for: .review, state: state),
                       "Waiting for the narration to finish uploading.")
    }

    func test_review_blockedAfterAFailedUpload() {
        var state = completeState()
        state.audioUpload = .failed
        XCTAssertFalse(TourWizardRules.canAdvance(from: .review, state: state))
    }

    /// Walking to Review is not gated on the upload — only submitting is.
    func test_audioStep_isNotBlockedByAnUploadInFlight() {
        var state = completeState()
        state.audioUpload = .uploading(0.1)
        XCTAssertTrue(TourWizardRules.canAdvance(from: .audio, state: state))
    }

    func test_review_needsADraftRow() {
        var state = completeState()
        state.draftExists = false
        XCTAssertFalse(TourWizardRules.canAdvance(from: .review, state: state))
    }

    // MARK: - Step order

    func test_stepsRunInOrderAndStopAtBothEnds() {
        XCTAssertEqual(TourWizardStep.allCases,
                       [.location, .details, .photos, .audio, .review])
        XCTAssertNil(TourWizardStep.location.previous)
        XCTAssertNil(TourWizardStep.review.next)
        XCTAssertEqual(TourWizardStep.location.next, .details)
        XCTAssertEqual(TourWizardStep.review.previous, .audio)
    }
}
