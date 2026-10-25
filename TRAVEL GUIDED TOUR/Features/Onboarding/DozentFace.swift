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

/// What the face is doing. Six faces, picked by the owner on 2026-10-25 from
/// a sheet of options (*"i want more variety"* and *"options that don't make
/// it look like its eyes are closed"* — but *"the current eyes closed one …
/// is fine too, just not every single instance"*).
enum DozentExpression: String, CaseIterable, Sendable {
    /// Eyes closed, small smile — the original face. Calm screens only.
    case rest
    /// Dot eyes, wide smile (E1 + M2). The everyday face.
    case smile
    /// Smiling eyes, small smile (E7). Warm, a little pleased.
    case content
    /// Dot eyes, big open laugh (M4).
    case beam
    /// Dot eyes, a little "o" (M6) — something worth seeing.
    case wow
    /// Smiling eyes, big open laugh (X9). The big moments.
    case excited
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
            eye()
                .offset(x: -radius * 0.38, y: -radius * 0.16)
            eye()
                .offset(x: radius * 0.38, y: -radius * 0.16)
            mouth
        }
    }

    /// Closed (a downward arc), open (a dot), or smiling (an upward arc).
    @ViewBuilder
    private func eye() -> some View {
        switch expression {
        case .rest:
            let w = radius * 0.34, h = radius * 0.13
            ArcStroke(width: w, dip: h)
                .stroke(ink, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: w, height: h)
        case .smile, .beam, .wow:
            Circle()
                .fill(ink)
                .frame(width: radius * 0.184, height: radius * 0.184)
        case .content, .excited:
            // 🔴 NEGATIVE dip: the middle rises, so the eye smiles (◠). The
            // same curve as `rest` with the sign flipped.
            let w = radius * 0.26, h = radius * 0.1
            ArcStroke(width: w, dip: -h)
                .stroke(ink, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: w, height: h)
                .offset(y: radius * 0.04)
        }
    }

    @ViewBuilder
    private var mouth: some View {
        switch expression {
        case .rest, .content:
            // A smile: the middle sits LOWER than the ends. 🔴 Positive `dip`.
            // Build 180 shipped this negative and every resting face on the
            // run was frowning (owner: *"why would a face ever be frowning?!"*).
            // Screen y grows downward, so "curves up" in the geometry is a
            // frown on the glass.
            ArcStroke(width: radius * 0.46, dip: radius * 0.17)
                .stroke(ink, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: radius * 0.46, height: radius * 0.17)
                .offset(y: radius * 0.26)
        case .smile:
            ArcStroke(width: radius * 0.68, dip: radius * 0.2)
                .stroke(ink, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: radius * 0.68, height: radius * 0.2)
                .offset(y: radius * 0.24)
        case .beam, .excited:
            // A big open laugh: the lower half of a wide ellipse.
            HalfEllipse()
                .fill(ink)
                .frame(width: radius * 0.76, height: radius * 0.34)
                .offset(y: radius * 0.33)
        case .wow:
            Ellipse()
                .fill(ink)
                .frame(width: radius * 0.2, height: radius * 0.24)
                .offset(y: radius * 0.3)
        }
    }
}

/// A single quadratic arc. `dip` positive pulls the MIDDLE DOWN — on screen
/// that is a smile (‿). Negative pulls it up, which reads as a frown (⌒); no
/// expression uses that.
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

/// The lower half of an ellipse — the open laugh. Its top edge is the
/// frame's top edge.
private struct HalfEllipse: Shape {
    func path(in rect: CGRect) -> Path {
        let whole = CGRect(x: rect.minX, y: rect.minY - rect.height,
                           width: rect.width, height: rect.height * 2)
        return Path(ellipseIn: whole).intersection(Path(rect))
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
