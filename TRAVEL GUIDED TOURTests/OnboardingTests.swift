//
//  OnboardingTests.swift
//  TRAVEL GUIDED TOURTests
//
//  The parts of first run that are pure: the flag lifecycle, the replay reset,
//  and the flow's ordering + progress arithmetic.
//
//  The views are not tested here — they are judged on device, which is the
//  whole reason the canvas exists.
//

import XCTest
@testable import TRAVEL_GUIDED_TOUR

@MainActor
final class OnboardingStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "onboarding.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testFreshInstallPresentsOnboarding() {
        let store = OnboardingStore(defaults: defaults)
        XCTAssertFalse(store.hasCompletedCurrentVersion)
        XCTAssertTrue(store.shouldPresentOnLaunch)
    }

    func testCompletingHidesItOnTheNextLaunch() {
        OnboardingStore(defaults: defaults).markCompleted()
        // A second store over the same defaults is the next launch.
        let relaunched = OnboardingStore(defaults: defaults)
        XCTAssertTrue(relaunched.hasCompletedCurrentVersion)
        XCTAssertFalse(relaunched.shouldPresentOnLaunch)
    }

    func testAnswersSurviveRelaunch() {
        let store = OnboardingStore(defaults: defaults)
        store.update {
            $0.firstName = "Edward"
            $0.homeCity = "New York"
            $0.interests = ["History", "Architecture"]
            $0.makerIntent = "browsing"
        }
        let relaunched = OnboardingStore(defaults: defaults)
        XCTAssertEqual(relaunched.state.firstName, "Edward")
        XCTAssertEqual(relaunched.state.homeCity, "New York")
        XCTAssertEqual(relaunched.state.interests, ["History", "Architecture"])
        XCTAssertEqual(relaunched.state.makerIntent, "browsing")
    }

    /// "Show tips again" must reset ONLY the coach marks. If it cleared the
    /// completion flag the user would be handed the whole twenty-screen run
    /// again, having asked for a tooltip.
    func testResetCoachMarksLeavesCompletionAndAnswersAlone() {
        let store = OnboardingStore(defaults: defaults)
        store.update {
            $0.seenCoachMarks = ["map", "search"]
            $0.firstName = "Edward"
        }
        store.markCompleted()

        store.resetCoachMarks()

        XCTAssertTrue(store.state.seenCoachMarks.isEmpty)
        XCTAssertTrue(store.hasCompletedCurrentVersion)
        XCTAssertEqual(store.state.firstName, "Edward")
    }

    func testResetAllReturnsToFirstLaunch() {
        let store = OnboardingStore(defaults: defaults)
        store.update { $0.firstName = "Edward" }
        store.markCompleted()

        store.resetAll()

        XCTAssertFalse(store.hasCompletedCurrentVersion)
        XCTAssertEqual(store.state.firstName, "")
        XCTAssertFalse(OnboardingStore(defaults: defaults).hasCompletedCurrentVersion)
    }

    /// Bumping `currentVersion` is the whole re-onboarding mechanism, so a
    /// completion recorded at an older version must not satisfy the current one.
    func testAnOlderCompletedVersionDoesNotCount() {
        let store = OnboardingStore(defaults: defaults)
        store.update { $0.completedVersion = OnboardingFlow.currentVersion - 1 }
        XCTAssertFalse(store.hasCompletedCurrentVersion)
    }
}

@MainActor
final class OnboardingFlowTests: XCTestCase {
    func testStepsRunInDrawnOrder() {
        let steps = OnboardingFlow.steps(replaying: false)
        XCTAssertEqual(steps.first, .faceAppears)
        XCTAssertEqual(steps.last, .questionMakerIntent)
        XCTAssertEqual(steps, steps.sorted { $0.rawValue < $1.rawValue })
    }

    /// A replay must not re-ask for an account: they have one, or they decided
    /// not to, and asking again is nagging.
    func testReplaySkipsTheAccountScreens() {
        let steps = OnboardingFlow.steps(replaying: true)
        XCTAssertFalse(steps.contains(.accountAsk))
        XCTAssertFalse(steps.contains(.accountProviders))
        XCTAssertFalse(steps.contains(.accountForm))
        XCTAssertTrue(steps.contains(.definition))
        XCTAssertTrue(steps.contains(.questionInterests))
    }

