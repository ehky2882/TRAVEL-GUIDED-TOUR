import Foundation

/// A resolved incoming deep link. Kept tiny and value-typed so the parsing
/// logic is pure and unit-testable, independent of any app state.
///
/// Today only tour links exist; the enum leaves room for `.maker(UUID)` etc.
enum DeepLink: Equatable {
    case tour(UUID)
}

/// Parses incoming URLs — Universal Links (https) and the `dozent://` custom
/// scheme — into a `DeepLink`. Pure and side-effect free; the app layer
/// resolves the id against the catalog and presents it.
///
/// Supported shapes:
///   - `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/t/?id=<uuid>`  (share link)
///   - `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/t/<uuid>`       (path form)
///   - `dozent://tour/<uuid>`                                        (fallback)
///   - `dozent://tour?id=<uuid>`                                     (fallback)
///
/// Everything else returns `nil`. Notably `dozent://login-callback` (Google
/// OAuth) is ignored: it never reaches app URL handling in the first place —
/// `ASWebAuthenticationSession` inside supabase-swift consumes it — and even
/// if it did, the host isn't `tour`.
enum DeepLinkParser {
    /// The path segment that marks a tour share link on the web host.
    static let tourPathMarker = "t"

    static func parse(_ url: URL) -> DeepLink? {
        guard let scheme = url.scheme?.lowercased() else { return nil }
        switch scheme {
        case "https", "http":
            // Universal Link. Only the tour share path (…/t/…) routes.
            guard url.pathComponents.contains(tourPathMarker) else { return nil }
            return tourId(in: url).map(DeepLink.tour)
        case "dozent":
            // Custom-scheme fallback — only the `tour` host.
            guard url.host?.lowercased() == "tour" else { return nil }
            return tourId(in: url).map(DeepLink.tour)
        default:
            return nil
        }
    }

    /// Extracts a tour UUID from the `id` query item, falling back to the last
    /// path component. `UUID(uuidString:)` is case-insensitive, so upper- and
    /// lower-cased ids both resolve. Returns `nil` when neither is a valid UUID.
    private static func tourId(in url: URL) -> UUID? {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let idValue = components.queryItems?.first(where: { $0.name == "id" })?.value,
           let id = UUID(uuidString: idValue) {
            return id
        }
        let segments = url.pathComponents.filter { $0 != "/" && $0 != tourPathMarker }
        if let last = segments.last, let id = UUID(uuidString: last) {
            return id
        }
        return nil
    }
}

/// Builds the outward-facing share URLs for tours. The https form is a Universal
/// Link: it opens the app when installed, else the web "coming soon" preview.
enum AtlasShareLink {
    /// Root of the project GitHub Pages site that hosts assets + the `t/` page.
    static let webBase = URL(string: "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR")!

    /// `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/t/?id=<uuid>`.
    /// The id is lower-cased so the visible link matches the ids in `Tours.json`.
    static func tourURL(id: UUID) -> URL {
        var components = URLComponents(
            url: webBase.appendingPathComponent("\(DeepLinkParser.tourPathMarker)/"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [URLQueryItem(name: "id", value: id.uuidString.lowercased())]
        return components.url!
    }

    static func tourURL(for tour: Tour) -> URL {
        tourURL(id: tour.id)
    }
}
