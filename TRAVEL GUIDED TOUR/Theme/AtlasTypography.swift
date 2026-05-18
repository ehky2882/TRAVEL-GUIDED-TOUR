import SwiftUI

/// Typography tokens. Values are **placeholders pending the
/// deferred design pass** — but mapped to SwiftUI system fonts so
/// the visual hierarchy is intact, Dynamic Type works, and dark
/// mode contrast follows iOS conventions.
///
/// Discipline: every view reaches for `AtlasTypography.*` instead
/// of hardcoded `Font.system(size:)`. The pre-launch swap to the
/// brand's custom face is then a one-file change.
enum AtlasTypography {
    static let largeTitle = Font.largeTitle
    static let title = Font.title
    static let title2 = Font.title2
    static let title3 = Font.title3
    static let headline = Font.headline
    static let body = Font.body
    static let callout = Font.callout
    static let caption = Font.caption
    /// Slot reserved for a serif caption (e.g. editorial captions
    /// on tour detail). Same as caption until the design pass picks
    /// a paired serif face.
    static let captionSerif = Font.caption
}
