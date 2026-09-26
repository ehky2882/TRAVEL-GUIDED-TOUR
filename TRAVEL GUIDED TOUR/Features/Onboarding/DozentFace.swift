//
//  DozentFace.swift
//  TRAVEL GUIDED TOUR
//
//  The character: the splash disc, given a face.
//
//  🔴 Nothing new is invented here. `SplashView` already draws and blooms this
//  brass disc at launch; onboarding is the same mark with eyes and a mouth on
//  it (owner decision, 2026-09-21, from their own screens 1 → 2). So it needs
//  no new asset, no Lottie, no video, and it scales to any size because it is
//  three curves rather than a picture of three curves.
//
//  Expressions change on TRANSITIONS, never idly. A face that fidgets while
//  you are reading competes with the thing it is introducing — Headspace's do
//  not blink either.
//

import SwiftUI

/// What the face is doing.
enum DozentExpression: String, CaseIterable, Sendable {
    /// The default, and every screen that is only telling you something.
    case rest
    /// Welcome, and the moment after you answer something.
    case beam
    /// "Let me suggest a few" — the conspiratorial one.
    case wink
    /// The payoff screens, when the map fills in.
    case wow
}

/// The brass disc with a face on it.
struct DozentFace: View {
    var expression: DozentExpression = .rest
    /// Radius in points. The splash's own mark is 22 (44pt across).
    var radius: CGFloat = 42
    var fill: Color = AtlasColors.brass

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle().fill(fill)
            FaceMarks(expression: expression, radius: radius)
        }
        .frame(width: radius * 2, height: radius * 2)
        // Cross-fade between expressions. Nothing moves but the eyes and the
        // mouth — the circle never changes size or position, which is what
        // lets the face stay pinned to one spot across every screen.
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.28), value: expression)
        .accessibilityHidden(true)
    }
}

/// The eyes and mouth. Split out so the disc can animate independently.
private struct FaceMarks: View {
    let expression: DozentExpression
    let radius: CGFloat

    /// One fixed dark brass in both schemes, exactly like `AtlasColors.brass`
    /// itself. 🔴 NOT `AtlasColors.background`: that inverts in dark mode, and
    /// the face would go from dark-on-brass to near-white-on-brass halfway
    /// through the run.
    private var ink: Color { Color(red: 43 / 255, green: 37 / 255, blue: 23 / 255) }

    private var lineWidth: CGFloat { max(radius * 0.085, 1.6) }

    var body: some View {
        ZStack {
            eye(flipped: false)
                .offset(x: -radius * 0.38, y: -radius * 0.16)
            eye(flipped: true)
                .offset(x: radius * 0.38, y: -radius * 0.16)
            mouth
                .offset(y: radius * 0.26)
        }
    }

    /// A closed, content eye: a downward arc. `wink` flattens the right one.
    @ViewBuilder
    private func eye(flipped: Bool) -> some View {
        let winking = expression == .wink && flipped
        let w = radius * 0.34
        let h = winking ? 0 : radius * 0.13
        ArcStroke(width: w, dip: h)
            .stroke(ink, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .frame(width: w, height: max(h, lineWidth))
    }

    @ViewBuilder
    private var mouth: some View {
        switch expression {
        case .rest, .wink:
            // A small upward arc — the same curve as an eye, turned over.
            ArcStroke(width: radius * 0.46, dip: -radius * 0.17)
                .stroke(ink, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: radius * 0.46, height: radius * 0.17)
        case .beam:
            // An open smile: the lower half of a circle.
            HalfDisc()
                .fill(ink)
                .frame(width: radius * 0.56, height: radius * 0.28)
        case .wow:
            Ellipse()
                .fill(ink)
                .frame(width: radius * 0.28, height: radius * 0.34)
        }
    }
}

/// A single quadratic arc. `dip` positive curves downward, negative upward.
private struct ArcStroke: Shape {
    var width: CGFloat
    var dip: CGFloat

    /// Animatable so an expression change interpolates rather than snapping.
    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(width, dip) }
        set { width = newValue.first; dip = newValue.second }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let y = rect.midY
        path.move(to: CGPoint(x: rect.minX, y: y))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: y),
            control: CGPoint(x: rect.midX, y: y + dip * 2)
        )
        return path
    }
}

/// The lower half of a circle — the open smile.
private struct HalfDisc: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.minY),
            radius: rect.width / 2,
            startAngle: .degrees(0),
            endAngle: .degrees(180),
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}

#Preview {
    HStack(spacing: 20) {
        ForEach(DozentExpression.allCases, id: \.self) { e in
            DozentFace(expression: e, radius: 34)
        }
    }
    .padding()
    .background(AtlasColors.background)
}
