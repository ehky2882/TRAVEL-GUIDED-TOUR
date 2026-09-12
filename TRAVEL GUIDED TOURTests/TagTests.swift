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

    func test_panelGroupPromotedTagsAreInTheirOwnFacet() {
        for group in Tag.panelGroups {
            for tag in group.promoted {
                XCTAssertEqual(
                    Tag.facet(for: tag), group.facet,
                    "\(tag) is promoted under \(group.title) but belongs to a different facet"
                )
            }
        }
    }

    func test_panelGroupsPromoteFewEnoughToFitOneScreen() {
        // The Tags panel fits one 844pt screen at 9 rows; it stopped fitting at
        // 13. Promoting more than four per group is what took it there, so this
        // guards the fit rather than the taste.
        for group in Tag.panelGroups {
            XCTAssertLessThanOrEqual(group.promoted.count, 4, "\(group.title) promotes too many to fit")
        }
    }

    func test_moreCountAccountsForEveryUnpromotedValue() {
        for group in Tag.panelGroups {
            XCTAssertEqual(
                group.promoted.count + group.moreCount, Tag.tags(in: group.facet).count,
                "\(group.title)'s More would hide or double-count values"
            )
        }
    }

    func test_broadTagsAreNotShelves() {
        // Architecture (56%) and History (44%) were dropped per §3.1.
        let shelfTags = Set(Tag.curatedShelves.map(\.tag))
        XCTAssertFalse(shelfTags.contains("Architecture"))
        XCTAssertFalse(shelfTags.contains("History"))
    }

    func test_duplicatingValuesAreNotPromoted() {
        // Measured overlaps, not taste: Faith is 88% Religious Building, Green
        // Escape 72% Park, and Architecture/History each match a third or more
        // of the catalogue. All four stay reachable under More.
        let promoted = Set(Tag.panelGroups.flatMap(\.promoted))
        for duplicating in ["Faith", "Green Escape", "Architecture", "History"] {
            XCTAssertFalse(promoted.contains(duplicating), "\(duplicating) duplicates a neighbour or narrows nothing")
        }
    }

    func test_searchedFacetIsTheOneTooLongForAGrid() {
        XCTAssertGreaterThan(Tag.tags(in: Tag.searchedFacet).count, 30)
        for group in Tag.panelGroups {
            XCTAssertLessThanOrEqual(Tag.tags(in: group.facet).count, 30, "\(group.title) should be a search, not a grid")
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

    // MARK: - tags(in:) + ordered (maker picker)

    func test_tagsInFacet_matchesVocabulary() {
        XCTAssertEqual(Tag.tags(in: .placeType), Tag.vocabulary.first { $0.facet == .placeType }?.tags)
        XCTAssertTrue(Tag.tags(in: .theme).contains("Food"))
    }

    func test_ordered_sortsSelectionIntoVocabularyOrder() {
        // Theme picked before Place type in the set → Place type leads out.
        let ordered = Tag.ordered(["Food", "Museum", "Contemporary"])
        XCTAssertEqual(ordered, ["Museum", "Food", "Contemporary"])
    }

    func test_ordered_dropsUnknownTags() {
        XCTAssertEqual(Tag.ordered(["Museum", "NotATag"]), ["Museum"])
    }

    // MARK: - deriveCategory (legacy primaryCategory bridge)

    func test_deriveCategory_faithWins() {
        XCTAssertEqual(Tag.deriveCategory(from: ["Religious Building", "Architecture", "History"]), .sacredSites)
    }

    func test_deriveCategory_artOverArchitecture() {
        XCTAssertEqual(Tag.deriveCategory(from: ["Museum", "Art", "Architecture"]), .visualArt)
    }

    func test_deriveCategory_parkGreen() {
        XCTAssertEqual(Tag.deriveCategory(from: ["Park", "Green Escape"]), .natureAndParks)
    }

    func test_deriveCategory_architectureWhenNoStrongerSignal() {
        XCTAssertEqual(Tag.deriveCategory(from: ["Notable Building", "Architecture"]), .architecture)
    }

    func test_deriveCategory_fallsBackToCulturalHeritage() {
        XCTAssertEqual(Tag.deriveCategory(from: ["Notable Building", "Immigration"]), .culturalHeritage)
    }
}
