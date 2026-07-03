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
    /// The signed-in user's id as a plain `UUID` (nil when anonymous). Lets
    /// views reference it without importing the Supabase module.
    var userId: UUID? { user?.id }

    /// Async hook invoked *before* the session is torn down in `signOut()`,
    /// while the access token (and `user`) are still valid. `SyncService`
    /// registers this to flush any pending debounced write-through — a
    /// save/un-save made within the 2s debounce window — up to Supabase, so a
    /// sign-out immediately after a change can't strand it locally (which would
    /// otherwise "resurrect" the change on next sign-in via the additive merge).
    /// Stored as a plain closure; `SyncService` captures itself weakly, so this
    /// creates no retain cycle even though `SyncService` holds `AuthService`.
    var preSignOut: (() async -> Void)?

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

    /// Sign in with Google via the OAuth web flow. supabase-swift opens an
    /// `ASWebAuthenticationSession` to Google, then completes the session when
    /// Google redirects back to our `dozent://login-callback` deep link. No
    /// Google SDK needed; the redirect URL must be allow-listed in Supabase.
    func signInWithGoogle() async throws {
        _ = try await client.auth.signInWithOAuth(
            provider: .google,
            redirectTo: SupabaseConfig.oauthRedirectURL
        )
    }

    /// Send a password-reset email. Supabase emails a recovery link; opening it
    /// returns to the app (`dozent://login-callback`) with a recovery session so
    /// the user can set a new password.
    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(
            email,
            redirectTo: SupabaseConfig.oauthRedirectURL
        )
    }

    /// Sign out everywhere and clear the local session.
    ///
    /// Flushes any pending local writes (`preSignOut`) *first*, while the token
    /// and `user` id are still valid — `client.auth.signOut()` clears them, and
    /// `SyncService.handleSignedOut` (which then runs off the auth-state change)
    /// sees a nil user and can no longer push. So the flush must happen here,
    /// before the session ends. Best-effort: the hook swallows its own errors,
    /// so an offline flush never blocks sign-out.
    func signOut() async throws {
        await preSignOut?()
        try await client.auth.signOut()
    }
}
