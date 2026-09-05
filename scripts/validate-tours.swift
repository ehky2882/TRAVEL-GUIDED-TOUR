#!/usr/bin/env swift
//
// validate-tours.swift
//
// Validates Tours.json against the Atlas data model. Run before
// committing edits to TRAVEL GUIDED TOUR/Resources/Tours.json so the
// app doesn't crash at launch on a typo or a missing field.
//
// Usage:
//   swift scripts/validate-tours.swift                            # default file
//   swift scripts/validate-tours.swift path/to/Tours.json         # custom file
//
// Exit codes: 0 = OK, 1 = validation errors, 2 = file/decode error
//
// The model types below mirror TRAVEL GUIDED TOUR/Models/. Keep in
// sync — if you add or rename a field on Tour / Stop / Maker /
// TourCategory, update this file too.
//

import Foundation

// MARK: - Model mirror
//
// ⚠️ THESE ENUMS STAY STRICT EVEN THOUGH THE APP'S NOW TOLERATE UNKNOWN VALUES.
// `StopTriggerMode`, `TourVideoRole` and `TourCategory` in `Models/` decode an
// unfamiliar value to a safe default, so that a catalog published in the future
// cannot break a build shipped today. That is a RUNTIME property, for data this
// build was never going to understand.
//
// This is the authoring gate, and it runs against data someone is writing right
// now. A typo here must fail loudly rather than land on a silent default and
// ship a tour onto the wrong shelf. Do not "sync" these with the app's
// tolerance — the two are meant to disagree.

enum TourKind: String, Codable {
    case single
    case multiStop
    case link
}

enum StopTriggerMode: String, Codable {
    case geofenced
    case manual
}

enum TourCategory: String, Codable, CaseIterable {
    case history, architecture, visualArt, musicAndPerformance, literature
    case foodAndDrink, natureAndParks, hiddenGems, culturalHeritage, sacredSites
}

struct Maker: Codable {
    let id: UUID
    let displayName: String
    let avatarURL: String?
    let avatarEmoji: String?
    let bio: String
    let websiteURL: String?
}

struct Stop: Codable {
    let id: UUID
    let order: Int
    let title: String
    let caption: String?
    let latitude: Double
    let longitude: Double
    let audioURL: String
    let audioDurationSeconds: Int
    let triggerMode: StopTriggerMode
    let triggerRadiusMeters: Int
    let imageURL: String?
    let transcriptText: String?
}

struct Tour: Codable {
    let id: UUID
    let title: String
    let shortDescription: String
    let longDescription: String
    let makerId: UUID
    let heroImageURL: String
    let additionalImageURLs: [String]?
    let videoURLs: [String]?
    let videoRole: String?
    let kind: TourKind
    let sourceURL: String?
    let sourceAuthor: String?
    let stops: [Stop]
    let introAudioURL: String?
    let totalDurationSeconds: Int
    let walkingDistanceMeters: Int?
    let centroidLatitude: Double
    let centroidLongitude: Double
    let city: String?
    /// Mirrors `Tour.country`. Optional so a tour authored before the key
    /// existed still validates.
    let country: String?
    let primaryCategory: TourCategory
    let tags: [String]
    let priceUSD: Decimal
    /// ISO "YYYY-MM-DD" catalog-added date (git-derived). Optional so
    /// tours added without it still validate; mirrors `Tour.createdAt`.
    let createdAt: String?
}

struct Place: Codable {
    let id: UUID
    let name: String
    let description: String?
    let latitude: Double
    let longitude: Double
    let city: String?
    let address: String?
    let heroImageURL: String?
    let additionalImageURLs: [String]?
    let tourIds: [UUID]
}

struct ToursFile: Codable {
    let makers: [Maker]
    let tours: [Tour]
    /// Optional — catalogs published before the place layer have no such key.
    let places: [Place]?
    /// Link pins, in their own top-level array so that a build predating
    /// `TourKind.link` skips them as an unknown key instead of throwing on an
    /// unknown `kind` and losing the entire catalog. Optional for the same
    /// reason `places` is: a catalog published before the split has no such
    /// key. See `TRAVEL GUIDED TOUR/Data/ToursData.swift` for the full
    /// reasoning; this file only enforces it.
    let linkPins: [Tour]?
}

