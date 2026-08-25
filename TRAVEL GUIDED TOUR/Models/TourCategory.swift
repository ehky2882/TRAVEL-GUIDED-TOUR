import Foundation

enum TourCategory: String, Codable, CaseIterable, Identifiable {
    case history
    case architecture
    case visualArt
    case musicAndPerformance
    case literature
    case foodAndDrink
    case natureAndParks
    case hiddenGems
    case culturalHeritage
    case sacredSites

    /// An unfamiliar category becomes `.culturalHeritage` rather than throwing.
    ///
    /// The tour itself is fine — it has a title, a hero, narration and a
    /// coordinate, all of which this build understands perfectly. The only
    /// thing in doubt is which shelf it belongs on, and losing the tour over
    /// that would be absurd. `.culturalHeritage` is the neutral choice: it is
    /// the widest existing bucket (its icon is a globe), so it claims nothing
    /// about the tour that the tour has not said. `.hiddenGems` would.
    ///
    /// ⚠️ The cost is real but small and visible: the tour appears under the
    /// wrong heading and answers the wrong filter chip until the app is
    /// updated. Browse has been keyed on `tags` since Tag Phase 2 anyway
    /// (`Models/Tag.swift`); `primaryCategory` mostly drives an icon and a
    /// shelf title.
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = TourCategory(rawValue: raw) ?? .culturalHeritage
    }

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .history: return "History"
        case .architecture: return "Architecture"
        case .visualArt: return "Art"
        case .musicAndPerformance: return "Music & Performance"
        case .literature: return "Literature"
        case .foodAndDrink: return "Food & Drink"
        case .natureAndParks: return "Nature & Parks"
        case .hiddenGems: return "Hidden Gems"
        case .culturalHeritage: return "Cultural Heritage"
        case .sacredSites: return "Sacred Sites"
        }
    }

    var iconName: String {
        switch self {
        case .history: return "building.columns"
        case .architecture: return "building.2"
        case .visualArt: return "paintpalette"
        case .musicAndPerformance: return "music.note"
        case .literature: return "book"
        case .foodAndDrink: return "fork.knife"
        case .natureAndParks: return "leaf"
        case .hiddenGems: return "sparkles"
        case .culturalHeritage: return "globe"
        case .sacredSites: return "moon.stars"
        }
    }
}
