import SwiftUI

/// Whether a link pin's embedded player has come up.
///
/// 🔴 THE WHOLE POINT IS THAT THERE IS NO NEGATIVE SIGNAL TO WAIT FOR. The
/// player lives in a **cross-origin iframe** inside a page we load with
/// `loadHTMLString`, so the main frame never touches the network and
/// `WKNavigationDelegate`'s failure callbacks cannot fire for it — that is why
/// `LinkEmbedView` had a `navigationDelegate` and still rendered a black
/// rectangle forever when TikTok was unreachable. Failure here is therefore
/// inferred from the **absence of a positive signal** within a deadline, not
/// reported by WebKit.
enum LinkEmbedLoadState: Equatable {
    /// The shell has been handed to WebKit and the deadline is running.
    case loading
    /// The iframe fired `load`. Whatever is in it — the video, or the
    /// platform's own "this post is unavailable" page — is the platform
    /// speaking for itself, and we get out of its way.
    case loaded
    /// The deadline passed with nothing, or WebKit told us the load died.
    case failed
}

/// What moved.
enum LinkEmbedLoadEvent: Equatable {
    /// A shell was (re)loaded — a first render, a new pin, or a retry.
    case loadStarted
    /// The iframe's own `load` event, relayed by the shell's script.
    case frameLoaded
    /// The iframe's own `error` event, relayed by the shell's script.
    /// ⚠️ Not the main detector: browsers fire `error` on an `<iframe>`
    /// inconsistently, and WebKit usually fires nothing at all for a subframe
    /// whose provisional load failed. The deadline is what actually catches a
    /// blocked host; this is a bonus when it happens to arrive.
    case frameError
    /// The deadline expired.
    case deadlineExpired
    /// The **main frame** failed, which given `loadHTMLString` means something
    /// far more basic than a blocked platform went wrong.
    case mainFrameFailed
}

enum LinkEmbedLoadRule {

    /// How long to wait for the iframe before calling it dead.
    ///
    /// ⚠️ Chosen for the failure it must not cause. A blocked host usually
    /// fails in under a second (the connection is reset), so any deadline
    /// catches that; the risk is the other direction — a slow-but-working
    /// network taking longer than this and being told, wrongly, that the
    /// platform is unreachable. Twelve seconds is well past a normal player
    /// handshake, and `nextState` makes a late arrival recoverable anyway, so
    /// being wrong here costs a message that then disappears rather than a
    /// video the viewer can no longer get to.
    static let deadline: TimeInterval = 12

    /// The complete transition table.
    ///
    /// 🔴 `.frameLoaded` wins from **every** state, `.failed` included. That is
    /// what makes the deadline safe to be wrong about: the fallback is an
    /// overlay above a player that is still mounted and still loading, so a
    /// player that arrives at second fourteen simply takes the message away.
    /// Tearing the player down to show the message instead would make the
    /// timeout unrecoverable and the choice of deadline load-bearing.
    ///
    /// 🔴 `.deadlineExpired` is ignored unless we are still `.loading`. A
    /// deadline from a previous load that outlived its cancellation must never
    /// be able to knock out a player that has since come up.
    static func nextState(_ current: LinkEmbedLoadState,
                         on event: LinkEmbedLoadEvent) -> LinkEmbedLoadState {
        switch event {
        case .loadStarted:
            return .loading
        case .frameLoaded:
            return .loaded
        case .frameError, .mainFrameFailed:
            return .failed
        case .deadlineExpired:
            return current == .loading ? .failed : current
        }
    }
}

/// The message shown over a player that never came up.
///
/// ⚠️ **Light-on-dark unconditionally, and that is a deliberate exception to
/// the design-token rule.** The box underneath is `black` in both appearances
/// — `LinkEmbedView` paints it that way so the platform's letterboxing does
/// not flash white — so `AtlasColors.primaryText` (`Color.primary`) would be
/// near-black text on a black panel in light mode, i.e. invisible exactly
/// where the whole point is to be read.
struct LinkEmbedFallbackView: View {
    let source: LinkSource
    /// Mount the shell again. The player is never torn down, so this is a
    /// retry of the load and not a rebuild of the page.
    let retry: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.92)

            VStack(spacing: AtlasSpacing.sm) {
                Image(systemName: "wifi.slash")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.55))

                Text(source.unreachableHeadline)
                    .font(AtlasTypography.body)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(source.unreachableDetail)
                    .font(AtlasTypography.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(5)
                    .minimumScaleFactor(0.7)

                Button(action: retry) {
                    Text("TRY AGAIN")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.brass)
                        .padding(.horizontal, AtlasSpacing.md)
                        .padding(.vertical, AtlasSpacing.sm)
                        .overlay(
                            RoundedRectangle(cornerRadius: AtlasSpacing.sm)
                                .stroke(AtlasColors.brass.opacity(0.7), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, AtlasSpacing.xs)
            }
            .padding(AtlasSpacing.md)
        }
        // The action row below this box still offers "OPEN IN TIKTOK", and on a
        // network that blocks TikTok that will fail too — but it is the one
        // route that works the moment the viewer is somewhere else, so it is
        // left exactly where it was rather than hidden here.
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("\(source.unreachableHeadline). \(source.unreachableDetail)"))
    }
}
