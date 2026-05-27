import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Color tokens. Values are **placeholders pending the deferred
/// design pass** — but adaptive ones, so Atlas reads correctly in
/// both light and dark color schemes. The design pass replaces
/// these tokens' values in this file; call sites don't change.
///
/// Discipline: every view reaches for `AtlasColors.*` instead of
/// hardcoded `Color.black` / `Color.white` / `Color(white:)`. The
/// pre-launch swap is then a one-file change.
enum AtlasColors {
    /// The brand accent. Mirrors `Assets.xcassets/AccentColor.colorset`
    /// (terracotta `#B85042` with a lighter dark-mode variant), so
    /// the asset catalog and code stay in sync — when the design
    /// pass picks a new accent, the asset gets updated and this
    /// value picks it up automatically.
    static let accent = Color.accentColor
    static let accentLight = Color.accentColor.opacity(0.6)

    /// Map pin color — dark gold `#8B7535`. Separate from the brand
    /// accent so pin styling can diverge from interactive-element
    /// tinting without a global accent change.
    static let mapPin = Color(red: 139/255, green: 117/255, blue: 53/255)

    /// Three-step text hierarchy. SwiftUI's semantic colors adapt
    /// to color scheme: primary is black in light mode and white
    /// in dark mode; secondary is a muted gray in both.
    static let primaryText = Color.primary
    static let secondaryText = Color.secondary
    static let tertiaryText = Color.secondary.opacity(0.6)

    // Surfaces. SwiftUI doesn't expose a cross-platform "system
    // background" Color, so we resolve to the platform's adaptive
    // equivalent. The design pass can replace these with
    // asset-catalog colorsets if the brand wants warmer surfaces.
    #if canImport(UIKit)
    static let background = Color(uiColor: .systemBackground)
    static let secondaryBackground = Color(uiColor: .secondarySystemBackground)
    static let cardBackground = Color(uiColor: .systemBackground)
    static let placeholderWarm = Color(uiColor: .tertiarySystemFill)
    static let placeholderCool = Color(uiColor: .tertiarySystemFill)
    static let divider = Color(uiColor: .separator)
    #elseif canImport(AppKit)
    static let background = Color(nsColor: .windowBackgroundColor)
    static let secondaryBackground = Color(nsColor: .underPageBackgroundColor)
    static let cardBackground = Color(nsColor: .windowBackgroundColor)
    static let placeholderWarm = Color(nsColor: .tertiaryLabelColor).opacity(0.3)
    static let placeholderCool = Color(nsColor: .tertiaryLabelColor).opacity(0.3)
    static let divider = Color(nsColor: .separatorColor)
    #else
    static let background = Color.gray.opacity(0.05)
    static let secondaryBackground = Color.gray.opacity(0.1)
    static let cardBackground = Color.gray.opacity(0.05)
    static let placeholderWarm = Color.gray.opacity(0.3)
    static let placeholderCool = Color.gray.opacity(0.3)
    static let divider = Color.gray.opacity(0.3)
    #endif

    /// Subtle card-elevation shadow. Kept as a literal because Apple's
    /// system shadow colors aren't accessible from SwiftUI; this is
    /// nearly imperceptible in dark mode (which is correct — dark
    /// surfaces shouldn't carry strong drop shadows).
    static let cardShadow = Color.black.opacity(0.12)
}
