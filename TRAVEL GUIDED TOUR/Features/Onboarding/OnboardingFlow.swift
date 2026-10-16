//
//  OnboardingFlow.swift
//  TRAVEL GUIDED TOUR
//
//  The shape of the first-run flow: which screens exist, in what order, and
//  which of them count toward the progress bar.
//
//  Pure — no SwiftUI, no storage, no services — so the ordering and the
//  progress arithmetic can be tested without a host. `OnboardingCoordinator`
//  walks it; `OnboardingRootView` draws it.
//

import Foundation

/// One screen of the first-run flow.
///
/// The raw values are the numbers the owner drew on their own pages, so a
/// comment or a design note that says "screen 12" names the same thing here.
enum OnboardingStep: Int, CaseIterable, Codable, Sendable {
    /// The splash gaining a face while the wordmark leaves. This is the
    /// existing hand-off with a different ending — see `SplashView`.
    case faceAppears = 2
    /// What a docent is, and what the app is. The dictionary entry.
    case definition = 3
    /// First, an account — create / sign in / skip.
    case accountAsk = 4
    /// Apple · Google · Email.
    case accountProviders = 5
    /// The form. Shortened when a provider was used — see `usedProvider`.
    case accountForm = 6
    /// Welcome, {first name}.
    case welcomeByName = 7
    /// How will you use Dozent?
    case questionUse = 8
    /// The library lead-in.
    case libraryLeadIn = 9
    /// I like my… (formats)
    case questionFormats = 10
    /// The people lead-in.
    case communityLeadIn = 11
    /// What are you drawn to? (the tag cloud)
    case questionInterests = 12
    /// Let me suggest a few.
    case suggestLeadIn = 13
    /// Six dozents you might like.
    case followSix = 14
    /// Your own lists.
    case listsLeadIn = 15
    /// How would you use a playlist?
    case questionLists = 16
    /// Anyone can be a dozent.
    case makerLeadIn = 17
    /// Browsing, or creating?
    case questionMakerIntent = 18

    /// The screens that carry the progress bar — 3 through 18.
    ///
    /// 🔴 Deliberately NOT every step. Screen 2 is the splash handing off, and
    /// a progress bar over the splash would claim the launch is part of a flow
    /// the user has not agreed to yet. Home (19+) is the real app, where a
    /// progress bar would say you are still in onboarding when you are not.
    static let progressBarSteps: [OnboardingStep] = OnboardingStep.allCases
        .filter { $0.rawValue >= 3 && $0.rawValue <= 18 }

    /// Every step, in the order they are shown.
    static let order: [OnboardingStep] = OnboardingStep.allCases.sorted { $0.rawValue < $1.rawValue }
}

/// Version + ordering rules for the flow.
enum OnboardingFlow {
    /// Bumping this makes every existing install see onboarding once more.
    /// `OnboardingStore.hasCompleted` compares against it, so re-onboarding
    /// after a big change is a one-line change here rather than new machinery.
    static let currentVersion = 1

    /// The steps to show, given whether the user signed in with Apple/Google.
    ///
    /// A provider hands back the name and the email, so username and password
    /// are meaningless on that path — screen 6 becomes a short form asking only
    /// for the home city. Same step, different content; the branch lives in the
    /// view rather than in this list.
    ///
    /// - Parameters:
    ///   - replaying: `true` when the user asked for the tour again from
    ///     Settings. The account screens are skipped — they have an account, or
    ///     they decided not to, and asking twice is nagging.
    static func steps(replaying: Bool) -> [OnboardingStep] {
        guard replaying else { return OnboardingStep.order }
        return OnboardingStep.order.filter {
            $0 != .accountAsk && $0 != .accountProviders && $0 != .accountForm
        }
    }

    /// How far along the progress bar a step sits: the index of `step` within
    /// the bar's own steps, or `nil` for a step the bar does not cover.
    ///
    /// The bar is Reels-style — one segment per screen (owner decision,
    /// 2026-09-22) — so this index IS the segment to fill.
    static func progressIndex(of step: OnboardingStep) -> Int? {
        OnboardingStep.progressBarSteps.firstIndex(of: step)
    }

    /// Total segments in the progress bar.
    static var progressSegmentCount: Int { OnboardingStep.progressBarSteps.count }
}
