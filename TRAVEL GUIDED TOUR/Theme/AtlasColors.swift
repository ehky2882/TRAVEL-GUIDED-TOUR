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
    /// The brand accent — dark gold (brass) `#8B7535`, owner-confirmed
    /// 2026-07-04. Mirrors `Assets.xcassets/AccentColor.colorset`, so the
    /// asset catalog and code stay in sync. Deliberately a SINGLE value in
    /// both light and dark mode (owner: "it is the one that stays
    /// consistent") — the asset carries no dark-mode variant.
    static let accent = Color.accentColor
    static let accentLight = Color.accentColor.opacity(0.6)

    /// Map pin + interactive-highlight color. Same gold as the brand
    /// accent since the 2026-07-04 unification (the old terracotta accent
    /// is gone); kept as its own token name because ~58 call sites read
    /// `mapPin`, and so pin styling COULD diverge again someday without
    /// touching them.
    static let mapPin = accent

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
    /// Hardcoded RGB pair instead of `.secondarySystemBackground` so
    /// every painted surface — tour-detail body in window 1, bars in
    /// window 2, drawer, search bar — resolves to the EXACT same
    /// RGB regardless of which window or elevation context renders
    /// it. The system semantic color resolved differently at
    /// `.base` vs `.elevated` user-interface-level traits, which is
    /// why the bottom-module CHROME used to show a visible seam
    /// against the detail body in dark mode.
    /// Light: #F2F2F7 (system default). Dark: #1C1C1E (base level).
    static let secondaryBackgroundUIColor: UIColor = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 28/255, green: 28/255, blue: 30/255, alpha: 1)
            : UIColor(red: 242/255, green: 242/255, blue: 247/255, alpha: 1)
    }
    static let secondaryBackground = Color(uiColor: secondaryBackgroundUIColor)
    /// The bottom-module surfaces (mini-player painted bar, tab bar
    /// painted button row) all use the same shade as the rest of
    /// the secondary CHROME, so the boundary between the bars and
    /// the surrounding detail body / drawer is invisible.
    static let miniPlayerBackground = secondaryBackground
    static let tabBarBackground = secondaryBackground
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
