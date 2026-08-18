import Foundation

/// The published policy pages, in one place.
///
/// These live on `dozent.world` rather than being bundled with the app so
/// there is a single canonical copy. Two other systems point at the same
/// pages and must keep agreeing with them: App Store Connect registers the
/// privacy URL for the listing, and Dozent's Stripe platform review cites
/// the acceptable use policy. A bundled copy would be a fourth version to
/// keep in step, and the one nobody would remember to update.
///
/// The site is deployed from `site/` in this repo (Vercel, project
/// `dozent-world`). Changing a path here means changing it there too.
///
/// - Note: Deliberately *not* the `ehky2882.github.io` host. That serves
///   the app's audio and images, and thousands of catalog URLs point at it;
///   it is a content CDN, not the website.
enum AtlasLegalLinks {
    /// Must match the Privacy Policy URL registered in App Store Connect.
    static let privacy = URL(string: "https://dozent.world/privacy/")!

    static let terms = URL(string: "https://dozent.world/terms/")!

    /// Cited in the Stripe platform review as our published content policy.
    static let acceptableUse = URL(string: "https://dozent.world/acceptable-use/")!

    /// Every page above, for tests that check the set stays reachable.
    static let all: [URL] = [privacy, terms, acceptableUse]
}