    /// The bar covers 3–18 and nothing else: not the splash handing off, and
    /// not the real app afterwards.
    func testProgressBarCoversOnlyTheRun() {
        XCTAssertNil(OnboardingFlow.progressIndex(of: .faceAppears))
        XCTAssertEqual(OnboardingFlow.progressIndex(of: .definition), 0)
        XCTAssertEqual(
            OnboardingFlow.progressIndex(of: .questionMakerIntent),
            OnboardingFlow.progressSegmentCount - 1
        )
        XCTAssertEqual(OnboardingFlow.progressSegmentCount, 16)
    }

    func testProgressIndexIsMonotonic() {
        let indices = OnboardingStep.progressBarSteps.compactMap(OnboardingFlow.progressIndex(of:))
        XCTAssertEqual(indices, Array(0..<OnboardingFlow.progressSegmentCount))
    }
}

@MainActor
final class OnboardingCoordinatorTests: XCTestCase {
    private func makeCoordinator() -> (OnboardingCoordinator, UserDefaults, String) {
        let suite = "onboarding.coordinator.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        return (OnboardingCoordinator(store: OnboardingStore(defaults: defaults)), defaults, suite)
    }

    func testAdvancingToTheEndFinishesAndRecordsCompletion() {
        let (coordinator, defaults, suite) = makeCoordinator()
        defer { defaults.removePersistentDomain(forName: suite) }

        coordinator.begin()
        XCTAssertTrue(coordinator.isCovering)
        for _ in 0..<(OnboardingFlow.steps(replaying: false).count + 2) { coordinator.advance() }

        XCTAssertFalse(coordinator.isCovering)
        XCTAssertTrue(OnboardingStore(defaults: defaults).hasCompletedCurrentVersion)
    }

    /// Skipping out is a decision, not an interruption — it must not reappear
    /// on the next launch.
    func testFinishingEarlyStillCounts() {
        let (coordinator, defaults, suite) = makeCoordinator()
        defer { defaults.removePersistentDomain(forName: suite) }

        coordinator.begin()
        coordinator.finish()

        XCTAssertFalse(coordinator.isCovering)
        XCTAssertTrue(OnboardingStore(defaults: defaults).hasCompletedCurrentVersion)
    }

    func testBeginIfNeededIsANoOpOnceCompleted() {
        let (coordinator, defaults, suite) = makeCoordinator()
        defer { defaults.removePersistentDomain(forName: suite) }

        coordinator.begin()
        coordinator.finish()

        // `willPresentWelcome` is resolved at init, so a fresh coordinator is
        // the honest stand-in for the next launch.
        let relaunched = OnboardingCoordinator(store: OnboardingStore(defaults: defaults))
        XCTAssertFalse(relaunched.willPresentWelcome)
        XCTAssertFalse(relaunched.beginIfNeeded())
        XCTAssertFalse(relaunched.isCovering)
    }

    func testBackStopsAtTheFirstCard() {
        let (coordinator, defaults, suite) = makeCoordinator()
        defer { defaults.removePersistentDomain(forName: suite) }

        coordinator.begin()
        coordinator.back()
        XCTAssertEqual(coordinator.index, 0)
        XCTAssertEqual(coordinator.currentStep, .faceAppears)
    }

    /// 🔴 Build 179: the bars' window sits ABOVE the main window, so it painted
    /// over the first card and covered Continue — the flow could not advance.
    /// The hold must cover the whole run, and release when it closes.
    func testFirstRunWithdrawsTheBottomModuleUntilItCloses() {
        let (coordinator, defaults, suite) = makeCoordinator()
        defer { defaults.removePersistentDomain(forName: suite) }

        // Between the splash handing off and `begin()` — no flash of bars.
        XCTAssertTrue(coordinator.holdsBottomModule)
        coordinator.begin()
        XCTAssertTrue(coordinator.holdsBottomModule)
        coordinator.finish()
        XCTAssertFalse(coordinator.holdsBottomModule)
    }