extension ToursFile {
    /// Every tour, labelled by where it actually sits in the file, so an error
    /// message points at the array the reader has to go and edit.
    ///
    /// Every rule below runs over this rather than over `tours`, so a link pin
    /// is validated exactly as strictly as it was when link pins lived inside
    /// `tours` — moving them must not quietly exempt them from anything.
    var locatedTours: [(location: String, tour: Tour)] {
        // Labels are written into each literal rather than relying on the
        // declared return type to add them: an array of unlabelled tuples does
        // not implicitly convert to an array of labelled ones.
        tours.enumerated().map { (location: "tours[\($0.offset)]", tour: $0.element) }
            + (linkPins ?? []).enumerated().map { (location: "linkPins[\($0.offset)]", tour: $0.element) }
    }

    var allTours: [Tour] { tours + (linkPins ?? []) }
}

// MARK: - Finding accumulator

enum Severity: String {
    case error = "ERROR"
    case warn  = "WARN "
}

struct Finding {
    let severity: Severity
    let location: String
    let message: String
}

var findings: [Finding] = []
func err(_ loc: String, _ msg: String)  { findings.append(.init(severity: .error, location: loc, message: msg)) }
func warn(_ loc: String, _ msg: String) { findings.append(.init(severity: .warn,  location: loc, message: msg)) }

// MARK: - Helpers

func isNonEmpty(_ s: String) -> Bool {
    !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
}

func isValidURL(_ s: String) -> Bool {
    guard let u = URL(string: s) else { return false }
    return u.scheme != nil && u.host != nil
}

// Word set + Jaccard similarity, used to catch near-duplicate transcripts
// between two stops in the same tour (the signature of the Amsterdam
// transcript scramble, where each stop's clean script was interleaved with
// a phonetic TTS twin). Legit distinct stops top out around 0.29 across the
// whole catalog; a duplicated/phonetic twin scores ~0.85+, so 0.6 is a safe
// error threshold.
func wordSet(_ s: String) -> Set<String> {
    Set(s.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init))
}
func jaccard(_ a: String, _ b: String) -> Double {
    let A = wordSet(a), B = wordSet(b)
    if A.isEmpty || B.isEmpty { return 0 }
    return Double(A.intersection(B).count) / Double(A.union(B).count)
}
let transcriptDupThreshold = 0.6

// MARK: - Controlled tag vocabulary (taxonomy v2)
//
// Mirrors TRAVEL GUIDED TOUR/Models/Tag.swift + scripts/seed_tags.py's
// VOCAB. Keep all three in sync. Unknown tags are a hard error; a
// missing required facet (≥1 Place type, ≥1 Theme) is a warning while
// the catalog is backfilled — some tours still lack one.

let placeTypeTags: Set<String> = [
    "Religious Building", "Museum", "Park", "Public Square", "Tower",
    "Bridge", "Monument", "Market", "Venue", "Library", "District",
    "Civic", "Waterfront", "Notable Building",
]
let themeTags: Set<String> = [
    "Architecture", "History", "Art", "Literature", "Performance", "Food",
    "Faith", "Power", "Commerce", "Immigration", "Crime", "Remembrance",
    "Engineering", "War", "Maritime", "Fashion", "LGBTQ+",
]
let styleEraTags: Set<String> = [
    "Gothic", "Baroque", "Neoclassical", "Beaux-Arts", "Victorian",
    "Art Deco", "Modernist", "Brutalist", "Contemporary", "Gilded Age",
    "Colonial",
]
let experienceTags: Set<String> = [
    "Iconic Landmark", "Hidden Gem", "Viewpoint", "Green Escape",
    "Free to Visit", "After Dark", "Public Art", "Designed by a Master",
]
let architectTags: Set<String> = [
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
]
let validTags: Set<String> = placeTypeTags
    .union(themeTags).union(styleEraTags)
    .union(experienceTags).union(architectTags)

