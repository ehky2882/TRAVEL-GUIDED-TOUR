import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// The seatbelt for the next time a value this build has never seen reaches the
/// live catalogue.
///
/// Two layers, tested separately because they fail differently:
///
/// - **Layer 1, per-field tolerance.** `triggerMode`, `videoRole` and
///   `primaryCategory` decode an unfamiliar value to a safe default instead of
///   throwing. `kind` deliberately does not — see the last section.
/// - **Layer 2, the tolerant array.** Every array in `ToursData` decodes
///   element by element, so one unreadable element costs that element and not
///   the catalogue. This is the real protection: it covers every field nobody
///   thought to guard, including ones added years from now.
final class CatalogDecodeToleranceTests: XCTestCase {

    // MARK: - Fixtures

    /// A tour with whatever overrides a test needs, written as JSON rather than
    /// built from the model — the point is what the *decoder* does with bytes.
    private func tourJSON(_ overrides: [String: String] = [:],
                          stopOverrides: [String: String] = [:],
                          id: String = "22222222-2222-2222-2222-222222222222",
                          stopId: String = "33333333-3333-3333-3333-333333333333") -> String {
        var tour: [String: String] = [
            "id": "\"\(id)\"",
            "title": "\"Test Tour\"",
            "shortDescription": "\"Short\"",
            "longDescription": "\"Long\"",
            "makerId": "\"11111111-1111-1111-1111-111111111111\"",
            "heroImageURL": "\"https://example.test/hero.jpg\"",
            "kind": "\"single\"",
            "introAudioURL": "null",
            "totalDurationSeconds": "120",
            "centroidLatitude": "40.7",
            "centroidLongitude": "-74.0",
            "primaryCategory": "\"architecture\"",
            "tags": "[]",
            "priceUSD": "0",
        ]
        var stop: [String: String] = [
            "id": "\"\(stopId)\"",
            "order": "0",
            "title": "\"Stop\"",
            "latitude": "40.7",
            "longitude": "-74.0",
            "audioURL": "\"https://example.test/audio.mp3\"",
            "audioDurationSeconds": "120",
            "triggerMode": "\"manual\"",
            "triggerRadiusMeters": "30",
        ]
        stop.merge(stopOverrides) { _, new in new }
        tour.merge(overrides) { _, new in new }
        let stopBody = stop.map { "\"\($0.key)\": \($0.value)" }.joined(separator: ",")
        tour["stops"] = "[{\(stopBody)}]"
        let body = tour.map { "\"\($0.key)\": \($0.value)" }.joined(separator: ",")
        return "{\(body)}"
    }

    private func makerJSON(id: String = "11111111-1111-1111-1111-111111111111") -> String {
        """
        {"id": "\(id)", "displayName": "Test Maker", "bio": "Test bio"}
        """
    }

    private func catalogJSON(tours: [String], linkPins: [String]? = nil, makers: [String]? = nil) -> Data {
        var body = "\"makers\": [\((makers ?? [makerJSON()]).joined(separator: ","))]," +
                   "\"tours\": [\(tours.joined(separator: ","))]"
        if let linkPins {
            body += ",\"linkPins\": [\(linkPins.joined(separator: ","))]"
        }
        return Data("{\(body)}".utf8)
    }

    // MARK: - Layer 1: per-field tolerance

    func test_unknownTriggerMode_becomesManual_soItCanNeverAutoFire() throws {
        let json = Data(tourJSON(stopOverrides: ["triggerMode": "\"whenTheMoonIsFull\""]).utf8)
        let tour = try JSONDecoder().decode(Tour.self, from: json)

        // `.manual` and not `.geofenced` is the load-bearing half:
        // `ProximityMonitor` registers regions only for `.geofenced` stops, so a
        // rule we did not understand cannot produce a geofence that fires by
        // itself. The user has to press play — visible, and harmless.
        XCTAssertEqual(tour.stops.first?.triggerMode, .manual)
    }

    func test_unknownPrimaryCategory_becomesTheNeutralShelf_andTheTourSurvives() throws {
        let json = Data(tourJSON(["primaryCategory": "\"astrophotography\""]).utf8)
        let tour = try JSONDecoder().decode(Tour.self, from: json)

        XCTAssertEqual(tour.primaryCategory, .culturalHeritage)
        // Only its shelf was ever in doubt. Everything that makes it a tour is
        // understood perfectly well.
        XCTAssertEqual(tour.title, "Test Tour")
        XCTAssertEqual(tour.stops.count, 1)
    }

