import SwiftUI

/// Lifecycle status of a tour in the maker platform (mirrors the Supabase
/// `tour_status` enum). Public catalog tours are always `.published`; a maker's
/// own profile can also show `.draft` / `.inReview` / `.takenDown` tours.
enum TourStatus: String, Codable, CaseIterable, Hashable {
    case draft
    case inReview = "in_review"
    case published
    case takenDown = "taken_down"

    /// Short label for the badge on a maker's own tour tiles.
    var label: String {
        switch self {
        case .draft:     return "Draft"
        case .inReview:  return "In review"
        case .published: return "Published"
        case .takenDown: return "Taken down"
        }
    }

    /// Whether this status should carry a visible badge on the own-profile feed.
    /// Published tours look like any catalog tour (no badge); the rest are
    /// works-in-progress worth flagging.
    var showsBadge: Bool { self != .published }

    var badgeColor: Color {
        switch self {
        case .draft:     return AtlasColors.secondaryText
        case .inReview:  return AtlasColors.mapPin
        case .published: return AtlasColors.secondaryText
        case .takenDown: return AtlasColors.accent
        }
    }
}
