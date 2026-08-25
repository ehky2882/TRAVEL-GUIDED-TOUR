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
///
/// # Why every array here decodes element by element
///
/// The split above fixes one known value. It cannot fix the next one, and it
/// does nothing for a field nobody thought to guard. So `init(from:)` below
/// decodes `makers`, `tours`, `linkPins` and `places` **one element at a
/// time**, keeping what decodes and dropping what does not: one unreadable
/// element costs that element, never the catalog.
///
/// ⚠️ **The drops are counted, not swallowed.** See `CatalogDecodeLosses` at
/// the bottom of this file; `RemoteCatalogLoader` logs a non-zero total with
/// its source named. A drop nobody can see is how a catalog quietly loses
/// content for months.
///
/// ⚠️ Tolerance is for ELEMENTS, not for the document. A payload with no
/// `tours` key at all still throws, because that is how the loader says "this
/// source is unusable, try the next one".
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

    /// What this decode threw away. Not part of the wire format — it describes
    /// the decode, not the catalog.
    let losses: CatalogDecodeLosses

    /// Written out rather than synthesized so `places` can default to nil for
    /// callers that predate the place layer. A `let` carrying an initial value
    /// would be skipped by the synthesized decoder entirely — the property
    /// would silently never decode — so the default belongs here, not on the
    /// declaration.
    init(makers: [Maker],
         tours: [Tour],
         places: [Place]? = nil,
         losses: CatalogDecodeLosses = CatalogDecodeLosses()) {
        self.makers = makers
        self.tours = tours
        self.places = places
        self.losses = losses
    }

    private enum CodingKeys: String, CodingKey {
        case makers, tours, places, linkPins
    }

    /// # Layer 2: one unreadable element costs that element, not the catalog
    ///
    /// 🔴 This is the real protection, and it is deliberately blunt: every
    /// array here decodes **element by element**, keeping what decodes and
    /// dropping what does not. It covers every field nobody thought to guard —
    /// including fields added years from now — where the per-field defaults on
    /// `StopTriggerMode`, `TourVideoRole` and `TourCategory` only cover the four
    /// closed enums we can currently name.
    ///
    /// It is also what makes `TourKind`'s deliberate strictness affordable: an
    /// unfamiliar `kind` drops that one tour, which is the outcome the owner
    /// asked for, rather than rendering it as an ordinary tour with a play
    /// button and no audio behind it.
    ///
    /// ⚠️ The drops are counted, never swallowed. See `CatalogDecodeLosses`.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var losses = CatalogDecodeLosses()

        let decodedMakers = try container.decodeTolerantArray(of: Maker.self, forKey: .makers)
        makers = decodedMakers.elements
        losses.makers = decodedMakers.dropped

        let decodedPlaces = try container.decodeTolerantArrayIfPresent(of: Place.self, forKey: .places)
        places = decodedPlaces.elements
        losses.places = decodedPlaces.dropped

        // `linkPins` is absent from every catalog published before the split,
        // and stays absent whenever there are no pins — hence the
        // if-present form, exactly as `places` is handled.
        let listed = try container.decodeTolerantArray(of: Tour.self, forKey: .tours)
        let pins = try container.decodeTolerantArrayIfPresent(of: Tour.self, forKey: .linkPins)
        losses.tours = listed.dropped
        losses.linkPins = pins.dropped

        tours = listed.elements + (pins.elements ?? [])
        self.losses = losses
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

// MARK: - Tolerant decoding

/// What a tolerant decode threw away, so it can be reported rather than
/// disappearing.
///
/// ⚠️ **A dropped element must stay countable.** The whole point of decoding
/// element by element is that one bad tour costs that tour instead of the
/// catalogue — but a drop that nobody can see is how a catalogue quietly loses
/// content for months. `RemoteCatalogLoader` logs a non-zero total, and this
/// type is what a future session greps for.
struct CatalogDecodeLosses: Equatable {
    var makers = 0
    var tours = 0
    var linkPins = 0
    var places = 0

    var total: Int { makers + tours + linkPins + places }
    var isEmpty: Bool { total == 0 }

    var summary: String {
        "\(makers) maker(s), \(tours) tour(s), \(linkPins) link pin(s), \(places) place(s)"
    }
}

/// Decodes one element without ever throwing, so a bad element cannot fail the
/// array around it.
///
/// 🔴 The obvious version of this — loop an `UnkeyedDecodingContainer` and
/// `try?` each `decode` — is a trap: whether `currentIndex` advances past an
/// element that threw is not guaranteed, so it can spin forever. Wrapping the
/// element in a type whose `init(from:)` *cannot* throw sidesteps that
/// entirely: the array decode always succeeds, and each element is attempted
/// independently.
private struct Tolerated<Wrapped: Decodable>: Decodable {
    let value: Wrapped?

    init(from decoder: Decoder) throws {
        value = try? Wrapped(from: decoder)
    }
}

private extension KeyedDecodingContainer {
    /// Decodes an array element by element, keeping what decodes and reporting
    /// how much was dropped.
    func decodeTolerantArray<Element: Decodable>(
        of _: Element.Type,
        forKey key: Key
    ) throws -> (elements: [Element], dropped: Int) {
        let wrapped = try decode([Tolerated<Element>].self, forKey: key)
        let elements = wrapped.compactMap(\.value)
        return (elements, wrapped.count - elements.count)
    }

    /// The same, for a key that may legitimately be absent.
    func decodeTolerantArrayIfPresent<Element: Decodable>(
        of _: Element.Type,
        forKey key: Key
    ) throws -> (elements: [Element]?, dropped: Int) {
        guard let wrapped = try decodeIfPresent([Tolerated<Element>].self, forKey: key) else {
            return (nil, 0)
        }
        let elements = wrapped.compactMap(\.value)
        return (elements, wrapped.count - elements.count)
    }
}
