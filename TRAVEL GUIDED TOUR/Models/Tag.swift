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
            "Norman Foster", "Renzo Piano", "Frank Gehry",
            "Christopher Wren", "Charles Holden", "Denys Lasdun",
            "Inigo Jones", "Giles Gilbert Scott", "George Gilbert Scott",
            "Herzog & de Meuron", "Frank Lloyd Wright", "Cass Gilbert",
            "McKim, Mead & White", "Inês Lobo", "Luís Pedro Silva",
            "Kengo Kuma", "Kenzō Tange", "Tadao Ando",
            "SANAA", "Toyo Ito", "Fumihiko Maki",
            "Shigeru Ban", "Sou Fujimoto", "Kisho Kurokawa",
            "I. M. Pei", "Mies van der Rohe", "Le Corbusier",
            "Philip Johnson", "William Van Alen", "Thomas Heatherwick",
            "Santiago Calatrava", "Bernard Maybeck", "Daniel Burnham",
            "Zaha Hadid", "Jean Nouvel", "Oscar Niemeyer",
            "Lina Bo Bardi", "Paulo Mendes da Rocha", "Vilanova Artigas",
            "Affonso Eduardo Reidy", "Lúcio Costa", "Christian de Portzamparc",
            "Ramos de Azevedo", "Rino Levi", "Roberto Burle Marx",
            "Karl Friedrich Schinkel", "Hans Scharoun", "August Endell",
            "Hermann Henselmann", "Nicholas Hawksmoor", "John Soane",
            "Edwin Lutyens", "Horace Jones", "Herbert Baker",
            "Amanda Levete", "Frederick Law Olmsted", "Calvert Vaux",
            "Richard Morris Hunt", "John Russell Pope", "Eero Saarinen",
            "Diller Scofidio + Renfro", "Jeanne Gang", "Michael Arad",
            "Marcel Breuer", "Francesco Tamburini", "Mario Palanti",
            "Carlos Thays", "Clorindo Testa", "Víctor Meano",
            "Jørn Utzon", "Joseph Reed", "Roy Grounds",
            "Marc Newson", "Studio KO", "Mario Botta",
            "Jun Aoki", "Rocco Yim", "Bing Thom",
            "Philippe Starck", "Gustave Eiffel", "Rem Koolhaas",
            "Dominique Perrault", "Hiroshi Sambuichi", "Bjarke Ingels",
            "Antoni Gaudí", "Lluís Domènech i Montaner", "Josep Puig i Cadafalch",
            "Ricardo Bofill", "Enric Sagnier", "Josep Fontserè",
            "Antoni Bonet i Castellana", "Josep Maria Subirachs", "Agostinho Ricca",
            "Aires Mateus", "Albert Guilbert", "Alberto Kuhlmann",
            "Alberto Prebisch", "Alejandro Christophersen", "Alexander Jackson Davis",
            "Alfred Foulhoux", "Alfred Waterhouse", "Allan Powell",
            "Américo Soares Braga", "Annabelle Selldorf", "Antonio Citterio",
            "António Correia da Silva", "Aron Johansson", "Artur Andrade",
            "Arturo Ochoa", "Baek Jong-hwan", "Bertrand Goldberg",
            "Bonaventura Bassegoda", "Bond Ryder", "Brad Cloepfil",
            "Bruce Price", "Carl Fredrik Adelcrantz", "Carlo Maciachini",
            "Carlos Zapata", "Charles Collens", "Charles Garnier",
            "Charles W. Clinton", "Chu Ming Silveira", "DHK Architects",
            "Dan Kiley", "Daniel Libeskind", "David Chipperfield",
            "David McGlashan", "David Rockwell", "Der Scutt",
            "Diogo de Boitaca", "Domiziano Rossi", "Donald Deskey",
            "Edgar de Oliveira da Fonseca", "Edson Elito", "Eduardo Catalano",
            "Eduardo Le Monnier", "Edward Durell Stone", "Egon Eiermann",
            "Ellen van Loon", "Emanuel Buchsbaum", "Emili Sala Cortés",
            "Emilio Lancia", "Emílio David", "Enrique Jan",
            "Ensamble Studio", "Eugène Ferret", "Eugénio dos Santos",
            "Ferdinand Boberg", "Fermín Vázquez", "Fernand Gardès",
            "Filippo Terzi", "Francesco Gianotti", "Francisco Joaquim Béthencourt da Silva",
            "Francisco de Paula del Villar", "Franz Koepp", "François Hennebique",
            "Frederick A. Petersen", "Fredrik Blom", "Fredrik Lilljekvist",
            "Friedrich August Stüler", "Fumio Asakura", "George McRae",
            "Gio Ponti", "Giovanni Muzio", "Giuseppe Cinatti",
            "Giuseppe Mengoni", "Giuseppe Piermarini", "Gonçalo Ribeiro Telles",
            "Guiniforte Solari", "Gunilla Bandolin", "Gunnar Asplund",
            "Gustavo Adolfo Gonçalves e Sousa", "Göran Josuae Adelcrantz", "H. Douglas Ives",
            "H3O Architects", "Hector Guimard", "Hendrick de Keyser",
            "Henry C. Pelton", "Henry Janeway Hardenbergh", "Hercules Manfredi",
            "Hiroshi Naito", "Hiroyuki Wakabayashi", "Ico Migliore",
            "Ilse Crawford", "Isak Gustaf Clason", "Ithiel Town",
            "Ivar Tengbom", "J. Cleaveland Cady", "Jacques Brownson",
            "James Corner Field Operations", "James Gibbs", "James O'Donnell",
            "James Renwick Jr.", "James Wardrop", "Jean-Michel Wilmotte",
            "Jeroni Martorell", "Jin Watanabe", "Jo Nagasaka",
            "Johan Nyrén", "John H. Duncan", "Jorge Colaço",
            "Joseph H. Freedlander", "Josiah Conder", "João Carlos Machado",
            "João Queiroz", "João de Castilho", "Juan A. Buschiazzo",
            "Juan Gómez de Mora", "Juan de Villanueva", "Jules Dormal",
            "Karl Fournier", "Kasper Salin", "Kazoo Sato",
            "Kazumasa Yamashita", "Kenichi Iwasaki", "Klein Dytham Architecture",
            "Kulapat Yantrasast", "Kunio Maekawa", "Lee Jae-yeon",
            "Lek Viriyaphant", "Lluís Clotet", "Luca Beltrami",
            "Ludger Lemieux", "Luigi Cagnola", "Luigi Vanvitelli",
            "Luis Rey", "Manuel Salgado", "Mara Servetto",
            "Mario Buschiazzo", "Mario Cucinella", "Mario Tamagno",
            "Mario Vodret", "Massimiliano Locatelli", "Michael Van Valkenburgh",
            "Michele De Lucchi", "Min Hyun-jun", "Minard Lafever",
            "Nelson Dupré", "Ngô Viết Thụ", "Nicodemus Tessin the Elder",
            "Nicodemus Tessin the Younger", "Nicola Salvi", "Norman Peebles",
            "OONN Metaworks", "Ole Scheeren", "Olivier Marty",
            "Paul Sinoir", "Paulo Bruna", "Pedro Ramalho",
            "Pellegrino Tibaldi", "Peter Chermayeff", "Peter Joseph Lenné",
            "Peter Zumthor", "Pezo von Ellrichshausen", "Philip Hubert",
            "Phillip Hudson", "Pietro Pestagalli", "Próspero Catelin",
            "Rafael Moneo", "Rafael Viñoly", "Ragnar Östberg",
            "Ramon Reventós", "Richard Meier", "Richard Rogers",
            "Richard Upjohn", "Richard Waite", "Robert W. Gibson",
            "Roberto Peregalli", "Rod Faucheux", "Rodney Leon",
            "Seung H-Sang", "Sigurd Lewerentz", "Silvia Bettini",
            "Stanford White", "Stefano Boeri", "Studio Tack",
            "Tamsin Johnson", "Thierry Despont", "Thom Mayne",
            "Thomas Dillen Jones", "Théophile Seyrig", "Tokuma Katayama",
            "Tomás Soler", "Tomás Taveira", "Viktor Sulčič",
            "Vittorio Gregotti", "Von Jour Caux", "Wallace Harrison",
            "Welton Becket", "Wes Anderson", "William Pereira",
            "William Pitt", "Work Architecture Company", "Yang Tae-oh",
            "Yoji Kasajima", "Yoshio Taniguchi",
            // Copenhagen (Atlas Studio CPH)
            "3XN", "Cobe", "Edvard Eriksen",
            "Ferdinand Meldahl", "Hack Kampmann", "Henning Larsen",
            "Ivar Bentsen", "Julien De Smedt", "Jørgen Bo",
            "Kaare Klint", "Lauritz de Thurah", "Lundgaard & Tranberg",
            "Martin Brudnizki", "Michael Gottlieb Bindesbøll", "Nicolai Eigtved",
            "Olafur Eliasson", "Peder Vilhelm Jensen-Klint", "Povl Baumann",
            "Superflex", "Thorvald Jørgensen", "Topotek 1",
            "Vilhelm Dahlerup", "Vilhelm Wohlert", "White Arkitekter",
            // Orlando (link pins)
            "Adjaye Associates", "James Gamble Rogers II",
            "John M. Johansen", "Nils M. Schweizer"
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

    /// The tags in a facet, in vocabulary order. For the maker tag picker.
    static func tags(in facet: TagFacet) -> [String] {
        vocabulary.first(where: { $0.facet == facet })?.tags ?? []
    }

    /// A selection sorted into canonical vocabulary order (Place type →
    /// Theme → Style → Experience → Architect), so authored tags lead
    /// with the place type like the rest of the catalog.
    static func ordered(_ selection: Set<String>) -> [String] {
        vocabulary.flatMap { $0.tags.filter(selection.contains) }
    }

    // MARK: - Derived category (maker authoring — legacy primaryCategory bridge)

    /// Maps a tour's controlled tags onto the still-required legacy
    /// `TourCategory` (map pins + placeholders + old builds read it until
    /// Phase 3). Lets the maker form pick *tags only* and derive the
    /// category. Ordered most-specific first; falls back to
    /// `.culturalHeritage` (the historical catch-all).
    static func deriveCategory(from tags: [String]) -> TourCategory {
        let s = Set(tags)
        func any(_ options: String...) -> Bool { !s.isDisjoint(with: Set(options)) }
        if any("Faith", "Religious Building") { return .sacredSites }
        if any("Art", "Museum") { return .visualArt }
        if any("Performance", "Venue") { return .musicAndPerformance }
        if any("Literature", "Library") { return .literature }
        if any("Food", "Market") { return .foodAndDrink }
        if any("Park", "Green Escape", "Waterfront") { return .natureAndParks }
        if any("Architecture") { return .architecture }
        if any("History", "Power", "Commerce", "War", "Remembrance", "Maritime") { return .history }
        if any("Hidden Gem") { return .hiddenGems }
        return .culturalHeritage
    }

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
