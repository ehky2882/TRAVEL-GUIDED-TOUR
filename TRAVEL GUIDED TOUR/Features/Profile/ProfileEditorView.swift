import SwiftUI
import PhotosUI
import UIKit

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
    // Avatar editing state.
    @State private var avatarURL: String?           // kept/uploaded photo URL
    @State private var avatarInitials: String
    @State private var avatarColorHex: String?
    @State private var pickedItem: PhotosPickerItem?
    @State private var pickedImageData: Data?        // cropped square JPEG, pre-upload
    @State private var isSaving = false
    @State private var errorMessage: String?
    @FocusState private var focused: Field?

    private enum Field { case name, bio, website, link2, link3, initials }

    /// Max display-name length (owner direction 2026-07-03).
    private static let nameLimit = 40

    init(currentMaker: Maker) {
        self.currentMaker = currentMaker
        _displayName = State(initialValue: currentMaker.displayName)
        _bio = State(initialValue: currentMaker.bio)
        _website = State(initialValue: currentMaker.websiteURL ?? "")
        _link2 = State(initialValue: currentMaker.link2URL ?? "")
        _link3 = State(initialValue: currentMaker.link3URL ?? "")
        _avatarURL = State(initialValue: currentMaker.avatarURL)
        _avatarInitials = State(initialValue: currentMaker.avatarInitials ?? "")
        _avatarColorHex = State(initialValue: currentMaker.avatarColor)
    }

    /// True while an uploaded/kept photo is the active avatar (vs. the
    /// initials-on-colour mode).
    private var usingPhoto: Bool {
        pickedImageData != nil || (avatarURL?.isEmpty == false)
    }

    private var trimmedName: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var canSave: Bool { !isSaving && !trimmedName.isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AtlasSpacing.lg) {
                    avatarSection

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
            // Reserve space for the mini-player + tab bar (a separate, higher
            // window that overlays even this sheet) so the Save button at the
            // bottom of the form scrolls clear of it and stays tappable.
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: AtlasBottomModule.height())
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

    // MARK: - Avatar

    private var avatarSection: some View {
        VStack(spacing: AtlasSpacing.md) {
            avatarPreview
                .frame(width: 96, height: 96)

            PhotosPicker(
                selection: $pickedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Text(usingPhoto ? "Change photo" : "Upload a photo")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(Color.blue)
            }
            .onChange(of: pickedItem) { _, item in
                Task { await loadPicked(item) }
            }

            if usingPhoto {
                Button("Use initials instead") { clearPhoto() }
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
            } else {
                initialsAndColor
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// Live preview: the freshly-picked photo if any, else the shared avatar
    /// resolved from the current editor state (kept photo / initials+colour /
    /// derived monogram).
    private var avatarPreview: some View {
        Group {
            if let data = pickedImageData, let ui = UIImage(data: data) {
                Image(uiImage: ui).resizable().scaledToFill()
                    .frame(width: 96, height: 96)
                    .clipShape(Circle())
            } else {
                MakerAvatarView(maker: previewMaker, size: 96)
            }
        }
    }

    /// A synthesized maker mirroring the current editor state, for the preview.
    private var previewMaker: Maker {
        Maker(
            id: currentMaker.id,
            displayName: displayName,
            avatarURL: usingPhoto ? avatarURL : nil,
            avatarEmoji: currentMaker.avatarEmoji,
            bio: "",
            websiteURL: nil,
            avatarInitials: avatarInitials.isEmpty ? nil : avatarInitials,
            avatarColor: avatarColorHex
        )
    }

    private var initialsAndColor: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            fieldLabel("INITIALS")
            TextField("e.g. AB", text: $avatarInitials)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .focused($focused, equals: .initials)
                .onChange(of: avatarInitials) { _, new in
                    let up = new.uppercased()
                    avatarInitials = up.count > 2 ? String(up.prefix(2)) : up
                }
                .fieldStyle()

            fieldLabel("COLOUR")
            colorSwatches
        }
    }

    private var colorSwatches: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AtlasSpacing.sm), count: 5),
                  spacing: AtlasSpacing.sm) {
            ForEach(MakerAvatarView.palette, id: \.self) { hex in
                Circle()
                    .fill(Color(atlasHex: hex) ?? .gray)
                    .frame(height: 40)
                    .overlay(
                        Circle().stroke(AtlasColors.primaryText,
                                        lineWidth: avatarColorHex == hex ? 3 : 0)
                    )
                    .onTapGesture { avatarColorHex = hex }
            }
        }
    }

    /// Load the picked photo → square-crop → hold as `pickedImageData` (uploaded
    /// on Save). Switching to a photo drops the initials/colour choice.
    private func loadPicked(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else { return }
            pickedImageData = Self.squareJPEG(data)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func clearPhoto() {
        pickedImageData = nil
        avatarURL = nil
        pickedItem = nil
    }

    /// Aspect-fill crop to a centred square JPEG for the avatar.
    private static func squareJPEG(_ data: Data, side: CGFloat = 512) -> Data? {
        guard let img = UIImage(data: data) else { return nil }
        let size = CGSize(width: side, height: side)
        let out = UIGraphicsImageRenderer(size: size).image { _ in
            let scale = max(side / img.size.width, side / img.size.height)
            let w = img.size.width * scale
            let h = img.size.height * scale
            img.draw(in: CGRect(x: (side - w) / 2, y: (side - h) / 2, width: w, height: h))
        }
        return out.jpegData(compressionQuality: 0.85)
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
                // Upload a freshly-picked photo first (creates the maker row if
                // needed), then persist. A photo wins; otherwise initials+colour.
                var finalAvatarURL = avatarURL
                if let data = pickedImageData {
                    finalAvatarURL = try await service.uploadAvatar(data)
                }
                let hasPhoto = finalAvatarURL?.isEmpty == false
                try await service.saveProfile(
                    displayName: displayName,
                    bio: bio,
                    websiteURL: website,
                    link2URL: link2,
                    link3URL: link3,
                    avatarURL: hasPhoto ? finalAvatarURL : nil,
                    avatarInitials: hasPhoto ? nil : avatarInitials,
                    avatarColor: hasPhoto ? nil : avatarColorHex
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
