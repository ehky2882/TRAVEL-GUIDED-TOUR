import XCTest
import CoreLocation
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

    /// The short description is NOT required (owner decision, 2026-08-19),
    /// on the same reasoning as tags: it decides how well a tour reads on a
    /// card, not whether it works.
    func test_details_shortDescriptionIsNeverRequired() {
        var state = completeState()
        state.shortDescription = ""
        XCTAssertTrue(TourWizardRules.canAdvance(from: .details, state: state))
        XCTAssertNil(TourWizardRules.blockingReason(for: .details, state: state))
    }

    /// Whitespace is not a title — the trim is the point.
    func test_details_whitespaceOnlyTitleDoesNotCount() {
        var state = completeState()
        state.title = "\n  \t "
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

    /// A title is the only thing this step asks for.
    func test_details_onlyTheTitleBlocks() {
        var state = completeState()
        state.title = ""
        state.shortDescription = ""
        state.tags = []
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
                       [.location, .details, .tags, .photos, .audio, .transcript, .review])
        XCTAssertNil(TourWizardStep.location.previous)
        XCTAssertNil(TourWizardStep.review.next)
        XCTAssertEqual(TourWizardStep.location.next, .details)
        XCTAssertEqual(TourWizardStep.details.next, .tags)
        XCTAssertEqual(TourWizardStep.tags.next, .photos)
        XCTAssertEqual(TourWizardStep.audio.next, .transcript)
        XCTAssertEqual(TourWizardStep.review.previous, .transcript)
    }

    /// The transcript gates nothing, and for a stronger reason than tags: the
    /// catalogue has always allowed a null transcript, the step arrives
    /// pre-filled by the on-device transcriber, and a maker whose language it
    /// doesn't cover must not be stopped at a box they'd have to type by hand.
    func test_transcript_neverBlocks() {
        var state = completeState()
        XCTAssertTrue(TourWizardRules.canAdvance(from: .transcript, state: state))
        XCTAssertNil(TourWizardRules.blockingReason(for: .transcript, state: state))
        // Not even with no audio to transcribe — Audio is where that is caught.
        state.audioDurationSeconds = 0
        XCTAssertTrue(TourWizardRules.canAdvance(from: .transcript, state: state))
    }

    /// Tags gate nothing. The step exists because the picker is too tall to
    /// share a screen, not because a tour needs tags to be made.
    func test_tags_neverBlocks() {
        var state = completeState()
        state.tags = []
        XCTAssertTrue(TourWizardRules.canAdvance(from: .tags, state: state))
        XCTAssertNil(TourWizardRules.blockingReason(for: .tags, state: state))
    }

    // MARK: - Coordinate equality

    /// The guard that stops the map's camera callback re-dirtying the view on
    /// every layout pass. `CLLocationCoordinate2D` has no `Equatable`, so
    /// without this SwiftUI treats an identical write as a change — and the
    /// wizard's sheet re-lays out, fires the callback again, and hangs.
    func test_identicalCoordinatesAreEssentiallyEqual() {
        let c = CLLocationCoordinate2D(latitude: 41.14961, longitude: -8.61099)
        XCTAssertTrue(c.isEssentially(c))
        XCTAssertTrue(c.isEssentially(CLLocationCoordinate2D(latitude: 41.14961,
                                                             longitude: -8.61099)))
    }

    func test_aRealPanIsNotEssentiallyEqual() {
        let c = CLLocationCoordinate2D(latitude: 41.14961, longitude: -8.61099)
        // ~1 m north, well inside anything a finger can express.
        XCTAssertFalse(c.isEssentially(CLLocationCoordinate2D(latitude: 41.14962,
                                                              longitude: -8.61099)))
        XCTAssertFalse(c.isEssentially(CLLocationCoordinate2D(latitude: 41.14961,
                                                              longitude: -8.61098)))
    }
}

/// The tidy-up the on-device transcriber runs over what it recognises.
///
/// Pure string work, so it is testable without a microphone, a language model
/// or a device — which is the whole of what can be tested here. Whether
/// `SpeechAnalyzer` hears the words is a device question.
final class AudioTranscriberTextTests: XCTestCase {

    func test_tidied_collapsesRunsOfSpaces() {
        XCTAssertEqual(AudioTranscriber.tidied("the   old   bridge"), "the old bridge")
    }

    func test_tidied_trimsEnds() {
        XCTAssertEqual(AudioTranscriber.tidied("  stand here.  "), "stand here.")
    }

    func test_tidied_keepsLineBreaksButNotThePaddingAroundThem() {
        XCTAssertEqual(AudioTranscriber.tidied("one line \n  next line"), "one line\nnext line")
    }

    func test_tidied_emptyStaysEmpty() {
        XCTAssertEqual(AudioTranscriber.tidied("   \n  "), "")
    }
}
