import SwiftUI
import UIKit
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

    /// Bump to load the shell again without rebuilding the view.
    ///
    /// ⚠️ A retry must not be a teardown. `LinkEmbedFallbackView` sits as an
    /// **overlay** above a player that is still mounted, so the player keeps
    /// whatever progress it had and a late success still lands. Recreating the
    /// `WKWebView` to retry would throw that away and make the deadline in
    /// `LinkEmbedLoadRule` a one-shot verdict rather than a guess that can be
    /// corrected.
    var reloadToken: Int = 0


    /// Called with `true` while the platform's own control has the player in
    /// element fullscreen, `false` the moment it leaves — **or the moment this
    /// view is torn down while still fullscreen**, which is the case that
    /// matters. See `Coordinator.restoreIfNeeded`.
    var onFullscreenChange: @MainActor (Bool) -> Void = { _ in }

    /// Every load signal, raw. The **rule** lives in `LinkEmbedLoadRule` and
    /// the **state** lives with the owning view, deliberately: this type sees
    /// one webview at a time and has no business deciding what a signal means
    /// or remembering what the last one was.
    ///
    /// ⚠️ Declared after `onFullscreenChange`, and that ordering is load-
    /// bearing: this struct has no explicit initialiser, so the memberwise one
    /// takes its arguments in declaration order and a swap here is a compile
    /// error at every call site.
    var onLoadEvent: @MainActor (LinkEmbedLoadEvent) -> Void = { _ in }

    /// Is a newly-visible `UIWindow` the platform player going fullscreen?
    ///
    /// 🔴 THE SIGNAL `fullscreenState` NEVER GAVE US. Proved on device by the
    /// probe builds: with a YouTube pin fullscreen and the bars on top of it,
    /// the trace showed no KVO at all — not with element fullscreen off, and
    /// not with it on. WebKit is not taking the element-fullscreen route here.
    /// What it does instead is put the video in its OWN `UIWindow`, and that
    /// window's level is at or below `.normal + 1`, which is where
    /// `BottomModuleWindowController` puts ours — so ours paints over it.
    ///
    /// ⚠️ EXCLUDING OUR OWN WINDOW IS LOAD-BEARING, not tidiness. Hiding the
    /// module makes its window post `didBecomeHidden`; if that fed back in as
    /// "left fullscreen" it would restore the bars immediately, and the hide
    /// would undo itself forever.
    ///
    /// ⚠️ The keyboard also gets a full-size window of its own. Typing in the
    /// search field would otherwise read as a video going fullscreen.
    static func isVideoFullscreenWindow(
        className: String,
        isOurModuleWindow: Bool,
        size: CGSize,
        screen: CGSize
    ) -> Bool {
        guard !isOurModuleWindow else { return false }
        guard !className.contains("Keyboard"), !className.contains("TextEffects") else { return false }
        guard screen.width > 0, screen.height > 0 else { return false }
        return size.width >= screen.width * 0.9 && size.height >= screen.height * 0.9
    }

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
        <iframe id="p" src="\(htmlAttributeEscaped(embed.absoluteString))"
                allow="autoplay; encrypted-media; picture-in-picture; fullscreen"
                allowfullscreen playsinline></iframe>
        <script>
        (function(){
          var f=document.getElementById('p');
          function say(m){try{window.webkit.messageHandlers.\(messageHandlerName).postMessage(m);}catch(e){}}
          f.addEventListener('load',function(){say('loaded');});
          f.addEventListener('error',function(){say('error');});
        })();
        </script>
        </body></html>
        """
    }

    /// 🔴 THE ONLY POSITIVE SIGNAL WE GET, and it comes from our own shell
    /// rather than from WebKit. The player is cross-origin, so we may not
    /// script into it — but the `<iframe>` element is ours, and its `load`
    /// event fires for a cross-origin child even though its contents stay
    /// unreadable. That one bit is the difference between "the player came up"
    /// and the black rectangle this file used to render forever.
    static let messageHandlerName = "atlasEmbed"

    /// Map a relayed message to an event. Pure, so the wiring is testable
    /// without a live `WKWebView`.
    ///
    /// ⚠️ An unrecognised body is **not** a failure. This channel is reachable
    /// only from our own shell, but treating anything unexpected as "dead"
    /// would let a future message we add here blank out a working player.
    static func loadEvent(forMessageBody body: Any) -> LinkEmbedLoadEvent? {
        switch body as? String {
        case "loaded": return .frameLoaded
        case "error": return .frameError
        default: return nil
        }
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
        // ⚠️ THIS DID NOT FIX THE BUG, AND THE COMMENT SAYS SO ON PURPOSE. It
        // defaults to false on iOS, and enabling it was build 1.1 (132)'s
        // theory: that with it off the iframe's `requestFullscreen()` could not
        // reach WebKit, so `fullscreenState` never moved. Enabling it changed
        // nothing — the probe trace on 132 was still empty, with no KVO at all.
        // TikTok and YouTube simply do not take that route here; the window
        // observation below is what actually fires.
        //
        // It is kept because it is the configuration the owner verified on
        // device in 1.1 (133), and removing it now would ship a combination
        // nobody has run. If a future platform DOES use element fullscreen,
        // this is what lets the KVO see it. Do not read it as the fix.
        config.preferences.isElementFullscreenEnabled = true

        // ⚠️ Registered on the configuration BEFORE the webview is built. The
        // configuration is copied at init, so a handler added afterwards via a
        // local `config` reference would be attached to an object the webview
        // is not using.
        config.userContentController.add(context.coordinator, name: Self.messageHandlerName)

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
        context.coordinator.beginLoad(web, url: embedURL)
        return web
    }

    func updateUIView(_ web: WKWebView, context: Context) {
        // Every re-render builds a fresh closure; the coordinator was made
        // once. Handing the new one over keeps the two from drifting if this
        // view is ever re-parented under a different owner.
        context.coordinator.onFullscreenChange = onFullscreenChange
        context.coordinator.onLoadEvent = onLoadEvent
        // Reload only when the pin actually changed, or a retry asked for it. A
        // plain `load` here would restart the video on every parent re-render —
        // and the tour page re-renders constantly while audio elsewhere is
        // playing, which now includes every load event this view reports.
        guard context.coordinator.loadedURL != embedURL
                || context.coordinator.loadedToken != reloadToken else { return }
        context.coordinator.loadedToken = reloadToken
        context.coordinator.beginLoad(web, url: embedURL)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(loadedURL: embedURL,
                    loadedToken: reloadToken,
                    onFullscreenChange: onFullscreenChange,
                    onLoadEvent: onLoadEvent)
    }

    /// 🔴 THE TEARDOWN RESTORE, and the reason it lives here rather than only
    /// on whichever view hid the module: this is SwiftUI's own hook for the
    /// representable going away, so it runs on the paths a `.onDisappear`
    /// higher up can miss — the tour layer collapsing under a tab tap, the
    /// page being dismissed, the whole layer being torn down mid-fullscreen.
    /// `Coordinator.deinit` is the third belt behind it.
    static func dismantleUIView(_ web: WKWebView, coordinator: Coordinator) {
        coordinator.restoreIfNeeded()
        coordinator.cancelDeadline()
        // The user content controller outlives this view inside the webview's
        // copied configuration; a handler left registered on it keeps the
        // coordinator alive with a page that is gone.
        web.configuration.userContentController
            .removeScriptMessageHandler(forName: messageHandlerName)
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var loadedURL: URL?
        /// The retry counter this coordinator has already acted on.
        var loadedToken: Int
        /// Fires `LinkEmbedLoadEvent.deadlineExpired` if the iframe has not
        /// reported in. Cancelled by a success and by a new load, so a stale
        /// one cannot outlive the load it was measuring.
        private var deadline: DispatchWorkItem?
        /// Refreshed on every `updateUIView`, so a stale closure can never be
        /// the thing holding the bars hostage.
        ///
        /// `@MainActor` because it drives `UIWindow.isHidden` and an
        /// `@MainActor @Observable` flag; `deliver` is the only thing that
        /// calls it, and it does so from the main queue by construction.
        var onFullscreenChange: @MainActor (Bool) -> Void
        /// Refreshed on every `updateUIView`, same reason as the one above.
        var onLoadEvent: @MainActor (LinkEmbedLoadEvent) -> Void
        private var fullscreenObservation: NSKeyValueObservation?
        /// Observers for the window route. Removed in `deinit` — a leaked one
        /// would keep reporting for a page that is long gone.
        fileprivate var windowObservers: [NSObjectProtocol] = []
        /// What we last reported. Every restore path reads it, so a teardown
        /// that happens outside fullscreen costs nothing at all.
        private var isFullscreen = false

        init(loadedURL: URL?,
             loadedToken: Int,
             onFullscreenChange: @escaping @MainActor (Bool) -> Void,
             onLoadEvent: @escaping @MainActor (LinkEmbedLoadEvent) -> Void) {
            self.loadedURL = loadedURL
            self.loadedToken = loadedToken
            self.onFullscreenChange = onFullscreenChange
            self.onLoadEvent = onLoadEvent
        }

        // MARK: - Load reporting

        /// Load the shell and start the clock.
        func beginLoad(_ web: WKWebView, url: URL) {
            loadedURL = url
            reportLoad(.loadStarted)
            cancelDeadline()
            let work = DispatchWorkItem { [weak self] in
                MainActor.assumeIsolated { self?.onLoadEvent(.deadlineExpired) }
            }
            deadline = work
            DispatchQueue.main.asyncAfter(deadline: .now() + LinkEmbedLoadRule.deadline,
                                          execute: work)
            web.loadHTMLString(LinkEmbedView.shell(url), baseURL: LinkEmbedView.embedOrigin)
        }

        func cancelDeadline() {
            deadline?.cancel()
            deadline = nil
        }

        /// ⚠️ Named apart from the fullscreen `report(_:)` below on purpose.
        /// Overloading on the argument type would compile, and would leave two
        /// unrelated signals — bars-withdrawn and player-came-up — reading as
        /// one function at every call site.
        ///
        /// Same main-queue dispatch as `deliver`, and for the same reason:
        /// these are ordered against each other, and `beginLoad` runs inside
        /// `makeUIView`, where touching the owner's `@State` synchronously is
        /// a mutation during view update.
        private func reportLoad(_ event: LinkEmbedLoadEvent) {
            let callback = onLoadEvent
            DispatchQueue.main.async {
                MainActor.assumeIsolated { callback(event) }
            }
        }

        /// The shell relaying its iframe's own `load` / `error`.
        func userContentController(_ controller: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            guard message.name == LinkEmbedView.messageHandlerName,
                  let event = LinkEmbedView.loadEvent(forMessageBody: message.body)
            else { return }
            if event == .frameLoaded { cancelDeadline() }
            reportLoad(event)
        }

        /// The main frame dying. With `loadHTMLString` this is not the blocked
        /// -platform case — that one never reaches the navigation delegate at
        /// all, which is the whole reason the deadline exists — but it is free
        /// to report and it covers a shell that somehow fails to parse.
        func webView(_ webView: WKWebView,
                     didFailProvisionalNavigation navigation: WKNavigation!,
                     withError error: Error) {
            cancelDeadline()
            reportLoad(.mainFrameFailed)
        }

        func webView(_ webView: WKWebView,
                     didFail navigation: WKNavigation!,
                     withError error: Error) {
            cancelDeadline()
            reportLoad(.mainFrameFailed)
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
            observeVideoWindows()
        }

        /// The second signal, and on TikTok/YouTube the only one that fires.
        /// See `LinkEmbedView.isVideoFullscreenWindow` for why a window is what
        /// we watch rather than `fullscreenState`.
        private func observeVideoWindows() {
            let centre = NotificationCenter.default
            for (name, entering) in [(UIWindow.didBecomeVisibleNotification, true),
                                     (UIWindow.didBecomeHiddenNotification, false)] {
                windowObservers.append(
                    centre.addObserver(forName: name, object: nil, queue: .main) { [weak self] note in
                        MainActor.assumeIsolated {
                            self?.handleWindow(note.object, entering: entering)
                        }
                    }
                )
            }
        }

        private func handleWindow(_ object: Any?, entering: Bool) {
            guard let window = object as? UIWindow else { return }
            let name = String(describing: type(of: window))
            let isOurs = window is PassThroughWindow
            guard LinkEmbedView.isVideoFullscreenWindow(
                className: name,
                isOurModuleWindow: isOurs,
                size: window.bounds.size,
                screen: window.screen.bounds.size
            ) else { return }
            if entering {
                guard !isFullscreen else { return }
                isFullscreen = true
                deliver(true)
            } else {
                restoreIfNeeded()
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
            deadline?.cancel()
            for observer in windowObservers { NotificationCenter.default.removeObserver(observer) }
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
