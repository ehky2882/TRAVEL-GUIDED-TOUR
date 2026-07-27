import SwiftUI

/// The app's one in-page switcher — an underline tab strip.
///
/// Replaces the two `.pickerStyle(.segmented)` rows Atlas used to carry
/// (Library's Lists / Downloaded / Recents and tour detail's Gallery /
/// Map). Owner direction 2026-07-27: the maker page's new Tours / Lists
/// / Map strip is the shape they want, and rather than let Atlas run two
/// switcher idioms side by side, the existing segmented controls adopt
/// it too.
///
/// Why a strip rather than a segmented control: a segmented control
/// reads as "the same content, filtered differently," which is not what
/// any of these three rows do — each holds genuinely different content.
/// The nesting settled it: a maker page whose switcher looked identical
/// to the switcher inside a tour opened from it would be two controls
/// doing different jobs one tap apart.
///
/// **Deleting the segmented controls also deleted two global hacks.**
/// Both former call sites reached into `UISegmentedControl.appearance()`
/// to force SF Mono onto the labels — an app-wide proxy mutation that
/// restyled every segmented control the app could ever show, including
/// ones inside system sheets. This component styles its own text, so
/// nothing global is touched.
///
/// The strip is **inset**, not full-bleed: its hairline starts and ends
/// level with the row content beneath it. Shipped full-bleed first and
/// the owner called it on device (TestFlight 1.1 (52)): *"definitely
/// prefer inset on the strips."*
///
/// The inset lives here rather than at the three call sites so all three
/// screens are guaranteed to match — a caller can still override it, but
/// nothing has to remember to.
struct AtlasTabStrip<Tab: Hashable>: View {
    let tabs: [Tab]
    @Binding var selection: Tab
    /// Display label for a tab. Rendered ALL CAPS in
    /// `AtlasTypography.caption`, so pass the plain name.
    let title: (Tab) -> String
    /// Gutter either side. Defaults to the page gutter every consumer
    /// uses for its own content, so the rule lines up with it.
    var horizontalInset: CGFloat = AtlasSpacing.lg

    /// Honour Reduce Motion: the underline jumps instead of sliding.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var underlineNamespace

    /// Shared id for the sliding underline — one per strip instance,
    /// since `@Namespace` is scoped to this view.
    private static var underlineID: String { "atlas-tab-strip-underline" }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.self) { tab in
                tabButton(tab)
            }
        }
        // Behind the buttons, so a selected tab's underline draws *over*
        // the hairline rather than under it. Applied BEFORE the padding
        // below, so the hairline insets along with the buttons instead
        // of running edge to edge behind them.
        .background(alignment: .bottom) {
            Rectangle()
                .fill(AtlasColors.divider)
                .frame(height: 1)
        }
        .padding(.horizontal, horizontalInset)
        .accessibilityElement(children: .contain)
    }

    private func tabButton(_ tab: Tab) -> some View {
        let isSelected = tab == selection

        return Button {
            guard tab != selection else { return }
            if reduceMotion {
                selection = tab
            } else {
                withAnimation(.easeInOut(duration: 0.18)) { selection = tab }
            }
        } label: {
            Text(title(tab))
                .font(AtlasTypography.caption)
                .textCase(.uppercase)
                .foregroundStyle(isSelected ? AtlasColors.primaryText : AtlasColors.tertiaryText)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                // The app's shared tap-target height (44pt, the HIG
                // minimum) — same token the search bar and map controls
                // use, so every interactive row carries one footprint.
                .frame(height: AtlasSpacing.searchBarHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            if isSelected {
                Rectangle()
                    .fill(AtlasColors.accent)
                    .frame(height: 2)
                    .matchedGeometryEffect(id: Self.underlineID, in: underlineNamespace)
            }
        }
        .accessibilityLabel(title(tab))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Convenience for `String`-backed enums

extension AtlasTabStrip where Tab: RawRepresentable, Tab.RawValue == String {
    /// The common case: a `String`-backed enum whose raw value is
    /// already the display label (`case gallery = "Gallery"`).
    init(
        tabs: [Tab],
        selection: Binding<Tab>,
        horizontalInset: CGFloat = AtlasSpacing.lg
    ) {
        self.init(
            tabs: tabs,
            selection: selection,
            title: { $0.rawValue },
            horizontalInset: horizontalInset
        )
    }
}

#Preview("Light") {
    StripPreviewHost()
        .background(AtlasColors.secondaryBackground)
}

#Preview("Dark") {
    StripPreviewHost()
        .background(AtlasColors.secondaryBackground)
        .preferredColorScheme(.dark)
}

private struct StripPreviewHost: View {
    private enum Demo: String, CaseIterable {
        case tours = "Tours"
        case lists = "Lists"
        case map = "Map"
    }

    @State private var two: Demo = .tours
    @State private var three: Demo = .lists

    var body: some View {
        VStack(spacing: AtlasSpacing.xl) {
            AtlasTabStrip(tabs: [Demo.tours, .map], selection: $two)
            AtlasTabStrip(tabs: Demo.allCases, selection: $three)
        }
        .padding(.vertical, AtlasSpacing.xl)
    }
}
