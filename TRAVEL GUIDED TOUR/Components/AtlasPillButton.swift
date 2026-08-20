import SwiftUI

/// The wizard's button, and the only one it has.
///
/// Owner, 2026-08-20, working through the wizard a step at a time: *"make
/// button sizes consistent. whatever is the height of the 'x' button at the top
/// should be the height of all buttons"* — and, of the steps as a set, *"it
/// should not differ so much which step you're on."*
///
/// 🔴 **SHARED, NOT COPIED.** Step 5 grew this shape first and step 6 wanted the
/// same one; a second copy is how the map pin ended up 14pt on one screen and
/// 16 on another, and how three screens each kept a private chrome button until
/// `AtlasChromeButton` collected them. One type, so a change to the shape is a
/// change everywhere it appears.
///
/// The height is read from `AtlasChromeButton.diameter` rather than repeated,
/// so the ✕ in the header and every button under it stay the same size by
/// construction.
struct AtlasPillLabel: View {
    let title: String
    var systemImage: String? = nil
    /// Drawn after the title — the chevron on a menu, and nothing else so far.
    var trailingImage: String? = nil
    var filled: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage { Image(systemName: systemImage) }
            Text(title)
                .lineLimit(1)
            if let trailingImage {
                Image(systemName: trailingImage).font(.system(size: 9))
            }
        }
        .font(AtlasTypography.caption)
        .foregroundStyle(filled ? AtlasColors.background : AtlasColors.primaryText)
        .padding(.horizontal, AtlasSpacing.sm)
        .frame(maxWidth: .infinity)
        .frame(height: AtlasChromeButton.diameter)
        .background {
            if filled {
                Capsule().fill(AtlasColors.mapPin)
            } else {
                Capsule().stroke(AtlasColors.tertiaryText.opacity(0.5), lineWidth: 1)
            }
        }
    }
}

/// `AtlasPillLabel` with a tap.
///
/// ⚠️ **Disabled, never absent.** A control that disappears is what moves
/// everything below it, and a gap says nothing — where a dimmed button says
/// *this becomes available*. Every step that uses these draws all of them in
/// every state and dims what does not apply.
struct AtlasPillButton: View {
    let title: String
    var systemImage: String? = nil
    var filled: Bool = false
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            AtlasPillLabel(title: title, systemImage: systemImage, filled: filled)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.35)
    }
}
