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
/// 🔴 WHY IT MEASURES RATHER THAN COUNTING CHARACTERS. The first version of this
/// copied the character-count proxy from `TourDetailView.descriptionSection`
/// (240 characters ≈ 4 lines of body text) and it was **wrong on the very first
/// screen the owner opened**: two Montreal stops of 161 and 191 characters were
/// visibly clamped to three lines with **no toggle at all**. The proxy had been
/// calibrated for body type at full width; these are caption type in a stop row
/// that is indented behind a 24-point marker, so they wrap in far fewer
/// characters than the count assumed.
///
/// ⚠️ **The two ways of being wrong are NOT equally bad, which is what settles
/// the mechanism.** Offering "Read more" on text that happened to fit is a
/// cosmetic miss. Clamping text and offering *nothing* **hides content with no
/// affordance to reach it** — the reader cannot even tell there is more. A
/// proxy cannot distinguish those cases; a measurement cannot get them wrong.
///
/// The measurement is two hidden copies of the text — one capped at `lineLimit`,
/// one uncapped — laid out at the real width inside `.background`, so they cost
/// no layout space and take the same width as the visible copy. It runs on
/// layout changes rather than on every body evaluation, so the concern recorded
/// on the old proxy (measurement fighting the expand animation) does not apply:
/// the comparison is between two heights that **do not depend on** whether the
/// text is currently expanded.
struct ExpandableText: View {
    let text: String
    let font: Font
    let lineLimit: Int
    var color: Color = AtlasColors.secondaryText

    @State private var isExpanded = false
    @State private var clampedHeight: CGFloat = 0
    @State private var fullHeight: CGFloat = 0

    /// Half a point, so a rounding difference between two layout passes cannot
    /// read as "there is more text".
    private var isTruncated: Bool { fullHeight > clampedHeight + 0.5 }

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
            Text(text)
                .font(font)
                .foregroundStyle(color)
                .multilineTextAlignment(.leading)
                .lineLimit(isExpanded ? nil : lineLimit)
                .fixedSize(horizontal: false, vertical: true)
                .animation(.easeInOut(duration: 0.2), value: isExpanded)
                .background(alignment: .topLeading) { probe }

            if isTruncated {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
                } label: {
                    Text(isExpanded ? "Show less" : "Read more")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                }
                // ⚠️ `.plain` matters beyond styling: these captions sit inside
                // stop rows that are themselves tappable, and a styled button
                // would both repaint the row and widen its hit target.
                .buttonStyle(.plain)
                .accessibilityLabel(isExpanded ? "Show less" : "Read more")
            }
        }
    }

    /// Both copies hidden, inside `.background` so they inherit the visible
    /// text's width and contribute no height of their own.
    private var probe: some View {
        ZStack(alignment: .topLeading) {
            measured(limit: lineLimit) { clampedHeight = $0 }
            measured(limit: nil) { fullHeight = $0 }
        }
        .hidden()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func measured(limit: Int?, onChange: @escaping (CGFloat) -> Void) -> some View {
        Text(text)
            .font(font)
            .multilineTextAlignment(.leading)
            .lineLimit(limit)
            .fixedSize(horizontal: false, vertical: true)
            .background(
                GeometryReader { geometry in
                    Color.clear.onChange(of: geometry.size.height, initial: true) { _, height in
                        onChange(height)
                    }
                }
            )
    }
}
