import SwiftUI

/// Persistent now-playing bar shown above the tab bar whenever audio
/// is loaded. Lets the user pause/resume and jump back to the full
/// player from anywhere in the app — without it, returning to the
/// player means navigating back to the tour and reopening it.
///
/// Hosted by `ContentView` between the tab content and `AtlasTabBar`,
/// matching the floating-island inset so it reads as part of the same
/// bottom UI region. Tapping the bar body (anywhere but the
/// play/pause button) opens the full `PlayerView`.
struct MiniPlayerBar: View {
    let tour: Tour
    let maker: Maker?
    /// Invoked when the user taps the bar body — opens the full player.
    var onExpand: () -> Void

    @Environment(AudioPlayerService.self) private var audioPlayer

    /// Bar content height.
    static let barHeight: CGFloat = 54
    /// Gap between the bar and the tab bar below it.
    static let topGap: CGFloat = 8
    /// Horizontal inset — matches the drawer / tab-bar island inset.
    static let sideInset: CGFloat = 8
    /// Total vertical space the bar occupies, including its top gap.
    /// `HomeView` adds this to its drawer peek height so the drawer's
    /// peek content clears the bar.
    static var layoutHeight: CGFloat { barHeight + topGap }

    var body: some View {
        // The bar body and the play/pause control are sibling buttons,
        // not nested — nested SwiftUI Buttons swallow each other's
        // taps unreliably.
        HStack(spacing: AtlasSpacing.sm) {
            Button(action: onExpand) {
                HStack(spacing: AtlasSpacing.sm) {
                    HeroImageView(
                        imageName: tour.heroImageURL,
                        height: 40,
                        cornerRadius: 8,
                        category: tour.primaryCategory
                    )
                    .frame(width: 40)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(tour.title)
                            .font(AtlasTypography.body)
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
        .padding(.leading, AtlasSpacing.sm)
        .padding(.trailing, AtlasSpacing.xs)
        .frame(height: Self.barHeight)
        .frame(maxWidth: .infinity)
        .background(AtlasColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, Self.sideInset)
        .padding(.top, Self.topGap)
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
                .font(.system(size: 26))
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
