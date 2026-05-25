import SwiftUI

/// Tour detail screen — spec § Key screens #4 / roadmap M-tour-detail.
///
/// Layout (top to bottom):
///   - Hero image (`HeroImageView` with category icon fallback)
///   - Title + category chip
///   - Maker row (NavigationLink → MakerView)
///   - Meta row (length, walking distance for multi-stop, stop count)
///   - Long description
///   - Stops list (non-tappable; tap-to-play is a player concern in M-player)
///   - Sticky action bar at the bottom: Start / Save / Download
///
/// Start hands off to `AudioPlayerService` — plays intro audio if the
/// tour has one, otherwise stop 0. Sequencing through subsequent stops
/// lands in M-player.
///
/// Save is fully wired to `LibraryStore`.
/// Download is visible but disabled until M-offline.
struct TourDetailView: View {
    let tour: Tour

    @Environment(DataService.self) private var dataService
    @Environment(LibraryStore.self) private var libraryStore
    @Environment(AudioPlayerService.self) private var audioPlayer
    @Environment(RecentlyViewedStore.self) private var recentlyViewedStore
    @Environment(TourDownloader.self) private var tourDownloader
    @Environment(\.atlasIsHomeTab) private var isHomeTab

    @State private var showingPlayer = false

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: AtlasSpacing.lg) {
                    imageSection

                    VStack(alignment: .leading, spacing: AtlasSpacing.md) {
                        titleSection
                        makerRow
                        metaRow
                        descriptionSection
                        stopsSection
                    }
                    .padding(.horizontal, AtlasSpacing.lg)

                    // Spacer matches the sticky action bar's full height
                    // so the last stop / description line lands at the
                    // action bar's top edge when the user scrolls all
                    // the way down. The action bar itself is sized to
                    // cover the bottom mini-player + tab bar module
                    // beneath it, so the buttons stay above the module
                    // and nothing scrollable hides behind either.
                    Color.clear.frame(height: actionBarHeight)
                }
            }
            .background(AtlasColors.secondaryBackground)

            actionBar
        }
        .navigationTitle(tour.title)
        .inlineNavigationBarTitle()
        .sheet(isPresented: $showingPlayer) {
            PlayerView(tour: tour)
        }
        .onAppear {
            recentlyViewedStore.record(tour.id)
        }
        .onChange(of: tourDownloader.states[tour.id]) { _, newState in
            // Keep LibraryStore in sync with the download lifecycle.
            // The downloader is decoupled from LibraryStore so this is
            // the single place that mirrors the two.
            switch newState {
            case .completed:
                libraryStore.markDownloaded(tour.id)
            case .idle, .failed, .none:
                // .idle from a delete or a failed-and-cleaned state;
                // .none if we never touched it. In both cases clear
                // the LibraryStore record so Library → Downloaded is
                // accurate.
                if libraryStore.entry(for: tour.id)?.downloadedAt != nil {
                    libraryStore.clearDownload(tour.id)
                }
            case .downloading:
                break
            }
        }
    }

    // MARK: - Sections

    /// Hero area: single image for tours with one photo, paging carousel
    /// for tours that supply `additionalImageURLs`.
    @ViewBuilder
    private var imageSection: some View {
        let allImages = [tour.heroImageURL] + (tour.additionalImageURLs ?? [])
        if allImages.count > 1 {
            TabView {
                ForEach(allImages, id: \.self) { url in
                    HeroImageView(imageName: url, height: AtlasSpacing.heroHeight, zoomable: true)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: AtlasSpacing.heroHeight)
            .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.cardCornerRadius))
            .padding(.horizontal, AtlasSpacing.lg)
        } else {
            HeroImageView(
                imageName: tour.heroImageURL,
                height: AtlasSpacing.heroHeight,
                cornerRadius: AtlasSpacing.cardCornerRadius,
                category: tour.primaryCategory,
                zoomable: true
            )
            .padding(.horizontal, AtlasSpacing.lg)
        }
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            Text(tour.title)
                .font(AtlasTypography.headline)
                .foregroundStyle(AtlasColors.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: AtlasSpacing.sm) {
                TagChip(text: tour.primaryCategory.displayName)
                if tour.kind == .multiStop {
                    TagChip(text: "Walking tour")
                }
            }
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
                    .padding(.vertical, AtlasSpacing.sm)
                }
                .buttonStyle(.plain)
            } else {
                EmptyView()
            }
        }
    }

    private var metaRow: some View {
        HStack(spacing: AtlasSpacing.md) {
            metaItem(icon: "clock", text: formattedDuration(tour.totalDurationSeconds))

            if tour.kind == .multiStop {
                metaItem(icon: "figure.walk", text: formattedWalkingDistance(tour.walkingDistanceMeters))
                metaItem(icon: "mappin.and.ellipse", text: "\(tour.stops.count) stops")
            }
        }
    }

    private func metaItem(icon: String, text: String) -> some View {
        HStack(spacing: AtlasSpacing.xs) {
            Image(systemName: icon)
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.secondaryText)
            Text(text)
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.secondaryText)
        }
    }

    private var descriptionSection: some View {
        Text(tour.longDescription)
            .font(AtlasTypography.body)
            .foregroundStyle(AtlasColors.primaryText)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var stopsSection: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            Text(tour.kind == .multiStop ? "Stops" : "Location")
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
            Text("\(stop.order + 1)")
                .font(AtlasTypography.body)
                .foregroundStyle(AtlasColors.secondaryText)
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

                Text(formattedDuration(stop.audioDurationSeconds))
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.tertiaryText)
            }

            Spacer()
        }
        .padding(.vertical, AtlasSpacing.xs)
    }

    // MARK: - Action bar

    /// Shared height for all three action-bar controls so the primary
    /// button, Save, and Download line up in size and baseline.
    private let controlHeight: CGFloat = 36

    /// Vertical space the action bar reserves for its button row above
    /// the bottom module: `top padding (lg)` + the button itself + a
    /// small breathing gap (`sm`) so the buttons don't kiss the
    /// floating-island's top edge.
    private var actionBarButtonArea: CGFloat {
        AtlasSpacing.lg + controlHeight + AtlasSpacing.sm
    }

    /// Action-bar height — large enough to (a) seat its button row at
    /// the top with the standard padding profile, and (b) extend its
    /// background down through the entire mini-player + tab bar module
    /// that floats over it from `ContentView`. Tracks
    /// `AtlasBottomModule.height` directly so the value stays correct
    /// when the module switches between Home's floating-island look
    /// and the full-edge look used on other tabs.
    private var actionBarHeight: CGFloat {
        AtlasBottomModule.height(extendsToScreenEdges: !isHomeTab)
            + actionBarButtonArea
    }

    private var actionBar: some View {
        HStack(spacing: AtlasSpacing.md) {
            Button(action: handlePrimaryAction) {
                Label(primaryButtonTitle, systemImage: primaryButtonIcon)
                    .font(AtlasTypography.body)
                    .frame(maxWidth: .infinity)
                    .frame(height: controlHeight)
            }
            .buttonStyle(.borderedProminent)
            // Intentionally never disabled — even when the audio engine
            // is mid-load or stuck in a transient `.loading` state (e.g.
            // after a seek-to-end), the player sheet is the user's
            // escape hatch and must stay reachable.

            Button(action: toggleSaved) {
                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                    .font(AtlasTypography.body)
                    .frame(width: controlHeight, height: controlHeight)
            }
            .buttonStyle(.bordered)
            .accessibilityLabel(isSaved ? "Remove from saved" : "Save tour")

            downloadButton
        }
        .padding(.horizontal, AtlasSpacing.lg)
        .padding(.top, AtlasSpacing.lg)
        .frame(maxWidth: .infinity)
        // Fixed height so the action bar's top edge lines up with the
        // home drawer's peek detent. Buttons sit at the top; the space
        // below clears the bottom island (tab bar + mini-player),
        // which overlays it.
        .frame(height: actionBarHeight, alignment: .top)
        .background(
            AtlasColors.secondaryBackground
                .shadow(color: AtlasColors.cardShadow, radius: 8, y: -2)
        )
        // Extend to the physical screen bottom so actionBarHeight is
        // measured from the same baseline as the drawer (which also
        // ignores the bottom safe area). Without this the action bar
        // stops at the home-indicator inset and its top sits higher
        // than the drawer's peek detent.
        .ignoresSafeArea(.container, edges: .bottom)
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

    // MARK: - Actions

    /// The primary button always opens the player sheet. The player itself
    /// owns playback orchestration — starting audio on first appear, and
    /// keeping it going when the sheet is dismissed. Re-tapping opens the
    /// sheet back up without restarting audio.
    private func handlePrimaryAction() {
        showingPlayer = true
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

    private var primaryButtonTitle: String {
        isThisTourActive ? "Open player" : "Start Tour"
    }

    private var primaryButtonIcon: String {
        isThisTourActive ? "waveform" : "play.fill"
    }

    private var isThisTourLoading: Bool {
        audioPlayer.currentSourceId == tour.id.uuidString
            && audioPlayer.state == .loading
    }

    // MARK: - Formatters

    private func formattedDuration(_ seconds: Int) -> String {
        AtlasFormatters.duration(seconds: seconds)
    }

    private func formattedWalkingDistance(_ meters: Int?) -> String {
        guard let meters else { return "—" }
        return AtlasFormatters.distance(meters: Double(meters))
    }
}
