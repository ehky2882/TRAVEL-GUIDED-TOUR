import Foundation

/// Everything the home filter row can ask of a tour, in one value.
///
/// Replaces the pair of fields the row used to carry (`selectedTags` plus a
/// `walksOnly` flag) with four groups: **Format · Price · Dozents · Tags**.
/// The combine rule is unchanged and is the same at every level —
/// **any within a group, all across groups** (owner decision D6).
///
/// 🔴 **The number of chips in the row is presentation, not semantics.** This
/// type is why: `Tag.matches` already takes one flat `Set<String>` and derives
/// each tag's facet itself, so collapsing five facet chips into a single `Tags`
/// chip changed the UI and nothing about the filtering. Do not "simplify" the
/// row by pushing layout decisions in here.
///
/// Pure and `Equatable` — no `Tour` array, no location, no services — so the
/// predicate and the option counts are testable without a catalogue.
/// Design + reasoning: `docs/filter-chips-design.md`.
struct TourFilter: Equatable {

    /// What the pin IS. Any-of: `Audio walk` + `TikTok` means either.
    var formats: Set<FormatOption> = []
    /// What it costs. Both selected is the same as neither.
    var prices: Set<PriceOption> = []
    /// Whose it is — maker ids, any-of.
    var makerIds: Set<UUID> = []
    /// The whole controlled vocabulary. Combines per `Tag.matches`: any within
    /// a facet, all across facets, so this one `Set` carries both halves of the
    /// rule by itself.
    var tags: Set<String> = []

    static let none = TourFilter()

    var isActive: Bool {
        !formats.isEmpty || !prices.isEmpty || !makerIds.isEmpty || !tags.isEmpty
    }

    /// How many values are switched on, for the `All` chip's badge. Counts
    /// values rather than groups: three tags and a price reads as 4, which is
    /// what someone glancing at the badge is asking.
    var valueCount: Int {
        formats.count + prices.count + makerIds.count + tags.count
    }

    // MARK: - The predicate

    /// AND across the four groups; OR inside each. An empty group is not a
    /// filter, so it matches everything — which is what makes the whole thing
    /// collapse to `true` when nothing is selected.
    func matches(_ tour: Tour) -> Bool {
        if !formats.isEmpty, !formats.contains(where: { $0.matches(tour) }) { return false }
        if !prices.isEmpty, !prices.contains(where: { $0.matches(tour) }) { return false }
        if !makerIds.isEmpty, !makerIds.contains(tour.makerId) { return false }
        return Tag.matches(tourTags: Set(tour.tags), selection: tags)
    }

    // MARK: - Contextual counts

    /// How many tours would match if `option` were also selected.
    ///
    /// 🔴 **Counts MUST be contextual, not global, and this is not a nicety.**
    /// `Contemporary` matches 401 tours on its own and **zero** alongside
    /// `Museum + Market + Food + Hidden Gem`. A global count beside an option
    /// is a lie the moment anything else is on, and it invites the one tap that
    /// empties the map. Options that would yield 0 are shown dimmed rather than
    /// hidden: a chip that vanishes reads as a bug, and "impossible here" is
    /// information.
    ///
    /// Adding a value to a group WIDENS that group (OR), so the count can go up
    /// as well as down — which is correct and is why this asks "if it were also
    /// selected" rather than "how many have this tag".
    /// ⚠️ **Cost.** One call is a linear pass over the catalogue, so a panel
    /// showing ~25 options does ~85,000 predicate evaluations — a few
    /// milliseconds, paid once per tap rather than per frame (the panels use
    /// eager stacks, not lazy ones, so scrolling re-evaluates nothing). If a
    /// panel ever grows well past that, cache into a `[FilterOption: Int]`
    /// keyed on the filter — and do NOT substitute the global tag counts, for
    /// the reason directly above.
    func count(adding option: FilterOption, in tours: [Tour]) -> Int {
        var probe = self
        probe.toggle(option)
        // A toggle that turned the option OFF would answer the wrong question.
        if !probe.contains(option) { probe = self; probe.insert(option) }
        return tours.reduce(into: 0) { total, tour in
            if probe.matches(tour) { total += 1 }
        }
    }

    /// Matches for the filter as it stands — what the commit pill shows.
    func matchCount(in tours: [Tour]) -> Int {
        tours.reduce(into: 0) { total, tour in
            if matches(tour) { total += 1 }
        }
    }

    // MARK: - Mutation

    func contains(_ option: FilterOption) -> Bool {
        switch option {
        case .format(let f): return formats.contains(f)
        case .price(let p): return prices.contains(p)
        case .maker(let id): return makerIds.contains(id)
        case .tag(let t): return tags.contains(t)
        }
    }

    mutating func insert(_ option: FilterOption) {
        switch option {
        case .format(let f): formats.insert(f)
        case .price(let p): prices.insert(p)
        case .maker(let id): makerIds.insert(id)
        case .tag(let t): tags.insert(t)
        }
    }

    mutating func remove(_ option: FilterOption) {
        switch option {
        case .format(let f): formats.remove(f)
        case .price(let p): prices.remove(p)
        case .maker(let id): makerIds.remove(id)
        case .tag(let t): tags.remove(t)
        }
    }

