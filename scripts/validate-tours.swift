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

enum TourKind: String, Codable {
    case single
    case multiStop
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
    let kind: TourKind
    let stops: [Stop]
    let introAudioURL: String?
    let totalDurationSeconds: Int
    let walkingDistanceMeters: Int?
    let centroidLatitude: Double
    let centroidLongitude: Double
    let city: String?
    let primaryCategory: TourCategory
    let tags: [String]
    let priceUSD: Decimal
    /// ISO "YYYY-MM-DD" catalog-added date (git-derived). Optional so
    /// tours added without it still validate; mirrors `Tour.createdAt`.
    let createdAt: String?
}

struct ToursFile: Codable {
    let makers: [Maker]
    let tours: [Tour]
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
    "Norman Foster", "Renzo Piano", "Frank Gehry", "Christopher Wren",
    "Charles Holden", "Denys Lasdun", "Inigo Jones", "Giles Gilbert Scott",
    "George Gilbert Scott", "Herzog & de Meuron", "Frank Lloyd Wright",
    "Cass Gilbert", "McKim, Mead & White", "Inês Lobo", "Luís Pedro Silva",
    "Kengo Kuma", "Kenzō Tange", "Tadao Ando", "SANAA", "Toyo Ito",
    "Fumihiko Maki", "Shigeru Ban", "Sou Fujimoto", "Kisho Kurokawa",
    "I. M. Pei", "Mies van der Rohe", "Le Corbusier", "Philip Johnson",
    "William Van Alen", "Thomas Heatherwick", "Santiago Calatrava",
    "Bernard Maybeck", "Daniel Burnham", "Zaha Hadid", "Jean Nouvel",
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

for (ti, t) in file.tours.enumerated() {
    let tloc = "tours[\(ti)] '\(t.title)'"

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

        if !isValidURL(s.audioURL) {
            err(sloc, "audioURL '\(s.audioURL)' is not a valid URL")
        }
        if let u = s.imageURL, !isValidURL(u) {
            err(sloc, "imageURL '\(u)' is not a valid URL")
        }

        if s.audioDurationSeconds <= 0 {
            err(sloc, "audioDurationSeconds must be positive, got \(s.audioDurationSeconds)")
        }
        stopAudioSum += max(0, s.audioDurationSeconds)

        if s.triggerRadiusMeters <= 0 {
            err(sloc, "triggerRadiusMeters must be positive, got \(s.triggerRadiusMeters)")
        } else if s.triggerRadiusMeters < 5 || s.triggerRadiusMeters > 500 {
            warn(sloc, "triggerRadiusMeters \(s.triggerRadiusMeters) is outside the typical 5–500m range — sanity check?")
        }
    }

    // Duration math: total must cover the sum of stop durations.
    if t.totalDurationSeconds <= 0 {
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

// MARK: - Report

let errorCount   = findings.filter { $0.severity == .error }.count
let warningCount = findings.filter { $0.severity == .warn  }.count
let stopCount    = file.tours.reduce(0) { $0 + $1.stops.count }

print("Atlas Tours.json validator")
print("  file:    \(path)")
print("  makers:  \(file.makers.count)")
print("  tours:   \(file.tours.count) (\(stopCount) stops total)")
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
