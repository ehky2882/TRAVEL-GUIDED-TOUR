import XCTest
import CoreLocation
import MapKit
@testable import TRAVEL_GUIDED_TOUR

final class HomeRailsViewModelTests: XCTestCase {

    // MARK: - Empty cases

    func test_emptyInputs_returnsNoRails() {
        let rails = HomeRailsViewModel.rails(
            tours: [],
            libraryEntries: [],
            recentlyViewedIds: [],
            userLocation: nil,
            visibleRegion: nil
        )
        XCTAssertTrue(rails.isEmpty)
    }

    // MARK: - Category rails

    func test_singleArchitectureTour_producesArchitectureRail() {
        let tour = TestFixtures.makeTour(category: .architecture)
        let rails = HomeRailsViewModel.rails(
            tours: [tour],
            libraryEntries: [],
            recentlyViewedIds: [],
            userLocation: nil,
            visibleRegion: nil
        )
        XCTAssertTrue(rails.contains { $0.id == "category.architecture" })
    }

    func test_emptyCategory_isHidden() {
        let tour = TestFixtures.makeTour(category: .architecture)
        let rails = HomeRailsViewModel.rails(
            tours: [tour],
            libraryEntries: [],
            recentlyViewedIds: [],
            userLocation: nil,
            visibleRegion: nil
        )
        // No tour in .history — that rail should be absent.
        XCTAssertFalse(rails.contains { $0.id == "category.history" })
    }

    func test_multipleCategories_producesMultipleRails() {
        let architectureTour = TestFixtures.makeTour(category: .architecture)
        let historyTour = TestFixtures.makeTour(category: .history)
        let rails = HomeRailsViewModel.rails(
            tours: [architectureTour, historyTour],
            libraryEntries: [],
            recentlyViewedIds: [],
            userLocation: nil,
            visibleRegion: nil
        )
        XCTAssertTrue(rails.contains { $0.id == "category.architecture" })
        XCTAssertTrue(rails.contains { $0.id == "category.history" })
    }

    // MARK: - Continue listening

    func test_continueListening_excludesEntriesWithoutProgress() {
        let tour = TestFixtures.makeTour()
        let savedOnly = LibraryEntry(
            tourId: tour.id,
            savedAt: Date(),
            listenedSeconds: 0
        )
        let rails = HomeRailsViewModel.rails(
            tours: [tour],
            libraryEntries: [savedOnly],
            recentlyViewedIds: [],
            userLocation: nil,
            visibleRegion: nil
        )
        XCTAssertFalse(rails.contains { $0.id == "continueListening" })
    }

    func test_continueListening_includesInProgressTours() {
        let tour = TestFixtures.makeTour()
        let inProgress = LibraryEntry(
            tourId: tour.id,
            savedAt: Date(),
            listenedSeconds: 60
        )
        let rails = HomeRailsViewModel.rails(
            tours: [tour],
            libraryEntries: [inProgress],
            recentlyViewedIds: [],
            userLocation: nil,
            visibleRegion: nil
        )
        XCTAssertTrue(rails.contains { $0.id == "continueListening" })
    }

    func test_continueListening_excludesCompletedTours() {
        let tour = TestFixtures.makeTour()
        let completed = LibraryEntry(
            tourId: tour.id,
            savedAt: Date(),
            listenedSeconds: 120,
            completedAt: Date()
        )
        let rails = HomeRailsViewModel.rails(
            tours: [tour],
            libraryEntries: [completed],
            recentlyViewedIds: [],
            userLocation: nil,
            visibleRegion: nil
        )
        XCTAssertFalse(rails.contains { $0.id == "continueListening" })
    }

    // MARK: - Recently viewed

    func test_recentlyViewed_includesViewedTours() {
        let tour1 = TestFixtures.makeTour()
        let tour2 = TestFixtures.makeTour()
        let rails = HomeRailsViewModel.rails(
            tours: [tour1, tour2],
            libraryEntries: [],
            recentlyViewedIds: [tour1.id],
            userLocation: nil,
            visibleRegion: nil
        )
        let rail = rails.first { $0.id == "recentlyViewed" }
        XCTAssertNotNil(rail)
        XCTAssertEqual(rail?.tours.count, 1)
        XCTAssertEqual(rail?.tours.first?.id, tour1.id)
    }

