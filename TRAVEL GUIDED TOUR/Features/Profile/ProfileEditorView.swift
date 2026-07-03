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
    @State private var link2: String
    @State private var link3: String
    @State private var isSaving = false
    @State private var errorMessage: String?
    @FocusState private var focused: Field?

    private enum Field { case name, bio, website, link2, link3 }

    /// Max display-name length (owner direction 2026-07-03).
    private static let nameLimit = 40

    init(currentMaker: Maker) {
        self.currentMaker = currentMaker
        _displayName = State(initialValue: currentMaker.displayName)
        _bio = State(initialValue: currentMaker.bio)
        _website = State(initialValue: currentMaker.websiteURL ?? "")
        _link2 = State(initialValue: currentMaker.link2URL ?? "")
        _link3 = State(initialValue: currentMaker.link3URL ?? "")
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
                        .onChange(of: displayName) { _, new in
                            if new.count > Self.nameLimit {
                                displayName = String(new.prefix(Self.nameLimit))
                            }
                        }
                        .fieldStyle()

                    fieldLabel("BIO")
                    TextField("A sentence about you or your tours", text: $bio, axis: .vertical)
                        .lineLimit(3...6)
                        .focused($focused, equals: .bio)
                        .fieldStyle()

                    fieldLabel("LINKS (OPTIONAL — UP TO 3)")
                    linkField("https://…", text: $website, field: .website, next: .link2)
                    linkField("https://…", text: $link2, field: .link2, next: .link3)
                    linkField("https://…", text: $link3, field: .link3, next: nil)

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

    /// A URL text field for one of the up-to-3 profile links. `next` focuses the
    /// following link field on return (nil = last field → dismiss keyboard).
    private func linkField(
        _ placeholder: String,
        text: Binding<String>,
        field: Field,
        next: Field?
    ) -> some View {
        TextField(placeholder, text: text)
            .textContentType(.URL)
            .keyboardType(.URL)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused($focused, equals: field)
            .submitLabel(next == nil ? .done : .next)
            .onSubmit { focused = next }
            .fieldStyle()
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
                    websiteURL: website,
                    link2URL: link2,
                    link3URL: link3
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
