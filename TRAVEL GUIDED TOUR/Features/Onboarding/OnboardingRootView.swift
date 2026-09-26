//
//  OnboardingRootView.swift
//  TRAVEL GUIDED TOUR
//
//  The first run, screens 2 through 18.
//
//  Screen 1 is the splash the app already ships — `SplashView` — and screens
//  19/20 are the real app, so neither is drawn here. Screen 2 is the splash
//  gaining a face, which is why it is the one card without the scaffold.
//
//  ⚠️ The coach marks (the five stops on Home) are NOT in this file and not in
//  this build. They need the cross-window overlay worked out in the plan and
//  ship as their own change.
//

import SwiftUI

struct OnboardingRootView: View {
    @Environment(OnboardingCoordinator.self) private var onboarding
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Held in the view, never persisted: the account screens in this build do
    /// not create an account, so there is nothing to submit it to.
    @State private var password = ""

    var body: some View {
        ZStack {
            AtlasColors.background.ignoresSafeArea()
            if let step = onboarding.currentStep {
                card(for: step)
                    .transition(.opacity)
                    .id(step)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: onboarding.index)
        .onDisappear { password = "" }
    }

    @ViewBuilder
    private func card(for step: OnboardingStep) -> some View {
        switch step {
        case .faceAppears:          FaceAppearsCard()
        case .definition:           DefinitionCard()
        case .accountAsk:           AccountAskCard()
        case .accountProviders:     AccountProvidersCard()
        case .accountForm:          AccountFormCard(password: $password)
        case .welcomeByName:        WelcomeByNameCard()
        case .questionUse:          UseQuestionCard()
        case .libraryLeadIn:        LibraryLeadInCard()
        case .questionFormats:      FormatsQuestionCard()
        case .communityLeadIn:      CommunityLeadInCard()
        case .questionInterests:    InterestsQuestionCard()
        case .suggestLeadIn:        SuggestLeadInCard()
        case .followSix:            FollowSixCard()
        case .listsLeadIn:          ListsLeadInCard()
        case .questionLists:        ListUseQuestionCard()
        case .makerLeadIn:          MakerLeadInCard()
        case .questionMakerIntent:  MakerIntentCard()
        }
    }
}

// MARK: - 2 · the face fades in

/// The existing hand-off with a different ending: the wordmark leaves, the
/// face arrives on the mark that is already there.
///
/// Geometry matches `SplashView` exactly — a 44pt mark, the wordmark one
/// `AtlasSpacing.md` below it — so nothing jumps between the two.
private struct FaceAppearsCard: View {
    @Environment(OnboardingCoordinator.self) private var onboarding
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var faceIn = false

