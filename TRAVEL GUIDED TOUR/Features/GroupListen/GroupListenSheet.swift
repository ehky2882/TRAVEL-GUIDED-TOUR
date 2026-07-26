import SwiftUI

/// "Listen together" — presented from a tour's overflow menu. Lets a signed-in
/// user **start a group** (they lead; everyone else mirrors their audio) or
/// **join** one by code. Nearby/offline (Bluetooth) for now — design
/// `docs/group-listen-design.md`.
struct GroupListenSheet: View {
    let tour: Tour

    @Environment(GroupListenCoordinator.self) private var coordinator: GroupListenCoordinator?
    @Environment(AuthService.self) private var authService: AuthService?
    @Environment(\.dismiss) private var dismiss

    @State private var joining = false
    @State private var codeEntry = ""
    @State private var showDownloadWarning = false
    /// Set when Start/Join couldn't even begin (a precondition failed). Without
    /// this the button was a dead tap — the same silent-failure pattern that
    /// made this feature look broken in the first place.
    @State private var actionError: String?
    @State private var showingScanner = false

    private var isSignedIn: Bool { authService?.isSignedIn == true }

    /// Matches the Group Listen glyph in `TourDetailView`'s action row, so the
    /// icon you tapped and the icon on the sheet it opens are the same weight
    /// (owner call). Was 40pt here, which dominated the half-height sheet.
    private static let glyphSize: CGFloat = 16

    /// Down from the component's 170pt default so the leader's screen — header,
    /// QR, join code, status line and Leave button — fits the half-height detent
    /// with Leave visible and no scrolling. Now that the code sits BESIDE the QR
    /// rather than under it, this is the only tall element left, so it sets the
    /// screen's height almost on its own. Kept as large as that allows: shrinking
    /// it further costs scan reliability, which is the entire point of showing it.
    private static let qrSize: CGFloat = 140

