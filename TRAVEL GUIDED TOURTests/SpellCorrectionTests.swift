import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// Pins `SearchSpellCorrector` to the behaviour that was measured, not assumed.
///
/// 🔴 EVERY CASE HERE CAME FROM A REAL MEASUREMENT, and three of them are
/// regressions the first implementation actually had. A prototype run against
/// the live catalog turned `deko` into `deno`, `loby` into `lobo` and `towr`
/// into `tour` — because it stopped at the first candidate one edit away, and
/// several words sit one edit from a typo. These tests exist so that cannot
/// come back quietly.
///
/// ⚠️ THE "MUST NOT TOUCH" HALF MATTERS MORE THAN THE CORRECTIONS. A speller
/// that fixes typos and also mangles `Soho`, `Gion` or `Naoshima` is worse than
/// no speller: it breaks searches that used to work. Those assertions are the
/// ones to keep if this file ever has to shrink.
final class SpellCorrectionTests: XCTestCase {

    /// A corpus small enough to read, shaped like the real catalog: the
    /// frequency skews that decide the tie-breaks are reproduced deliberately.
    private func makeCorrector() -> SearchSpellCorrector {
        // "deco" must out-number "deno", and "tower" out-number "tour", or the
        // tie-break has nothing to break the tie with — the same skew the live
        // catalog has (deco 56/deno 1, tower 169/tour 7).
        let titles = [
            "Radio City Music Hall Art Deco Interior",
            "Art Deco Miami Beach",
            "The Art Deco Lobby",
            // 🔴 TWICE, NOT ONCE. At one use these would fall below
            // `minimumTargetCount` and be excluded as correction targets
            // outright — so the test would pass without the frequency
            // tie-break existing at all. They have to be eligible AND rarer
            // for the assertion to mean anything.
            "Deno Grill", "Deno Bar",
            "Trellick Tower", "Balfron Tower", "Tower Bridge", "Tower of London",
            "A Walking Tour", "Tour of the Docks",
            "The British Museum", "Museum of Modern Art",
            "The Japanese Hill-and-Pond Garden", "Japanese Garden Walk",
            "Soho Square", "Gion", "Naoshima", "Barbican Estate",
            "Borough Market", "Food Market Walk",
            // ⚠️ "Brutalist" TWICE. Every word a test expects as a correction
            // TARGET must clear `minimumTargetCount`, and at one use this
            // silently was not a candidate at all — the assertion failed
            // against a corpus problem, not a code one. The live catalog has
            // it many times over, so the behaviour was always right there.
            "Brutalist Concrete Tower", "Brutalist London", "Concrete Housing",
            "Saint Paul's Cathedral", "Cathedral Quarter",
            "A Good Restaurant", "Restaurant Row",
            "Stained Glass Windows", "Glass House", "Windows on the World",
        ]
        let tours = titles.enumerated().map { index, title in
            TestFixtures.makeTour(
                title: title,
                city: index.isMultiple(of: 2) ? "London" : "Tokyo",
                // `lobby` appears ONLY here, never in a title — which is the
                // whole point of the test below. Twice, so it clears
                // `minimumTargetCount`.
                shortDescription: title.contains("Lobby")
                    ? "A grand lobby with a lobby ceiling."
                    : "A short description."
            )
        }
        return SearchSpellCorrector(tours: tours, makerNames: ["Atlas Studio LDN"])
    }

    /// 🔴 GUARDS THE CORPUS, NOT THE CODE. Every word the tests below expect a
    /// typo to land on has to occur at least `minimumTargetCount` times, or it
    /// is not an eligible target and the assertion fails for a reason that has
    /// nothing to do with the corrector. That happened once: "Brutalist"
    /// appeared in a single title.
    func testTheCorpusMakesEveryExpectedTargetEligible() {
        let corrector = makeCorrector()
        // If a word is a valid target, a one-edit typo of it must resolve back.
        let targets = ["museum": "musuem", "tower": "towr", "deco": "deko",
                       "cathedral": "cathedrel", "restaurant": "resturant",
                       "japanese": "japanees", "garden": "gardn",
                       "brutalist": "brutalst", "lobby": "loby"]
        for (word, typo) in targets {
            XCTAssertEqual(corrector.corrected(typo), word,
                           "\(word) is not an eligible correction target in the "
                           + "test corpus — it needs at least "
                           + "\(SearchSpellCorrector.minimumTargetCount) uses")
        }
    }

