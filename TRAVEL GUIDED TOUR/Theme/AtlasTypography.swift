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
    /// 15pt SF Pro regular. Pinned smaller than SwiftUI's semantic
    /// `Font.body` (17pt) for a tighter overall feel across the
    /// home + detail surfaces. NOTE: `Font.system(size:)` is a
    /// fixed-size font, so this disables Dynamic Type scaling for
    /// every body use — accept that tradeoff for now; a future
    /// pass can switch to `Font.system(size:relativeTo:)` once the
    /// design target is locked.
    static let body = Font.system(size: 15, weight: .regular, design: .default)
    static let callout = Font.callout
    /// 13pt SF Mono regular. Used wherever the home + detail surfaces
    /// show a small auxiliary label — chip text, mini-player subtitle,
    /// tab bar labels, stop captions / durations, the search-bar
    /// placeholder, the subtitle line on tour detail. The monospaced
    /// face gives the small-metadata copy a distinct editorial voice
    /// next to the SF Pro body text above it.
    static let caption = Font.system(size: 13, weight: .regular, design: .monospaced)
    /// Slot reserved for a serif caption (e.g. editorial captions on
    /// tour detail). Holds the SwiftUI semantic `Font.caption` (12pt
    /// SF Pro) as a placeholder until the design pass picks a paired
    /// serif face — intentionally NOT the same value as `caption`
    /// above, which is now monospaced.
    static let captionSerif = Font.caption
    /// Brand wordmark face — **New York** (the serif system design) at
    /// caption size. Used for the "DOZENT" app name on the Settings
    /// masthead so the wordmark reads as a logotype, distinct from the
    /// SF Mono caption used everywhere else on that surface.
    static let wordmark = Font.system(size: 13, weight: .regular, design: .serif)
}
