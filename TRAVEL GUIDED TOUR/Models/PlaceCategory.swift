import Foundation

enum PlaceCategory: String, Codable, CaseIterable, Identifiable {
    case gallery
    case museum
    case architecture
    case designShop
    case studio
    case streetArt
    case publicSpace
    case culturalInstitution
    case cafe
    case bookshop
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gallery: return "Gallery"
        case .museum: return "Museum"
        case .architecture: return "Architecture"
        case .designShop: return "Design Shop"
        case .studio: return "Studio"
        case .streetArt: return "Street Art"
        case .publicSpace: return "Public Space"
        case .culturalInstitution: return "Cultural Institution"
        case .cafe: return "Cafe"
        case .bookshop: return "Bookshop"
        case .other: return "Other"
        }
    }

    var iconName: String {
        switch self {
        case .gallery: return "paintpalette"
        case .museum: return "building.columns"
        case .architecture: return "building.2"
        case .designShop: return "bag"
        case .studio: return "hammer"
        case .streetArt: return "paintbrush.pointed"
        case .publicSpace: return "leaf"
        case .culturalInstitution: return "theatermasks"
        case .cafe: return "cup.and.saucer"
        case .bookshop: return "book"
        case .other: return "mappin"
        }
    }
}

enum PriceIndicator: String, Codable {
    case free
    case low
    case medium
    case high

    var displayText: String {
        switch self {
        case .free: return "Free"
        case .low: return "$"
        case .medium: return "$$"
        case .high: return "$$$"
        }
    }
}
