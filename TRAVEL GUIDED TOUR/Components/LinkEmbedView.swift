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

    /// 🔴 The embed is hosted in an iframe under a **real origin** rather than
    /// loaded directly. `web.load(URLRequest(url: embedURL))` gives the player
    /// no referrer and an opaque parent origin; TikTok tolerates that, YouTube
    /// refuses it outright with **"Error 153 — video player configuration
    /// error"** and plays nothing. Verified both ways in the simulator.
    static func shell(_ embed: URL) -> String {
        """
        <!DOCTYPE html><html><head>
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
        <style>html,body{margin:0;padding:0;background:#000;height:100%;overflow:hidden}
        iframe{border:0;width:100%;height:100%;display:block}</style>
        </head><body>
        <iframe src="\(htmlAttributeEscaped(embed.absoluteString))"
                allow="autoplay; encrypted-media; picture-in-picture; fullscreen"
                allowfullscreen playsinline></iframe>
        </body></html>
        """
    }

    /// ⚠️ The embed URL is now interpolated into an **HTML attribute**, which it
    /// never was before this shell existed. `LinkSource.embedURL` only ever
    /// builds URLs from validated ids, so nothing hostile reaches here today —
    /// but escaping at the boundary is cheaper than proving every future
    /// derivation safe, and this file has already paid once for a URL that
    /// looked trustworthy (`tiktok.evil.com`).
    ///
    /// `&` is replaced first, or the escapes introduced after it get
    /// double-escaped into visible `&amp;quot;`.
    static func htmlAttributeEscaped(_ raw: String) -> String {
        raw.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    /// The origin the iframe's parent reports. Any real https origin we control
    /// satisfies the platforms' referrer checks.
    static let embedOrigin = URL(string: "https://dozent.world")

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
        web.loadHTMLString(Self.shell(embedURL), baseURL: Self.embedOrigin)
        return web
    }

    func updateUIView(_ web: WKWebView, context: Context) {
        // Reload only when the pin actually changed. A plain `load` here would
        // restart the video on every parent re-render — and the tour page
        // re-renders constantly while audio elsewhere is playing.
        guard context.coordinator.loadedURL != embedURL else { return }
        context.coordinator.loadedURL = embedURL
        web.loadHTMLString(Self.shell(embedURL), baseURL: Self.embedOrigin)
    }

    func makeCoordinator() -> Coordinator { Coordinator(loadedURL: embedURL) }

    /// 🔴 A TAP ON THE VIDEO IS A LINK, AND SENDING IT OUT LAUNCHES THE OTHER APP.
    ///
    /// Instagram's embed wraps the media itself in an anchor —
    /// `<a class="EmbeddedMedia" href="instagram.com/reel/CODE/…">` — so
    /// pressing play arrives here as `.linkActivated` even though the player's
    /// own JS also handles it. Opening that externally launches the Instagram
    /// app, which is precisely the thing link pins exist to avoid.
    ///
    /// ⚠️ THIS DOES NOT REPRODUCE IN THE SIMULATOR. With no Instagram app
    /// installed, `UIApplication.open` silently does nothing and the JS play
    /// runs, so the embed looks perfect. It only fails on a real phone, which
    /// is where the owner found it.
    ///
    /// So: a link pointing back at the post we are already showing is
    /// swallowed — cancelled and NOT opened — leaving the tap to the player.
    /// Anything genuinely outbound (the creator's profile, their stories, the
    /// sound) still opens the real app, which is what a viewer wants there.
    static func shouldOpenExternally(_ target: URL, embedURL: URL) -> Bool {
        guard let t = URLComponents(url: target, resolvingAgainstBaseURL: false),
              let e = URLComponents(url: embedURL, resolvingAgainstBaseURL: false)
        else { return true }
        guard t.host?.lowercased() == e.host?.lowercased() else { return true }

        // The embed lives one path component below the post
        // (…/reel/CODE/embed), so compare against the post's own path.
        func normalised(_ path: String) -> String {
            var p = path
            if p.hasSuffix("/") { p.removeLast() }
            if p.hasSuffix("/embed") { p.removeLast("/embed".count) }
            return p.lowercased()
        }
        return normalised(t.path) != normalised(e.path)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var loadedURL: URL?
        let embedURL: URL
        init(loadedURL: URL?) {
            self.loadedURL = loadedURL
            self.embedURL = loadedURL ?? URL(string: "https://invalid.invalid")!
        }

        /// Keep navigation inside the embed. A tap on the creator's handle is a
        /// link out — it should open the real app rather than replacing the
        /// player with a login wall. A tap on the video is not.
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard navigationAction.navigationType == .linkActivated,
                  let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }
            decisionHandler(.cancel)
            // Swallowed rather than opened: the player handles this tap.
            guard LinkEmbedView.shouldOpenExternally(url, embedURL: embedURL) else { return }
            UIApplication.shared.open(url)
        }
    }
}
