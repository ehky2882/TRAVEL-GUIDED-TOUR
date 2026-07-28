import SwiftUI

/// A single TourList: its title/description + the ordered list of tours in it.
/// Tapping a tour opens it (via the shared `TourPresenter` when no detail
/// layer is up, else a push within the current stack). Editing (remove tours,
/// delete the TourList) lives behind an Edit toggle.
///
/// Tours are resolved from `DataService` by id — a TourList stores only tour
/// references, never duplicated content (design: `docs/lists-design.md`).
struct TourListDetailView: View {
    let listId: UUID
    /// Metadata for a list the viewer does **not** own, passed in by the
    /// screen that already fetched it (a creator's maker page).
    ///
    /// Without this the title would be blank: metadata used to be looked up in
    /// `listService.myLists`, which by definition never contains someone
    /// else's list. Passing it beats re-fetching — the caller has it already.
    var preloaded: TourList? = nil

    @Environment(TourListService.self) private var listService
    @Environment(DataService.self) private var dataService
    @Environment(TourPresenter.self) private var tourPresenter
    @Environment(\.dismiss) private var dismiss

    @State private var items: [TourListItem] = []
    @State private var isLoading = true
    @State private var isEditing = false
    @State private var showingDeleteConfirm = false
    @State private var showingEditDetails = false
    @State private var noteTarget: NoteTarget?

    /// The list's metadata — yours from the service, someone else's from
    /// whoever pushed this screen.
    private var journey: TourList? {
        listService.myLists.first(where: { $0.id == listId }) ?? preloaded
    }

    /// Whether the viewer owns this list. Drives every editing affordance:
    /// the server would reject the writes anyway (RLS is the real gate), but
    /// offering a Delete button that silently fails is worse than not offering
    /// it.
    private var isOwner: Bool {
        listService.myLists.contains { $0.id == listId }
    }

    /// Resolved (tour, note) pairs in TourList order — dropping any tour id no
    /// longer in the catalog.
    private var resolvedTours: [(item: TourListItem, tour: Tour)] {
        items.compactMap { item in
            guard let tour = dataService.tour(by: item.tourId) else { return nil }
            return (item, tour)
        }
    }

