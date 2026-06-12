import SwiftUI
import UIKit

/// UIKit-backed "slide up from the bottom, stop short of the tab bar"
/// modal presentation, driven directly from SwiftUI via a `.onChange`
/// observer in `ContentView`.
///
/// **Why this exists.** SwiftUI's built-in presentation primitives
/// (`.sheet`, `.fullScreenCover`) cover the persistent mini-player +
/// tab bar at the bottom of the screen. The owner-requested UX is
/// "slide up from the bottom AND keep mini-player + tab bar visible
/// underneath" — a combination iOS doesn't expose natively.
///
/// **The architecture.** UIKit's `UIPresentationController` is the
/// canonical pattern for a custom modal:
///
///   - `BottomLayerPresentationController` overrides
///     `frameOfPresentedViewInContainerView` to size the presented
///     view to "everything except the bottom inset." The bottom
///     inset is exactly `AtlasBottomModule.height()` so the
///     mini-player + tab bar (rendered in the original SwiftUI
///     hierarchy) remain visible.
///   - `BottomLayerContainerView` overrides hit testing so touches
///     in the bottom-inset region pass through to the underlying
///     SwiftUI content (the mini-player + tab bar stay tappable).
///   - `BottomLayerSlideUpAnimator` / `…SlideDownAnimator` run the
///     present/dismiss as a UIKit spring animation on the presented
///     view's `transform`. UIKit's spring is the same primitive
///     system sheets use — no SwiftUI animation curve mismatch, no
///     per-direction asymmetry.
///   - `BottomLayerController` is the public entry point. Call
///     `present(_:from:bottomInset:onDismiss:)` from a SwiftUI
///     `.onChange` to slide a UIKit-hosted SwiftUI view up;
///     `dismiss()` to slide it back down. The controller looks up
///     the active window's top view controller, builds a
///     `UIHostingController`, and presents.

// MARK: - Container view (hit-test pass-through)

/// The transparent container view UIKit uses as the presentation's
/// containerView. Hit-tests inside the presented view's frame go to
/// the presented view as normal; hit-tests outside it (i.e. the
/// bottom-inset region where mini-player + tab bar live) return
/// `nil` so UIKit walks back up to the underlying SwiftUI hierarchy
/// — same pattern Apple Music uses for its persistent now-playing
/// bar.
final class BottomLayerContainerView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hit = super.hitTest(point, with: event)
        return hit === self ? nil : hit
    }
}

// MARK: - Presentation controller

final class BottomLayerPresentationController: UIPresentationController {
    private let bottomInset: CGFloat
    private weak var passThrough: BottomLayerContainerView?

    init(
        presentedViewController: UIViewController,
        presenting: UIViewController?,
        bottomInset: CGFloat
    ) {
        self.bottomInset = bottomInset
        super.init(presentedViewController: presentedViewController, presenting: presenting)
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView else { return .zero }
        // Full-screen frame. The mini-player + tab bar in the
        // secondary higher-level window naturally cover the bottom
        // strip — so as the modal slides up, its bottom passes
        // *behind* them rather than stopping short. This gives the
        // "comes up from behind the bottom module" look the owner
        // asked for. The `bottomInset` is retained on this object
        // only as documentation of the height the secondary window
        // occupies — not used in the frame math anymore.
        return CGRect(
            x: 0,
            y: 0,
            width: containerView.bounds.width,
            height: containerView.bounds.height
        )
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        // Install a transparent pass-through view at the back of the
        // container so the bottom-inset area (mini-player + tab bar)
        // remains touch-interactive while the modal is up.
        if let containerView {
            let v = BottomLayerContainerView(frame: containerView.bounds)
            v.backgroundColor = .clear
            v.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            containerView.insertSubview(v, at: 0)
            passThrough = v
        }
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)
        if completed { passThrough?.removeFromSuperview() }
    }

    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        presentedView?.frame = frameOfPresentedViewInContainerView
    }
}

// MARK: - Animators

/// Slide-up: translate the presented view from off-screen-below to
/// its final frame, using UIKit's standard system-sheet spring
/// (damping 1.0 = no overshoot, same look `.sheet` uses).
final class BottomLayerSlideUpAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    static let duration: TimeInterval = 0.4

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        Self.duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let toVC = transitionContext.viewController(forKey: .to),
            let toView = transitionContext.view(forKey: .to)
        else {
            transitionContext.completeTransition(false)
            return
        }
        let container = transitionContext.containerView
        toView.frame = transitionContext.finalFrame(for: toVC)
        container.addSubview(toView)
        toView.transform = CGAffineTransform(translationX: 0, y: container.bounds.height)

        UIView.animate(
            withDuration: Self.duration,
            delay: 0,
            usingSpringWithDamping: 1.0,
            initialSpringVelocity: 0,
            options: [.curveEaseInOut, .allowUserInteraction],
            animations: { toView.transform = .identity },
            completion: { finished in
                transitionContext.completeTransition(finished && !transitionContext.transitionWasCancelled)
            }
        )
    }
}

