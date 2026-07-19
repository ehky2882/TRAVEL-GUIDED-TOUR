import SwiftUI

/// "Add to a Journey" — presented from a tour's overflow menu. Lists the
/// signed-in user's Journeys with a checkmark for the ones already containing
/// this tour; tapping toggles membership. A "New Journey" row creates one and
/// adds the tour in a single step.
///
/// Signed-out users are nudged to sign in (Journeys are a per-account feature).
struct AddToJourneySheet: View {
    let tour: Tour

    @Environment(JourneyService.self) private var journeyService
    @Environment(AuthService.self) private var authService: AuthService?
    @Environment(\.dismiss) private var dismiss

    /// Journey ids that currently contain this tour.
    @State private var member: Set<UUID> = []
    @State private var isLoading = true
    @State private var busyJourney: UUID?
    @State private var showingCreate = false

    private var isSignedIn: Bool { authService?.isSignedIn == true }

    var body: some View {
        NavigationStack {
            Group {
                if !isSignedIn {
                    signedOut
                } else {
                    content
                }
            }
            .background(AtlasColors.secondaryBackground)
            .navigationTitle("Add to a Journey")
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingCreate, onDismiss: reload) {
                JourneyEditorSheet()
            }
        }
        .task { await load() }
    }

    @ViewBuilder
    private var content: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                newJourneyRow
                Divider()

                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, AtlasSpacing.xl)
                } else if journeyService.myJourneys.isEmpty {
                    Text("You don't have any Journeys yet. Create one to start curating.")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, AtlasSpacing.xl)
                        .padding(.horizontal, AtlasSpacing.md)
                } else {
                    ForEach(journeyService.myJourneys) { journey in
                        journeyRow(journey)
                        if journey.id != journeyService.myJourneys.last?.id { Divider() }
                    }
                }
            }
            .padding(.horizontal, AtlasSpacing.lg)
            .padding(.top, AtlasSpacing.md)
        }
    }

    private var newJourneyRow: some View {
        Button {
            showingCreate = true
        } label: {
            HStack(spacing: AtlasSpacing.md) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(AtlasColors.mapPin)
                Text("New Journey")
                    .font(AtlasTypography.body)
                    .foregroundStyle(AtlasColors.primaryText)
                Spacer()
            }
            .padding(.vertical, AtlasSpacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func journeyRow(_ journey: Journey) -> some View {
        Button {
            toggle(journey)
        } label: {
            HStack(spacing: AtlasSpacing.md) {
                VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                    Text(journey.title)
                        .font(AtlasTypography.body)
                        .foregroundStyle(AtlasColors.primaryText)
                        .lineLimit(1)
                    Text(journey.itemCount == 1 ? "1 tour" : "\(journey.itemCount) tours")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                }

                Spacer()

                if busyJourney == journey.id {
                    ProgressView()
                } else {
                    Image(systemName: member.contains(journey.id) ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundStyle(member.contains(journey.id) ? AtlasColors.mapPin : AtlasColors.tertiaryText)
                }
            }
            .padding(.vertical, AtlasSpacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(busyJourney != nil)
        .accessibilityLabel(member.contains(journey.id)
            ? "Remove from \(journey.title)"
            : "Add to \(journey.title)")
    }

    private var signedOut: some View {
        VStack(spacing: AtlasSpacing.md) {
            Spacer()
            JoinDozentPrompt(showIcon: true)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Data

    private func load() async {
        guard isSignedIn else { isLoading = false; return }
        await journeyService.loadMyJourneys()
        member = await journeyService.journeyIdsContaining(tourId: tour.id)
        isLoading = false
    }

    private func reload() {
        Task { await load() }
    }

    private func toggle(_ journey: Journey) {
        busyJourney = journey.id
        Task {
            defer { busyJourney = nil }
            do {
                if member.contains(journey.id) {
                    try await journeyService.removeTour(tour.id, from: journey.id)
                    member.remove(journey.id)
                } else {
                    try await journeyService.addTour(tour.id, to: journey.id)
                    member.insert(journey.id)
                }
            } catch {
                // Leave state as-is on failure.
            }
        }
    }
}