// MARK: - Load & decode

let defaultPath = "TRAVEL GUIDED TOUR/Resources/Tours.json"
let path = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : defaultPath

guard let data = FileManager.default.contents(atPath: path) else {
    FileHandle.standardError.write(Data("ERROR: cannot read '\(path)'. Run from repo root, or pass a path: swift scripts/validate-tours.swift path/to/Tours.json\n".utf8))
    exit(2)
}

let file: ToursFile
do {
    file = try JSONDecoder().decode(ToursFile.self, from: data)
} catch let DecodingError.keyNotFound(key, ctx) {
    let p = ctx.codingPath.map { $0.stringValue }.joined(separator: " > ")
    print("DECODE ERROR: missing key '\(key.stringValue)' at [\(p)]")
    exit(2)
} catch let DecodingError.typeMismatch(_, ctx) {
    let p = ctx.codingPath.map { $0.stringValue }.joined(separator: " > ")
    print("DECODE ERROR: type mismatch at [\(p)] — \(ctx.debugDescription)")
    exit(2)
} catch let DecodingError.valueNotFound(_, ctx) {
    let p = ctx.codingPath.map { $0.stringValue }.joined(separator: " > ")
    print("DECODE ERROR: missing value at [\(p)] — \(ctx.debugDescription)")
    exit(2)
} catch let DecodingError.dataCorrupted(ctx) {
    let p = ctx.codingPath.map { $0.stringValue }.joined(separator: " > ")
    print("DECODE ERROR: corrupted data at [\(p)] — \(ctx.debugDescription)")
    exit(2)
} catch {
    print("DECODE ERROR: \(error)")
    exit(2)
}

// MARK: - Validation rules

// Makers: ID uniqueness, required text, optional-URL validity.
var seenMakerIds = Set<UUID>()
for (i, m) in file.makers.enumerated() {
    let loc = "makers[\(i)] '\(m.displayName)'"
    if !seenMakerIds.insert(m.id).inserted {
        err(loc, "duplicate maker id \(m.id)")
    }
    if !isNonEmpty(m.displayName) { err(loc, "displayName is empty") }
    if !isNonEmpty(m.bio)         { err(loc, "bio is empty") }
    if let u = m.avatarURL, !isValidURL(u)  { err(loc, "avatarURL '\(u)' is not a valid URL") }
    if let u = m.websiteURL, !isValidURL(u) { err(loc, "websiteURL '\(u)' is not a valid URL") }
}

let makerById = Dictionary(uniqueKeysWithValues: file.makers.map { ($0.id, $0) })

// Tours + stops: foreign keys, uniqueness (stops globally), kind ↔ count,
// order packing, coord ranges, audio math, sanity bounds on radius.
var seenTourIds = Set<UUID>()
var seenStopIds = Set<UUID>()

// 🔴 The split is only worth anything if it holds. A link pin left in `tours`
// is the original bug — one unknown `kind` fails the whole catalog decode on
// every build shipped before `TourKind.link`, silently. And a non-link tour
// filed under `linkPins` would be invisible to those builds for no reason.
for (i, t) in file.tours.enumerated() where t.kind == .link {
    err("tours[\(i)] '\(t.title)'",
        "a 'link' tour is in `tours` — link pins belong in the top-level `linkPins` array, " +
        "or every build predating TourKind.link stops decoding the catalog at all")
}
for (i, t) in (file.linkPins ?? []).enumerated() where t.kind != .link {
    err("linkPins[\(i)] '\(t.title)'",
        "kind '\(t.kind.rawValue)' is in `linkPins` — only 'link' belongs there; " +
        "an ordinary tour filed here is hidden from every build that skips the key")
}

