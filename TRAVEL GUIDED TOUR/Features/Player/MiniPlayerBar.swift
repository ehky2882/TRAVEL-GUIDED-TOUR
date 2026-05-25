import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Total visible height of the mini-player + tab bar stack at the
/// bottom of every screen — fed into `BottomSheet.bottomReservedHeight`
/// on Home and `safeAreaInset(.bottom)` on every other scrollable
/// surface so content never hides behind the module.
///
/// The module is **the same height (126pt) in every geometry mode**:
/// mini-player (62pt = 54 bar + 8 transparent top) + tab bar's
/// painted button row (56pt) + an 8pt outer strip below the buttons
/// (transparent on Home, opaque elsewhere). Because the height is
/// the same, the mini-player + tab bar buttons sit at the same
/// screen-y across all tabs and pushed detail screens.
///
/// The 8pt outer strip + the safe area beneath it (~34pt on Face-ID
/// iPhones) is already covered by the *painted* button row on
/// non-Home — the painted area extends down through the safe area
/// because the parent `ContentView` ignores the bottom safe area
/// and the VStack is bottom-aligned. So we don't need to *add*
/// safe-area height to the module's measurement; the standard 64pt
/// of tab bar already covers it.
///
/// The `extendsToScreenEdges` parameter is kept for callers that
/// want to be explicit at the call site about which geometry their
/// surface uses; the value it returns is the same in both modes.
enum AtlasBottomModule {
    /// Height of the `AtlasTabBar` painted button row (button
    /// column + 8pt vertical padding × 2). Constant across geometry
    /// modes — see `AtlasTabBar.body`.
    static let tabBarBackgroundHeight: CGFloat = 56

    /// Constant 126pt: 62 (mini-player view incl. 8pt transparent
    /// top) + 56 (tab bar painted) + 8 (outer strip). Same in both
    /// geometry modes, by design — only what's painted in the 8pt
    /// outer strip differs.
    static func height(extendsToScreenEdges: Bool = false) -> CGFloat {
        // `extendsToScreenEdges` no longer affects the math; both
        // modes have the same module height. Kept as a parameter
        // (with a default) so call sites that already pass it stay
        // valid and self-documenting at the boundary.
        _ = extendsToScreenEdges
        return MiniPlayerBar.layoutHeight
            + tabBarBackgroundHeight
            + MiniPlayerBar.floatingSideInset
    }
}

/// Persistent now-playing bar shown directly above the tab bar.
/// **Always present** — when a tour's audio is loaded it shows the
/// active tour with inline pause/resume, skip-forward, and
/// tap-to-open-player; when nothing is playing it shows a muted
/// welcome state with the same control footprint, so the bottom
/// island keeps a constant height.
///
/// Hosted by `ContentView` between the tab content and `AtlasTabBar`.
/// The bar is a plain rectangle with square corners; it stacks flush
/// on top of the tab bar (whose top corners are also square), so the
/// two read as one shape — square at the top, phone-rounded at the
/// bottom. Tapping the bar body (anywhere but the controls) opens
/// the full `PlayerView` when a tour is loaded.
struct MiniPlayerBar: View {
    /// The loaded tour, or `nil` when nothing is playing — the bar then
    /// renders its muted idle state.
    let tour: Tour?
    let maker: Maker?
    /// Invoked when the user taps the bar body — opens the full player.
    var onExpand: () -> Void

    @Environment(AudioPlayerService.self) private var audioPlayer

    /// Bar content height.
    static let barHeight: CGFloat = 54
    /// Gap above the bar, separating the bottom island from the
    /// content / drawer above it.
    static let topGap: CGFloat = 8
    /// Horizontal inset — matches the tab bar's inset so the bar
    /// and tab bar stack into one flush, equal-width island. Used
    /// on every surface: the bar is always rendered in the
    /// inset-island form so the buttons sit in the same place
    /// across Home, Library, Me, and every pushed detail. On
    /// non-Home surfaces `ContentView` paints an edge-to-edge
    /// background behind the inset island so the side gaps blend
    /// into a continuous full-width strip; the bar itself is
    /// unchanged.
    static let floatingSideInset: CGFloat = 8
    /// Total vertical space the bar occupies, including its top gap.
    /// `HomeView` adds this to its drawer peek height, and
    /// `TourDetailView` to its action-bar inset, so their content
    /// clears the bar.
    static var layoutHeight: CGFloat { barHeight + topGap }

