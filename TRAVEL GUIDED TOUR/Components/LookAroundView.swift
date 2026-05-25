import SwiftUI
import MapKit

/// Wraps Apple's `MKLookAroundViewController` so a Look Around scene
/// can be presented from SwiftUI (no first-class SwiftUI Look Around
/// view as of iOS 26.2). The scene is loaded via
/// `MKLookAroundSceneRequest(coordinate:)` by the caller and handed
/// in here — this view is a pure presenter, no probing logic.
struct LookAroundView: UIViewControllerRepresentable {
    let scene: MKLookAroundScene

    func makeUIViewController(context: Context) -> MKLookAroundViewController {
        let controller = MKLookAroundViewController(scene: scene)
        controller.isNavigationEnabled = true
        controller.showsRoadLabels = true
        return controller
    }

    func updateUIViewController(_ controller: MKLookAroundViewController, context: Context) {
        controller.scene = scene
    }
}