    /// Cover image source: an explicit `coverImageURL` if set, else the first
    /// resolved tour's hero. `nil` (no banner) for an empty TourList with no
    /// cover set.
    private var coverImageName: String? {
        if let url = journey?.coverImageURL, !url.isEmpty { return url }
        return resolvedTours.first?.tour.heroImageURL
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AtlasSpacing.md) {
                if let coverImageName {
                    HeroImageView(
                        imageName: coverImageName,
                        height: 180,
                        cornerRadius: 0,
                        category: resolvedTours.first?.tour.primaryCategory
                    )
                }

                header

                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, AtlasSpacing.xl)
                } else if resolvedTours.isEmpty {
                    emptyState
                } else {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(resolvedTours.enumerated()), id: \.element.item.id) { index, pair in
                            tourRow(index: index, tour: pair.tour, note: pair.item.note)
                            if pair.item.id != resolvedTours.last?.item.id {
                                Divider()
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, AtlasSpacing.lg)
            .padding(.top, AtlasSpacing.md)
        }
        .background(AtlasColors.secondaryBackground)
        .navigationTitle(journey?.title ?? "List")
        .inlineNavigationBarTitle()
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: AtlasBottomModule.height())
        }
        .toolbar {
            // Someone else's list is read-only — no menu at all, rather than a
            // menu whose every item fails.
            if isOwner {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Edit details", systemImage: "square.and.pencil") {
                            showingEditDetails = true
                        }
                        Button(isEditing ? "Done" : "Edit tours", systemImage: "arrow.up.arrow.down") {
                            isEditing.toggle()
                        }
                        Section {
                            Button("Delete list", systemImage: "trash", role: .destructive) {
                                showingDeleteConfirm = true
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .accessibilityLabel("List options")
                    }
                }
            }
        }
        .confirmationDialog(
            "Delete this list? This can't be undone.",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete list", role: .destructive) { deleteList() }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showingEditDetails) {
            if let journey {
                TourListEditorSheet(editing: journey)
            }
        }
        .sheet(item: $noteTarget) { target in
            TourListNoteEditorSheet(
                tourTitle: target.tourTitle,
                initialNote: target.note
            ) { newNote in
                saveNote(newNote, for: target.tourId)
            }
        }
        .task(id: listId) {
            items = await listService.items(of: listId)
            isLoading = false
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
            if let journey, let description = journey.description, !description.isEmpty {
                Text(description)
                    .font(AtlasTypography.body)
                    .foregroundStyle(AtlasColors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: AtlasSpacing.xs) {
                Text(resolvedTours.count == 1 ? "1 tour" : "\(resolvedTours.count) tours")
                // Only flag the exception. Visible is the normal state now, so
                // labelling it says nothing; "Only me" is the fact worth
                // knowing. And on someone else's list it's redundant either
                // way — you can only be here because you can see it.
                if isOwner, journey?.isPublic == false {
                    Text("·")
                    Text("Only me")
                }
            }
            .font(AtlasTypography.caption)
            .foregroundStyle(AtlasColors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func tourRow(index: Int, tour: Tour, note: String?) -> some View {
        HStack(alignment: .center, spacing: AtlasSpacing.md) {
            Text("\(index + 1)")
                .font(AtlasTypography.body)
                .foregroundStyle(AtlasColors.secondaryText)
                .frame(width: 20, alignment: .leading)

            HeroImageView(
                imageName: tour.heroImageURL,
                height: 56,
                cornerRadius: 0,
                category: tour.primaryCategory
            )
            .frame(width: 56)

            VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                Text(tour.title)
                    .font(AtlasTypography.body)
                    .textCase(.uppercase)
                    .foregroundStyle(AtlasColors.primaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(AtlasFormatters.duration(seconds: tour.totalDurationSeconds))
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)

                if let note, !note.isEmpty {
                    Text(note)
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.tertiaryText)
                        .lineLimit(2)
                }

                if isEditing {
                    Button {
                        noteTarget = NoteTarget(tourId: tour.id, tourTitle: tour.title, note: note ?? "")
                    } label: {
                        Label(note?.isEmpty ?? true ? "Add note" : "Edit note",
                              systemImage: "text.bubble")
                            .font(AtlasTypography.caption)
                            .foregroundStyle(AtlasColors.mapPin)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 2)
                }
            }

            Spacer()

            if isEditing {
                editingControls(for: tour.id, tourTitle: tour.title)
            } else {
                Image(systemName: "chevron.right")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.tertiaryText)
            }
        }
        .padding(.vertical, AtlasSpacing.sm)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isEditing else { return }
            openTour(tour)
        }
    }

    /// Trailing per-row controls in edit mode: move up / down (reorder) + remove.
    private func editingControls(for tourId: UUID, tourTitle: String) -> some View {
        let idx = items.firstIndex(where: { $0.tourId == tourId })
        return HStack(spacing: AtlasSpacing.sm) {
            VStack(spacing: 2) {
                Button { move(tourId, up: true) } label: {
                    Image(systemName: "chevron.up").font(.system(size: 14, weight: .semibold))
                }
                .buttonStyle(.plain)
                .disabled(idx == nil || idx == 0)
                .foregroundStyle(idx == 0 ? AtlasColors.tertiaryText : AtlasColors.secondaryText)
                .accessibilityLabel("Move \(tourTitle) up")

                Button { move(tourId, up: false) } label: {
                    Image(systemName: "chevron.down").font(.system(size: 14, weight: .semibold))
                }
                .buttonStyle(.plain)
                .disabled(idx == nil || idx == items.count - 1)
                .foregroundStyle(idx == items.count - 1 ? AtlasColors.tertiaryText : AtlasColors.secondaryText)
                .accessibilityLabel("Move \(tourTitle) down")
            }

            Button {
                remove(tourId)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(tourTitle) from list")
        }
    }

    private var emptyState: some View {
        VStack(spacing: AtlasSpacing.sm) {
            Text("No tours yet")
                .font(AtlasTypography.body)
                .foregroundStyle(AtlasColors.primaryText)
            Text("Open any tour, tap Save to…, and pick this list.")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AtlasSpacing.xl)
        .padding(.horizontal, AtlasSpacing.md)
    }

    // MARK: - Actions

    /// Open a tour. Within a pushed nav stack (this view) with no slide-up
    /// layer active, present via the shared presenter; if a layer is already
    /// up, that presenter call still swaps its content correctly.
    private func openTour(_ tour: Tour) {
        tourPresenter.present(tour)
    }

    private func remove(_ tourId: UUID) {
        Task {
            try? await listService.removeTour(tourId, from: listId)
            items = await listService.items(of: listId)
        }
    }

    /// Move a tour one slot up/down. Reorders `items` optimistically (the list
    /// follows array order) then persists the new positions.
    private func move(_ tourId: UUID, up: Bool) {
        guard let idx = items.firstIndex(where: { $0.tourId == tourId }) else { return }
        let target = up ? idx - 1 : idx + 1
        guard items.indices.contains(target) else { return }
        items.swapAt(idx, target)
        let ordered = items.map(\.tourId)
        Task { try? await listService.reorder(ordered, in: listId) }
    }

    private func saveNote(_ note: String, for tourId: UUID) {
        Task {
            try? await listService.setNote(note, for: tourId, in: listId)
            items = await listService.items(of: listId)
        }
    }

    private func deleteList() {
        Task {
            try? await listService.deleteList(listId)
            dismiss()
        }
    }
}

/// Identifies which tour's note is being edited (drives the note sheet).
private struct NoteTarget: Identifiable {
    let tourId: UUID
    let tourTitle: String
    let note: String
    var id: UUID { tourId }
}

/// Small sheet to add/edit a per-tour curator note ("do this at golden hour").
struct TourListNoteEditorSheet: View {
    let tourTitle: String
    let initialNote: String
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text: String
    private let limit = 140

    init(tourTitle: String, initialNote: String, onSave: @escaping (String) -> Void) {
        self.tourTitle = tourTitle
        self.initialNote = initialNote
        self.onSave = onSave
        _text = State(initialValue: initialNote)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("e.g. do this at golden hour", text: $text, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                        .onChange(of: text) { _, new in
                            if new.count > limit { text = String(new.prefix(limit)) }
                        }
                } header: {
                    Text("Note for \(tourTitle)")
                } footer: {
                    Text("\(limit - text.count) left")
                        .foregroundStyle(text.count >= limit ? .red : AtlasColors.tertiaryText)
                }
            }
            .navigationTitle("Note")
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(text); dismiss() }
                }
            }
        }
    }
}
