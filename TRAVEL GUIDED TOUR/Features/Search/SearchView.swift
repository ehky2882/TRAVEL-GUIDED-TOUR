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
    @Environment(MakerPresenter.self) private var makerPresenter
    // Shared with the Home map so tapping a place result can fly the
    // camera there. Injected at the `ContentView` ZStack level, so it
    // reaches this pushed screen too. `dismiss` pops back to Home.
    @Environment(HomeSharedState.self) private var sharedState
    @Environment(\.dismiss) private var dismiss

    @State private var query: String = ""
    @State private var placeSearch = PlaceSearchService()
    /// The place row currently resolving its coordinate after a tap —
    /// drives a small spinner on that row so the tap doesn't feel dead
    /// during the one-off geocode.
    @State private var resolvingPlaceID: PlaceSuggestion.ID?
    @FocusState private var queryFieldFocused: Bool

    /// Precomputed, lowercased search fields built once from the catalog
    /// so each keystroke does cheap substring checks instead of
    /// re-lowercasing every tour's (long) text and re-resolving its
    /// maker on the main thread every character. Re-lowercasing the whole
    /// catalog per keystroke was the typing lag once it passed ~350 tours.
    @State private var searchIndex: [SearchEntry] = []
    /// Tour → maker, resolved once (avoids per-row linear `maker(for:)`).
    @State private var makerByTourID: [Tour.ID: Maker] = [:]
    /// Maker → tour count, resolved once (avoids an O(catalog) scan per
    /// maker row).
    @State private var makerTourCounts: [Maker.ID: Int] = [:]

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
        // `secondaryBackground` (fixed RGB) rather than the
        // level-sensitive `.systemBackground`, so Search reads as the
        // same shade as the module + sibling detail pages instead of
        // falling to pure black at the main window's base level. Same
        // fix as MakerView; matches TourDetailView / ManageDownloadsView.
        .background(AtlasColors.secondaryBackground)
        // Title in the caption token (13pt SF Mono) ALL CAPS. The
        // principal toolbar item replaces the system inline title
        // visually; `.navigationTitle("Search")` is kept above so the
        // back-button label on pushed screens still reads "Search".
        // Same pattern as SettingsView / LibraryView.
        .navigationTitle("Search")
        .inlineNavigationBarTitle()
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("SEARCH")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.primaryText)
            }
        }
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
            buildIndexIfNeeded()
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
                    && placeSearch.suggestions.isEmpty && !placeSearch.isSearching {
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
        let showHeaders = !placeSearch.suggestions.isEmpty || !filteredMakers.isEmpty
        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                // Places section — autocomplete suggestions from Apple's
                // geocoder. Tapping one resolves its coordinate, closes
                // Search, and flies the Home map there (owner direction
                // 2026-06-06). Sits above Makers + Tours so "take me
                // somewhere on the map" reads as distinct from "open
                // this tour / maker".
                if !placeSearch.suggestions.isEmpty {
                    if showHeaders { sectionHeader("Places") }
                    ForEach(placeSearch.suggestions) { place in
                        Button {
                            goToPlace(place)
                        } label: {
                            placeRow(place)
                        }
                        .buttonStyle(.plain)

                        if place.id != placeSearch.suggestions.last?.id {
                            Divider().padding(.leading, AtlasSpacing.lg)
                        }
                    }
                }

                // Makers section — maker entries open the creator page as
                // its own top-level screen via `MakerPresenter` (the maker
                // twin of tapping a tour result → tourPresenter), so a
                // creator is a first-class destination, not a child push.
                if !filteredMakers.isEmpty {
                    if showHeaders { sectionHeader("Makers") }
                    ForEach(filteredMakers) { maker in
                        Button {
                            makerPresenter.present(maker)
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
    private func placeRow(_ place: PlaceSuggestion) -> some View {
        HStack(alignment: .center, spacing: AtlasSpacing.md) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 26))
                .foregroundStyle(AtlasColors.mapPin)
                .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                Text(place.title)
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

            if resolvingPlaceID == place.id {
                ProgressView()
                    .controlSize(.small)
            } else {
                Image(systemName: "arrow.up.right")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.tertiaryText)
            }
        }
        .padding(.horizontal, AtlasSpacing.lg)
        .padding(.vertical, AtlasSpacing.sm)
    }

    /// Resolve the tapped suggestion to a coordinate (one MKLocalSearch),
    /// hand the region to the Home map (via shared state), and pop back
    /// so the user sees the camera fly there. The resolve is the only
    /// network round-trip in the place flow — type-ahead above is served
    /// by the completer. Places are deliberately NOT recorded in Recent
    /// Searches — those stay tour/catalog-focused.
    private func goToPlace(_ place: PlaceSuggestion) {
        // Ignore extra taps while a resolve is already in flight (also
        // avoids firing back-to-back MKLocalSearch calls).
        guard resolvingPlaceID == nil else { return }
        resolvingPlaceID = place.id
        Task {
            let region = await placeSearch.resolve(place)
            resolvingPlaceID = nil
            guard let region else { return }
            sharedState.pendingMapMove = PendingMapMove(region: region)
            dismiss()
        }
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
                if let maker = makerByTourID[tour.id] {
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

    /// "N tours" subtitle for a maker row (count precomputed once).
    private func makerTourCountText(_ maker: Maker) -> String {
        let count = makerTourCounts[maker.id] ?? 0
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

        // Iterate the precomputed index — every field is already
        // lowercased, so each keystroke is just substring checks (no
        // per-tour `.lowercased()` of long descriptions, no maker scan).
        for entry in searchIndex {
            if entry.title.contains(q) {
                titleHits.append(entry.tour)
                continue
            }
            if entry.category.contains(q) {
                categoryHits.append(entry.tour)
                continue
            }
            if !entry.makerName.isEmpty, entry.makerName.contains(q) {
                makerHits.append(entry.tour)
                continue
            }
            if entry.tags.contains(where: { $0.contains(q) }) {
                tagHits.append(entry.tour)
                continue
            }
            if entry.shortDescription.contains(q)
                || entry.longDescription.contains(q) {
                descriptionHits.append(entry.tour)
            }
        }

        return titleHits + categoryHits + makerHits + tagHits + descriptionHits
    }

    // MARK: - Search index

    /// One tour's searchable fields, lowercased once up front.
    private struct SearchEntry {
        let tour: Tour
        let title: String
        let category: String
        let makerName: String   // "" when the tour has no maker
        let tags: [String]
        let shortDescription: String
        let longDescription: String
    }

    /// Build the lowercased search index + the tour→maker and
    /// maker→count maps once. Guards on catalog size so a background
    /// remote-catalog refresh (which changes `dataService.tours.count`)
    /// rebuilds the index next time Search appears.
    private func buildIndexIfNeeded() {
        guard searchIndex.count != dataService.tours.count else { return }

        var byTour: [Tour.ID: Maker] = [:]
        var counts: [Maker.ID: Int] = [:]
        searchIndex = dataService.tours.map { tour in
            let maker = dataService.maker(for: tour)
            if let maker {
                byTour[tour.id] = maker
                counts[maker.id, default: 0] += 1
            }
            return SearchEntry(
                tour: tour,
                title: tour.title.lowercased(),
                category: tour.primaryCategory.displayName.lowercased(),
                makerName: maker?.displayName.lowercased() ?? "",
                tags: tour.tags.map { $0.lowercased() },
                shortDescription: tour.shortDescription.lowercased(),
                longDescription: tour.longDescription.lowercased()
            )
        }
        makerByTourID = byTour
        makerTourCounts = counts
    }
}
