import Foundation

/// Turns the errors the authoring flow can actually hit into something a maker
/// can act on.
///
/// **Why this exists.** Every failure path in the tour editor showed
/// `error.localizedDescription` in red. For a Supabase/PostgREST failure that is
/// a developer-facing string — the owner saw
/// *"failed to parse order (eq.0)" (line 1, column 4)* on a real bug — and for a
/// dropped connection it is a sentence about NSURLErrorDomain. Neither tells
/// somebody what to do next.
///
/// The rule here: **say what happened, and whether their work is safe.** A maker
/// who has just recorded three minutes of narration mostly wants to know they
/// haven't lost it. We never claim a cause we can't identify — the fallback is
/// honest about being unexpected rather than inventing a reason.
enum AuthoringErrorText {

    static func message(for error: Error) -> String {
        // Offline / timeout / connection lost — by far the most common failure
        // for someone uploading audio from a phone, and the most reassuring to
        // name precisely.
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet:
                return "You're offline. Nothing was lost — reconnect and try again."
            case NSURLErrorTimedOut:
                return "That took too long and timed out. Your work is still here — try again."
            case NSURLErrorNetworkConnectionLost, NSURLErrorCannotConnectToHost,
                 NSURLErrorCannotFindHost, NSURLErrorDNSLookupFailed:
                return "The connection dropped part-way. Nothing was lost — try again."
            default:
                return "Something went wrong with the connection. Your work is still here — try again."
            }
        }

        let text = "\(error)".lowercased()

        // Row-level security rejected the write. In practice this means the
        // session expired or the tour is no longer editable in its current
        // status — not something a retry fixes.
        if text.contains("row-level security") || text.contains("permission denied")
            || text.contains("jwt") || text.contains("401") || text.contains("403") {
            return "You don't have permission to change this right now. Try signing out and back in."
        }

        // A published tour can't be edited directly by its owner under the
        // moderation policy; surfaced plainly rather than as a constraint name.
        if text.contains("violates check constraint") || text.contains("status") && text.contains("constraint") {
            return "That change isn't allowed while the tour is in this state."
        }

        if text.contains("payload too large") || text.contains("413") {
            return "That file is too large to upload. Try a shorter recording or a smaller photo."
        }

        if text.contains("duplicate key") {
            return "That's already saved."
        }

        // Deliberately does not guess. An unrecognised failure is reported as
        // unrecognised — inventing a plausible cause is worse than admitting we
        // don't know, because the maker will act on it.
        return "Something went wrong and the change wasn't saved. Your work is still here — try again."
    }
}
