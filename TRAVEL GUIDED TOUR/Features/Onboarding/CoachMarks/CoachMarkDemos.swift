//
//  CoachMarkDemos.swift
//  TRAVEL GUIDED TOUR
//
//  Two stops show how the thing works, not just where it is (owner,
//  2026-10-25: "should these be animated so that user understands how they
//  operate?"):
//
//  · Filters — a tap lands on one chip, then a second, and both read as on:
//    they stack.
//  · The list — a finger drags the handle up, then down: three heights.
//
//  🔴 Both are DRAWN over the spotlight, in the overlay. Neither touches the
//  real filter or the real drawer — a demonstration that changed the user's
//  filters would leave them filtered after "Got it". Map, search and the bar
//  stay still; moving the real map would lose the user's place.
//
//  Reduce Motion: the filters demo shows its end state still; the drawer demo
//  is not drawn at all (a motionless finger says nothing).
//

import SwiftUI

// MARK: - Filters

struct CoachMarkFiltersDemo: View {
    /// The first two filter chips, where they actually sit on screen.
    let chips: [(title: String, frame: CGRect)]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// How many chips currently read as on.
    @State private var on = 0
    @State private var tapIndex: Int?
    @State private var rippleOut = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(chips.enumerated()), id: \.offset) { i, chip in
                HStack(spacing: AtlasSpacing.sm) {
                    Text(chip.title)
                        .font(AtlasTypography.caption)
                        .lineLimit(1)
                    Image(systemName: "checkmark")
                        .font(AtlasTypography.caption)
                }
                .foregroundStyle(AtlasColors.background)
                .frame(width: chip.frame.width, height: chip.frame.height)
                .background(Capsule().fill(AtlasColors.mapPin))
                .position(x: chip.frame.midX, y: chip.frame.midY)
                .opacity(i < on ? 1 : 0)
            }
            if let i = tapIndex, chips.indices.contains(i) {
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 34, height: 34)
                    .scaleEffect(rippleOut ? 1.7 : 0.6)
                    .opacity(rippleOut ? 0 : 0.95)
                    .position(x: chips[i].frame.midX, y: chips[i].frame.midY)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task { await run() }
    }

    private func run() async {
        guard !chips.isEmpty else { return }
        if reduceMotion {
            on = chips.count
            return
        }
        while !Task.isCancelled {
            for i in chips.indices {
                try? await Task.sleep(for: .milliseconds(650))
                tapIndex = i
                rippleOut = false
                try? await Task.sleep(for: .milliseconds(30))
                withAnimation(.easeOut(duration: 0.45)) { rippleOut = true }
                try? await Task.sleep(for: .milliseconds(160))
                withAnimation(.easeInOut(duration: 0.25)) { on = i + 1 }
            }
            try? await Task.sleep(for: .milliseconds(1_700))
            withAnimation(.easeInOut(duration: 0.35)) { on = 0 }
            tapIndex = nil
            try? await Task.sleep(for: .milliseconds(450))
        }
    }
}

// MARK: - The list

struct CoachMarkDrawerDemo: View {
    /// The lit drawer.
    let spot: CGRect
    /// How far the finger travels each way.
    static let travel: CGFloat = 56
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var offset: CGFloat = 0
    @State private var visible = false

    var body: some View {
        if !reduceMotion {
            ZStack {
                // A ghost of the handle, carried by the finger. Brass, not
                // white: the drawer is white in light mode and a white finger
                // vanished into it.
                Capsule()
                    .fill(AtlasColors.brass)
                    .frame(width: 40, height: 5)
                    .offset(y: -24)
                Circle()
                    .fill(AtlasColors.brass.opacity(0.85))
                    .frame(width: 32, height: 32)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(color: .black.opacity(0.35), radius: 6, y: 2)
            }
            .position(x: spot.midX, y: spot.minY + 30)
            .offset(y: offset)
            .opacity(visible ? 1 : 0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .task { await run() }
        }
    }

    private func run() async {
        let travel = Self.travel
        while !Task.isCancelled {
            withAnimation(.easeOut(duration: 0.25)) { visible = true }
            try? await Task.sleep(for: .milliseconds(350))
            // Up: the full list.
            withAnimation(.easeInOut(duration: 0.7)) { offset = -travel }
            try? await Task.sleep(for: .milliseconds(1_000))
            // Down past where it started: the map comes back.
            withAnimation(.easeInOut(duration: 0.9)) { offset = travel }
            try? await Task.sleep(for: .milliseconds(1_200))
            withAnimation(.easeInOut(duration: 0.5)) { offset = 0 }
            try? await Task.sleep(for: .milliseconds(600))
            withAnimation(.easeIn(duration: 0.25)) { visible = false }
            try? await Task.sleep(for: .milliseconds(700))
        }
    }
}
