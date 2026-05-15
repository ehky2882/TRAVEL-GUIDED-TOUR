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
