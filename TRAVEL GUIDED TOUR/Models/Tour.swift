import Foundation
import CoreLocation

/// 🔴 **`TourKind` DELIBERATELY HAS NO UNKNOWN-VALUE FALLBACK, and it is the
/// only one of the four closed enums on this model that does not.**
/// `StopTriggerMode`, `TourVideoRole` and `TourCategory` all decode an
/// unfamiliar value to a safe default. `kind` must not, and the reason is not
/// symmetry — it is that **rendering an unfamiliar pin as an ordinary tour is
/// worse than not showing it at all.**
///
/// Look at what already exists: a link pin decoded as `.single` appears with a
/// play button and no audio behind it. Whatever the *next* kind turns out to
/// be, "some tour type this build has never heard of" is not a tour, and
/// dressing it as one produces a control that lies. An unknown `kind` should
/// **drop that one tour** — which the element-wise array decode in `ToursData`
/// now does, at the cost of that tour and nothing else — never fall back to
/// `.single`.
///
/// ⚠️ So if you are here to "tidy up" the inconsistency by giving this enum an
/// `init(from:)` like its neighbours: that is the change this comment exists to
/// stop. Owner's reasoning, not a style choice.
///
/// This is also why the split in `ToursData` matters more than tolerance ever
/// could: a new kind belongs in its own top-level section, where no shipped
/// build has to have an opinion about it.
enum TourKind: String, Codable {
    case single
    case multiStop

    /// A pin that stands for someone else's post — a TikTok, a Short — rather
    /// than narration Atlas hosts. It appears everywhere a tour appears, and
    /// its detail page sends you to the platform instead of playing anything.
    ///
    /// ⚠️ Deliberately a `TourKind` and not a separate model. Map markers,
    /// placecards, rails, search and the library are all keyed to `Tour`, and
    /// this enum is only ever `==`-compared — never exhaustively switched — so
    /// a new case reaches all of them without touching any of it.
    ///
    /// 🔴 A link pin carries exactly ONE stop, `triggerMode == .manual`, with
    /// an EMPTY `audioURL` and a duration of 0 — the same "no audio yet"
    /// representation a fresh maker draft already writes. That is what keeps
    /// it safe by construction: `ProximityMonitor` registers only `.geofenced`
    /// stops so the geofence can never fire, and every reader of `audioURL`
    /// goes through `URL(string:)`, which rejects an empty string. Validator-
    /// enforced in `scripts/validate-tours.swift`.
    case link
}

/// Which app a link pin opens, derived from its own URL rather than stored
/// beside it — one field cannot then contradict the other.
enum LinkSource {
    case tiktok
    case youtube
    case instagram
    case other

    /// What the button says. The post already plays inside Atlas via the
    /// embed, so this is the *secondary* action — going to the platform to
    /// like, comment or follow. Naming the app is the honest warning that the
    /// tap leaves Atlas; a generic "Open" hides it.
    var watchLabel: String {
        switch self {
        case .tiktok: "OPEN IN TIKTOK"
        case .youtube: "OPEN IN YOUTUBE"
        case .instagram: "OPEN IN INSTAGRAM"
        case .other: "OPEN THIS POST"
        }
    }

    /// Shape of the embedded player, so the box matches the post rather than
    /// letterboxing it. TikTok and Reels are vertical by construction;
    /// YouTube's player letterboxes a Short correctly inside 16:9.
    var embedAspectRatio: CGFloat {
        switch self {
        case .tiktok, .instagram: 9.0 / 16.0
        case .youtube, .other: 16.0 / 9.0
        }
    }

    /// 🔴 A YouTube **Short** is 9:16, exactly like a TikTok — so the shape has
    /// to come from the URL, not from the platform alone. Framed in the 16:9
    /// box that suits an ordinary video, a Short's picture fills only
    /// `(9/16)² = 31.6%` of the width; YouTube pads the rest with a blurred,
    /// stretched copy of the frame and clips its own title overlay.
    static func embedAspectRatio(for urlString: String) -> CGFloat {
        let source = from(urlString: urlString)
        if source == .youtube, isYouTubeShort(urlString) { return 9.0 / 16.0 }
        return source.embedAspectRatio
    }

