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
    @Environment(MakerProfileService.self) private var makerProfileService
    @Environment(MakerTourService.self) private var makerTourService
    @Environment(DataService.self) private var dataService

    var body: some View {
        if authService.isSignedIn {
            NavigationStack {
                MakerView(maker: ownMaker, mode: .ownProfile)
            }
            // Load (or clear) the real maker row + the user's own tours on
            // sign-in / sign-out. `.task(id:)` re-fires when the user id changes.
            .task(id: authService.userId) {
                await makerProfileService.loadMyMaker()
                if let makerId = makerProfileService.myMaker?.id {
                    await makerTourService.loadMyTours(makerId: makerId)
                } else {
                    makerTourService.clear()
                }
            }
            // Mirror the live maker row into the in-memory catalog so a
            // just-saved profile edit shows on the public maker page right
            // away, instead of waiting for the next catalog refresh.
            .onChange(of: makerProfileService.myMaker) { _, maker in
                if let maker { dataService.applyLocalMaker(maker) }
            }
        } else {
            SignedOutProfileView()
        }
    }

    /// The maker rendered on the profile. Once the user's real `makers` row
    /// is loaded (or just saved) it's used directly; until then — before the
    /// profile has ever been created — a placeholder synthesized from the
    /// auth account (name = the email's local-part) stands in, so the header
    /// isn't blank and "Edit Profile" prefills something sensible.
    private var ownMaker: Maker {
        makerProfileService.myMaker ?? placeholderMaker
    }

    private var placeholderMaker: Maker {
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

    /// The app's standard control diameter — map recenter / map-type buttons,
    /// tour-detail action buttons, search bar all use 44pt (also the iOS HIG
    /// minimum touch target). The icon + Sign-in button match it.
    private static let controlSize: CGFloat = 44

    var body: some View {
        NavigationStack {
            VStack(spacing: AtlasSpacing.md) {
                Spacer()

                Image(systemName: "person.crop.circle")
                    .font(.system(size: Self.controlSize))
                    .foregroundStyle(AtlasColors.secondaryText)

                Text("JOIN DOZENT")
                    .font(AtlasTypography.body)
                    .textCase(.uppercase)
                    .foregroundStyle(AtlasColors.primaryText)
                    .padding(.top, AtlasSpacing.xs)

                Text("Save tours, pick up on any device, and publish your own audio guides — free.")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AtlasSpacing.xl)

                Button {
                    showingSignIn = true
                } label: {
                    Text("Sign in")
                        .font(AtlasTypography.body)
                        .frame(height: Self.controlSize)
                        .padding(.horizontal, AtlasSpacing.xl)
                        .background(AtlasColors.mapPin)
                        .foregroundStyle(AtlasColors.background)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, AtlasSpacing.sm)

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
