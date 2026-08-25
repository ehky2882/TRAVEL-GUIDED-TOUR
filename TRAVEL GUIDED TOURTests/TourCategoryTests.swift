import XCTest
@testable import TRAVEL_GUIDED_TOUR

final class TourCategoryTests: XCTestCase {

    func test_allCases_haveNonEmptyDisplayName() {
        for category in TourCategory.allCases {
            XCTAssertFalse(
                category.displayName.isEmpty,
                "TourCategory.\(category.rawValue) has empty displayName"
            )
        }
    }

    func test_allCases_haveNonEmptyIconName() {
        for category in TourCategory.allCases {
            XCTAssertFalse(
                category.iconName.isEmpty,
                "TourCategory.\(category.rawValue) has empty iconName"
            )
        }
    }

    func test_id_matchesRawValue() {
        XCTAssertEqual(TourCategory.history.id, "history")
        XCTAssertEqual(TourCategory.architecture.id, "architecture")
        XCTAssertEqual(TourCategory.visualArt.id, "visualArt")
    }

    func test_decodesFromJSON() throws {
        let json = Data(#""visualArt""#.utf8)
        let category = try JSONDecoder().decode(TourCategory.self, from: json)
        XCTAssertEqual(category, .visualArt)
    }

    /// ⚠️ **CONTRACT DELIBERATELY CHANGED — this was
    /// `test_decodingBadValue_throws`.**
    ///
    /// Throwing meant one unfamiliar category failed its tour, which failed the
    /// whole `[Tour]` array, which `RemoteCatalogLoader`'s `try?` turned into a
    /// silent "no new content". A tour with a category this build has not heard
    /// of is still a perfectly good tour — title, hero, narration, coordinate
    /// all understood — and only its shelf is in doubt, so it now lands on the
    /// neutral one rather than being lost.
    func test_decodingUnknownValue_fallsBackToNeutralCategory() throws {
        let json = Data(#""notACategory""#.utf8)
        let category = try JSONDecoder().decode(TourCategory.self, from: json)
        XCTAssertEqual(category, .culturalHeritage)
    }

    func test_encodeDecodeRoundTrip() throws {
        for category in TourCategory.allCases {
            let encoded = try JSONEncoder().encode(category)
            let decoded = try JSONDecoder().decode(TourCategory.self, from: encoded)
            XCTAssertEqual(decoded, category)
        }
    }
}
