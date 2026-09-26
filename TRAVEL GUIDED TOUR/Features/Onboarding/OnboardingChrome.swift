//
//  OnboardingChrome.swift
//  TRAVEL GUIDED TOUR
//
//  The fixed skeleton every onboarding card is drawn into, and the one type
//  style they all use.
//
//  🔴 THE SKELETON IS THE DESIGN. Owner decisions, 2026-09-22/23:
//  · the face is the same size, in the same place, on every screen from 3 on;
//  · Continue is at the same height on every screen that has one;
//  · the copy is CENTRED in the band between them;
//  · the progress bar sits as high as iOS allows — 9pt under the safe area,
//    because the Dynamic Island owns everything above it.
//  Only the middle changes. That is what makes twenty screens not read as
//  twenty.
//

import SwiftUI

// MARK: - Type

/// One style, everywhere. Owner, 2026-09-22: *"make all font same 'caption' …
/// including font size, color etc."*
///
/// ⚠️ `AtlasTypography.caption` is a hard 13pt and does **not** respond to
/// Dynamic Type (`docs/design-tokens.md`). Onboarding is the worst place in the
/// app to inherit that — it is the first thing a new user reads and it is
/// almost entirely text — so `.dynamicTypeSize` is left unclamped here and the
/// scaling fix is tracked as a follow-up rather than silently diverging from
/// the token the owner asked for.
enum OnboardingType {
    static let caption = AtlasTypography.caption
    /// Hierarchy comes from space, not size. These are the only gaps used.
    enum Gap {
        static let tight: CGFloat = 8
        static let step: CGFloat = 16
        static let block: CGFloat = 32
        static let section: CGFloat = 40
    }
}

/// A line of onboarding copy. Centred, caption, primary ink — no exceptions
/// but the wordmark.
struct OnboardingLine: View {
    private let content: Text
    init(_ text: String) { self.content = Text(text) }
    init(_ text: Text) { self.content = text }

    var body: some View {
        content
            .font(OnboardingType.caption)
            .foregroundStyle(AtlasColors.primaryText)
            .multilineTextAlignment(.center)
            .lineSpacing(5)
            .frame(maxWidth: .infinity)
    }
}

/// "Dozent", always in the wordmark — New York serif 15pt, tracked 2, Title
/// Case. Same as `SplashView` and the Settings masthead.
func dozentWordmark(_ trailing: String = "") -> Text {
    Text("Dozent")
        .font(AtlasTypography.wordmark)
        .tracking(2)
    + Text(trailing)
}

// MARK: - Progress

/// Reels-style: one segment per screen. 🔴 OWNER DECISION 2026-09-22 — *"B,
/// Reels style, my preference"* — over the chapter-segmented alternative.
///
/// Past segments fill, the current one half-fills, the rest are empty.
struct OnboardingProgressBar: View {
    /// Index of the current segment, or `nil` on a screen the bar skips.
    let index: Int?

    var body: some View {
        HStack(spacing: 2.5) {
            ForEach(0..<OnboardingFlow.progressSegmentCount, id: \.self) { i in
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(AtlasColors.primaryText.opacity(0.18))
                        Capsule()
                            .fill(AtlasColors.brass)
                            .frame(width: geo.size.width * fraction(for: i))
                    }
                }
                .frame(height: 3)
            }
        }
        .opacity(index == nil ? 0 : 1)
        .accessibilityHidden(true)
    }

    private func fraction(for segment: Int) -> CGFloat {
        guard let index else { return 0 }
        if segment < index { return 1 }
        if segment == index { return 0.52 }
        return 0
    }
}

// MARK: - Actions

/// The primary button. Same height, same place, every screen.
struct OnboardingButton: View {
    let title: String
    var filled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AtlasTypography.caption)
                .fontWeight(.bold)
                .foregroundStyle(filled ? Color.white : AtlasColors.secondaryText)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    Capsule()
                        .fill(filled ? AtlasColors.brass : Color.clear)
                )
                .overlay(
                    Capsule()
                        .stroke(filled ? Color.clear : AtlasColors.primaryText.opacity(0.24),
                                lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }
}

/// A secondary link under the button — "I already have an account", "Skip".
struct OnboardingLink: View {
    let title: String
    var dimmed = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AtlasTypography.caption)
                .foregroundStyle(dimmed ? AtlasColors.tertiaryText : AtlasColors.secondaryText)
                .frame(maxWidth: .infinity, minHeight: 40)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - The scaffold

/// The frame every card is drawn into.
struct OnboardingScaffold<Content: View, Actions: View>: View {
    var progressIndex: Int?
    var expression: DozentExpression = .rest
    /// Screens 2 and the splash-adjacent ones hide the face; everything from 3
    /// on shows it in exactly the same spot.
    var showsFace = true
    @ViewBuilder var content: () -> Content
    @ViewBuilder var actions: () -> Actions

    /// 42pt radius — the size the whole run was drawn at.
    private let faceRadius: CGFloat = 42

    var body: some View {
        VStack(spacing: 0) {
            OnboardingProgressBar(index: progressIndex)
                .padding(.top, 9)
                .padding(.horizontal, AtlasSpacing.lg)

            Spacer().frame(height: 36)

            DozentFace(expression: expression, radius: faceRadius)
                .opacity(showsFace ? 1 : 0)

            // The band. Copy centres in it; anything taller scrolls rather
            // than being squeezed or clipped.
            GeometryReader { geo in
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        content()
                        Spacer(minLength: 0)
                    }
                    .frame(minHeight: geo.size.height)
                    .frame(maxWidth: .infinity)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .padding(.top, 36)
            .padding(.horizontal, AtlasSpacing.lg)

            VStack(spacing: 0) { actions() }
                .padding(.horizontal, AtlasSpacing.lg)
                .padding(.bottom, AtlasSpacing.sm)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AtlasColors.background)
    }
}