    /// `youtube.com/shorts/{id}` — matched as a whole path component so a video
    /// merely *titled* "shorts" cannot be mistaken for one.
    static func isYouTubeShort(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return url.pathComponents.contains("shorts")
    }

    /// The post's own embeddable player, derived from the share URL.
    ///
    /// 🔴 All three platforms publish a player that needs **no API key, no
    /// registration and no app review** — verified live 2026-08-24, and it is
    /// what lets a post play *inside* Atlas instead of throwing the viewer out
    /// to another app. TikTok's `player/v1/{id}` returned HTTP 200 unauthenticated.
    ///
    /// ⚠️ Derived, never stored beside `sourceURL`, so the two cannot disagree
    /// about which post this pin is.
    ///
    /// ⚠️ Short links (`vm.tiktok.com/…`, `youtu.be` aside) cannot be resolved
    /// here — they need a redirect follow. `scripts/make-link-pin.py` resolves
    /// them at authoring time and stores the canonical URL, so this stays pure.
    static func embedURL(for urlString: String) -> URL? {
        guard let url = URL(string: urlString) else { return nil }
        let parts = url.pathComponents.filter { $0 != "/" }

        switch from(urlString: urlString) {
        case .tiktok:
            // .../@handle/video/{id}
            guard let i = parts.firstIndex(of: "video"), i + 1 < parts.count else { return nil }
            let id = parts[i + 1]
            guard !id.isEmpty, id.allSatisfy(\.isNumber) else { return nil }
            // Chrome kept on: the creator's handle, the sound and the caption
            // are TikTok's own credit, and stripping them to make the pin look
            // native would be passing someone's work off as ours.
            return URL(string: "https://www.tiktok.com/player/v1/\(id)?music_info=1&description=1&rel=0")

        case .youtube:
            let id: String?
            if let v = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "v" })?.value {
                id = v                                   // youtube.com/watch?v=ID
            } else if let i = parts.firstIndex(of: "shorts"), i + 1 < parts.count {
                id = parts[i + 1]                        // youtube.com/shorts/ID
            } else if url.host()?.lowercased().contains("youtu.be") == true {
                id = parts.first                         // youtu.be/ID
            } else {
                id = nil
            }
            guard let id, !id.isEmpty else { return nil }
            return URL(string: "https://www.youtube.com/embed/\(id)?playsinline=1&rel=0")

        case .instagram:
            // instagram.com/p/{code}/ and /reel/{code}/
            guard let i = parts.firstIndex(where: { $0 == "p" || $0 == "reel" || $0 == "tv" }),
                  i + 1 < parts.count else { return nil }
            let code = parts[i + 1]
            guard !code.isEmpty else { return nil }
            return URL(string: "https://www.instagram.com/\(parts[i])/\(code)/embed")

        case .other:
            return nil
        }
    }

    /// Matched on the **registrable domain** — the label immediately before
    /// the TLD — so `www.`, `m.` and regional prefixes all resolve.
    ///
    /// 🔴 NOT a `contains` over the labels. That was the first version and the
    /// authoring tool's self-test caught it within a minute: `tiktok.evil.com`
    /// splits to ["tiktok", "evil", "com"], so a hostile URL would have been
    /// labelled "WATCH ON TIKTOK" while sending the tap somewhere else. Only
    /// the second-to-last label decides.
    static func from(urlString: String) -> LinkSource {
        guard let host = URL(string: urlString)?.host()?.lowercased() else { return .other }
        let labels = host.split(separator: ".").map(String.init)
        guard labels.count >= 2 else { return .other }
        switch labels[labels.count - 2] {
        case "tiktok": return .tiktok
        case "youtube", "youtu": return .youtube
        case "instagram": return .instagram
        default: return .other
        }
    }
}

