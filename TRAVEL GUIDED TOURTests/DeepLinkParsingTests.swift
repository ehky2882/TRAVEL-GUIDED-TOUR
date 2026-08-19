import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// Covers the pure URL → `DeepLink` parsing and the outbound share-link
/// builder. No app state — just the routing logic behind Universal Links and
/// the `dozent://` fallback.
final class DeepLinkParsingTests: XCTestCase {

    private let sampleID = UUID(uuidString: "17050c9f-27a2-45e2-9e69-3ae9528c66c9")!
    private let makerID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private let listID = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
    private let placeID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

    // MARK: - Universal Links (https)

    func test_parses_universalLink_queryForm() {
        let url = URL(string: "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/t/?id=17050c9f-27a2-45e2-9e69-3ae9528c66c9")!
        XCTAssertEqual(DeepLinkParser.parse(url), .tour(sampleID))
    }

    func test_parses_universalLink_pathForm() {
        let url = URL(string: "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/t/17050c9f-27a2-45e2-9e69-3ae9528c66c9")!
        XCTAssertEqual(DeepLinkParser.parse(url), .tour(sampleID))
    }

    func test_parses_universalLink_uppercaseUUID() {
        let url = URL(string: "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/t/?id=17050C9F-27A2-45E2-9E69-3AE9528C66C9")!
        XCTAssertEqual(DeepLinkParser.parse(url), .tour(sampleID))
    }

    // MARK: - Custom scheme (dozent://)

    func test_parses_customScheme_pathForm() {
        let url = URL(string: "dozent://tour/17050c9f-27a2-45e2-9e69-3ae9528c66c9")!
        XCTAssertEqual(DeepLinkParser.parse(url), .tour(sampleID))
    }

    func test_parses_customScheme_queryForm() {
        let url = URL(string: "dozent://tour?id=17050c9f-27a2-45e2-9e69-3ae9528c66c9")!
        XCTAssertEqual(DeepLinkParser.parse(url), .tour(sampleID))
    }

    // MARK: - Maker links

    func test_parses_maker_universalLink_queryForm() {
        let url = URL(string: "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/m/?id=00000000-0000-0000-0000-000000000001")!
        XCTAssertEqual(DeepLinkParser.parse(url), .maker(makerID))
    }

    func test_parses_maker_universalLink_pathForm() {
        let url = URL(string: "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/m/00000000-0000-0000-0000-000000000001")!
        XCTAssertEqual(DeepLinkParser.parse(url), .maker(makerID))
    }

    func test_parses_maker_customScheme() {
        XCTAssertEqual(
            DeepLinkParser.parse(URL(string: "dozent://maker/00000000-0000-0000-0000-000000000001")!),
            .maker(makerID)
        )
        XCTAssertEqual(
            DeepLinkParser.parse(URL(string: "dozent://maker?id=00000000-0000-0000-0000-000000000001")!),
            .maker(makerID)
        )
    }

    // MARK: - List links

    func test_parses_list_universalLink_queryForm() {
        let url = URL(string: "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/l/?id=00000000-0000-0000-0000-000000000003")!
        XCTAssertEqual(DeepLinkParser.parse(url), .list(listID))
    }

    func test_parses_list_universalLink_pathForm() {
        let url = URL(string: "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/l/00000000-0000-0000-0000-000000000003")!
        XCTAssertEqual(DeepLinkParser.parse(url), .list(listID))
    }

    func test_parses_list_customScheme() {
        XCTAssertEqual(
            DeepLinkParser.parse(URL(string: "dozent://list/00000000-0000-0000-0000-000000000003")!),
            .list(listID)
        )
        XCTAssertEqual(
            DeepLinkParser.parse(URL(string: "dozent://list?id=00000000-0000-0000-0000-000000000003")!),
            .list(listID)
        )
    }

