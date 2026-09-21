import SwiftUI

/// Long text clamped to a few lines, with an inline toggle to open it.
///
/// 🔴 WHY THIS EXISTS. Link-pin captions are the creator's own words, and until
/// 2026-09-21 the pipeline kept only their first 140 characters and threw the
/// rest away. That did two kinds of damage: **2,320 captions ended mid-word** on
/// screen, and — because creators put their address LAST — the cut landed on the
/// single most useful line in the text. One pin shipped **22.9 km wrong** for
/// want of a postcode that had been in the caption we discarded.
///
/// Keeping the whole caption fixes both, but only if something clamps it at
/// display time; otherwise a stop row becomes a wall of hashtags.
///
/// ⚠️ **The overflow test is a CHARACTER COUNT, deliberately.** It is the same
/// proxy `TourDetailView.shouldShowReadMoreToggle` already uses for
/// `longDescription`, and the reason is recorded there: a GeometryReader /
/// Text-measurement round-trip on every body evaluation fights the inline
/// truncation animation. A proxy can be wrong at the margin — it may offer
/// "Read more" on text that happened to fit — which is a cosmetic miss, where
/// measuring is a visible stutter. The threshold belongs to the CALLER, because
/// characters-per-line depends on the font: body at 15pt fits ~60, caption at
/// 12pt closer to ~80.
struct ExpandableText: View {
    let text: String
    let font: Font
    let lineLimit: Int
    /// Above this many characters, offer the toggle. See the note above on why
    /// this is a count rather than a measurement, and why the caller sets it.
    let overflowThreshold: Int
    var color: Color = AtlasColors.secondaryText

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
            Text(text)
                .font(font)
                .foregroundStyle(color)
                .multilineTextAlignment(.leading)
                .lineLimit(isExpanded ? nil : lineLimit)
                .fixedSize(horizontal: false, vertical: true)
                .animation(.easeInOut(duration: 0.2), value: isExpanded)

            if text.count > overflowThreshold {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
                } label: {
                    Text(isExpanded ? "Show less" : "Read more")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                }
                // ⚠️ `.plain` matters here beyond styling: these captions sit
                // inside stop rows that are themselves tappable, and a styled
                // button would both repaint the row and widen its hit target.
                .buttonStyle(.plain)
                .accessibilityLabel(isExpanded ? "Show less" : "Read more")
            }
        }
    }
}
