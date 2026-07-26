import Foundation

/// Binds the `SaveState` rules to the two stores behind them, so every bookmark
/// surface — the home cards, tour detail, the player — shares one
/// implementation of "is this saved" and "what does a tap do."
///
/// `journeyService` is optional on purpose. Tour detail and the player are
/// hosted in UIKit slide-up layers that only receive the services `ContentView`
/// explicitly injects, so a surface can legitimately have no journeys service.
/// When it's absent this degrades to Liked-only — which is also exactly what a
/// signed-out user gets, since named lists need an account.
/// Deliberately *not* `@MainActor`-annotated: it's constructed inside view
/// bodies and button actions, matching how the existing journeys sheet already
/// reaches into `JourneyService` from those contexts.
struct TourSaveActions {
    let libraryStore: LibraryStore
    let journeyService: JourneyService?

    /// Is this tour in Liked?
    func isLiked(_ tourId: UUID) -> Bool {
        libraryStore.isSaved(tourId)
    }

    /// The named lists containing this tour. O(number of lists) — only called
    /// on a tap, never while drawing a card.
    func lists(for tourId: UUID) -> Set<UUID> {
        journeyService?.listsContaining(tourId: tourId) ?? []
    }

    /// Saved = in at least one list, Liked included.
    ///
    /// Deliberately reads the flat `allListedTourIds` set rather than
    /// `lists(for:)`: this runs for every card in every rail, so it has to stay
    /// an O(1) lookup.
    func isSaved(_ tourId: UUID) -> Bool {
        if libraryStore.isSaved(tourId) { return true }
        return journeyService?.allListedTourIds.contains(tourId) ?? false
    }

    /// How many lists this tour is in, Liked included.
    func placeCount(_ tourId: UUID) -> Int {
        SaveState.placeCount(isLiked: isLiked(tourId), listIds: lists(for: tourId))
    }

    /// Apply a bookmark tap.
    ///
    /// - Returns: `true` when the tour is in several lists and the caller should
    ///   present the membership sheet instead of having guessed for the user.
    @discardableResult
    func handleTap(_ tourId: UUID) -> Bool {
        switch SaveState.tapAction(isLiked: isLiked(tourId), listIds: lists(for: tourId)) {
        case .addToLiked, .removeFromLiked:
            libraryStore.toggleSaved(tourId)
            return false
        case .removeFromList(let listId):
            // Un-saving the last place it lived. Haptic here so the feedback
            // matches the Liked path, which gets one inside `toggleSaved`.
            AtlasHaptics.selection()
            Task { try? await journeyService?.removeTour(tourId, from: listId) }
            return false
        case .chooseLists:
            return true
        }
    }

    /// The label a bookmark control should carry, for VoiceOver and for the
    /// overflow-menu item that spells the action out in words.
    func accessibilityLabel(_ tourId: UUID) -> String {
        guard isSaved(tourId) else { return "Save tour" }
        return placeCount(tourId) > 1 ? "Saved in several lists. Choose where to keep it" : "Saved"
    }
}
