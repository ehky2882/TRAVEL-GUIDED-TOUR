import SwiftUI

/// A single TourList: its tours, where they are, and what the owner said about
/// them. Tours are resolved from `DataService` by id — a TourList stores only
/// references, never duplicated content (design: `docs/lists-design.md`).
///
/// **Built on `PlaceView`'s structure, deliberately** (owner direction,
/// 2026-08-19: *"I want playlists to look more consistent with everything
/// else. I think the formatting for the places page is a good place to
/// start"*). Before this it was a different-looking screen — a system nav bar
/// where the others hide it, a 180 pt banner where the others use a hero
/// carousel, and no tab strip at all. What the three pages now share, and must
/// keep sharing:
///
///   - `secondaryBackground` ground and a hidden system nav bar.
///   - A sticky chrome row parked by `.safeAreaInset(edge: .top)` — 44 pt
///     capsules on a material bar, content scrolling *under* it.
///   - `AtlasTabStrip` (GALLERY / MAP) above a swap zone.
///   - `TourMediaCarousel` at the hero ratio, inset by `lg`, square corners.
///   - Outer stack spacing `lg`, inner `md`, one horizontal `lg` on the body.
///   - A 4-line description with an inline Read more.
///   - Rows running edge to edge, with their padding inside.
///
/// **Three deliberate differences from a place**, each because a list is not a
/// site: the carousel swipes the **tours' own heroes** (a list has no
/// photographs of its own), there is **no GET DIRECTIONS** (a list is not
/// anywhere), and the map plots **every tour in the list** rather than one pin.
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
    /// Optional: this screen is reachable from the UIKit maker layer, which
    /// doesn't carry every service. A required lookup crashes there.
    @Environment(AuthService.self) private var authService: AuthService?
    /// Optional for the same reason — not every layer injects it.
    @Environment(MakerPresenter.self) private var makerPresenter: MakerPresenter?
    @Environment(\.dismiss) private var dismiss

    @State private var items: [TourListItem] = []
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var showingShareVisibilityPrompt = false
    @State private var isEditing = false
    @State private var showingDeleteConfirm = false
    @State private var showingEditDetails = false
    @State private var noteTarget: NoteTarget?
    @State private var topSectionTab: TopSectionTab = .gallery
    @State private var isDescriptionExpanded = false

    private enum TopSectionTab: String, CaseIterable, Identifiable {
        case gallery = "Gallery"
        case map = "Map"
        var id: String { rawValue }
    }

    /// The same empirical break point tour detail and the place page use — 4
    /// lines of 15 pt body at content width. A character count avoids a
    /// `GeometryReader` round-trip on every body eval, which would fight the
    /// truncation animation.
    private static let descriptionPreviewLineLimit = 4
    private static let descriptionOverflowThreshold = 240

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

    /// Saving is account-backed (`saved_journeys` is keyed on the user), so
    /// unlike bookmarking a tour it can't work signed out. Hide the control
    /// rather than offer one that fails — the same choice the Follow button
    /// makes on a maker page.
    private var canSave: Bool {
        !isOwner && authService?.isSignedIn == true
    }

    private var isSavedList: Bool { listService.isListSaved(listId) }

    /// Resolved (tour, note) pairs in TourList order — dropping any tour id no
    /// longer in the catalog.
    private var resolvedTours: [(item: TourListItem, tour: Tour)] {
        items.compactMap { item in
            guard let tour = dataService.tour(by: item.tourId) else { return nil }
            return (item, tour)
        }
    }

    var body: some View {
        scrollBody
            .safeAreaInset(edge: .top, spacing: 0) {
                chromeRow
                    .background(AtlasColors.secondaryBackground.opacity(0.8))
                    .background(.regularMaterial)
            }
            .background(AtlasColors.secondaryBackground)
            .toolbar(.hidden, for: .navigationBar)
            // Kept for VoiceOver: the visible title now lives in the body's
            // masthead, as it does on tour detail and the place page.
            .navigationTitle(journey?.title ?? "List")
            .inlineNavigationBarTitle()
            .confirmationDialog(
                "Delete this list? This can't be undone.",
                isPresented: $showingDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete list", role: .destructive) { deleteList() }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog(
                "Only you can see this list. Anyone you send the link to won't be able to open it.",
                isPresented: $showingShareVisibilityPrompt,
                titleVisibility: .visible
            ) {
                Button("Make visible on my profile") { makeVisibleForSharing() }
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
            // Only when the Save item can appear, and only if we don't already
            // know — Library's load fills this in for the common case.
            .task(id: canSave) {
                guard canSave, !listService.hasLoadedSaves else { return }
                await listService.loadSavedListIds()
            }
    }

    // MARK: - Chrome

    /// Back or close (leading) · the `…` menu (trailing) — the same capsules,
    /// in the same places, as tour detail and the place page.
    ///
    /// ⚠️ The leading control is a **back chevron**, not an X. Unlike a place,
    /// this screen is *pushed* onto a nav stack from Library or a profile, so
    /// there is somewhere to go back to. The shared-link path presents it in a
    /// sheet with its own Close, which is why `dismiss()` is right either way.
    private var chromeRow: some View {
        HStack(spacing: AtlasSpacing.sm) {
            Button { dismiss() } label: {
                chromeCapsule("chevron.left")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            Spacer()

            // Saving lives in the menu as well, but a bookmark you can see is
            // worth a capsule of its own — the place page makes the same call.
            if canSave {
                Button { toggleSaved() } label: {
                    chromeCapsule(isSavedList ? "bookmark.fill" : "bookmark")
                }
                .buttonStyle(.plain)
                .disabled(isSaving)
                .accessibilityLabel(isSavedList ? "Remove from your saved lists" : "Save this list")
            }

            overflowMenu
        }
        .padding(.horizontal, AtlasSpacing.lg)
        .padding(.vertical, AtlasSpacing.sm)
    }

    /// Identical to tour detail's and the place page's, down to the fill
    /// opacity. Gold is reserved for action controls, so chrome stays neutral.
    private func chromeCapsule(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 20, weight: .regular))
            .foregroundStyle(AtlasColors.primaryText)
            .frame(width: 44, height: 44)
            .background(Capsule().fill(AtlasColors.tertiaryText.opacity(0.18)))
            .contentShape(Capsule())
    }

    // MARK: - Body

    private var scrollBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AtlasSpacing.lg) {
                topSection
                    .padding(.top, AtlasSpacing.md)

                VStack(alignment: .leading, spacing: AtlasSpacing.md) {
                    masthead
                    if let description = journey?.description, !description.isEmpty {
                        descriptionSection(description)
                    }
                }
                .padding(.horizontal, AtlasSpacing.lg)

                // Rows run edge to edge — their padding is inside, so the
                // dividers reach the screen edges the way a list's do. That is
                // why this sits outside the padded stack above.
                tourList

                // The bottom module floats over every screen from a higher
                // window, so the last row has to reserve its height or it can
                // never be tapped.
                Color.clear.frame(height: AtlasBottomModule.height())
            }
        }
    }

    // MARK: - Top section (Gallery / Map)

    private var topSection: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            AtlasTabStrip(tabs: TopSectionTab.allCases, selection: $topSectionTab)
            Group {
                switch topSectionTab {
                case .gallery: imageSection
                case .map:     mapContent
                }
            }
        }
    }

    /// The **same** carousel the tour page, the player and the place page use.
    ///
    /// A list has no photographs of its own, so it swipes **the heroes of the
    /// tours in it, in list order** (owner direction 2026-08-19). An explicit
    /// `coverImageURL` still leads when the owner has set one.
    private var imageSection: some View {
        TourMediaCarousel(
            heroImageURL: carouselHero,
            additionalImageURLs: carouselRest,
            videoURLs: nil,
            height: nil,   // takes AtlasSpacing.heroAspectRatio
            category: resolvedTours.first?.tour.primaryCategory
        )
        .padding(.horizontal, AtlasSpacing.lg)
    }

    /// Every tour hero, in list order, with an explicit cover in front of them.
    private var carouselImages: [String] {
        var urls: [String] = []
        if let cover = journey?.coverImageURL, !cover.isEmpty { urls.append(cover) }
        urls.append(contentsOf: resolvedTours.map(\.tour.heroImageURL))
        // A tour whose hero *is* the cover would otherwise show twice in a row.
        var seen = Set<String>()
        return urls.filter { seen.insert($0).inserted }
    }

    private var carouselHero: String { carouselImages.first ?? "" }
    private var carouselRest: [String]? {
        let rest = Array(carouselImages.dropFirst())
        return rest.isEmpty ? nil : rest
    }

    /// Every tour in the list, clustered, with the stacked cards a doubled-up
    /// pin needs. The same component the maker page uses — see `TourSetMap`
    /// for why that behaviour can't be skipped.
    private var mapContent: some View {
        TourSetMap(
            tours: resolvedTours.map(\.tour),
            places: dataService.places,
            // A list holds other people's tours, so each card names its own
            // maker rather than assuming one.
            makerForTour: { dataService.maker(for: $0) },
            countLabel: { count in
                switch count {
                case 0: return "Nothing on the map yet"
                case 1: return "1 tour on the map"
                default: return "\(count) tours on the map"
                }
            },
            onOpenTour: { tourId in
                guard let tour = dataService.tour(by: tourId) else { return }
                openTour(tour)
            },
            onOpenPlace: { place in
                // No place presenter is reliably injected on every path that
                // reaches a list, so open the place's tours where we are.
                guard let first = dataService.rankedTours(at: place).first else { return }
                openTour(first)
            }
        )
        .padding(.horizontal, AtlasSpacing.lg)
    }

    // MARK: - Masthead + description

    private var masthead: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text((journey?.title ?? "List").uppercased())
                .font(AtlasTypography.body)
                .foregroundStyle(AtlasColors.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            let metaLine = [ownerName, onlyMeText].compactMap { $0 }.joined(separator: " · ")
            if !metaLine.isEmpty {
                Text(metaLine)
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
                    .padding(.top, 6)
            }
        }
    }

    /// Whose list this is — only on someone else's, since on your own it would
    /// just be your own name.
    private var ownerName: String? {
        guard !isOwner, let journey else { return nil }
        return TourListOwner.name(of: journey, in: dataService)
    }

    /// Only flag the exception. Visible is the normal state, so labelling it
    /// says nothing; "Only me" is the fact worth knowing — and on someone
    /// else's list it is redundant either way, since you could not be here.
    private var onlyMeText: String? {
        (isOwner && journey?.isPublic == false) ? "Only me" : nil
    }

    /// Truncated to 4 lines with an inline toggle, like the other two pages.
    /// Untruncated, a long description pushes the tours off the screen — on
    /// the one page whose whole purpose is that list.
    private func descriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
            Text(description)
                .font(AtlasTypography.body)
                .foregroundStyle(AtlasColors.primaryText)
                .lineLimit(isDescriptionExpanded ? nil : Self.descriptionPreviewLineLimit)
                .fixedSize(horizontal: false, vertical: true)
                .animation(.easeInOut(duration: 0.2), value: isDescriptionExpanded)

            if description.count > Self.descriptionOverflowThreshold {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { isDescriptionExpanded.toggle() }
                } label: {
                    Text(isDescriptionExpanded ? "Show less" : "Read more")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isDescriptionExpanded ? "Show less description" : "Read more description")
            }
        }
    }

    // MARK: - The tours

    /// The list itself, shaped like the place page's tour list: a brass count
    /// header over rows that run edge to edge with their padding inside.
    ///
    /// The count is **just the number** — owner direction 2026-08-19, dropping
    /// the place page's "AVAILABLE", which reads oddly for a list you made.
    /// The trailing slot the place page uses to state its sort rule is
    /// deliberately empty here: a list's order is whatever its owner arranged,
    /// so there is no rule to state.
    private var tourList: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            if !resolvedTours.isEmpty {
                Text(resolvedTours.count == 1 ? "1 TOUR" : "\(resolvedTours.count) TOURS")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.accent)
                    .padding(.horizontal, AtlasSpacing.lg)
            }

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AtlasSpacing.xl)
            } else if resolvedTours.isEmpty {
                emptyState
            } else {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(resolvedTours, id: \.item.id) { pair in
                        tourRow(tour: pair.tour, note: pair.item.note)

                        if pair.item.id != resolvedTours.last?.item.id {
                            Divider().padding(.leading, AtlasSpacing.lg)
                        }
                    }
                }
            }
        }
    }

    /// One tour in the list.
    ///
    /// **The place page's row, plus the two things only a list has**: the
    /// curator's note, and — in edit mode — reorder and remove. Everything
    /// else is deliberately identical (56 pt hero, WALK pill, price badge,
    /// maker · duration, trailing chevron) so a user scanning tours never has
    /// to learn a second row format.
    ///
    /// ⚠️ **No position number.** A list is ordered, but the sequence of rows
    /// already shows that, and a leading number column would push the hero in
    /// and break the match with every other tour row in the app. Order is made
    /// *actionable* by the arrows in edit mode, which is where it matters.
    @ViewBuilder
    private func tourRow(tour: Tour, note: String?) -> some View {
        HStack(spacing: AtlasSpacing.sm) {
            HeroImageView(
                imageName: tour.heroImageURL,
                height: 56,
                cornerRadius: AtlasSpacing.xs,
                category: tour.primaryCategory
            )
            .frame(width: 56)

            VStack(alignment: .leading, spacing: 3) {
                // Absence is the default state: only the exception is marked,
                // so a free single-stop tour carries no badge at all.
                HStack(spacing: AtlasSpacing.xs) {
                    if tour.kind == .multiStop {
                        Text("WALK")
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .foregroundStyle(AtlasColors.background)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(AtlasColors.accent, in: Capsule())
                    }
                    TourPriceBadge(tour: tour)
                }

                Text(tour.title.uppercased())
                    .font(AtlasTypography.body)
                    .foregroundStyle(AtlasColors.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(rowSubtitle(for: tour))
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
                    .lineLimit(1)

                // The curator's voice — the one thing a list row carries that
                // no other tour row in the app does.
                if let note, !note.isEmpty {
                    Text(note)
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.tertiaryText)
                        .lineLimit(2)
                        .padding(.top, 1)
                }

                if isEditing {
                    Button {
                        noteTarget = NoteTarget(tourId: tour.id, tourTitle: tour.title, note: note ?? "")
                    } label: {
                        Label(note?.isEmpty ?? true ? "Add note" : "Edit note",
                              systemImage: "text.bubble")
                            .font(AtlasTypography.caption)
                            .foregroundStyle(AtlasColors.accent)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 2)
                }
            }

            Spacer(minLength: 0)

            if isEditing {
                editingControls(for: tour.id, tourTitle: tour.title)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(AtlasColors.tertiaryText)
            }
        }
        .padding(.vertical, AtlasSpacing.sm)
        .padding(.horizontal, AtlasSpacing.lg)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isEditing else { return }
            openTour(tour)
        }
    }

    /// `maker · N stops · duration` — the place page's subtitle exactly. A
    /// list holds other people's tours, so naming the maker matters more here
    /// than anywhere: two rows may well be by two different creators.
    private func rowSubtitle(for tour: Tour) -> String {
        var parts: [String] = []
        if let maker = dataService.maker(for: tour) { parts.append(maker.displayName) }
        if tour.kind == .multiStop { parts.append("\(tour.stops.count) stops") }
        parts.append(AtlasFormatters.duration(seconds: tour.totalDurationSeconds))
        return parts.joined(separator: " · ")
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

    /// Top-trailing `…` menu. Same idiom as a tour's, and the same first
    /// item — Share — because a list is a thing you send someone, which is
    /// most of the point of making one.
    ///
    /// What's below Share depends on whose list it is. Yours gets the editing
    /// items; someone else's gets Save and a way to their profile. Neither
    /// menu shows an item that would fail: RLS is the real gate, but offering
    /// Delete on a list you don't own would be a lie.
    @ViewBuilder
    private var overflowMenu: some View {
        Menu {
            shareItem

            if isOwner {
                Section {
                    Button("Edit details", systemImage: "square.and.pencil") {
                        showingEditDetails = true
                    }
                    Button(isEditing ? "Done" : "Edit tours", systemImage: "arrow.up.arrow.down") {
                        isEditing.toggle()
                    }
                }
                Section {
                    Button("Delete list", systemImage: "trash", role: .destructive) {
                        showingDeleteConfirm = true
                    }
                }
            } else {
                Section {
                    if canSave {
                        Button {
                            toggleSaved()
                        } label: {
                            Label(
                                isSavedList ? "Saved to your lists" : "Save to your lists",
                                systemImage: isSavedList ? "bookmark.fill" : "bookmark"
                            )
                        }
                        .disabled(isSaving)
                    }

                    if let ownerMaker {
                        Button {
                            makerPresenter?.present(ownerMaker)
                        } label: {
                            Label("Go to creator", systemImage: "person.crop.circle")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .accessibilityLabel("List options")
        }
    }

    /// Share the list's https link — nothing else, so Messages renders one
    /// rich link bubble rather than a link plus a stray text bubble. Same
    /// choice `TourDetailView` makes.
    ///
    /// **A list only you can see has nothing to share**, so on one of those
    /// the item becomes a prompt instead: a link to an Only-me list opens to
    /// an empty screen for whoever receives it, and shipping a share button
    /// that quietly produces a dead link is worse than asking first.
    @ViewBuilder
    private var shareItem: some View {
        if let journey {
            if journey.isPublic {
                ShareLink(item: AtlasShareLink.listURL(for: journey), subject: Text(journey.title)) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            } else if isOwner {
                Button {
                    showingShareVisibilityPrompt = true
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
        }
    }

    /// The list's owner as a `Maker`, matched through `Maker.userId` against
    /// the catalog already in memory. Nil for a creator with nothing published
    /// yet — then there is simply no profile to send anyone to.
    private var ownerMaker: Maker? {
        guard let ownerUserId = journey?.ownerUserId else { return nil }
        return dataService.makers.first { $0.userId == ownerUserId }
    }

    /// Flip an Only-me list to visible so it can actually be shared. Split out
    /// because it changes who can see the list — it is a real decision, not a
    /// step in a share flow, so it is confirmed and then the user shares.
    private func makeVisibleForSharing() {
        guard let journey, !journey.isPublic else { return }
        Task {
            try? await listService.updateList(
                id: journey.id,
                title: journey.title,
                description: journey.description,
                isPublic: true
            )
        }
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

    /// Keep or un-keep someone else's list.
    ///
    /// Un-saving is deliberate and reversible — it removes a reference, never
    /// the list — so unlike the tour bookmark it toggles both ways with no
    /// confirmation. The tour bookmark can't, because there un-saving is the
    /// only way to lose a save.
    private func toggleSaved() {
        guard let journey, !isSaving else { return }
        isSaving = true
        Task {
            if isSavedList {
                await listService.unsaveList(listId)
            } else {
                await listService.saveList(journey)
            }
            isSaving = false
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