for (tloc0, t) in file.locatedTours {
    let tloc = "\(tloc0) '\(t.title)'"

    if !seenTourIds.insert(t.id).inserted {
        err(tloc, "duplicate tour id \(t.id)")
    }

    if makerById[t.makerId] == nil {
        err(tloc, "makerId \(t.makerId) does not reference any maker")
    }

    if !isNonEmpty(t.title)            { err(tloc, "title is empty") }
    if !isNonEmpty(t.shortDescription) { err(tloc, "shortDescription is empty") }
    if !isNonEmpty(t.longDescription)  { err(tloc, "longDescription is empty") }
    if !isValidURL(t.heroImageURL)     { err(tloc, "heroImageURL '\(t.heroImageURL)' is not a valid URL") }
    if let extras = t.additionalImageURLs {
        for (i, u) in extras.enumerated() {
            if !isValidURL(u) {
                err(tloc, "additionalImageURLs[\(i)] '\(u)' is not a valid URL")
            }
        }
        // Gallery integrity: the carousel renders hero → additionalImageURLs,
        // so the hero must not reappear in the list and the list must not
        // repeat itself (the Amsterdam gallery bug showed the same image 2–3×).
        if Set(extras).count != extras.count {
            err(tloc, "additionalImageURLs contains duplicate URLs — the gallery would show the same image twice")
        }
        if extras.contains(t.heroImageURL) {
            err(tloc, "heroImageURL also appears in additionalImageURLs — the gallery repeats the hero (list one distinct image per stop; the hero renders first on its own)")
        }
    }
    if let videos = t.videoURLs {
        let videoExts = [".mp4", ".mov", ".m4v"]
        for (i, u) in videos.enumerated() {
            if !isValidURL(u) {
                err(tloc, "videoURLs[\(i)] '\(u)' is not a valid URL")
            } else if !videoExts.contains(where: { u.lowercased().hasSuffix($0) }) {
                warn(tloc, "videoURLs[\(i)] '\(u)' doesn't end in a known video extension (.mp4/.mov/.m4v) — sanity check?")
            }
        }
    }
    // videoRole — closed vocabulary, mirroring `TourVideoRole` in
    // Models/Tour.swift. Absent means `gallery`, which is every video authored
    // before the role existed.
    if let role = t.videoRole {
        let known = ["gallery", "narration"]
        if !known.contains(role) {
            err(tloc, "videoRole '\(role)' is not one of \(known.joined(separator: ", "))")
        }
        if (t.videoURLs ?? []).isEmpty {
            err(tloc, "videoRole '\(role)' is set but the tour has no videoURLs")
        }
        // A narration clip IS the tour, so a tour with several of them has no
        // single soundtrack to be slaved to.
        if role == "narration", (t.videoURLs ?? []).count > 1 {
            err(tloc, "videoRole 'narration' with \((t.videoURLs ?? []).count) videos — a narration clip is the tour, so there can only be one")
        }
    }
    if let u = t.introAudioURL, !isValidURL(u) { err(tloc, "introAudioURL '\(u)' is not a valid URL") }

    // Tags: closed vocabulary (hard error on anything unknown) + the
    // required-facet coverage (warnings while the catalog is backfilled).
    for tag in t.tags where !validTags.contains(tag) {
        err(tloc, "tag '\(tag)' is not in the controlled vocabulary (see Models/Tag.swift)")
    }
    let tagSet = Set(t.tags)
    if tagSet.isDisjoint(with: placeTypeTags) {
        warn(tloc, "no Place type tag — every tour should carry ≥1 (Museum, Park, Tower, …)")
    }
    if tagSet.isDisjoint(with: themeTags) {
        warn(tloc, "no Theme tag — every tour should carry ≥1 (History, Architecture, Art, …)")
    }

    if !(-90.0...90.0).contains(t.centroidLatitude) {
        err(tloc, "centroidLatitude \(t.centroidLatitude) out of [-90, 90]")
    }
    if !(-180.0...180.0).contains(t.centroidLongitude) {
        err(tloc, "centroidLongitude \(t.centroidLongitude) out of [-180, 180]")
    }

    // kind ↔ stop count and walking distance.
    switch t.kind {
    case .single:
        if t.stops.count != 1 {
            err(tloc, "kind 'single' requires exactly 1 stop, found \(t.stops.count)")
        }
        if t.walkingDistanceMeters != nil {
            warn(tloc, "kind 'single' should have walkingDistanceMeters: null")
        }
    case .multiStop:
        if t.stops.count < 2 {
            err(tloc, "kind 'multiStop' requires at least 2 stops, found \(t.stops.count)")
        }
        if t.walkingDistanceMeters == nil {
            warn(tloc, "kind 'multiStop' should specify walkingDistanceMeters")
        } else if let d = t.walkingDistanceMeters, d <= 0 {
            err(tloc, "walkingDistanceMeters \(d) must be positive")
        }
    case .link:
        // A link pin stands for someone else's post. It carries one
        // placeholder stop so `MapMarkers` has something at order 0 to draw,
        // and that stop must be `manual` — a geofenced one would ask
        // `ProximityMonitor` to fire audio that does not exist.
        if t.stops.count != 1 {
            err(tloc, "kind 'link' requires exactly 1 stop, found \(t.stops.count)")
        }
        if let first = t.stops.first, first.triggerMode != .manual {
            err(tloc, "kind 'link' requires its stop to be triggerMode 'manual', got '\(first.triggerMode.rawValue)'")
        }
        if !isValidURL(t.sourceURL ?? "") {
            err(tloc, "kind 'link' requires a valid sourceURL, got '\(t.sourceURL ?? "nil")'")
        }
        if !isNonEmpty(t.sourceAuthor ?? "") {
            // The pin is built out of someone's work; shipping it uncredited
            // is an editorial fault, not a technical one.
            err(tloc, "kind 'link' requires sourceAuthor — a link pin must credit its creator")
        }
        if t.totalDurationSeconds != 0 {
            err(tloc, "kind 'link' must have totalDurationSeconds 0, got \(t.totalDurationSeconds)")
        }
    }

    // Only a link pin may name a source; anything else is a mis-set key.
    if t.kind != .link {
        if t.sourceURL != nil { err(tloc, "sourceURL is set on a '\(t.kind.rawValue)' tour — only 'link' may carry one") }
        if t.sourceAuthor != nil { err(tloc, "sourceAuthor is set on a '\(t.kind.rawValue)' tour — only 'link' may carry one") }
    }

    // Stop order must pack 0..<count, no gaps, no dupes within a tour.
    let orders = t.stops.map { $0.order }.sorted()
    let expected = Array(0..<t.stops.count)
    if orders != expected {
        err(tloc, "stop 'order' values must be 0..<\(t.stops.count), got \(orders)")
    }

    // Per-stop checks; accumulate audio total for sanity vs totalDurationSeconds.
    var stopAudioSum = 0
    for (si, s) in t.stops.enumerated() {
        let sloc = "\(tloc).stops[\(si)] '\(s.title)'"

        if !seenStopIds.insert(s.id).inserted {
            err(sloc, "duplicate stop id \(s.id) (stop ids must be globally unique)")
        }

        if !isNonEmpty(s.title) { err(sloc, "title is empty") }

        if !(-90.0...90.0).contains(s.latitude) {
            err(sloc, "latitude \(s.latitude) out of [-90, 90]")
        }
        if !(-180.0...180.0).contains(s.longitude) {
            err(sloc, "longitude \(s.longitude) out of [-180, 180]")
        }

        // 🔴 A link pin's stop carries an EMPTY audioURL and a zero duration
        // — the same "no audio" representation a fresh maker draft writes,
        // and safe because every reader goes through `URL(string:)`, which
        // rejects "". Legal for `kind: link` and nowhere else: relaxing this
        // for other kinds would let a real tour ship silently unplayable.
        if t.kind == .link {
            if !s.audioURL.isEmpty {
                err(sloc, "a link pin's stop must have an empty audioURL, got '\(s.audioURL)'")
            }
        } else if !isValidURL(s.audioURL) {
            err(sloc, "audioURL '\(s.audioURL)' is not a valid URL")
        }
        if let u = s.imageURL, !isValidURL(u) {
            err(sloc, "imageURL '\(u)' is not a valid URL")
        }

        if t.kind == .link {
            if s.audioDurationSeconds != 0 {
                err(sloc, "a link pin's stop must have audioDurationSeconds 0, got \(s.audioDurationSeconds)")
            }
        } else if s.audioDurationSeconds <= 0 {
            err(sloc, "audioDurationSeconds must be positive, got \(s.audioDurationSeconds)")
        }
        stopAudioSum += max(0, s.audioDurationSeconds)

        if s.triggerRadiusMeters <= 0 {
            err(sloc, "triggerRadiusMeters must be positive, got \(s.triggerRadiusMeters)")
        } else if s.triggerRadiusMeters < 5 || s.triggerRadiusMeters > 500 {
            warn(sloc, "triggerRadiusMeters \(s.triggerRadiusMeters) is outside the typical 5–500m range — sanity check?")
        }

        // Transcript integrity. transcriptText should be clean, user-facing
        // prose — never a production artifact. This catches the Amsterdam
        // incident, where "SEGMENT NN" script headers leaked into the field,
        // and flags stops that shipped with no transcript at all.
        if let tx = s.transcriptText, isNonEmpty(tx) {
            if tx.range(of: "SEGMENT[ ]+[0-9]", options: .regularExpression) != nil {
                err(sloc, "transcriptText contains a 'SEGMENT NN' production header — strip it")
            }
            if tx.range(of: "\\[[A-Za-z]", options: .regularExpression) != nil {
                err(sloc, "transcriptText contains a bracketed stage direction (e.g. '[beat]') — strip production markers")
            }
        } else if t.kind != .link {
            // A link pin has no audio, so "has audio but no transcript" would
            // be a false warning on every one of them.
            warn(sloc, "stop has audio but no transcriptText (accessibility gap — backfill when possible)")
        }
    }

    // Near-duplicate transcripts between two stops in the same tour: the
    // signature of a scrambled/duplicated transcript (e.g. a clean script
    // and its phonetic TTS twin landing on different stops).
    for i in 0..<t.stops.count {
        for j in (i + 1)..<t.stops.count {
            guard let a = t.stops[i].transcriptText, isNonEmpty(a),
                  let b = t.stops[j].transcriptText, isNonEmpty(b) else { continue }
            let r = jaccard(a, b)
            if r >= transcriptDupThreshold {
                let msg = String(format: "%.2f", r)
                err(tloc, "stops order \(t.stops[i].order) and \(t.stops[j].order) have near-identical transcripts (Jaccard \(msg)) — likely a scrambled or duplicated transcript")
            }
        }
    }

    // Duration math: total must cover the sum of stop durations.
    if t.kind == .link {
        // Already checked above: a link pin is 0/0 by definition, and the
        // sum-vs-total comparisons below are meaningless without audio.
    } else if t.totalDurationSeconds <= 0 {
        err(tloc, "totalDurationSeconds must be positive, got \(t.totalDurationSeconds)")
    } else if t.totalDurationSeconds < stopAudioSum {
        err(tloc, "totalDurationSeconds \(t.totalDurationSeconds) < sum of stop durations \(stopAudioSum)")
    } else if t.introAudioURL == nil && t.totalDurationSeconds != stopAudioSum {
        warn(tloc, "totalDurationSeconds \(t.totalDurationSeconds) ≠ sum of stop durations \(stopAudioSum) (no intro audio — were they meant to match?)")
    }

    // Centroid sanity: within bounding box of stops, with ~1km slop.
    if !t.stops.isEmpty {
        let lats = t.stops.map { $0.latitude }
        let lons = t.stops.map { $0.longitude }
        let slop = 0.01
        if let minLat = lats.min(), let maxLat = lats.max(),
           let minLon = lons.min(), let maxLon = lons.max() {
            if t.centroidLatitude < minLat - slop || t.centroidLatitude > maxLat + slop {
                warn(tloc, "centroidLatitude \(t.centroidLatitude) is outside stop range [\(minLat), \(maxLat)]")
            }
            if t.centroidLongitude < minLon - slop || t.centroidLongitude > maxLon + slop {
                warn(tloc, "centroidLongitude \(t.centroidLongitude) is outside stop range [\(minLon), \(maxLon)]")
            }
        }
    }
}

