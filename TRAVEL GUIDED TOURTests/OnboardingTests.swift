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
