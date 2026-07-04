import SwiftUI

/// Encourages a signed-out user to create an account. Used on the Me tab's
/// signed-out profile (`showIcon: true`) and appended below each Library empty
/// state (`showIcon: false`, so it doesn't repeat that state's own icon).
///
/// Renders nothing when already signed in, so callers can include it
/// unconditionally. Mono `caption` type throughout to match the Library /
/// empty-state voice.
struct JoinDozentPrompt: View {
    /// Show the leading person icon (the Me-tab hero uses it; the Library
    /// empty states already have their own icon above, so they pass false).
    var showIcon: Bool = true

    @Environment(AuthService.self) private var authService: AuthService?
    @State private var showingSignIn = false

    /// App-standard control diameter — map controls, tour-detail action
    /// buttons, and the search bar all use 44pt.
    private static let controlSize: CGFloat = 44

    var body: some View {
        if authService?.isSignedIn == false {
            VStack(spacing: AtlasSpacing.md) {
                if showIcon {
                    // Sized to the empty-state / control glyph (20pt), not the
                    // 44pt button diameter.
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(AtlasColors.secondaryText)
                }

                Text("JOIN DOZENT")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.primaryText)

                Text("Save tours, pick up on any device, and publish your own audio guides — free.")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AtlasSpacing.xl)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    showingSignIn = true
                } label: {
                    Text("Sign in")
                        .font(AtlasTypography.caption)
                        .frame(height: Self.controlSize)
                        .padding(.horizontal, AtlasSpacing.xl)
                        .background(AtlasColors.mapPin)
                        .foregroundStyle(AtlasColors.background)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, AtlasSpacing.xs)
            }
            // Extra separation from the empty-state text above it in Library.
            .padding(.top, showIcon ? 0 : AtlasSpacing.xl)
            .sheet(isPresented: $showingSignIn) { SignInView() }
        }
    }
}