    mutating func toggle(_ option: FilterOption) {
        if contains(option) { remove(option) } else { insert(option) }
    }

    /// Clear one group — what a panel's own `Clear` does.
    mutating func clear(_ group: FilterGroup) {
        switch group {
        case .format: formats = []
        case .price: prices = []
        case .dozents: makerIds = []
        case .tags: tags = []
        }
    }

    /// The values on in one group, for the chip's collapsed label.
    func values(in group: FilterGroup, makerName: (UUID) -> String?) -> [String] {
        switch group {
        case .format: return FormatOption.allCases.filter(formats.contains).map(\.label)
        case .price: return PriceOption.allCases.filter(prices.contains).map(\.label)
        case .dozents: return makerIds.compactMap(makerName).sorted()
        case .tags: return Tag.ordered(tags)
        }
    }
}

// MARK: - Groups

/// The four chips, in row order: what it is · what it costs · whose it is ·
/// what it is tagged. The first three are **structural fields** on `Tour`
/// (`kind`, `priceTier`, `makerId`) and get a chip each because each asks a
/// different kind of question; the fourth is the entire vocabulary, because
/// that is all one kind of question.
enum FilterGroup: String, CaseIterable, Identifiable {
    case format, price, dozents, tags

    var id: String { rawValue }

    /// Shown on the chip when nothing in the group is selected, and as the
    /// panel's title. Uppercased at the call site, not here.
    var title: String {
        switch self {
        case .format: return "Format"
        case .price: return "Price"
        case .dozents: return "Dozents"
        case .tags: return "Tags"
        }
    }
}

/// One selectable value, whichever group it belongs to. Lets a panel — and in
/// particular the **All** panel, which shows every group at once — hand back a
/// single thing to toggle.
enum FilterOption: Hashable {
    case format(FormatOption)
    case price(PriceOption)
    case maker(UUID)
    case tag(String)
}

// MARK: - Format

/// What the pin actually is, split by platform AND by short-form format, in
/// each platform's own words: **Reels** and **Shorts** are product names and
/// take a capital, **videos** and **posts** are generic and do not. TikTok
/// brands nothing separately, so it is one option.
///
/// ⚠️ Two of these are tiny — Shorts at 3 pins, Instagram posts at 9 — which
/// cuts against the rule that an option finding a handful reads as broken (the
/// rule still keeping `videoRole`-carrying tours out of this list, at 1 tour).
/// Owner decision, 2026-09-12, and the reason is reachability: picking
/// `instagramReels` excludes those 9 posts and **nothing else would select
/// them**.
enum FormatOption: String, CaseIterable, Identifiable {
    case audioStop, audioWalk, instagramPosts, instagramReels, tiktok, youtubeShorts, youtubeVideos

    var id: String { rawValue }

    /// Alphabetical, which is also `allCases` order — see `Tag.promoted` for
    /// why display order is alphabetical everywhere in this design.
    var label: String {
        switch self {
        case .audioStop: return "Audio stop"
        case .audioWalk: return "Audio walk"
        case .instagramPosts: return "Instagram posts"
        case .instagramReels: return "Instagram Reels"
        case .tiktok: return "TikTok"
        case .youtubeShorts: return "YouTube Shorts"
        case .youtubeVideos: return "YouTube videos"
        }
    }

    func matches(_ tour: Tour) -> Bool {
        switch self {
        case .audioStop: return tour.kind == .single
        case .audioWalk: return tour.kind == .multiStop
        case .instagramPosts:
            return tour.linkSource == .instagram && !isReel(tour)
        case .instagramReels:
            return tour.linkSource == .instagram && isReel(tour)
        case .tiktok: return tour.linkSource == .tiktok
        case .youtubeShorts:
            return tour.linkSource == .youtube && isShort(tour)
        case .youtubeVideos:
            return tour.linkSource == .youtube && !isShort(tour)
        }
    }

    private func isShort(_ tour: Tour) -> Bool {
        guard let url = tour.sourceURL else { return false }
        return LinkSource.isYouTubeShort(url)
    }

    private func isReel(_ tour: Tour) -> Bool {
        guard let url = tour.sourceURL else { return false }
        return LinkSource.isInstagramReel(url)
    }
}

// MARK: - Price

/// 🔴 **Price comes from the database, never from `Tours.json`.**
/// `seed_from_toursjson.py` omits `price_tier` deliberately — price is
/// maker-set and lives in the DB, so a content re-seed cannot reset it — which
/// means the bundled file reads `priceTier: nil` for every tour **and always
/// will**, however many paid tours exist. This design nearly shipped without a
/// Price chip on exactly that false reading.
enum PriceOption: String, CaseIterable, Identifiable {
    case free, paid

    var id: String { rawValue }

    /// ⚠️ `Free` here means the *tour* costs nothing. `Tag`'s experience facet
    /// carries **Free to Visit**, which means the *place* is free to enter. If
    /// the two ever read ambiguously side by side, this becomes "Free to
    /// listen".
    var label: String {
        switch self {
        case .free: return "Free"
        case .paid: return "Paid"
        }
    }

    func matches(_ tour: Tour) -> Bool {
        switch self {
        case .free: return !tour.isPaid
        case .paid: return tour.isPaid
        }
    }
}
