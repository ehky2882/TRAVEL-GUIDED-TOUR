import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// These URLs are not decoration: App Store Connect registers the privacy
/// page for the listing, and Stripe's platform review cites the acceptable
/// use page. A typo here ships a dead link into both.
final class AtlasLegalLinksTests: XCTestCase {

    func test_allLinksUseTheWebsiteHost() {
        for url in AtlasLegalLinks.all {
            XCTAssertEqual(url.host, "dozent.world", "\(url) is not on the website host")
        }
    }

    /// The gh-pages host serves the app's audio and images. Pointing a policy
    /// link at it would mean two copies of the same page drifting apart.
    func test_noLinkPointsAtTheAssetCDN() {
        for url in AtlasLegalLinks.all {
            XCTAssertFalse(url.absoluteString.contains("github.io"), "\(url) points at the asset CDN")
        }
    }

    func test_allLinksAreHTTPS() {
        for url in AtlasLegalLinks.all {
            XCTAssertEqual(url.scheme, "https", "\(url) is not https")
        }
    }

    /// Trailing slashes matter: the site serves directory-style paths, and
    /// the privacy URL has to match what is registered in App Store Connect
    /// character for character.
    ///
    /// Asserted on `absoluteString`, not `path` — Foundation normalises the
    /// trailing slash away from `path`, so it cannot see the difference.
    func test_urlsAreTheExpectedDirectoryPaths() {
        XCTAssertEqual(AtlasLegalLinks.privacy.absoluteString, "https://dozent.world/privacy/")
        XCTAssertEqual(AtlasLegalLinks.terms.absoluteString, "https://dozent.world/terms/")
        XCTAssertEqual(AtlasLegalLinks.acceptableUse.absoluteString, "https://dozent.world/acceptable-use/")
    }

    func test_linksAreDistinct() {
        XCTAssertEqual(Set(AtlasLegalLinks.all.map(\.absoluteString)).count, AtlasLegalLinks.all.count)
    }
}
