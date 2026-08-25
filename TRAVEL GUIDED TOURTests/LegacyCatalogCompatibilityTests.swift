import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// Can a build that has never heard of a link pin still read the catalogue we
/// ship?
///
/// This is the whole point of moving link pins into their own top-level
/// `linkPins` array, so it is tested against **the real shipped catalogue** —
/// `Resources/Tours.json`, the file `publish-catalog.yml` copies byte-for-byte
/// to the gh-pages mirror and seeds into Supabase — rather than a hand-written
/// fixture that could be made to say anything.
///
/// # What went wrong, and why an old build is what matters
///
/// `TourKind` is a closed string enum, `ToursData` decodes `tours` as ONE
/// array, and `RemoteCatalogLoader` wraps the decode in `try?`. So the day four
/// `kind: "link"` pins went into the live catalogue, every build shipped before
/// `TourKind.link` threw on those elements — which failed the entire array,
/// which failed the entire catalogue, which the loader read as a failed fetch.
/// It kept its last good copy and logged nothing. No crash. The phone simply
/// stopped receiving all new content.
///
/// 🔴 **Tolerance cannot fix that.** Tolerance only protects builds shipped
/// after it. A build already in review at Apple is strict and always will be.
/// Moving the pins to a key it does not know is the only change that reaches
/// backwards, because an unknown top-level KEY is skipped in silence while an
/// unknown VALUE in a known field is fatal.
private enum Legacy {

    // MARK: The model layer of build 66, transcribed from commit 2bcf0df2
    //
    // Build 66 is the build sitting in "Waiting for Review" at Apple, submitted
    // 17 August. Its `ToursData` really is just these two properties, and its
    // `TourKind` really does have only two cases — that is what makes the
    // unknown-key argument a fact about this app rather than a claim about
    // Swift. It carries no `country`, no `videoRole`, no `sourceURL`, no
    // `Place` type at all; every one of those is a key it silently skips.
    //
    // ⚠️ Do NOT "update" these to match the current models. They are a frozen
    // record of what is already on people's phones. The moment they track
    // `Models/`, this test stops testing anything.

    enum TourKind: String, Codable {
        case single
        case multiStop
    }

    enum StopTriggerMode: String, Codable {
        case geofenced
        case manual
    }

    enum TourCategory: String, Codable {
        case history, architecture, visualArt, musicAndPerformance, literature
        case foodAndDrink, natureAndParks, hiddenGems, culturalHeritage, sacredSites
    }

    struct Maker: Codable {
        let id: UUID
        let displayName: String
        let avatarURL: String?
        let avatarEmoji: String?
        let avatarInitials: String?
        let avatarColor: String?
        let bio: String
        let websiteURL: String?
        let link2URL: String?
        let link3URL: String?
        let isPrivate: Bool?
        let userId: UUID?
    }

    struct Stop: Codable {
        let id: UUID
        let order: Int
        let title: String
        let caption: String?
        let latitude: Double
        let longitude: Double
        let audioURL: String
        let audioDurationSeconds: Int
        let triggerMode: StopTriggerMode
        let triggerRadiusMeters: Int
        let imageURL: String?
        let transcriptText: String?
    }

    struct Tour: Codable {
        let id: UUID
        let title: String
        let shortDescription: String
        let longDescription: String
        let makerId: UUID
        let heroImageURL: String
        let additionalImageURLs: [String]?
        let videoURLs: [String]?
        let kind: TourKind
        let stops: [Stop]
        let introAudioURL: String?
        let totalDurationSeconds: Int
        let walkingDistanceMeters: Int?
        let centroidLatitude: Double
        let centroidLongitude: Double
        let city: String?
        let primaryCategory: TourCategory
        let tags: [String]
        let priceUSD: Decimal
        let priceTier: Int?
        let createdAt: String?
    }

    struct ToursData: Codable {
        let makers: [Maker]
        let tours: [Tour]
    }
}

final class LegacyCatalogCompatibilityTests: XCTestCase {

    // MARK: - The shipped catalogue

    /// The bundled `Resources/Tours.json`, exactly as it ships — and, because
    /// `publish-catalog.yml` copies this same file, exactly as the gh-pages
    /// mirror serves it.
    private func shippedCatalogData() throws -> Data {
        // The unit test bundle is hosted by the app (TEST_HOST), so `Bundle.main`
        // is the app bundle and carries Resources/Tours.json. The test bundle is
        // a fallback for any host arrangement where it is not.
        let url = Bundle.main.url(forResource: "Tours", withExtension: "json")
            ?? Bundle(for: LegacyCatalogCompatibilityTests.self)
                .url(forResource: "Tours", withExtension: "json")
        return try Data(contentsOf: XCTUnwrap(url, "Tours.json is not in the test host's bundle"))
    }

    /// The raw top-level object, so a test can talk about what is literally in
    /// the file rather than about what a model chose to decode.
    private func shippedCatalogJSON() throws -> [String: Any] {
        let object = try JSONSerialization.jsonObject(with: try shippedCatalogData())
        return try XCTUnwrap(object as? [String: Any])
    }

