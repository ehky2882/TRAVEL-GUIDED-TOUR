import Foundation
import Observation
import Supabase

/// App-wide authentication state, wrapping `supabase.auth`.
///
/// V2 Step 3 (accounts/auth), first cut: **email/password**. Apple + Google
/// sign-in land as additional methods in follow-ups (the `SupabaseClient` and
/// this service are the shared foundation they'll build on).
///
/// supabase-swift persists the session in the Keychain and refreshes tokens
/// automatically, so a signed-in user stays signed in across launches. We mirror
/// its session into an `@Observable` `user` so SwiftUI views react to sign-in /
/// sign-out. Anonymous use of the app is unaffected — nothing here gates content.
@MainActor
@Observable
final class AuthService {
    /// Result of a sign-up attempt. With Supabase email-confirmation ON (the
    /// default), a new sign-up returns no session until the user confirms via
    /// the emailed link — so the UI shows a "check your email" message rather
    /// than a signed-in state.
    enum SignUpOutcome {
        case signedIn
        case confirmationRequired
    }

    /// The currently signed-in user, or `nil` when signed out. Drives the UI.
    private(set) var user: User?

    var isSignedIn: Bool { user != nil }
    var email: String? { user?.email }

    private let client: SupabaseClient
    private var observation: Task<Void, Never>?

    init(client: SupabaseClient = SupabaseClientProvider.shared) {
        self.client = client
        // Seed synchronously from any persisted session so the UI doesn't flash
        // signed-out on launch; the stream below keeps it in sync thereafter.
        self.user = client.auth.currentUser
        observation = Task { [weak self] in
            for await (event, session) in client.auth.authStateChanges {
                guard let self else { return }
                switch event {
                case .signedOut:
                    self.user = nil
                default:
                    // .initialSession / .signedIn / .tokenRefreshed / .userUpdated
                    self.user = session?.user
                }
            }
        }
    }

    /// Create an account with email + password. Returns `.signedIn` if a session
    /// came back immediately (email-confirmation disabled), else
    /// `.confirmationRequired`.
    func signUp(email: String, password: String) async throws -> SignUpOutcome {
        let response = try await client.auth.signUp(email: email, password: password)
        return response.session != nil ? .signedIn : .confirmationRequired
    }

    /// Sign in with an existing email + password. The `authStateChanges` stream
    /// publishes the resulting session into `user`.
    func signIn(email: String, password: String) async throws {
        _ = try await client.auth.signIn(email: email, password: password)
    }

    /// Sign in with Apple. The view performs the native `ASAuthorization` flow
    /// (passing a SHA256-hashed nonce to Apple) and hands us the resulting
    /// identity token plus the *raw* nonce; Supabase verifies the token's `iss`
    /// against the configured Apple client IDs and the nonce against the hash.
    func signInWithApple(idToken: String, nonce: String) async throws {
        _ = try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
    }

    /// Sign out everywhere and clear the local session.
    func signOut() async throws {
        try await client.auth.signOut()
    }
}
