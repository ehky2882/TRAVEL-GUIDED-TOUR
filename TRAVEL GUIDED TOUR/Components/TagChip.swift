import SwiftUI

struct TagChip: View {
    let text: String
    var isSelected: Bool = false

    var body: some View {
        Text(text)
            .font(AtlasTypography.caption)
            .foregroundStyle(isSelected ? Color.white : AtlasColors.primaryText)
            .padding(.horizontal, AtlasSpacing.md - 2)
            .padding(.vertical, AtlasSpacing.sm)
            .background(isSelected ? AtlasColors.accent : AtlasColors.secondaryBackground)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : AtlasColors.secondaryText.opacity(0.15), lineWidth: 1)
            )
    }
}
