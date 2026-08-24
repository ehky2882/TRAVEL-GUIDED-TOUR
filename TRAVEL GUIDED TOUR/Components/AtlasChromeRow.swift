import SwiftUI

/// How a full-screen detail page carries its own top chrome.
///
/// One modifier, used by every page that parks a row of `AtlasChromeButton`s
/// above its scrolling body — tour detail, the place page, the list page. It
/// owns four things those pages must never disagree about:
///
/// 1. **The row's shell** — `AtlasSpacing.sm` between controls, `.lg`
///    horizontal and `.sm` vertical padding around them.
/// 2. **Parking it** via `.safeAreaInset(edge: .top)`, so the row stays put
///    while the body scrolls *under* it.
/// 3. **The paint.** The row and the page are filled from the **same
///    expression**, so they cannot resolve to different colours.
/// 4. **Hiding the system navigation bar**, because this row replaces it.
///
/// Callers pass only the controls. Those legitimately differ per page — the
/// list page hides its bookmark when there is nothing to save, and its `…` when
/// Liked is on screen — and that is the whole reason the *contents* stay at the
/// call site while everything above stays here.
///
/// 🔴 **THE PAINT IS OPAQUE, AND IT IS NOT OVER A MATERIAL.** All three pages
/// used to draw `secondaryBackground.opacity(0.8)` over `.regularMaterial`,
/// which defeated the one guarantee `secondaryBackground` exists to give: it is
/// a hardcoded RGB pair specifically so every painted surface resolves to the
/// same value regardless of window or elevation (see its doc comment — a
/// semantic colour resolved differently at `.base` vs `.elevated`, which is
/// what put a seam between the bottom-module chrome and the detail body).
/// `.regularMaterial` resolves lighter than `#1C1C1E`, so the composite landed
/// a few levels above the page and the boundary read as a band (owner,
/// 2026-08-24, from a screenshot with the two regions marked).
///
/// ⚠️ **And it was not a constant.** A material samples what is behind it, and
/// page content — including a full-width hero — scrolls directly under this
/// row, so its shade *drifted as you scrolled*. That is why it read as
/// "something feels slightly off" for months rather than being filed as a bug.
///
/// 🔴 **DO NOT REINTRODUCE THE MATERIAL.** A future pass cannot have
/// translucency on this row *and* an invisible boundary with the page: one
/// token deliberately paints both surfaces, so any material resolves off it.
/// Same constraint recorded in PR #563 for why light mode cannot separate the
/// bars from the page they sit on. At full opacity a material behind this fill
/// is invisible anyway — it only costs an offscreen blur pass per frame.
///
/// **Why a modifier rather than three copies.** Until 2026-08-24 these lines
/// were duplicated across the three files and kept in step by a note in
/// CLAUDE.md saying they were byte-identical by design. That held, but the
/// opacity bug then had to be fixed in three places, which is one place too
/// many to get right by hand. A fourth page now gets the row correct by
/// construction instead of by remembering.
extension View {
    func atlasChromeRow<Controls: View>(
        @ViewBuilder controls: () -> Controls
    ) -> some View {
        self
            .safeAreaInset(edge: .top, spacing: 0) {
                HStack(spacing: AtlasSpacing.sm) {
                    controls()
                }
                .padding(.horizontal, AtlasSpacing.lg)
                .padding(.vertical, AtlasSpacing.sm)
                .background(AtlasColors.secondaryBackground)
            }
            .background(AtlasColors.secondaryBackground)
            // Our row IS the top chrome, so the system bar must go. iOS 26's
            // automatic glass-grouping around toolbar items otherwise stacks
            // on top of custom chrome and produces a visible "two layers"
            // look (owner correction, 2026-06-03). Applied here rather than
            // at each call site so a new page cannot get half of this right.
            // A page may still set `.navigationTitle` afterwards — the list
            // page does, purely so VoiceOver has a label for a bar nobody
            // sees.
            .toolbar(.hidden, for: .navigationBar)
    }
}
