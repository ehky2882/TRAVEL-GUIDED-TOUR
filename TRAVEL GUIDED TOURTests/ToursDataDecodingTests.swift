import XCTest
@testable import TRAVEL_GUIDED_TOUR

final class ToursDataDecodingTests: XCTestCase {

    // MARK: - Happy path

    func test_decodesMinimalValidPayload() throws {
        let json = Data(#"""
        {
          "makers": [
            {
              "id": "11111111-1111-1111-1111-111111111111",
              "displayName": "Test Maker",
              "avatarURL": null,
              "bio": "Test bio",
              "websiteURL": null
            }
          ],
          "tours": [
            {
              "id": "22222222-2222-2222-2222-222222222222",
              "title": "Test Tour",
              "shortDescription": "Short",
              "longDescription": "Long",
              "makerId": "11111111-1111-1111-1111-111111111111",
              "heroImageURL": "https://example.test/hero.jpg",
              "kind": "single",
              "stops": [
                {
                  "id": "33333333-3333-3333-3333-333333333333",
                  "order": 0,
                  "title": "Stop",
                  "caption": null,
                  "latitude": 40.7,
                  "longitude": -74.0,
                  "audioURL": "https://example.test/audio.mp3",
                  "audioDurationSeconds": 120,
                  "triggerMode": "manual",
                  "triggerRadiusMeters": 30,
                  "imageURL": null,
                  "transcriptText": null
                }
              ],
              "introAudioURL": null,
              "totalDurationSeconds": 120,
              "walkingDistanceMeters": null,
              "centroidLatitude": 40.7,
              "centroidLongitude": -74.0,
              "city": null,
              "primaryCategory": "architecture",
              "tags": [],
              "priceUSD": 0
            }
          ]
        }
        """#.utf8)

        let decoded = try JSONDecoder().decode(ToursData.self, from: json)
        XCTAssertEqual(decoded.makers.count, 1)
        XCTAssertEqual(decoded.tours.count, 1)
        XCTAssertEqual(decoded.tours.first?.title, "Test Tour")
        XCTAssertEqual(decoded.tours.first?.kind, .single)
        XCTAssertEqual(decoded.tours.first?.stops.first?.triggerMode, .manual)
        // additionalImageURLs is optional; missing field decodes as nil.
        XCTAssertNil(decoded.tours.first?.additionalImageURLs)
    }

    func test_decodesAdditionalImageURLs_whenPresent() throws {
        let json = Data(#"""
        {
          "id": "22222222-2222-2222-2222-222222222222",
          "title": "Carousel Tour",
          "shortDescription": "Short",
          "longDescription": "Long",
          "makerId": "11111111-1111-1111-1111-111111111111",
          "heroImageURL": "https://example.test/hero.jpg",
          "additionalImageURLs": [
            "https://example.test/2.jpg",
            "https://example.test/3.jpg"
          ],
          "kind": "single",
          "stops": [
            {
              "id": "33333333-3333-3333-3333-333333333333",
              "order": 0,
              "title": "Stop",
              "caption": null,
              "latitude": 40.7,
              "longitude": -74.0,
              "audioURL": "https://example.test/audio.mp3",
              "audioDurationSeconds": 120,
              "triggerMode": "manual",
              "triggerRadiusMeters": 30,
              "imageURL": null,
              "transcriptText": null
            }
          ],
          "introAudioURL": null,
          "totalDurationSeconds": 120,
          "walkingDistanceMeters": null,
          "centroidLatitude": 40.7,
          "centroidLongitude": -74.0,
          "city": null,
          "primaryCategory": "architecture",
          "tags": [],
          "priceUSD": 0
        }
        """#.utf8)

        let tour = try JSONDecoder().decode(Tour.self, from: json)
        XCTAssertEqual(tour.additionalImageURLs?.count, 2)
        XCTAssertEqual(tour.additionalImageURLs?.first, "https://example.test/2.jpg")
        // videoURLs is optional; a catalog without the key decodes as nil.
        XCTAssertNil(tour.videoURLs)
    }

    func test_decodesVideoURLs_whenPresent() throws {
        let json = Data(#"""
        {
          "id": "44444444-4444-4444-4444-444444444444",
          "title": "Video Tour",
          "shortDescription": "Short",
          "longDescription": "Long",
          "makerId": "11111111-1111-1111-1111-111111111111",
          "heroImageURL": "https://example.test/hero.jpg",
          "additionalImageURLs": ["https://example.test/2.jpg"],
          "videoURLs": [
            "https://example.test/clip-1.mp4",
            "https://example.test/clip-2.mp4"
          ],
          "kind": "single",
          "stops": [
            {
              "id": "55555555-5555-5555-5555-555555555555",
              "order": 0,
              "title": "Stop",
              "caption": null,
              "latitude": 40.7,
              "longitude": -74.0,
              "audioURL": "https://example.test/audio.mp3",
              "audioDurationSeconds": 120,
              "triggerMode": "manual",
              "triggerRadiusMeters": 30,
              "imageURL": null,
              "transcriptText": null
            }
          ],
          "introAudioURL": null,
          "totalDurationSeconds": 120,
          "walkingDistanceMeters": null,
          "centroidLatitude": 40.7,
          "centroidLongitude": -74.0,
          "city": null,
          "primaryCategory": "architecture",
          "tags": [],
          "priceUSD": 0
        }
        """#.utf8)

        let tour = try JSONDecoder().decode(Tour.self, from: json)
        XCTAssertEqual(tour.videoURLs?.count, 2)
        XCTAssertEqual(tour.videoURLs?.first, "https://example.test/clip-1.mp4")
        // Images are unaffected by the new field.
        XCTAssertEqual(tour.additionalImageURLs?.count, 1)
    }

    func test_decodesEmptyArrays() throws {
        let json = Data(#"{"makers":[],"tours":[]}"#.utf8)
        let decoded = try JSONDecoder().decode(ToursData.self, from: json)
        XCTAssertTrue(decoded.makers.isEmpty)
        XCTAssertTrue(decoded.tours.isEmpty)
    }

    // MARK: - Failure cases

    func test_decodingTour_missingRequiredField_throws() {
        // Missing `title`.
        let json = Data(#"""
        {
          "id": "22222222-2222-2222-2222-222222222222",
          "shortDescription": "Short",
          "longDescription": "Long",
          "makerId": "11111111-1111-1111-1111-111111111111",
          "heroImageURL": "https://example.test/hero.jpg",
          "kind": "single",
          "stops": [],
          "totalDurationSeconds": 120,
          "centroidLatitude": 40.7,
          "centroidLongitude": -74.0,
          "primaryCategory": "architecture",
          "tags": [],
          "priceUSD": 0
        }
        """#.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(Tour.self, from: json))
    }

    /// 🔴 **`kind` IS THE ONE THAT STILL THROWS, ON PURPOSE.** Its three
    /// neighbours — `triggerMode`, `primaryCategory`, `videoRole` — all fall
    /// back to a safe default now. `kind` must not: a tour type this build has
    /// never heard of, rendered as `.single`, gets a play button with no audio
    /// behind it, and a control that lies is worse than a pin that is absent.
    ///
    /// The tour is not lost noisily either — the element-wise decode in
    /// `ToursData` drops that one tour and counts it, which is the whole reason
    /// this strictness is affordable. See `CatalogDecodeToleranceTests`.
    func test_decodingTour_badKind_throws() {
        // `kind` is a closed enum; "tripleStop" isn't one of the cases.
        let json = Data(#"""
        {
          "id": "22222222-2222-2222-2222-222222222222",
          "title": "Test",
          "shortDescription": "Short",
          "longDescription": "Long",
          "makerId": "11111111-1111-1111-1111-111111111111",
          "heroImageURL": "https://example.test/hero.jpg",
          "kind": "tripleStop",
          "stops": [],
          "totalDurationSeconds": 120,
          "centroidLatitude": 40.7,
          "centroidLongitude": -74.0,
          "primaryCategory": "architecture",
          "tags": [],
          "priceUSD": 0
        }
        """#.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(Tour.self, from: json))
    }

    /// ⚠️ **CONTRACT DELIBERATELY CHANGED — this test used to be
    /// `test_decodingStop_badTriggerMode_throws`.**
    ///
    /// Throwing here was the old, strict contract, and it is what made the
    /// catalogue brittle: an unfamiliar `triggerMode` failed the stop, which
    /// failed its tour, which failed the whole `[Tour]` array, which
    /// `RemoteCatalogLoader`'s `try?` turned into a silent "no new content".
    /// `StopTriggerMode` now decodes an unfamiliar value to `.manual`, which is
    /// safe by construction — `ProximityMonitor` registers regions only for
    /// `.geofenced` stops, so a mode we do not understand can never produce a
    /// geofence that fires on its own.
    ///
    /// The strict case is not gone, it moved: `test_decodingTour_badKind_throws`
    /// above still holds, because `TourKind` deliberately has no fallback.
    func test_decodingStop_unknownTriggerMode_fallsBackToManual() throws {
        let json = Data(#"""
        {
          "id": "33333333-3333-3333-3333-333333333333",
          "order": 0,
          "title": "Stop",
          "latitude": 40.7,
          "longitude": -74.0,
          "audioURL": "https://example.test/audio.mp3",
          "audioDurationSeconds": 120,
          "triggerMode": "auto",
          "triggerRadiusMeters": 30
        }
        """#.utf8)
        let stop = try JSONDecoder().decode(Stop.self, from: json)
        XCTAssertEqual(stop.triggerMode, .manual)
        // Everything else about the stop survives — the point is that one
        // unfamiliar word costs nothing, not that the stop is degraded.
        XCTAssertEqual(stop.triggerRadiusMeters, 30)
        XCTAssertEqual(stop.audioDurationSeconds, 120)
    }

    // MARK: - Round trip

    func test_encodeDecode_preservesShape() throws {
        let original = ToursData(
            makers: [TestFixtures.makeMaker()],
            tours: [TestFixtures.makeTour(stopCount: 2)]
        )
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ToursData.self, from: encoded)
        XCTAssertEqual(decoded.makers.count, original.makers.count)
        XCTAssertEqual(decoded.tours.count, original.tours.count)
        XCTAssertEqual(decoded.tours.first?.id, original.tours.first?.id)
        XCTAssertEqual(decoded.tours.first?.stops.count, 2)
    }
}