/// Slide-down: mirror of the slide-up — same duration, same spring,
/// same options — so the two directions feel like time-reverses.
final class BottomLayerSlideDownAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        BottomLayerSlideUpAnimator.duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from) else {
            transitionContext.completeTransition(false)
            return
        }
        let container = transitionContext.containerView

        UIView.animate(
            withDuration: BottomLayerSlideUpAnimator.duration,
            delay: 0,
            usingSpringWithDamping: 1.0,
            initialSpringVelocity: 0,
            options: [.curveEaseInOut, .allowUserInteraction],
            animations: {
                fromView.transform = CGAffineTransform(translationX: 0, y: container.bounds.height)
            },
            completion: { finished in
                fromView.removeFromSuperview()
                transitionContext.completeTransition(finished && !transitionContext.transitionWasCancelled)
            }
        )
    }
}

// MARK: - Transitioning delegate

final class BottomLayerTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    let bottomInset: CGFloat
    let onSystemDismiss: () -> Void

    init(bottomInset: CGFloat, onSystemDismiss: @escaping () -> Void) {
        self.bottomInset = bottomInset
        self.onSystemDismiss = onSystemDismiss
    }

    func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        let pc = BottomLayerPresentationController(
            presentedViewController: presented,
            presenting: presenting,
            bottomInset: bottomInset
        )
        pc.delegate = self
        return pc
    }

    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        BottomLayerSlideUpAnimator()
    }

    func animationController(
        forDismissed dismissed: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        BottomLayerSlideDownAnimator()
    }
}

extension BottomLayerTransitioningDelegate: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        // Fired when UIKit dismisses the modal without the app
        // initiating it (e.g. a future interactive drag-down).
        // Keeps SwiftUI state in sync.
        onSystemDismiss()
    }
}

// MARK: - Public controller

/// Public entry point. Holds the live transitioning delegate (UIKit
/// only retains it weakly) and references the currently-presented
/// hosting controller so SwiftUI's `.onChange` observer can drive
/// present/dismiss as a tour-binding flips.
@MainActor
final class BottomLayerController {
    private let bottomInset: CGFloat
    private var transitioningDelegate: BottomLayerTransitioningDelegate?
    private weak var presented: UIViewController?

    init(bottomInset: CGFloat) {
        self.bottomInset = bottomInset
    }

    /// Present `view` from the topmost view controller in the active
    /// window. `onDismiss` is invoked if UIKit dismisses the modal
    /// without `dismiss()` being called explicitly.
    func present<Content: View>(
        _ view: Content,
        onDismiss: @escaping () -> Void
    ) {
        guard let top = topViewController() else { return }
        // Tear down any previous transitioning delegate before
        // building a new one — the delegate's `onSystemDismiss`
        // closure captures app state, so we need a fresh one per
        // presentation.
        let delegate = BottomLayerTransitioningDelegate(
            bottomInset: bottomInset,
            onSystemDismiss: onDismiss
        )
        self.transitioningDelegate = delegate

        let hosting = UIHostingController(rootView: view)
        // Paint the hosting view with the same UIColor the SwiftUI
        // content uses for its surface. Without this the host view
        // defaults to .systemBackground (pure black in dark mode);
        // any region not covered by the SwiftUI content shows that
        // color instead of the bar fill. Uses the hardcoded
        // `AtlasColors.secondaryBackgroundUIColor` so the detail
        // body's UIKit fill matches the bars' SwiftUI fill exactly
        // — no elevation-trait shade divergence between windows.
        hosting.view.backgroundColor = AtlasColors.secondaryBackgroundUIColor
        // Force the elevated user-interface-level trait. The
        // mini-player + tab bar live in a higher-level UIWindow
        // (`windowLevel = .normal + 1`), which UIKit treats as
        // elevated — and in dark mode `.secondarySystemBackground`
        // resolves to a *slightly lighter* shade at the elevated
        // level than at the base. Without this override, the detail
        // body (base) reads as visibly darker than the mini-player
        // + tab bar (elevated), even though both ask for the same
        // semantic color.
        hosting.overrideUserInterfaceStyle = .unspecified
        hosting.traitOverrides.userInterfaceLevel = .elevated
        hosting.modalPresentationStyle = .custom
        hosting.transitioningDelegate = delegate
        top.present(hosting, animated: true)
        presented = hosting
    }

    /// Dismiss the currently-presented detail, if any. `completion`
    /// fires when the slide-down animation finishes — callers use it
    /// to flip state that must outlast the animation (e.g. keeping
    /// the home drawer mounted until the layer has fully revealed it).
    func dismiss(completion: (() -> Void)? = nil) {
        guard let presented else {
            completion?()
            return
        }
        presented.dismiss(animated: true, completion: completion)
    }

    private func topViewController() -> UIViewController? {
        let root = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })?
            .windows
            .first(where: \.isKeyWindow)?
            .rootViewController
        var top = root
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}
