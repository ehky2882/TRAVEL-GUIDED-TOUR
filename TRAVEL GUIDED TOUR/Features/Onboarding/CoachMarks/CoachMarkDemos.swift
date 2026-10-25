//
//  CoachMarkDemos.swift
//  TRAVEL GUIDED TOUR
//
//  Two stops show how the thing works, not just where it is (owner,
//  2026-10-25: "should these be animated so that user understands how they
//  operate?"):
//
//  · Filters — a tap lands on one chip, then a second, and both read as on:
//    they stack. Then a swipe slides the row sideways to show there are more
//    (owner, 2026-10-25: "add to the animation that it is sideways-scrollable").
//    That swipe moves the REAL row — by an offset only (`filterRowNudge`), so
//    no filter and no scroll position changes.
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
    /// The lit filter row.
    let row: CGRect
    /// Slides the real row by this much (0 = at rest).
    let nudge: (CGFloat) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// How many chips currently read as on.
    @State private var on = 0
    @State private var tapIndex: Int?
    @State private var rippleOut = false
    /// The swipe's finger: shown, and how far it has travelled left.
    @State private var swiping = false
    @State private var swipeX: CGFloat = 0

    /// How far the swipe slides the row.
    private static let swipeTravel: CGFloat = 150

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
            Circle()
                .fill(AtlasColors.brass.opacity(0.85))
                .frame(width: 32, height: 32)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .shadow(color: .black.opacity(0.35), radius: 6, y: 2)
                .position(x: row.maxX - 70 + swipeX, y: row.midY)
                .opacity(swiping ? 1 : 0)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task { await run() }
        // Never leave the real row slid over when the stop ends.
        .onDisappear { nudge(0) }
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

            // Sideways: the finger slides left and the row goes with it.
            let travel = Self.swipeTravel
            withAnimation(.easeOut(duration: 0.2)) { swiping = true }
            try? await Task.sleep(for: .milliseconds(250))
            withAnimation(.easeInOut(duration: 0.8)) {
                swipeX = -travel
                nudge(-travel)
            }
            try? await Task.sleep(for: .milliseconds(1_300))
            withAnimation(.easeInOut(duration: 0.6)) {
                swipeX = 0
                nudge(0)
            }
            withAnimation(.easeIn(duration: 0.3).delay(0.3)) { swiping = false }
            try? await Task.sleep(for: .milliseconds(900))
        }
    }
}

// MARK: - A finger

/// The brass finger every demonstration uses. Brass, not white: the drawer is
/// white in light mode and a white finger vanished into it.
private struct DemoFinger: View {
    var carriesHandle = false

    var body: some View {
        ZStack {
            if carriesHandle {
                Capsule()
                    .fill(AtlasColors.brass)
                    .frame(width: 40, height: 5)
                    .offset(y: -24)
            }
            Circle()
                .fill(AtlasColors.brass.opacity(0.85))
                .frame(width: 32, height: 32)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .shadow(color: .black.opacity(0.35), radius: 6, y: 2)
        }
    }
}

// MARK: - The list

/// Three things the list does: drag its handle (three heights), swipe a
/// carousel sideways, scroll the list up. The last two move the REAL content
/// by an offset (`CoachMarkCenter.listNudge`) — owner, 2026-10-25: "can you
/// actually scroll sideways on the carousel and up the content?"
struct CoachMarkDrawerDemo: View {
    /// The lit drawer, as it was when the stop opened (mid-height).
    let spot: CGRect
    /// The bar, for where the drawer's smallest height sits.
    let bar: CGRect
    /// Slides the real first carousel (`width`) and list (`height`).
    let nudge: (CGSize) -> Void
    /// Moves the REAL drawer between its heights — owner, 2026-10-25: "this
    /// should actually show the ability for the drawer to go up and down".
    let setDrawer: (BottomSheetDetent?) -> Void
    /// How far the handle finger travels each way.
    static let travel: CGFloat = 56
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var finger: CGPoint = .zero
    @State private var carriesHandle = true
    @State private var visible = false

    var body: some View {
        if !reduceMotion {
            DemoFinger(carriesHandle: carriesHandle)
                .position(x: spot.midX + finger.x, y: spot.minY + 30 + finger.y)
                .opacity(visible ? 1 : 0)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                .task { await run() }
                .onDisappear {
                    nudge(.zero)
                    setDrawer(.medium)
                    setDrawer(nil)
                }
        }
    }

    /// How far the handle travels to the drawer's full and smallest heights.
    /// Full stops just under the filter row (`topReservedHeight` in
    /// `ContentView`); smallest shows 80pt above the bar (its peekHeight).
    private var upTravel: CGFloat { -max(0, spot.minY - 180) }
    private var downTravel: CGFloat { max(0, (bar.minY - 80) - spot.minY) }

    private func move(_ to: CGPoint, _ seconds: Double) {
        withAnimation(.easeInOut(duration: seconds)) { finger = to }
    }

    private func pause(_ ms: Int) async {
        try? await Task.sleep(for: .milliseconds(ms))
    }

