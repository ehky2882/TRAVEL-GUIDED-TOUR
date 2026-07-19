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
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Chooser

    private var chooser: some View {
        VStack(spacing: AtlasSpacing.lg) {
            VStack(spacing: AtlasSpacing.sm) {
                Image(systemName: "person.2.wave.2.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(AtlasColors.mapPin)
                Text("Listen to this tour together, in sync.")
                    .font(AtlasTypography.body)
                    .foregroundStyle(AtlasColors.primaryText)
                    .multilineTextAlignment(.center)
                Text("One person leads; everyone nearby hears the same words at the same moment. Works offline over Bluetooth.")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, AtlasSpacing.xl)

            VStack(spacing: AtlasSpacing.md) {
                Button {
                    startLeading()
                } label: {
                    actionLabel("Start a group", subtitle: "You lead", systemImage: "play.circle.fill", filled: true)
                }
                .buttonStyle(.plain)

                Button {
                    joining = true
                } label: {
                    actionLabel("Join a group", subtitle: "Enter a code", systemImage: "arrow.right.circle", filled: false)
                }
                .buttonStyle(.plain)
            }

            if let coordinator, !coordinator.isTourDownloaded(tour) {
                Label("For a reliable offline session, download this tour first (⋯ → Download).",
                      systemImage: "wifi.slash")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, AtlasSpacing.sm)
            }

            Spacer()
        }
        .padding(.horizontal, AtlasSpacing.lg)
    }

    private func actionLabel(_ title: String, subtitle: String, systemImage: String, filled: Bool) -> some View {
        HStack(spacing: AtlasSpacing.md) {
            Image(systemName: systemImage).font(.system(size: 22))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(AtlasTypography.body)
                Text(subtitle).font(AtlasTypography.caption)
                    .foregroundStyle(filled ? AtlasColors.background.opacity(0.8) : AtlasColors.secondaryText)
            }
            Spacer()
        }
        .padding(AtlasSpacing.md)
        .frame(maxWidth: .infinity)
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
            Text("Enter the leader's code")
                .font(AtlasTypography.body)
                .foregroundStyle(AtlasColors.primaryText)
                .padding(.top, AtlasSpacing.xl)

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
                coordinator?.join(code: codeEntry)
            } label: {
                Text("Join")
                    .font(AtlasTypography.body)
                    .foregroundStyle(AtlasColors.background)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(codeEntry.count == 5 ? AtlasColors.mapPin : AtlasColors.tertiaryText)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .disabled(codeEntry.count != 5)

            Button("Back") { joining = false }
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
                    Text("Share this code")
                        .font(AtlasTypography.body)
                        .foregroundStyle(AtlasColors.primaryText)
                    Text(coordinator.code ?? "—")
                        .font(.system(size: 44, weight: .bold, design: .monospaced))
                        .foregroundStyle(AtlasColors.mapPin)
                        .textSelection(.enabled)
                    Text("Others: ⋯ → Listen together → Join → enter this code.")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                        .multilineTextAlignment(.center)
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
                        .font(AtlasTypography.body)
                        .foregroundStyle(AtlasColors.primaryText)
                    Text(coordinator.leaderLost
                         ? "Playback paused. Leave and rejoin, or start your own group."
                         : "Your audio mirrors the leader — sit back and listen.")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, AtlasSpacing.xl)
            }

            Label(coordinator.participantCount == 1
                  ? "Just you so far"
                  : "\(coordinator.participantCount) listening",
                  systemImage: "person.3.fill")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.secondaryText)

            Button {
                coordinator.leave()
                dismiss()
            } label: {
                Text("Leave group")
                    .font(AtlasTypography.body)
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
        _ = coordinator?.startAsLeader(tour: tour)
    }
}
