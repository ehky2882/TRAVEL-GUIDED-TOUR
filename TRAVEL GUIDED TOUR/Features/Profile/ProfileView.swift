import SwiftUI

/// The Me tab — the signed-in user's own profile.
///
/// A profile IS a maker page (owner direction, 2026-07-01: "each maker
/// should be thought of like a user too"), so a signed-in user's
/// profile renders through `MakerView(mode: .ownProfile)` — the exact
/// same component as any public maker page, for visual continuity.
/// Settings now lives behind the gear inside that view.
///
/// **One login = one profile** (owner decision, 2026-07-01): the profile
/// starts empty and fills as the user creates tours under it. The seven
/// seed studios stay as separate public maker pages. A signed-out user
/// has no profile yet, so they see a sign-in prompt (with Settings still
/// reachable via the gear).
struct ProfileView: View {
    @Environment(AuthService.self) private var authService

    var body: some View {
        if authService.isSignedIn {
            NavigationStack {
                MakerView(maker: ownMaker, mode: .ownProfile)
            }
        } else {
            SignedOutProfileView()
        }
    }

    /// The signed-in user rendered as a `Maker` so the profile can reuse
    /// `MakerView`. Increment 1: synthesized from the auth account
    /// (id = user id, name = the email's local-part). `DataService`
    /// finds no catalog tours owned by this id yet, so the feed is empty
    /// until the create flow (next increment) adds tours under this user.
    private var ownMaker: Maker {
        Maker(
            id: authService.userId ?? Self.placeholderId,
            displayName: displayName,
            avatarURL: nil,
            avatarEmoji: nil,
            bio: "",
            websiteURL: nil
        )
    }

    private var displayName: String {
        if let email = authService.email,
           let local = email.split(separator: "@").first {
            return String(local)
        }
        return "You"
    }

    /// Stable fallback id if somehow signed in without a user id.
    private static let placeholderId =
        UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
}

/// Signed-out state for the Me tab: a prompt to sign in (their profile
/// doesn't exist until they do), with the gear still opening Settings so
/// appearance / location / downloads stay reachable while signed out.
private struct SignedOutProfileView: View {
    @State private var showingSignIn = false
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            VStack(spacing: AtlasSpacing.lg) {
                Spacer()

                Image(systemName: "person.crop.circle")
                    .font(.system(size: 72))
                    .foregroundStyle(AtlasColors.secondaryText)

                Text("YOUR PROFILE")
                    .font(AtlasTypography.body)
                    .textCase(.uppercase)
                    .foregroundStyle(AtlasColors.primaryText)

                Text("Sign in to create your profile and publish audio tours.")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AtlasSpacing.xl)

                Button {
                    showingSignIn = true
                } label: {
                    Text("Sign in")
                        .font(AtlasTypography.body)
                        .padding(.horizontal, AtlasSpacing.xl)
                        .padding(.vertical, AtlasSpacing.md)
                        .background(AtlasColors.mapPin)
                        .foregroundStyle(AtlasColors.background)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AtlasColors.secondaryBackground)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: AtlasBottomModule.height())
            }
            .navigationTitle("")
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showingSignIn) { SignInView() }
            .sheet(isPresented: $showingSettings) { SettingsView() }
        }
    }
}
