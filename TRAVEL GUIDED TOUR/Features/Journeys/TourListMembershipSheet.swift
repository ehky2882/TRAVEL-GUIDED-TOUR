import SwiftUI

/// Where a tour is kept — the one screen that answers "which lists is this in?"
/// and lets the user change it.
///
/// **Liked** is always the first row. It's the default list (`SaveState`),
/// backed by `LibraryStore`, so it works signed out exactly as bookmarking
/// always has. Named lists live in Supabase and need an account, so a
/// signed-out user gets Liked plus a sign-in nudge rather than a dead end.
///
/// Reached two ways: from a tour's overflow menu, and from a bookmark tap on a
/// tour that already sits in several lists — which is why this sheet removes as
/// well as adds. Nothing is ever moved implicitly: filing a tour into a named
/// list doesn't pull it out of Liked, the user unticks Liked if that's what
/// they want.
struct TourListMembershipSheet: View {
    let tour: Tour

    @Environment(LibraryStore.self) private var libraryStore
    @Environment(JourneyService.self) private var journeyService: JourneyService?
    @Environment(AuthService.self) private var authService: AuthService?
    @Environment(\.dismiss) private var dismiss

    /// Named-list ids that currently contain this tour.
    @State private var member: Set<UUID> = []
    @State private var isLoading = true
    @State private var busyList: UUID?
    @State private var showingCreate = false

    private var isSignedIn: Bool { authService?.isSignedIn == true }
    private var lists: [Journey] { journeyService?.myJourneys ?? [] }

    var body: some View {
        NavigationStack {
            content
                .background(AtlasColors.secondaryBackground)
                .navigationTitle("Save to")
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
                likedRow
                Divider()

                if isSignedIn, journeyService != nil {
                    newListRow

                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, AtlasSpacing.xl)
                    } else {
                        ForEach(lists) { list in
                            Divider()
                            listRow(list)
                        }
                    }
                } else {
                    // Liked still works signed out; named lists need an account.
                    JoinDozentPrompt(showIcon: false)
                        .padding(.top, AtlasSpacing.lg)
                }
            }
            .padding(.horizontal, AtlasSpacing.lg)
            .padding(.top, AtlasSpacing.md)
        }
    }

    /// The default list. Always present, always first, never deletable.
    private var likedRow: some View {
        let isLiked = libraryStore.isSaved(tour.id)
        return Button {
            libraryStore.toggleSaved(tour.id)
        } label: {
            HStack(spacing: AtlasSpacing.md) {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(AtlasColors.mapPin)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                    Text("Liked")
                        .font(AtlasTypography.body)
                        .foregroundStyle(AtlasColors.primaryText)
                    Text(countLabel(libraryStore.savedEntries.count))
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                }

                Spacer()

                checkmark(isOn: isLiked)
            }
            .padding(.vertical, AtlasSpacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isLiked ? "Remove from Liked" : "Add to Liked")
    }

    private var newListRow: some View {
        Button {
            showingCreate = true
        } label: {
            HStack(spacing: AtlasSpacing.md) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(AtlasColors.mapPin)
                    .frame(width: 28)
                Text("New list")
                    .font(AtlasTypography.body)
                    .foregroundStyle(AtlasColors.primaryText)
                Spacer()
            }
            .padding(.vertical, AtlasSpacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func listRow(_ list: Journey) -> some View {
        Button {
            toggle(list)
        } label: {
            HStack(spacing: AtlasSpacing.md) {
                Image(systemName: "map")
                    .font(.system(size: 20))
                    .foregroundStyle(AtlasColors.secondaryText)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                    Text(list.title)
                        .font(AtlasTypography.body)
                        .foregroundStyle(AtlasColors.primaryText)
                        .lineLimit(1)
                    Text(countLabel(list.itemCount))
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                }

                Spacer()

                if busyList == list.id {
                    ProgressView()
                } else {
                    checkmark(isOn: member.contains(list.id))
                }
            }
            .padding(.vertical, AtlasSpacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(busyList != nil)
        .accessibilityLabel(member.contains(list.id)
            ? "Remove from \(list.title)"
            : "Add to \(list.title)")
    }

    private func checkmark(isOn: Bool) -> some View {
        Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
            .font(.system(size: 22))
            .foregroundStyle(isOn ? AtlasColors.mapPin : AtlasColors.tertiaryText)
    }

    private func countLabel(_ count: Int) -> String {
        count == 1 ? "1 tour" : "\(count) tours"
    }

    // MARK: - Data

    private func load() async {
        guard isSignedIn, let journeyService else { isLoading = false; return }
        await journeyService.loadMyJourneys()
        member = journeyService.listsContaining(tourId: tour.id)
        isLoading = false
    }

    private func reload() {
        Task { await load() }
    }

    private func toggle(_ list: Journey) {
        guard let journeyService else { return }
        busyList = list.id
        Task {
            defer { busyList = nil }
            do {
                if member.contains(list.id) {
                    try await journeyService.removeTour(tour.id, from: list.id)
                    member.remove(list.id)
                } else {
                    try await journeyService.addTour(tour.id, to: list.id)
                    member.insert(list.id)
                }
            } catch {
                // Leave state as-is on failure.
            }
        }
    }
}
