import SwiftUI

/// Holds the app back until the launch splash has been drawn, so the breathing
/// brass mark is the first thing on screen.
///
/// 🔴 WHY THIS EXISTS. The splash is an overlay on the app's root view, and an
/// overlay cannot be drawn until the view it sits on has been built. With
/// `ContentView` mounted from the first frame, that meant building MKMapView,
/// the first clustering pass over the whole catalog, the drawer and the rails
/// before a single pixel of the splash reached the screen — all of it behind
/// iOS's static launch picture. Owner on TestFlight 1.1.2 (149), 2026-09-12:
/// *"the breathing is visibly there but i had to wait a long time for it."*
///
/// So the first frame is just the ground and the splash. The moment the mark
/// reports it is on screen (`LaunchState.markSplashShown`), `ContentView` mounts
/// underneath it and is built while the mark breathes.
///
/// ⚠️ THIS ONLY WORKS BECAUSE THE BREATH IS A CORE ANIMATION ANIMATION. Building
/// the app blocks the main thread for seconds on a cold launch; a SwiftUI-driven
/// breath would freeze for exactly that stretch. The render server keeps a layer
/// animation running regardless — see `SplashBreathingDisc`.
///
/// The #559 reasoning still holds: the expensive work happens behind the splash,
/// not in front of the user after it. It now starts one frame later, and the
/// splash is visible while it happens instead of waiting for it.
struct LaunchDeferredContent<Content: View>: View {
    let launchState: LaunchState
    @ViewBuilder var content: () -> Content

    @State private var fallbackElapsed = false

    /// If the splash never reports a drawn frame, mount the app anyway after
    /// this long — a broken signal must never leave a blank screen.
    static var fallbackDelay: TimeInterval { 1.0 }

    /// Whether the app may be built yet.
    static func shouldMount(splashShown: Bool, fallbackElapsed: Bool) -> Bool {
        splashShown || fallbackElapsed
    }

    var body: some View {
        if Self.shouldMount(
            splashShown: launchState.splashShownAt != nil,
            fallbackElapsed: fallbackElapsed
        ) {
            content()
        } else {
            // The same ground the splash paints, so the one frame before the
            // app mounts is indistinguishable from the splash itself.
            AtlasColors.background
                .ignoresSafeArea()
                .task {
                    try? await Task.sleep(for: .seconds(Self.fallbackDelay))
                    fallbackElapsed = true
                }
        }
    }
}
