import SwiftUI

/// Full-screen audio player — spec § Key screens #6 / roadmap M-player.
///
/// Presented as a modal sheet from `TourDetailView` (Apple Music /
/// Spotify pattern). Owns the playlist orchestration for the tour:
/// holds `currentStopIndex` (-1 = intro, 0..n = stops) and drives
/// `AudioPlayerService` with the matching URL.
///
/// `AudioPlayerService` stays a pure audio engine — no tour awareness.
/// Auto-advance: when the service reports `.ended`, we move to the
/// next stop and play it. If we were at the last stop, playback stops.
///
/// Geofence-driven stop progression and "distance to next stop" land
/// in M-geofencing — the slots for them stay in this layout so the
/// migration is small.
struct PlayerView: View {
    let tour: Tour

    @Environment(\.dismiss) private var dismiss
    @Environment(DataService.self) private var dataService
    @Environment(AudioPlayerService.self) private var audioPlayer
    @Environment(LibraryStore.self) private var libraryStore
    @Environment(LocationManager.self) private var locationManager
    @Environment(ProximityMonitor.self) private var proximityMonitor
    @Environment(TourDownloader.self) private var tourDownloader
    @Environment(AppSharedState.self) private var appShared

    /// -1 means the tour's intro audio is playing (only valid when
    /// the tour has an `introAudioURL`). 0...n indexes `sortedStops`.
    @State private var currentStopIndex: Int = 0

    /// Local mirror of the user's scrub gesture — when the user is
    /// actively dragging, we display this instead of `audioPlayer.currentTime`
    /// so the thumb doesn't fight the periodic time observer.
    @State private var isScrubbing: Bool = false
    @State private var scrubTime: TimeInterval = 0

    /// Drives the inline 3-line / full toggle on the current stop's
    /// caption.
    @State private var isCaptionExpanded: Bool = false

