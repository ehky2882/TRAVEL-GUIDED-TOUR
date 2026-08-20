import SwiftUI

/// The app's page-chrome button — the round-cornered 44pt glyph that closes a
/// page, goes back from one, saves it or opens its `…` menu.
///
/// **`TourDetailView` is the canon** (owner, 2026-08-20): whatever a page's top
/// chrome does, it looks like that page's. This type is that shape, in one
/// place, so a fifth screen can't quietly ship a slightly different one.
///
/// It exists because there were already three byte-identical private copies —
/// `TourDetailView`, `PlaceView`, `TourListDetailView` — and the tour wizard
/// was about to be the fourth. They had not drifted yet. `StopPin` and
/// `ClusterPin` were also identical copies until one of them became 14pt while
/// the other stayed 16, which is the thing worth not repeating: a private view
/// that another screen visibly needs is a duplicate that hasn't diverged yet.
///
/// The 44pt frame is the app's universal control diameter — map controls, the
/// tour action row, the search bar — so this sits on the same grid as every
/// other button, not merely on its own.
struct AtlasChromeButton: View {
    let systemName: String

    /// Whether the control can act.
    ///
    /// ⚠️ **Greys the GLYPH ONLY** — the capsule keeps its fill and its 44pt
    /// frame, so a control that can't act still holds its place in the row.
    /// The colour has to be stated here rather than left to `.disabled()`,
    /// because the glyph names `primaryText` explicitly and SwiftUI will not
    /// dim a colour a view has set for itself.
    ///
    /// Came from `TourListDetailView`, which grew a private copy of this
    /// button again in order to have it (2026-08-20, merging main into the
    /// wizard branch). That is the second time this shape has been
    /// re-privatised to gain one capability; adding the capability here is
    /// what stops a third.
    var enabled: Bool = true

    /// The app's universal control diameter. Read it rather than writing 44.
    static let diameter: CGFloat = 44
    /// A chrome row's full height: the button plus `AtlasSpacing.sm` above and
    /// below. Screens that lay a chrome row out by hand — the wizard, whose
    /// header is plain layout rather than a toolbar — need this to reserve the
    /// right space without guessing.
    // (The type's own name, not `Self` — which Swift rejects in a stored
    // property's initializer.)
    static let rowHeight: CGFloat = AtlasChromeButton.diameter + AtlasSpacing.sm * 2

    init(_ systemName: String, enabled: Bool = true) {
        self.systemName = systemName
        self.enabled = enabled
    }

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 20, weight: .regular))
            .foregroundStyle(enabled ? AtlasColors.primaryText : AtlasColors.tertiaryText)
            .frame(width: Self.diameter, height: Self.diameter)
            .background(Capsule().fill(AtlasColors.tertiaryText.opacity(0.18)))
            .contentShape(Capsule())
    }
}
