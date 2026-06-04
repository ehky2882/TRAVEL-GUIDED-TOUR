import SwiftUI

/// Tour detail screen — spec § Key screens #4 / roadmap M-tour-detail.
///
/// PR 1 of the detail-sheet retool (session 12, 2026-05-29). Owner-driven
/// design pass — see `archive/HANDOFF-260529.md` for the full Q&A trail.
///
/// **Layout** (top to bottom, in scroll order):
///   - Toolbar (in nav bar): X close (leading) · bookmark (trailing) · `…`
///     overflow menu (trailing). **No title text** — the body's title
///     carries the page identity.
///   - Hero image — single image OR paging carousel (multi-image tours).
///     Inset side padding, **no corner radius** (square corners).
///   - Title
///   - Maker row (chevron pushes to MakerView)
///   - Subtitle line: `"3 min · 1 stop · 455 ft away"` (or, multi-stop:
///     `"… · 1.2 mi walk"`). Replaces the old meta row + chips.
///   - Button row: Start Tour / Save / Download. Repeated at the bottom
///     of the scroll body, redundancy intentional.
///   - Description — full text inline, scroll-edge gradient fade signals
///     "more below."
///   - Stops section — same simple numbered list as today for both
///     single- and multi-stop tours (PR 2 reshapes this into a numbered
///     timeline with thumbnails + a now-playing indicator).
///   - Button row (second copy)
///   - Bottom inset reserving room for the mini-player + tab bar that
///     float over from the secondary higher-level UIWindow.
///
/// **Overflow menu** (`…`): Download · Save · Share · Follow creator
/// (disabled, V1 has no follow graph) · Go to creator · Report a concern.
///
/// **Action wiring** (PR 1 only — Start Tour still opens PlayerView;
/// PR 2 rewires it to a non-modal playback start):
///   - Start Tour → opens PlayerView sheet (today's behaviour).
///   - Save / bookmark → `LibraryStore.toggleSaved`.
///   - Download → state-aware (idle / downloading / completed / failed),
///     gated when another tour is mid-download.
///   - Share → `ShareLink` with the tour title + maker line.
///   - Report a concern → `mailto:` to owner inbox prefilled with tour
///     title + ID.
///   - Go to creator → in-stack `NavigationLink` to MakerView, same
///     destination as tapping the inline maker row.
struct TourDetailView: View {
    let tour: Tour

    @Environment(DataService.self) private var dataService
    @Environment(LibraryStore.self) private var libraryStore
    @Environment(AudioPlayerService.self) private var audioPlayer
    @Environment(RecentlyViewedStore.self) private var recentlyViewedStore
    @Environment(TourDownloader.self) private var tourDownloader
    @Environment(AtlasNavigationState.self) private var navState
    @Environment(LocationManager.self) private var locationManager
    /// Used by the X close button in the top-leading toolbar slot —
    /// closes the entire detail layer (slides it back down), even
    /// when reached via a `NavigationLink` push (e.g. from
    /// `MakerView`). Within the layer's nav stack the default back
    /// chevron pops one level; X always exits the layer.
    @Environment(TourPresenter.self) private var tourPresenter
    @Environment(AppSharedState.self) private var appShared
    @Environment(\.openURL) private var openURL

    /// Programmatic push for the menu's "Go to creator" item. The
    /// inline maker row uses its own inline `NavigationLink`; the
    /// menu item can't host a NavigationLink directly inside a Menu's
    /// content closure (iOS would render it as a plain row that
    /// doesn't push), so we drive it through `.navigationDestination`.
    @State private var showingMaker = false

    /// Toggles between the truncated 4-line preview of `longDescription`
    /// and the full text. Apple Music / Podcasts pattern — keeps the
    /// action row close to the fold, lets readers expand inline.
    @State private var isDescriptionExpanded = false

