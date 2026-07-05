import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Centralized haptic feedback so the taps the app fires stay consistent and
/// live in one place.
///
/// No-op where UIKit haptics don't exist (macOS / visionOS) and on the
/// Simulator (which has no haptic engine) — these are felt only on a device.
/// Each call spins up a fresh generator: for the app's occasional, discrete
/// events that's simpler than caching + `prepare()`ing generators, and the
/// latency is imperceptible for one-off taps.
@MainActor
enum AtlasHaptics {
    /// A light selection tick — reversible toggles (save / bookmark / follow).
    static func selection() {
        #if canImport(UIKit)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }

    /// A soft physical bump — used for the geofence "you've arrived at a stop"
    /// cue, the app's signature moment (often felt with the phone pocketed).
    static func impact(_ style: Style = .light) {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: style.uiStyle).impactOccurred()
        #endif
    }

    /// A completed download, an accepted request — a positive resolution.
    static func success() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    /// A failed download / write — a negative resolution.
    static func error() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        #endif
    }

    enum Style {
        case light, medium
        #if canImport(UIKit)
        var uiStyle: UIImpactFeedbackGenerator.FeedbackStyle {
            switch self {
            case .light:  return .light
            case .medium: return .medium
            }
        }
        #endif
    }
}