    func test_unknownVideoRole_becomesGallery_soAClipCanNeverSeizeTheTour() throws {
        let json = Data(tourJSON(["videoRole": "\"interactive\""]).utf8)
        let tour = try JSONDecoder().decode(Tour.self, from: json)

        // `.gallery` is b-roll: it plays on its own and hands the narration
        // back. `.narration` would let a value we did not understand take over
        // the play bar.
        XCTAssertEqual(tour.videoRole, .gallery)
    }

    // MARK: - 🔴 Optional does NOT protect a field

    /// **The thing a future reader will get wrong.**
    ///
    /// It is tempting to read `let videoRole: TourVideoRole?` and conclude that
    /// a bad value there is survivable because the property is optional. It is
    /// not. Synthesised `decodeIfPresent` returns nil for an **absent** key and
    /// for an explicit **null** — but when the key is PRESENT with a value the
    /// enum does not recognise it delegates to the enum's initialiser and
    /// **propagates whatever that throws**.
    ///
    /// So an optional closed enum is exactly as fragile as a non-optional one.
    /// This pins the underlying behaviour with a strict control enum, so the
    /// point survives even if every enum on the model later gains a fallback.
    private enum StrictControl: String, Codable { case known }
    private struct OptionalBox: Codable { let value: StrictControl? }