    var body: some View {
        NavigationStack {
            // A ScrollView, not a fixed frame. With a fixed frame, content taller
            // than the detent overflowed *upwards* and drew straight through the
            // navigation bar — which is how "YOU'RE LEADING" ended up printed on
            // top of the "LISTEN TOGETHER" title. Scrolling makes overflow
            // impossible to render out of bounds, on any device size or Dynamic
            // Type setting; `.basedOnSize` keeps it from bouncing when, as
            // intended, everything already fits.
            ScrollView {
                Group {
                    if !isSignedIn {
                        signedOut
                    } else if let coordinator, coordinator.isActive {
                        activeSession(coordinator)
                    } else if joining {
                        joinForm
                    } else {
                        chooser
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // The mini-player + tab bar live in a higher-level window, so they
            // paint OVER the bottom of this sheet. Without reserving their
            // height, the last line of the sheet (the download hint) sat
            // underneath them and looked cut off. Same inset every other
            // scrollable surface in the app applies.
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: AtlasBottomModule.height())
            }
            .background(AtlasColors.secondaryBackground)
            .navigationTitle("Listen together")
            .inlineNavigationBarTitle()
            // Render the nav-bar title ourselves so it carries the caption
            // token (13pt SF Mono) in ALL CAPS, matching Settings / Follow
            // Requests / the other pushed screens. `.navigationTitle` is kept
            // above purely for the accessibility label.
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("LISTEN TOGETHER")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.primaryText)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(AtlasTypography.caption)
                }
            }
            .sheet(isPresented: $showingScanner) {
                QRScannerView { scannedCode in
                    // The scanner only ever hands back an already-validated code.
                    codeEntry = scannedCode
                    joinGroup()
                }
            }
        }
        // Half-height by default — the chooser is two buttons and a line of
        // copy, so a full-screen sheet was mostly empty space. `.large` stays
        // available by drag, because the leader's QR code wants the extra room.
        // Declared on the NavigationStack (the presented root) so it applies to
        // THIS sheet and not the nested scanner sheet above.
        .presentationDetents([.medium, .large])
    }

    // MARK: - Chooser

    private var chooser: some View {
        VStack(spacing: AtlasSpacing.md) {
            VStack(spacing: AtlasSpacing.sm) {
                Image(systemName: "person.2.wave.2.fill")
                    .font(.system(size: Self.glyphSize))
                    .foregroundStyle(AtlasColors.mapPin)
                // One line each. The old copy explained the transport
                // (Bluetooth/Wi‑Fi) and the download caveat up front — detail
                // nobody needs before choosing which button to press. The
                // download caveat still appears below, but only when this tour
                // actually isn't downloaded.
                Text("Hear this tour together, in sync.")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.primaryText)
                    .multilineTextAlignment(.center)
                Text("One person leads. Everyone nearby follows.")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, AtlasSpacing.md)

            // Side by side: two equal cards, so the choice reads as one
            // decision rather than a primary action with an afterthought
            // beneath it. The labels are self-explanatory, so there's no
            // subtitle — the old "You lead" / "Scan a code" second lines made
            // each card twice as tall for no information (owner call).
            HStack(spacing: AtlasSpacing.md) {
                Button {
                    startLeading()
                } label: {
                    actionLabel("LEAD A TOUR", systemImage: "play.circle.fill", filled: true)
                }
                .buttonStyle(.plain)

                Button {
                    joining = true
                } label: {
                    actionLabel("JOIN A TOUR", systemImage: "arrow.right.circle", filled: false)
                }
                .buttonStyle(.plain)
            }
            // Equal heights even if one title wraps and the other doesn't: the
            // cards stretch to the row, the row takes its ideal height.
            .fixedSize(horizontal: false, vertical: true)

            if let actionError {
                Label(actionError, systemImage: "exclamationmark.triangle")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let coordinator, !coordinator.isTourDownloaded(tour) {
                // Trimmed, but the load-bearing fact stays: audio is NOT sent
                // peer-to-peer, so "connected" with no signal means silence.
                // That honesty fix is why this line exists at all.
                Label("Each phone streams its own audio — with no signal, download this tour on both first.",
                      systemImage: "wifi.slash")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

        }
        .padding(.horizontal, AtlasSpacing.lg)
    }

    /// One of the two side-by-side choice cards: glyph beside the label, on one
    /// line, so the pair stays short enough for everything on the sheet to be
    /// visible at the half-height detent without dragging.
    private func actionLabel(_ title: String, systemImage: String, filled: Bool) -> some View {
        HStack(spacing: AtlasSpacing.xs) {
            Image(systemName: systemImage).font(.system(size: Self.glyphSize))
            Text(title)
                .font(AtlasTypography.caption)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.vertical, AtlasSpacing.md)
        .padding(.horizontal, AtlasSpacing.sm)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(filled ? AtlasColors.background : AtlasColors.primaryText)
        .background(filled ? AtlasColors.mapPin : Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AtlasColors.secondaryText.opacity(filled ? 0 : 0.4), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Join form

    private var joinForm: some View {
        // Scan and type-a-code sit SIDE BY SIDE, mirroring the leader screen.
        // Stacked full-width (button, "or type it", field, Join, Back) they ran
        // past the half detent and pushed Back under the mini-player. They're
        // two ways to do one thing, not sequential steps, so columns fit the
        // meaning as well as the space. Each column labels itself, which also
        // retires the separate header and the "or type it" divider.
        VStack(spacing: AtlasSpacing.md) {
            HStack(alignment: .top, spacing: AtlasSpacing.md) {
                Button {
                    showingScanner = true
                } label: {
                    actionLabel("SCAN TO JOIN", systemImage: "qrcode.viewfinder", filled: true)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                    Text("OR ENTER CODE TO JOIN")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    // Deliberately still monospaced and larger than caption: you
                    // check this while someone reads a code aloud, so legibility
                    // beats compactness. Padding gives up the height instead.
                    TextField("Code", text: $codeEntry)
                        .disableAutocorrection(true)
                        .multilineTextAlignment(.center)
                        .font(.system(.title3, design: .monospaced))
                        .padding(.vertical, AtlasSpacing.sm)
                        .padding(.horizontal, AtlasSpacing.sm)
                        .background(AtlasColors.placeholderWarm.opacity(0.35))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .onChange(of: codeEntry) { _, new in
                            codeEntry = String(new.uppercased().prefix(5))
                        }

                    Button {
                        joinGroup()
                    } label: {
                        Text("JOIN")
                            .font(AtlasTypography.caption)
                            .foregroundStyle(AtlasColors.background)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(codeEntry.count == 5 ? AtlasColors.mapPin : AtlasColors.tertiaryText)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .disabled(codeEntry.count != 5)
                }
                .frame(maxWidth: .infinity)
            }
            // The scan card stretches to the typed-code column's height, and the
            // row takes its ideal height rather than filling the sheet.
            .fixedSize(horizontal: false, vertical: true)

            if let actionError {
                Label(actionError, systemImage: "exclamationmark.triangle")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button("Back") {
                joining = false
                actionError = nil
            }
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.secondaryText)
        }
        .padding(.top, AtlasSpacing.md)
        .padding(.horizontal, AtlasSpacing.lg)
    }

    // MARK: - Active session

    private func activeSession(_ coordinator: GroupListenCoordinator) -> some View {
        // Tighter than the old `lg` spacing / `xl` top padding: the sheet opens
        // at half height now, and the leader's QR code is the tallest content in
        // it, so every spare point matters for fitting without a drag.
        VStack(spacing: AtlasSpacing.sm) {
            if coordinator.isLeader {
                VStack(spacing: AtlasSpacing.sm) {
                    Text("SCAN TO JOIN")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.primaryText)

                    // QR and the typed code sit SIDE BY SIDE rather than stacked.
                    // Stacked, the two of them plus their captions were most of
                    // the sheet's height and pushed Leave below the fold; beside
                    // each other they cost only the height of the QR itself
                    // (owner call). They're alternatives, not steps, so reading
                    // left-to-right also suits them better than top-to-bottom.
                    HStack(alignment: .center, spacing: AtlasSpacing.md) {
                        if let code = coordinator.code {
                            QRCodeView(
                                content: AtlasShareLink.groupJoinURL(code: code).absoluteString,
                                size: Self.qrSize
                            )
                        }

                        VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                            Text("OR ENTER CODE TO JOIN")
                                .font(AtlasTypography.caption)
                                .foregroundStyle(AtlasColors.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(coordinator.code ?? "—")
                                .font(.system(size: 26, weight: .bold, design: .monospaced))
                                .foregroundStyle(AtlasColors.mapPin)
                                .textSelection(.enabled)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.top, AtlasSpacing.sm)
            } else {
                VStack(spacing: AtlasSpacing.sm) {
                    Image(systemName: coordinator.leaderLost ? "person.fill.questionmark" : "person.2.wave.2.fill")
                        .font(.system(size: Self.glyphSize))
                        .foregroundStyle(AtlasColors.mapPin)
                    Text(coordinator.leaderLost
                         ? "Leader left"
                         : "Following \(coordinator.leaderName ?? "the leader")")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.primaryText)
                    Text(coordinator.leaderLost
                         ? "Playback paused. Leave and rejoin, or start your own."
                         : "Your audio mirrors the leader.")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, AtlasSpacing.md)
            }

            statusRow(coordinator)

            Button {
                coordinator.leave()
                dismiss()
            } label: {
                Text("LEAVE GROUP")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.5), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .padding(.top, AtlasSpacing.sm)

        }
        .padding(.horizontal, AtlasSpacing.lg)
    }

    /// Connection/permission state so an active session can never look "stuck".
    /// A denied Local Network permission or an empty room now says so, instead
    /// of a silent screen.
    @ViewBuilder
    private func statusRow(_ coordinator: GroupListenCoordinator) -> some View {
        switch coordinator.connectionStatus {
        case .failed(let message):
            VStack(spacing: AtlasSpacing.xs) {
                Label(message, systemImage: "wifi.exclamationmark")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        case .connected where coordinator.followerAudioFailed:
            // Connected to the leader, but our own audio never loaded — the
            // giveaway that this tour isn't downloaded and there's no signal.
            Label("Connected, but the audio couldn't load. Download this tour, or move somewhere with signal.",
                  systemImage: "exclamationmark.triangle")
                .font(AtlasTypography.caption)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        case .searching:
            HStack(spacing: AtlasSpacing.sm) {
                ProgressView().controlSize(.small)
                Text(coordinator.isLeader ? "Waiting for people to join…" : "Connecting to the leader…")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
            }
        case .connected, .idle:
            VStack(spacing: AtlasSpacing.xs) {
                Label(coordinator.participantCount == 1
                      ? "Just you so far"
                      : "\(coordinator.participantCount) listening",
                      systemImage: "person.3.fill")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)

                // The mesh radios cap out around 8; say so rather than letting
                // the next person silently fail to connect (design §6).
                if coordinator.isAtParticipantCap {
                    Text("A nearby group holds about \(GroupListenCoordinator.maxNearbyParticipants) people — anyone else may not be able to join.")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Signed out

    private var signedOut: some View {
        // Spacers would collapse to nothing inside the enclosing ScrollView, so
        // this pads instead of centring — otherwise the prompt hugged the nav bar.
        VStack(spacing: AtlasSpacing.md) {
            JoinDozentPrompt(showIcon: true)
        }
        .padding(.top, AtlasSpacing.xl)
    }

    // MARK: - Actions

    private func startLeading() {
        actionError = nil
        // nil covers both "no coordinator in the environment" and "the
        // coordinator refused" (signed out / not yet wired).
        if coordinator?.startAsLeader(tour: tour) == nil {
            actionError = Self.cantStartMessage
        }
    }

    private func joinGroup() {
        actionError = nil
        if coordinator?.join(code: codeEntry) != true {
            actionError = Self.cantStartMessage
        }
    }

    /// Both failure paths have the same cause (we're not signed in, or the app
    /// hasn't finished wiring up), so they share one actionable message.
    private static let cantStartMessage =
        "Couldn't start a group. Make sure you're signed in, then try again."
}