    // MARK: - It fixes what it should

    func testFixesTyposAgainstTheCatalogsOwnWords() {
        let corrector = makeCorrector()
        let cases: [(String, String)] = [
            ("musuem", "museum"),               // transposition — Damerau, not Levenshtein
            ("towr", "tower"),                  // was "tour" before frequency tie-breaking
            ("cathedrel", "cathedral"),
            ("resturant", "restaurant"),
            ("japanees garden", "japanese garden"),
            ("brutalst concrete tower", "brutalist concrete tower"),
        ]
        for (typed, expected) in cases {
            XCTAssertEqual(corrector.corrected(typed), expected,
                           "\(typed) should correct to \(expected)")
        }
    }

    /// 🔴 The three that the first implementation got wrong.
    func testPicksTheFrequentWordWhenSeveralAreOneEditAway() {
        let corrector = makeCorrector()
        // Both alternatives are eligible targets here — see the corpus note.
        // The only thing separating them is how often they occur.
        XCTAssertEqual(corrector.corrected("deko"), "deco",
                       "'deno' is one edit away too, and rarer")
        XCTAssertEqual(corrector.corrected("towr"), "tower",
                       "'tour' is one edit away too, and rarer")
    }

    /// `lobby` lives only in a description, never in a title. Excluding
    /// shortDescription from the vocabulary left `loby` with nothing to correct
    /// to but a one-off word.
    func testReachesWordsThatOnlyAppearInShortDescriptions() {
        XCTAssertEqual(makeCorrector().corrected("loby"), "lobby")
    }

    // MARK: - 🔴 It leaves alone what it must

    func testNeverTouchesAWordTheCatalogKnows() {
        let corrector = makeCorrector()
        for query in ["museum", "soho", "gion", "naoshima", "barbican", "tokyo",
                      "food market", "brutalist concrete tower", "tower"] {
            XCTAssertNil(corrector.corrected(query),
                         "\(query) is a real catalog word and must be left alone")
        }
    }

    func testLeavesShortWordsAlone() {
        // At three letters almost everything is one edit from something else,
        // so corrections stop being inference and become noise.
        XCTAssertNil(makeCorrector().corrected("fud"))
    }

    /// ⚠️ A character-level edit distance over ideographs is meaningless — one
    /// substitution can change the word entirely — and a CJK title has no
    /// spaces to tokenise on. Those queries pass through untouched.
    func testLeavesNonLatinQueriesAlone() {
        let corrector = makeCorrector()
        for query in ["祇園", "ベネッセハウス", "문무묘", "ตลาดน้ำ"] {
            XCTAssertNil(corrector.corrected(query))
        }
    }

    func testReturnsNilRatherThanTheOriginalWhenNothingChanged() {
        // The caller has to be able to tell a correction happened, because a
        // corrected search must say so on screen.
        XCTAssertNil(makeCorrector().corrected("museum"))
        XCTAssertNil(makeCorrector().corrected(""))
        XCTAssertNil(makeCorrector().corrected("   "))
    }

    // MARK: - The distance function itself

    func testEditDistanceCountsATranspositionAsOne() {
        // The reason for Damerau over Levenshtein: under plain Levenshtein this
        // is 2, and a word shorter than six letters never gets a budget of 2.
        XCTAssertEqual(SearchSpellCorrector.editDistance("musuem", "museum", limit: 2), 1)
        XCTAssertEqual(SearchSpellCorrector.editDistance("towr", "tower", limit: 2), 1)
        XCTAssertEqual(SearchSpellCorrector.editDistance("abc", "abc", limit: 2), 0)
    }

    func testEditDistanceGivesUpOnceItPassesTheLimit() {
        // Bounded so a scan of thousands of candidates stays cheap while typing.
        XCTAssertEqual(
            SearchSpellCorrector.editDistance("aaaaaaaa", "zzzzzzzz", limit: 2), Int.max
        )
    }
}
