import SwiftUI

/// Email/password sign-in + sign-up sheet (V2 Step 3, first cut).
///
/// Presented from the Me tab's Account row. Toggles between "Sign in" and
/// "Create account"; on a successful sign-in it dismisses, and on a sign-up that
/// needs email confirmation it shows a "check your email" message instead.
/// Apple / Google buttons will be added here in follow-ups.
struct SignInView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss

    private enum Mode { case signIn, signUp }

    @State private var mode: Mode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var isWorking = false
    @State private var errorMessage: String?
    @State private var confirmationMessage: String?
    @FocusState private var focused: Field?

    private enum Field { case email, password }

    private var title: String { mode == .signIn ? "SIGN IN" : "CREATE ACCOUNT" }
    private var submitLabel: String { mode == .signIn ? "Sign in" : "Create account" }
    private var switchPrompt: String {
        mode == .signIn ? "No account? Create one" : "Have an account? Sign in"
    }
    private var canSubmit: Bool {
        !isWorking && email.contains("@") && password.count >= 6
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AtlasSpacing.lg) {
                if let confirmationMessage {
                    confirmationState(confirmationMessage)
                } else {
                    formFields
                    if let errorMessage {
                        Text(errorMessage)
                            .font(AtlasTypography.caption)
                            .foregroundStyle(AtlasColors.mapPin)
                    }
                    submitButton
                    Button(switchPrompt) {
                        withAnimation { mode = mode == .signIn ? .signUp : .signIn }
                        errorMessage = nil
                    }
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
                    .frame(maxWidth: .infinity)
                }
                Spacer()
            }
            .padding(AtlasSpacing.lg)
            .background(AtlasColors.secondaryBackground)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.primaryText)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .font(AtlasTypography.caption)
                        .tint(AtlasColors.primaryText)
                }
            }
        }
    }

    private var formFields: some View {
        VStack(spacing: AtlasSpacing.md) {
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focused, equals: .email)
                .submitLabel(.next)
                .onSubmit { focused = .password }
                .fieldStyle()

            SecureField("Password", text: $password)
                .textContentType(mode == .signIn ? .password : .newPassword)
                .focused($focused, equals: .password)
                .submitLabel(.go)
                .onSubmit { if canSubmit { submit() } }
                .fieldStyle()
        }
    }

    private var submitButton: some View {
        Button(action: submit) {
            HStack {
                Spacer()
                if isWorking {
                    ProgressView().tint(AtlasColors.background)
                } else {
                    Text(submitLabel).font(AtlasTypography.caption)
                }
                Spacer()
            }
            .padding(.vertical, AtlasSpacing.md)
            .background(canSubmit ? AtlasColors.mapPin : AtlasColors.mapPin.opacity(0.4))
            .foregroundStyle(AtlasColors.background)
            .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.sm))
        }
        .disabled(!canSubmit)
    }

    private func confirmationState(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.md) {
            Image(systemName: "envelope.badge")
                .font(.system(size: 32))
                .foregroundStyle(AtlasColors.mapPin)
            Text(message)
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.primaryText)
            Button("Back to sign in") {
                withAnimation {
                    confirmationMessage = nil
                    mode = .signIn
                    password = ""
                }
            }
            .font(AtlasTypography.caption)
            .foregroundStyle(AtlasColors.secondaryText)
        }
    }

    private func submit() {
        focused = nil
        errorMessage = nil
        isWorking = true
        Task {
            defer { isWorking = false }
            do {
                switch mode {
                case .signIn:
                    try await authService.signIn(email: email, password: password)
                    dismiss()
                case .signUp:
                    let outcome = try await authService.signUp(email: email, password: password)
                    switch outcome {
                    case .signedIn:
                        dismiss()
                    case .confirmationRequired:
                        withAnimation {
                            confirmationMessage =
                                "We sent a confirmation link to \(email). Tap it, then come back and sign in."
                        }
                    }
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

private extension View {
    /// Shared field chrome — matches the app's secondary-surface look.
    func fieldStyle() -> some View {
        self
            .font(AtlasTypography.caption)
            .padding(AtlasSpacing.md)
            .background(AtlasColors.background)
            .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.sm))
    }
}
