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

    /// The steps for the run in progress.
    private(set) var steps: [OnboardingStep] = []
    private(set) var index = 0

    /// True when this run was started from Settings rather than by a cold
    /// launch. The account screens are dropped — see `OnboardingFlow.steps`.
    private(set) var isReplay = false

    /// Set when the user takes Apple or Google on screen 5, which shortens the
    /// form on screen 6 to the one thing a provider cannot give us.
    var usedProvider = false

    init(store: OnboardingStore) {
        self.store = store
        self.willPresentWelcome = store.shouldPresentOnLaunch
    }

    var currentStep: OnboardingStep? {
        guard steps.indices.contains(index) else { return nil }
        return steps[index]
    }

    var state: OnboardingState { store.state }

    func update(_ mutate: (inout OnboardingState) -> Void) { store.update(mutate) }

    // MARK: - Running

    /// Present the flow from the top. Called after the launch hand-off, and
    /// again from Settings when the user asks for the tour.
    func begin(replaying: Bool = false) {
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

    func back() {
        guard index > 0 else { return }
        index -= 1
    }

    /// Leave the flow. Marks it complete so it never reappears — including
    /// when the user skipped out of it, because someone who skipped has made a
    /// decision and re-asking on the next launch is nagging.
    func finish() {
        isCovering = false
        steps = []
        index = 0
        store.markCompleted()
    }

    /// Settings → "Show tips again". Clears only the coach-mark record.
    func resetCoachMarks() { store.resetCoachMarks() }

    // MARK: - Progress

    /// Which Reels segment is filling, or `nil` on a step the bar skips.
    var progressIndex: Int? {
        guard let step = currentStep else { return nil }
        return OnboardingFlow.progressIndex(of: step)
    }
}
