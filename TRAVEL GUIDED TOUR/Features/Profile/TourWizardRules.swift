import Foundation
import CoreLocation

/// The seven steps of making a tour, and the rules for leaving each one.
///
/// Tags were split out of Details on 2026-08-20. Details had four things in it
/// and the fourth was the tag picker at 382pt closed — 691pt of content into a
/// 529pt screen before anyone opened a group, and 907 after. The line to cut
/// along was already in the picker's own copy: "tags are how people find your
/// tour" is a different question from what the tour is.
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
    case location, details, tags, photos, audio, transcript, review

    var label: String {
        switch self {
        case .location: return "LOCATION"
        case .details:  return "DETAILS"
        case .tags:     return "TAGS"
        case .photos:   return "PHOTOS"
        case .audio:    return "AUDIO"
        case .transcript: return "TRANSCRIPT"
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

        case .tags:
            // Nothing is required here, and that is the whole character of the
            // step. Tags decide how well a tour is found, not whether it works
            // — the catalogue's own validator treats a missing Place type or
            // Theme as a warning, never an error (owner decision, 2026-08-19).
            // Tags got a step of their own because the picker is 382pt tall,
            // not because it earned a gate.
            return nil

        case .photos:
            return state.hasCoverPhoto
                ? nil
                : "Add at least one photo. The first becomes the cover."

        case .audio:
            return state.audioDurationSeconds > 0
                ? nil
                : "Record or import the narration."

        case .transcript:
            // Optional, like tags — and for a stronger reason than tags. The
            // catalogue has always allowed a null `transcriptText`, the step
            // arrives pre-filled by the on-device transcriber, and a maker
            // whose language the transcriber doesn't cover must not be stopped
            // at a box they'd have to type by hand. Gating here would make a
            // convenience into an obstacle.
            return nil

        case .review:
            if state.isAlreadyInReview {
                return "Already with us — we'll let you know either way."
            }
            // 🔴 A TOUR COULD BE SUBMITTED WITH NO AUDIO. The earlier steps
            // gate *advancing*, but the progress bar lets an existing tour
            // jump straight to Review — so a maker who jumped here from step 1
            // found Submit live on a tour with no narration and no cover, and
            // this case never looked. Review is the last gate and has to
            // re-ask every question, not just its own.
            //
            // The first unfinished step's reason is the one shown: it names
            // something concrete to go and do, and the progress bar is one tap
            // from doing it.
            for earlier in TourWizardStep.allCases where earlier != .review {
                if let reason = blockingReason(for: earlier, state: state) {
                    return reason
                }
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

extension CLLocationCoordinate2D {
    /// Whether two coordinates are the same point for our purposes — about a
    /// centimetre, far below anything a finger can express on a map.
    ///
    /// `CLLocationCoordinate2D` deliberately has no `Equatable` conformance,
    /// which means SwiftUI cannot tell an unchanged write to a coordinate
    /// `@State` from a real one: every assignment dirties the view. Anywhere a
    /// coordinate is written from a callback that fires on layout — the map's
    /// `onMapCameraChange` above all — the write has to be gated on this, or
    /// layout and rendering feed each other until the watchdog kills the app.
    func isEssentially(_ other: CLLocationCoordinate2D) -> Bool {
        let tolerance = 1e-7
        return abs(latitude - other.latitude) < tolerance
            && abs(longitude - other.longitude) < tolerance
    }
}
