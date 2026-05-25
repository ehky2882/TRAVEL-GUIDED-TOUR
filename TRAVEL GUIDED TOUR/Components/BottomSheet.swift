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
    /// the drawer.
    var horizontalInset: CGFloat = 8
    /// Drawer's top corner radius. Softer than a typical card corner
    /// but well short of the phone-radius bottom — a moderate curve
    /// that doesn't make the drawer look like a flipped half-pill.
    var topCornerRadius: CGFloat = 30
    /// Drawer's bottom corner radius — matches the phone screen's
    /// rounded corners so the drawer feels like a floating island
    /// that "follows" the device's bottom curvature. The AtlasTabBar
    /// uses the same bottom radius so when stacked they read as one
    /// continuous phone-shaped pill.
    var bottomCornerRadius: CGFloat = AtlasSpacing.phoneScreenRadius
    /// Vertical space the parent has reserved for a floating element
    /// below the drawer (mini-player + tab bar, on the home screen).
    /// The `.large` detent stops short by this amount, so the drawer
    /// stacks *on top of* that element instead of extending behind it
    /// and letting its rounded bottom corners peek out around the
    /// floating island's edges.
    var bottomReservedHeight: CGFloat = 0

    /// Signed drag delta in points: positive when the user is dragging
    /// down (shrinking the drawer), negative when dragging up. Reset
    /// to 0 inside a `withAnimation` block on gesture end so the snap
    /// animates as a single tween instead of two separate changes.
    ///
    /// Exposed as a `@Binding` so the parent can position other UI
    /// (like the home screen's recenter button) that needs to track
    /// the drawer's edge during the drag — not just after the snap.
    @Binding var dragOffset: CGFloat
    @GestureState private var isDragging: Bool = false

    init(
        detent: Binding<BottomSheetDetent>,
        dragOffset: Binding<CGFloat>,
        peekHeight: CGFloat = 100,
        horizontalInset: CGFloat = 8,
        topCornerRadius: CGFloat = 30,
        bottomCornerRadius: CGFloat = AtlasSpacing.phoneScreenRadius,
        bottomReservedHeight: CGFloat = 0,
        @ViewBuilder content: () -> Content
    ) {
        self._detent = detent
        self._dragOffset = dragOffset
        self.peekHeight = peekHeight
        self.horizontalInset = horizontalInset
        self.topCornerRadius = topCornerRadius
        self.bottomCornerRadius = bottomCornerRadius
        self.bottomReservedHeight = bottomReservedHeight
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
            .background(AtlasColors.secondaryBackground)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: topCornerRadius,
                    bottomLeadingRadius: bottomCornerRadius,
                    bottomTrailingRadius: bottomCornerRadius,
                    topTrailingRadius: topCornerRadius,
                    style: .continuous
                )
            )
            // 8pt insets on left + right. The bottom padding is
            // exactly the parent's reserved height — when 0, the
            // drawer sits flush against the screen edge (default
            // behavior); when set (home screen passes the floating
            // mini-player + tab bar height) the drawer's bottom edge
            // lines up flush with the top of that element, no gap.
            .padding(.horizontal, horizontalInset)
            .padding(.bottom, bottomReservedHeight)
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
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Tour list")
            .accessibilityValue(detentAccessibilityValue)
            .accessibilityHint("Swipe up or down with one finger to change height.")
            .accessibilityAddTraits(.isButton)
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment:
                    detent = nextDetent(above: detent)
                case .decrement:
                    detent = nextDetent(below: detent)
                @unknown default:
                    break
                }
            }
    }

    private var detentAccessibilityValue: String {
        switch detent {
        case .peek:   return "Collapsed"
        case .medium: return "Half open"
        case .large:  return "Fully open"
        }
    }

    private func nextDetent(above current: BottomSheetDetent) -> BottomSheetDetent {
        switch current {
        case .peek:   return .medium
        case .medium: return .large
        case .large:  return .large
        }
    }

    private func nextDetent(below current: BottomSheetDetent) -> BottomSheetDetent {
        switch current {
        case .large:  return .medium
        case .medium: return .peek
        case .peek:   return .peek
        }
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
        case .large:
            // Fill the container, less the 8pt top inset, less the
            // height the parent reserved at the bottom for a floating
            // element (mini-player + tab bar on the home screen). The
            // matching `.padding(.bottom, bottomReservedHeight)` below
            // pushes the drawer's bottom edge flush against the top of
            // that element — no gap.
            return geo.size.height - horizontalInset - bottomReservedHeight
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