    /// Diameter of the circular leading icon (author avatar / idle
    /// placeholder).
    private static let iconSize: CGFloat = 32
    /// Visible diameter of the progress ring around the play/pause
    /// icon. The button's tappable frame is larger (`controlSize`).
    private static let playRingSize: CGFloat = 36
    /// Tappable square frame for both the skip-forward and play/pause
    /// controls — kept ≥ Apple's 44pt HIG minimum.
    private static let controlSize: CGFloat = 44

    /// Welcome message shown in the title slot when no tour is loaded.
    private static let idleWelcomeText = "Hello! Ready to explore? Let's find an audio tour!"

    /// 0…1 fraction of the loaded audio that has played. 0 when no
    /// tour is loaded or the duration is not yet known. Drives both
    /// the trim arc and animates smoothly because
    /// `AudioPlayerService` republishes `currentTime` ~2×/sec.
    /// Forced to 1 on `.ended` so the ring reads as a complete circle
    /// even when AVPlayer stopped publishing `currentTime` a touch
    /// short of `duration`.
    private var progress: Double {
        guard tour != nil else { return 0 }
        if audioPlayer.state == .ended { return 1 }
        guard audioPlayer.duration > 0 else { return 0 }
        let raw = audioPlayer.currentTime / audioPlayer.duration
        return min(max(raw, 0), 1)
    }

    /// True when the bar has no tour loaded — used to gate control
    /// behavior and tone the icons down so the bar reads as inert.
    private var isIdle: Bool { tour == nil }

    var body: some View {
        HStack(spacing: AtlasSpacing.sm) {
            bodyButton
            skipForwardButton
            playPauseButton
        }
        .padding(.leading, AtlasSpacing.lg)
        .padding(.trailing, AtlasSpacing.md)
        .frame(height: Self.barHeight)
        .frame(maxWidth: .infinity)
        .background(AtlasColors.secondaryBackground)
        .padding(.horizontal, Self.floatingSideInset)
        .padding(.top, Self.topGap)
    }

    // MARK: - Leading body (icon + titles)

    /// Icon + two-line marquee block. Tappable when a tour is loaded
    /// (opens the full player); a passive view otherwise.
    @ViewBuilder
    private var bodyButton: some View {
        if isIdle {
            bodyContent
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Self.idleWelcomeText)
        } else {
            Button(action: onExpand) {
                bodyContent
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Now playing: \(tour?.title ?? "")")
            .accessibilityHint("Opens the full player.")
        }
    }

    private var bodyContent: some View {
        HStack(spacing: AtlasSpacing.sm) {
            leadingIcon

            VStack(alignment: .leading, spacing: 1) {
                MarqueeText(
                    text: titleText,
                    font: AtlasTypography.caption,
                    color: AtlasColors.primaryText
                )
                MarqueeText(
                    text: subtitleText,
                    font: AtlasTypography.caption,
                    color: AtlasColors.secondaryText
                )
            }
        }
    }

    @ViewBuilder
    private var leadingIcon: some View {
        if tour != nil {
            authorIcon
        } else {
            idleIcon
        }
    }

