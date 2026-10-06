//
//  OnboardingCoordinator.swift
//  TRAVEL GUIDED TOUR
//
//  Owns whether onboarding is on screen and which step it is on.
//
//  Built in the App's `init()` alongside `AuthService`, because one value it
//  publishes — `willPresentWelcome` — has to be settled BEFORE any view runs.
//  `ContentView`'s location-permission guard reads it, and that `.onChange`
//  fires before `begin()` does; a live check there would still let the system
//  alert land over the first card.
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class OnboardingCoordinator {
    private let store: OnboardingStore

    /// Resolved once, in App `init`, from the store as it was at launch.
    /// 🔴 Do not recompute this. See the file comment.
    let willPresentWelcome: Bool

    /// True while any onboarding card is on screen.
    private(set) var isCovering = false

    /// Set by the first `begin()` of this process.
    private(set) var hasBegun = false

    /// Should the bottom module (mini-player + tab bar) be withdrawn?
    ///
    /// 🔴 That module lives in its OWN `UIWindow`, one level ABOVE the main
    /// window, so it paints over anything the main window draws — onboarding
    /// included. Build 179 shipped without this and the bars sat on top of
    /// the first card, covering Continue: the flow could not be advanced.
    ///
    /// Also true in the gap between the splash handing off and `begin()`
    /// running, so the bars do not flash in and straight back out. That gap
    /// is a single synchronous step in `runLaunchGate` — `beginIfNeeded()` is
    /// the very next line after the hand-off — so this cannot strand the bars
    /// hidden (the failure this app has shipped three times).
    var holdsBottomModule: Bool {
        isCovering || (willPresentWelcome && !hasBegun)
    }

    /// The steps for the run in progress.
    private(set) var steps: [OnboardingStep] = []
    private(set) var index = 0

    /// True when this run was started from Settings rather than by a cold
    /// launch. The account screens are dropped — see `OnboardingFlow.steps`.
    private(set) var isReplay = false

    /// Runs in the SAME call that closes the flow — the App wires it to start
    /// the navigation tour.
    ///
    /// 🔴 Deliberately a synchronous hand-off, not an `.onChange` on
    /// `isCovering`. Done as two separate updates, there was a moment where
    /// neither onboarding nor the tour was on screen, and `ContentView` —
    /// which asks for location the instant first run is over — would put the
    /// system alert on top of the tour's first stop.
    var onFinish: (@MainActor () -> Void)?

    /// Set when the user takes Apple or Google on screen 5, which shortens the
    /// form on screen 6 to the one thing a provider cannot give us.
    var usedProvider = false

    init(store: OnboardingStore) {
        self.store = store
        self.willPresentWelcome = store.shouldPresentOnLaunch
        self.state = store.state
    }

    var currentStep: OnboardingStep? {
        guard steps.indices.contains(index) else { return nil }
        return steps[index]
    }

    /// The answers so far — an OBSERVED copy of the store's.
    ///
    /// 🔴 Must be stored here, not computed from `store.state`. The store is
    /// a plain class, so reading through it records no dependency: build 181
    /// saved every tap on screens 8, 10, 12, 16 and 18 and never redrew one,
    /// so no row or chip could be seen to select. Every write goes through
    /// `update`, which re-syncs this copy.
    private(set) var state: OnboardingState

    func update(_ mutate: (inout OnboardingState) -> Void) {
        store.update(mutate)
        state = store.state
    }

    // MARK: - Running

    /// Present the flow from the top. Called after the launch hand-off, and
    /// again from Settings when the user asks for the tour.
    func begin(replaying: Bool = false) {
        hasBegun = true
        isReplay = replaying
        usedProvider = false
        steps = OnboardingFlow.steps(replaying: replaying)
        index = 0
        isCovering = true
    }

    /// Present the flow only if this install has never finished it.
    /// Returns `true` if it is now on screen.
    @discardableResult
    func beginIfNeeded() -> Bool {
        guard willPresentWelcome else { return false }
        begin()
        return true
    }

    func advance() {
        guard index + 1 < steps.count else { return finish() }
        index += 1
    }

    /// Can the user step back from here? Only between two screens that carry
    /// the progress bar — never back onto screen 2, which is the splash's own
    /// face-appearing moment rather than a card anyone chose to be on.
    var canGoBack: Bool {
        guard index > 0, let step = currentStep else { return false }
        let bar = OnboardingStep.progressBarSteps
        return bar.contains(step) && bar.contains(steps[index - 1])
    }

    func back() {
        guard canGoBack else { return }
        index -= 1
        // Back onto "First, an account" after skipping it: put the provider
        // and form screens back, so changing your mind leads to them again.
        if currentStep == .accountAsk {
            let full = OnboardingFlow.steps(replaying: isReplay)
            if let at = full.firstIndex(of: .accountAsk) {
                steps = full
                index = at
            }
        }
    }

    /// "Skip" on the account screens (owner, 2026-10-06): skips signing up,
    /// NOT the rest of onboarding. The questions are stored on the device and
    /// need no account, so the run carries on at "Welcome", which already
    /// reads without a name.
    ///
    /// The provider and form screens leave this run, so the bar keeps one
    /// segment per screen actually shown. "First, an account" stays, so back
    /// from Welcome returns to where the choice was made — see `back()`.
    func skipAccount() {
        guard let from = currentStep else { return }
        steps.removeAll { $0 == .accountProviders || $0 == .accountForm }
        usedProvider = false
        if let next = steps.firstIndex(of: .welcomeByName) {
            index = next
        } else if let stay = steps.firstIndex(of: from) {
            index = stay
        }
    }

    /// Leave the flow. Marks it complete so it never reappears — including
    /// when the user skipped out of it, because someone who skipped has made a
    /// decision and re-asking on the next launch is nagging.
    func finish() {
        isCovering = false
        steps = []
        index = 0
        store.markCompleted()
        state = store.state
        onFinish?()
    }

    /// Settings → "Show tips again". Clears only the coach-mark record.
    func resetCoachMarks() {
        store.resetCoachMarks()
        state = store.state
    }

    // MARK: - Progress

    /// The steps in THIS run that carry the bar. A replay drops the account
    /// screens, so its bar is shorter — one segment per screen shown, never a
    /// segment for a screen that will not appear.
    var progressSteps: [OnboardingStep] {
        steps.filter { OnboardingStep.progressBarSteps.contains($0) }
    }

    /// Segments in this run's bar.
    var progressCount: Int { progressSteps.count }

    /// Which segment is current, or `nil` on a step the bar skips.
    var progressIndex: Int? {
        guard let step = currentStep else { return nil }
        return progressSteps.firstIndex(of: step)
    }
}