    /// The failure this app has shipped three times is the bars going missing
    /// for a whole session. An install that has finished onboarding must
    /// never hold them, not even for an instant.
    func testACompletedInstallNeverWithdrawsTheBottomModule() {
        let (first, defaults, suite) = makeCoordinator()
        defer { defaults.removePersistentDomain(forName: suite) }
        first.begin()
        first.finish()

        let relaunched = OnboardingCoordinator(store: OnboardingStore(defaults: defaults))
        XCTAssertFalse(relaunched.holdsBottomModule)
    }

    /// A replay from Settings must hold them too, and give them back.
    func testReplayWithdrawsAndRestoresTheBottomModule() {
        let (first, defaults, suite) = makeCoordinator()
        defer { defaults.removePersistentDomain(forName: suite) }
        first.begin()
        first.finish()

        let relaunched = OnboardingCoordinator(store: OnboardingStore(defaults: defaults))
        relaunched.begin(replaying: true)
        XCTAssertTrue(relaunched.holdsBottomModule)
        relaunched.finish()
        XCTAssertFalse(relaunched.holdsBottomModule)
    }

    /// Owner on build 180: *"just have as many counts as there are screens."*
    /// A replay shows 13 of them, so its bar must have 13 segments — not 16
    /// with three that could never fill.
    func testTheBarHasOneSegmentPerScreenInThisRun() {
        let (coordinator, defaults, suite) = makeCoordinator()
        defer { defaults.removePersistentDomain(forName: suite) }

        coordinator.begin()
        XCTAssertEqual(coordinator.progressCount, 16)

        coordinator.begin(replaying: true)
        XCTAssertEqual(coordinator.progressCount, 13)

        // Walk the replay: the index runs 0…12 with no gaps, and the last
        // screen fills the last segment.
        var seen: [Int] = []
        while coordinator.isCovering {
            if let i = coordinator.progressIndex { seen.append(i) }
            coordinator.advance()
        }
        XCTAssertEqual(seen, Array(0..<13))
    }

    func testReplayDropsTheAccountScreens() {
        let (coordinator, defaults, suite) = makeCoordinator()
        defer { defaults.removePersistentDomain(forName: suite) }

        coordinator.begin(replaying: true)
        XCTAssertTrue(coordinator.isReplay)
        XCTAssertFalse(coordinator.steps.contains(.accountForm))
    }
}

/// Screen 12's chips promise that every pick can promote something, which is
/// only true while they are real catalogue tags.
final class OnboardingInterestsTests: XCTestCase {
    func testInterestTagsAreUniqueAndNonEmpty() {
        let tags = OnboardingInterests.all.map(\.tag)
        XCTAssertEqual(Set(tags).count, tags.count, "a tag is listed twice")
        XCTAssertFalse(tags.contains(where: \.isEmpty))
        XCTAssertFalse(OnboardingInterests.all.map(\.label).contains(where: \.isEmpty))
    }

    /// Every chip must name a tag the catalogue's own controlled vocabulary
    /// knows about — otherwise it filters to nothing and reads as broken.
    func testEveryInterestIsAKnownTag() {
        let vocabulary = Set(Tag.vocabulary.flatMap { $0.tags })
        for interest in OnboardingInterests.all {
            XCTAssertTrue(
                vocabulary.contains(interest.tag),
                "\(interest.tag) is not in Tag.vocabulary — screen 12 would filter to nothing"
            )
        }
    }
}

// MARK: - The navigation tour

@MainActor
final class CoachMarkCenterTests: XCTestCase {
    private func makeCenter() -> (CoachMarkCenter, OnboardingStore, UserDefaults, String) {
        let suite = "coachmarks.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let store = OnboardingStore(defaults: defaults)
        return (CoachMarkCenter(store: store), store, defaults, suite)
    }

    /// Owner's order, 2026-09-22: "1. map 2. search bar 3. filters 4. drawer
    /// 5. tab bar".
    func testTheStopsRunInTheOwnersOrder() {
        let (center, _, defaults, suite) = makeCenter()
        defer { defaults.removePersistentDomain(forName: suite) }

        var seen: [CoachMark] = []
        center.beginTour()
        while let mark = center.current {
            seen.append(mark)
            center.advance()
        }
        XCTAssertEqual(seen, [.map, .search, .filters, .drawer, .tabBar])
        XCTAssertFalse(center.isRunning)
        XCTAssertTrue(center.hasSeenAll)
    }

