import SwiftUI

/// Single-line text that **scrolls continuously** when its content
/// exceeds the available width, and renders as a static label
/// otherwise.
///
/// Implementation:
/// - `ViewThatFits(in: .horizontal)` decides which child to render
///   based on whether it fits the offered width.
///   - First choice is a static `Text` with
///     `.fixedSize(horizontal: true, vertical: false)` — it requests
///     its natural width. If that fits, `ViewThatFits` picks it.
///   - Otherwise `ViewThatFits` falls back to `ScrollingMarquee`, a
///     horizontal `ScrollView` (scroll disabled) hosting two copies
///     of the text in an `HStack`. The combined offset animates
///     leftward by `textWidth + gap`, looping forever — so as one
///     copy scrolls off, the next is already in place. The seam is
///     invisible.
/// - Because `ViewThatFits` always picks the largest-fitting child,
///   the resulting layout never pushes its parent wider than the
///   offered width — even when text overflows.
///
/// Used by `MiniPlayerBar` for the title and subtitle so long tour
/// names don't truncate. Drop in anywhere a single-line label needs
/// the same treatment.
struct MarqueeText: View {
    let text: String
    var font: Font = .body
    var color: Color = .primary
    /// Scroll speed in points per second. ~30pt/sec reads as a calm,
    /// unobtrusive crawl.
    var speed: Double = 30

    var body: some View {
        ViewThatFits(in: .horizontal) {
            // First choice — fits at natural width.
            Text(text)
                .font(font)
                .foregroundStyle(color)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
            // Fallback — doesn't fit; scroll it.
            ScrollingMarquee(text: text, font: font, color: color, speed: speed)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Always-scrolling variant used by `MarqueeText` when the static
/// text won't fit. Renders two copies of the text in an `HStack` and
/// animates a leftward offset of `textWidth + gap` on repeat —
/// because the second copy starts exactly `gap` past the end of the
/// first, the loop is seamless.
private struct ScrollingMarquee: View {
    let text: String
    let font: Font
    let color: Color
    let speed: Double

    private static let gap: CGFloat = 40

    @State private var textWidth: CGFloat = 0
    @State private var offset: CGFloat = 0

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Self.gap) {
                label
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: MarqueeTextWidthKey.self,
                                value: geo.size.width
                            )
                        }
                    )
                label
            }
            .offset(x: offset)
        }
        .scrollDisabled(true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onPreferenceChange(MarqueeTextWidthKey.self) { w in
            guard abs(w - textWidth) > 0.5 else { return }
            textWidth = w
            startAnimation()
        }
        .onChange(of: text) { _, _ in
            // Reset & re-measure for the new text. The new
            // PreferenceKey fire will call startAnimation again.
            offset = 0
            textWidth = 0
        }
    }

    private var label: some View {
        Text(text)
            .font(font)
            .foregroundStyle(color)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
    }

    /// Resets offset to 0, then starts an indefinitely-repeating
    /// linear animation that slides the HStack leftwards by
    /// `textWidth + gap`. The `DispatchQueue.main.async` hop lets
    /// SwiftUI commit the reset before the animation begins —
    /// otherwise the new animation would interpolate from the old
    /// running offset value, producing a jump.
    private func startAnimation() {
        offset = 0
        guard textWidth > 0 else { return }
        let distance = textWidth + Self.gap
        let duration = Double(distance) / speed
        DispatchQueue.main.async {
            withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                offset = -distance
            }
        }
    }
}

private struct MarqueeTextWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
