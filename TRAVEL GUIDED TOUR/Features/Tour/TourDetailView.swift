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

    @State private var showingPlayer = false

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: AtlasSpacing.lg) {
                    HeroImageView(
                        imageName: tour.heroImageURL,
                        height: AtlasSpacing.heroHeight,
                        category: tour.primaryCategory
                    )

                    VStack(alignment: .leading, spacing: AtlasSpacing.md) {
                        titleSection
                        makerRow
                        metaRow
                        descriptionSection
                        stopsSection
                    }
                    .padding(.horizontal, AtlasSpacing.lg)

                    // Spacer so the sticky action bar doesn't cover the
                    // last stop row when the user scrolls to the bottom.
                    Color.clear.frame(height: AtlasSpacing.xxl + AtlasSpacing.lg)
                }
            }
            .background(AtlasColors.background)

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

    private var actionBar: some View {
        HStack(spacing: AtlasSpacing.md) {
            Button(action: handlePrimaryAction) {
                Label(primaryButtonTitle, systemImage: primaryButtonIcon)
                    .font(AtlasTypography.body)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AtlasSpacing.sm)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isThisTourLoading)

            Button(action: toggleSaved) {
                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                    .font(AtlasTypography.body)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.bordered)
            .accessibilityLabel(isSaved ? "Remove from saved" : "Save tour")

            downloadButton
        }
        .padding(.horizontal, AtlasSpacing.lg)
        .padding(.vertical, AtlasSpacing.md)
        .background(
            AtlasColors.background
                .shadow(color: AtlasColors.cardShadow, radius: 8, y: -2)
                .ignoresSafeArea(edges: .bottom)
        )
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

        VStack(spacing: 2) {
            Button(action: handleDownloadTap) {
                downloadButtonIcon(for: state)
                    .font(AtlasTypography.body)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.bordered)
            .disabled(isOtherActive)
            .accessibilityLabel(downloadAccessibilityLabel(for: state))

            Text(downloadCaption(for: state))
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.tertiaryText)
                .lineLimit(1)
        }
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

    private func downloadCaption(for state: TourDownloader.DownloadState) -> String {
        switch state {
        case .idle: return "Download"
        case .downloading(let progress): return "\(Int(progress * 100))%"
        case .completed: return "Downloaded"
        case .failed: return "Retry"
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
        isThisTourActive ? "Open player" : "Start"
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
        let minutes = seconds / 60
        let remaining = seconds % 60
        if minutes == 0 {
            return "\(remaining)s"
        }
        if remaining == 0 {
            return "\(minutes) min"
        }
        return "\(minutes) min \(remaining)s"
    }

    private func formattedWalkingDistance(_ meters: Int?) -> String {
        guard let meters else { return "—" }
        if meters < 1000 {
            return "\(meters) m"
        }
        let km = Double(meters) / 1000
        return String(format: "%.1f km", km)
    }
}
