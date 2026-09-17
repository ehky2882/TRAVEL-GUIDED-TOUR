import Foundation

/// Fixes typos in a search query against the catalog's own words.
///
/// WHY THIS EXISTS
/// ---------------
/// Both halves of search were completely unforgiving about spelling, in
/// different ways. Measured on the live catalog:
///
///     museum       → The British Museum        musuem      → NOTHING
///     food market  → Ben Thanh Market          fud markit  → NOTHING
///     art deco lobby → Radio City Music Hall   art deko loby → wrong tour
///
/// The keyword list is a literal substring test, so `musuem` matches no text
/// anywhere. The semantic half chops an unknown word into subword fragments
/// that no longer resemble the real one, so it drifts to something related or
/// falls under the floor. **Neither half had any notion that a word was
/// misspelled**, so a single transposed letter returned an empty screen.
///
/// 🔴 THE DICTIONARY IS THE CATALOG ITSELF, NOT ENGLISH. A general speller
/// would "correct" Naoshima, Kubuswoningen or Trellick into nonsense, and would
/// not know that `bt` should become `bthanh`. Every word here came from a title,
/// city, country, maker, tag or category we actually ship — so a correction can
/// only ever move a query toward something the catalog contains.
///
/// ⚠️ IT CORRECTS ONLY WHAT IT DOES NOT RECOGNISE. A word already in the
/// catalog is never touched, whatever it looks like. That is what stops "soho"
/// becoming "sofa".
struct SearchSpellCorrector {

    /// Below this, a word is too short to correct safely: at three letters,
    /// almost everything is within one edit of something else, and the
    /// corrections stop being guesses and start being noise. It is why "fud"
    /// does not become "food" — accepted deliberately, in exchange for never
    /// mangling a short real word.
    static let minimumLength = 4

    /// Words this long or more may be two edits out; shorter ones get one.
    /// A two-edit correction on a five-letter word changes too much of it.
    static let twoEditLength = 6

    /// 🔴 A word must appear at least twice to be something we correct TO.
    /// Without this, `loby` became `lobo` — a word occurring exactly once in
    /// the whole catalog. Correcting a typo into a hapax is almost always
    /// wrong, and there are thousands of them to land on.
    static let minimumTargetCount = 2

    /// Every distinct word in the catalog, lowercased, `minimumLength`+.
    ///
    /// ⚠️ THIS IS THE FULL SET, INCLUDING ONE-OFF WORDS, and that is deliberate:
    /// it answers "do I recognise this?", which must stay generous so a rare
    /// real word is never treated as a typo. `byFirstCharacter` below answers
    /// the different question "what may I correct TO?", and that one is strict.
    private let vocabulary: Set<String>

    /// Correction targets bucketed by first character, **most frequent first**.
    ///
    /// A typo rarely changes the first letter, so this turns a scan of ~10,000
    /// words into a few hundred — which matters because this runs while someone
    /// is typing. The frequency ordering is not an optimisation: combined with
    /// a strictly-better comparison it is what picks the right word when
    /// several sit the same distance away. `deko` is one edit from both `deco`
    /// (56 uses) and `deno` (1); `towr` from `tower` (169) and `tour` (7).
    private let byFirstCharacter: [Character: [String]]

    // MARK: - Building

    init(tours: [Tour], makerNames: [String]) {
        var counts: [String: Int] = [:]

        func absorb(_ text: String) {
            for word in Self.words(in: text) { counts[word, default: 0] += 1 }
        }
        for tour in tours {
            absorb(tour.title)
            absorb(tour.primaryCategory.displayName)
            for tag in tour.tags { absorb(tag) }
            if let city = tour.city { absorb(city) }
            if let country = tour.country { absorb(country) }
            // `shortDescription` IS included; `longDescription` is not.
            // The keyword search reads both, so words in either are fairly
            // searchable — but the long one is prose, and it would triple the
            // vocabulary with words nobody types while adding thousands more
            // one-off targets to land on wrongly. The short one is where
            // ordinary vocabulary like "lobby" lives, which titles do not
            // contain and which a query plainly should be able to reach.
            absorb(tour.shortDescription)
        }
        for name in makerNames { absorb(name) }

        self.vocabulary = Set(counts.keys)
        var buckets: [Character: [String]] = [:]
        for (word, count) in counts
        where count >= Self.minimumTargetCount && !word.isEmpty {
            buckets[word.first!, default: []].append(word)
        }
        // Most frequent first — see the property comment; this ordering is
        // load-bearing, not cosmetic.
        for key in buckets.keys {
            buckets[key]?.sort {
                counts[$0, default: 0] == counts[$1, default: 0]
                    ? $0 < $1
                    : counts[$0, default: 0] > counts[$1, default: 0]
            }
        }
        self.byFirstCharacter = buckets
    }

