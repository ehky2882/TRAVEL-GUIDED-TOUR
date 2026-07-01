import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// Covers the pure URL → `DeepLink` parsing and the outbound share-link
/// builder. No app state — just the routing logic behind Universal Links and
/// the `dozent://` fallback.
final class DeepLinkParsingTests: XCTestCase {

    private let sampleID = UUID(uuidString: "17050c9f-27a2-45e2-9e69-3ae9528c66c9")!

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

    // MARK: - Rejections (must NOT route)

    func test_ignores_oauthCallback() {
        // The Google sign-in callback must never be treated as a tour link.
        let url = URL(string: "dozent://login-callback#access_token=abc")!
        XCTAssertNil(DeepLinkParser.parse(url))
    }

    func test_ignores_customScheme_wrongHost() {
        XCTAssertNil(DeepLinkParser.parse(URL(string: "dozent://maker/17050c9f-27a2-45e2-9e69-3ae9528c66c9")!))
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
}
