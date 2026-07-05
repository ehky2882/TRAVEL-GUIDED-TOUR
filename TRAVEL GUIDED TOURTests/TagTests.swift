import XCTest
@testable import TRAVEL_GUIDED_TOUR

final class TagTests: XCTestCase {

    // MARK: - Vocabulary integrity

    func test_everyFacetTagResolvesBackToItsFacet() {
        for (facet, tags) in Tag.vocabulary {
            for tag in tags {
                XCTAssertEqual(Tag.facet(for: tag), facet, "\(tag) should map to \(facet.rawValue)")
            }
        }
    }

    func test_curatedShelfTagsAreInVocabulary() {
        for shelf in Tag.curatedShelves {
            XCTAssertTrue(Tag.allValid.contains(shelf.tag), "Shelf tag \(shelf.tag) must be a valid vocabulary tag")
        }
    }

    func test_filterChipsAreInVocabulary() {
        for tag in Tag.filterChips {
            XCTAssertTrue(Tag.allValid.contains(tag), "Filter chip \(tag) must be a valid vocabulary tag")
        }
    }

    func test_broadTagsAreNotShelves() {
        // Architecture (56%) and History (44%) were dropped per §3.1.
        let shelfTags = Set(Tag.curatedShelves.map(\.tag))
        XCTAssertFalse(shelfTags.contains("Architecture"))
        XCTAssertFalse(shelfTags.contains("History"))
    }

    func test_thinTagsAreNotFilterChips() {
        // Plan §3.1: these read as broken chips (5 tours / 1 city).
        let chips = Set(Tag.filterChips)
        for thin in ["LGBTQ+", "Library", "Brutalist", "Gilded Age", "Art Deco", "Crime", "Bridge"] {
            XCTAssertFalse(chips.contains(thin), "\(thin) is too thin to be a filter chip")
        }
    }

    // MARK: - Multi-select filter logic (D6)

    func test_matches_emptySelection_matchesEverything() {
        XCTAssertTrue(Tag.matches(tourTags: [], selection: []))
        XCTAssertTrue(Tag.matches(tourTags: ["Museum"], selection: []))
    }

    func test_matches_singleTag_requiresPresence() {
        XCTAssertTrue(Tag.matches(tourTags: ["Museum", "Art"], selection: ["Museum"]))
        XCTAssertFalse(Tag.matches(tourTags: ["Park"], selection: ["Museum"]))
    }

    func test_matches_acrossFacets_ANDs() {
        // Museum (Place type) + Food (Theme) → both required.
        let sel: Set<String> = ["Museum", "Food"]
        XCTAssertTrue(Tag.matches(tourTags: ["Museum", "Food", "History"], selection: sel))
        XCTAssertFalse(Tag.matches(tourTags: ["Museum", "Art"], selection: sel), "Missing the Food theme fails the AND")
        XCTAssertFalse(Tag.matches(tourTags: ["Food"], selection: sel), "Missing the Museum place type fails the AND")
    }

    func test_matches_withinFacet_ORs() {
        // Museum + Market are both Place types → either satisfies.
        let sel: Set<String> = ["Museum", "Market"]
        XCTAssertTrue(Tag.matches(tourTags: ["Museum"], selection: sel))
        XCTAssertTrue(Tag.matches(tourTags: ["Market"], selection: sel))
        XCTAssertFalse(Tag.matches(tourTags: ["Park"], selection: sel))
    }

    func test_matches_mixedFacets_ORwithin_ANDacross() {
        // (Museum OR Market) AND (Food) — Place type facet ORs, and the
        // Food theme facet must also be present.
        let sel: Set<String> = ["Museum", "Market", "Food"]
        XCTAssertTrue(Tag.matches(tourTags: ["Market", "Food"], selection: sel))
        XCTAssertFalse(Tag.matches(tourTags: ["Market"], selection: sel), "Food theme missing")
        XCTAssertFalse(Tag.matches(tourTags: ["Park", "Food"], selection: sel), "No matching place type")
    }

    // MARK: - Derived primary (D5)

    func test_derivePrimary_prefersPlaceTypeOverTheme() {
        XCTAssertEqual(Tag.derivePrimary(from: ["History", "Museum"]), "Museum")
    }

    func test_derivePrimary_placeTypeSpecificOverCatchAll() {
        // Religious Building precedes Notable Building in vocab order.
        XCTAssertEqual(Tag.derivePrimary(from: ["Notable Building", "Religious Building"]), "Religious Building")
    }

    func test_derivePrimary_fallsBackToTheme() {
        XCTAssertEqual(Tag.derivePrimary(from: ["Faith"]), "Faith")
    }

    func test_derivePrimary_taglessIsNil() {
        XCTAssertNil(Tag.derivePrimary(from: []))
    }

    func test_derivePrimary_isDeterministic() {
        let tags = ["Art", "Museum", "Iconic Landmark", "Contemporary"]
        XCTAssertEqual(Tag.derivePrimary(from: tags), Tag.derivePrimary(from: tags.reversed()))
    }
}