    func test_recentlyViewed_silentlyDropsMissingTours() {
        let tour = TestFixtures.makeTour()
        let missingId = UUID()
        let rails = HomeRailsViewModel.rails(
            tours: [tour],
            libraryEntries: [],
            recentlyViewedIds: [missingId, tour.id],
            userLocation: nil,
            visibleRegion: nil
        )
        let rail = rails.first { $0.id == "recentlyViewed" }
        XCTAssertEqual(rail?.tours.count, 1)
        XCTAssertEqual(rail?.tours.first?.id, tour.id)
    }

    // MARK: - Near you

    func test_nearYou_requiresUserLocation() {
        let tour = TestFixtures.makeTour()
        let rails = HomeRailsViewModel.rails(
            tours: [tour],
            libraryEntries: [],
            recentlyViewedIds: [],
            userLocation: nil,
            visibleRegion: nil
        )
        XCTAssertFalse(rails.contains { $0.id == "nearYou" })
    }

    func test_nearYou_includesToursWithUserLocation() {
        let tour = TestFixtures.makeTour()
        let rails = HomeRailsViewModel.rails(
            tours: [tour],
            libraryEntries: [],
            recentlyViewedIds: [],
            userLocation: CLLocation(latitude: 40.75, longitude: -73.99),
            visibleRegion: nil
        )
        XCTAssertTrue(rails.contains { $0.id == "nearYou" })
    }

    // MARK: - In view

    func test_inView_requiresVisibleRegion() {
        let tour = TestFixtures.makeTour()
        let rails = HomeRailsViewModel.rails(
            tours: [tour],
            libraryEntries: [],
            recentlyViewedIds: [],
            userLocation: nil,
            visibleRegion: nil
        )
        XCTAssertFalse(rails.contains { $0.id == "inView" })
    }

    func test_inView_hiddenWhenRegionMatchesUserLocation() {
        // Region centered at the user — "Near you" already covers this.
        let userCoord = CLLocationCoordinate2D(latitude: 40.75, longitude: -73.99)
        let tour = TestFixtures.makeTour(
            latitude: userCoord.latitude,
            longitude: userCoord.longitude
        )
        let region = MKCoordinateRegion(
            center: userCoord,
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        let rails = HomeRailsViewModel.rails(
            tours: [tour],
            libraryEntries: [],
            recentlyViewedIds: [],
            userLocation: CLLocation(latitude: userCoord.latitude, longitude: userCoord.longitude),
            visibleRegion: region
        )
        XCTAssertFalse(
            rails.contains { $0.id == "inView" },
            "When region center is within the panThreshold of user, inView rail should be hidden"
        )
    }

    func test_inView_shownWhenPannedAwayFromUser() {
        // User in NYC; map panned to LA. Tour in LA.
        let tour = TestFixtures.makeTour(latitude: 34.05, longitude: -118.25)
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 34.05, longitude: -118.25),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        let rails = HomeRailsViewModel.rails(
            tours: [tour],
            libraryEntries: [],
            recentlyViewedIds: [],
            userLocation: CLLocation(latitude: 40.75, longitude: -73.99),
            visibleRegion: region
        )
        XCTAssertTrue(rails.contains { $0.id == "inView" })
    }

    // MARK: - Ordering

    func test_railsOrder_personalizedBeforeLocationBeforeCategory() {
        // Set up state that should produce all rail families.
        let tour = TestFixtures.makeTour(category: .architecture)
        let inProgress = LibraryEntry(tourId: tour.id, listenedSeconds: 30)
        let rails = HomeRailsViewModel.rails(
            tours: [tour],
            libraryEntries: [inProgress],
            recentlyViewedIds: [tour.id],
            userLocation: CLLocation(latitude: 40.75, longitude: -73.99),
            visibleRegion: nil
        )
        let ids = rails.map(\.id)
        let indexOf: (String) -> Int? = { id in ids.firstIndex(of: id) }

        if let continueIdx = indexOf("continueListening"),
           let nearIdx = indexOf("nearYou") {
            XCTAssertLessThan(continueIdx, nearIdx, "Personalized rails should come before location-anchored")
        }
        if let nearIdx = indexOf("nearYou"),
           let archIdx = indexOf("category.architecture") {
            XCTAssertLessThan(nearIdx, archIdx, "Location-anchored rails should come before interest-based")
        }
    }
}
