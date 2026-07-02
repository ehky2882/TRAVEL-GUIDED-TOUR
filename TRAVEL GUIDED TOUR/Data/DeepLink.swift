import Foundation

/// A resolved incoming deep link. Kept tiny and value-typed so the parsing
/// logic is pure and unit-testable, independent of any app state.
enum DeepLink: Equatable {
    case tour(UUID)
    case maker(UUID)
}

/// Parses incoming URLs — Universal Links (https) and the `dozent://` custom
/// scheme — into a `DeepLink`. Pure and side-effect free; the app layer
/// resolves the id against the catalog and presents it.
///
/// Supported shapes:
///   Tours:
///   - `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/t/?id=<uuid>`  (share link)
///   - `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/t/<uuid>`       (path form)
///   - `dozent://tour/<uuid>` · `dozent://tour?id=<uuid>`             (fallback)
///   Makers:
///   - `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/m/?id=<uuid>`
///   - `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/m/<uuid>`
///   - `dozent://maker/<uuid>` · `dozent://maker?id=<uuid>`
///
/// Everything else returns `nil`. Notably `dozent://login-callback` (Google
/// OAuth) is ignored: it never reaches app URL handling in the first place —
/// `ASWebAuthenticationSession` inside supabase-swift consumes it — and its
/// host isn't `tour`/`maker` anyway.
enum DeepLinkParser {
    /// Web path segment marking a tour share link.
    static let tourPathMarker = "t"
    /// Web path segment marking a maker share link.
    static let makerPathMarker = "m"

    static func parse(_ url: URL) -> DeepLink? {
        guard let scheme = url.scheme?.lowercased() else { return nil }
        switch scheme {
        case "https", "http":
            // Universal Link. Route only the tour (…/t/…) and maker (…/m/…) paths.
            let segments = url.pathComponents
            if segments.contains(tourPathMarker) {
                return id(in: url, marker: tourPathMarker).map(DeepLink.tour)
            }
            if segments.contains(makerPathMarker) {
                return id(in: url, marker: makerPathMarker).map(DeepLink.maker)
            }
            return nil
        case "dozent":
            // Custom-scheme fallback — only the `tour` / `maker` hosts.
            switch url.host?.lowercased() {
            case "tour":  return id(in: url, marker: tourPathMarker).map(DeepLink.tour)
            case "maker": return id(in: url, marker: makerPathMarker).map(DeepLink.maker)
            default:      return nil
            }
        default:
            return nil
        }
    }

    /// Extracts a UUID from the `id` query item, falling back to the last path
    /// component (ignoring the marker segment). `UUID(uuidString:)` is
    /// case-insensitive, so upper- and lower-cased ids both resolve. Returns
    /// `nil` when neither is a valid UUID.
    private static func id(in url: URL, marker: String) -> UUID? {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let idValue = components.queryItems?.first(where: { $0.name == "id" })?.value,
           let uuid = UUID(uuidString: idValue) {
            return uuid
        }
        let segments = url.pathComponents.filter { $0 != "/" && $0 != marker }
        if let last = segments.last, let uuid = UUID(uuidString: last) {
            return uuid
        }
        return nil
    }
}

/// Builds the outward-facing share URLs. The https forms are Universal Links:
/// they open the app when installed, else the web "coming soon" preview.
enum AtlasShareLink {
    /// Root of the project GitHub Pages site that hosts assets + the landing pages.
    static let webBase = URL(string: "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR")!

    /// `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/t/?id=<uuid>`.
    /// The id is lower-cased so the visible link matches the ids in `Tours.json`.
    static func tourURL(id: UUID) -> URL {
        shareURL(marker: DeepLinkParser.tourPathMarker, id: id)
    }

    static func tourURL(for tour: Tour) -> URL {
        tourURL(id: tour.id)
    }

    /// `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/m/?id=<uuid>`.
    static func makerURL(id: UUID) -> URL {
        shareURL(marker: DeepLinkParser.makerPathMarker, id: id)
    }

    static func makerURL(for maker: Maker) -> URL {
        makerURL(id: maker.id)
    }

    private static func shareURL(marker: String, id: UUID) -> URL {
        var components = URLComponents(
            url: webBase.appendingPathComponent("\(marker)/"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [URLQueryItem(name: "id", value: id.uuidString.lowercased())]
        return components.url!
    }
}
