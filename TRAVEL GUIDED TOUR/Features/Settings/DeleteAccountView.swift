import SwiftUI
import AuthenticationServices

/// Settings → Account → Delete account.
///
/// Apple App Review Guideline 5.1.1(v): an app that offers account creation
/// must let people start deleting the account from inside the app. What this
/// screen promises is what the privacy policy already says — "we remove your
/// profile, synced library and creator content; records we must keep for legal
/// or financial reasons are retained in minimal form" — and what
/// `backend/functions/delete-account` does. Keep the three in step.
///
/// Irreversible, so it takes two deliberate steps: this explanation, then a
/// confirmation dialog. Accounts that sign in with Apple add one more — a fresh
/// Apple authorization, which both confirms it is really them and lets the
/// server revoke Dozent's Apple tokens, as Apple requires.
struct DeleteAccountView: View {
    @Environment(AuthService.self) private var authService
    @Environment(PurchaseService.self) private var purchaseService
    @Environment(\.dismiss) private var dismiss

    private enum Phase { case explaining, confirmingWithApple, deleting, deleted }

    @State private var phase: Phase = .explaining
    @State private var showingConfirmation = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AtlasSpacing.lg) {
                if phase == .deleted {
                    deletedState
                } else {
                    explanation
                    actions
                }
            }
            .padding(AtlasSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(AtlasTypography.caption)
        .foregroundStyle(AtlasColors.primaryText)
        .background(AtlasColors.secondaryBackground)
        .navigationTitle("Delete account")
        .inlineNavigationBarTitle()
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("DELETE ACCOUNT")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.primaryText)
            }
        }
        // Once the request is in flight there is no going back to a screen
        // for an account that may already be gone.
        .navigationBarBackButtonHidden(phase == .deleting || phase == .deleted)
        .confirmationDialog(
            "Delete your account?",
            isPresented: $showingConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete account", role: .destructive) { confirmed() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes your Dozent account. It can't be undone.")
        }
    }

    // MARK: - Explanation

    private var explanation: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.lg) {
            VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                Text("Deleting your account is permanent and can't be undone.")
                    .bold()
                if let email = authService.email {
                    Text("Signed in as \(email)")
                        .foregroundStyle(AtlasColors.secondaryText)
                }
            }

            group("What we remove", [
                "Your profile and creator page: name, photo, bio and links.",
                "Your synced library, saved places and lists, and your listening and search history.",
                "Who you follow, and who follows you.",
                "Tours you created that nobody has bought, with their audio and photos.",
            ])

            group("What we keep, in minimal form", [
                "Purchase records, with your account removed from them. We need these for tax and accounting.",
                "If someone bought a tour you created, it stays available to them, credited to \"Former creator\" instead of you.",
            ])

            if !purchaseService.entitlements.isEmpty {
                group("Tours you bought", [
                    "They belong to this account. Once it's deleted they can't be moved to a new account, and deleting doesn't cancel or refund anything with Apple.",
                ])
            }

            group("On this device", [
                "Downloaded tours stay until you remove them in Manage downloads.",
            ])

            Link("Read the Privacy Policy", destination: AtlasLegalLinks.privacy)
                .foregroundStyle(AtlasColors.secondaryText)
                .underline()
        }
    }

    private func group(_ title: String, _ lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            Text(title)
                .foregroundStyle(AtlasColors.secondaryText)
                .textCase(.uppercase)
            ForEach(lines, id: \.self) { line in
                HStack(alignment: .firstTextBaseline, spacing: AtlasSpacing.sm) {
                    Text("•")
                    Text(line).fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Actions

    @ViewBuilder
    private var actions: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.md) {
            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(AtlasColors.mapPin)
                    .fixedSize(horizontal: false, vertical: true)
            }

            switch phase {
            case .explaining:
                Button(role: .destructive) {
                    errorMessage = nil
                    showingConfirmation = true
                } label: {
                    Text("Delete my account")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AtlasSpacing.sm)
                }
                .buttonStyle(.bordered)

            case .confirmingWithApple:
                Text("One more step: confirm with Apple. This also disconnects Dozent from your Apple ID.")
                    .fixedSize(horizontal: false, vertical: true)
                SignInWithAppleButton(.continue) { request in
                    request.requestedScopes = []
                } onCompletion: { result in
                    handleApple(result)
                }
                .signInWithAppleButtonStyle(.whiteOutline)
                .frame(height: 48)
                .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.sm))
                Button("Cancel") { phase = .explaining }
                    .foregroundStyle(AtlasColors.secondaryText)
                    .frame(maxWidth: .infinity)

            case .deleting:
                HStack(spacing: AtlasSpacing.sm) {
                    ProgressView()
                    Text("Deleting your account…")
                }
                .frame(maxWidth: .infinity)

            case .deleted:
                EmptyView()
            }
        }
    }

    private var deletedState: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.md) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 32))
                .foregroundStyle(AtlasColors.brass)
            Text("Your account has been deleted.")
                .bold()
            Text("We've removed your profile, synced library and creator content, and signed you out on this device.")
                .fixedSize(horizontal: false, vertical: true)
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AtlasSpacing.sm)
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Flow

    private func confirmed() {
        if authService.usesSignInWithApple {
            phase = .confirmingWithApple
        } else {
            delete(appleAuthorizationCode: nil)
        }
    }

    private func handleApple(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let codeData = credential.authorizationCode,
                let code = String(data: codeData, encoding: .utf8)
            else {
                errorMessage = "Apple didn't confirm it's you. Please try again."
                return
            }
            delete(appleAuthorizationCode: code)
        case .failure(let error):
            // Cancelling the Apple sheet just leaves this step open.
            if (error as? ASAuthorizationError)?.code != .canceled {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func delete(appleAuthorizationCode: String?) {
        errorMessage = nil
        phase = .deleting
        Task {
            do {
                try await authService.deleteAccount(appleAuthorizationCode: appleAuthorizationCode)
                phase = .deleted
            } catch {
                errorMessage = error.localizedDescription
                phase = .explaining
            }
        }
    }
}
