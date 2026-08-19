import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Catches the swipe-down on a sheet so the screen can ask before throwing
/// work away.
///
/// **Why not `interactiveDismissDisabled`.** SwiftUI's modifier only *blocks*
/// the gesture — it offers no way to know it was tried. A sheet full of unsaved
/// work then has a swipe that silently does nothing, which reads as broken
/// rather than protective. UIKit has exactly the callback needed
/// (`presentationControllerDidAttemptToDismiss`), so this bridges to it: the
/// swipe is refused *and* reported, and the screen puts up its own prompt.
///
/// The delegate is re-asserted on every update because SwiftUI owns the
/// presentation controller and may reset it. Programmatic dismissal is
/// unaffected — `dismiss()` doesn't go through this delegate.
extension View {
    func onDismissAttempt(enabled: Bool, perform action: @escaping () -> Void) -> some View {
        #if canImport(UIKit)
        background(DismissAttemptGuard(isEnabled: enabled, onAttempt: action))
        #else
        self
        #endif
    }
}

#if canImport(UIKit)
private struct DismissAttemptGuard: UIViewControllerRepresentable {
    let isEnabled: Bool
    let onAttempt: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onAttempt: onAttempt) }

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.isUserInteractionEnabled = false
        return controller
    }

    func updateUIViewController(_ controller: UIViewController, context: Context) {
        context.coordinator.onAttempt = onAttempt
        // The sheet's controller is an ancestor of this invisible one, and it
        // isn't in place on the first layout pass — hence the hop to the next
        // runloop turn rather than reading it here.
        DispatchQueue.main.async {
            guard let presented = controller.presentedRoot,
                  let presentation = presented.presentationController else { return }
            // Refusing the swipe is what makes UIKit report the attempt at all.
            presented.isModalInPresentation = isEnabled
            if !(presentation.delegate is Coordinator) {
                context.coordinator.previousDelegate = presentation.delegate
            }
            presentation.delegate = context.coordinator
        }
    }

    final class Coordinator: NSObject, UIAdaptivePresentationControllerDelegate {
        var onAttempt: () -> Void
        /// Kept so anything SwiftUI relied on still hears about adaptation.
        weak var previousDelegate: UIAdaptivePresentationControllerDelegate?

        init(onAttempt: @escaping () -> Void) {
            self.onAttempt = onAttempt
        }

        func presentationControllerDidAttemptToDismiss(_ controller: UIPresentationController) {
            onAttempt()
        }

        func presentationControllerDidDismiss(_ controller: UIPresentationController) {
            previousDelegate?.presentationControllerDidDismiss?(controller)
        }
    }
}

private extension UIViewController {
    /// The sheet's own controller — the first ancestor that was actually
    /// presented. This view is buried several children deep inside it.
    var presentedRoot: UIViewController? {
        var candidate: UIViewController? = self
        while let current = candidate {
            if current.presentingViewController != nil { return current }
            candidate = current.parent
        }
        return nil
    }
}
#endif
