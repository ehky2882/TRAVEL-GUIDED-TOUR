import SwiftUI
import Observation

/// A transient status banner. `id` is fresh per show so re-showing the same
/// message re-triggers the slide-in animation.
struct AtlasToast: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let style: Style

    enum Style {
        case error, success, info

        var icon: String {
            switch self {
            case .error:   return "exclamationmark.triangle.fill"
            case .success: return "checkmark.circle.fill"
            case .info:    return "info.circle.fill"
            }
        }

        var tint: Color {
            switch self {
            case .error:   return .red
            case .success: return AtlasColors.accent
            case .info:    return AtlasColors.accent
            }
        }
    }
}

/// App-wide channel for transient toasts. Built once at the app entry and
/// injected into both windows; call `show(_:style:)` from anywhere (usually a
/// failed user action). Auto-dismisses; a new toast replaces the current one.
@MainActor
@Observable
final class ToastCenter {
    private(set) var current: AtlasToast?
    private var dismissTask: Task<Void, Never>?

    /// Show a message. Default style is `.error` since that's the common case
    /// (surfacing a silently-swallowed failure).
    func show(_ message: String, style: AtlasToast.Style = .error) {
        current = AtlasToast(message: message, style: style)
        dismissTask?.cancel()
        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(3.2))
            guard !Task.isCancelled else { return }
            self?.current = nil
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        current = nil
    }
}

/// Renders the `ToastCenter`'s current toast, anchored to the top. Hosted in the
/// bottom-module window (which sits above every UIKit modal), so a toast shows
/// over tour/maker sheets and detail layers alike. Optional environment so it's
/// a no-op where the center isn't injected.
struct ToastHost: View {
    @Environment(ToastCenter.self) private var toastCenter: ToastCenter?

    var body: some View {
        ZStack(alignment: .top) {
            if let toast = toastCenter?.current {
                ToastView(toast: toast)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: toastCenter?.current)
    }
}

private struct ToastView: View {
    let toast: AtlasToast

    var body: some View {
        HStack(spacing: AtlasSpacing.sm) {
            Image(systemName: toast.style.icon)
                .font(AtlasTypography.caption)
                .foregroundStyle(toast.style.tint)
            Text(toast.message)
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.primaryText)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, AtlasSpacing.md)
        .padding(.vertical, AtlasSpacing.sm + 2)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AtlasColors.secondaryBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AtlasColors.secondaryText.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: AtlasColors.cardShadow, radius: 10, y: 4)
        .padding(.horizontal, AtlasSpacing.md)
        .padding(.top, AtlasSpacing.sm)
    }
}
