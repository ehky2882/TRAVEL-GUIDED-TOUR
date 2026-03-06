import SwiftUI

struct TagChip: View {
    let text: String
    var isSelected: Bool = false

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? AtlasColors.accent : AtlasColors.secondaryBackground)
            .foregroundStyle(isSelected ? .white : AtlasColors.primaryText)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : AtlasColors.secondaryText.opacity(0.15), lineWidth: 1)
            )
    }
}
