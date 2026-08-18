import Foundation

/// A resolved incoming deep link. Kept tiny and value-typed so the parsing
/// logic is pure and unit-testable, independent of any app state.
enum DeepLink: Equatable {
    case tour(UUID)
    case maker(UUID)
    /// A shared list ("playlist"). Only resolvable if the owner has it visible
    /// — RLS returns nothing for an Only-me list, so a link to one opens the
    /// app and finds nothing, which is the correct outcome.
    case list(UUID)
    /// Join a Group Listen session by its short code. Carried by the QR code a
    /// leader shows, so a joiner can scan instead of typing five characters.
    /// No tour id is needed — the leader broadcasts which tour the group is on.
    case group(String)
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
///   Lists:
///   - `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/l/?id=<uuid>`
///   - `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/l/<uuid>`
///   - `dozent://list/<uuid>` · `dozent://list?id=<uuid>`
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
    /// Web path segment marking a shared list.
    static let listPathMarker = "l"
    /// Web path segment marking a Group Listen join link (QR codes).
    static let groupPathMarker = "g"

    static func parse(_ url: URL) -> DeepLink? {
        guard let scheme = url.scheme?.lowercased() else { return nil }
        switch scheme {
        case "https", "http":
            // Universal Link. Route the tour (…/t/…), maker (…/m/…) and Group
            // Listen join (…/g/…) paths.
            let segments = url.pathComponents
            if segments.contains(tourPathMarker) {
                return id(in: url, marker: tourPathMarker).map(DeepLink.tour)
            }
            if segments.contains(makerPathMarker) {
                return id(in: url, marker: makerPathMarker).map(DeepLink.maker)
            }
            if segments.contains(listPathMarker) {
                return id(in: url, marker: listPathMarker).map(DeepLink.list)
            }
            if segments.contains(groupPathMarker) {
                return groupCode(in: url, marker: groupPathMarker).map(DeepLink.group)
            }
            return nil
        case "dozent":
            // Custom-scheme fallback — the `tour` / `maker` / `group` hosts.
            switch url.host?.lowercased() {
            case "tour":  return id(in: url, marker: tourPathMarker).map(DeepLink.tour)
            case "maker": return id(in: url, marker: makerPathMarker).map(DeepLink.maker)
            case "list":  return id(in: url, marker: listPathMarker).map(DeepLink.list)
            case "group": return groupCode(in: url, marker: groupPathMarker).map(DeepLink.group)
            default:      return nil
            }
        default:
            return nil
        }
    }

    /// Extracts a Group Listen join code from the `code` query item, falling back
    /// to the last path component. Normalised to upper case and validated against
    /// the canonical code format, so a malformed or truncated scan is rejected
    /// rather than starting a session that can never connect.
    static func groupCode(in url: URL, marker: String) -> String? {
        let candidate: String? = {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let value = components.queryItems?.first(where: { $0.name == "code" })?.value {
                return value
            }
            return url.pathComponents.filter { $0 != "/" && $0 != marker }.last
        }()
        guard let raw = candidate else { return nil }
        return normalizedGroupCode(raw)
    }

    /// Resolves whatever a QR scan produced into a join code. Accepts both the
    /// link form we generate (`…/g/?code=XXXXX`, `dozent://group?code=XXXXX`) and
    /// a bare code, so a code shared as plain text still works — and so QR codes
    /// produced by older or future builds both scan correctly.
    static func groupCode(fromScannedPayload raw: String) -> String? {
        if let url = URL(string: raw), let link = parse(url), case .group(let code) = link {
            return code
        }
        return normalizedGroupCode(raw)
    }

    /// Upper-cases and validates a scanned/typed join code. Returns nil unless it
    /// is exactly the expected length and drawn entirely from the code alphabet
    /// (which excludes look-alike glyphs). Shared by the QR scanner so both
    /// entry paths agree on what a valid code is.
    static func normalizedGroupCode(_ raw: String) -> String? {
        let upper = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard upper.count == GroupListenCoordinator.codeLength else { return nil }
        let allowed = Set(GroupListenCoordinator.codeAlphabet)
        guard upper.allSatisfy({ allowed.contains($0) }) else { return nil }
        return upper
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

    /// `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/l/?id=<uuid>` — a shared
    /// list. Note the recipient only sees anything if the owner has the list
    /// visible; `TourListDetailView` handles the empty case.
    static func listURL(id: UUID) -> URL {
        shareURL(marker: DeepLinkParser.listPathMarker, id: id)
    }

    static func listURL(for list: TourList) -> URL {
        listURL(id: list.id)
    }

    /// `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/g/?code=K7QP2` — the payload
    /// encoded into a leader's join QR code. Deliberately the https (Universal
    /// Link) form, not `dozent://`: pointed at with the system Camera app it can
    /// open the app directly, and if the app isn't installed it degrades to the
    /// web page instead of a dead custom-scheme prompt.
    static func groupJoinURL(code: String) -> URL {
        var components = URLComponents(
            url: webBase.appendingPathComponent("\(DeepLinkParser.groupPathMarker)/"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [URLQueryItem(name: "code", value: code.uppercased())]
        return components.url!
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
