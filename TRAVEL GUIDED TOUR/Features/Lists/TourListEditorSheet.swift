import SwiftUI

/// Create/edit sheet for a list's metadata (title, description, public toggle).
/// `editing == nil` creates a new list (from Library or the membership sheet);
/// passing an existing one edits it in place.
///
/// Naming note: the type and the Supabase tables are still `TourList` —
/// user-facing copy says "list" (owner direction). Renaming the symbols and
/// tables is a separate, purely cosmetic change.
struct TourListEditorSheet: View {
    /// The list being edited, or nil to create a new one.
    let editing: TourList?

    @Environment(TourListService.self) private var listService
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var description: String
    @State private var isPublic: Bool
    @State private var isSaving = false
    @State private var errorText: String?

    private let titleLimit = 60
    private let descriptionLimit = 200

    init(editing: TourList? = nil) {
        self.editing = editing
        _title = State(initialValue: editing?.title ?? "")
        _description = State(initialValue: editing?.description ?? "")
        _isPublic = State(initialValue: editing?.isPublic ?? false)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                        .onChange(of: title) { _, new in
                            if new.count > titleLimit { title = String(new.prefix(titleLimit)) }
                        }
                } header: {
                    Text("Title")
                } footer: {
                    Text("\(titleLimit - title.count) left")
                        .foregroundStyle(title.count >= titleLimit ? .red : AtlasColors.tertiaryText)
                }

                Section {
                    TextField("What's this list about?", text: $description, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                        .onChange(of: description) { _, new in
                            if new.count > descriptionLimit { description = String(new.prefix(descriptionLimit)) }
                        }
                } header: {
                    Text("Description (optional)")
                }

                Section {
                    Toggle("Public", isOn: $isPublic)
                } footer: {
                    Text(isPublic
                         ? "Anyone with the link can view this list."
                         : "Only you can see this list.")
                }

                if let errorText {
                    Section {
                        Text(errorText).foregroundStyle(.red).font(AtlasTypography.caption)
                    }
                }
            }
            .navigationTitle(editing == nil ? "New list" : "Edit list")
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(editing == nil ? "Create" : "Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
        }
    }

    private func save() {
        isSaving = true
        errorText = nil
        Task {
            defer { isSaving = false }
            do {
                if let editing {
                    try await listService.updateList(
                        id: editing.id,
                        title: title,
                        description: description,
                        isPublic: isPublic
                    )
                } else {
                    _ = try await listService.createList(
                        title: title,
                        description: description,
                        isPublic: isPublic
                    )
                }
                dismiss()
            } catch {
                errorText = error.localizedDescription
            }
        }
    }
}
