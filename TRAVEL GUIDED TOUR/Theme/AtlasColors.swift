import SwiftUI

enum AtlasColors {
    static let accent = Color(red: 184/255, green: 80/255, blue: 66/255) // #B85042 terracotta
    static let accentLight = Color(red: 210/255, green: 140/255, blue: 130/255)

    static let primaryText = Color.primary
    static let secondaryText = Color.secondary
    static let tertiaryText = Color.secondary.opacity(0.6)

    #if os(iOS) || os(visionOS)
    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let cardBackground = Color(.tertiarySystemBackground)
    #else
    static let background = Color(.windowBackgroundColor)
    static let secondaryBackground = Color(.controlBackgroundColor)
    static let cardBackground = Color(.textBackgroundColor)
    #endif

    // Placeholder colors that adapt to dark mode
    static let placeholderWarm = Color(red: 230/255, green: 218/255, blue: 210/255)
    static let placeholderCool = Color(red: 215/255, green: 220/255, blue: 225/255)

    // Semantic colors for specific use cases
    static let divider = Color.secondary.opacity(0.15)
    static let cardShadow = Color.black.opacity(0.12)
}
