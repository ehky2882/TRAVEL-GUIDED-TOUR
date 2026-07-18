import SwiftUI

/// The signed-in user's list of Journeys (their curated tour "playlists").
/// Pushed from the own-profile (Me tab). Each row opens `JourneyDetailView`;
/// the top button creates a new Journey.
///
/// Journeys are the "anyone can be a Dozent" curation layer (design:
/// `docs/journeys-design.md`) — a user strings whole tours into an ordered,
/// optionally-public collection.
struct JourneysListView: View {
    @Environment(JourneyService.self) private var journeyService

    @State private var showingCreate = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                newJourneyRow
                if !journeyService.myJourneys.isEmpty { Divider() }

                ForEach(journeyService.myJourneys) { journey in
                    NavigationLink {
                        JourneyDetailView(journeyId: journey.id)
                    } label: {
                        journeyRow(journey)
                    }
                    .buttonStyle(.plain)

                    if journey.id != journeyService.myJourneys.last?.id {
                        Divider()
                    }
                }

                if journeyService.myJourneys.isEmpty {
                    emptyState
                }
            }
            .padding(.horizontal, AtlasSpacing.lg)
            .padding(.top, AtlasSpacing.md)
        }
        .background(AtlasColors.secondaryBackground)
        .navigationTitle("Journeys")
        .inlineNavigationBarTitle()
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: AtlasBottomModule.height())
        }
        .sheet(isPresented: $showingCreate) {
            JourneyEditorSheet()
        }
        .task {
            // Load on appearance; refreshes when returning too.
            await journeyService.loadMyJourneys()
        }
    }

    /// "New Journey" affordance — mirrors the own-profile "Add a tour" row.
    private var newJourneyRow: some View {
        Button {
            showingCreate = true
        } label: {
            HStack(alignment: .center, spacing: AtlasSpacing.md) {
                ZStack {
                    Rectangle()
                        .fill(AtlasColors.placeholderWarm.opacity(0.35))
                    Image(systemName: "plus")
                        .font(AtlasTypography.body)
                        .foregroundStyle(AtlasColors.secondaryText)
                }
                .frame(width: 56, height: 56)

                Text("NEW JOURNEY")
                    .font(AtlasTypography.body)
                    .foregroundStyle(AtlasColors.primaryText)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.tertiaryText)
            }
            .padding(.vertical, AtlasSpacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("New Journey")
    }

    private func journeyRow(_ journey: Journey) -> some View {
        HStack(alignment: .center, spacing: AtlasSpacing.md) {
            ZStack {
                Rectangle()
                    .fill(AtlasColors.placeholderWarm.opacity(0.35))
                Image(systemName: "map")
                    .font(AtlasTypography.body)
                    .foregroundStyle(AtlasColors.secondaryText)
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                Text(journey.title)
                    .font(AtlasTypography.body)
                    .foregroundStyle(AtlasColors.primaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)

                HStack(spacing: AtlasSpacing.xs) {
                    Text(journey.itemCount == 1 ? "1 tour" : "\(journey.itemCount) tours")
                    Text("·")
                    Text(journey.isPublic ? "Public" : "Private")
                }
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.secondaryText)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.tertiaryText)
        }
        .padding(.vertical, AtlasSpacing.sm)
    }

    private var emptyState: some View {
        VStack(spacing: AtlasSpacing.sm) {
            Text("No Journeys yet")
                .font(AtlasTypography.body)
                .foregroundStyle(AtlasColors.primaryText)
            Text("Curate your favourite tours into an ordered collection — a themed walk, a neighbourhood, a day out — and share it.")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AtlasSpacing.xl)
        .padding(.horizontal, AtlasSpacing.md)
    }
}

/// Create/edit sheet for a Journey's metadata (title, description, public
/// toggle). Used for creation from the list; add-tour flows create inline.
struct JourneyEditorSheet: View {
    @Environment(JourneyService.self) private var journeyService
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var isPublic = false
    @State private var isSaving = false
    @State private var errorText: String?

    private let titleLimit = 60
    private let descriptionLimit = 200

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
                    TextField("What's this Journey about?", text: $description, axis: .vertical)
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
                         ? "Anyone with the link can view this Journey."
                         : "Only you can see this Journey.")
                }

                if let errorText {
                    Section {
                        Text(errorText).foregroundStyle(.red).font(AtlasTypography.caption)
                    }
                }
            }
            .navigationTitle("New Journey")
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { save() }
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
                _ = try await journeyService.createJourney(
                    title: title,
                    description: description,
                    isPublic: isPublic
                )
                dismiss()
            } catch {
                errorText = error.localizedDescription
            }
        }
    }
}
