//
//  CoachMark.swift
//  TRAVEL GUIDED TOUR
//
//  The five stops of the navigation tour that ends onboarding, and the
//  send-off after them.
//
//  Order is the owner's (2026-09-22): *"1. map 2. search bar 3. filters
//  4. drawer 5. tab bar"*. It runs biggest to smallest — the whole screen,
//  then the bar across the top, the row inside it, the panel over the bottom,
//  the strip at the very bottom — so the eye travels one way and never
//  doubles back.
//
//  Then `ready` (owner, 2026-10-25): *"one more that goes back to the default
//  home page and says something along the lines of 'i'm ready to explore!'
//  with excitement and then the screen fades into use."* It points at
//  nothing — it is Home itself, behind the same dim as every stop.
//

import Foundation

enum CoachMark: String, CaseIterable, Codable, Sendable {
    case map
    case search
    case filters
    case drawer
    case tabBar
    case ready

    /// The stops in the order they run.
    static let tour: [CoachMark] = [.map, .search, .filters, .drawer, .tabBar, .ready]

    /// The bubble's first line. No step count — owner, 2026-09-23: *"no need
    /// to count out the steps."*
    var title: String {
        switch self {
        case .map: "The map"
        case .search: "Search"
        case .filters: "Filters"
        case .drawer: "The list"
        case .tabBar: "The bar"
        case .ready: "That's the tour"
        }
    }

    var message: String {
        switch self {
        case .map:
            "Everything lives here. Pan it and the list underneath follows — what you can see is what you get. Swipe the list down for the whole map."
        case .search:
            "Any city on earth, or any dozent by name. Pick a place and the map flies there."
        case .filters:
            "They stack. Turn on more than one and the map narrows to what matches."
        case .drawer:
            "Three heights. Drag it up for the full list, down to get the map back."
        case .tabBar:
            "Whatever is playing stays here while you browse. Home, Library and you, underneath it."
        case .ready:
            "The rest you'll find as you go. Pick a pin, press play, and start walking. These tips are always in Settings."
        }
    }

    var expression: DozentExpression {
        switch self {
        case .map: .wow
        case .search: .smile
        case .filters: .content
        case .drawer: .rest
        case .tabBar: .beam
        case .ready: .excited
        }
    }

    /// "Next" on every stop; the send-off's button is the user saying it.
    var buttonTitle: String { self == .ready ? "I'm ready to explore!" : "Next" }

    /// Whether this stop gets a spotlight cut-out. Every stop that explains
    /// a control does; `ready` explains nothing and shows Home whole.
    ///
    /// ⚠️ The map had none until 2026-10-06 (decided 2026-09-22: "it IS the
    /// screen"). On device that read as nothing being lit at all — owner:
    /// "the actual map is not highlighted." It now lights the visible map,
    /// between the filter row and the drawer; see
    /// `CoachMarkCenter.spotlightFrame(for:)`.
    var hasSpotlight: Bool { self != .ready }
}
