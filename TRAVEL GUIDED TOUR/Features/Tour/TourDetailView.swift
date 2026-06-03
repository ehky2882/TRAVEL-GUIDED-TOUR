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

    private var descriptionSection: some View {
        Text(tour.longDescription)
            .font(AtlasTypography.body)
            .foregroundStyle(AtlasColors.primaryText)
            .fixedSize(horizontal: false, vertical: true)
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

    private func stopRow(_ stop: Stop) -> some View {
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

                if let caption = stop.caption {
                    Text(caption)
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text(AtlasFormatters.duration(seconds: stop.audioDurationSeconds))
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.tertiaryText)
            }

            Spacer()
        }
        .padding(.vertical, AtlasSpacing.xs)
    }

    // MARK: - Button row (inline)

    /// Shared height for the three buttons so they line up in size and
    /// baseline.
    private let controlHeight: CGFloat = 44

    /// Inline button row — sits above the description so users can
    /// act without scrolling. Order: Start Tour (primary, full
    /// width) · Save · Download. Tinted with the map-pin gold so the
    /// inline action surface matches the map's visual identity.
    private var buttonRow: some View {
        HStack(spacing: AtlasSpacing.md) {
            Button(action: handlePrimaryAction) {
                Label(primaryButtonTitle, systemImage: primaryButtonIcon)
                    .font(AtlasTypography.body.weight(.semibold))
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
        // If this tour's audio is already loaded, don't restart —
        // resume if paused, no-op otherwise. The "Open player" label
        // case is already handled by this branch (mini-player is
        // where users go to actually open it now).
        if audioPlayer.currentSourceId == tour.id.uuidString
            && audioPlayer.state != .idle
            && audioPlayer.state != .failed {
            if audioPlayer.state == .paused || audioPlayer.state == .ended {
                audioPlayer.play()
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
    ///   - "Playing" when audio is actively producing sound → tap is a
    ///     no-op (visual indicator only — the mini-player handles
    ///     transport and is the only path to the full player).
    ///   - "Resume" when paused or ended → tap resumes / replays.
    private var primaryButtonTitle: String {
        guard isThisTourActive else { return "Start Tour" }
        switch audioPlayer.state {
        case .playing, .loading: return "Playing"
        case .paused, .ended:    return "Resume"
        case .idle, .failed:     return "Start Tour"
        }
    }

    private var primaryButtonIcon: String {
        guard isThisTourActive else { return "play.fill" }
        switch audioPlayer.state {
        case .playing, .loading: return "waveform"
        case .paused, .ended:    return "play.fill"
        case .idle, .failed:     return "play.fill"
        }
    }

    private var isThisTourLoading: Bool {
        audioPlayer.currentSourceId == tour.id.uuidString
            && audioPlayer.state == .loading
    }
}
