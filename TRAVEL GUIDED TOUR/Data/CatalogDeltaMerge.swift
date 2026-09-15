import Foundation

/// Merging a `get_catalog_since` delta into the catalogue already on disk.
///
/// # Why this works on raw JSON and not on `ToursData`
///
/// 🔴 **Decoding to `ToursData` and re-encoding would silently discard every
/// key this build does not model.** `ToursData.encode` writes exactly four
/// keys, and each `Tour` writes exactly the properties `Tour` declares — so a
/// field the server starts sending tomorrow would survive the *fetch* (the
/// decoder ignores unknown keys harmlessly) and then be **deleted from the
/// cache** by the first merge. `ToursData` even says so: *"the cache is written
/// from the raw response bytes, never re-encoded"*. Becoming the first caller
/// to break that rule, in a repo whose recurring failure is a key quietly
/// vanishing (2026-08-19: `places`, `priceTier`, `isPrivate` gone for 14
/// hours), is not a trade worth making for tidier code.
///
/// So the merge treats both sides as opaque dictionaries, replaces whole
/// elements by `id`, and never inspects a field it does not need. A key nobody
/// here has heard of rides along untouched.
///
/// # What it does not preserve
///
/// ⚠️ The server orders `tours` by title. New elements are **appended**, so a
/// long-lived merged cache drifts out of that order. Nothing in the app reads
/// catalogue order — the rails sort by distance, search scans — and any full
/// download resets it. Stated because it is a real difference between a merged
/// cache and a fetched one, not because it is known to matter.
///
/// ⚠️ The merged bytes are re-serialised, so they are not byte-identical to
/// what the server sent (key order and spacing differ). The cache is decoded,
/// never compared, so this is immaterial — but do not build a checksum on it.
enum CatalogDeltaMerge {

    /// The four arrays a delta can carry. Each is an array of objects with an
    /// `id`; anything else is a malformed delta and throws rather than being
    /// guessed at.
    static let sections = ["tours", "linkPins", "makers", "places"]

    struct Result {
        /// Merged catalogue bytes, ready to be cached and decoded.
        let data: Data
        /// The cursor the server reported. Store this **only** once the merged
        /// bytes have been decoded successfully.
        let rev: Int64
        /// The snapshot timestamp the delta was built from, if the server sent
        /// one. Used as the cache's catalog-version token so both sidecars
        /// describe the same instant.
        let refreshedAt: String?
        /// How many elements the delta actually changed, across all sections.
        /// Zero is normal and means the delta was empty.
        let applied: Int
        /// How many elements `removedIds` took out.
        let removed: Int
    }

    enum Failure: Error, Equatable {
        case cachedNotAnObject
        case deltaNotAnObject
        case missingRev
        case sectionNotAnArray(String)
        case elementWithoutID(String)
        case couldNotSerialise
    }

    /// Applies `delta` to `cached`, returning new catalogue bytes.
    ///
    /// Pure: no I/O, no clock, no globals. Every failure is thrown rather than
    /// papered over, because the caller's rule is *any doubt → full download* —
    /// a merge that guesses is worse than one that gives up.
    static func merge(cached: Data, delta: Data) throws -> Result {
        guard let base = try? JSONSerialization.jsonObject(with: cached) as? [String: Any] else {
            throw Failure.cachedNotAnObject
        }
        guard let patch = try? JSONSerialization.jsonObject(with: delta) as? [String: Any] else {
            throw Failure.deltaNotAnObject
        }
        // `rev` is the whole point of the exchange. A delta without one cannot
        // advance the cursor, so there is nothing safe to do with it.
        guard let rev = intValue(patch["rev"]) else { throw Failure.missingRev }

        let removedIDs = Set((patch["removedIds"] as? [Any] ?? [])
            .compactMap { ($0 as? String)?.lowercased() })

        var merged = base
        var applied = 0
        var removed = 0

        for section in sections {
            let incoming = try elements(patch[section], section: section)
            let existing = try elements(base[section], section: section)

            // Nothing to do for this section, and — importantly — do not
            // *create* it. A catalogue with no `linkPins` key predates the
            // split, and writing an empty array into it would change its shape
            // for no reason.
            if incoming.isEmpty && removedIDs.isEmpty { continue }
            if existing.isEmpty && incoming.isEmpty { continue }

            var result = existing
            var indexByID: [String: Int] = [:]
            for (i, element) in result.enumerated() {
                guard let id = identifier(of: element) else {
                    throw Failure.elementWithoutID(section)
                }
                indexByID[id] = i
            }

            for element in incoming {
                guard let id = identifier(of: element) else {
                    throw Failure.elementWithoutID(section)
                }
                if let at = indexByID[id] {
                    result[at] = element          // replace in place, keeping order
                } else {
                    indexByID[id] = result.count  // new row, appended
                    result.append(element)
                }
                applied += 1
            }

            if !removedIDs.isEmpty {
                let before = result.count
                result = result.filter { element in
                    guard let id = identifier(of: element) else { return true }
                    return !removedIDs.contains(id)
                }
                removed += before - result.count
            }

            merged[section] = result
        }

        guard let data = try? JSONSerialization.data(withJSONObject: merged) else {
            throw Failure.couldNotSerialise
        }
        return Result(data: data,
                      rev: rev,
                      refreshedAt: patch["refreshedAt"] as? String,
                      applied: applied,
                      removed: removed)
    }

    // MARK: - Pieces

    /// ⚠️ Ids are compared lowercased throughout. CLAUDE.md records that pin ids
    /// are UPPERCASE in `Tours.json` and lowercase out of Postgres, and that a
    /// naive comparison "reports every pin as missing". Here that would not
    /// error — it would append a duplicate of every pin on every merge, growing
    /// the cache silently until something else noticed.
    private static func identifier(of element: [String: Any]) -> String? {
        (element["id"] as? String)?.lowercased()
    }

    /// A section is an array of objects, absent, or null. Anything else is a
    /// malformed payload: throw instead of treating it as empty, which would
    /// quietly merge nothing and report success.
    private static func elements(_ value: Any?, section: String) throws -> [[String: Any]] {
        guard let value, !(value is NSNull) else { return [] }
        guard let array = value as? [Any] else { throw Failure.sectionNotAnArray(section) }
        guard let objects = array as? [[String: Any]] else {
            throw Failure.sectionNotAnArray(section)
        }
        return objects
    }

    /// JSON numbers arrive as `NSNumber`; a server that ever renders `rev` as a
    /// string should still be understood rather than rejected.
    private static func intValue(_ value: Any?) -> Int64? {
        if let n = value as? NSNumber { return n.int64Value }
        if let s = value as? String { return Int64(s) }
        return nil
    }
}
