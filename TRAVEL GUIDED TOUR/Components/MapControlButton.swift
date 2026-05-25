import SwiftUI

/// Visual style — the circular pill background + centered SF Symbol —
/// shared by every floating map-overlay control on Home. Extracted
/// so it can be used both inside a `Button` (for direct-action
/// controls like recenter and Look Around) and as the label of a
/// `Menu` (for the map-mode picker) without double-wrapping a
/// `Button` in another `Button`.
///
/// Single form per the bottom-module design rule: buttons identical
/// everywhere; only the icon and the enabled tint differ.
struct MapControlButtonLabel: View {
    let systemImage: String
    var isEnabled: Bool = true

    /// Diameter of the circular hit-target. Picked to match the
    /// previous recenter button so existing layout math (button stack
    /// heights, drawer offsets) doesn't shift.
    static let diameter: CGFloat = 44

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 16))
            .foregroundStyle(isEnabled ? AtlasColors.primaryText : AtlasColors.tertiaryText)
            .frame(width: Self.diameter, height: Self.diameter)
            .background(AtlasColors.secondaryBackground)
            .clipShape(Circle())
            .shadow(color: Color.black.opacity(0.12), radius: 2, y: 1)
    }
}

/// Tappable `MapControlButtonLabel`. Use for direct-action controls
/// (recenter, Look Around). For controls that need a SwiftUI `Menu`,
/// use `MapControlButtonLabel` directly as the menu's label.
struct MapControlButton: View {
    let systemImage: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            MapControlButtonLabel(systemImage: systemImage, isEnabled: isEnabled)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}