    func testOnlyTheLastStopSaysGotIt() {
        XCTAssertEqual(CoachMark.tabBar.buttonTitle, "Got it")
        for mark in CoachMark.tour.dropLast() {
            XCTAssertEqual(mark.buttonTitle, "Next")
        }
    }

    /// The map IS the screen, so it is the one stop with nothing to cut out.
    func testOnlyTheMapHasNoSpotlight() {
        XCTAssertFalse(CoachMark.map.hasSpotlight)
        for mark in CoachMark.tour where mark != .map {
            XCTAssertTrue(mark.hasSpotlight)
        }
    }

    /// Settings → "Show tips again" must actually run the tour again, not just
    /// clear a flag that nothing reads.
    func testReplayForgetsAndRestarts() {
        let (center, _, defaults, suite) = makeCenter()
        defer { defaults.removePersistentDomain(forName: suite) }

        center.beginTour()
        center.finish()
        XCTAssertTrue(center.hasSeenAll)

        center.replay()
        XCTAssertEqual(center.current, .map)
        XCTAssertFalse(center.hasSeenAll)
    }

    /// Mid-layout frames arrive empty; one would put the spotlight in the
    /// top-left corner for a frame.
    func testEmptyFramesAreIgnored() {
        let (center, _, defaults, suite) = makeCenter()
        defer { defaults.removePersistentDomain(forName: suite) }

        center.setAnchor(.search, .zero)
        XCTAssertNil(center.anchors[.search])
        center.setAnchor(.search, CGRect(x: 8, y: 67, width: 377, height: 44))
        XCTAssertNotNil(center.anchors[.search])
        center.clearAnchor(.search)
        XCTAssertNil(center.anchors[.search])
    }

    /// The hand-off from onboarding to the tour happens in the SAME call.
    /// Done as two updates there was a moment where neither was on screen, and
    /// the location prompt would have landed on the tour's first stop.
    func testClosingOnboardingStartsTheTourInTheSameCall() {
        let suite = "handoff.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = OnboardingStore(defaults: defaults)
        let onboarding = OnboardingCoordinator(store: store)
        let center = CoachMarkCenter(store: store)
        onboarding.onFinish = { center.beginTour() }

        onboarding.begin()
        onboarding.finish()

        XCTAssertFalse(onboarding.isCovering)
        XCTAssertTrue(center.isRunning, "no gap between onboarding and the tour")
    }
}

#if canImport(UIKit)
/// 🔴 The tour's overlay lives in the bars' window, which normally takes only
/// the strip the bars paint. While the tour is up it must take every touch —
/// and the moment it ends, give them all back. Stuck on, the whole app is dead.
final class PassThroughWindowClaimTests: XCTestCase {
    private let height: CGFloat = 852
    private let strip: CGFloat = 126

    func testOrdinarilyOnlyTheBottomStripIsTaken() {
        XCTAssertFalse(PassThroughWindow.claimsTouch(
            atY: 300, windowHeight: height, interactiveBottomInset: strip,
            isPresentingModal: false, claimsEntireScreen: false))
        XCTAssertTrue(PassThroughWindow.claimsTouch(
            atY: 800, windowHeight: height, interactiveBottomInset: strip,
            isPresentingModal: false, claimsEntireScreen: false))
    }

    func testTheTourTakesEveryTouch() {
        XCTAssertTrue(PassThroughWindow.claimsTouch(
            atY: 10, windowHeight: height, interactiveBottomInset: strip,
            isPresentingModal: false, claimsEntireScreen: true))
    }

    func testTheFullPlayerStillTakesEveryTouch() {
        XCTAssertTrue(PassThroughWindow.claimsTouch(
            atY: 10, windowHeight: height, interactiveBottomInset: strip,
            isPresentingModal: true, claimsEntireScreen: false))
    }
}
#endif