    var body: some View {
        VStack(spacing: AtlasSpacing.md) {
            DozentFace(expression: .rest, radius: 22)
                .opacity(faceIn ? 1 : 0)
                .overlay {
                    // The bare mark underneath, so the disc never blinks.
                    Circle().fill(AtlasColors.brass).opacity(faceIn ? 0 : 1)
                        .frame(width: 44, height: 44)
                        .allowsHitTesting(false)
                }
            dozentWordmark()
                .foregroundStyle(AtlasColors.primaryText)
                .opacity(faceIn ? 0 : 1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { onboarding.advance() }
        .task {
            if reduceMotion {
                faceIn = true
                try? await Task.sleep(for: .milliseconds(900))
            } else {
                try? await Task.sleep(for: .milliseconds(240))
                withAnimation(.easeInOut(duration: 0.55)) { faceIn = true }
                try? await Task.sleep(for: .milliseconds(1_250))
            }
            onboarding.advance()
        }
    }
}

// MARK: - 3 · what a docent is

private struct DefinitionCard: View {
    @Environment(OnboardingCoordinator.self) private var onboarding

    /// The z, in brass, wherever the app's own spelling appears — so the eye
    /// pairs the two spellings before anyone has read a word.
    private var dozentInline: Text {
        Text("Do") + Text("z").foregroundColor(AtlasColors.brass) + Text("ent")
    }

    var body: some View {
        OnboardingScaffold(
            progressIndex: onboarding.progressIndex,
            expression: .beam
        ) {
            VStack(spacing: 0) {
                OnboardingLine(Text("Welcome to ") + dozentWordmark())
                // The dictionary entry. Both spellings in the headword —
                // that is how a dictionary prints a variant, so the form
                // explains itself and nothing has to be announced.
                OnboardingLine(
                    Text("do·") + Text("c").foregroundColor(AtlasColors.brass) + Text("ent")
                    + Text("  ·  ") + dozentInline
                )
                .padding(.top, OnboardingType.Gap.section)
                OnboardingLine("/ˈdəʊs(ə)nt/  noun")
                    .opacity(0.55)
                    .padding(.top, 2)
                OnboardingLine(
                    "a person who acts as a guide, leading others through a place "
                    + "and telling them what is worth knowing about it."
                )
                .padding(.top, OnboardingType.Gap.tight)
                // The usage example every dictionary entry carries. It is what
                // introduces the lowercase common noun the rest of the run uses.
                OnboardingLine(Text("“we spent the morning with a dozent.”").italic())
                    .opacity(0.55)
                    .padding(.top, OnboardingType.Gap.tight)
                // 🔴 The handoff. The entry defines *docent*; this sentence uses
                // *Dozent*; screens 11, 13, 14 and 17 then use it as an ordinary
                // word. Before 2026-09-26 this line said "docent" and the switch
                // was never made anywhere.
                OnboardingLine(
                    Text("An app built for travel and exploration. Think of it as having a ")
                    + dozentInline + Text(" in your hands.")
                )
                .padding(.top, OnboardingType.Gap.block)
            }
        } actions: {
            OnboardingButton(title: "Continue") { onboarding.advance() }
        }
    }
}

// MARK: - 4 · first, an account

private struct AccountAskCard: View {
    @Environment(OnboardingCoordinator.self) private var onboarding

    var body: some View {
        OnboardingScaffold(progressIndex: onboarding.progressIndex) {
            VStack(spacing: 0) {
                OnboardingLine("First, an account")
                OnboardingLine("An account keeps your playlists, your downloads, and where you left off.")
                    .padding(.top, OnboardingType.Gap.step)
            }
        } actions: {
            OnboardingButton(title: "Create an account") { onboarding.advance() }
            OnboardingLink(title: "I already have an account") { onboarding.advance() }
            OnboardingLink(title: "Skip", dimmed: true) { onboarding.finish() }
        }
    }
}

// MARK: - 5 · providers

private struct AccountProvidersCard: View {
    @Environment(OnboardingCoordinator.self) private var onboarding

    var body: some View {
        OnboardingScaffold(progressIndex: onboarding.progressIndex) {
            VStack(spacing: 0) {
                OnboardingLine("Create an account")
                VStack(spacing: 10) {
                    provider("Apple", symbol: "apple.logo") {
                        onboarding.usedProvider = true
                        onboarding.advance()
                    }
                    provider("Google", symbol: "g.circle") {
                        onboarding.usedProvider = true
                        onboarding.advance()
                    }
                    provider("Email", symbol: "envelope") {
                        onboarding.usedProvider = false
                        onboarding.advance()
                    }
                }
                .padding(.top, 22)
                // The line that makes the three account screens acceptable
                // this early. It is the owner's own wording from their page 5.
                OnboardingLine(
                    Text("Browse, play and download all work without an account. ")
                    + dozentWordmark() + Text(" is not gated.")
                )
                .padding(.top, OnboardingType.Gap.step)
            }
        } actions: {
            OnboardingButton(title: "Skip for now", filled: false) { onboarding.finish() }
            OnboardingLink(title: "I already have an account") { onboarding.advance() }
        }
    }

    private func provider(_ label: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: symbol)
                Text(label).font(AtlasTypography.caption).fontWeight(.semibold)
            }
            .foregroundStyle(AtlasColors.primaryText)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Capsule().fill(AtlasColors.secondaryBackground))
            .overlay(Capsule().stroke(AtlasColors.primaryText.opacity(0.20), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 6 / 6b · the form

private struct AccountFormCard: View {
    @Environment(OnboardingCoordinator.self) private var onboarding
    @Binding var password: String
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var username = ""
    @State private var homeCity = ""

    /// Apple and Google both hand back the name and the email, so username and
    /// password are meaningless on that path — the provider IS the login.
    /// What is left is the one thing they cannot give us.
    private var fromProvider: Bool { onboarding.usedProvider }

    var body: some View {
        OnboardingScaffold(progressIndex: onboarding.progressIndex) {
            VStack(spacing: 0) {
                OnboardingLine(Text("Welcome to ") + dozentWordmark())
                if fromProvider {
                    OnboardingLine("Two things we could not get from Apple.")
                        .padding(.top, OnboardingType.Gap.tight)
                }
                VStack(spacing: 11) {
                    field("First name", text: $firstName, prefilled: fromProvider)
                    field("Last name", text: $lastName, prefilled: fromProvider)
                    if !fromProvider {
                        field("Username", text: $username)
                        secureField("Password")
                    }
                    field("Home city", text: $homeCity)
                }
                .padding(.top, 22)
            }
        } actions: {
            OnboardingButton(title: "Continue") {
                onboarding.update {
                    $0.firstName = firstName.trimmingCharacters(in: .whitespaces)
                    $0.lastName = lastName.trimmingCharacters(in: .whitespaces)
                    $0.homeCity = homeCity.trimmingCharacters(in: .whitespaces)
                }
                onboarding.advance()
            }
        }
    }

    private func field(_ label: String, text: Binding<String>, prefilled: Bool = false) -> some View {
        HStack(spacing: 8) {
            TextField(label, text: text)
                .font(AtlasTypography.caption)
                // `textInputAutocapitalization` does not exist on macOS, and
                // this target builds there too — `PlatformHelpers` is the shim.
                .atlasNoAutocapitalization()
                .autocorrectionDisabled()
            if prefilled {
                Text("FROM APPLE")
                    .font(.system(size: 9.5, design: .monospaced))
                    .foregroundStyle(AtlasColors.brass)
                    .padding(.horizontal, 8)
                    .frame(height: 20)
                    .background(Capsule().fill(AtlasColors.brass.opacity(0.13)))
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(RoundedRectangle(cornerRadius: 13).fill(AtlasColors.secondaryBackground))
        .overlay(RoundedRectangle(cornerRadius: 13)
            .stroke(AtlasColors.primaryText.opacity(0.18), lineWidth: 1))
    }

    private func secureField(_ label: String) -> some View {
        SecureField(label, text: $password)
            .font(AtlasTypography.caption)
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(RoundedRectangle(cornerRadius: 13).fill(AtlasColors.secondaryBackground))
            .overlay(RoundedRectangle(cornerRadius: 13)
                .stroke(AtlasColors.primaryText.opacity(0.18), lineWidth: 1))
    }
}

// MARK: - 7 · welcome, {name}

private struct WelcomeByNameCard: View {
    @Environment(OnboardingCoordinator.self) private var onboarding

    /// Someone can reach this screen having skipped the account, so there may
    /// be no name. The line then reads "Welcome." rather than leaving a hole
    /// where a name should be.
    private var greeting: String {
        let name = onboarding.state.firstName
        return name.isEmpty ? "Welcome." : "Welcome, \(name)."
    }

    var body: some View {
        OnboardingScaffold(progressIndex: onboarding.progressIndex, expression: .beam) {
            VStack(spacing: 0) {
                OnboardingLine(greeting)
                OnboardingLine(
                    Text("Think of ") + dozentWordmark()
                    + Text(" as your guide to exploring the world around you.")
                )
                .padding(.top, OnboardingType.Gap.step)
                OnboardingLine("There are many ways to explore.")
                    .padding(.top, OnboardingType.Gap.step)
            }
        } actions: {
            OnboardingButton(title: "Show me") { onboarding.advance() }
        }
    }
}

// MARK: - 8 · how will you use it

private struct UseQuestionCard: View {
    @Environment(OnboardingCoordinator.self) private var onboarding

    /// The owner's five, plus the three from the brainstorm board they picked
    /// out (2026-09-22). Every row earns its place by changing what the app
    /// does with the answer — that was the rule for adding any of them.
    private static let options: [OnboardingOption] = [
        .init(label: "While travelling", symbol: "airplane"),
        .init(label: "From home", symbol: "house"),
        .init(label: "Explore my city", symbol: "building.2"),
        .init(label: "Plan a future trip", symbol: "map"),
        .init(label: "Deep dive into a place", symbol: "sparkles"),
        .init(label: "Showing someone around", symbol: "person.2"),
        .init(label: "Somewhere I already went", symbol: "arrow.uturn.backward"),
        .init(label: "Just browsing, no plans", symbol: "wind")
    ]

    var body: some View {
        OnboardingScaffold(progressIndex: onboarding.progressIndex) {
            OnboardingRowQuestion(
                title: Text("How will you use ") + dozentWordmark() + Text("?"),
                options: Self.options,
                selection: Binding(
                    get: { onboarding.state.uses },
                    set: { new in onboarding.update { $0.uses = new } }
                )
            )
        } actions: {
            OnboardingButton(title: "Continue") { onboarding.advance() }
        }
    }
}

// MARK: - 9 · the library lead-in

private struct LibraryLeadInCard: View {
    @Environment(OnboardingCoordinator.self) private var onboarding

    var body: some View {
        OnboardingScaffold(progressIndex: onboarding.progressIndex, expression: .beam) {
            VStack(spacing: 0) {
                // 🔴 A lead-in card's first line names what comes next. It used
                // to read "Fantastic." — a reaction, pointing backwards, telling
                // the reader nothing (owner, 2026-09-23).
                OnboardingLine("Next, the kinds you like to watch and hear")
                OnboardingLine(
                    dozentWordmark()
                    + Text(" has a constantly expanding library of curated content "
                           + "to help you on your journeys.")
                )
                .padding(.top, OnboardingType.Gap.step)
            }
        } actions: {
            OnboardingButton(title: "Show me") { onboarding.advance() }
        }
    }
}

// MARK: - 10 · formats

private struct FormatsQuestionCard: View {
    @Environment(OnboardingCoordinator.self) private var onboarding

    /// ⚠️ Long-form stays despite there being a handful of long-form items in
    /// a 3,000-entry catalogue: the owner is commissioning it, and asking now
    /// tells them who wants it.
    private static let options: [OnboardingOption] = [
        .init(label: "Short-form videos", symbol: "play.rectangle"),
        .init(label: "Long-form videos", symbol: "film"),
        .init(label: "IRL audio tours", symbol: "headphones"),
        .init(label: "IRL walking tours", symbol: "figure.walk"),
        .init(label: "All of it", symbol: "star")
    ]

    var body: some View {
        OnboardingScaffold(progressIndex: onboarding.progressIndex) {
            OnboardingRowQuestion(
                title: Text("I like my…"),
                options: Self.options,
                selection: Binding(
                    get: { onboarding.state.formats },
                    set: { new in onboarding.update { $0.formats = new } }
                )
            )
        } actions: {
            OnboardingButton(title: "Continue") { onboarding.advance() }
        }
    }
}

// MARK: - 11 · the people lead-in

private struct CommunityLeadInCard: View {
    @Environment(OnboardingCoordinator.self) private var onboarding

    var body: some View {
        OnboardingScaffold(progressIndex: onboarding.progressIndex) {
            VStack(spacing: 0) {
                OnboardingLine("Let's find you dozents to follow")
                OnboardingLine(
                    Text("We all have different ways of seeing the world, and different interests. ")
                    + dozentWordmark()
                    + Text(" represents a diversity of both. Follow the ones whose eye you trust, "
                           + "and see what they are up to.")
                )
                .padding(.top, OnboardingType.Gap.step)
                OnboardingLine("First, what you are drawn to.")
                    .padding(.top, OnboardingType.Gap.step)
            }
        } actions: {
            OnboardingButton(title: "Show me") { onboarding.advance() }
        }
    }
}

// MARK: - 12 · interests

private struct InterestsQuestionCard: View {
    @Environment(OnboardingCoordinator.self) private var onboarding

    var body: some View {
        OnboardingScaffold(progressIndex: onboarding.progressIndex) {
            VStack(spacing: 0) {
                OnboardingLine("What are you drawn to?")
                OnboardingLine(countLine)
                    .padding(.top, OnboardingType.Gap.tight)
                ChipFlowLayout(spacing: 7) {
                    ForEach(OnboardingInterests.all) { interest in
                        OnboardingChip(
                            label: interest.label,
                            isOn: onboarding.state.interests.contains(interest.tag)
                        ) {
                            onboarding.update {
                                if $0.interests.contains(interest.tag) {
                                    $0.interests.remove(interest.tag)
                                } else {
                                    $0.interests.insert(interest.tag)
                                }
                            }
                        }
                    }
                }
                .padding(.top, OnboardingType.Gap.step)
            }
        } actions: {
            OnboardingButton(title: "Continue") { onboarding.advance() }
        }
    }

    private var countLine: String {
        let n = onboarding.state.interests.count
        return n == 0 ? "Pick as many as you like" : "Pick as many as you like — \(n) chosen"
    }
}

// MARK: - 13 · let me suggest a few

private struct SuggestLeadInCard: View {
    @Environment(OnboardingCoordinator.self) private var onboarding

    var body: some View {
        OnboardingScaffold(progressIndex: onboarding.progressIndex, expression: .wink) {
            VStack(spacing: 0) {
                OnboardingLine("Let me suggest a few")
                OnboardingLine("There are a lot of dozents covering what you are drawn to.")
                    .padding(.top, OnboardingType.Gap.step)
            }
        } actions: {
            OnboardingButton(title: "Continue") { onboarding.advance() }
        }
    }
}

// MARK: - 14 · six to follow

private struct FollowSixCard: View {
    @Environment(OnboardingCoordinator.self) private var onboarding
    @State private var followed: Set<String> = []

    /// ⚠️ Keyed to INTERESTS, not city. 82% of the catalogue's cities have
    /// exactly one maker, so a city-keyed grid would show one avatar and five
    /// blanks for four people in five.
    ///
    /// ⚠️ The handles are real, the RANKING is not built. "Best six for these
    /// tags" needs a rule — most tours, most recent, most cities, or editorial
    /// — and until it exists this is a fixed list.
    private static let creators: [OnboardingCreator] = [
        .init(initials: "AS", handle: "Atlas Studio LDN", tag: "ARCHITECTURE"),
        .init(initials: "UA", handle: "@urbanistariel", tag: "ARCHITECTURE"),
        .init(initials: "HA", handle: "@history_alice", tag: "HISTORY"),
        .init(initials: "AM", handle: "@archimarathon", tag: "ARCHITECTURE"),
        .init(initials: "HN", handle: "@hereinnyc", tag: "HISTORY"),
        .init(initials: "BL", handle: "@benlookingatart", tag: "ART")
    ]

    private var chosenLabels: [String] {
        OnboardingInterests.all
            .filter { onboarding.state.interests.contains($0.tag) }
            .prefix(2)
            .map(\.label)
    }

    var body: some View {
        OnboardingScaffold(progressIndex: onboarding.progressIndex, expression: .beam) {
            VStack(spacing: 0) {
                OnboardingLine("Six dozents you might like")
                if !chosenLabels.isEmpty {
                    // The derivation, made visible. If the six look arbitrary
                    // the suggestion is noise; with the user's own answers
                    // above them the same six read as a service.
                    HStack(spacing: 6) {
                        Text("because you picked")
                            .font(AtlasTypography.caption)
                            .foregroundStyle(AtlasColors.primaryText)
                        ForEach(chosenLabels, id: \.self) { label in
                            OnboardingChip(label: label, isOn: true) {}
                                .allowsHitTesting(false)
                        }
                    }
                    .padding(.top, OnboardingType.Gap.tight)
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3),
                          spacing: 16) {
                    ForEach(Self.creators) { creator in
                        creatorCell(creator)
                    }
                }
                .padding(.top, OnboardingType.Gap.step)
            }
        } actions: {
            OnboardingButton(title: "Continue") { onboarding.advance() }
            OnboardingLink(title: "Show me different ones") { onboarding.advance() }
        }
    }

    private func creatorCell(_ creator: OnboardingCreator) -> some View {
        let isFollowing = followed.contains(creator.handle)
        return VStack(spacing: 7) {
            // 🔴 Every avatar is brass (owner, 2026-09-26). They were six
            // different colours, which sorted the eye by colour — and the
            // colours meant nothing.
            ZStack {
                Circle().fill(AtlasColors.brass)
                Text(creator.initials)
                    .font(.system(size: 17, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white)
            }
            .frame(width: 58, height: 58)
            Text(creator.handle)
                .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                .foregroundStyle(AtlasColors.primaryText)
                .lineLimit(1)
                .truncationMode(.tail)
            Text(creator.tag)
                .font(.system(size: 8, design: .monospaced))
                .tracking(0.9)
                .foregroundStyle(AtlasColors.secondaryText)
            Button {
                if isFollowing { followed.remove(creator.handle) } else { followed.insert(creator.handle) }
            } label: {
                Text(isFollowing ? "Following" : "Follow")
                    .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                    .foregroundStyle(isFollowing ? AtlasColors.brass : Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 28)
                    .background(Capsule().fill(isFollowing ? AtlasColors.brass.opacity(0.14)
                                                           : AtlasColors.brass))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - 15 · your own lists

private struct ListsLeadInCard: View {
    @Environment(OnboardingCoordinator.self) private var onboarding

    var body: some View {
        OnboardingScaffold(progressIndex: onboarding.progressIndex) {
            VStack(spacing: 0) {
                OnboardingLine("Your own lists")
                OnboardingLine(
                    "With an account you can create personal lists for the things you care "
                    + "about — or use one to plan an upcoming trip, stop by stop."
                )
                .padding(.top, OnboardingType.Gap.step)
                OnboardingLine("We will ask how you would use one.")
                    .padding(.top, OnboardingType.Gap.step)
            }
        } actions: {
            OnboardingButton(title: "Show me") { onboarding.advance() }
        }
    }
}

// MARK: - 16 · how you'd use a list

private struct ListUseQuestionCard: View {
    @Environment(OnboardingCoordinator.self) private var onboarding

    private static let options: [OnboardingOption] = [
        .init(label: "Plan a trip", symbol: "map"),
        .init(label: "Curate a special interest", symbol: "star"),
        .init(label: "Share lists with others", symbol: "square.and.arrow.up"),
        .init(label: "Keep private lists for friends", symbol: "lock")
    ]

    var body: some View {
        OnboardingScaffold(progressIndex: onboarding.progressIndex) {
            OnboardingRowQuestion(
                title: Text("How would you use a playlist?"),
                options: Self.options,
                selection: Binding(
                    get: { onboarding.state.listUses },
                    set: { new in onboarding.update { $0.listUses = new } }
                )
            )
        } actions: {
            OnboardingButton(title: "Continue") { onboarding.advance() }
        }
    }
}

// MARK: - 17 · anyone can be a dozent

private struct MakerLeadInCard: View {
    @Environment(OnboardingCoordinator.self) private var onboarding

    var body: some View {
        OnboardingScaffold(progressIndex: onboarding.progressIndex, expression: .beam) {
            VStack(spacing: 0) {
                OnboardingLine("Anyone can be a dozent")
                OnboardingLine(
                    "Everyone in the community can be one. When you know a place well enough "
                    + "to say something about it, we would like you to."
                )
                .padding(.top, OnboardingType.Gap.step)
            }
        } actions: {
            OnboardingButton(title: "Continue") { onboarding.advance() }
        }
    }
}

// MARK: - 18 · browsing, or creating

private struct MakerIntentCard: View {
    @Environment(OnboardingCoordinator.self) private var onboarding

    var body: some View {
        OnboardingScaffold(progressIndex: onboarding.progressIndex, expression: .beam) {
            VStack(spacing: 0) {
                OnboardingLine(
                    Text("Whichever you choose, we are happy to have you in the ")
                    + dozentWordmark() + Text(" community.")
                )
                VStack(spacing: 11) {
                    OnboardingCardChoice(
                        title: "I'm browsing",
                        subtitle: "Here to listen and watch. That is most people, and it is plenty.",
                        symbol: "headphones",
                        isOn: onboarding.state.makerIntent == "browsing"
                    ) {
                        onboarding.update { $0.makerIntent = "browsing" }
                    }
                    // 🔴 This card does NOT open a recorder, and must not
                    // promise one (owner, 2026-09-22). A first-run screen that
                    // says "show me how" and then does not is worse than one
                    // that says nothing.
                    OnboardingCardChoice(
                        title: "I'm ready to create",
                        subtitle: "The tools to upload a tour live on your profile page. "
                            + "Got a lot to upload? Email hello@dozent.world and we will help.",
                        symbol: "sparkles",
                        isOn: onboarding.state.makerIntent == "creating"
                    ) {
                        onboarding.update { $0.makerIntent = "creating" }
                    }
                }
                .padding(.top, 22)
            }
        } actions: {
            OnboardingButton(title: "Start exploring") { onboarding.finish() }
        }
    }
}

// MARK: - Interests

/// The chips on screen 12, every one a real catalogue tag so no pick can
/// promote an empty shelf. Ordered by how much of the catalogue each covers.
struct OnboardingInterest: Identifiable {
    let label: String
    /// The real catalogue tag this chip filters on.
    let tag: String
    var id: String { tag }
}

/// One of the six suggested makers on screen 14.
struct OnboardingCreator: Identifiable {
    let initials: String
    let handle: String
    let tag: String
    var id: String { handle }
}

enum OnboardingInterests {
    static let all: [OnboardingInterest] = [
        .init(label: "History", tag: "History"),
        .init(label: "Architecture", tag: "Architecture"),
        .init(label: "Designed by a master", tag: "Designed by a Master"),
        .init(label: "Art", tag: "Art"),
        .init(label: "Food & drink", tag: "Food"),
        .init(label: "Hidden gems", tag: "Hidden Gem"),
        .init(label: "Iconic landmarks", tag: "Iconic Landmark"),
        .init(label: "Museums", tag: "Museum"),
        .init(label: "Modern icons", tag: "Contemporary"),
        .init(label: "Free to visit", tag: "Free to Visit"),
        .init(label: "Sacred spaces", tag: "Faith"),
        .init(label: "Green escapes", tag: "Green Escape"),
        .init(label: "Engineering", tag: "Engineering"),
        .init(label: "Monuments", tag: "Monument"),
        .init(label: "Parks", tag: "Park"),
        .init(label: "By the water", tag: "Waterfront"),
        .init(label: "Viewpoints", tag: "Viewpoint"),
        .init(label: "Public art", tag: "Public Art"),
        .init(label: "Remembrance", tag: "Remembrance"),
        .init(label: "Markets & halls", tag: "Market"),
        .init(label: "Towers & rooftops", tag: "Tower"),
        .init(label: "After dark", tag: "After Dark"),
        .init(label: "Literature", tag: "Literature"),
        .init(label: "Fashion & retail", tag: "Fashion")
    ]
}