    private let availableRates: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]

    var body: some View {
        VStack(spacing: 0) {
            dismissHandle

            ScrollView {
                VStack(spacing: AtlasSpacing.lg) {
                    imageSection

                    currentStopSection
                    if audioPlayer.state == .failed {
                        failureBanner
                    }
                    scrubBar
                    transportRow
                    stopsListSection
                }
                .padding(.bottom, AtlasSpacing.xl)
            }
        }
        .background(AtlasColors.background)
        .onAppear {
            startPlaybackIfNeeded()
            startGeofenceMonitoringIfNeeded()
        }
        .onChange(of: audioPlayer.state, initial: false) { _, newState in
            // Persist progress to the LibraryStore at meaningful state
            // transitions. Writing on every periodic-time observation
            // would be too chatty — pause/end is the natural checkpoint.
            // V1 simplification: listenedSeconds reflects position within
            // the *current item* (intro or stop), not aggregated progress
            // across the whole tour. The "Recently played" rail only
            // needs `> 0` to surface, so this is functionally enough.
            // M-launch-content / a polish pass can tighten the math.
            switch newState {
            case .paused, .ended:
                writeProgress()
            case .playing, .loading, .idle, .failed:
                break
            }

            if newState == .ended {
                handlePlaybackEnded()
            }
        }
        .onChange(of: proximityMonitor.lastEnteredStopId, initial: false) { _, newStopId in
            // Geofence fired for one of this tour's stops. Proximity
            // monitor has already kicked off audio for that stop; we
            // just sync our local currentStopIndex so transport
            // controls (prev/next, list highlight) match the new
            // playing source.
            syncStopIndex(from: newStopId)
        }
        .onDisappear {
            // Also write on dismiss so closing the sheet captures the
            // last-known position without waiting for a pause event.
            writeProgress()
            // NB: don't stop geofence monitoring here — audio may
            // continue while the user pockets their phone. Monitoring
            // is torn down only on a new tour's start or explicit stop.
        }
    }

    // MARK: - Geofencing

    private var hasGeofencedStops: Bool {
        tour.stops.contains { $0.triggerMode == .geofenced }
    }

    private func startGeofenceMonitoringIfNeeded() {
        guard hasGeofencedStops else { return }
        // Upgrade-prompt for Always location — only shown if user
        // previously granted When-In-Use. Apple gates the dialog.
        locationManager.requestAlwaysIfPossible()
        proximityMonitor.startMonitoring(
            tour: tour,
            maker: dataService.maker(for: tour),
            audioPlayer: audioPlayer,
            tourDownloader: tourDownloader
        )
    }

    private func syncStopIndex(from stopId: UUID?) {
        guard let stopId,
              let index = sortedStops.firstIndex(where: { $0.id == stopId }) else {
            return
        }
        currentStopIndex = index
    }

    private func writeProgress() {
        let secs = Int(audioPlayer.currentTime)
        guard secs > 0 else { return }
        // We mark completed=false here. A true "tour completed" flag
        // is more naturally set when we reach the end of the *last*
        // stop and the audio ends — leave that refinement for later.
        libraryStore.updateProgress(
            tour.id,
            listenedSeconds: secs,
            completed: false
        )
    }

    // MARK: - Sections

    /// Chevron-down close button. The player is presented as a
    /// `.fullScreenCover` (so it covers the mini-player + tab bar
    /// window), which has no built-in swipe-to-dismiss — this is the
    /// only way out, wired to the environment `dismiss`.
    private var dismissHandle: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AtlasColors.secondaryText)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Close player")
            Spacer()
        }
        .padding(.horizontal, AtlasSpacing.sm)
        .padding(.top, AtlasSpacing.xs)
        .frame(maxWidth: .infinity)
        .background(AtlasColors.background)
    }

    /// Hero carousel — mirrors `TourDetailView.imageSection` exactly:
    /// square-cornered (no `clipShape` / `cornerRadius`), pinch-to-zoom
    /// enabled, and load crossfade disabled. Page dots match.
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

    /// Now-playing block. Sits directly under the carousel (the old
    /// tour-title section was removed — the stop title carries page
    /// identity). Header is the muted "Now playing" / "Stop N of M"
    /// line; the stop title is the prominent BODY all-caps element;
    /// the caption truncates to 3 lines with an inline Read more.
    private var currentStopSection: some View {
        VStack(spacing: AtlasSpacing.xs) {
            Text(stopHeaderText)
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.secondaryText)

            Text(currentStopTitle.uppercased())
                .font(AtlasTypography.body)
                .foregroundStyle(AtlasColors.primaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let caption = currentStopCaption {
                Text(caption)
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(isCaptionExpanded ? nil : 3)
                    .fixedSize(horizontal: false, vertical: true)
                    .animation(.easeInOut(duration: 0.2), value: isCaptionExpanded)

                if captionOverflowsThreeLines(caption) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isCaptionExpanded.toggle()
                        }
                    } label: {
                        Text(isCaptionExpanded ? "Show less" : "Read more…")
                            .font(AtlasTypography.caption)
                            .foregroundStyle(AtlasColors.secondaryText)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isCaptionExpanded ? "Show less" : "Read more")
                }
            }
        }
        .padding(.horizontal, AtlasSpacing.lg)
    }

    /// Char-count proxy for "does this caption exceed 3 lines at our
    /// width?" — mirrors `TourDetailView`'s description overflow proxy
    /// (~60 chars/line on iPhone width → ~180 for 3 lines). Avoids a
    /// GeometryReader round-trip that would fight the expand animation.
    private func captionOverflowsThreeLines(_ text: String) -> Bool {
        text.count > 180
    }

    /// Shown when `audioPlayer.state == .failed`. The transport row's
    /// play button (a refresh icon in this state) is the retry path.
    private var failureBanner: some View {
        HStack(spacing: AtlasSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(AtlasTypography.body)
                .foregroundStyle(AtlasColors.primaryText)
            Text(audioPlayer.lastError?.localizedDescription ?? "Couldn't load audio.")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.primaryText)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(AtlasSpacing.md)
        .background(AtlasColors.secondaryBackground)
        .overlay(
            RoundedRectangle(cornerRadius: AtlasSpacing.cardCornerRadius)
                .stroke(AtlasColors.secondaryText.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.cardCornerRadius))
        .padding(.horizontal, AtlasSpacing.lg)
    }

    private var scrubBar: some View {
        VStack(spacing: AtlasSpacing.xs) {
            Slider(
                value: scrubValueBinding,
                in: 0...(max(audioPlayer.duration, 1)),
                onEditingChanged: { editing in
                    if editing {
                        isScrubbing = true
                        scrubTime = audioPlayer.currentTime
                    } else {
                        audioPlayer.seek(to: scrubTime)
                        isScrubbing = false
                    }
                }
            )
            .tint(AtlasColors.mapPin)
            .disabled(audioPlayer.duration <= 0)

            HStack {
                Text(formatTime(displayedTime))
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
                Spacer()
                Text(formatTime(audioPlayer.duration))
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
            }
        }
        .padding(.horizontal, AtlasSpacing.lg)
    }

    /// Transport row. The leading + trailing controls swap on tour
    /// kind: multi-stop tours navigate between stops (prev/next),
    /// single-stop tours — which have no other stops to jump to —
    /// scrub the current audio by ±10s instead, so the controls are
    /// always live rather than greyed out.
    private var transportRow: some View {
        HStack(spacing: AtlasSpacing.xl) {
            if tour.kind == .multiStop {
                previousStopButton
            } else {
                skipBackwardButton
            }

            playPauseButton

            if tour.kind == .multiStop {
                nextStopButton
            } else {
                skipForwardButton
            }
        }
        // Center the skip/play/skip cluster on the full width so the
        // play button lands on the horizontal center of the screen;
        // the speed button is a trailing overlay so it never shifts
        // the cluster off center.
        .frame(maxWidth: .infinity)
        .overlay(alignment: .trailing) {
            rateButton
                .padding(.trailing, AtlasSpacing.lg)
        }
        .padding(.vertical, AtlasSpacing.md)
    }

    /// Play / pause — the screen-centered anchor of the transport row,
    /// tinted map-pin gold to match the scrubber.
    private var playPauseButton: some View {
        Button(action: togglePlayPause) {
            Image(systemName: playPauseIcon)
                .font(.system(size: 44))
                .foregroundStyle(AtlasColors.mapPin)
        }
        .accessibilityLabel(audioPlayer.state == .playing ? "Pause" : "Play")
    }

    private var rateButton: some View {
        Button(action: cycleRate) {
            Text(rateLabel)
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.primaryText)
                .padding(.horizontal, AtlasSpacing.sm)
                .padding(.vertical, AtlasSpacing.xs)
                .overlay(
                    RoundedRectangle(cornerRadius: AtlasSpacing.cardCornerRadius / 2)
                        .stroke(AtlasColors.secondaryText.opacity(0.3), lineWidth: 1)
                )
        }
        .accessibilityLabel("Playback speed \(rateLabel)")
    }

    private var previousStopButton: some View {
        Button(action: previousStop) {
            Image(systemName: "backward.fill")
                .font(.system(size: 24))
                .foregroundStyle(canGoPrevious ? AtlasColors.primaryText : AtlasColors.tertiaryText)
        }
        .disabled(!canGoPrevious)
        .accessibilityLabel("Previous stop")
    }

    private var nextStopButton: some View {
        Button(action: nextStop) {
            Image(systemName: "forward.fill")
                .font(.system(size: 24))
                .foregroundStyle(canGoNext ? AtlasColors.primaryText : AtlasColors.tertiaryText)
        }
        .disabled(!canGoNext)
        .accessibilityLabel("Next stop")
    }

    private var skipBackwardButton: some View {
        Button(action: { audioPlayer.skip(by: -10) }) {
            Image(systemName: "gobackward.10")
                .font(.system(size: 24))
                .foregroundStyle(canSkip ? AtlasColors.primaryText : AtlasColors.tertiaryText)
        }
        .disabled(!canSkip)
        .accessibilityLabel("Skip back 10 seconds")
    }

    private var skipForwardButton: some View {
        Button(action: { audioPlayer.skip(by: 10) }) {
            Image(systemName: "goforward.10")
                .font(.system(size: 24))
                .foregroundStyle(canSkip ? AtlasColors.primaryText : AtlasColors.tertiaryText)
        }
        .disabled(!canSkip)
        .accessibilityLabel("Skip forward 10 seconds")
    }

    private var stopsListSection: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            Text(tour.kind == .multiStop ? "Stops" : "Location")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.secondaryText)
                .padding(.horizontal, AtlasSpacing.lg)

            ForEach(Array(sortedStops.enumerated()), id: \.element.id) { index, stop in
                Button {
                    playStop(at: index)
                } label: {
                    stopRow(stop, index: index)
                }
                .buttonStyle(.plain)

                if stop.id != sortedStops.last?.id {
                    Divider().padding(.leading, AtlasSpacing.lg)
                }
            }
        }
    }

    private func stopRow(_ stop: Stop, index: Int) -> some View {
        HStack(alignment: .top, spacing: AtlasSpacing.md) {
            ZStack {
                if index == currentStopIndex {
                    Image(systemName: audioPlayer.state == .playing ? "speaker.wave.2.fill" : "speaker.fill")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.primaryText)
                } else {
                    Text("\(stop.order + 1)")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                }
            }
            .frame(width: 24, alignment: .leading)

            VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                Text(stop.title.uppercased())
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

                Text(formatTime(TimeInterval(stop.audioDurationSeconds)))
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.tertiaryText)
            }

            Spacer()
        }
        .padding(.horizontal, AtlasSpacing.lg)
        .padding(.vertical, AtlasSpacing.sm)
        .background(
            index == currentStopIndex
                ? AtlasColors.secondaryBackground.opacity(0.0)
                : Color.clear
        )
    }

    // MARK: - Actions

    private func startPlaybackIfNeeded() {
        // If this tour's audio is already playing/paused/loading, don't
        // restart — just sync currentStopIndex to whatever's loaded.
        // `.failed` is treated like `.idle` so the user gets a retry
        // on the same source.
        if audioPlayer.currentSourceId == tour.id.uuidString
            && audioPlayer.state != .idle
            && audioPlayer.state != .failed {
            return
        }

        if tour.introAudioURL != nil {
            playIntro()
        } else if !sortedStops.isEmpty {
            playStop(at: 0)
        }
    }

    private func playIntro() {
        guard let urlString = tour.introAudioURL,
              let remoteURL = URL(string: urlString) else {
            return
        }
        // Prefer the on-disk copy if the tour is downloaded. Falls
        // back to streaming the remote URL otherwise.
        let url = tourDownloader.localURL(forIntroOf: tour) ?? remoteURL

        currentStopIndex = -1
        // Intro audio doesn't belong to any single stop — clear
        // the shared playing-stop id so the detail-sheet now-playing
        // indicator doesn't light up an unrelated row.
        appShared.currentPlayingStopId = nil
        let maker = dataService.maker(for: tour)
        audioPlayer.play(
            url: url,
            title: tour.title,
            artist: maker?.displayName,
            sourceId: tour.id.uuidString
        )
    }

    private func playStop(at index: Int) {
        guard sortedStops.indices.contains(index) else { return }
        let stop = sortedStops[index]
        guard let remoteURL = URL(string: stop.audioURL) else { return }

        // Prefer the on-disk copy if the tour is downloaded. Falls
        // back to streaming the remote URL otherwise.
        let url = tourDownloader.localURL(forStop: stop, in: tour) ?? remoteURL

        currentStopIndex = index
        // Surface the currently-playing stop to the detail-sheet
        // now-playing indicator (shared via AppSharedState — the
        // detail sheet may be the visible surface when this fires).
        appShared.currentPlayingStopId = stop.id
        let maker = dataService.maker(for: tour)
        audioPlayer.play(
            url: url,
            title: tour.title,
            artist: maker?.displayName,
            sourceId: tour.id.uuidString
        )
    }

    private func togglePlayPause() {
        switch audioPlayer.state {
        case .playing:
            audioPlayer.pause()
        case .paused:
            audioPlayer.play()
        case .ended:
            // AVQueuePlayer drains its queue at end-of-item, so a
            // parameterless `play()` would no-op. Restart the current
            // item from the beginning — feels like "replay" from the
            // user's POV. Mirrors the mini-player's tap-to-replay path.
            replayCurrent()
        case .idle, .failed:
            // No item loaded, or previous load failed → retry from the
            // tour's start (or current stop, if mid-tour).
            replayCurrent()
        case .loading:
            break
        }
    }

    /// Re-plays whatever is "current" — intro if we're on it, otherwise
    /// the current stop, otherwise the tour's start. Used after `.ended`
    /// (drained queue) and `.idle/.failed` (no/failed item).
    ///
    /// Goes directly through `playIntro` / `playStop` rather than
    /// `startPlaybackIfNeeded`, which short-circuits when our own
    /// sourceId is already loaded — exactly the case here.
    private func replayCurrent() {
        if currentStopIndex == -1 {
            playIntro()
        } else if sortedStops.indices.contains(currentStopIndex) {
            playStop(at: currentStopIndex)
        } else if tour.introAudioURL != nil {
            playIntro()
        } else if !sortedStops.isEmpty {
            playStop(at: 0)
        }
    }

    private func previousStop() {
        // From intro, no-op. From stop 0, no-op (caller disables it).
        // From stop n>0, go to stop n-1. (No "back to intro" jump —
        // the intro is a once-per-session preface, not a re-listenable item.)
        if currentStopIndex > 0 {
            playStop(at: currentStopIndex - 1)
        }
    }

    private func nextStop() {
        if currentStopIndex == -1 {
            // Intro → first stop.
            if !sortedStops.isEmpty { playStop(at: 0) }
        } else if currentStopIndex < sortedStops.count - 1 {
            playStop(at: currentStopIndex + 1)
        }
    }

    private func handlePlaybackEnded() {
        // Auto-advance from intro -> stop 0 is always desirable: the
        // user tapped Start so they've committed to begin the tour.
        if currentStopIndex == -1 {
            if !sortedStops.isEmpty { playStop(at: 0) }
            return
        }

        // Beyond intro, the *trigger mode of the next stop* governs
        // whether we auto-advance. Geofenced stops wait for the user
        // to walk into them; manual stops wait for a user tap (the
        // stops-list row or the next-stop transport button). In
        // either case we don't auto-advance here.
        //
        // The transport row's next-stop button stays available so
        // users on a couch can still progress through a geofenced
        // tour by tapping next.
    }

    private func cycleRate() {
        let currentIndex = availableRates.firstIndex(of: audioPlayer.rate) ?? 0
        let nextIndex = (currentIndex + 1) % availableRates.count
        audioPlayer.setPlaybackRate(availableRates[nextIndex])
    }

    // MARK: - Derived state

    private var sortedStops: [Stop] {
        tour.stops.sorted(by: { $0.order < $1.order })
    }

    private var canGoPrevious: Bool {
        currentStopIndex > 0
    }

    private var canGoNext: Bool {
        if currentStopIndex == -1 { return !sortedStops.isEmpty }
        return currentStopIndex < sortedStops.count - 1
    }

    /// Whether the ±10s skip controls (single-stop tours) are live —
    /// true once an audio item with a known duration is loaded.
    private var canSkip: Bool {
        audioPlayer.duration > 0
    }

    private var playPauseIcon: String {
        switch audioPlayer.state {
        case .playing: return "pause.circle.fill"
        case .loading: return "hourglass.circle.fill"
        case .failed: return "arrow.clockwise.circle.fill"
        default: return "play.circle.fill"
        }
    }

    private var rateLabel: String {
        let r = audioPlayer.rate
        if r == floor(r) {
            return String(format: "%.0fx", r)
        }
        return String(format: "%.2fx", r).replacingOccurrences(of: "0x", with: "x")
    }

    private var stopHeaderText: String {
        if currentStopIndex == -1 {
            return "Intro"
        }
        if tour.kind == .single {
            return "Now playing"
        }
        return "Stop \(currentStopIndex + 1) of \(sortedStops.count)"
    }

    private var currentStopTitle: String {
        if currentStopIndex == -1 {
            return "Tour introduction"
        }
        guard sortedStops.indices.contains(currentStopIndex) else { return tour.title }
        return sortedStops[currentStopIndex].title
    }

    private var currentStopCaption: String? {
        if currentStopIndex == -1 {
            return nil
        }
        guard sortedStops.indices.contains(currentStopIndex) else { return nil }
        return sortedStops[currentStopIndex].caption
    }

    private var displayedTime: TimeInterval {
        isScrubbing ? scrubTime : audioPlayer.currentTime
    }

    private var scrubValueBinding: Binding<TimeInterval> {
        Binding(
            get: { displayedTime },
            set: { scrubTime = $0 }
        )
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let total = Int(seconds)
        let minutes = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}
