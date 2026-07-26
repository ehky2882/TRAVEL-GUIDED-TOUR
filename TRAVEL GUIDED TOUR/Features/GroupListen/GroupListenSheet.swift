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

    var body: some View {
        NavigationStack {
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        VStack(spacing: AtlasSpacing.lg) {
            VStack(spacing: AtlasSpacing.sm) {
                Image(systemName: "person.2.wave.2.fill")
                    .font(.system(size: 40))
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
            .padding(.top, AtlasSpacing.lg)

            // Side by side: two equal cards, so the choice reads as one
            // decision rather than a primary action with an afterthought
            // beneath it.
            HStack(spacing: AtlasSpacing.md) {
                Button {
                    startLeading()
                } label: {
                    actionLabel("START", subtitle: "You lead", systemImage: "play.circle.fill", filled: true)
                }
                .buttonStyle(.plain)

                Button {
                    joining = true
                } label: {
                    actionLabel("JOIN", subtitle: "Scan a code", systemImage: "arrow.right.circle", filled: false)
                }
                .buttonStyle(.plain)
            }
            // Equal heights even if one subtitle wraps and the other doesn't:
            // the cards stretch to the row, the row takes its ideal height.
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

            Spacer()
        }
        .padding(.horizontal, AtlasSpacing.lg)
    }

    /// One of the two side-by-side choice cards. Stacked vertically (glyph over
    /// label) rather than the old full-width icon-beside-text row, so both fit
    /// half the width without truncating.
    private func actionLabel(_ title: String, subtitle: String, systemImage: String, filled: Bool) -> some View {
        VStack(spacing: AtlasSpacing.xs) {
            Image(systemName: systemImage).font(.system(size: 22))
            Text(title)
                .font(AtlasTypography.caption)
            Text(subtitle)
                .font(AtlasTypography.caption)
                .foregroundStyle(filled ? AtlasColors.background.opacity(0.8) : AtlasColors.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AtlasSpacing.md)
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
        VStack(spacing: AtlasSpacing.lg) {
            Text("SCAN THE LEADER'S CODE")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.primaryText)
                .padding(.top, AtlasSpacing.lg)

            Button {
                showingScanner = true
            } label: {
                actionLabel("SCAN QR CODE", subtitle: "Fastest", systemImage: "qrcode.viewfinder", filled: true)
            }
            .buttonStyle(.plain)
            .fixedSize(horizontal: false, vertical: true)

            Text("or type it")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.secondaryText)

            TextField("Code", text: $codeEntry)
                .disableAutocorrection(true)
                .multilineTextAlignment(.center)
                .font(.system(.title2, design: .monospaced))
                .padding(AtlasSpacing.md)
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
                    .frame(height: 48)
                    .background(codeEntry.count == 5 ? AtlasColors.mapPin : AtlasColors.tertiaryText)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .disabled(codeEntry.count != 5)

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

            Spacer()
        }
        .padding(.horizontal, AtlasSpacing.lg)
    }

    // MARK: - Active session

    private func activeSession(_ coordinator: GroupListenCoordinator) -> some View {
        VStack(spacing: AtlasSpacing.lg) {
            if coordinator.isLeader {
                VStack(spacing: AtlasSpacing.sm) {
                    Text("YOU'RE LEADING")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                    Text("Let them scan this")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.primaryText)

                    // Scanning beats reading five characters aloud in a busy
                    // museum; the code stays visible right below as the fallback.
                    if let code = coordinator.code {
                        QRCodeView(content: AtlasShareLink.groupJoinURL(code: code).absoluteString)
                    }

                    Text(coordinator.code ?? "—")
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundStyle(AtlasColors.mapPin)
                        .textSelection(.enabled)
                    Text("Or they can tap Join and type it.")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, AtlasSpacing.xl)
            } else {
                VStack(spacing: AtlasSpacing.sm) {
                    Image(systemName: coordinator.leaderLost ? "person.fill.questionmark" : "person.2.wave.2.fill")
                        .font(.system(size: 40))
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
                .padding(.top, AtlasSpacing.xl)
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
                    .frame(height: 48)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.5), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .padding(.top, AtlasSpacing.sm)

            Spacer()
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
        VStack(spacing: AtlasSpacing.md) {
            Spacer()
            JoinDozentPrompt(showIcon: true)
            Spacer()
        }
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