/// What a tour's video actually IS — the distinction the app could not make
/// before, and the reason a clip and the play bar behaved as two unrelated
/// things (owner, 2026-08-24: *"i agree we need to define different types of
/// videos"*).
///
/// 🔴 Do NOT infer this from the data. The tempting rule — single stop, clip
/// has sound, durations match — breaks `gallery` the first time a piece of
/// b-roll happens to be the length of its narration, and the failure is
/// silent: a moving photograph would seize the tour's transport.
enum TourVideoRole: String, Codable {
    /// The clip is extra: b-roll, a moving photograph beside the still ones.
    /// It plays on its own, and if it has sound it borrows the narration and
    /// hands it straight back. This is every video in the catalogue today,
    /// and the default for anything that does not say otherwise.
    case gallery

    /// The clip IS the tour. Its soundtrack is the narration, so the play bar
    /// and the picture are one thing: play, pause or scrub either and both
    /// move together.
    ///
    /// ⚠️ The AUDIO is the clock and the video is muted, not the other way
    /// round. The tour player already owns the lock screen, background
    /// playback, the geofence hand-off, Group Listen, downloads, playback
    /// progress and the speed control; rebuilding all of that on an
    /// `AVPlayer` fed by a video file would be enormous and would regress
    /// every one of them. Slaving a muted picture to the existing clock costs
    /// almost nothing and keeps them all. It also matches how creator import
    /// is planned to work, which extracts the clip's audio to an MP3 anyway.
    case narration

    /// An unfamiliar role becomes `.gallery` rather than throwing.
    ///
    /// Safe by construction: `.gallery` is b-roll, so the worst a
    /// misunderstood clip can do is sit in the carousel and play on its own. It
    /// never takes over the tour's transport. The opposite default would let a
    /// value we did not understand seize the play bar.
    ///
    /// 🔴 **BEING OPTIONAL DOES NOT PROTECT THIS FIELD — that is the thing a
    /// future reader will get wrong.** `Tour.videoRole` is `TourVideoRole?`,
    /// and synthesised `decodeIfPresent` returns nil for an *absent* key or an
    /// explicit `null`, but for a key that is PRESENT with an unfamiliar value
    /// it delegates to this initialiser and PROPAGATES whatever it throws. So
    /// before this fallback existed, `videoRole` was exactly as fragile as
    /// `kind`, `primaryCategory` and `triggerMode`. Pinned by
    /// `CatalogDecodeToleranceTests`.
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = TourVideoRole(rawValue: raw) ?? .gallery
    }
}

