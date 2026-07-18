import SwiftUI

/// A single Journey: its title/description + the ordered list of tours in it.
/// Tapping a tour opens it (via the shared `TourPresenter` when no detail
/// layer is up, else a push within the current stack). Editing (remove tours,
/// delete the Journey) lives behind an Edit toggle.
///
/// Tours are resolved from `DataService` by id — a Journey stores only tour
/// references, never duplicated content (design: `docs/journeys-design.md`).
struct JourneyDetailView: View {
    let journeyId: UUID

    @Environment(JourneyService.self) private var journeyService
    @Environment(DataService.self) private var dataService
    @Environment(TourPresenter.self) private var tourPresenter
    @Environment(\.dismiss) private var dismiss

    @State private var items: [JourneyItem] = []
    @State private var isLoading = true
    @State private var isEditing = false
    @State private var showingDeleteConfirm = false

    /// The journey's metadata from the in-memory list (title / public flag).
    private var journey: Journey? {
        journeyService.myJourneys.first(where: { $0.id == journeyId })
    }

    /// Resolved (tour, note) pairs in Journey order — dropping any tour id no
    /// longer in the catalog.
    private var resolvedTours: [(item: JourneyItem, tour: Tour)] {
        items.compactMap { item in
            guard let tour = dataService.tour(by: item.tourId) else { return nil }
            return (item, tour)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AtlasSpacing.md) {
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
        .navigationTitle(journey?.title ?? "Journey")
        .inlineNavigationBarTitle()
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: AtlasBottomModule.height())
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(isEditing ? "Done" : "Edit tours", systemImage: "pencil") {
                        isEditing.toggle()
                    }
                    Section {
                        Button("Delete Journey", systemImage: "trash", role: .destructive) {
                            showingDeleteConfirm = true
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .accessibilityLabel("Journey options")
                }
            }
        }
        .confirmationDialog(
            "Delete this Journey? This can't be undone.",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete Journey", role: .destructive) { deleteJourney() }
            Button("Cancel", role: .cancel) {}
        }
        .task(id: journeyId) {
            items = await journeyService.items(of: journeyId)
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
                if let journey {
                    Text("·")
                    Text(journey.isPublic ? "Public" : "Private")
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
            }

            Spacer()

            if isEditing {
                Button {
                    remove(tour.id)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove \(tour.title) from Journey")
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

    private var emptyState: some View {
        VStack(spacing: AtlasSpacing.sm) {
            Text("No tours yet")
                .font(AtlasTypography.body)
                .foregroundStyle(AtlasColors.primaryText)
            Text("Open any tour and use “Add to a Journey” to build this collection.")
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
            try? await journeyService.removeTour(tourId, from: journeyId)
            items = await journeyService.items(of: journeyId)
        }
    }

    private func deleteJourney() {
        Task {
            try? await journeyService.deleteJourney(journeyId)
            dismiss()
        }
    }
}
