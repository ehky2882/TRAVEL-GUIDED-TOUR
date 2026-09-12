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
///   2. **The Tags panel** (`panelGroups`, `searchedFacet`) — the facets as
///      groups inside one panel behind the row's `Tags` chip.
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
            "Richard Morris Hunt", "John Russell Pope", "E. J. Lennox", "Eero Saarinen",
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
            "Carlo Scarpa",
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
            "Johan Nyrén", "John H. Duncan", "John Portman", "Jorge Colaço",
            "Joseph H. Freedlander", "Josiah Conder", "Jože Plečnik", "João Carlos Machado",
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
            "Ramon Reventós", "Raymond Moriyama", "Richard Meier",
            "Richard Rogers",
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
            "John M. Johansen", "Nils M. Schweizer",
            // Link pins — verified from the post's own subject
            "John Augustus Roebling", "José Ignacio Linazasoro", "KieranTimberlake",
            "Moshe Safdie", "William Henry Barlow",
            "Alvar Aalto", "Aino Aalto", "Elissa Aalto",
            "Aldo van Eyck", "Akihisa Hirata", "Allmann Sattler Wappner",
            "ArchSD", "Arthur Erickson", "Berger + Parkkinen",
            "CannonDesign", "Chi-kuan Chen", "Cornelia Oberlander",
            "DIALOG", "Frei Otto", "Fritz Schaller",
            "Geoffrey Massey", "Gerrit Rietveld", "Gottfried Böhm",
            "Günther Behnisch", "Hariri Pontarini", "HDR",
            "Head Arhitektid", "Hiroshi Nakamura", "Iredale Architecture",
            "James Stirling", "Kiyoaki Takeda", "Lahznimmo Architects",
            "MAD Architects", "McFarland Marceau Architects", "Mecanoo",
            "Meiklejohn Architects", "Mount Fuji Architects Studio", "MVRDV",
            "Neri&Hu", "Neutelings Riedijk", "MX_SI",
            "OPEN Architecture", "Pan Tianyi", "Patkau Architects",
            "Peter Böhm", "Piet Blom", "Public Architecture",
            "RLA Architects", "Schneider + Schumacher", "Shozo Uchii",
            "Truus Schröder-Schräder", "UNStudio", "Willem Dudok",
            "Aditya Prakash", "Arne Jacobsen", "Atelier Oslo",
            "Austin Maynard Architects", "B. P. Mathur", "Billie Tsien",
            "Coldefy & Associés", "Craig Ellwood", "Department of Architecture Co",
            "Gaetano Pesce", "George Wyman", "Gordon Bunshaft",
            "Greene & Greene", "Hendrik Petrus Berlage", "Hiroaki Misawa",
            "Hodgetts + Fung", "John Dinkeloo", "John Ronan",
            "Jorge Yulo", "Junya Ishigami", "Kevin Roche",
            "Kubala Washatko", "Leandro Locsin", "Lund Hagem",
            "Paul Rudolph", "Pierre Jeanneret", "Reima Pietilä",
            "Ruben Payumo", "Rudolph Schindler", "Sachio Otani",
            "Satish Gujral", "Scott Johnson", "Slow Architects",
            "Sumner Hunt", "Tod Williams", "Vicens + Ramos",
            "BVN Architecture", "EMTB", "Hirvonen-Huttunen",
            "Kim Swoo-geun", "MGT Architects", "Shin Takamatsu",
            "Timo Suomalainen", "Tuomo Suomalainen",
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

    // MARK: - The Tags panel (owner decisions D8, then 2026-09-12)

    /// One group inside the **Tags** panel. The five tag facets are no longer
    /// five chips in the row — they are five groups in one panel — but they are
    /// still separate facets, and that is the whole point: `Place` AND `Subject`
    /// asks "a market, about empire", which one flat list could never ask.
    ///
    /// The titles are the **question each group answers**, not the facet's
    /// internal name: nobody should have to remember what "Theme" meant.
    struct PanelGroup: Identifiable, Equatable {
        let title: String
        let facet: TagFacet
        /// Shown as chips, alphabetically. Everything else in the facet is
        /// behind `More`.
        let promoted: [String]

        var id: String { title }
        /// How many of the facet's values are NOT promoted.
        var moreCount: Int { Tag.tags(in: facet).count - promoted.count }
    }

    /// 🔴 **Two rules govern this list, and they are different rules.**
    ///
    /// **Counts decide WHICH values are promoted.** The four in each group are
    /// the ones most of the catalogue carries, so `More` holds the tail rather
    /// than the things people came for.
    ///
    /// **The alphabet decides the ORDER they appear in.** An earlier pass
    /// displayed each group by count, biggest first. Rejected for two reasons
    /// that generalise to any list in this app: the order was **invisible**
    /// (nothing on screen says "these are in size order", so it reads as
    /// arbitrary) and **unstable** (every content merge reshuffles it, so nobody
    /// can learn where anything is).
    ///
    /// ⚠️ **Why only three or four per group.** The panel has to fit one screen,
    /// and at seven promoted place types the content ran to 829 pt — 96 pt
    /// short even with the panel at the very top of the screen. Sliding it up
    /// could not fix that, so the promoted set is the lever. Trimming further
    /// is the right response if the panel ever grows again; tightening
    /// `AtlasSpacing.panelRowGap` is not, because that is the tap target.
    ///
    /// ⚠️ Four values are deliberately absent from the promoted sets for
    /// duplicating a neighbouring group or matching a third of everything:
    /// `Faith` (88% of it is also `Religious Building`), `Architecture` (82% of
    /// `Designed by a Master` carries it, and it matches 37% of the catalogue),
    /// `History` (42% of the catalogue — it narrows almost nothing) and
    /// `Green Escape` (72% of it is also `Park`). All four are still selectable
    /// under `More`.
    static let panelGroups: [PanelGroup] = [
        PanelGroup(title: "Place — what it is", facet: .placeType,
                   promoted: ["District", "Monument", "Museum", "Park"]),
        PanelGroup(title: "Subject — what it is about", facet: .theme,
                   promoted: ["Art", "Commerce", "Engineering", "Food"]),
        PanelGroup(title: "Why go", facet: .experience,
                   promoted: ["Designed by a Master", "Free to Visit", "Hidden Gem"]),
        PanelGroup(title: "Era", facet: .styleEra,
                   promoted: ["Contemporary", "Gothic", "Modernist"]),
    ]

    /// The facet shown as a **search field** rather than a grid of chips.
    ///
    /// The rule: over ~30 values a grid becomes a list with a search field.
    /// Architect has 429 and the largest matches 23 pins, so every one of them
    /// is small by construction and a wall of chips would be the worst screen
    /// in the app. Search changes the presentation only — it stays
    /// multi-select, like every other facet.
    static let searchedFacet: TagFacet = .architect

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
