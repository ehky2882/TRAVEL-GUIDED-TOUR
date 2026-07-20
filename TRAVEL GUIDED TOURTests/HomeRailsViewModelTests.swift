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

    // MARK: - Curated shelves (Phase 2)

    func test_tourWithShelfTag_producesThatShelf() {
        let tour = TestFixtures.makeTour(tags: ["Iconic Landmark"])
        let rails = HomeRailsViewModel.rails(
            tours: [tour],
            libraryEntries: [],
            recentlyViewedIds: [],
            userLocation: nil,
            visibleRegion: nil
        )
        XCTAssertTrue(rails.contains { $0.id == "shelf.Iconic Landmark" })
    }

    func test_shelfWithNoMatchingTours_isHidden() {
        let tour = TestFixtures.makeTour(tags: ["Iconic Landmark"])
        let rails = HomeRailsViewModel.rails(
            tours: [tour],
            libraryEntries: [],
            recentlyViewedIds: [],
            userLocation: nil,
            visibleRegion: nil
        )
        // No tour tagged Food — that shelf should be absent.
        XCTAssertFalse(rails.contains { $0.id == "shelf.Food" })
    }

    func test_curatedShelvesFollowEditorialOrder() {
        // Two tours, one per shelf; assert the shelves render in the
        // curated order, not tag-alphabetical or insertion order.
        let iconic = TestFixtures.makeTour(tags: ["Iconic Landmark"])
        let food = TestFixtures.makeTour(tags: ["Food"])
        let rails = HomeRailsViewModel.rails(
            tours: [food, iconic],
            libraryEntries: [],
            recentlyViewedIds: [],
            userLocation: nil,
            visibleRegion: nil
        )
        let ids = rails.map(\.id)
        let iconicIdx = ids.firstIndex(of: "shelf.Iconic Landmark")
        let foodIdx = ids.firstIndex(of: "shelf.Food")
        XCTAssertNotNil(iconicIdx)
        XCTAssertNotNil(foodIdx)
        XCTAssertLessThan(iconicIdx!, foodIdx!, "Iconic landmarks shelf comes before Food in the curated order")
    }

    func test_broadTagsAreNotShelves() {
        // Architecture (56%) + History (44%) were dropped as shelves —
        // a tour carrying only those tags produces no shelf.
        let tour = TestFixtures.makeTour(tags: ["Architecture", "History"])
        let rails = HomeRailsViewModel.rails(
            tours: [tour],
            libraryEntries: [],
            recentlyViewedIds: [],
            userLocation: nil,
            visibleRegion: nil
        )
        XCTAssertFalse(rails.contains { $0.id == "shelf.Architecture" })
        XCTAssertFalse(rails.contains { $0.id == "shelf.History" })
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

    // MARK: - Near you / In view (§1.5 location-rail behaviour)

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

    func test_nearYou_shownWhenMapOverUser() {
        // User with no panned region → near mode → Near you shows.
        let tour = TestFixtures.makeTour()
        let rails = HomeRailsViewModel.rails(
            tours: [tour],
            libraryEntries: [],
            recentlyViewedIds: [],
            userLocation: CLLocation(latitude: 40.75, longitude: -73.99),
            visibleRegion: nil
        )
        XCTAssertTrue(rails.contains { $0.id == "nearYou" })
        XCTAssertFalse(rails.contains { $0.id == "inView" })
    }

    func test_inView_requiresVisibleRegion() {
        let tour = TestFixtures.makeTour()
        let rails = HomeRailsViewModel.rails(
            tours: [tour],
            libraryEntries: [],
            recentlyViewedIds: [],
            userLocation: CLLocation(latitude: 40.75, longitude: -73.99),
            visibleRegion: nil
        )
        XCTAssertFalse(rails.contains { $0.id == "inView" })
    }

    func test_nearMode_regionMatchesUser_showsNearYouNotInView() {
        // Region centered at the user (within pan threshold) → near mode.
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
        XCTAssertTrue(rails.contains { $0.id == "nearYou" })
        XCTAssertFalse(rails.contains { $0.id == "inView" })
    }

    func test_farMode_pannedAway_showsInViewAndHidesNearYou() {
        // User in NYC; map panned to LA. §1.5: "In view" becomes the
        // top location rail and "Near you" is hidden entirely.
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
        XCTAssertTrue(rails.contains { $0.id == "inView" }, "In view is the top location rail in far mode")
        XCTAssertFalse(rails.contains { $0.id == "nearYou" }, "Near you is hidden in far mode")
    }

    func test_isPannedFar_boundaries() {
        let user = CLLocation(latitude: 40.75, longitude: -73.99)
        // No region → not far (near mode).
        XCTAssertFalse(HomeRailsViewModel.isPannedFar(userLocation: user, visibleRegion: nil))
        // No user but a region → far (show In view).
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 34.05, longitude: -118.25),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        XCTAssertTrue(HomeRailsViewModel.isPannedFar(userLocation: nil, visibleRegion: region))
        // Region far from user → far.
        XCTAssertTrue(HomeRailsViewModel.isPannedFar(userLocation: user, visibleRegion: region))
    }

    // MARK: - Filtered results (§1.6 + D6/D8)

    func test_filteredResults_walksOnly_keepsMultiStop() {
        let single = TestFixtures.makeTour(kind: .single, stopCount: 1)
        let walk = TestFixtures.makeTour(kind: .multiStop, stopCount: 4)
        let results = HomeRailsViewModel.filteredResults(
            tours: [single, walk],
            selectedTags: [],
            walksOnly: true,
            userLocation: nil,
            visibleRegion: nil
        )
        XCTAssertEqual(results.map(\.id), [walk.id])
    }

    func test_filteredResults_tagFilter_andWalks_combine() {
        let museumWalk = TestFixtures.makeTour(kind: .multiStop, tags: ["Museum", "Art"], stopCount: 3)
        let museumSingle = TestFixtures.makeTour(kind: .single, tags: ["Museum", "Art"])
        let parkWalk = TestFixtures.makeTour(kind: .multiStop, tags: ["Park"], stopCount: 3)
        let results = HomeRailsViewModel.filteredResults(
            tours: [museumWalk, museumSingle, parkWalk],
            selectedTags: ["Museum"],
            walksOnly: true,
            userLocation: nil,
            visibleRegion: nil
        )
        XCTAssertEqual(results.map(\.id), [museumWalk.id], "Only the multi-stop Museum tour survives Museum + Walks")
    }

    func test_filteredResults_userInView_sortsByUserLocationNotViewportCenter() {
        // User is on screen. The tour nearest the *user* ranks first even
        // though a different tour sits nearer the region center — the
        // owner's rule: rank by distance to you when you're in view.
        let user = CLLocationCoordinate2D(latitude: 40.0, longitude: -74.0)
        let regionCenter = CLLocationCoordinate2D(latitude: 40.2, longitude: -74.0)
        let nearUser = TestFixtures.makeTour(tags: ["Food"], latitude: 40.01, longitude: -74.0)
        let nearCenter = TestFixtures.makeTour(tags: ["Food"], latitude: 40.2, longitude: -74.0)
        // Region spans the user (center 40.2 ± 1.5° covers 40.0).
        let region = MKCoordinateRegion(
            center: regionCenter,
            span: MKCoordinateSpan(latitudeDelta: 3, longitudeDelta: 3)
        )
        let results = HomeRailsViewModel.filteredResults(
            tours: [nearCenter, nearUser],
            selectedTags: ["Food"],
            walksOnly: false,
            userLocation: CLLocation(latitude: user.latitude, longitude: user.longitude),
            visibleRegion: region
        )
        XCTAssertEqual(results.map(\.id), [nearUser.id, nearCenter.id])
    }

    func test_filteredResults_userOffScreen_sortsByViewportCenter() {
        // User has panned far away (not contained in the region) → fall
        // back to ranking by the viewport center.
        let user = CLLocationCoordinate2D(latitude: 40.75, longitude: -73.99) // NYC
        let center = CLLocationCoordinate2D(latitude: 34.05, longitude: -118.25) // LA
        let nearCenter = TestFixtures.makeTour(tags: ["Food"], latitude: 34.06, longitude: -118.25)
        let nearUser = TestFixtures.makeTour(tags: ["Food"], latitude: 40.74, longitude: -73.99)
        let region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
        let results = HomeRailsViewModel.filteredResults(
            tours: [nearUser, nearCenter],
            selectedTags: ["Food"],
            walksOnly: false,
            userLocation: CLLocation(latitude: user.latitude, longitude: user.longitude),
            visibleRegion: region
        )
        XCTAssertEqual(results.map(\.id), [nearCenter.id, nearUser.id])
    }

    func test_filteredResults_sortsByViewportCenter() {
        // Two tours; the one nearer the visible-region center ranks first.
        let center = CLLocationCoordinate2D(latitude: 40.0, longitude: -74.0)
        let near = TestFixtures.makeTour(tags: ["Food"], latitude: 40.01, longitude: -74.0)
        let far = TestFixtures.makeTour(tags: ["Food"], latitude: 41.0, longitude: -74.0)
        let region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 3, longitudeDelta: 3)
        )
        let results = HomeRailsViewModel.filteredResults(
            tours: [far, near],
            selectedTags: ["Food"],
            walksOnly: false,
            userLocation: nil,
            visibleRegion: region
        )
        XCTAssertEqual(results.map(\.id), [near.id, far.id])
    }
}
