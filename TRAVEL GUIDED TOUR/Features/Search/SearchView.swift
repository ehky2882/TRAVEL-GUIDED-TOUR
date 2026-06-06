import SwiftUI
import MapKit

/// Minimal V1 search — spec § Key screens #2 / roadmap M-search.
///
/// Live filter as the user types. Matches case-insensitive substring
/// against tour title, maker display name, and category display name.
/// No filters, facets, fuzzy matching, sort options — explicitly
/// deferred per spec.
///
/// When the user taps a result, we record the current query as a
/// "successful" RecentSearch and push `TourDetailView` onto the host
/// tab's navigation stack (the same stack `SearchView` itself was
/// pushed onto by `SearchBar`).
struct SearchView: View {
    @Environment(DataService.self) private var dataService
    @Environment(RecentSearchStore.self) private var recentSearchStore
    @Environment(AtlasNavigationState.self) private var navState
    @Environment(TourPresenter.self) private var tourPresenter
    // Shared with the Home map so tapping a place result can fly the
    // camera there. Injected at the `ContentView` ZStack level, so it
    // reaches this pushed screen too. `dismiss` pops back to Home.
    @Environment(HomeSharedState.self) private var sharedState
    @Environment(\.dismiss) private var dismiss

    @State private var query: String = ""
    @State private var placeSearch = PlaceSearchService()
    @FocusState private var queryFieldFocused: Bool