    /// The three markers are single letters (`t` / `m` / `l`) and the parser
    /// tests them against whole path components. Pin that: a substring match
    /// would make every link containing an "l" a list link.
    func test_listMarker_doesNotCaptureOtherLinks() {
        XCTAssertEqual(
            DeepLinkParser.parse(AtlasShareLink.tourURL(id: sampleID)),
            .tour(sampleID)
        )
        XCTAssertEqual(
            DeepLinkParser.parse(AtlasShareLink.makerURL(id: makerID)),
            .maker(makerID)
        )
    }

    // MARK: - Rejections (must NOT route)

    func test_ignores_oauthCallback() {
        // The Google sign-in callback must never be treated as a deep link.
        let url = URL(string: "dozent://login-callback#access_token=abc")!
        XCTAssertNil(DeepLinkParser.parse(url))
    }

    func test_ignores_customScheme_wrongHost() {
        XCTAssertNil(DeepLinkParser.parse(URL(string: "dozent://profile/17050c9f-27a2-45e2-9e69-3ae9528c66c9")!))
    }

    func test_ignores_https_nonTourPath() {
        XCTAssertNil(DeepLinkParser.parse(URL(string: "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/index.html")!))
    }

    func test_ignores_tourPath_withInvalidUUID() {
        XCTAssertNil(DeepLinkParser.parse(URL(string: "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/t/?id=not-a-uuid")!))
    }

    func test_ignores_tourPath_missingID() {
        XCTAssertNil(DeepLinkParser.parse(URL(string: "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/t/")!))
    }

    func test_ignores_unrelatedScheme() {
        XCTAssertNil(DeepLinkParser.parse(URL(string: "mailto:hi@example.com")!))
    }

    // MARK: - Share-link builder

    func test_shareURL_hasExpectedShape() {
        let url = AtlasShareLink.tourURL(id: sampleID)
        XCTAssertEqual(
            url.absoluteString,
            "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/t/?id=17050c9f-27a2-45e2-9e69-3ae9528c66c9"
        )
    }

    func test_shareURL_lowercasesUUID() {
        // Visible link should match the lowercase ids used in Tours.json.
        let upper = UUID(uuidString: "17050C9F-27A2-45E2-9E69-3AE9528C66C9")!
        XCTAssertTrue(AtlasShareLink.tourURL(id: upper).absoluteString.contains("17050c9f-27a2-45e2-9e69-3ae9528c66c9"))
    }

    func test_shareURL_roundTripsThroughParser() {
        // A link we generate must parse back to the same tour id.
        let url = AtlasShareLink.tourURL(id: sampleID)
        XCTAssertEqual(DeepLinkParser.parse(url), .tour(sampleID))
    }

    func test_makerShareURL_hasExpectedShape() {
        XCTAssertEqual(
            AtlasShareLink.makerURL(id: makerID).absoluteString,
            "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/m/?id=00000000-0000-0000-0000-000000000001"
        )
    }

    func test_makerShareURL_roundTripsThroughParser() {
        let url = AtlasShareLink.makerURL(id: makerID)
        XCTAssertEqual(DeepLinkParser.parse(url), .maker(makerID))
    }

    func test_listShareURL_hasExpectedShape() {
        XCTAssertEqual(
            AtlasShareLink.listURL(id: listID).absoluteString,
            "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/l/?id=00000000-0000-0000-0000-000000000003"
        )
    }

    func test_listShareURL_roundTripsThroughParser() {
        let url = AtlasShareLink.listURL(id: listID)
        XCTAssertEqual(DeepLinkParser.parse(url), .list(listID))
    }

    // MARK: - Place links

    func test_placeShareURL_hasExpectedShape() {
        XCTAssertEqual(
            AtlasShareLink.placeURL(id: placeID).absoluteString,
            "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/p/?id=00000000-0000-0000-0000-000000000002"
        )
    }

    func test_placeShareURL_roundTripsThroughParser() {
        let url = AtlasShareLink.placeURL(id: placeID)
        XCTAssertEqual(DeepLinkParser.parse(url), .place(placeID))
    }

