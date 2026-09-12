import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// `TourFilter` is the whole filter row reduced to one value, so these cover
/// the two things that would be invisible if they broke: the **combine rule**
/// (any within a group, all across groups) and the **contextual counts**, which
/// are the part most likely to ship subtly wrong.
final class TourFilterTests: XCTestCase {

    // MARK: - The combine rule

    func test_emptyFilter_matchesEverything() {
        let filter = TourFilter.none
        XCTAssertFalse(filter.isActive)
        XCTAssertTrue(filter.matches(TestFixtures.makeTour()))
        XCTAssertTrue(filter.matches(TestFixtures.makeTour(kind: .multiStop, tags: ["Museum"], stopCount: 3)))
    }

    func test_withinAGroup_valuesOR() {
        let stop = TestFixtures.makeTour(kind: .single)
        let walk = TestFixtures.makeTour(kind: .multiStop, stopCount: 3)
        let filter = TourFilter(formats: [.audioStop, .audioWalk])
        XCTAssertTrue(filter.matches(stop), "Picking two formats means either, not both")
        XCTAssertTrue(filter.matches(walk))
    }

    func test_acrossGroups_valuesAND() {
        let paidWalk = TestFixtures.makeTour(kind: .multiStop, stopCount: 3, priceTier: 99)
        let freeWalk = TestFixtures.makeTour(kind: .multiStop, stopCount: 3)
        let paidStop = TestFixtures.makeTour(kind: .single, priceTier: 99)
        let filter = TourFilter(formats: [.audioWalk], prices: [.paid])
        XCTAssertTrue(filter.matches(paidWalk))
        XCTAssertFalse(filter.matches(freeWalk), "Format matched but price did not — groups AND")
        XCTAssertFalse(filter.matches(paidStop), "Price matched but format did not — groups AND")
    }

    /// The `Tags` group carries both halves of the rule by itself, because
    /// `Tag.matches` derives each tag's facet rather than being told it. This is
    /// why collapsing five facet chips into one `Tags` chip changed no
    /// behaviour.
    func test_tagsGroup_keepsFacetSemanticsOnItsOwn() {
        let museumAboutFood = TestFixtures.makeTour(tags: ["Museum", "Food"])
        let museumAboutArt = TestFixtures.makeTour(tags: ["Museum", "Art"])
        let marketAboutFood = TestFixtures.makeTour(tags: ["Market", "Food"])

        // Two place types — same facet, so either.
        let placeOnly = TourFilter(tags: ["Museum", "Market"])
        XCTAssertTrue(placeOnly.matches(museumAboutArt))
        XCTAssertTrue(placeOnly.matches(marketAboutFood))

        // A place type and a subject — different facets, so both.
        let across = TourFilter(tags: ["Museum", "Food"])
        XCTAssertTrue(across.matches(museumAboutFood))
        XCTAssertFalse(across.matches(museumAboutArt), "Right place, wrong subject")
        XCTAssertFalse(across.matches(marketAboutFood), "Right subject, wrong place")
    }

    func test_makerGroup_filtersByAuthor() {
        let mine = UUID(), theirs = UUID()
        let filter = TourFilter(makerIds: [mine])
        XCTAssertTrue(filter.matches(TestFixtures.makeTour(makerId: mine)))
        XCTAssertFalse(filter.matches(TestFixtures.makeTour(makerId: theirs)))
    }

    // MARK: - Format, including the short-form split

    func test_youTubeShortsAndVideosAreDistinct() {
        let short = TestFixtures.makeTour(kind: .link, sourceURL: "https://www.youtube.com/shorts/abc123")
        let video = TestFixtures.makeTour(kind: .link, sourceURL: "https://www.youtube.com/watch?v=abc123")

        XCTAssertTrue(TourFilter(formats: [.youtubeShorts]).matches(short))
        XCTAssertFalse(TourFilter(formats: [.youtubeShorts]).matches(video))
        XCTAssertTrue(TourFilter(formats: [.youtubeVideos]).matches(video))
        XCTAssertFalse(TourFilter(formats: [.youtubeVideos]).matches(short))
    }

    /// A video merely *titled* "shorts" is not a Short — the path component
    /// match is what stops a caption deciding a format.
    func test_aVideoTitledShortsIsNotAShort() {
        let tour = TestFixtures.makeTour(kind: .link, sourceURL: "https://www.youtube.com/watch?v=x&t=shorts")
        XCTAssertTrue(TourFilter(formats: [.youtubeVideos]).matches(tour))
        XCTAssertFalse(TourFilter(formats: [.youtubeShorts]).matches(tour))
    }

