import Foundation

/// The five facets of the controlled Atlas tag vocabulary (tag taxonomy
/// v2). A tag belongs to exactly one facet. Facets drive the
/// multi-select filter logic (D6: OR *within* a facet, AND *across*
/// facets) and the derived-primary rule (D5).
enum TagFacet: String, CaseIterable {
    case placeType   = "Place type"
    case theme       = "Theme"
    case styleEra    = "Style & era"
    case experience  = "Experience"
    case architect   = "Architect"
}

/// The controlled tag vocabulary as a Swift value type — the single
/// source of truth on the app side. Mirrors `scripts/seed_tags.py`'s
/// `VOCAB` and `docs/tag-taxonomy-v2.md`; keep the three in sync.
///
/// Phase 2 uses this for three things:
///   1. **Curated browse shelves** (`curatedShelves`) — the hand-picked,
///      ordered set that replaces the old one-shelf-per-category layout.
///   2. **Multi-select filter chips** (`filterChips`) — the strong,
///      multi-city tags promoted to Home's filter row.
///   3. **Facet-aware filtering** (`matches`) — the D6 combine rule.
///
/// The `derivePrimary` helper (D5) computes one lightweight "primary"
/// tag per tour so any one-label spot can migrate off `primaryCategory`
/// later without a map-layer rewrite. `primaryCategory` stays until
/// Phase 3.
enum Tag {

    // MARK: - Vocabulary (facet → tags, in editorial order)

    /// Ordered so `derivePrimary` can walk place types specific → catch-all.
    static let vocabulary: [(facet: TagFacet, tags: [String])] = [
        (.placeType, [
            "Religious Building", "Museum", "Park", "Public Square",
            "Tower", "Bridge", "Monument", "Market", "Venue",
            "Library", "District", "Civic", "Waterfront", "Notable Building",
        ]),
        (.theme, [
            "Architecture", "History", "Art", "Literature", "Performance",
            "Food", "Faith", "Power", "Commerce", "Immigration", "Crime",
            "Remembrance", "Engineering", "War", "Maritime", "Fashion", "LGBTQ+",
        ]),
        (.styleEra, [
            "Gothic", "Baroque", "Neoclassical", "Beaux-Arts", "Victorian",
            "Art Deco", "Modernist", "Brutalist", "Contemporary",
            "Gilded Age", "Colonial",
        ]),
        (.experience, [
            "Iconic Landmark", "Hidden Gem", "Viewpoint", "Green Escape",
            "Free to Visit", "After Dark", "Public Art", "Designed by a Master",
        ]),
        (.architect, [
            "Álvaro Siza", "Eduardo Souto de Moura", "Fernando Távora",
            "Norman Foster", "Renzo Piano", "Frank Gehry", "Christopher Wren",
            "Charles Holden", "Denys Lasdun", "Inigo Jones",
            "Giles Gilbert Scott", "George Gilbert Scott", "Herzog & de Meuron",
            "Frank Lloyd Wright", "Cass Gilbert", "McKim, Mead & White",
            "Inês Lobo", "Luís Pedro Silva", "Kengo Kuma", "Kenzō Tange",
            "Tadao Ando", "SANAA", "Toyo Ito", "Fumihiko Maki", "Shigeru Ban",
            "Sou Fujimoto", "Kisho Kurokawa", "I. M. Pei", "Mies van der Rohe",
            "Le Corbusier", "Philip Johnson", "William Van Alen",
            "Thomas Heatherwick", "Santiago Calatrava", "Bernard Maybeck",
            "Daniel Burnham", "Zaha Hadid", "Jean Nouvel",
        ]),
    ]

    /// tag → facet, built once from `vocabulary`.
    static let facetByTag: [String: TagFacet] = {
        var map: [String: TagFacet] = [:]
        for (facet, tags) in vocabulary {
            for tag in tags { map[tag] = facet }
        }
        return map
    }()

    /// Every valid tag (for the validator + defensive checks).
    static let allValid: Set<String> = Set(facetByTag.keys)

    static func facet(for tag: String) -> TagFacet? { facetByTag[tag] }

    // MARK: - Curated browse shelves (owner decision D7 — editorial)