    /// Lines shown in the truncated state. iOS convention (Apple Music
    /// album notes, Podcasts show notes); ~25 words at 15pt SF Pro.
    private static let descriptionPreviewLineLimit = 4

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AtlasSpacing.lg) {
                // Breathing room between the nav bar and the hero —
                // without this the image kisses the title strip.
                imageSection
                    .padding(.top, AtlasSpacing.md)

                VStack(alignment: .leading, spacing: AtlasSpacing.md) {
                    masthead
                    buttonRow
                        .padding(.top, AtlasSpacing.xs)
                    descriptionSection
                    stopsSection
                }
                .padding(.horizontal, AtlasSpacing.lg)

                // Bottom inset so the last line of content clears the
                // mini-player + tab bar that float over this view from
                // the secondary higher-level window.
                Color.clear.frame(height: AtlasBottomModule.height())
            }
        }
        .background(AtlasColors.secondaryBackground)
        // Title moved into the body — the nav bar carries only the
        // chrome (close + bookmark + overflow). Empty `navigationTitle`
        // keeps SwiftUI's toolbar geometry stable.
        .navigationTitle("")
        .inlineNavigationBarTitle()
        // Hide the toolbar's own background — SwiftUI's
        // `.toolbarBackground(Color…)` renders as a *translucent
        // material* tinted with the color, not as a solid fill, so
        // the nav bar reads as a slightly different shade than the
        // body. Hidden so the hosting view's UIKit-level
        // `.secondarySystemBackground` shows behind the toolbar items.
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { tourPresenter.dismiss() }) {
                    Image(systemName: "xmark")
                        .font(AtlasTypography.body.weight(.semibold))
                        .foregroundStyle(AtlasColors.primaryText)
                }
                .accessibilityLabel("Close")
            }
            ToolbarItem(placement: .atlasTrailing) {
                Button(action: toggleSaved) {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .font(AtlasTypography.body.weight(.semibold))
                        .foregroundStyle(AtlasColors.primaryText)
                }
                .accessibilityLabel(isSaved ? "Remove from saved" : "Save tour")
            }
            ToolbarItem(placement: .atlasTrailing) {
                overflowMenu
            }
        }
        .navigationDestination(isPresented: $showingMaker) {
            if let maker = dataService.maker(for: tour) {
                MakerView(maker: maker)
            }
        }
        // Mark this surface as a pushed detail screen so the bottom
        // module switches to full-edge while it's on top of the
        // stack — even when reached from the Home tab. Reverts to the
        // host tab's root geometry on pop / disappear.
        .onAppear {
            navState.push()
            recentlyViewedStore.record(tour.id)
        }
        .onDisappear {
            navState.pop()
        }
        .onChange(of: tourDownloader.states[tour.id]) { _, newState in
            // Keep LibraryStore in sync with the download lifecycle.
            // The downloader is decoupled from LibraryStore so this is
            // the single place that mirrors the two.
            switch newState {
            case .completed:
                libraryStore.markDownloaded(tour.id)
            case .idle, .failed, .none:
                if libraryStore.entry(for: tour.id)?.downloadedAt != nil {
                    libraryStore.clearDownload(tour.id)
                }
            case .downloading:
                break
            }
        }
    }

    // MARK: - Hero image

    /// Hero area: single image for tours with one photo, paging carousel
    /// for tours that supply `additionalImageURLs`.
    ///
    /// `cornerRadius` defaults to 0 on `HeroImageView`, so we pass
    /// nothing — the hero renders as a square-cornered rectangle with
    /// its side padding intact. Owner chose this in the detail-sheet
    /// retool: same shape as before, just no rounded corners.
    ///
    /// `disableLoadAnimation: true` keeps the hero from crossfading
    /// while the detail layer is sliding up (see HeroImageView's
    /// `disableLoadAnimation` doc for the full reason).
    @ViewBuilder
    private var imageSection: some View {
        let allImages = [tour.heroImageURL] + (tour.additionalImageURLs ?? [])
        if allImages.count > 1 {
            TabView {
                ForEach(allImages, id: \.self) { url in
                    HeroImageView(
                        imageName: url,
                        height: AtlasSpacing.heroHeight,
                        zoomable: true,
                        disableLoadAnimation: true
                    )
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: AtlasSpacing.heroHeight)
            .padding(.horizontal, AtlasSpacing.lg)
        } else {
            HeroImageView(
                imageName: tour.heroImageURL,
                height: AtlasSpacing.heroHeight,
                category: tour.primaryCategory,
                zoomable: true,
                disableLoadAnimation: true
            )
            .padding(.horizontal, AtlasSpacing.lg)
        }
    }

    // MARK: - Masthead

    /// Title + maker row + subtitle line. Replaces the old
    /// title+chips+maker+meta stack with a tighter editorial-style
    /// header. Category chips dropped per the design pass; duration /
    /// stops / distance folded into a single small subtitle line.
    private var masthead: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            Text(tour.title)
                .font(AtlasTypography.headline)
                .foregroundStyle(AtlasColors.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            makerRow

            Text(subtitleLine)
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.secondaryText)
        }
    }

    private var makerRow: some View {
        Group {
            if let maker = dataService.maker(for: tour) {
                NavigationLink {
                    MakerView(maker: maker)
                } label: {
                    HStack(spacing: AtlasSpacing.sm) {
                        Image(systemName: "person.crop.circle")
                            .font(AtlasTypography.body)
                            .foregroundStyle(AtlasColors.secondaryText)
                        Text("by \(maker.displayName)")
                            .font(AtlasTypography.body)
                            .foregroundStyle(AtlasColors.primaryText)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(AtlasTypography.caption)
                            .foregroundStyle(AtlasColors.tertiaryText)
                    }
                    .padding(.vertical, AtlasSpacing.xs)
                }
                .buttonStyle(.plain)
            } else {
                EmptyView()
            }
        }
    }

    /// One-line summary: `"3 min · 1 stop · 455 ft away"` for single-stop
    /// tours when the user's location is known, `"3 min · 1 stop"`
    /// otherwise. Multi-stop tours swap "away" for total walking
    /// distance: `"8 min 44 sec · 5 stops · 1.2 mi walk"`.
    private var subtitleLine: String {
        var parts: [String] = []
        parts.append(AtlasFormatters.duration(seconds: tour.totalDurationSeconds))

        let stopWord = tour.stops.count == 1 ? "stop" : "stops"
        parts.append("\(tour.stops.count) \(stopWord)")

        if tour.kind == .multiStop, let meters = tour.walkingDistanceMeters {
            parts.append("\(AtlasFormatters.distance(meters: Double(meters))) walk")
        } else if let user = locationManager.userLocation {
            parts.append(AtlasFormatters.distanceAway(meters: tour.distance(from: user)))
        }

        return parts.joined(separator: " · ")
    }

    // MARK: - Description + stops

    /// Description — truncated to a 4-line preview by default with an
    /// inline "Read more" / "Show less" toggle. Apple Music / Podcasts
    /// pattern; keeps the action row close to the fold for tours with
    /// long editorial-voice longDescription strings (the Cloisters
    /// runs ~32 lines unbounded).
    ///
    /// The toggle row only renders when the text actually overflows
    /// the limit — short descriptions skip the affordance entirely.
    /// We detect overflow by comparing the text's intrinsic height
    /// at body typography against the height of the same text capped
    /// at `descriptionPreviewLineLimit` lines.
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
            Text(tour.longDescription)
                .font(AtlasTypography.body)
                .foregroundStyle(AtlasColors.primaryText)
                .lineLimit(isDescriptionExpanded ? nil : Self.descriptionPreviewLineLimit)
                .fixedSize(horizontal: false, vertical: true)
                .animation(.easeInOut(duration: 0.2), value: isDescriptionExpanded)

            if shouldShowReadMoreToggle {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isDescriptionExpanded.toggle()
                    }
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

    /// Cheap overflow check — uses raw character count as a proxy for
    /// "does this overflow 4 lines at 15pt body on iPhone width?"
    /// 240 chars is the empirical break point (4 × ~60 chars/line at
    /// our content width); anything under that always fits, anything
    /// over reliably overflows. A character-count proxy avoids a
    /// GeometryReader / Text-measurement round-trip on every body
    /// eval, which would fight the inline truncation animation.
    private var shouldShowReadMoreToggle: Bool {
        tour.longDescription.count > 240
    }

    /// Stops list — header unified to "Stops" for both single- and
    /// multi-stop tours per the album/track-list metaphor (PR 2 will
    /// reshape this into a numbered timeline with thumbnails + a
    /// now-playing indicator next to the currently-playing row).
    private var stopsSection: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            Text("Stops")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.tertiaryText)
                .padding(.top, AtlasSpacing.md)

            ForEach(tour.stops.sorted(by: { $0.order < $1.order })) { stop in
                stopRow(stop)
                if stop.id != tour.stops.last?.id {
                    Divider()
                }
            }
        }
    }

    /// Tappable stop row — whole row acts as one play affordance
    /// (Apple Podcasts pattern). Leading column shows the stop
    /// number, or an animated waveform when this stop is currently
    /// producing audio. Trailing column shows a play / pause SF
    /// Symbol so the per-row affordance is also visible at the
    /// row's right edge — same effect on tap.
    private func stopRow(_ stop: Stop) -> some View {
        Button {
            handleStopTap(stop)
        } label: {
            HStack(alignment: .top, spacing: AtlasSpacing.md) {
                // Stop number, OR an animated waveform when this stop is
                // currently playing. The waveform sits in the same 24pt
                // slot as the number so the column alignment doesn't
                // shift when playback starts. `.symbolEffect(.variableColor.iterative)`
                // is iOS 17+ — Atlas targets 26.2+, so it's fine.
                Group {
                    if isPlayingStop(stop) {
                        Image(systemName: "waveform")
                            .font(AtlasTypography.body.weight(.semibold))
                            .foregroundStyle(AtlasColors.mapPin)
                            .symbolEffect(.variableColor.iterative, options: .repeating)
                            .accessibilityLabel("Playing")
                    } else {
                        Text("\(stop.order + 1)")
                            .font(AtlasTypography.body)
                            .foregroundStyle(AtlasColors.secondaryText)
                    }
                }
                .frame(width: 24, alignment: .leading)

                VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                    Text(stop.title)
                        .font(AtlasTypography.body)
                        .foregroundStyle(AtlasColors.primaryText)
                        .multilineTextAlignment(.leading)

                    if let caption = stop.caption {
                        Text(caption)
                            .font(AtlasTypography.caption)
                            .foregroundStyle(AtlasColors.secondaryText)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Text(AtlasFormatters.duration(seconds: stop.audioDurationSeconds))
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.tertiaryText)
                }

                Spacer()

                Image(systemName: stopRowAffordanceIcon(for: stop))
                    .font(AtlasTypography.body.weight(.semibold))
                    .foregroundStyle(AtlasColors.mapPin)
                    .frame(width: 28, height: 28)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, AtlasSpacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(stopRowAccessibilityLabel(for: stop))
        .accessibilityHint("Plays this stop")
    }

    /// Trailing-edge affordance icon — pause when this stop is the
    /// audible one and the engine is producing sound, otherwise play.
    private func stopRowAffordanceIcon(for stop: Stop) -> String {
        if isPlayingStop(stop) && audioPlayer.state == .playing {
            return "pause.fill"
        }
        return "play.fill"
    }

    private func stopRowAccessibilityLabel(for stop: Stop) -> String {
        let base = "Stop \(stop.order + 1): \(stop.title)"
        if isPlayingStop(stop) && audioPlayer.state == .playing {
            return "\(base), now playing"
        }
        return base
    }

    /// Whole-row tap handler. If this stop is the audible one, toggle
    /// pause / resume in place; otherwise start playback at this stop.
    private func handleStopTap(_ stop: Stop) {
        let isAudible = appShared.currentPlayingStopId == stop.id
            && audioPlayer.currentSourceId == tour.id.uuidString
        if isAudible {
            switch audioPlayer.state {
            case .playing, .loading:
                audioPlayer.pause()
                return
            case .paused, .ended:
                audioPlayer.play()
                return
            case .idle, .failed:
                break // fall through to a fresh play
            }
        }
        playStop(stop)
    }

    /// Plays the given stop's audio through `AudioPlayerService` —
    /// lifted from `PlayerView.playStop(at:)`. Prefers the on-disk
    /// copy when the tour is downloaded; sets the shared
    /// `currentPlayingStopId` so the waveform indicator + row
    /// highlight light up immediately.
    private func playStop(_ stop: Stop) {
        guard let remoteURL = URL(string: stop.audioURL) else { return }
        let url = tourDownloader.localURL(forStop: stop, in: tour) ?? remoteURL
        let maker = dataService.maker(for: tour)
        appShared.currentPlayingStopId = stop.id
        audioPlayer.play(
            url: url,
            title: tour.title,
            artist: maker?.displayName,
            sourceId: tour.id.uuidString
        )
    }

    // MARK: - Button row (inline)

    /// Shared height for the three buttons so they line up in size and
    /// baseline.
    private let controlHeight: CGFloat = 44

    /// Inline button row — sits above the description so users can
    /// act without scrolling. Order: Start Tour (primary, full
    /// width) · Save · Download. Tinted with the map-pin gold so the
    /// inline action surface matches the map's visual identity.
    ///
    /// When this tour is the audible source, the Start Tour button's
    /// leading glyph is wrapped in a *PROGRESS RING* identical to the
    /// MiniPlayerBar's (lineWidth 2, clockwise trim, faint full-circle
    /// track behind). Same ring math, same visual identity — the
    /// detail-sheet button and the persistent mini-player read as one
    /// surface.
    private var buttonRow: some View {
        HStack(spacing: AtlasSpacing.md) {
            Button(action: handlePrimaryAction) {
                HStack(spacing: AtlasSpacing.sm) {
                    primaryButtonLeadingGlyph
                    Text(primaryButtonTitle)
                        .font(AtlasTypography.body.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: controlHeight)
            }
            .buttonStyle(.borderedProminent)

            Button(action: toggleSaved) {
                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                    .font(AtlasTypography.body)
                    .frame(width: controlHeight, height: controlHeight)
            }
            .buttonStyle(.bordered)
            .accessibilityLabel(isSaved ? "Remove from saved" : "Save tour")

            downloadButton
        }
        .frame(maxWidth: .infinity)
        // Owner-confirmed: inline action buttons should read in the
        // same gold as map pins, giving the detail-sheet action
        // surface a visual handshake with the map. `.tint` propagates
        // to .borderedProminent (fill color) and .bordered (icon +
        // stroke).
        .tint(AtlasColors.mapPin)
    }

    // MARK: - Download button

    /// State-aware download control. Four faces:
    ///   - idle         → arrow.down icon, taps to start a download
    ///   - downloading  → circular progress around a stop icon, taps to cancel
    ///   - completed    → checkmark, taps to delete
    ///   - failed       → exclamation mark, taps to retry
    /// `tourDownloader.activeTourId` gates whether *other* tours can
    /// also start downloading — the button is disabled when another
    /// tour is already in flight.
    @ViewBuilder
    private var downloadButton: some View {
        let state = tourDownloader.states[tour.id] ?? .idle
        let isOtherActive = tourDownloader.activeTourId != nil
            && tourDownloader.activeTourId != tour.id

        Button(action: handleDownloadTap) {
            downloadButtonIcon(for: state)
                .font(AtlasTypography.body)
                .frame(width: controlHeight, height: controlHeight)
        }
        .buttonStyle(.bordered)
        .disabled(isOtherActive)
        .accessibilityLabel(
            isOtherActive
                ? "Download unavailable"
                : downloadAccessibilityLabel(for: state)
        )
        .accessibilityHint(
            isOtherActive
                ? "Wait for the current download to finish, then try again."
                : ""
        )
    }

    @ViewBuilder
    private func downloadButtonIcon(for state: TourDownloader.DownloadState) -> some View {
        switch state {
        case .idle, .failed:
            Image(systemName: state == .idle ? "arrow.down.circle" : "exclamationmark.circle")
        case .downloading(let progress):
            ZStack {
                Image(systemName: "stop.circle")
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(AtlasColors.primaryText, lineWidth: 2)
                    .rotationEffect(.degrees(-90))
                    .frame(width: 28, height: 28)
                    .animation(.linear(duration: 0.25), value: progress)
            }
        case .completed:
            // SF Symbol's multicolor variant for checkmark.circle.fill
            // is blue, not green. Hardcoding .green here as the one
            // exception to the theme-tokens rule — "success = green"
            // is a strong enough convention that the placeholder
            // theme would feel wrong without it. M-polish-theme can
            // promote this to an AtlasColors.success token later.
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
    }

    private func downloadAccessibilityLabel(for state: TourDownloader.DownloadState) -> String {
        switch state {
        case .idle: return "Download tour"
        case .downloading: return "Cancel download"
        case .completed: return "Delete downloaded tour"
        case .failed: return "Retry download"
        }
    }

    private func handleDownloadTap() {
        let state = tourDownloader.states[tour.id] ?? .idle
        switch state {
        case .idle, .failed:
            tourDownloader.download(tour: tour)
        case .downloading:
            tourDownloader.cancel(tourId: tour.id)
        case .completed:
            tourDownloader.deleteDownload(tourId: tour.id)
            libraryStore.clearDownload(tour.id)
        }
    }

    // MARK: - Overflow menu

    /// Top-trailing `…` overflow menu. Order:
    ///   1. Download (mirrors the inline download button's current state)
    ///   2. Save (mirrors the inline bookmark)
    ///   3. Share (ShareLink → standard iOS share sheet)
    ///   4. Follow creator — DISABLED in V1; the follow graph requires
    ///      accounts which aren't in scope. Shown grayed-out so the
    ///      slot is visible and the feature reads as "planned" rather
    ///      than missing.
    ///   5. Go to creator — pushes MakerView via `.navigationDestination`.
    ///   6. Report a concern — `mailto:` to owner inbox.
    @ViewBuilder
    private var overflowMenu: some View {
        Menu {
            Button(action: handleDownloadTap) {
                Label(menuDownloadLabel, systemImage: menuDownloadIcon)
            }
            .disabled(menuDownloadDisabled)

            Button(action: toggleSaved) {
                Label(
                    isSaved ? "Remove from saved" : "Save",
                    systemImage: isSaved ? "bookmark.fill" : "bookmark"
                )
            }

            ShareLink(item: shareText, subject: Text(tour.title)) {
                Label("Share", systemImage: "square.and.arrow.up")
            }

            Section {
                Button {
                    // No-op — kept as a disabled item to surface the
                    // upcoming "Follow" feature without delivering the
                    // (unbuilt) follow graph.
                } label: {
                    Label("Follow creator", systemImage: "person.badge.plus")
                }
                .disabled(true)

                Button {
                    showingMaker = true
                } label: {
                    Label("Go to creator", systemImage: "person.crop.circle")
                }
            }

            Section {
                Button(role: .destructive) {
                    if let url = reportURL {
                        openURL(url)
                    }
                } label: {
                    Label("Report a concern", systemImage: "exclamationmark.bubble")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(AtlasTypography.body.weight(.semibold))
                .foregroundStyle(AtlasColors.primaryText)
                .accessibilityLabel("More options")
        }
    }

    /// Menu-side label for the download item — mirrors the inline
    /// button's state so the menu reads as a parallel control surface.
    private var menuDownloadLabel: String {
        let state = tourDownloader.states[tour.id] ?? .idle
        switch state {
        case .idle:        return "Download"
        case .downloading: return "Cancel download"
        case .completed:   return "Remove download"
        case .failed:      return "Retry download"
        }
    }

    private var menuDownloadIcon: String {
        let state = tourDownloader.states[tour.id] ?? .idle
        switch state {
        case .idle:        return "arrow.down.circle"
        case .downloading: return "stop.circle"
        case .completed:   return "checkmark.circle.fill"
        case .failed:      return "exclamationmark.circle"
        }
    }

    private var menuDownloadDisabled: Bool {
        tourDownloader.activeTourId != nil
            && tourDownloader.activeTourId != tour.id
    }

    /// Plain-text payload for `ShareLink`. V1 has no public web
    /// presence yet so we share a tour-identifying string rather than
    /// a deep link — the design pass / launch can swap this for a
    /// universal link without changing the UI.
    private var shareText: String {
        if let maker = dataService.maker(for: tour) {
            return "\(tour.title) — by \(maker.displayName) on Atlas"
        }
        return "\(tour.title) on Atlas"
    }

    /// `mailto:` URL for the Report a concern menu item. Owner is sole
    /// recipient for V1 (no moderation backend yet). Subject + body
    /// are URL-encoded; tour ID lets the owner trace the report.
    private var reportURL: URL? {
        let to = "eyung@tishman.com"
        let subject = "Atlas — report concern: \(tour.title)"
        let body = """
            Tour: \(tour.title)
            Tour ID: \(tour.id.uuidString)

            Concern:

            """
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = to
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        return components.url
    }

    // MARK: - Actions

    /// Start Tour kicks off audio playback *non-modally* — the
    /// full `PlayerView` sheet is no longer presented from the detail
    /// sheet. The user opens the full player by tapping the
    /// mini-player at the bottom of the screen, the same way Apple
    /// Music and Spotify gate the full now-playing UI.
    ///
    /// Logic mirrors `PlayerView.startPlaybackIfNeeded`: if this
    /// tour's audio is already loaded, just resume (or no-op when
    /// already playing). Otherwise, start from the intro audio if
    /// it exists, else the first stop.
    ///
    /// **Multi-stop auto-advance.** For geofenced multi-stop tours
    /// (Atlas's common case) `ProximityMonitor` drives the next
    /// stop's playback as the user walks. For non-geofenced
    /// multi-stop tours auto-advance still requires `PlayerView` to
    /// be the visible surface (its `.onChange(of: audioPlayer.state)`
    /// observer is what calls `playStop(at: nextIndex)`); a future
    /// pass can promote that orchestrator to an env-level service so
    /// auto-advance survives without `PlayerView` on screen. Single-
    /// stop tours and geofenced multi-stop tours are unaffected.
    private func handlePrimaryAction() {
        // If this tour's audio is already loaded, toggle pause/resume
        // in place — the button now doubles as the tour-level
        // transport control on the detail sheet (owner-confirmed,
        // 2026-06-03). The mini-player is still the canonical
        // transport surface, but the detail button is no longer a
        // dead-end "Playing" label.
        if audioPlayer.currentSourceId == tour.id.uuidString
            && audioPlayer.state != .idle
            && audioPlayer.state != .failed {
            switch audioPlayer.state {
            case .playing, .loading:
                audioPlayer.pause()
            case .paused, .ended:
                audioPlayer.play()
            case .idle, .failed:
                break
            }
            return
        }

        let maker = dataService.maker(for: tour)
        let sortedStops = tour.stops.sorted(by: { $0.order < $1.order })

        // Prefer the on-disk copy when the tour is downloaded — same
        // pattern PlayerView uses. Falls back to streaming.
        if let introString = tour.introAudioURL,
           let remoteURL = URL(string: introString) {
            let url = tourDownloader.localURL(forIntroOf: tour) ?? remoteURL
            // Intro audio doesn't belong to a single stop.
            appShared.currentPlayingStopId = nil
            audioPlayer.play(
                url: url,
                title: tour.title,
                artist: maker?.displayName,
                sourceId: tour.id.uuidString
            )
        } else if let firstStop = sortedStops.first,
                  let remoteURL = URL(string: firstStop.audioURL) {
            let url = tourDownloader.localURL(forStop: firstStop, in: tour) ?? remoteURL
            // Light up the now-playing indicator on the first stop
            // row immediately — `PlayerView` would do this too if it
            // were the surface starting playback.
            appShared.currentPlayingStopId = firstStop.id
            audioPlayer.play(
                url: url,
                title: tour.title,
                artist: maker?.displayName,
                sourceId: tour.id.uuidString
            )
        }
    }

    /// Whether a given stop is the one currently producing audio.
    /// Combines the shared `currentPlayingStopId` (set by every
    /// playback trigger — PlayerView, ProximityMonitor, this view's
    /// Start Tour) with the audio engine's live state, so the
    /// indicator clears on pause / end / failure rather than
    /// flickering as a stale highlight.
    private func isPlayingStop(_ stop: Stop) -> Bool {
        appShared.currentPlayingStopId == stop.id
            && audioPlayer.currentSourceId == tour.id.uuidString
            && (audioPlayer.state == .playing || audioPlayer.state == .loading)
    }

    private func toggleSaved() {
        libraryStore.toggleSaved(tour.id)
    }

    private var isSaved: Bool {
        libraryStore.isSaved(tour.id)
    }

    // MARK: - Audio state derivations
    //
    // We identify "this tour's audio" via the AudioPlayerService's
    // `currentSourceId`, set by PlayerView to the tour's UUID string
    // when it calls `play(url:title:artist:sourceId:)`. M-player owns
    // the actual playback control; this view only reads the state for
    // label decoration.

    private var isThisTourActive: Bool {
        audioPlayer.currentSourceId == tour.id.uuidString
            && audioPlayer.state != .idle
            && audioPlayer.state != .failed
    }

    /// Label adapts to the audio state:
    ///   - "Start Tour" when idle / no audio loaded → tap starts playback.
    ///   - "Pause"  when audio is actively producing sound → tap pauses.
    ///   - "Resume" when paused or ended → tap resumes / replays.
    private var primaryButtonTitle: String {
        guard isThisTourActive else { return "Start Tour" }
        switch audioPlayer.state {
        case .playing, .loading: return "Pause"
        case .paused, .ended:    return "Resume"
        case .idle, .failed:     return "Start Tour"
        }
    }

    private var primaryButtonIcon: String {
        guard isThisTourActive else { return "play.fill" }
        switch audioPlayer.state {
        case .playing, .loading: return "pause.fill"
        case .paused, .ended:    return "play.fill"
        case .idle, .failed:     return "play.fill"
        }
    }

    private var isThisTourLoading: Bool {
        audioPlayer.currentSourceId == tour.id.uuidString
            && audioPlayer.state == .loading
    }

    // MARK: - Primary-button progress ring

    /// Diameter of the *PROGRESS RING* drawn around the primary
    /// button's leading glyph. Smaller than the MiniPlayerBar's 36pt
    /// because the inline button is shorter; ring fits comfortably
    /// inside the 44pt control height with breathing room.
    private static let primaryButtonRingSize: CGFloat = 28

    /// 0…1 fraction of the loaded audio that has played, mirrored
    /// from MiniPlayerBar's identical computation. 0 when this tour
    /// isn't the audible source or the duration isn't yet known.
    /// Forced to 1 on `.ended` so the ring reads as a complete
    /// circle when AVPlayer stops publishing currentTime a hair
    /// short of duration.
    private var tourProgressFraction: Double {
        guard isThisTourActive else { return 0 }
        if audioPlayer.state == .ended { return 1 }
        guard audioPlayer.duration > 0 else { return 0 }
        let raw = audioPlayer.currentTime / audioPlayer.duration
        return min(max(raw, 0), 1)
    }

    /// Leading glyph for the primary button. Idle tours get a plain
    /// SF Symbol (no ring); active tours get the glyph wrapped in a
    /// matching *PROGRESS RING* — same trim math, same lineWidth as
    /// the MiniPlayerBar, scaled to fit the inline 44pt control. Ring
    /// strokes use white so they read against the gold tint fill.
    @ViewBuilder
    private var primaryButtonLeadingGlyph: some View {
        if isThisTourActive {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.35), lineWidth: 2)
                    .frame(width: Self.primaryButtonRingSize, height: Self.primaryButtonRingSize)
                Circle()
                    .trim(from: 0, to: tourProgressFraction)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: Self.primaryButtonRingSize, height: Self.primaryButtonRingSize)
                    .animation(.linear(duration: 0.5), value: tourProgressFraction)
                Image(systemName: primaryButtonIcon)
                    .font(.system(size: 13, weight: .semibold))
            }
        } else {
            Image(systemName: primaryButtonIcon)
                .font(AtlasTypography.body.weight(.semibold))
        }
    }
}
