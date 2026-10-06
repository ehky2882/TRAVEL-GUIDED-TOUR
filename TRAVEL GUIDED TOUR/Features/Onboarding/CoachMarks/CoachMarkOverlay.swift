//
//  CoachMarkOverlay.swift
//  TRAVEL GUIDED TOUR
//
//  The navigation tour's overlay: a dim with a spotlight cut out of it, and
//  the dozent speaking a bubble beside the control.
//
//  Hosted on `BottomModuleRoot` — the bars' window — because that window sits
//  above the main one and so is the only place a dim can cover the tab bar as
//  well as the map. See `CoachMarkCenter` for why, and for the touch claim.
//
//  Owner decisions this draws, all from the canvas review:
//  · the dozent stands OUTSIDE the bubble and speaks it (2026-09-23);
//  · no step counting, no "Skip all" (2026-09-23);
//  · the face moves with the bubble to whatever it is explaining (2026-09-22);
//  · the map stop has no cut-out — the map is the screen (2026-09-22).
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct CoachMarkOverlay: View {
    @Environment(CoachMarkCenter.self) private var center: CoachMarkCenter?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if let center, let mark = center.current {
                CoachMarkStop(mark: mark, anchor: center.anchors[mark],
                              advance: { center.advance() },
                              back: { center.back() })
                .id(mark)
                .transition(.opacity)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: center?.current)
    }
}

/// One stop.
private struct CoachMarkStop: View {
    let mark: CoachMark
    let anchor: CGRect?
    let advance: () -> Void
    let back: () -> Void

    private let faceRadius: CGFloat = 22
    private let edge: CGFloat = 20

    var body: some View {
        GeometryReader { geo in
            let spot = spotlight(in: geo.size)
            ZStack(alignment: .topLeading) {
                dim(spot: spot)
                bubbleColumn(spot: spot, size: geo.size)
            }
            // Reels-style, like the onboarding cards (owner, 2026-10-06): a
            // tap on the left third goes back, anywhere else advances; swipe
            // left for next, right for back. The button's own tap takes
            // priority on its own area. Never require a tap ON the target —
            // that needs pass-through hit-testing across two windows and does
            // not ship.
            .contentShape(Rectangle())
            .onTapGesture { location in
                if location.x < geo.size.width / 3 { back() } else { advance() }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 24)
                    .onEnded { drag in
                        let dx = drag.translation.width, dy = drag.translation.height
                        guard abs(dx) > 80, abs(dx) > abs(dy) * 2 else { return }
                        if dx > 0 { back() } else { advance() }
                    }
            )
        }
        .ignoresSafeArea()
        // The likeliest defect here is VoiceOver focus landing behind the
        // overlay, in the other window. Modal + a screen-changed post keeps it
        // on the card.
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .onAppear {
            #if canImport(UIKit)
            UIAccessibility.post(notification: .screenChanged, argument: nil)
            #endif
        }
    }

    // MARK: - Spotlight

    /// The hole, in screen coordinates — or `nil` for the map stop, or while
    /// the control has not reported where it is yet.
    private func spotlight(in size: CGSize) -> CGRect? {
        guard mark.hasSpotlight, var rect = anchor else { return nil }
        // The drawer reports its visible panel, so it is lit whole — the
        // list is the thing being explained (owner, 2026-10-06).
        rect = rect.insetBy(dx: -6, dy: -6)
        // Keep it on the glass.
        return rect.intersection(CGRect(origin: .zero, size: size))
    }

    @ViewBuilder
    private func dim(spot: CGRect?) -> some View {
        ZStack {
            Rectangle().fill(Color.black.opacity(spot == nil ? 0.42 : 0.62))
            if let spot {
                RoundedRectangle(cornerRadius: 16)
                    .frame(width: spot.width, height: spot.height)
                    .position(x: spot.midX, y: spot.midY)
                    .blendMode(.destinationOut)
            }
        }
        .compositingGroup()
        .overlay {
            if let spot {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.55), lineWidth: 1.5)
                    .frame(width: spot.width, height: spot.height)
                    .position(x: spot.midX, y: spot.midY)
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - The dozent and its bubble

    /// Below the control when it sits in the top half, above it when it sits
    /// in the bottom half, and a third of the way down when there is nothing
    /// to point at.
    @ViewBuilder
    private func bubbleColumn(spot: CGRect?, size: CGSize) -> some View {
        VStack(spacing: 0) {
            if let spot, spot.midY < size.height / 2 {
                Color.clear.frame(height: spot.maxY + 18)
                speech
                Spacer(minLength: 0)
            } else if let spot {
                Spacer(minLength: 0)
                speech
                Color.clear.frame(height: max(size.height - spot.minY + 18, 0))
            } else {
                Color.clear.frame(height: size.height * 0.34)
                speech
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, edge)
        .frame(width: size.width, height: size.height)
    }

    /// The dozent, standing outside the card, speaking it.
    private var speech: some View {
        HStack(alignment: .top, spacing: 12) {
            DozentFace(expression: mark.expression, radius: faceRadius)
                .shadow(color: .black.opacity(0.35), radius: 8, y: 3)
            card
                .overlay(alignment: .topLeading) {
                    // The tail — off the card's left edge, toward the face.
                    SpeechTail()
                        .fill(AtlasColors.secondaryBackground)
                        .frame(width: 9, height: 16)
                        .offset(x: -8, y: faceRadius - 8)
                }
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(mark.title)
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.primaryText)
            Text(mark.message)
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.primaryText)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Spacer(minLength: 0)
                Button(action: advance) {
                    Text(mark.buttonTitle)
                        .font(AtlasTypography.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 17)
                        .frame(height: 32)
                        .background(Capsule().fill(AtlasColors.brass))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 6)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AtlasColors.secondaryBackground)
                .shadow(color: .black.opacity(0.4), radius: 17, y: 10)
        )
    }
}

/// A small left-pointing triangle.
private struct SpeechTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
