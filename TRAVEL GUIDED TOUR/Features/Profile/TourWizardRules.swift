import Foundation

/// The five steps of making a tour, and the rules for leaving each one.
///
/// The rules live here as pure functions, following `SaveState`: the wizard is
/// the only screen in the app where "can I go on?" has an answer per step, and
/// getting it wrong is invisible — a maker taps through five screens and
/// arrives at a tour that can't be submitted, with nothing to explain why.
/// Nothing else the project checks can see that: the validator reads
/// `Tours.json`, the duplicate checker reads bytes, and the compiler is happy
/// either way. So the rules are testable without standing up a view, a
/// service, or a Supabase row.
enum TourWizardStep: Int, CaseIterable {
    case location, details, photos, audio, review

    var label: String {
        switch self {
        case .location: return "LOCATION"
        case .details:  return "DETAILS"
        case .photos:   return "PHOTOS"
        case .audio:    return "AUDIO"
        case .review:   return "REVIEW"
        }
    }

    var next: TourWizardStep? { TourWizardStep(rawValue: rawValue + 1) }
    var previous: TourWizardStep? { TourWizardStep(rawValue: rawValue - 1) }
}

/// Everything the rules need to know, flattened out of the view's state and the
/// draft row so neither has to exist to test them.
struct TourWizardState: Equatable {
    var hasCoordinate = false
    var title = ""
    var shortDescription = ""
    var tags: Set<String> = []
    var hasCoverPhoto = false
    var audioDurationSeconds = 0
    var audioUpload: AudioUploadState = .idle
    /// Whether the draft row exists yet. Steps 3 onward write against a tour
    /// id, so they have nothing to act on until it does.
    var draftExists = false
    /// A tour already with the moderators has nothing to submit.
    var isAlreadyInReview = false

    var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum TourWizardRules {

    /// Whether the step is finished enough to leave.
    static func canAdvance(from step: TourWizardStep, state: TourWizardState) -> Bool {
        blockingReason(for: step, state: state) == nil
    }

    /// Why the step can't be left, phrased for the maker. Nil means it can.
    /// One function serves both questions so a rule and its explanation can
    /// never disagree — the failure mode being a dimmed button with no reason,
    /// or a reason shown beside a live one.
    static func blockingReason(for step: TourWizardStep, state: TourWizardState) -> String? {
        switch step {
        case .location:
            return state.hasCoordinate
                ? nil
                : "Pan the map to put the pin where the tour begins."

        case .details:
            // A title is the only thing asked for here, and only because a
            // tour has to be called something — the row it lands on in the
            // maker's own list would otherwise be blank.
            //
            // Neither tags nor the short description are required (owner
            // decisions, 2026-08-19). They decide how well a tour shows up,
            // not whether it works, and that is the maker's call: the
            // catalogue's own validator treats a missing tag as a warning,
            // never an error, and review is the backstop if a tour arrives
            // bare.
            return state.trimmedTitle.isEmpty ? "A title is needed." : nil

        case .photos:
            return state.hasCoverPhoto
                ? nil
                : "Add at least one photo. The first becomes the cover."

        case .audio:
            return state.audioDurationSeconds > 0
                ? nil
                : "Record or import the narration."

        case .review:
            if state.isAlreadyInReview {
                return "Already with us — we'll let you know either way."
            }
            // Reaching Review mid-upload is fine; submitting is not. The
            // audio can still be in flight while the maker reads the summary.
            switch state.audioUpload {
            case .uploading:
                return "Waiting for the narration to finish uploading."
            case .failed:
                return "The narration didn't upload. Go back and try again."
            case .idle:
                return state.draftExists ? nil : "Go back to Location and place the pin first."
            }
        }
    }
}
