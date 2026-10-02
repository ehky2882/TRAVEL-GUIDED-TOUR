//
//  OnboardingStore.swift
//  TRAVEL GUIDED TOUR
//
//  What the first run remembers: that it happened, and what the user answered.
//
//  One Codable blob under a single `UserDefaults` key, in the shape
//  `LibraryStore` and `ProfileSnapshotStore` already use, with an injectable
//  `UserDefaults` so the lifecycle is testable without touching the real
//  defaults.
//
//  🔴 LOCAL, NOT SYNCED — on purpose. Onboarding runs before any sign-in, so a
//  sync-only design would lose every anonymous user's answers. And
//  `SyncService.handleSignedOut()` wipes local stores, which would make
//  signing out re-trigger first run.
//

import Foundation

/// Everything the first run leaves behind.
struct OnboardingState: Codable, Equatable, Sendable {
    /// The `OnboardingFlow.currentVersion` the user completed, or `nil` if they
    /// never finished one.
    var completedVersion: Int?
    /// Their first name, from screen 6 (or handed back by Apple/Google).
    /// Screen 7 greets them with it; empty means the greeting drops the name.
    var firstName: String = ""
    var lastName: String = ""
    /// Typed on screen 6. **Not** the GPS permission — this is profile data,
    /// and it is what makes "explore my city" work for someone currently
    /// abroad.
    var homeCity: String = ""
    /// Screen 8 — the situations they picked.
    var uses: Set<String> = []
    /// Screen 10 — audio, video, short, long.
    var formats: Set<String> = []
    /// Screen 12 — real catalogue tags, so every pick can promote something.
    var interests: Set<String> = []
    /// Screen 16 — what they would use a list for.
    var listUses: Set<String> = []
    /// Screen 18 — browsing, or ready to create.
    var makerIntent: String?
    /// Coach marks already shown. Phase 3 reads this; nothing writes it yet.
    var seenCoachMarks: Set<String> = []
}

/// Reads and writes `OnboardingState`.
@MainActor
final class OnboardingStore {
    private let defaults: UserDefaults
    private let key = "onboarding.state"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private(set) lazy var state: OnboardingState = load()

    /// Has this install finished the current version of the flow?
    var hasCompletedCurrentVersion: Bool {
        guard let completed = state.completedVersion else { return false }
        return completed >= OnboardingFlow.currentVersion
    }

    /// Should a cold launch present onboarding?
    ///
    /// ⚠️ Resolved ONCE, in the App's `init` — see `OnboardingCoordinator`.
    /// Reading live state later is wrong: `ContentView`'s permission guard
    /// fires before `begin()` runs, so it would let the system alert land over
    /// the first card.
    var shouldPresentOnLaunch: Bool {
        // 🔴 `ScreenshotUITests` passes `-UITestSkipOnboarding`; without this
        // every App Store screenshot would be of the welcome carousel.
        if UITestSupport.shouldSkipOnboarding { return false }
        return !hasCompletedCurrentVersion
    }

    func update(_ mutate: (inout OnboardingState) -> Void) {
        var copy = state
        mutate(&copy)
        state = copy
        save()
    }

    /// Mark the flow finished at the current version.
    func markCompleted() {
        update { $0.completedVersion = OnboardingFlow.currentVersion }
    }

    /// Clear only the coach-mark record — Settings → "Show tips again".
    /// Deliberately does not touch `completedVersion` or the answers.
    func resetCoachMarks() {
        update { $0.seenCoachMarks = [] }
    }

    /// Wipe everything, so the next launch is a first launch. Not wired to any
    /// UI; useful in tests and for a debug build.
    func resetAll() {
        state = OnboardingState()
        defaults.removeObject(forKey: key)
    }

    // MARK: - Persistence

    private func load() -> OnboardingState {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(OnboardingState.self, from: data)
        else { return OnboardingState() }
        return decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: key)
    }
}
