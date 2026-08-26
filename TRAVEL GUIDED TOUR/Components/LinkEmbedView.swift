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

    /// Called with `true` while the platform's own control has the player in
    /// element fullscreen, `false` the moment it leaves — **or the moment this
    /// view is torn down while still fullscreen**, which is the case that
    /// matters. See `Coordinator.restoreIfNeeded`.
    var onFullscreenChange: @MainActor (Bool) -> Void = { _ in }

    /// Does this state mean the bottom module has to be withdrawn?
    ///
    /// Pure and static so the rule is testable without a live `WKWebView` —
    /// the same treatment `BottomModuleRoot.extendsToScreenEdges` and
    /// `BottomModuleWindowController.installOutcome` get.
    ///
    /// ⚠️ `.enteringFullscreen` counts as fullscreen and `.exitingFullscreen`
    /// does not, deliberately. The module must be gone *before* the player has
    /// finished growing and may only come back once it has finished shrinking;
    /// reading the two transitional states the other way round leaves the bars
    /// painted over the first and last frames of the animation, which is this
    /// bug in miniature.
    ///
    /// 🔴 An unrecognised future state resolves to `false` — "show the bars".
    /// The two failure directions are not equal: painting the bars over a
    /// fullscreen video is the defect being fixed here, while failing to bring
    /// them back costs the tab bar and the mini-player for the rest of the
    /// session with no way to get them back.
    static func withdrawsBottomModule(for state: WKWebView.FullscreenState) -> Bool {
        switch state {
        case .enteringFullscreen, .inFullscreen:
            return true
        case .exitingFullscreen, .notInFullscreen:
            return false
        @unknown default:
            return false
        }
    }

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
        context.coordinator.observeFullscreen(on: web)
        web.loadHTMLString(Self.shell(embedURL), baseURL: Self.embedOrigin)
        return web
    }

    func updateUIView(_ web: WKWebView, context: Context) {
        // Every re-render builds a fresh closure; the coordinator was made
        // once. Handing the new one over keeps the two from drifting if this
        // view is ever re-parented under a different owner.
        context.coordinator.onFullscreenChange = onFullscreenChange
        // Reload only when the pin actually changed. A plain `load` here would
        // restart the video on every parent re-render — and the tour page
        // re-renders constantly while audio elsewhere is playing.
        guard context.coordinator.loadedURL != embedURL else { return }
        context.coordinator.loadedURL = embedURL
        web.loadHTMLString(Self.shell(embedURL), baseURL: Self.embedOrigin)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(loadedURL: embedURL, onFullscreenChange: onFullscreenChange)
    }

    /// 🔴 THE TEARDOWN RESTORE, and the reason it lives here rather than only
    /// on whichever view hid the module: this is SwiftUI's own hook for the
    /// representable going away, so it runs on the paths a `.onDisappear`
    /// higher up can miss — the tour layer collapsing under a tab tap, the
    /// page being dismissed, the whole layer being torn down mid-fullscreen.
    /// `Coordinator.deinit` is the third belt behind it.
    static func dismantleUIView(_ web: WKWebView, coordinator: Coordinator) {
        coordinator.restoreIfNeeded()
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var loadedURL: URL?
        /// Refreshed on every `updateUIView`, so a stale closure can never be
        /// the thing holding the bars hostage.
        ///
        /// `@MainActor` because it drives `UIWindow.isHidden` and an
        /// `@MainActor @Observable` flag; `deliver` is the only thing that
        /// calls it, and it does so from the main queue by construction.
        var onFullscreenChange: @MainActor (Bool) -> Void
        private var fullscreenObservation: NSKeyValueObservation?
        /// What we last reported. Every restore path reads it, so a teardown
        /// that happens outside fullscreen costs nothing at all.
        private var isFullscreen = false

        init(loadedURL: URL?,
             onFullscreenChange: @escaping @MainActor (Bool) -> Void) {
            self.loadedURL = loadedURL
            self.onFullscreenChange = onFullscreenChange
        }

        /// 🔴 `fullscreenState` (iOS 16+, KVO-observable) is the ONLY signal we
        /// get. The fullscreen control lives inside a **cross-origin iframe**,
        /// so nothing about the tap reaches us — not a navigation, not a script
        /// message, and we may not inject script into it. WebKit changing this
        /// property is the entire event.
        func observeFullscreen(on web: WKWebView) {
            fullscreenObservation = web.observe(\.fullscreenState,
                                                options: [.new]) { [weak self] web, _ in
                self?.report(web.fullscreenState)
            }
        }

        /// The one way the callback is ever invoked.
        ///
        /// ⚠️ `DispatchQueue.main.async` rather than `Task { @MainActor in }`,
        /// and that is not a style choice: main-queue blocks run strictly
        /// FIFO, while the order two `Task`s reach the main actor in is not
        /// guaranteed. The ordering of a hide against the restore that follows
        /// it is the one thing here that must never be reordered — a restore
        /// overtaking its own hide would leave the bars withdrawn for the rest
        /// of the session, which is the failure this whole file guards
        /// against. Dispatching unconditionally (rather than calling straight
        /// through when already on main) is what keeps that queue the single
        /// ordering authority; the cost is one runloop turn, which is not
        /// visible against a fullscreen transition.
        ///
        /// `assumeIsolated` is safe by construction here: we are inside a
        /// block the main queue just ran.
        private func deliver(_ fullscreen: Bool) {
            let callback = onFullscreenChange
            DispatchQueue.main.async {
                MainActor.assumeIsolated { callback(fullscreen) }
            }
        }

        private func report(_ state: WKWebView.FullscreenState) {
            let withdraw = LinkEmbedView.withdrawsBottomModule(for: state)
            guard withdraw != isFullscreen else { return }
            isFullscreen = withdraw
            deliver(withdraw)
        }

        /// Put the module back if we are the reason it is gone. Idempotent,
        /// and safe to call from anywhere at any time.
        func restoreIfNeeded() {
            guard isFullscreen else { return }
            isFullscreen = false
            deliver(false)
        }

        /// 🔴 The last line of defence, and the only one ARC guarantees: this
        /// runs whenever the webview is released, however that happened —
        /// including paths where neither `dismantleUIView` nor an
        /// `.onDisappear` higher up ever fires.
        ///
        /// Inlined rather than calling `deliver`, because a deinit may not
        /// escape `self` and `deliver` is an instance method. `restoreIfNeeded`
        /// clears the flag, so a teardown that already restored skips here.
        deinit {
            guard isFullscreen else { return }
            let callback = onFullscreenChange
            DispatchQueue.main.async {
                MainActor.assumeIsolated { callback(false) }
            }
        }

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
