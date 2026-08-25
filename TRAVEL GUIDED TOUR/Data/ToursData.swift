import Foundation

/// The catalog as it arrives on the wire, from any of the four sources that
/// serve it — the Supabase `get_catalog` RPC, the gh-pages mirror, the on-disk
/// cache, and the bundled offline seed.
///
/// # Why link pins live in their own top-level array
///
/// 🔴 **An unknown top-level KEY is free. An unknown VALUE in a field a build
/// already parses is fatal.** This type uses `Codable` with a fixed key set, so
/// a key it does not know is skipped without a word — that is how `places`
/// reached builds that had never heard of a place, and how `sourceURL`,
/// `sourceAuthor`, `country`, `videoURLs` and `videoRole` all reached shipped
/// builds without breaking one of them.
///
/// `kind` is the opposite case. It is a closed `String` enum, so the moment
/// `kind: "link"` appeared *inside* `tours`, every build that predates
/// `TourKind.link` threw on that one element — and because `[Tour]` decodes as
/// a single array, one unreadable tour failed the WHOLE catalog. The loader's
/// `try?` turned that into `nil`, which it reads as a failed fetch, so it kept
/// its last good copy and logged nothing. No crash; the phone just stopped
/// receiving all new content, silently.
///
/// So a link pin travels under **`linkPins`**, a sibling of `tours`:
///
/// - **Every build shipped before this change** reads `tours`, finds only words
///   it knows, decodes happily, and ignores `linkPins`. It keeps receiving every
///   city and every correction, permanently. This is the only change that can
///   rescue a build that is already in review or on a phone.
/// - **This build and later** decode `linkPins` here and merge them into
///   `tours`, so the map, rails, search, library and the place page never learn
///   that the split exists.
/// - **The next new kind** gets its own section the same way, and no shipped
///   version notices.
///
/// ⚠️ The same shape has to hold in all four places that serve a catalog, or
/// the fallback chain reintroduces the bug the first time the source above it
/// is unreachable: `Resources/Tours.json` (the bundled seed, which
/// `publish-catalog.yml` copies byte-for-byte to the gh-pages mirror),
/// `backend/seed_from_toursjson.py`, and `get_catalog`
/// (`backend/split_link_pins.sql`).
struct ToursData: Codable {
    let makers: [Maker]

    /// Every tour the app shows — the wire's `tours` array **plus** its
    /// `linkPins`, merged during decode. Nothing downstream distinguishes them;
    /// a link pin is a `Tour` whose `kind` is `.link`.
    let tours: [Tour]

    /// Sites that more than one tour describes. **Optional on purpose** — an
    /// older catalog (the on-disk cache written by a previous build, or the
    /// gh-pages mirror before it republishes) carries no `places` key, and must
    /// still decode rather than dropping the whole catalog on the floor.
    let places: [Place]?

    /// Written out rather than synthesized so `places` can default to nil for
    /// callers that predate the place layer. A `let` carrying an initial value
    /// would be skipped by the synthesized decoder entirely — the property
    /// would silently never decode — so the default belongs here, not on the
    /// declaration.
    init(makers: [Maker], tours: [Tour], places: [Place]? = nil) {
        self.makers = makers
        self.tours = tours
        self.places = places
    }

    private enum CodingKeys: String, CodingKey {
        case makers, tours, places, linkPins
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        makers = try container.decode([Maker].self, forKey: .makers)
        places = try container.decodeIfPresent([Place].self, forKey: .places)

        // `linkPins` is absent from every catalog published before this change,
        // and stays absent whenever there are no pins — hence
        // `decodeIfPresent`, exactly as `places` is handled.
        let listed = try container.decode([Tour].self, forKey: .tours)
        let pins = try container.decodeIfPresent([Tour].self, forKey: .linkPins) ?? []
        tours = listed + pins
    }

    /// Splits the pins back out, so a re-encoded catalog carries the same wire
    /// shape it was decoded from. Only tests encode this type today — the cache
    /// is written from the raw response bytes, never re-encoded — but a
    /// round-trip that silently moved link pins back into `tours` would be a
    /// trap sitting there waiting for the first caller who does.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(makers, forKey: .makers)
        try container.encode(tours.filter { $0.kind != .link }, forKey: .tours)
        try container.encodeIfPresent(places, forKey: .places)

        let pins = tours.filter { $0.kind == .link }
        if !pins.isEmpty {
            try container.encode(pins, forKey: .linkPins)
        }
    }
}
