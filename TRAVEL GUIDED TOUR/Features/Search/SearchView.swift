import SwiftUI

/// Minimal V1 search — spec § Key screens #2 / roadmap M-search.
///
/// Live filter as the user types. Matches case-insensitive substring
/// against tour title, maker display name, and category display name.
/// No filters, facets, fuzzy matching, sort options — explicitly
/// deferred per spec.
///
/// When the user taps a result, we record the current query as a
/// "successful" RecentSearch and navigate to TourDetailView inside
/// the sheet's own NavigationStack.
struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataService.self) private var dataService
    @Environment(RecentSearchStore.self) private var recentSearchStore

    @State private var query: String = ""
    @State private var selectedTour: Tour?
    @FocusState private var queryFieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchField
                    .padding(.horizontal, AtlasSpacing.lg)
                    .padding(.vertical, AtlasSpacing.sm)

                Divider()

                contentArea
                    // Pin content area to fill available space, top-aligned.
                    // Without this the outer VStack collapses to fit small
                    // empty-state content and SwiftUI centers it vertically,
                    // which makes the search bar appear to jump downward.
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .background(AtlasColors.background)
            .navigationTitle("Search")
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .navigationDestination(item: $selectedTour) { tour in
                TourDetailView(tour: tour)
            }
        }
        .onAppear {
            queryFieldFocused = true
        }
    }

    // MARK: - Subviews

    private var searchField: some View {
        HStack(spacing: AtlasSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(AtlasTypography.body)
                .foregroundStyle(AtlasColors.secondaryText)

            TextField("Search tours, makers, categories", text: $query)
                .font(AtlasTypography.body)
                .foregroundStyle(AtlasColors.primaryText)
                .atlasNoAutocapitalization()
                .autocorrectionDisabled()
                .focused($queryFieldFocused)
                .submitLabel(.search)

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(AtlasTypography.body)
                        .foregroundStyle(AtlasColors.tertiaryText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, AtlasSpacing.md)
        .padding(.vertical, AtlasSpacing.sm + AtlasSpacing.xs)
        .background(AtlasColors.secondaryBackground)
        .overlay(
            Capsule()
                .stroke(AtlasColors.secondaryText.opacity(0.2), lineWidth: 1)
        )
        .clipShape(Capsule())
    }

    @ViewBuilder
    private var contentArea: some View {
        if trimmedQuery.isEmpty {
            recentSearchesSection
        } else if filteredTours.isEmpty {
            emptyResults
        } else {
            resultsList
        }
    }

    private var recentSearchesSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
                if recentSearchStore.searches.isEmpty {
                    Text("Try a title, maker, or category — like \"history\" or \"architecture\".")
                        .font(AtlasTypography.body)
                        .foregroundStyle(AtlasColors.secondaryText)
                        .padding(.top, AtlasSpacing.xl)
                        .padding(.horizontal, AtlasSpacing.lg)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                } else {
                    HStack {
                        Text("Recent searches")
                            .font(AtlasTypography.caption)
                            .foregroundStyle(AtlasColors.tertiaryText)
                        Spacer()
                        Button("Clear") {
                            recentSearchStore.clearAll()
                        }
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                    }
                    .padding(.horizontal, AtlasSpacing.lg)
                    .padding(.top, AtlasSpacing.md)

                    ForEach(recentSearchStore.recent()) { recent in
                        recentRow(recent)
                        if recent.id != recentSearchStore.searches.last?.id {
                            Divider().padding(.leading, AtlasSpacing.lg)
                        }
                    }
                }
            }
            .padding(.vertical, AtlasSpacing.sm)
        }
    }

    private func recentRow(_ recent: RecentSearch) -> some View {
        HStack(spacing: AtlasSpacing.md) {
            Button {
                query = recent.query
            } label: {
                HStack(spacing: AtlasSpacing.md) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(AtlasTypography.body)
                        .foregroundStyle(AtlasColors.secondaryText)
                    Text(recent.query)
                        .font(AtlasTypography.body)
                        .foregroundStyle(AtlasColors.primaryText)
                    Spacer()
                }
            }
            .buttonStyle(.plain)

            Button {
                recentSearchStore.remove(recent)
            } label: {
                Image(systemName: "xmark")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.tertiaryText)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(recent.query) from recent searches")
        }
        .padding(.horizontal, AtlasSpacing.lg)
        .padding(.vertical, AtlasSpacing.sm)
    }

    private var resultsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(filteredTours) { tour in
                    Button {
                        recentSearchStore.record(query: trimmedQuery)
                        selectedTour = tour
                    } label: {
                        resultRow(tour)
                    }
                    .buttonStyle(.plain)

                    if tour.id != filteredTours.last?.id {
                        Divider().padding(.leading, AtlasSpacing.lg)
                    }
                }
            }
            .padding(.vertical, AtlasSpacing.sm)
        }
    }

    private func resultRow(_ tour: Tour) -> some View {
        HStack(alignment: .top, spacing: AtlasSpacing.md) {
            HeroImageView(
                imageName: tour.heroImageURL,
                height: 56,
                cornerRadius: 8,
                category: tour.primaryCategory
            )
            .frame(width: 56)

            VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                Text(tour.title)
                    .font(AtlasTypography.body)
                    .foregroundStyle(AtlasColors.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: AtlasSpacing.xs) {
                    Text(tour.primaryCategory.displayName)
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)

                    if let maker = dataService.maker(for: tour) {
                        Text("•")
                            .font(AtlasTypography.caption)
                            .foregroundStyle(AtlasColors.tertiaryText)
                        Text(maker.displayName)
                            .font(AtlasTypography.caption)
                            .foregroundStyle(AtlasColors.secondaryText)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.tertiaryText)
        }
        .padding(.horizontal, AtlasSpacing.lg)
        .padding(.vertical, AtlasSpacing.sm)
    }

    private var emptyResults: some View {
        VStack(spacing: AtlasSpacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(AtlasColors.secondaryText.opacity(0.4))
            Text("No tours match \"\(trimmedQuery)\"")
                .font(AtlasTypography.body)
                .foregroundStyle(AtlasColors.secondaryText)
                .multilineTextAlignment(.center)
            Text("Try a different word, or check spelling.")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.tertiaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AtlasSpacing.xl)
        .padding(.horizontal, AtlasSpacing.lg)
    }

    // MARK: - Derived

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Substring (case-insensitive) match on title, category display
    /// name, maker name, tags, or descriptions (short + long). Order
    /// (small ranking heuristic so the most "obvious" match surfaces
    /// first): title → category → maker → tags → description. Each
    /// tour appears at most once, in the highest-ranked bucket it hits
    /// (audit P3-8). docs/authoring-tours.md already promises tags
    /// feed the search index; this implements that promise.
    private var filteredTours: [Tour] {
        let q = trimmedQuery.lowercased()
        guard !q.isEmpty else { return [] }

        var titleHits: [Tour] = []
        var categoryHits: [Tour] = []
        var makerHits: [Tour] = []
        var tagHits: [Tour] = []
        var descriptionHits: [Tour] = []

        for tour in dataService.tours {
            if tour.title.lowercased().contains(q) {
                titleHits.append(tour)
                continue
            }
            if tour.primaryCategory.displayName.lowercased().contains(q) {
                categoryHits.append(tour)
                continue
            }
            if let maker = dataService.maker(for: tour),
               maker.displayName.lowercased().contains(q) {
                makerHits.append(tour)
                continue
            }
            if tour.tags.contains(where: { $0.lowercased().contains(q) }) {
                tagHits.append(tour)
                continue
            }
            if tour.shortDescription.lowercased().contains(q)
                || tour.longDescription.lowercased().contains(q) {
                descriptionHits.append(tour)
            }
        }

        return titleHits + categoryHits + makerHits + tagHits + descriptionHits
    }
}