    /// One shelf = one tag drawn from the whole catalog. Ordered as
    /// they render top-to-bottom. Empty shelves auto-hide (e.g. a city
    /// with no tours of that tag). Owner reorders / adds / drops these
    /// freely — this is the editorial control D7 buys.
    ///
    /// The two too-broad tags from the plan's §3 (`Architecture` 56% and
    /// `History` 44% of the catalog) are deliberately **dropped** — a
    /// shelf that matches half of everything isn't curated (plan §3.1).
    /// Three selective replacements are folded in: Modern icons, Markets
    /// & halls, Towers & rooftops.
    struct Shelf: Identifiable, Equatable {
        let title: String
        let tag: String
        var id: String { tag }
    }

    static let curatedShelves: [Shelf] = [
        Shelf(title: "Iconic landmarks",     tag: "Iconic Landmark"),
        Shelf(title: "Hidden gems",          tag: "Hidden Gem"),
        Shelf(title: "Designed by a master", tag: "Designed by a Master"),
        Shelf(title: "Modern icons",         tag: "Contemporary"),
        Shelf(title: "Sacred spaces",        tag: "Faith"),
        Shelf(title: "Art & museums",        tag: "Art"),
        Shelf(title: "Food & drink",         tag: "Food"),
        Shelf(title: "Markets & halls",      tag: "Market"),
        Shelf(title: "Green escapes",        tag: "Green Escape"),
        Shelf(title: "Viewpoints",           tag: "Viewpoint"),
        Shelf(title: "Towers & rooftops",    tag: "Tower"),
        Shelf(title: "By the water",         tag: "Maritime"),
        Shelf(title: "Fashion & retail",     tag: "Fashion"),
    ]

    // MARK: - Filter chips (owner decision D8 — simple multi-select)

    /// The tags promoted to Home's filter chip row, in order. Curated to
    /// the **strong, multi-city** tags (plan §3.1): every one matches a
    /// useful, cross-city slice. Thin tags (LGBTQ+, Library, Brutalist,
    /// Gilded Age, Art Deco, Crime, Bridge) are deliberately kept OUT —
    /// a chip that finds 5 tours across 1 city reads as broken. They
    /// stay searchable / on the detail page, just not promoted here.
    ///
    /// The "Walks" *format* filter is not a tag — it's handled alongside
    /// these in `TagFilterChipRow` and ANDs with the tag selection.
    static let filterChips: [String] = [
        "Iconic Landmark",
        "Hidden Gem",
        "Designed by a Master",
        "Museum",
        "Art",
        "Religious Building",
        "Faith",
        "Food",
        "Market",
        "Green Escape",
        "Park",
        "Viewpoint",
        "Tower",
        "Waterfront",
        "Venue",
        "Fashion",
    ]

    // MARK: - Multi-select filter logic (owner decision D6)

    /// Whether a tour's tag set satisfies a multi-select selection under
    /// the D6 rule: **OR within a facet, AND across facets.** e.g.
    /// selecting `Museum` + `Art` (a Place type and a Theme, two facets)
    /// requires *both*; selecting `Museum` + `Market` (both Place types,
    /// one facet) requires *either*.
    ///
    /// Pure — takes tag sets so it's testable without a `Tour`. An empty
    /// selection matches everything. A selected tag with no known facet
    /// falls into a shared bucket (treated as one implicit facet).
    static func matches(tourTags: Set<String>, selection: Set<String>) -> Bool {
        guard !selection.isEmpty else { return true }

        var byFacet: [TagFacet?: [String]] = [:]
        for tag in selection {
            byFacet[facet(for: tag), default: []].append(tag)
        }

        // AND across facets: every facet group must be satisfied.
        for (_, group) in byFacet {
            // OR within a facet: at least one of the group's tags present.
            if !group.contains(where: { tourTags.contains($0) }) {
                return false
            }
        }
        return true
    }

    // MARK: - Derived primary (owner decision D5)

    /// The single "primary" tag for a tour, derived from its tag set so
    /// one-label spots (and, later, map pins) can drop `primaryCategory`
    /// without a rewrite. Deterministic: walks Place type → Theme →
    /// Experience → Style & era, each in vocabulary order, and returns
    /// the first tag the tour carries. `nil` only for a tagless tour.
    static func derivePrimary(from tags: [String]) -> String? {
        let tourTags = Set(tags)
        let priority: [TagFacet] = [.placeType, .theme, .experience, .styleEra]
        for facet in priority {
            guard let candidates = vocabulary.first(where: { $0.facet == facet })?.tags else { continue }
            if let hit = candidates.first(where: { tourTags.contains($0) }) {
                return hit
            }
        }
        return tags.first
    }
}
