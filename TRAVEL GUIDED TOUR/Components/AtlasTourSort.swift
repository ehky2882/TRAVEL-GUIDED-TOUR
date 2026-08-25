import CoreLocation
import SwiftUI

/// How a list of tours is ordered, and the pull-down that changes it.
///
/// The maker page has had this since PR #435; the place page now carries the
/// identical control (owner, 2026-08-25: *"it should just look exactly like the
/// example from profile page"*). It lives here for the reason
/// `AtlasLayoutToggle` does — a control two screens both render is a duplicate
/// that has not diverged yet.
///
/// All four criteria are reversible, and the menu names the direction in the
/// reader's words ("A–Z" / "Z–A", "Newest" / "Oldest") rather than
/// "ascending".
enum AtlasTourSort: String, CaseIterable, Identifiable {
    case name, duration, distance, dateAdded

    var id: String { rawValue }

    /// The direction a criterion takes when first selected. Date added opens
    /// newest-first; everything else takes its natural ascending form.
    var defaultAscending: Bool {
        self == .dateAdded ? false : true
    }

    func label(ascending: Bool) -> String {
        switch self {
        case .name:      return ascending ? "A–Z" : "Z–A"
        case .duration:  return ascending ? "Shortest" : "Longest"
        case .distance:  return ascending ? "Nearest" : "Farthest"
        case .dateAdded: return ascending ? "Oldest" : "Newest"
        }
    }

    /// Sorts `tours`, **stably** — two tours this criterion cannot separate
    /// keep the order they arrived in.
    ///
    /// 🔴 The stability is load-bearing, not tidiness. `Array.sorted` is not
    /// stable, and a place's tours are almost always published in one city
    /// batch, so their `createdAt` ties **exactly** — 22 of 24 places when the
    /// place layer shipped. `Place.ranked` breaks those ties deliberately
    /// (single-stop tour before the walk that merely starts there, then title),
    /// and an unstable sort would throw that away the moment the page ordered
    /// by its own default. Ties fall through to the incoming index instead, so
    /// whatever order the caller handed in survives.
    static func sorted(
        _ tours: [Tour],
        by criterion: AtlasTourSort,
        ascending: Bool,
        from userLocation: CLLocation?
    ) -> [Tour] {
        tours.enumerated()
            .sorted { lhs, rhs in
                compare(
                    lhs.element, rhs.element,
                    by: criterion, ascending: ascending, from: userLocation
                ) ?? (lhs.offset < rhs.offset)
            }
            .map(\.element)
    }

    /// `nil` means "this criterion cannot separate these two" — the caller
    /// then falls back to the incoming order. Distance with no location fix
    /// returns nil for every pair, so the list is left exactly as it came
    /// rather than put in a meaningless order.
    private static func compare(
        _ lhs: Tour,
        _ rhs: Tour,
        by criterion: AtlasTourSort,
        ascending: Bool,
        from userLocation: CLLocation?
    ) -> Bool? {
        switch criterion {
        case .name:
            let cmp = lhs.title.localizedCaseInsensitiveCompare(rhs.title)
            guard cmp != .orderedSame else { return nil }
            return ascending ? cmp == .orderedAscending : cmp == .orderedDescending

        case .duration:
            let l = lhs.totalDurationSeconds, r = rhs.totalDurationSeconds
            guard l != r else { return nil }
            return ascending ? l < r : l > r

        case .distance:
            guard let userLocation else { return nil }
            let l = lhs.distance(from: userLocation), r = rhs.distance(from: userLocation)
            guard l != r else { return nil }
            return ascending ? l < r : l > r

        case .dateAdded:
            // A tour with no date sorts LAST in both directions — an unknown
            // date is not an old one.
            switch (lhs.createdAt, rhs.createdAt) {
            case let (l?, r?):
                guard l != r else { return nil }
                return ascending ? l < r : l > r
            case (_?, nil): return true
            case (nil, _?): return false
            case (nil, nil): return nil
            }
        }
    }
}

/// The pull-down sort control. Each criterion is one row; the active one
/// carries an up/down chevron and a direction-aware label. Tapping the active
/// criterion flips its direction; tapping another selects it at its default
/// direction.
struct AtlasSortMenu: View {
    @Binding var criterion: AtlasTourSort
    @Binding var ascending: Bool

    var body: some View {
        Menu {
            ForEach(AtlasTourSort.allCases) { option in
                Button {
                    if option == criterion {
                        ascending.toggle()
                    } else {
                        criterion = option
                        ascending = option.defaultAscending
                    }
                } label: {
                    rowLabel(option)
                }
            }
        } label: {
            HStack(spacing: AtlasSpacing.xs) {
                Image(systemName: "arrow.up.arrow.down")
                Text(activeLabel)
            }
            .font(AtlasTypography.caption)
            .foregroundStyle(AtlasColors.secondaryText)
        }
        .accessibilityLabel("Sort tours, currently \(activeLabel)")
    }

    private var activeLabel: String { criterion.label(ascending: ascending) }

    @ViewBuilder
    private func rowLabel(_ option: AtlasTourSort) -> some View {
        if option == criterion {
            Label(
                option.label(ascending: ascending),
                systemImage: ascending ? "chevron.up" : "chevron.down"
            )
        } else {
            Text(option.label(ascending: option.defaultAscending))
        }
    }
}
