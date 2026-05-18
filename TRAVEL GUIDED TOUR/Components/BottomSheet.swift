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

    @State private var dragOffset: CGFloat = 0
    @GestureState private var isDragging: Bool = false

    init(
        detent: Binding<BottomSheetDetent>,
        peekHeight: CGFloat = 100,
        @ViewBuilder content: () -> Content
    ) {
        self._detent = detent
        self.peekHeight = peekHeight
        self.content = content()
    }

    var body: some View {
        GeometryReader { geo in
            let visibleHeight = heightForDetent(detent, in: geo)

            VStack(spacing: 0) {
                dragHandle
                content
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(.regularMaterial)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 24,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 24,
                    style: .continuous
                )
            )
            .offset(y: geo.size.height - visibleHeight + dragOffset)
            .gesture(dragGesture(in: geo))
            .animation(
                isDragging ? nil : .spring(response: 0.4, dampingFraction: 0.85),
                value: detent
            )
        }
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
                // Use predicted end to honor flick velocity.
                let predictedVisible = heightForDetent(detent, in: geo) - value.predictedEndTranslation.height

                let target = nearestDetent(
                    toVisibleHeight: predictedVisible,
                    in: geo,
                    fallback: currentVisible
                )
                detent = target
                dragOffset = 0
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
