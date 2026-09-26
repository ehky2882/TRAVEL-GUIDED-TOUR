//
//  CoachMark.swift
//  TRAVEL GUIDED TOUR
//
//  The five stops of the navigation tour that ends onboarding.
//
//  Order is the owner's (2026-09-22): *"1. map 2. search bar 3. filters
//  4. drawer 5. tab bar"*. It runs biggest to smallest — the whole screen,
//  then the bar across the top, the row inside it, the panel over the bottom,
//  the strip at the very bottom — so the eye travels one way and never
//  doubles back.
//

import Foundation

enum CoachMark: String, CaseIterable, Codable, Sendable {
    case map
    case search
    case filters
    case drawer
    case tabBar

    /// The stops in the order they run.
    static let tour: [CoachMark] = [.map, .search, .filters, .drawer, .tabBar]

    /// The bubble's first line. No step count — owner, 2026-09-23: *"no need
    /// to count out the steps."*
    var title: String {
        switch self {
        case .map: "The map"
        case .search: "Search"
        case .filters: "Filters"
        case .drawer: "The list"
        case .tabBar: "The bar"
        }
    }

    var message: String {
        switch self {
        case .map:
            "Everything lives here. Pan it and the list underneath follows — what you can see is what you get."
        case .search:
            "Any city on earth, or any dozent by name. Pick a place and the map flies there."
        case .filters:
            "They stack. Turn on more than one and the map narrows to what matches."
        case .drawer:
            "Three heights. Drag it up for the full list, down to get the map back."
        case .tabBar:
            "Whatever is playing stays here while you browse. Home, Library and you, underneath it."
        }
    }

    var expression: DozentExpression {
        switch self {
        case .map: .wow
        case .filters, .tabBar: .beam
        case .search, .drawer: .rest
        }
    }

    /// "Got it" on the last stop, "Next" everywhere else.
    var buttonTitle: String { self == Self.tour.last ? "Got it" : "Next" }

    /// Whether this stop gets a spotlight cut-out.
    ///
    /// 🔴 The map does not: it IS the screen, so there is nothing to cut a
    /// hole in. The whole screen dims a little instead and the bubble floats
    /// over the middle of it — the inverse of the other four.
    var hasSpotlight: Bool { self != .map }
}