    private func run() async {
        // Where the first carousel's cards sit, and the list below them.
        let cards: CGFloat = min(170, spot.height * 0.35)
        while !Task.isCancelled {
            // 1 · The handle: the real drawer goes up for the full list,
            // down for the map, and back to the middle.
            finger = .zero
            carriesHandle = true
            withAnimation(.easeOut(duration: 0.25)) { visible = true }
            await pause(350)
            move(CGPoint(x: 0, y: upTravel), 0.7);   setDrawer(.large);  await pause(1_300)
            move(CGPoint(x: 0, y: downTravel), 0.7); setDrawer(.peek);   await pause(1_300)
            move(.zero, 0.7);                        setDrawer(.medium); await pause(900)
            withAnimation(.easeIn(duration: 0.2)) { visible = false }
            await pause(400)

            // 2 · A carousel scrolls sideways.
            carriesHandle = false
            finger = CGPoint(x: 90, y: cards)
            withAnimation(.easeOut(duration: 0.2)) { visible = true }
            await pause(300)
            withAnimation(.easeInOut(duration: 0.8)) {
                finger = CGPoint(x: -90, y: cards)
                nudge(CGSize(width: -180, height: 0))
            }
            await pause(1_200)
            withAnimation(.easeInOut(duration: 0.6)) {
                finger = CGPoint(x: 90, y: cards)
                nudge(.zero)
            }
            await pause(700)
            withAnimation(.easeIn(duration: 0.2)) { visible = false }
            await pause(400)

            // 3 · The list scrolls up.
            finger = CGPoint(x: 0, y: cards + 120)
            withAnimation(.easeOut(duration: 0.2)) { visible = true }
            await pause(300)
            withAnimation(.easeInOut(duration: 0.8)) {
                finger = CGPoint(x: 0, y: cards - 20)
                nudge(CGSize(width: 0, height: -140))
            }
            await pause(1_200)
            withAnimation(.easeInOut(duration: 0.6)) {
                finger = CGPoint(x: 0, y: cards + 120)
                nudge(.zero)
            }
            await pause(700)
            withAnimation(.easeIn(duration: 0.2)) { visible = false }
            await pause(900)
        }
    }
}

// MARK: - The map

/// The map stop lowers the REAL drawer to its smallest and raises it again —
/// owner, 2026-10-25: "can you actually show that the drawer can be
/// minimized?" A finger rides the handle down and back.
struct CoachMarkMapDemo: View {
    /// Where the drawer and the bar sit when the stop opens.
    let drawer: CGRect
    let bar: CGRect
    /// Sets the real drawer's detent; `nil` hands it back.
    let setDrawer: (BottomSheetDetent?) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var down = false
    @State private var visible = false

    /// The peeking drawer shows 80pt above the bar (`ContentView`'s peekHeight).
    private var drop: CGFloat { max(0, (bar.minY - 80) - drawer.minY) }

    var body: some View {
        if !reduceMotion {
            DemoFinger(carriesHandle: true)
                .position(x: drawer.midX, y: drawer.minY + 30 + (down ? drop : 0))
                .opacity(visible ? 1 : 0)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                .task { await run() }
                .onDisappear {
                    setDrawer(.medium)
                    setDrawer(nil)
                }
        }
    }

    private func run() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(900))
            withAnimation(.easeOut(duration: 0.25)) { visible = true }
            try? await Task.sleep(for: .milliseconds(350))
            // Down: the drawer gets out of the way, the whole map shows.
            withAnimation(.easeInOut(duration: 0.7)) { down = true }
            setDrawer(.peek)
            try? await Task.sleep(for: .milliseconds(1_800))
            // And back up.
            withAnimation(.easeInOut(duration: 0.7)) { down = false }
            setDrawer(.medium)
            try? await Task.sleep(for: .milliseconds(900))
            withAnimation(.easeIn(duration: 0.25)) { visible = false }
            try? await Task.sleep(for: .milliseconds(900))
        }
    }
}

// MARK: - The bar

/// The bar stop taps Library, then Me, then Home — and the real pages switch
/// underneath (owner, 2026-10-25: "actually show the different tabs pages").
/// Always ends on Home, where the rest of the tour points.
struct CoachMarkBarDemo: View {
    /// The lit bottom module: mini-player above, three tabs below.
    let bar: CGRect
    let setTab: (AtlasTab?) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var at: AtlasTab = .home
    @State private var visible = false
    @State private var rippleOut = false

    /// Where a tab's icon sits: three equal columns along the bottom row.
    private func point(_ tab: AtlasTab) -> CGPoint {
        let column: CGFloat = switch tab {
        case .home: 0.5
        case .library: 1.5
        case .me: 2.5
        }
        return CGPoint(x: bar.minX + bar.width * column / 3, y: bar.maxY - 50)
    }

    var body: some View {
        if !reduceMotion {
            ZStack {
                Circle()
                    .stroke(AtlasColors.brass, lineWidth: 2)
                    .frame(width: 34, height: 34)
                    .scaleEffect(rippleOut ? 1.8 : 0.8)
                    .opacity(rippleOut ? 0 : 0.9)
                DemoFinger()
            }
            .position(point(at))
            .opacity(visible ? 1 : 0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .task { await run() }
            .onDisappear {
                setTab(.home)
                setTab(nil)
            }
        }
    }

    private func tap(_ tab: AtlasTab) async {
        withAnimation(.easeInOut(duration: 0.5)) { at = tab }
        try? await Task.sleep(for: .milliseconds(550))
        rippleOut = false
        try? await Task.sleep(for: .milliseconds(30))
        withAnimation(.easeOut(duration: 0.4)) { rippleOut = true }
        setTab(tab)
    }

    private func run() async {
        while !Task.isCancelled {
            at = .home
            try? await Task.sleep(for: .milliseconds(700))
            withAnimation(.easeOut(duration: 0.25)) { visible = true }
            try? await Task.sleep(for: .milliseconds(300))
            await tap(.library)
            try? await Task.sleep(for: .milliseconds(1_500))
            await tap(.me)
            try? await Task.sleep(for: .milliseconds(1_500))
            await tap(.home)
            try? await Task.sleep(for: .milliseconds(900))
            withAnimation(.easeIn(duration: 0.25)) { visible = false }
            try? await Task.sleep(for: .milliseconds(900))
        }
    }
}
