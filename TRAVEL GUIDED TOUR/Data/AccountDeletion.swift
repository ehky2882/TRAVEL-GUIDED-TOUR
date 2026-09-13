import Foundation

/// The body sent to the `delete-account` Edge Function.
///
/// 🔴 It deliberately has **no user id**. The function deletes only the account
/// whose verified session made the call (`backend/functions/delete-account`),
/// so there is nothing here that could point it at anyone else — and
/// `AccountDeletionTests` fails if a field that could is ever added.
struct AccountDeletionRequest: Encodable, Equatable {
    /// A fresh Sign in with Apple authorization code, for accounts that sign in
    /// with Apple: the function exchanges it and revokes Dozent's tokens, which
    /// Apple requires when an account is deleted. `nil` for everyone else.
    let appleAuthorizationCode: String?
}

/// A `delete-account` call that did not succeed, carrying the message to show.
///
/// Every step on the server is safe to repeat and the login is deleted last,
/// so every failure here is one the person can simply retry.
struct AccountDeletionError: LocalizedError, Equatable {
    let status: Int
    let serverMessage: String?

    init(status: Int, body: Data) {
        self.status = status
        struct Body: Decodable { let error: String? }
        let message = (try? JSONDecoder().decode(Body.self, from: body))?.error?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        self.serverMessage = (message?.isEmpty ?? true) ? nil : message
    }

    var errorDescription: String? {
        if status == 401 {
            return "Your sign-in has expired. Sign out, sign back in, and try again."
        }
        let lead = serverMessage ?? "We couldn't finish deleting your account. Please try again."
        return lead + " If it keeps failing, write to hello@dozent.world."
    }
}

/// On-device data belonging to one account.
enum LocalAccountData {
    /// Remove every `UserDefaults` value scoped to `uid` — the entitlement
    /// cache (`atlas.entitlements.<uid>`), unrecorded purchases
    /// (`atlas.pendingPurchases.<uid>`) and profile snapshots
    /// (`profileSnapshot.<name>.<uid>`). Signing out keeps these so signing
    /// back in is instant; after the account is deleted there is nothing to
    /// sign back in to. Matching on the id suffix rather than a list of keys
    /// means a future per-account store is covered without anyone remembering.
    static func forget(uid: String, defaults: UserDefaults = .standard) {
        let needle = uid.lowercased()
        guard !needle.isEmpty else { return }
        for key in defaults.dictionaryRepresentation().keys
        where key.lowercased().hasSuffix(needle) {
            defaults.removeObject(forKey: key)
        }
    }
}
