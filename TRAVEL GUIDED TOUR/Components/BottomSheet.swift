import SwiftUI

/// Apple-Maps-style persistent bottom sheet with three snap detents.
/// Lives inside the parent view's layout (NOT presented modally), so
/// the tab bar above remains visible. Built because SwiftUI's
/// `.sheet(presentationDetents:)` is presented at the window level
/// and covers the tab bar regardless of detent height.
///
/// Usage:
///   ```
///   @State private var detent: BottomSheetDetent = .peek
///   ZStack(alignment: .bottom) {
///     mapBackground
///     BottomSheet(detent: $detent) { sheetContent }
///   }
///   ```
///
/// V1 design choices:
///   - 3 fixed detents (peek / medium / large). Heights are computed
///     from the parent's `GeometryProxy.size.height`.
///   - Drag gesture snaps to nearest detent on release, using the
///     predicted-end translation so a fast flick goes further than
///     a slow drag of the same distance.
///   - Spring animations on detent transitions; interactive spring
///     while the user is actively dragging.
///   - `.regularMaterial` background for the iOS 26 glass aesthetic.
///   - The map remains pannable through the sheet up to `.medium` —
///     handled at the call site by leaving touches above the sheet
///     unhandled (we don't add a backdrop).
struct BottomSheet<Content: View>: View {
    @Binding var detent: BottomSheetDetent
    let content: Content
    /// Peek detent's pixel height. Tunable per consumer; default ~100
    /// gives room for a drag handle + a single header line.
    var peekHeight: CGFloat = 100
    /// Inset from the screen edges on the left, right, AND bottom of
    /// the drawer. Same value on all three sides so the drawer reads
    /// as a uniformly-floating card. The iOS 26 floating tab bar sits
    /// above the drawer at the same inset, so the two visually align
    /// into one integrated element.
    var horizontalInset: CGFloat = 8
    /// Corner radius applied to all four corners of the drawer.
    var cornerRadius: CGFloat = 20

    /// Signed drag delta in points: positive when the user is dragging
    /// down (shrinking the drawer), negative when dragging up. Reset
    /// to 0 inside a `withAnimation` block on gesture end so the snap
    /// animates as a single tween instead of two separate changes.
    @State private var dragOffset: CGFloat = 0
    @GestureState private var isDragging: Bool = false

    init(
        detent: Binding<BottomSheetDetent>,
        peekHeight: CGFloat = 100,
        horizontalInset: CGFloat = 8,
        cornerRadius: CGFloat = 20,
        @ViewBuilder content: () -> Content
    ) {
        self._detent = detent
        self.peekHeight = peekHeight
        self.horizontalInset = horizontalInset
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        GeometryReader { geo in
            let baseHeight = heightForDetent(detent, in: geo)
            // Negative dragOffset = drag up = drawer grows.
            // Positive dragOffset = drag down = drawer shrinks.
            let dragHeight = min(
                max(peekHeight, baseHeight - dragOffset),
                geo.size.height - horizontalInset
            )

            VStack(spacing: 0) {
                dragHandle
                content
            }
            .frame(maxWidth: .infinity)
            .frame(height: dragHeight, alignment: .top)
            .background(.regularMaterial)
            .clipShape(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            // Equal inset on left, right, and bottom — the drawer's
            // glass extends *past* the safe area into the tab bar's
            // territory, so the tab bar visually sits on top of the
            // drawer's bottom edge. iOS 26's tab bar uses the same
            // glass material, so the two read as a single integrated
            // bottom element.
            .padding(.horizontal, horizontalInset)
            .padding(.bottom, horizontalInset)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .gesture(dragGesture(in: geo))
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }

    // MARK: - Subviews

    private var dragHandle: some View {
        Capsule()
            .fill(Color.secondary.opacity(0.4))
            .frame(width: 40, height: 5)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle()) // make the whole handle area draggable
    }

    // MARK: - Gesture

    private func dragGesture(in geo: GeometryProxy) -> some Gesture {
        DragGesture()
            .updating($isDragging) { _, state, _ in
                state = true
            }
            .onChanged { value in
                dragOffset = value.translation.height
            }
            .onEnded { value in
                let currentVisible = heightForDetent(detent, in: geo) - value.translation.height
                let predictedVisible = heightForDetent(detent, in: geo) - value.predictedEndTranslation.height
                let target = nearestDetent(
                    toVisibleHeight: predictedVisible,
                    in: geo,
                    fallback: currentVisible
                )
                // Animate detent change AND dragOffset reset together
                // in a single spring. Previously these were separate
                // state mutations and the offset-snap-back to 0 ran
                // implicitly without an animation, which caused the
                // jerk between detents.
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    detent = target
                    dragOffset = 0
                }
            }
    }

    // MARK: - Detent math

    private func heightForDetent(_ d: BottomSheetDetent, in geo: GeometryProxy) -> CGFloat {
        switch d {
        case .peek:   return peekHeight
        case .medium: return geo.size.height * 0.5
        case .large:  return geo.size.height * 0.92
        }
    }

    private func nearestDetent(
        toVisibleHeight target: CGFloat,
        in geo: GeometryProxy,
        fallback: CGFloat
    ) -> BottomSheetDetent {
        let scored = BottomSheetDetent.allCases.map { d in
            (d, abs(heightForDetent(d, in: geo) - target))
        }
        return scored.min(by: { $0.1 < $1.1 })?.0
            ?? BottomSheetDetent.allCases.min(by: {
                abs(heightForDetent($0, in: geo) - fallback)
                    < abs(heightForDetent($1, in: geo) - fallback)
            })
            ?? .peek
    }
}

enum BottomSheetDetent: CaseIterable {
    case peek
    case medium
    case large
}
