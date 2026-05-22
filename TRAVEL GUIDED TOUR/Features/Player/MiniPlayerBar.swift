import SwiftUI

/// Persistent now-playing bar shown directly above the tab bar.
/// **Always present** — when a tour's audio is loaded it shows the
/// active tour with inline pause/resume and tap-to-open-player; when
/// nothing is playing it shows a muted placeholder so the bottom
/// island keeps a constant height.
///
/// Hosted by `ContentView` between the tab content and `AtlasTabBar`.
/// The bar is a plain rectangle with square corners; it stacks flush
/// on top of the tab bar (whose top corners are also square), so the
/// two read as one shape — square at the top, phone-rounded at the
/// bottom. Tapping the bar body (anywhere but the play/pause button)
/// opens the full `PlayerView`.
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
    /// Horizontal inset — matches the tab bar's inset so the bar and
    /// tab bar stack into one flush, equal-width island.
    static let sideInset: CGFloat = 8
    /// Total vertical space the bar occupies, including its top gap.
    /// `HomeView` adds this to its drawer peek height, and
    /// `TourDetailView` to its action-bar inset, so their content
    /// clears the bar.
    static var layoutHeight: CGFloat { barHeight + topGap }

    /// Diameter of the circular leading icon (author avatar / idle
    /// placeholder).
    private static let iconSize: CGFloat = 32

    var body: some View {
        Group {
            if let tour {
                activeBar(tour: tour)
            } else {
                idleBar
            }
        }
        .frame(height: Self.barHeight)
        .frame(maxWidth: .infinity)
        .background(AtlasColors.secondaryBackground)
        .padding(.horizontal, Self.sideInset)
        .padding(.top, Self.topGap)
    }

    // MARK: - Idle state

    /// Shown when no tour is loaded. Structurally identical to the
    /// active bar — same icon slot, same two text lines — so nothing
    /// shifts position when playback starts. The lines just read " - ".
    private var idleBar: some View {
        HStack(spacing: AtlasSpacing.sm) {
            idleIcon

            VStack(alignment: .leading, spacing: 1) {
                Text(" - ")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.primaryText)
                    .lineLimit(1)
                Text(" - ")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.leading, AtlasSpacing.lg)
        .padding(.trailing, AtlasSpacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Nothing playing")
    }

    /// Circular muted placeholder — the headphones glyph in the same
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

    // MARK: - Active state

    private func activeBar(tour: Tour) -> some View {
        // The bar body and the play/pause control are sibling buttons,
        // not nested — nested SwiftUI Buttons swallow each other's
        // taps unreliably.
        HStack(spacing: AtlasSpacing.sm) {
            Button(action: onExpand) {
                HStack(spacing: AtlasSpacing.sm) {
                    authorIcon

                    VStack(alignment: .leading, spacing: 1) {
                        // Title and subtitle share a type size — they're
                        // distinguished only by tint (primary vs.
                        // secondary).
                        Text(tour.title)
                            .font(AtlasTypography.caption)
                            .foregroundStyle(AtlasColors.primaryText)
                            .lineLimit(1)
                        Text(subtitle)
                            .font(AtlasTypography.caption)
                            .foregroundStyle(AtlasColors.secondaryText)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Now playing: \(tour.title)")
            .accessibilityHint("Opens the full player.")

            playPauseButton
        }
        .padding(.leading, AtlasSpacing.lg)
        .padding(.trailing, AtlasSpacing.md)
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

    private var subtitle: String {
        switch audioPlayer.state {
        case .loading:
            return "Loading…"
        case .failed:
            return "Tap to retry"
        case .paused:
            if let maker { return "Paused · \(maker.displayName)" }
            return "Paused"
        case .idle, .playing, .ended:
            return maker?.displayName ?? ""
        }
    }

    private var playPauseButton: some View {
        Button(action: togglePlayPause) {
            Image(systemName: playPauseIcon)
                .font(.system(size: 24))
                .foregroundStyle(AtlasColors.primaryText)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(audioPlayer.state == .playing ? "Pause" : "Play")
    }

    private var playPauseIcon: String {
        switch audioPlayer.state {
        case .playing:               return "pause.fill"
        case .loading:               return "hourglass"
        case .failed:                return "arrow.clockwise"
        case .idle, .paused, .ended: return "play.fill"
        }
    }

    private func togglePlayPause() {
        switch audioPlayer.state {
        case .playing:
            audioPlayer.pause()
        case .paused:
            audioPlayer.play()
        case .loading, .failed, .ended, .idle:
            // No clean in-place resume — hand off to the full player,
            // which owns stop/intro sequencing and the retry path.
            onExpand()
        }
    }
}