    /// Circular avatar of the tour's maker. Falls back to the Atlas
    /// Studio app-icon avatar when the maker has no remote avatar —
    /// mirrors `MakerView`.
    private var authorIcon: some View {
        Group {
            if let urlString = maker?.avatarURL,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        Circle().fill(AtlasColors.placeholderWarm)
                    }
                }
            } else {
                Image("AtlasStudioAvatar")
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(width: Self.iconSize, height: Self.iconSize)
        .clipShape(Circle())
    }

    /// Circular muted placeholder — headphones glyph in the same
    /// 32pt slot the author avatar occupies when a tour is playing.
    private var idleIcon: some View {
        ZStack {
            Circle().fill(AtlasColors.tertiaryText.opacity(0.15))
            Image(systemName: "headphones")
                .font(.system(size: 15))
                .foregroundStyle(AtlasColors.tertiaryText)
        }
        .frame(width: Self.iconSize, height: Self.iconSize)
    }

    private var titleText: String {
        if let tour { return tour.title }
        return Self.idleWelcomeText
    }

    private var subtitleText: String {
        guard tour != nil else { return " " } // blank second line keeps layout stable
        switch audioPlayer.state {
        case .failed:
            return "Tap to retry"
        case .paused:
            if let maker { return "Paused · \(maker.displayName)" }
            return "Paused"
        case .idle, .loading, .playing, .ended:
            // The mini-player never surfaces a transient "Loading…"
            // line — the full-screen player owns that affordance.
            // Falling through to the maker name keeps the bar visually
            // stable as the tour spins up, finishes, or briefly
            // re-buffers between AVPlayer transitions.
            return maker?.displayName ?? " "
        }
    }

    // MARK: - Controls

    /// 10-second jump-ahead control. Always visible; tonally muted +
    /// inert when there's no tour to skip within.
    private var skipForwardButton: some View {
        Button(action: skipForward) {
            Image(systemName: "goforward.10")
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(isIdle ? AtlasColors.tertiaryText : AtlasColors.primaryText)
                .frame(width: Self.controlSize, height: Self.controlSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isIdle)
        .accessibilityLabel("Skip forward 10 seconds")
    }

    /// Play / pause control wrapped in a thin circular progress ring.
    /// Ring trims from 0 to `progress` so it fills clockwise as the
    /// current audio advances. Always visible; tap is inert when
    /// nothing's loaded.
    private var playPauseButton: some View {
        Button(action: togglePlayPause) {
            ZStack {
                // Background track — a faint full circle so the ring
                // is legible even at 0% progress.
                Circle()
                    .stroke(
                        AtlasColors.tertiaryText.opacity(0.3),
                        lineWidth: 2
                    )
                    .frame(width: Self.playRingSize, height: Self.playRingSize)
                // Progress arc.
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        isIdle ? AtlasColors.tertiaryText : AtlasColors.primaryText,
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: Self.playRingSize, height: Self.playRingSize)
                    .animation(.linear(duration: 0.5), value: progress)
                Image(systemName: playPauseIcon)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(isIdle ? AtlasColors.tertiaryText : AtlasColors.primaryText)
            }
            .frame(width: Self.controlSize, height: Self.controlSize)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isIdle)
        .accessibilityLabel(playPauseAccessibilityLabel)
    }

    private var playPauseAccessibilityLabel: String {
        switch audioPlayer.state {
        case .playing: return "Pause"
        case .ended:   return "Replay tour"
        default:       return "Play"
        }
    }

    /// `.loading` resolves to the play glyph rather than an hourglass
    /// on purpose: the mini-player keeps the same icon throughout
    /// buffering and end-of-tour transitions so it doesn't flicker
    /// when AVPlayer briefly re-enters `.waitingToPlayAtSpecifiedRate`.
    private var playPauseIcon: String {
        switch audioPlayer.state {
        case .playing:                         return "pause.fill"
        case .failed:                          return "arrow.clockwise"
        case .idle, .loading, .paused, .ended: return "play.fill"
        }
    }

    private func togglePlayPause() {
        guard tour != nil else { return }
        switch audioPlayer.state {
        case .playing:
            audioPlayer.pause()
        case .paused:
            audioPlayer.play()
        case .ended:
            // Tour finished — restart from the beginning in place so
            // the user doesn't have to open the full player just to
            // replay. AVQueuePlayer has already drained its queue, so
            // we re-issue the last play(url:) rather than calling
            // play() with no args.
            audioPlayer.replayLast()
        case .loading, .failed, .idle:
            // No clean in-place resume — hand off to the full player,
            // which owns stop/intro sequencing and the retry path.
            onExpand()
        }
    }

    private func skipForward() {
        guard tour != nil else { return }
        audioPlayer.skip(by: 10)
    }
}
