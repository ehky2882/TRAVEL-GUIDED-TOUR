import SwiftUI

/// The top-right control cluster shared by the home tour cards
/// (`RailCarousel`'s rail card + the filter-results `FilterResultCard`).
/// Renders a **download** chip beside the existing **bookmark** chip —
/// the AllTrails layout (download-arrow + heart). Both chips are the
/// same 36pt circular material treatment so they read as one paired
/// unit. Extracted into one component so the two card families stay in
/// lockstep and the download wiring lives in a single place.
///
/// The chips sit inside each card's outer tap-to-open `Button`; SwiftUI
/// routes a tap to the innermost interactive view, so tapping a chip
/// fires its action while a tap anywhere else on the card opens the tour.
struct CardHeroControls: View {
    let tour: Tour

    var body: some View {
        HStack(spacing: AtlasSpacing.xs) {
            CardDownloadButton(tour: tour)
            CardBookmarkButton(tour: tour)
        }
        .padding(AtlasSpacing.sm)
    }
}

/// The bookmark chip — identical behaviour to the inline button the
/// cards used to carry, now shared so it always matches the download
/// chip's size/treatment.
private struct CardBookmarkButton: View {
    let tour: Tour
    @Environment(LibraryStore.self) private var libraryStore

    var body: some View {
        Button {
            libraryStore.toggleSaved(tour.id)
        } label: {
            Image(systemName: libraryStore.isSaved(tour.id) ? "bookmark.fill" : "bookmark")
                .font(AtlasTypography.body)
                .foregroundStyle(AtlasColors.primaryText)
                .frame(width: CardHeroControlMetrics.diameter, height: CardHeroControlMetrics.diameter)
                .background(.regularMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(libraryStore.isSaved(tour.id) ? "Saved" : "Save tour")
    }
}

/// State-aware download chip. Mirrors the tour-detail download control's
/// four faces and tap semantics exactly (offline availability, re-tap to
/// cancel / delete), just sized to match the bookmark chip:
///   - idle        → down-arrow, taps to start a download
///   - downloading → progress ring around a stop icon, taps to cancel
///   - completed   → green checkmark, taps to remove the download
///   - failed      → warning icon, taps to retry
/// The single-active-download rule (`TourDownloader.activeTourId`) gates
/// starting *other* tours, so the chip disables while another tour is in
/// flight — same as the detail button.
private struct CardDownloadButton: View {
    let tour: Tour

    @Environment(TourDownloader.self) private var tourDownloader
    @Environment(LibraryStore.self) private var libraryStore

    var body: some View {
        let state = tourDownloader.states[tour.id] ?? .idle
        let isOtherActive = tourDownloader.activeTourId != nil
            && tourDownloader.activeTourId != tour.id

        Button(action: handleTap) {
            icon(for: state)
                .font(AtlasTypography.body)
                .foregroundStyle(AtlasColors.primaryText)
                .frame(width: CardHeroControlMetrics.diameter, height: CardHeroControlMetrics.diameter)
                .background(.regularMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(isOtherActive)
        .accessibilityLabel(isOtherActive ? "Download unavailable" : accessibilityLabel(for: state))
        .accessibilityHint(isOtherActive ? "Wait for the current download to finish, then try again." : "")
        // Keep the Library → Downloaded section in sync exactly as the
        // detail view does: mark on completion, clear if a removal /
        // failure resets the state. Best-effort while this card is on
        // screen (the tour the user just tapped Download on always is).
        .onChange(of: tourDownloader.states[tour.id]) { _, newState in
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

    @ViewBuilder
    private func icon(for state: TourDownloader.DownloadState) -> some View {
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
                    .frame(width: 22, height: 22)
                    .animation(.linear(duration: 0.25), value: progress)
            }
        case .completed:
            // Green = "success/done", matching the tour-detail download
            // control (the one deliberate hardcoded color there).
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
    }

    private func accessibilityLabel(for state: TourDownloader.DownloadState) -> String {
        switch state {
        case .idle: return "Download tour"
        case .downloading: return "Cancel download"
        case .completed: return "Downloaded. Remove download"
        case .failed: return "Retry download"
        }
    }

    private func handleTap() {
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
}

enum CardHeroControlMetrics {
    /// 36pt circular chip — the size the card bookmark has always used;
    /// the download chip matches it so the pair reads as one unit.
    static let diameter: CGFloat = 36
}