    // MARK: - The proof

    /// 🔴 THE ONE THAT MATTERS. Build 66's decoder, against the catalogue we
    /// actually publish.
    func test_shippedCatalog_decodesOnABuildThatNeverHeardOfALinkPin() throws {
        let data = try shippedCatalogData()

        // No `try?` here on purpose: if this throws, the failure message names
        // the exact coding path, which is the diagnosis the shipped loader
        // throws away.
        let legacy = try JSONDecoder().decode(Legacy.ToursData.self, from: data)

        let raw = try shippedCatalogJSON()
        let listed = try XCTUnwrap(raw["tours"] as? [[String: Any]])

        XCTAssertEqual(legacy.tours.count, listed.count,
                       "an old build must read every tour in `tours`, not a prefix of them")
        XCTAssertGreaterThan(legacy.tours.count, 1_000,
                             "the catalogue decoded but came back implausibly small")
        XCTAssertFalse(legacy.makers.isEmpty)

        // `places` and `linkPins` are both keys build 66 has never heard of. It
        // got here, so both were skipped in silence — which is the mechanism the
        // whole change rests on.
        XCTAssertNotNil(raw["linkPins"], "the catalogue is no longer carrying a linkPins key")
        XCTAssertNotNil(raw["places"], "the catalogue is no longer carrying a places key")
    }

    /// The pins are outside `tours`, and this build still sees them.
    func test_linkPins_travelOutsideTours_andThisBuildMergesThemBackIn() throws {
        let raw = try shippedCatalogJSON()
        let listed = try XCTUnwrap(raw["tours"] as? [[String: Any]])
        let pins = raw["linkPins"] as? [[String: Any]] ?? []

        XCTAssertTrue(listed.allSatisfy { $0["kind"] as? String != "link" },
                      "a link pin is in `tours` — that is the bug this array exists to prevent")
        XCTAssertTrue(pins.allSatisfy { $0["kind"] as? String == "link" },
                      "`linkPins` may only hold link pins; anything else is hidden from old builds for nothing")

        let modern = try JSONDecoder().decode(ToursData.self, from: try shippedCatalogData())
        XCTAssertEqual(modern.tours.count, listed.count + pins.count,
                       "the merge must add the pins to `tours`, not replace or drop them")
        XCTAssertEqual(modern.tours.filter { $0.kind == .link }.count, pins.count)
    }

    /// The teeth. Put a single unknown `kind` back inside `tours` — the shape
    /// the live catalogue actually had on 2026-08-24 — and build 66's decoder
    /// loses the **entire** catalogue, not one tour.
    ///
    /// Without this, the test above would pass just as happily against a
    /// decoder that never rejects anything.
    func test_oneUnknownKindInsideTours_losesTheWholeCatalogue() throws {
        var raw = try shippedCatalogJSON()
        var listed = try XCTUnwrap(raw["tours"] as? [[String: Any]])
        XCTAssertGreaterThan(listed.count, 1, "need at least two tours to make the point")

        // Relabel exactly one ordinary tour, so this reproduces the failure
        // whatever the catalogue happens to contain today.
        listed[0]["kind"] = "link"
        raw["tours"] = listed
        let data = try JSONSerialization.data(withJSONObject: raw)

        XCTAssertThrowsError(try JSONDecoder().decode(Legacy.ToursData.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError,
                          "expected the closed enum to reject it, got \(error)")
        }

        // And this is the part that made it silent: the loader's `try?` turns
        // that throw into a plain nil, which it cannot tell apart from a
        // network failure — so it keeps its last good copy and says nothing.
        XCTAssertNil(try? JSONDecoder().decode(Legacy.ToursData.self, from: data))

        // One bad element out of ~1,500 costs all of them.
        let survivors = listed.dropFirst().count
        XCTAssertGreaterThan(survivors, 1_000,
                             "…and every one of these decodes perfectly well on its own")
    }

    /// The same bytes, with the pins where they belong, decode fine — so the
    /// failure above is caused by the placement and nothing else.
    func test_movingThatSameTourIntoLinkPins_isWhatFixesIt() throws {
        var raw = try shippedCatalogJSON()
        var listed = try XCTUnwrap(raw["tours"] as? [[String: Any]])
        var pins = raw["linkPins"] as? [[String: Any]] ?? []

        var moved = listed.removeFirst()
        moved["kind"] = "link"
        pins.append(moved)
        raw["tours"] = listed
        raw["linkPins"] = pins
        let data = try JSONSerialization.data(withJSONObject: raw)

        let legacy = try JSONDecoder().decode(Legacy.ToursData.self, from: data)
        XCTAssertEqual(legacy.tours.count, listed.count)

        // This build loses nothing by it.
        let modern = try JSONDecoder().decode(ToursData.self, from: data)
        XCTAssertEqual(modern.tours.count, listed.count + pins.count)
    }
}
