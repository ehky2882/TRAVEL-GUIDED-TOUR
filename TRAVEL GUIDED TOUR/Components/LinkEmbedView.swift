import SwiftUI
import WebKit

/// The post itself, playing inside Atlas.
///
/// A link pin stands for someone else's TikTok, Reel or Short. This renders
/// that platform's **own** embedded player, so the viewer watches without
/// being thrown out to another app — the thing the owner asked for
/// (2026-08-24) and what Albo does with its share-sheet saves.
///
/// 🔴 THIS IS AN EMBED, NOT A COPY. The bytes stream from TikTok/Meta/Google
/// and are never fetched, stored or re-served by us. That is the whole reason
/// it is allowed: all three publish a player that needs **no API key, no
/// registration and no app review** (verified live 2026-08-24 —
/// `tiktok.com/player/v1/{id}` answered HTTP 200 unauthenticated). Obtaining
/// the video file instead would breach their terms, and TikTok's API exposes
/// no such field in any case.
///
/// ⚠️ WHAT AN EMBED CANNOT DO, and it is most of what Atlas is for: it needs a
/// live network, needs the screen on, cannot be downloaded, cannot join a
/// Group Listen and cannot fire at a geofence. A link pin is something people
/// *look at*; a tour is something that plays while they walk. Keeping the two
/// distinguishable is why `TourKind.link` exists.
struct LinkEmbedView: UIViewRepresentable {
    let embedURL: URL

    /// ⚠️ Both of these are required for the player to work at all inside an
    /// app. Without `allowsInlineMediaPlayback` iOS hands playback to the
    /// fullscreen system player, which defeats the point; without clearing
    /// `mediaTypesRequiringUserActionForPlayback` the platform's own play
    /// button cannot start anything.
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let web = WKWebView(frame: .zero, configuration: config)
        web.navigationDelegate = context.coordinator
        web.scrollView.isScrollEnabled = false
        web.scrollView.bounces = false
        // The page is letterboxed on black by the player itself; a white flash
        // while it loads reads as a broken view on a dark tour page.
        web.isOpaque = false
        web.backgroundColor = .black
        web.scrollView.backgroundColor = .black
        web.load(URLRequest(url: embedURL))
        return web
    }

    func updateUIView(_ web: WKWebView, context: Context) {
        // Reload only when the pin actually changed. A plain `load` here would
        // restart the video on every parent re-render — and the tour page
        // re-renders constantly while audio elsewhere is playing.
        guard context.coordinator.loadedURL != embedURL else { return }
        context.coordinator.loadedURL = embedURL
        web.load(URLRequest(url: embedURL))
    }

    func makeCoordinator() -> Coordinator { Coordinator(loadedURL: embedURL) }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var loadedURL: URL?
        init(loadedURL: URL?) { self.loadedURL = loadedURL }

        /// Keep navigation inside the embed. A tap on the creator's handle or
        /// the sound name inside the player is a link out — it should open the
        /// real app rather than replacing the player with a login wall, which
        /// is what happens if a webview follows it.
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard navigationAction.navigationType == .linkActivated,
                  let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }
            decisionHandler(.cancel)
            UIApplication.shared.open(url)
        }
    }
}
