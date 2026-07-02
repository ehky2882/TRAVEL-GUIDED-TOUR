import SwiftUI

/// Create / edit the signed-in user's creator profile (V2 Step 4, increment 2a).
///
/// Presented from the own-profile (Me tab). Writes a real `makers` row to
/// Supabase via `MakerProfileService` — the first time this runs it creates the
/// profile (turning the synthesized placeholder into a persisted, cross-device
/// profile); afterwards it edits it. Avatar editing comes in a later increment.
struct ProfileEditorView: View {
    /// Current profile values to prefill (the real maker if it exists, else the
    /// synthesized placeholder).
    let currentMaker: Maker

    @Environment(MakerProfileService.self) private var service
    @Environment(\.dismiss) private var dismiss

    @State private var displayName: String
    @State private var bio: String
    @State private var website: String
    @State private var isSaving = false
    @State private var errorMessage: String?
    @FocusState private var focused: Field?

    private enum Field { case name, bio, website }

    init(currentMaker: Maker) {
        self.currentMaker = currentMaker
        _displayName = State(initialValue: currentMaker.displayName)
        _bio = State(initialValue: currentMaker.bio)
        _website = State(initialValue: currentMaker.websiteURL ?? "")
    }

    private var trimmedName: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var canSave: Bool { !isSaving && !trimmedName.isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AtlasSpacing.lg) {
                    fieldLabel("DISPLAY NAME")
                    TextField("Your creator name", text: $displayName)
                        .focused($focused, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { focused = .bio }
                        .fieldStyle()

                    fieldLabel("BIO")
                    TextField("A sentence about you or your tours", text: $bio, axis: .vertical)
                        .lineLimit(3...6)
                        .focused($focused, equals: .bio)
                        .fieldStyle()

                    fieldLabel("WEBSITE (OPTIONAL)")
                    TextField("https://…", text: $website)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focused, equals: .website)
                        .submitLabel(.done)
                        .fieldStyle()

                    if let errorMessage {
                        Text(errorMessage)
                            .font(AtlasTypography.caption)
                            .foregroundStyle(AtlasColors.mapPin)
                    }

                    saveButton
                        .padding(.top, AtlasSpacing.sm)
                }
                .padding(AtlasSpacing.lg)
            }
            .background(AtlasColors.secondaryBackground)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("")
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("EDIT PROFILE")
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

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(AtlasTypography.caption)
            .foregroundStyle(AtlasColors.secondaryText)
    }

    private var saveButton: some View {
        Button(action: save) {
            HStack {
                Spacer()
                if isSaving {
                    ProgressView().tint(AtlasColors.background)
                } else {
                    Text("Save").font(AtlasTypography.caption)
                }
                Spacer()
            }
            .padding(.vertical, AtlasSpacing.md)
            .background(canSave ? AtlasColors.mapPin : AtlasColors.mapPin.opacity(0.4))
            .foregroundStyle(AtlasColors.background)
            .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.sm))
        }
        .disabled(!canSave)
    }

    private func save() {
        focused = nil
        errorMessage = nil
        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                try await service.saveProfile(
                    displayName: displayName,
                    bio: bio,
                    websiteURL: website
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

private extension View {
    /// Shared field chrome — matches SignInView's fields.
    func fieldStyle() -> some View {
        self
            .font(AtlasTypography.caption)
            .padding(AtlasSpacing.md)
            .background(AtlasColors.background)
            .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.sm))
    }
}