    var body: some View {
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
        // Reserve room at the bottom for the mini-player + tab bar
        // stack so the last result row is reachable above the
        // module rather than hidden behind it. Wasn't needed under
        // the old `.sheet` presentation (the sheet covered the
        // module entirely), but matters now that search is pushed
        // into the host nav stack with the module still visible.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: AtlasBottomModule.height())
        }
        // Mark this surface as a pushed detail screen so the bottom
        // module switches to full-edge while search is on top.
        .onAppear {
            queryFieldFocused = true
            navState.push()
        }
        .onDisappear {
            navState.pop()
            placeSearch.clear()
        }
        // Drive the (debounced) geocoder off the live query. Tour /
        // maker filtering stays synchronous; only places hit Apple's
        // service, so they're fetched here rather than recomputed in a
        // view-derived property.
        .onChange(of: query) { _, newValue in
            placeSearch.search(newValue)
        }
    }

    // MARK: - Subviews

    private var searchField: some View {
        HStack(spacing: AtlasSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.secondaryText)

            TextField("Search tours, makers, categories", text: $query)
                .font(AtlasTypography.caption)
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
                        .font(AtlasTypography.caption)
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
        } else if filteredTours.isEmpty && filteredMakers.isEmpty
                    && placeSearch.results.isEmpty && !placeSearch.isSearching {
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
                        .font(AtlasTypography.caption)
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
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                    Text(recent.query)
                        .font(AtlasTypography.caption)
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
        // Show section headers whenever there's more than tours to
        // label. Tours-only keeps its clean headerless list (existing
        // behavior); any Places or Makers section turns headers on for
        // every group so the boundaries read clearly.
        let showHeaders = !placeSearch.results.isEmpty || !filteredMakers.isEmpty
        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                // Places section — geographic results from Apple's
                // geocoder. Tapping one closes Search and flies the
                // Home map there (owner direction 2026-06-06). Sits
                // above Makers + Tours so "take me somewhere on the
                // map" reads as distinct from "open this tour / maker".
                if !placeSearch.results.isEmpty {
                    if showHeaders { sectionHeader("Places") }
                    ForEach(placeSearch.results) { place in
                        Button {
                            goToPlace(place)
                        } label: {
                            placeRow(place)
                        }
                        .buttonStyle(.plain)

                        if place.id != placeSearch.results.last?.id {
                            Divider().padding(.leading, AtlasSpacing.lg)
                        }
                    }
                }

                // Makers section — maker entries that deep-link to the
                // maker page (owner direction 2026-06-06). Pushed onto
                // the host nav stack via NavigationLink, the same way
                // "Go to creator" pushes MakerView from TourDetailView.
                if !filteredMakers.isEmpty {
                    if showHeaders { sectionHeader("Makers") }
                    ForEach(filteredMakers) { maker in
                        NavigationLink {
                            MakerView(maker: maker)
                        } label: {
                            makerRow(maker)
                        }
                        .buttonStyle(.plain)

                        if maker.id != filteredMakers.last?.id {
                            Divider().padding(.leading, AtlasSpacing.lg)
                        }
                    }
                }

                if !filteredTours.isEmpty {
                    if showHeaders { sectionHeader("Tours") }
                    ForEach(filteredTours) { tour in
                        Button {
                            recentSearchStore.record(query: trimmedQuery)
                            tourPresenter.present(tour)
                        } label: {
                            resultRow(tour)
                        }
                        .buttonStyle(.plain)

                        if tour.id != filteredTours.last?.id {
                            Divider().padding(.leading, AtlasSpacing.lg)
                        }
                    }
                }
            }
            .padding(.vertical, AtlasSpacing.sm)
        }
    }

    /// Caption all-caps section divider for the Makers / Tours groups.
    /// Only shown when makers are present, so the common tours-only
    /// query keeps its clean headerless list.
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(AtlasTypography.caption)
            .textCase(.uppercase)
            .foregroundStyle(AtlasColors.tertiaryText)
            .padding(.horizontal, AtlasSpacing.lg)
            .padding(.top, AtlasSpacing.md)
            .padding(.bottom, AtlasSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Maker result row — parallels `resultRow` but with a circular
    /// avatar (emoji when the maker supplies one, else a person glyph)
    /// and a tour-count subtitle. Title is BODY all-caps like the tour
    /// rows; everything else is caption.
    private func makerRow(_ maker: Maker) -> some View {
        HStack(alignment: .center, spacing: AtlasSpacing.md) {
            ZStack {
                Circle().fill(AtlasColors.secondaryBackground)
                if let emoji = maker.avatarEmoji {
                    Text(emoji)
                        .font(.system(size: 28))
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(AtlasColors.secondaryText)
                }
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                Text(maker.displayName)
                    .font(AtlasTypography.body)
                    .textCase(.uppercase)
                    .foregroundStyle(AtlasColors.primaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(makerTourCountText(maker))
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.tertiaryText)
        }
        .padding(.horizontal, AtlasSpacing.lg)
        .padding(.vertical, AtlasSpacing.sm)
    }

    /// Place result row — a geographic destination (city, neighborhood,
    /// landmark) from Apple's geocoder. Mirrors the maker/tour row
    /// rhythm (56-wide leading element, BODY all-caps title, caption
    /// subtitle) but uses a map-pin glyph and an "out to the map"
    /// affordance instead of a disclosure chevron.
    private func placeRow(_ place: PlaceResult) -> some View {
        HStack(alignment: .center, spacing: AtlasSpacing.md) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 26))
                .foregroundStyle(AtlasColors.mapPin)
                .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                Text(place.name)
                    .font(AtlasTypography.body)
                    .textCase(.uppercase)
                    .foregroundStyle(AtlasColors.primaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)

                if !place.subtitle.isEmpty {
                    Text(place.subtitle)
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }

            Spacer()

            Image(systemName: "arrow.up.right")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.tertiaryText)
        }
        .padding(.horizontal, AtlasSpacing.lg)
        .padding(.vertical, AtlasSpacing.sm)
    }

    /// Hand the place's region to the Home map (via shared state) and
    /// pop back so the user sees the camera fly there. Places are
    /// deliberately NOT recorded in Recent Searches — those stay
    /// tour/catalog-focused.
    private func goToPlace(_ place: PlaceResult) {
        sharedState.pendingMapMove = PendingMapMove(region: place.region)
        dismiss()
    }

    private func resultRow(_ tour: Tour) -> some View {
        HStack(alignment: .center, spacing: AtlasSpacing.md) {
            // Square corners (cornerRadius 0) per the app-wide
            // "all images square corners" rule (owner, 2026-06-04).
            HeroImageView(
                imageName: tour.heroImageURL,
                height: 56,
                cornerRadius: 0,
                category: tour.primaryCategory
            )
            .frame(width: 56)

            VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                // Title: BODY, all-caps, single line, tail-truncated
                // (owner direction 2026-06-06). The only non-caption
                // text on this surface — mirrors the Player's "stop
                // titles → BODY all-caps" exception.
                Text(tour.title)
                    .font(AtlasTypography.body)
                    .textCase(.uppercase)
                    .foregroundStyle(AtlasColors.primaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)

                // Subtitle: maker name only (no category), single line.
                if let maker = dataService.maker(for: tour) {
                    Text(maker.displayName)
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                        .lineLimit(1)
                        .truncationMode(.tail)
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
                .font(AtlasTypography.caption)
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

    /// Makers whose display name matches the query (case-insensitive
    /// substring). Surfaced as their own result section above tours so
    /// the user can jump straight to the maker page. Small catalog
    /// (3 makers), so no cap needed.
    private var filteredMakers: [Maker] {
        let q = trimmedQuery.lowercased()
        guard !q.isEmpty else { return [] }
        return dataService.makers.filter {
            $0.displayName.lowercased().contains(q)
        }
    }

    /// "N tours" subtitle for a maker row.
    private func makerTourCountText(_ maker: Maker) -> String {
        let count = dataService.tours.filter {
            dataService.maker(for: $0)?.id == maker.id
        }.count
        return count == 1 ? "1 tour" : "\(count) tours"
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