struct Tour: Codable, Identifiable, Hashable {
    let id: UUID
    let title: String
    let shortDescription: String
    let longDescription: String
    let makerId: UUID
    let heroImageURL: String
    let additionalImageURLs: [String]?
    /// Optional gallery videos (hosted as `.mp4` on gh-pages, same
    /// pipeline as images/audio). Rendered as extra swipeable pages at
    /// the end of the tour-detail / player photo carousel, after the
    /// images. `nil` (the common case) or empty → the carousel is
    /// image-only exactly as before. Additive + backward-compatible:
    /// a catalog without this key decodes to `nil`.
    let videoURLs: [String]?
    /// What those videos are — see `TourVideoRole`. Optional, and nil means
    /// `.gallery`: every tour authored before this existed keeps behaving
    /// exactly as it did, and the bundled seed and the gh-pages mirror both
    /// decode fine without the key.
    let videoRole: TourVideoRole?
    let kind: TourKind
    /// For a `.link` tour, the post this pin stands for. Optional because
    /// every other kind has none, and because the bundled seed and the
    /// gh-pages mirror decode fine without the key until republished.
    let sourceURL: String?
    /// The creator being credited, as the platform reports them (e.g.
    /// `"@explaining.architecturee"`). Shown on the detail page — a pin
    /// standing for someone's work names them.
    let sourceAuthor: String?
    let stops: [Stop]
    let introAudioURL: String?
    let totalDurationSeconds: Int
    let walkingDistanceMeters: Int?
    let centroidLatitude: Double
    let centroidLongitude: Double
    let city: String?
    /// The city's country, as authored in the catalog.
    ///
    /// Denormalised onto the tour exactly as `city` is — there is no city
    /// entity to hang it off — so it travels with content and reaches
    /// phones over the air on a catalog merge, with no build. That is the
    /// point of storing it rather than deriving it from `city` in Swift:
    /// a city launch ships as content alone, so a lookup table compiled
    /// into the binary would start understating the moment one landed.
    ///
    /// Optional, and load-bearing: the bundled offline seed and the
    /// gh-pages mirror predate this key until they are republished, and
    /// maker-authored tours (`MakerTourService`) carry no country at all,
    /// so every one of those must keep decoding.
    let country: String?
    let primaryCategory: TourCategory
    let tags: [String]
    let priceUSD: Decimal
    /// The tour's price in **US cents**, or `nil` for free — which is the
    /// entire catalog today. One of the ten App Store tiers created in
    /// Phase 1 (99, 199, 299, 399, 499, 699, 899, 999, 1499, 1999).
    ///
    /// **Not the authority on what was paid.** `paid_tours.sql` CHECK-
    /// constrains the same closed set, and `record-purchase` re-checks the
    /// tier against the receipt server-side before granting anything. This
    /// value drives display + which StoreKit product to buy, nothing more.
    ///
    /// Optional so a catalog without the key (or an older cached copy)
    /// still decodes — absent means free, which is the safe default.
    let priceTier: Int?
    /// Catalog-added date as an ISO `"YYYY-MM-DD"` string — the day this
    /// tour first appeared in `Tours.json` (derived from git history).
    /// Powers the maker page's Newest / Oldest sort. Stored as a String
    /// (not `Date`) so it needs no decoder date-strategy and sorts
    /// chronologically by plain lexicographic compare. **Optional** so
    /// tours added without it (e.g. by a concurrent content session)
    /// still decode — they sort last under Newest/Oldest.
    let createdAt: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: centroidLatitude, longitude: centroidLongitude)
    }

    /// The lightweight primary tag derived from `tags` (owner decision
    /// D5), for one-label spots that will migrate off `primaryCategory`
    /// in Phase 3. `nil` only for a tagless tour. `primaryCategory` is
    /// still the source of truth for map pins + placeholders in Phase 2.
    var primaryTag: String? { Tag.derivePrimary(from: tags) }

    /// True when this pin stands for a post hosted somewhere else.
    var isLink: Bool { kind == .link }

    /// Which app this link pin opens. `nil` for anything that is not a link
    /// pin, or a link pin whose URL is missing — both of which the validator
    /// rejects, so `nil` here means bad data rather than a state to design for.
    var linkSource: LinkSource? {
        guard kind == .link, let sourceURL else { return nil }
        return LinkSource.from(urlString: sourceURL)
    }

    /// The player to embed for this link pin, or `nil` when the URL is one we
    /// cannot derive a player from — in which case the detail page falls back
    /// to sending the viewer to the post instead of showing it inline.
    var linkEmbedURL: URL? {
        guard kind == .link, let sourceURL else { return nil }
        return LinkSource.embedURL(for: sourceURL)
    }

    /// True when this tour must be bought before its audio will play.
    /// A `nil` or non-positive tier means free — the whole catalog today.
    var isPaid: Bool { (priceTier ?? 0) > 0 }

    /// The App Store product id backing this tour's tier, e.g. 299 →
    /// `"tour.tier.299"` and 99 → `"tour.tier.099"`. Zero-padded to **at
    /// least** three digits so it matches the products created by hand in
    /// App Store Connect (`tour.tier.099` … `tour.tier.1999`); four-digit
    /// tiers are already wide enough and pass through unpadded.
    ///
    /// `nil` for a free tour — there is nothing to buy.
    var storeProductId: String? {
        guard let tier = priceTier, tier > 0 else { return nil }
        return "tour.tier." + String(format: "%03d", tier)
    }

    /// Fallback price string (`"$2.99"`) for the rare moment before
    /// StoreKit's localized `displayPrice` is available. **Prefer
    /// `PurchaseService.displayPrice(for:)`** — this one is always USD, so
    /// it would misstate the price to a non-US storefront if it were the
    /// primary source.
    var fallbackPriceText: String? {
        guard let tier = priceTier, tier > 0 else { return nil }
        return String(format: "$%.2f", Double(tier) / 100)
    }

    func distance(from location: CLLocation) -> CLLocationDistance {
        let tourLocation = CLLocation(latitude: centroidLatitude, longitude: centroidLongitude)
        return location.distance(from: tourLocation)
    }
}
