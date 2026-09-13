import Foundation

/// The rules for a Dozent username (`makers.handle`), as far as the app needs
/// them. Design: `docs/usernames-design.md`.
///
/// 🔴 **The database is the authority, not this file.** `backend/usernames.sql`
/// enforces every rule — format, reserved words, pinned creators' handles, the
/// 30-day limit, uniqueness — in a trigger that holds for every build ever
/// shipped. What lives here is only what gives instant feedback while typing:
/// the FORMAT rules, worded exactly as the server words them. Reserved words
/// and availability come from `handle_available()`.
enum Username {
    static let minLength = 3
    static let maxLength = 24

    /// What the server stores for what was typed: trimmed, no leading `@`,
    /// lowercase. `  @KathyNg ` → `kathyng`.
    static func normalise(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        while s.hasPrefix("@") { s.removeFirst() }
        return s.lowercased()
    }

    /// Why this (already normalised) username breaks a format rule, or nil.
    /// Mirrors `public.handle_problem` in `backend/usernames.sql`, same order,
    /// same words, so the line under the field never disagrees with a save.
    static func formatProblem(_ h: String) -> String? {
        if h.isEmpty { return "is empty" }
        if h.count < minLength || h.count > maxLength { return "must be 3 to 24 characters" }
        let allowed = Set("abcdefghijklmnopqrstuvwxyz0123456789._")
        if !h.allSatisfy({ allowed.contains($0) }) { return "may use only letters, numbers, . and _" }
        let edge = Set("abcdefghijklmnopqrstuvwxyz0123456789")
        if let f = h.first, let l = h.last, !(edge.contains(f) && edge.contains(l)) {
            return "must start and end with a letter or number"
        }
        if h.contains("..") { return "may not have two dots in a row" }
        if !h.contains(where: { $0.isLetter }) { return "must contain a letter" }
        return nil
    }

    /// The answer to "is this username free?" — `handle_available()`'s reply.
    enum Availability: Equatable {
        case available
        /// Already this person's own username.
        case yours
        case taken
        case reserved
        case invalid(String)
        /// Could not ask (offline, timeout, an answer this build does not
        /// know). Not a refusal: the save still goes to the server, which
        /// decides.
        case unknown

        init(server value: String) {
            switch value {
            case "available": self = .available
            case "yours":     self = .yours
            case "taken":     self = .taken
            case "reserved":  self = .reserved
            default:
                let prefix = "invalid: "
                self = value.hasPrefix(prefix) ? .invalid(String(value.dropFirst(prefix.count))) : .unknown
            }
        }
    }

    /// Words for a failed username save. `23505` is the unique index losing a
    /// race (two people, one handle, the same second); `23514` carries the
    /// trigger's own message, which is already written for a person.
    static func friendlyMessage(code: String?, message: String) -> String {
        switch code {
        case "23505": return "That username was just taken. Try another."
        case "23514": return message
        default:      return "Couldn't change your username. Please try again."
        }
    }
}
