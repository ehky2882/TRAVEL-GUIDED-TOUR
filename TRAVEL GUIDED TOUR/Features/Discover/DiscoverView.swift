import SwiftUI

struct DiscoverView: View {
    @Environment(DataService.self) private var dataService
    @Environment(AudioPlayerService.self) private var audioPlayer

    // SoundHelix has hosted stable public-domain test audio for years.
    // Replaced by real tour audio once a CDN is chosen in M-launch-content.
    private let testAudioURL = URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3")

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AtlasSpacing.md) {
                    Image(systemName: "map")
                        .font(.system(size: 48))
                        .foregroundStyle(AtlasColors.secondaryText.opacity(0.4))
                    Text("Home")
                        .font(AtlasTypography.headline)
                        .foregroundStyle(AtlasColors.primaryText)
                    Text("Map-dominant home with curated rails lands in M-home.")
                        .font(AtlasTypography.standard)
                        .foregroundStyle(AtlasColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AtlasSpacing.lg)
                    Text("Loaded \(dataService.tours.count) tour(s) from Tours.json.")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.tertiaryText)
                        .padding(.top, AtlasSpacing.md)

                    tourListSection
                        .padding(.top, AtlasSpacing.lg)

                    audioFoundationTestSection
                        .padding(.top, AtlasSpacing.xl)
                }
                .padding(.vertical, AtlasSpacing.xl)
                .frame(maxWidth: .infinity)
            }
            .background(AtlasColors.background)
            .navigationTitle("Home")
            .inlineNavigationBarTitle()
        }
    }

    // Temporary M-tour-detail test entry: a tappable list of tours that
    // pushes TourDetailView. Goes away in M-home when the map+rails
    // home screen lands and provides the real navigation entry points.
    private var tourListSection: some View {
        VStack(spacing: AtlasSpacing.sm) {
            Divider().padding(.horizontal, AtlasSpacing.xl)

            Text("M-tour-detail test")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.tertiaryText)
                .padding(.top, AtlasSpacing.md)

            VStack(spacing: AtlasSpacing.sm) {
                ForEach(dataService.tours) { tour in
                    NavigationLink {
                        TourDetailView(tour: tour)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                                Text(tour.title)
                                    .font(AtlasTypography.body)
                                    .foregroundStyle(AtlasColors.primaryText)
                                Text(tour.shortDescription)
                                    .font(AtlasTypography.caption)
                                    .foregroundStyle(AtlasColors.secondaryText)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(AtlasTypography.caption)
                                .foregroundStyle(AtlasColors.tertiaryText)
                        }
                        .padding(.horizontal, AtlasSpacing.lg)
                        .padding(.vertical, AtlasSpacing.sm)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var audioFoundationTestSection: some View {
        VStack(spacing: AtlasSpacing.sm) {
            Divider().padding(.horizontal, AtlasSpacing.xl)

            Text("M-audio-foundation test")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.tertiaryText)
                .padding(.top, AtlasSpacing.md)

            Text("State: \(stateLabel)")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.secondaryText)

            if audioPlayer.duration > 0 {
                Text("\(Int(audioPlayer.currentTime))s / \(Int(audioPlayer.duration))s")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
            }

            HStack(spacing: AtlasSpacing.md) {
                Button("Load + Play") {
                    if let url = testAudioURL {
                        audioPlayer.play(url: url, title: "SoundHelix Song 1", artist: "Atlas test")
                    }
                }

                Button(audioPlayer.state == .playing ? "Pause" : "Resume") {
                    if audioPlayer.state == .playing {
                        audioPlayer.pause()
                    } else {
                        audioPlayer.play()
                    }
                }
                .disabled(audioPlayer.state == .idle || audioPlayer.state == .loading)

                Button("Stop") {
                    audioPlayer.stop()
                }
                .disabled(audioPlayer.state == .idle)
            }
            .font(AtlasTypography.standard)
            .padding(.top, AtlasSpacing.sm)

            HStack(spacing: AtlasSpacing.md) {
                Button("−15s") { audioPlayer.skip(by: -15) }
                Button("+15s") { audioPlayer.skip(by: 15) }
            }
            .font(AtlasTypography.standard)
            .disabled(audioPlayer.state != .playing && audioPlayer.state != .paused)
        }
    }

    private var stateLabel: String {
        switch audioPlayer.state {
        case .idle: return "idle"
        case .loading: return "loading…"
        case .playing: return "playing"
        case .paused: return "paused"
        case .ended: return "ended"
        }
    }
}
