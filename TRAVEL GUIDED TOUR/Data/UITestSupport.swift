import Foundation

/// Switches that exist **only** so the App Store screenshot UI test can put
/// the app into a photogenic, deterministic state.
///
/// 🔴 EVERYTHING HERE IS INERT IN A SHIPPING BUILD. Each behaviour is gated on
/// a launch argument that nothing but `ScreenshotUITests` ever passes, and the
/// flags are read **once** from `ProcessInfo` into a `Set` at first use. With
/// no arguments present the app behaves exactly as it did before this file
/// existed — there is no debug menu, no `#if DEBUG`, and no runtime cost
/// beyond one set lookup per flag for the lifetime of the process.
///
/// Why these two switches and not "just wait longer" in the test:
///   - **Marquee.** `MarqueeText` scrolls *continuously* and never comes to
///     rest, so every screenshot caught the mini-player's title mid-word
///     ("DY TO EXPLORE? LET'S FIND AN AUD"). It reads as a rendering bug on
///     the store page. No settle time can fix an animation with no end state.
///   - **Library.** The Library screenshot advertised an app with no content
///     ("LIKED · 0 tours" on a blank screen). Driving the UI to bookmark six
///     tours would add ~40 fragile taps to the run; seeding the store the
///     user-facing save action writes to is both shorter and steadier.
enum UITestSupport {

    // MARK: - Launch arguments

    /// Render `MarqueeText` as static, non-scrolling text.
    static let disableMarqueeArgument = "-UITestDisableMarquee"

    /// Pre-populate `LibraryStore` with a handful of saved tours.
    static let seedLibraryArgument = "-UITestSeedLibrary"

    /// Parsed once. `ProcessInfo.arguments` never changes for a running
    /// process, so caching it keeps `MarqueeText`'s body cheap.
    private static let launchArguments = Set(ProcessInfo.processInfo.arguments)

    static let isMarqueeDisabled = launchArguments.contains(disableMarqueeArgument)
    static let shouldSeedLibrary = launchArguments.contains(seedLibraryArgument)

    // MARK: - Library seeding

    /// Tours the seeded Library shows, in the order they appear. Chosen to be
    /// recognisable, well-photographed New York entries so the Library
    /// screenshot reads as a real collection. Matched by case-insensitive
    /// substring so a small copy edit to a title doesn't silently empty the
    /// list; anything that doesn't match is simply skipped and back-filled.
    private static let preferredSeedTitles = [
        "Empire State Building",
        "Brooklyn Bridge, Manhattan Side",
        "Rockefeller Center",
        "Statue of Liberty",
        "High Line",
        "The South Facade of Grand Central"
    ]

    private static let seedCount = 6

    /// Saves a few tours so the Library screenshot has real rows.
    ///
    /// No-ops unless `-UITestSeedLibrary` was passed, and no-ops again if the
    /// user already has saved tours — so it can never overwrite a real
    /// library, even if the argument somehow reached a real device.
    ///
    /// Writes via `applyMerged`, not `toggleSaved`: that persists without
    /// firing the `onChange` write-through hook, so seeding cannot push
    /// fabricated rows at Supabase if a session ever existed.
    @MainActor
    static func seedLibraryIfRequested(tours: [Tour], into library: LibraryStore) {
        guard shouldSeedLibrary else { return }
        guard library.savedEntries.isEmpty else { return }
        guard !tours.isEmpty else { return }

        var picked: [Tour] = []
        var seen = Set<UUID>()

        for title in preferredSeedTitles {
            guard let match = tours.first(where: {
                $0.title.localizedCaseInsensitiveContains(title)
            }) else { continue }
            if seen.insert(match.id).inserted { picked.append(match) }
        }

        // Back-fill from the head of the catalog if a preferred title has been
        // renamed, so the list is never short.
        for tour in tours where picked.count < seedCount {
            if seen.insert(tour.id).inserted { picked.append(tour) }
        }

        // Stagger `savedAt` so the rendered order matches `preferredSeedTitles`
        // (`savedEntries` sorts newest-saved first).
        let now = Date()
        let entries = picked.prefix(seedCount).enumerated().map { index, tour in
            LibraryEntry(
                tourId: tour.id,
                savedAt: now.addingTimeInterval(-Double(index) * 60)
            )
        }

        library.applyMerged(entries)
    }
}