// MARK: - Places

// A place is a physical site that more than one tour describes. Identity is
// EXACT coordinate equality (owner decision 2026-08-18) — a looser proximity
// rule was measured and rejected because it merged genuinely different sites.
// These checks exist because nothing else can see a broken place: every URL
// still resolves and every tour still decodes.
if let places = file.places {
    var seenPlaceIds = Set<UUID>()
    var tourToPlace: [UUID: String] = [:]
    // `allTours`, not `tours`: a place legitimately names a link pin among
    // its members (AMNH does), and looking those up in `tours` alone would
    // report a real reference as an unknown tour.
    let tourById = Dictionary(file.allTours.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })

    for (i, place) in places.enumerated() {
        let loc = "places[\(i)] '\(place.name)'"

        if !isNonEmpty(place.name) { err(loc, "place has an empty name") }
        if !seenPlaceIds.insert(place.id).inserted { err(loc, "duplicate place id \(place.id)") }

        if !(-90...90).contains(place.latitude) || !(-180...180).contains(place.longitude) {
            err(loc, "coordinate out of range (\(place.latitude), \(place.longitude))")
        }

        // A place with one tour is not a place — it is just a tour, and it
        // would render a count badge reading "1".
        if place.tourIds.count < 2 {
            err(loc, "a place needs at least 2 tours, found \(place.tourIds.count)")
        }

        if let hero = place.heroImageURL, !isValidURL(hero) {
            err(loc, "heroImageURL '\(hero)' is not a valid URL")
        }

        for (j, url) in (place.additionalImageURLs ?? []).enumerated() {
            if !isValidURL(url) { err(loc, "additionalImageURLs[\(j)] is not a valid URL: \(url)") }
            if url == place.heroImageURL {
                err(loc, "additionalImageURLs[\(j)] repeats the hero — it would show twice in the carousel")
            }
        }

        for tourId in place.tourIds {
            guard let tour = tourById[tourId] else {
                err(loc, "tourIds references a tour not in the catalog: \(tourId)")
                continue
            }
            if let other = tourToPlace[tourId] {
                err(loc, "tour '\(tour.title)' already belongs to place '\(other)'")
            } else {
                tourToPlace[tourId] = place.name
            }

            // The identity rule, enforced: every member must actually sit on
            // the place's coordinate. The marker a map draws for a tour is its
            // single stop, or stop 0 of a walk.
            guard let marker = tour.stops.first(where: {
                tour.kind == .single || $0.order == 0
            }) else {
                err(loc, "tour '\(tour.title)' has no stop that would draw a map pin")
                continue
            }
            let dLat = abs(marker.latitude - place.latitude)
            let dLon = abs(marker.longitude - place.longitude)
            if dLat > 0.0000001 || dLon > 0.0000001 {
                err(loc, "tour '\(tour.title)' is not at this place's exact coordinate " +
                         "(\(marker.latitude), \(marker.longitude) vs \(place.latitude), \(place.longitude))")
            }
        }
    }
}

// MARK: - Report

let errorCount   = findings.filter { $0.severity == .error }.count
let warningCount = findings.filter { $0.severity == .warn  }.count
let stopCount    = file.allTours.reduce(0) { $0 + $1.stops.count }

print("Atlas Tours.json validator")
print("  file:    \(path)")
print("  makers:  \(file.makers.count)")
print("  tours:   \(file.tours.count) (\(stopCount) stops total)")
print("  linkPins: \(file.linkPins?.count ?? 0)")
print("  places:  \(file.places?.count ?? 0)")
print("")

if findings.isEmpty {
    print("OK — no issues found")
    exit(0)
}

for f in findings {
    print("\(f.severity.rawValue)  \(f.location): \(f.message)")
}
print("")
print("\(errorCount) error(s), \(warningCount) warning(s)")
exit(errorCount > 0 ? 1 : 0)