    func test_optionalIsNotProtection_absentAndNullAreNil_butAnUnknownValueThrows() throws {
        // Absent → nil. Fine.
        XCTAssertNil(try JSONDecoder().decode(OptionalBox.self, from: Data(#"{}"#.utf8)).value)

        // Explicit null → nil. Also fine.
        XCTAssertNil(try JSONDecoder().decode(OptionalBox.self, from: Data(#"{"value":null}"#.utf8)).value)

        // Present with an unfamiliar value → THROWS. This is the case that
        // "it's optional, so it's safe" gets wrong, and it is why `videoRole`
        // needed an explicit fallback rather than inheriting safety from `?`.
        XCTAssertThrowsError(
            try JSONDecoder().decode(OptionalBox.self, from: Data(#"{"value":"brandNew"}"#.utf8))
        )
    }

    func test_videoRole_survivesBecauseOfItsFallback_notBecauseItIsOptional() throws {
        // Proof that the fallback is doing the work: an unfamiliar value comes
        // back as `.gallery`, not as nil. Nil would be what "optional absorbed
        // it" looks like — and that is not what happens.
        let unknown = try JSONDecoder().decode(Tour.self, from: Data(tourJSON(["videoRole": "\"interactive\""]).utf8))
        XCTAssertEqual(unknown.videoRole, .gallery)
        XCTAssertNotNil(unknown.videoRole)

        // …while a genuinely absent key still means "not stated".
        let absent = try JSONDecoder().decode(Tour.self, from: Data(tourJSON().utf8))
        XCTAssertNil(absent.videoRole)
    }

    // MARK: - Layer 2: one unreadable element costs that element

    func test_oneUnreadableTour_costsThatTourAndNotTheCatalogue() throws {
        let good = tourJSON(id: "22222222-2222-2222-2222-222222222222",
                            stopId: "33333333-3333-3333-3333-333333333333")
        // Not an unknown enum value — a structurally broken tour, missing a
        // required field. That is the class no per-field default can cover, and
        // the reason layer 2 exists.
        let broken = #"{"id":"44444444-4444-4444-4444-444444444444","kind":"single"}"#
        let alsoGood = tourJSON(id: "55555555-5555-5555-5555-555555555555",
                                stopId: "66666666-6666-6666-6666-666666666666")

        let data = catalogJSON(tours: [good, broken, alsoGood])
        let catalog = try JSONDecoder().decode(ToursData.self, from: data)

        XCTAssertEqual(catalog.tours.count, 2, "the two readable tours must survive")
        XCTAssertEqual(catalog.makers.count, 1)
        XCTAssertEqual(catalog.losses.tours, 1)
    }

    func test_aTourWithAnUnknownKind_isDropped_neverRenderedAsAnOrdinaryTour() throws {
        let good = tourJSON()
        let futureKind = tourJSON(["kind": "\"somethingWeHaveNotInventedYet\""],
                                  id: "44444444-4444-4444-4444-444444444444",
                                  stopId: "77777777-7777-7777-7777-777777777777")

        let catalog = try JSONDecoder().decode(ToursData.self, from: catalogJSON(tours: [good, futureKind]))

        // 🔴 The owner's judgement call, pinned. A pin of an unfamiliar kind
        // shown as `.single` would carry a play button and no audio. Dropping
        // it costs one tour; falling back would cost trust in every control.
        XCTAssertEqual(catalog.tours.count, 1)
        XCTAssertEqual(catalog.tours.first?.kind, .single)
        XCTAssertEqual(catalog.losses.tours, 1)
    }

    func test_makersAndPlacesAreTolerantToo() throws {
        let brokenMaker = #"{"id":"99999999-9999-9999-9999-999999999999"}"#   // no displayName
        let data = catalogJSON(tours: [tourJSON()], makers: [makerJSON(), brokenMaker])

        let catalog = try JSONDecoder().decode(ToursData.self, from: data)
        XCTAssertEqual(catalog.makers.count, 1)
        XCTAssertEqual(catalog.losses.makers, 1)
        XCTAssertEqual(catalog.tours.count, 1, "a bad maker must not take the tours with it")
    }

    func test_anUnreadableLinkPin_costsOnlyThatPin() throws {
        let brokenPin = #"{"id":"88888888-8888-8888-8888-888888888888","kind":"link"}"#
        let data = catalogJSON(tours: [tourJSON()], linkPins: [brokenPin])

        let catalog = try JSONDecoder().decode(ToursData.self, from: data)
        XCTAssertEqual(catalog.tours.count, 1)
        XCTAssertEqual(catalog.losses.linkPins, 1)
        XCTAssertEqual(catalog.losses.tours, 0, "the loss must be attributed to the array it came from")
    }

    // MARK: - Drops are counted, never swallowed

    func test_aCleanCatalogueReportsNoLosses() throws {
        let catalog = try JSONDecoder().decode(ToursData.self, from: catalogJSON(tours: [tourJSON()]))
        XCTAssertTrue(catalog.losses.isEmpty)
        XCTAssertEqual(catalog.losses.total, 0)
    }

    /// ⚠️ A drop nobody can see is how a catalogue quietly loses content for
    /// months. `RemoteCatalogLoader` logs a non-zero total; this pins that the
    /// number reaching it is real and attributed.
    func test_lossesAreCountedPerArray_soAFutureSessionCanSeeWhatHappened() throws {
        let brokenTour = #"{"id":"44444444-4444-4444-4444-444444444444"}"#
        let brokenPin = #"{"id":"88888888-8888-8888-8888-888888888888"}"#
        let brokenMaker = #"{"id":"99999999-9999-9999-9999-999999999999"}"#
        let data = catalogJSON(tours: [tourJSON(), brokenTour],
                               linkPins: [brokenPin],
                               makers: [makerJSON(), brokenMaker])

        let catalog = try JSONDecoder().decode(ToursData.self, from: data)
        XCTAssertEqual(catalog.losses, CatalogDecodeLosses(makers: 1, tours: 1, linkPins: 1, places: 0))
        XCTAssertEqual(catalog.losses.total, 3)
        XCTAssertFalse(catalog.losses.isEmpty)
    }

    // MARK: - What tolerance must NOT do

    /// A catalogue that is broken *as a whole* must still fail, so the loader
    /// keeps saying "this source is unusable, try the next one". Tolerance is
    /// for elements, not for the document.
    func test_aStructurallyBrokenCatalogueStillFails() {
        XCTAssertThrowsError(try JSONDecoder().decode(ToursData.self, from: Data(#"{"makers":[]}"#.utf8)),
                             "a catalog with no `tours` key at all is not a catalog")
        XCTAssertThrowsError(try JSONDecoder().decode(ToursData.self, from: Data(#"{"tours":[]}"#.utf8)),
                             "a catalog with no `makers` key at all is not a catalog")
    }

    /// The `places` key stays optional. An older cached catalogue carries none,
    /// and must still decode — do not "simplify" that away.
    func test_placesRemainsOptional() throws {
        let catalog = try JSONDecoder().decode(ToursData.self, from: catalogJSON(tours: [tourJSON()]))
        XCTAssertNil(catalog.places)
        XCTAssertEqual(catalog.losses.places, 0)
    }
}
