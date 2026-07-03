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
    /// When `false` (Home + detail-up), the painted bar is inset
    /// 8pt from the screen edges — the floating-island look. When
    /// `true` (Library / Me with no detail), the painted bar grows
    /// to the screen edges. In both modes the controls sit at the
    /// SAME x positions so the design rule of "buttons identical
    /// everywhere" holds.
    var extendsToScreenEdges: Bool = false

    @Environment(AudioPlayerService.self) private var audioPlayer

    /// Bar content height.
    static let barHeight: CGFloat = 54
    /// Top gap is 0 — the painted bar's top edge IS the top of the
    /// mini-player view, so there's no transparent strip above the
    /// bar showing through to whatever's behind. Without this, the
    /// bar's painted top edge floats 8pt below the mini-player
    /// view's top, and any subtle window-compositing or subpixel
    /// alignment difference reads as a hairline "bump" at that y.
    static let topGap: CGFloat = 0
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
    /// Inner-HStack trailing inset. Chosen so the progress ring's
    /// outer right edge ends up 16pt from the bar's right edge:
    /// the ring (`playRingSize` = 36) sits centered in the
    /// `controlSize` = 44 frame, leaving 4pt between the ring and
    /// the frame's right edge; adding this 12pt trailing inset
    /// yields 16pt total ring-to-bar-edge.
    private static let trailingInnerInset: CGFloat = 12

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
        // Outer HStack spacing is 0: the 44pt control frames sit
        // edge-to-edge, but the 20pt skip-forward glyph and 36pt
        // play-ring inside them are each centered, so the *visual*
        // gap from the skip glyph's right edge to the ring's left
        // edge works out to 44 − 10 − 18 = 16pt — matching the
        // bar-edge paddings. The bodyButton/skipForwardButton
        // boundary remains a clean tap split because each control
        // has its own `.contentShape(Rectangle())`.
        HStack(spacing: 0) {
            bodyButton
            skipForwardButton
            playPauseButton
        }
        // Inner H padding: shifts the controls in by 8pt in
        // edge-to-edge mode so they match the island-mode x
        // positions (where the .padding(.horizontal, 8) below
        // creates the inset).
        //
        // Leading 16pt → avatar's left edge sits 16pt from bar's
        // left edge. Trailing 12pt + 4pt (ring-to-frame inset, half
        // the 44-36 diameter difference) → progress ring's outer
        // right edge sits 16pt from bar's right edge. Both gaps
        // match so the bar reads symmetric.
        .padding(.leading, AtlasSpacing.md + (extendsToScreenEdges ? Self.floatingSideInset : 0))
        .padding(.trailing, Self.trailingInnerInset + (extendsToScreenEdges ? Self.floatingSideInset : 0))
        .frame(height: Self.barHeight)
        .frame(maxWidth: .infinity)
        .background(AtlasColors.miniPlayerBackground)
        .padding(.horizontal, extendsToScreenEdges ? 0 : Self.floatingSideInset)
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
        // 16pt gap between avatar's right edge and the text block's
        // left edge — matches the bar-edge paddings so the body
        // half of the mini-player reads with consistent breathing
        // room on all sides.
        HStack(spacing: AtlasSpacing.md) {
            leadingIcon

            // Title sits in `body` (15pt SF Pro regular) while the
            // subtitle stays in `caption` (13pt SF Mono) — gives the
            // two lines a real type hierarchy instead of two
            // equally-weighted captions.
            VStack(alignment: .leading, spacing: 1) {
                MarqueeText(
                    text: titleText,
                    font: AtlasTypography.body,
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

    /// Circular avatar of the tour's maker. Goes through the shared
    /// `MakerAvatarView` (photo → emoji → custom initials+colour →
    /// display-name monogram) so it stays in sync with the profile /
    /// maker page. Falls back to the bundled brand asset only when no
    /// maker is loaded at all.
    private var authorIcon: some View {
        Group {
            if let maker {
                MakerAvatarView(maker: maker, size: Self.iconSize)
            } else {
                Image("AtlasStudioAvatar")
                    .resizable()
                    .scaledToFill()
                    .frame(width: Self.iconSize, height: Self.iconSize)
                    .clipShape(Circle())
            }
        }
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

    /// Title line — uppercased so the mini-player reads with the
    /// same editorial-caps voice as the drawer header. The string
    /// is uppercased at the call site (not via `.textCase(.uppercase)`
    /// on Text) because `MarqueeText` renders its own internal Text
    /// and the modifier wouldn't propagate through it.
    private var titleText: String {
        if let tour { return tour.title.uppercased() }
        return Self.idleWelcomeText.uppercased()
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
                    .font(.system(size: 20, weight: .regular))
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