    func test_parses_placeUniversalLink_pathForm() {
        let url = URL(string: "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/p/00000000-0000-0000-0000-000000000002")!
        XCTAssertEqual(DeepLinkParser.parse(url), .place(placeID))
    }

    func test_parses_placeCustomScheme() {
        let url = URL(string: "dozent://place/00000000-0000-0000-0000-000000000002")!
        XCTAssertEqual(DeepLinkParser.parse(url), .place(placeID))
    }

    /// The three markers are single letters, so a link must route to exactly
    /// one of them. `p` must never be mistaken for a tour or a maker.
    func test_placeLink_doesNotParseAsTourOrMaker() {
        let url = AtlasShareLink.placeURL(id: placeID)
        guard case .place = DeepLinkParser.parse(url) else {
            return XCTFail("place link parsed as something else")
        }
    }

    // MARK: - Group Listen join links (QR codes)

    func test_groupJoinURL_hasExpectedShape() {
        XCTAssertEqual(
            AtlasShareLink.groupJoinURL(code: "K7QP2").absoluteString,
            "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/g/?code=K7QP2"
        )
    }

    func test_groupJoinURL_roundTripsThroughParser() {
        XCTAssertEqual(DeepLinkParser.parse(AtlasShareLink.groupJoinURL(code: "K7QP2")), .group("K7QP2"))
    }

    func test_groupJoinURL_upperCasesCode() {
        XCTAssertEqual(DeepLinkParser.parse(AtlasShareLink.groupJoinURL(code: "k7qp2")), .group("K7QP2"))
    }

    func test_customSchemeGroupLink_parses() {
        XCTAssertEqual(DeepLinkParser.parse(URL(string: "dozent://group?code=K7QP2")!), .group("K7QP2"))
        XCTAssertEqual(DeepLinkParser.parse(URL(string: "dozent://group/K7QP2")!), .group("K7QP2"))
    }

    func test_groupLink_rejectsMalformedCodes() {
        // Wrong length, or characters outside the unambiguous alphabet (O/0/I/1),
        // must not start a session that could never connect.
        XCTAssertNil(DeepLinkParser.parse(URL(string: "dozent://group?code=K7QP")!))
        XCTAssertNil(DeepLinkParser.parse(URL(string: "dozent://group?code=K7QP23")!))
        XCTAssertNil(DeepLinkParser.parse(URL(string: "dozent://group?code=K7QP0")!))
        XCTAssertNil(DeepLinkParser.parse(URL(string: "dozent://group?code=")!))
    }

    // MARK: - Scanned payloads

    func test_scannedPayload_acceptsLinkForm() {
        let link = AtlasShareLink.groupJoinURL(code: "K7QP2").absoluteString
        XCTAssertEqual(DeepLinkParser.groupCode(fromScannedPayload: link), "K7QP2")
    }

    func test_scannedPayload_acceptsBareCode() {
        // A code shared as plain text (or by a future/older QR) still works.
        XCTAssertEqual(DeepLinkParser.groupCode(fromScannedPayload: "k7qp2"), "K7QP2")
        XCTAssertEqual(DeepLinkParser.groupCode(fromScannedPayload: " K7QP2 "), "K7QP2")
    }

    func test_scannedPayload_rejectsUnrelatedQRContent() {
        // Pointing the camera at some other QR code must do nothing.
        XCTAssertNil(DeepLinkParser.groupCode(fromScannedPayload: "https://example.com"))
        XCTAssertNil(DeepLinkParser.groupCode(fromScannedPayload: "hello world"))
        XCTAssertNil(DeepLinkParser.groupCode(fromScannedPayload: ""))
    }

    func test_scannedPayload_rejectsTourLink() {
        // A tour share QR is a valid deep link but not a join code.
        XCTAssertNil(DeepLinkParser.groupCode(fromScannedPayload: AtlasShareLink.tourURL(id: sampleID).absoluteString))
    }
}