    func test_instagramReelsAndPostsAreDistinct() {
        let reel = TestFixtures.makeTour(kind: .link, sourceURL: "https://www.instagram.com/reel/DdBnCYhMHVz/")
        let post = TestFixtures.makeTour(kind: .link, sourceURL: "https://www.instagram.com/p/CEMpGQVHy8W/")
        let igtv = TestFixtures.makeTour(kind: .link, sourceURL: "https://www.instagram.com/tv/CjarNZrJrt6/")

        XCTAssertTrue(TourFilter(formats: [.instagramReels]).matches(reel))
        XCTAssertTrue(TourFilter(formats: [.instagramPosts]).matches(post))
        // IGTV is retired and there is exactly one of these in the catalogue;
        // it reads as a post, which is the honest place for it.
        XCTAssertTrue(TourFilter(formats: [.instagramPosts]).matches(igtv))
        XCTAssertFalse(TourFilter(formats: [.instagramReels]).matches(post))
    }

    func test_audioFormatsDoNotMatchPinnedPosts() {
        let tiktok = TestFixtures.makeTour(kind: .link, sourceURL: "https://www.tiktok.com/@a/video/123")
        XCTAssertFalse(TourFilter(formats: [.audioStop]).matches(tiktok))
        XCTAssertFalse(TourFilter(formats: [.audioWalk]).matches(tiktok))
        XCTAssertTrue(TourFilter(formats: [.tiktok]).matches(tiktok))
    }

    // MARK: - Price

    func test_priceReadsTheTier() {
        let free = TestFixtures.makeTour()
        let paid = TestFixtures.makeTour(priceTier: 99)
        XCTAssertTrue(TourFilter(prices: [.free]).matches(free))
        XCTAssertFalse(TourFilter(prices: [.free]).matches(paid))
        XCTAssertTrue(TourFilter(prices: [.paid]).matches(paid))
    }

    // MARK: - Contextual counts

    /// 🔴 The one that matters. A global count beside an option is a lie the
    /// moment anything else is selected, and it invites the tap that empties
    /// the map.
    func test_countIsContextual_notGlobal() {
        let tours = [
            TestFixtures.makeTour(tags: ["Museum", "Art", "Contemporary"]),
            TestFixtures.makeTour(tags: ["Park", "Contemporary"]),
            TestFixtures.makeTour(tags: ["Park", "Contemporary"]),
        ]
        let contemporary = FilterOption.tag("Contemporary")

        // Globally, Contemporary is everything here.
        XCTAssertEqual(TourFilter.none.count(adding: contemporary, in: tours), 3)

        // Alongside Museum it is one — and alongside Market, none at all.
        XCTAssertEqual(TourFilter(tags: ["Museum"]).count(adding: contemporary, in: tours), 1)
        XCTAssertEqual(TourFilter(tags: ["Market"]).count(adding: contemporary, in: tours), 0)
    }

    /// Adding a value WIDENS its own group, so a count can go up. The method
    /// asks "if this were also selected", not "how many carry this tag".
    func test_countCanRiseWithinAGroup() {
        let tours = [
            TestFixtures.makeTour(tags: ["Museum"]),
            TestFixtures.makeTour(tags: ["Market"]),
        ]
        let filter = TourFilter(tags: ["Museum"])
        XCTAssertEqual(filter.matchCount(in: tours), 1)
        XCTAssertEqual(filter.count(adding: .tag("Market"), in: tours), 2, "Same facet, so the group ORs wider")
    }

    /// An already-selected option must still report what selecting it gives —
    /// otherwise a selected chip would show the count for deselecting itself.
    func test_countOfAnAlreadySelectedOption_doesNotReportItsRemoval() {
        let tours = [
            TestFixtures.makeTour(tags: ["Museum"]),
            TestFixtures.makeTour(tags: ["Park"]),
        ]
        let filter = TourFilter(tags: ["Museum"])
        XCTAssertEqual(filter.count(adding: .tag("Museum"), in: tours), 1)
    }

    // MARK: - Badge and labels

    func test_valueCountCountsValuesNotGroups() {
        let filter = TourFilter(formats: [.audioWalk], prices: [.paid], tags: ["Museum", "Art"])
        XCTAssertEqual(filter.valueCount, 4)
    }

    func test_clearingOneGroupLeavesTheOthers() {
        var filter = TourFilter(formats: [.audioWalk], tags: ["Museum"])
        filter.clear(.format)
        XCTAssertTrue(filter.formats.isEmpty)
        XCTAssertEqual(filter.tags, ["Museum"])
        XCTAssertTrue(filter.isActive)
    }

    func test_toggleAddsThenRemoves() {
        var filter = TourFilter.none
        filter.toggle(.format(.audioWalk))
        XCTAssertTrue(filter.contains(.format(.audioWalk)))
        filter.toggle(.format(.audioWalk))
        XCTAssertFalse(filter.isActive)
    }

    /// The chip's collapsed label comes from these, so their order is what a
    /// viewer reads as "Museum +2".
    func test_tagValuesComeBackInVocabularyOrder() {
        let filter = TourFilter(tags: ["Art", "Museum"])
        XCTAssertEqual(filter.values(in: .tags, makerName: { _ in nil }), ["Museum", "Art"],
                       "Place type leads, as everywhere else in the catalogue")
    }
}
