//
//  CoachMarkCenter.swift
//  TRAVEL GUIDED TOUR
//
//  Runs the five-stop navigation tour and holds where each control is on
//  screen.
//
//  🔴 The tour is drawn in the BOTTOM-MODULE window, not the main one. That
//  window sits one level above the main window, so only an overlay there can
//  dim the tab bar and cut a hole over it — and over the search bar, filters
//  and drawer, which live in the main window below. The two windows share the
//  scene's coordinate space, so a frame measured `.global` in either one lines
//  up in the other.
//
//  While the tour runs, that window has to take every touch (normally it only
//  takes the strip the bars paint). That claim is DERIVED from `isRunning` —
//  see `TRAVEL_GUIDED_TOURApp.syncBottomModuleVisibility()` — never latched,
//  because a window stuck claiming every touch would leave the whole app dead.
//

import Foundation
import CoreGraphics
import Observation

@MainActor
@Observable
final class CoachMarkCenter {
    private let store: OnboardingStore

    init(store: OnboardingStore) {
        self.store = store
    }

    /// The stop on screen, or `nil` when the tour is not running.
    private(set) var current: CoachMark?

    var isRunning: Bool { current != nil }

    /// Where each control is, in screen coordinates. Written by
    /// `.coachMarkAnchor(_:)`; cleared when the control leaves the screen, so
    /// a stale frame can never cut a hole over empty space.
    private(set) var anchors: [CoachMark: CGRect] = [:]

    // MARK: - Running

    /// Start from the first stop. Called when onboarding closes, and by
    /// Settings → "Show tips again".
    func beginTour() {
        current = CoachMark.tour.first
    }

    /// Move to the next stop, or finish after the last.
    func advance() {
        guard let current else { return }
        store.update { $0.seenCoachMarks.insert(current.rawValue) }
        guard let i = CoachMark.tour.firstIndex(of: current),
              i + 1 < CoachMark.tour.count
        else { return finish() }
        self.current = CoachMark.tour[i + 1]
    }

    /// Step back one stop — a tap on the left third, like the onboarding
    /// cards (owner, 2026-10-06). A no-op on the first stop.
    func back() {
        guard let current,
              let i = CoachMark.tour.firstIndex(of: current), i > 0
        else { return }
        self.current = CoachMark.tour[i - 1]
    }

    /// End the tour and record every stop as seen.
    func finish() {
        store.update { state in
            for mark in CoachMark.tour { state.seenCoachMarks.insert(mark.rawValue) }
        }
        current = nil
    }

    /// Settings → "Show tips again": forget what was seen, then run it again.
    func replay() {
        store.resetCoachMarks()
        beginTour()
    }

    /// Has this install seen every stop?
    var hasSeenAll: Bool {
        CoachMark.tour.allSatisfy { store.state.seenCoachMarks.contains($0.rawValue) }
    }

    // MARK: - Anchors

    func setAnchor(_ mark: CoachMark, _ frame: CGRect) {
        // Ignore empty and non-finite frames: they arrive mid-layout and
        // would put the spotlight in the top-left corner for a frame.
        guard frame.width > 0, frame.height > 0,
              frame.minX.isFinite, frame.minY.isFinite else { return }
        if anchors[mark] != frame { anchors[mark] = frame }
    }

    func clearAnchor(_ mark: CoachMark) {
        anchors[mark] = nil
    }
}