    /// Splits text the way someone types it, and keeps only what is worth
    /// correcting.
    ///
    /// ⚠️ LATIN LETTERS ONLY. A CJK title has no spaces to split on and a
    /// character-level edit distance over ideographs is meaningless — one
    /// substitution can change the word entirely. Those queries are left
    /// exactly as typed rather than guessed at.
    static func words(in text: String) -> [String] {
        text.lowercased()
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
            .filter { $0.count >= minimumLength && $0.allSatisfy(\.isASCII) }
    }

    // MARK: - Correcting

    /// The query with unrecognised words replaced, or nil when nothing changed.
    ///
    /// Returning nil rather than the original is deliberate: the caller needs to
    /// know whether a correction happened, because a corrected search has to say
    /// so on screen. Silently changing what someone typed is worse than
    /// returning nothing.
    func corrected(_ query: String) -> String? {
        var changed = false
        // Rebuilt from the original so punctuation and case survive: only the
        // tokens that were actually replaced differ.
        let pieces = query.split(separator: " ", omittingEmptySubsequences: false)
        let fixed = pieces.map { piece -> String in
            let token = String(piece)
            let bare = token.lowercased().filter { $0.isLetter || $0.isNumber }
            guard bare.count >= Self.minimumLength, bare.allSatisfy(\.isASCII),
                  !vocabulary.contains(bare),
                  let best = nearest(to: bare)
            else { return token }
            changed = true
            return token.replacingOccurrences(
                of: bare, with: best, options: [.caseInsensitive]
            )
        }
        return changed ? fixed.joined(separator: " ") : nil
    }

    /// The closest catalog word, or nil if nothing is close enough.
    private func nearest(to word: String) -> String? {
        guard let first = word.first else { return nil }
        let budget = word.count >= Self.twoEditLength ? 2 : 1

        var best: String?
        var bestDistance = budget + 1
        // Same first letter, and within the edit budget in length — a word
        // three letters longer cannot be two edits away.
        //
        // 🔴 NO EARLY EXIT ON distance == 1, and this cost a bug. Stopping at
        // the first one-edit match takes whichever candidate happened to come
        // first, which is arbitrary: `deko` became `deno`, `loby` became `lobo`
        // and `towr` became `tour`. The list is frequency-ordered and the test
        // below is STRICTLY better, so the first candidate at the winning
        // distance is the most frequent one — which is the answer we want.
        for candidate in byFirstCharacter[first] ?? [] {
            guard abs(candidate.count - word.count) <= budget else { continue }
            let distance = Self.editDistance(word, candidate, limit: bestDistance - 1)
            guard distance < bestDistance else { continue }
            bestDistance = distance
            best = candidate
        }
        return best
    }

    /// Damerau-Levenshtein, bounded — it gives up as soon as every cell in a
    /// row exceeds `limit`.
    ///
    /// 🔴 TRANSPOSITION IS THE WHOLE POINT of using Damerau rather than plain
    /// Levenshtein. `musuem` → `museum` is two substitutions but ONE swap, and
    /// swapping adjacent letters is the most common typo there is. Under plain
    /// Levenshtein it needs the full two-edit budget, which a five-letter word
    /// never gets.
    static func editDistance(_ a: String, _ b: String, limit: Int) -> Int {
        if limit < 0 { return Int.max }
        let x = Array(a), y = Array(b)
        if x.isEmpty { return y.count }
        if y.isEmpty { return x.count }

        var previous2 = [Int](repeating: 0, count: y.count + 1)
        var previous = Array(0...y.count)
        var current = [Int](repeating: 0, count: y.count + 1)

        for i in 1...x.count {
            current[0] = i
            var rowBest = current[0]
            for j in 1...y.count {
                let cost = x[i - 1] == y[j - 1] ? 0 : 1
                var value = min(
                    previous[j] + 1,          // deletion
                    current[j - 1] + 1,       // insertion
                    previous[j - 1] + cost    // substitution
                )
                if i > 1, j > 1, x[i - 1] == y[j - 2], x[i - 2] == y[j - 1] {
                    value = min(value, previous2[j - 2] + 1)   // transposition
                }
                current[j] = value
                rowBest = min(rowBest, value)
            }
            // Nothing in this row can still come in under the limit, and every
            // later row is at least as large.
            if rowBest > limit { return Int.max }
            previous2 = previous
            previous = current
            current = [Int](repeating: 0, count: y.count + 1)
        }
        return previous[y.count]
    }
}
