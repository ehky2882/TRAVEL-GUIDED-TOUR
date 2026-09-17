import Foundation
import os

/// Abstracts the network fetch so the catalog loader can be unit-tested
/// without hitting the network. Production uses `URLSessionCatalogFetcher`;
/// tests inject a stub.
protocol CatalogFetching: Sendable {
    func fetchData(from url: URL) async throws -> Data
}

/// Error surfaced by `URLSessionCatalogFetcher` for a non-2xx response, so the
/// retry policy can tell a transient server-side condition (5xx/408/429) from a
/// clean 4xx that won't fix itself on retry. Transport problems (timeouts,
/// dropped connections, offline) surface as `URLError` directly.
enum CatalogFetchError: Error {
    case httpStatus(Int)
}

/// Controls how `RemoteCatalogLoader.refresh()` retries a failed fetch.
///
/// Attempt *n* waits roughly `baseDelay * 2^(n-1)` seconds plus up to `jitter`
/// seconds of random spread, so the default (3 attempts, 1s base) backs off
/// ~1s / ~2s between the three tries before giving up.
struct CatalogRetryPolicy: Sendable {
    let maxAttempts: Int
    let baseDelay: TimeInterval
    let jitter: TimeInterval

    init(maxAttempts: Int = 3, baseDelay: TimeInterval = 1.0, jitter: TimeInterval = 0.3) {
        self.maxAttempts = max(1, maxAttempts)
        self.baseDelay = max(0, baseDelay)
        self.jitter = max(0, jitter)
    }

    /// Production default: three attempts with ~1s/2s exponential backoff.
    static let `default` = CatalogRetryPolicy()
    /// Single attempt, no waiting — the legacy one-shot behavior; used by tests
    /// that exercise the failure path without paying backoff sleeps.
    static let none = CatalogRetryPolicy(maxAttempts: 1, baseDelay: 0, jitter: 0)
}

struct URLSessionCatalogFetcher: CatalogFetching {
    /// A dedicated session with longer timeouts than the 15s the catalog used
    /// to use — slow-but-working connections were timing out before the small
    /// JSON arrived. `timeoutIntervalForRequest` bounds inactivity between
    /// bytes; `timeoutIntervalForResource` caps the whole transfer.
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        // We manage freshness ourselves via the cache file; never let the
        // URL loading system hand back a stale CDN-pinned copy.
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        self.session = URLSession(configuration: config)
    }

    func fetchData(from url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 30
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw CatalogFetchError.httpStatus(http.statusCode)
        }
        return data
    }
}

/// Fetches the catalog from the Supabase `get_catalog` RPC.
///
/// The RPC is a `POST …/rest/v1/rpc/get_catalog` with an empty `{}` body and the
/// `apikey` + `Authorization: Bearer <anon>` headers; it returns the same
/// `{makers, tours}` JSON document `ToursData` already decodes (camelCase keys
/// matching the Swift `Codable` names). Non-2xx surfaces as
/// `CatalogFetchError.httpStatus` so the retry policy can classify it exactly
/// like the gh-pages path. No third-party SDK — a plain `URLSession` POST is all
/// the read side needs (the supabase-swift SDK arrives with auth in Step 3).
struct SupabaseCatalogFetcher: CatalogFetching {
    private let anonKey: String
    private let session: URLSession

    init(anonKey: String) {
        self.anonKey = anonKey
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        self.session = URLSession(configuration: config)
    }

    func fetchData(from url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data("{}".utf8)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw CatalogFetchError.httpStatus(http.statusCode)
        }
        return data
    }
}

/// Abstracts the cheap "has the catalog changed?" question, so the loader can
/// be unit-tested without hitting the network. Production uses
/// `SupabaseCatalogVersionProbe`; tests inject a stub.
///
/// The returned string is an **opaque token**, never parsed. All the loader
/// does is compare it to the token stored beside the cache.
protocol CatalogVersionProbing: Sendable {
    func fetchVersion() async throws -> String
}

/// Asks Supabase which catalog it is currently serving, in 34 bytes.
///
/// `catalog_snapshot_age()` returns the `refreshed_at` of the single stored
/// snapshot row — the same row `get_catalog()` reads its `payload` from, written
/// by the same upsert. So the token is exactly as fresh as the catalog it
/// describes: it cannot say "unchanged" about content that has changed.
///
/// ⚠️ It *can* be wrong in the harmless direction — a re-seed that changes
/// nothing still moves the timestamp, so the app downloads unnecessarily. That
/// costs one download and breaks nothing. The dangerous direction is
/// structurally unreachable.
struct SupabaseCatalogVersionProbe: CatalogVersionProbing {
    /// A version token is a timestamp string. Anything appreciably larger is not
    /// the answer we asked for — treat it as a failed probe and download.
    private static let maxTokenBytes = 4_096

    private let anonKey: String
    private let url: URL
    private let session: URLSession

    init(anonKey: String, url: URL = SupabaseConfig.catalogVersionRPCURL) {
        self.anonKey = anonKey
        self.url = url
        let config = URLSessionConfiguration.ephemeral
        // Short timeouts on purpose: this probe exists to SAVE time and bytes.
        // If it is slow, skipping it and downloading is the better trade.
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 15
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        self.session = URLSession(configuration: config)
    }

    func fetchVersion() async throws -> String {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 10
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data("{}".utf8)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw CatalogFetchError.httpStatus(http.statusCode)
        }
        guard data.count <= Self.maxTokenBytes,
              let token = String(data: data, encoding: .utf8)?
                  .trimmingCharacters(in: .whitespacesAndNewlines),
              !token.isEmpty,
              token != "null" else {
            // An empty snapshot row, or anything we did not expect. Say "no
            // answer" rather than inventing a token — the loader then downloads.
            throw URLError(.cannotParseResponse)
        }
        return token
    }
}

/// Fetches only the catalogue rows newer than a cursor the client already
/// holds. Separate from `CatalogFetching` because it takes an argument and
/// because a source may offer one without the other — the gh-pages mirror
/// offers neither a probe nor a delta.
protocol CatalogDeltaFetching: Sendable {
    func fetchDelta(since rev: Int64) async throws -> Data
}

/// `get_catalog_since(client_rev)` over PostgREST.
struct SupabaseCatalogDeltaFetcher: CatalogDeltaFetching {
    /// A delta is normally a few KB. This ceiling exists so a server that
    /// answers a low cursor with the entire catalogue cannot be merged row by
    /// row through `JSONSerialization` on the main actor's heap — past this,
    /// giving up and taking the ordinary full download is both cheaper and the
    /// path that is already well tested.
    private static let maxDeltaBytes = 4 * 1_024 * 1_024

    private let anonKey: String
    private let url: URL
    private let session: URLSession

    init(anonKey: String, url: URL = SupabaseConfig.catalogDeltaRPCURL) {
        self.anonKey = anonKey
        self.url = url
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        self.session = URLSession(configuration: config)
    }

    func fetchDelta(since rev: Int64) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data("{\"client_rev\":\(rev)}".utf8)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        // ⚠️ A 404 here means the RPC is not deployed yet. That is not an error
        // worth surfacing — the caller falls through to the full fetch, which
        // is exactly what every build did before this existed.
        guard (200..<300).contains(http.statusCode) else {
            throw CatalogFetchError.httpStatus(http.statusCode)
        }
        guard data.count <= Self.maxDeltaBytes else {
            throw URLError(.dataLengthExceedsMaximum)
        }
        return data
    }
}

/// One catalog source: a fetcher paired with the URL it fetches. `refresh()`
/// tries the configured sources in order — Supabase first, gh-pages as a
/// fallback mirror — so a backend outage transparently degrades to the last
/// published gh-pages copy (and then to the on-disk cache / bundled seed).
struct CatalogSource: Sendable {
    let fetcher: CatalogFetching
    let url: URL
    /// Optional cheap "has anything changed?" probe for this source. When it is
    /// present and answers with the token already stored beside a readable
    /// cache, the (large) fetch is skipped entirely. `nil` means "always fetch",
    /// which is what the gh-pages mirror does — it publishes no version.
    let versionProbe: CatalogVersionProbing?
    /// Optional "send only what changed" fetcher. Present alongside
    /// `versionProbe` on Supabase; `nil` on the gh-pages mirror, which
    /// publishes one whole file and nothing else. `nil` means "always fetch in
    /// full", which is the behaviour every build had before this existed.
    let deltaFetcher: CatalogDeltaFetching?

    init(fetcher: CatalogFetching,
         url: URL,
         versionProbe: CatalogVersionProbing? = nil,
         deltaFetcher: CatalogDeltaFetching? = nil) {
        self.fetcher = fetcher
        self.url = url
        self.versionProbe = versionProbe
        self.deltaFetcher = deltaFetcher
    }
}

/// Loads the tour catalog with a **local-first, network-refresh** strategy.
///
/// - `loadLocal()` returns an immediately-available catalog: the on-disk cache
///   from the last good network fetch if present (and stamped with the current
///   app version), otherwise the catalog seed bundled in the app. This is what
///   the UI shows at first frame and what keeps the app fully functional
///   offline.
/// - `refresh()` fetches the latest catalog from the remote URL, retrying a few
///   times with backoff on transient failures; on success it overwrites the
///   cache and returns the decoded catalog. Any failure after all attempts
///   returns `nil`, leaving the existing local copy in place.
///
/// This is the first reusable piece of the eventual backend: swapping
/// `remoteURL` for a live API endpoint is all that changes on the app side.
final class RemoteCatalogLoader {
    /// The published catalog mirror, hosted alongside audio + images on gh-pages.
    /// Retained as the automatic fallback source behind the Supabase RPC.
    static let remoteURL = URL(string: "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/Tours.json")!

    /// The running app's build number (`CFBundleVersion`), used to stamp the
    /// cache so an update can discard a cache written by the previous build.
    /// Seven days. Long enough that the cheap-probe saving is untouched in
    /// normal use, short enough that nobody lives with a bad cache.
    static let defaultMaxCacheAge: TimeInterval = 7 * 24 * 60 * 60

    static var currentAppVersion: String {
        (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "unknown"
    }

    /// Production catalog sources, tried in order: the live Supabase backend
    /// first, then the gh-pages mirror. The Supabase source is included only
    /// when credentials are filled in (`SupabaseConfig.isConfigured`), so a
    /// missing key degrades to gh-pages-only rather than failing every refresh.
    static var defaultSources: [CatalogSource] {
        var sources: [CatalogSource] = []
        if SupabaseConfig.isConfigured {
            sources.append(CatalogSource(fetcher: SupabaseCatalogFetcher(anonKey: SupabaseConfig.anonKey),
                                         url: SupabaseConfig.catalogRPCURL,
                                         versionProbe: SupabaseCatalogVersionProbe(anonKey: SupabaseConfig.anonKey),
                                         deltaFetcher: SupabaseCatalogDeltaFetcher(anonKey: SupabaseConfig.anonKey)))
        }
        sources.append(CatalogSource(fetcher: URLSessionCatalogFetcher(), url: remoteURL))
        return sources
    }

    private let sources: [CatalogSource]
    private let bundle: Bundle
    private let cacheURL: URL?
    private let retryPolicy: CatalogRetryPolicy
    private let appVersion: String

    /// How long a cache may go unre-downloaded while the version probe keeps
    /// saying "you already hold this".
    ///
    /// 🔴 **This is the catch-all, and it is deliberately not a fix for a known
    /// cause.** On 2026-09-16 a device held a cache the probe called current
    /// while its contents were not: one place was missing, the map drew a
    /// cluster where it should have drawn a place, and **the owner restarted
    /// the app repeatedly over an hour without recovering.** Only deleting the
    /// app fixed it. The mechanism was never found — a partial publish was
    /// ruled out (the seed is one transaction and `refresh_catalog_snapshot()`
    /// is its last statement, so no reader can see a half-written catalogue).
    ///
    /// `catalogAlreadyHeld` returning the cache on a token match is what makes
    /// a refresh cost 34 bytes instead of 2.3 MB, and it is worth keeping. But
    /// a token match is a claim about the *server*, not evidence about what is
    /// on this disk — so believing it forever means a cache that goes wrong for
    /// ANY reason stays wrong forever, silently, with no user-visible symptom
    /// and no recovery short of reinstalling. Bounding it means the app heals
    /// itself within a known window whether or not anyone understands why it
    /// broke.
    ///
    /// The cost is one full download per device per window, and only when
    /// nothing has changed for that entire window — which, at this catalogue's
    /// rate of change, is close to never.
    private let maxCacheAge: TimeInterval

    /// Designated initializer — takes the ordered list of catalog sources.
    init(sources: [CatalogSource] = RemoteCatalogLoader.defaultSources,
         bundle: Bundle = .main,
         cacheDirectory: URL? = nil,
         retryPolicy: CatalogRetryPolicy = .default,
         appVersion: String = RemoteCatalogLoader.currentAppVersion,
         maxCacheAge: TimeInterval = RemoteCatalogLoader.defaultMaxCacheAge) {
        self.sources = sources
        self.bundle = bundle
        self.retryPolicy = retryPolicy
        self.appVersion = appVersion
        self.maxCacheAge = maxCacheAge
        let dir = cacheDirectory
            ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        self.cacheURL = dir?.appendingPathComponent("Tours.cache.json")
    }

    /// Single-source convenience — wraps one `fetcher` against `remoteURL`.
    /// Used by the unit tests, which inject a stub fetcher.
    convenience init(fetcher: CatalogFetching,
                     bundle: Bundle = .main,
                     cacheDirectory: URL? = nil,
                     retryPolicy: CatalogRetryPolicy = .default,
                     appVersion: String = RemoteCatalogLoader.currentAppVersion,
                     maxCacheAge: TimeInterval = RemoteCatalogLoader.defaultMaxCacheAge) {
        self.init(sources: [CatalogSource(fetcher: fetcher, url: RemoteCatalogLoader.remoteURL)],
                  bundle: bundle,
                  cacheDirectory: cacheDirectory,
                  retryPolicy: retryPolicy,
                  appVersion: appVersion,
                  maxCacheAge: maxCacheAge)
    }

    /// Sidecar file recording which app version wrote the cache.
    private var versionURL: URL? {
        cacheURL?.deletingLastPathComponent().appendingPathComponent("Tours.cache.version")
    }

    /// Sidecar file recording which *catalog* version the cache came from — the
    /// opaque token returned by the source's version probe. Distinct from
    /// `versionURL`, which records the *app build* that wrote the cache.
    private var catalogVersionURL: URL? {
        cacheURL?.deletingLastPathComponent().appendingPathComponent("Tours.cache.catalogVersion")
    }

    /// Sidecar file recording the server `rev` the cache corresponds to — the
    /// cursor handed to `get_catalog_since` next time.
    ///
    /// ⚠️ Deliberately a THIRD file rather than a field inside the cache. The
    /// cache holds the server's own bytes and nothing of ours; putting a
    /// client-side bookkeeping value inside it would mean rewriting the
    /// document to record something the document does not describe.
    private var catalogRevURL: URL? {
        cacheURL?.deletingLastPathComponent().appendingPathComponent("Tours.cache.rev")
    }

    /// Sidecar recording the byte length of the cache as written, so a short
    /// write can be detected without decoding ~3 MB of JSON. See
    /// `cacheLengthMatches()`.
    private var cacheLengthURL: URL? {
        cacheURL?.deletingLastPathComponent().appendingPathComponent("Tours.cache.length")
    }

    /// Immediately-available catalog: cached copy if valid, else bundled seed.
    ///
    /// The cache is discarded if it was written by a *different* app version, so
    /// a freshly bundled seed shipped in an update isn't shadowed by a stale
    /// cache (the exact failure mode of an offline 47→48 update: the old cache
    /// would otherwise keep masking the newer bundled catalog until the next
    /// successful network refresh). Cache-first otherwise — the cache is the
    /// newest copy in the common case.
    func loadLocal() -> ToursData? {
        readCache() ?? readBundle()
    }

    /// Fetches the latest catalog from the network, trying each source in order
    /// (Supabase → gh-pages) and returning the first that yields a decodable
    /// catalog. On success, writes it to the cache (stamped with the current app
    /// version) and returns it. Returns `nil` only after every source fails,
    /// leaving the local copy untouched.
    ///
    /// A source carrying a version probe is asked the cheap question first: if
    /// it is still serving the catalog we already hold, this returns that copy
    /// having transferred 34 bytes instead of ~3.4 MB. See
    /// `docs/catalog-version-check-design.md`.
    func refresh() async -> ToursData? {
        for source in sources {
            switch await refresh(from: source) {
            case .fetched(let decoded), .merged(let decoded):
                return decoded
            case .upToDate(let current):
                // ⚠️ Returning here — rather than falling through — is the whole
                // point. Continuing to the next source would download the
                // gh-pages mirror in full to learn what we already knew.
                return current
            case .unusable:
                continue
            }
        }
        return nil
    }

    /// What one source produced. `upToDate` is not a failure: the source told us
    /// (cheaply) that the catalog we already hold is the current one.
    private enum RefreshOutcome {
        case fetched(ToursData)
        /// A delta was applied to the cache we already held. Distinct from
        /// `.fetched` because it was assembled here rather than downloaded
        /// whole, which is worth being able to see in a log and in a test.
        case merged(ToursData)
        case upToDate(ToursData)
        case unusable
    }

    /// The one place a catalog is turned from bytes into a `ToursData`.
    ///
    /// ⚠️ **This exists so a dropped element cannot pass unnoticed.** The
    /// element-wise decode in `ToursData` means one unreadable tour costs that
    /// tour instead of the whole catalog — a good trade, and exactly the kind
    /// of thing that then goes unobserved for months. The three decode sites
    /// (network, cache, bundle) all come through here, so any loss is logged
    /// once, with its source named.
    ///
    /// It stays `try?` at the boundary: a decode that fails *outright* is still
    /// how this loader says "this source is unusable, try the next one".
    private func decodeCatalog(_ data: Data, from source: String) -> ToursData? {
        guard let decoded = try? JSONDecoder().decode(ToursData.self, from: data) else {
            return nil
        }
        if !decoded.losses.isEmpty {
            // `.public` throughout: none of this is user data, and a redacted
            // "<private>" in Console is exactly as useless as not logging it.
            Self.log.error("Catalog from \(source, privacy: .public) dropped \(decoded.losses.summary, privacy: .public) this build could not read; kept \(decoded.tours.count, privacy: .public) tours and \(decoded.makers.count, privacy: .public) makers.")
        }
        return decoded
    }

    private static let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.ehky.atlas",
                                    category: "catalog")

    /// Resolves one source: probe if it offers one, otherwise fetch — retrying
    /// transient failures with exponential backoff. Yields `.fetched` (and
    /// caches it), `.upToDate` when the probe says we already hold this exact
    /// catalog, or `.unusable` when the source is exhausted — the caller then
    /// falls through to the next source.
    private func refresh(from source: CatalogSource) async -> RefreshOutcome {
        // Ask the cheap question first (34 bytes vs ~3.4 MB). A probe that fails
        // for any reason returns nil and we download exactly as we did before —
        // this is an optimisation and must never be why content fails to arrive.
        let serverVersion = await probedVersion(for: source)
        if let serverVersion, let current = catalogAlreadyHeld(matching: serverVersion) {
            return .upToDate(current)
        }

        // Then the cheap-ish question: can we be sent only what changed?
        // Everything in here is an optimisation layered on a full download that
        // already works, so every branch that is not plainly correct returns nil
        // and we fall through to that download. *Any doubt → full download* is
        // the rule, and it is the reason this is safe to ship.
        if let merged = await mergedCatalog(for: source, serverVersion: serverVersion) {
            return .merged(merged)
        }

        // 🔴 The cursor for the NEXT refresh has to be read BEFORE this
        // download, not after. Read before, a reseed landing mid-download
        // leaves us with a cursor slightly behind the bytes we stored, and the
        // next delta re-sends a handful of rows we already have — which is
        // harmless, because a merge replaces by id. Read after, the same reseed
        // would pair a NEW cursor with OLDER content, and every row in between
        // would never be sent again. Same argument as the version token above,
        // and the same direction of safety.
        //
        // Costs 139 bytes, and only on a full download.
        let cursor = await headRev(for: source)

        var attempt = 0
        while true {
            attempt += 1
            do {
                let data = try await source.fetcher.fetchData(from: source.url)
                guard let decoded = decodeCatalog(data, from: source.url.host() ?? "network") else {
                    // A 2xx with undecodable bytes is a bad response, not a
                    // transient glitch — a retry returns the same bytes. Give up
                    // on this source and fall through to the next.
                    return .unusable
                }
                // The token is stamped only now, on bytes we have actually
                // decoded — and it is the token read BEFORE the download, so a
                // snapshot rebuilt mid-download leaves us one version behind
                // (we re-download next time) rather than one version ahead
                // (we would never download again).
                writeCache(data, catalogVersion: serverVersion, rev: cursor)
                return .fetched(decoded)
            } catch {
                if attempt >= retryPolicy.maxAttempts || !Self.isRetryable(error) {
                    return .unusable
                }
                let delay = backoffDelay(forAttempt: attempt)
                if delay > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
    }

    /// The server's current cursor, asked for with a sentinel above any real
    /// `rev` so the answer is an empty envelope — about 139 bytes.
    ///
    /// ⚠️ Returns `nil` for a source with no delta fetcher, and for any failure
    /// including the RPC simply not being deployed yet. `nil` then CLEARS the
    /// stored cursor when the fetched bytes are written, which is correct: a
    /// catalogue we cannot describe with a cursor must not carry a stale one.
    private func headRev(for source: CatalogSource) async -> Int64? {
        guard let deltaFetcher = source.deltaFetcher else { return nil }
        guard let data = try? await deltaFetcher.fetchDelta(since: Int64.max) else { return nil }
        guard let envelope = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        if let n = envelope["rev"] as? NSNumber { return n.int64Value }
        if let text = envelope["rev"] as? String { return Int64(text) }
        return nil
    }

    /// Applies a delta to the cache we already hold, or returns `nil` to mean
    /// "do the full download instead".
    ///
    /// Every guard here corresponds to a rule in
    /// `docs/delta-catalog-fetch-design.md` § Phase 2, and each was earned by an
    /// incident in this repo:
    ///
    /// 1. **Any doubt → full download.** No cursor, no cache, a cache from
    ///    another build, an HTTP error, an unreadable body, a merge that throws
    ///    — all of it returns nil, and the caller downloads exactly as it did
    ///    before this existed.
    /// 2. **The cursor advances only on a merge that completed.** It is written
    ///    in the same call as the bytes it describes, after those bytes have
    ///    been decoded — never before, and never on a path that gave up.
    /// 3. **A merge that loses elements is not cached.** For a full download a
    ///    dropped element costs one tour; for a merge it means the cache is now
    ///    missing a row it is supposed to hold, and every later delta builds on
    ///    that hole.
    /// 4. **A merge must not shrink the catalogue** by more than `removedIds`
    ///    accounted for. Cheap, and it catches a whole class of merge bug that
    ///    would otherwise be invisible until a user noticed missing content.
    ///
    /// ⚠️ **This decodes the whole catalogue twice** — once here for the
    /// baseline the two guards below compare against, and once more on the
    /// merged bytes — where a full download decodes once. That is a real cost,
    /// not a free win, and it is paid on every refresh that reaches this path.
    /// It buys skipping a ~2.4 MB transfer, which is seconds against tens of
    /// milliseconds, so the trade is not close — but it should be understood
    /// rather than discovered. There is no cheaper way to get the baseline:
    /// both `losses` and `tours.count` only exist after a decode.
    private func mergedCatalog(for source: CatalogSource, serverVersion: String?) async -> ToursData? {
        guard let deltaFetcher = source.deltaFetcher,
              let rev = storedCatalogRev(),
              let cacheURL,
              cachedVersionMatches(),
              let cachedBytes = try? Data(contentsOf: cacheURL),
              let cachedCatalog = try? JSONDecoder().decode(ToursData.self, from: cachedBytes)
        else { return nil }

        guard let deltaBytes = try? await deltaFetcher.fetchDelta(since: rev) else { return nil }

        let result: CatalogDeltaMerge.Result
        do {
            result = try CatalogDeltaMerge.merge(cached: cachedBytes, delta: deltaBytes)
        } catch {
            Self.log.error("Catalog delta since rev \(rev, privacy: .public) could not be merged (\(String(describing: error), privacy: .public)); falling back to a full download.")
            return nil
        }

        guard let decoded = try? JSONDecoder().decode(ToursData.self, from: result.data) else {
            Self.log.error("Catalog delta since rev \(rev, privacy: .public) merged into bytes that would not decode; falling back to a full download.")
            return nil
        }

        // Rule 3 — compared against what the CACHE already lost, not against
        // zero. A build that cannot read some existing row (an unfamiliar
        // `kind`, say) drops it on every decode, and measuring against zero
        // would disable the delta path permanently for that user.
        guard decoded.losses.total <= cachedCatalog.losses.total else {
            Self.log.error("Catalog delta since rev \(rev, privacy: .public) dropped \(decoded.losses.summary, privacy: .public) beyond what the cache already lost; falling back to a full download.")
            return nil
        }

        // Rule 4 — the only sanctioned way for the catalogue to get smaller is
        // `removedIds`, and today the server never sends any.
        guard decoded.tours.count >= cachedCatalog.tours.count - result.removed else {
            Self.log.error("Catalog delta since rev \(rev, privacy: .public) shrank the catalogue from \(cachedCatalog.tours.count, privacy: .public) to \(decoded.tours.count, privacy: .public) tours with \(result.removed, privacy: .public) removals; falling back to a full download.")
            return nil
        }

        // Rule 2 — both sidecars are written here, from the delta's own
        // envelope, so the cursor and the token describe the same instant the
        // server read them at. `refreshedAt` comes from the same row as the
        // payload, which is why it is preferred over the separately-probed
        // token.
        writeCache(result.data,
                   catalogVersion: result.refreshedAt ?? serverVersion,
                   rev: result.rev)
        if result.applied > 0 || result.removed > 0 {
            Self.log.info("Catalog delta since rev \(rev, privacy: .public): applied \(result.applied, privacy: .public), removed \(result.removed, privacy: .public), now at rev \(result.rev, privacy: .public).")
        }
        return decoded
    }

    /// The source's current version token, or `nil` if this source has no probe
    /// or the probe did not give a usable answer. `nil` means "download".
    private func probedVersion(for source: CatalogSource) async -> String? {
        guard let probe = source.versionProbe else { return nil }
        guard let token = try? await probe.fetchVersion() else { return nil }
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// The catalog we already hold, **only if** it came from this exact version
    /// *and* is still readable.
    ///
    /// ⚠️ A matching token is not enough on its own. If the cache is missing,
    /// corrupt, or was written by a different app build, `readCache()` returns
    /// nil here and we download — otherwise a matching version with no usable
    /// local copy would leave the app showing nothing.
    private func catalogAlreadyHeld(matching serverVersion: String) -> ToursData? {
        guard let stored = storedCatalogVersion(), stored == serverVersion else { return nil }

        // 🔴 A token match says the SERVER has not changed. It is not evidence
        // that this disk holds what that token describes, and treating it as
        // such is how a cache that has gone wrong stays wrong forever — see
        // `maxCacheAge`.
        //
        // ⚠️ Both guards RETURN NIL RATHER THAN DISCARDING. Returning nil only
        // declines the short-circuit, so the full download below still runs and
        // overwrites the cache on success — while a download that FAILS leaves
        // the existing copy untouched and still serving. Discarding here would
        // mean a device that is offline, or hitting a bad source, loses a
        // complete catalogue and falls back to the bundled seed: strictly worse
        // than the stale cache we were worried about. The pinning this fixes
        // comes from believing the token, not from the bytes being present.
        guard cacheIsFresh() else {
            Self.log.notice("Cache matches the server token but is past the self-heal window; downloading in full instead of trusting it.")
            return nil
        }
        guard let cached = readCache(), cacheLengthMatches() else {
            Self.log.error("Cache matches the server token but failed its length check; downloading in full instead of trusting it.")
            return nil
        }
        return cached
    }

    /// Whether the cache is young enough to be trusted on a bare token match.
    /// A cache with no readable timestamp is treated as NOT fresh: unknown age
    /// is exactly the case this guard exists for, and a full download is the
    /// safe direction.
    private func cacheIsFresh() -> Bool {
        guard maxCacheAge > 0 else { return true }
        guard let written = cacheWrittenAt else { return false }
        return Date().timeIntervalSince(written) < maxCacheAge
    }

    /// When the cached catalogue was last written — i.e. when the content the
    /// app is showing actually arrived from the network.
    ///
    /// Surfaced in Settings. On 2026-09-16 the owner spent an hour unable to
    /// tell whether their phone had taken new content, and neither could this
    /// session: "the server has it" and "the phone has it" are different
    /// claims, and nothing in the app answered the second. One line of text
    /// answers it, and would have turned that hour into a glance.
    var cacheWrittenAt: Date? {
        guard let cacheURL else { return nil }
        return (try? FileManager.default.attributesOfItem(atPath: cacheURL.path))?[.modificationDate] as? Date
    }

    /// Cheap integrity check: the cache file is the length it was when written.
    ///
    /// ⚠️ **This catches a truncated or partially-written cache and nothing
    /// else.** A cache that is complete but describes older content has a
    /// consistent length and passes — which is why `cacheIsFresh()` above, not
    /// this, is the guard that actually bounds the damage. Kept because a short
    /// write is a real and otherwise-silent failure, and the check costs one
    /// `stat`.
    ///
    /// No recorded length (a cache written by a build before this shipped) is
    /// not a failure — there is nothing to disagree with.
    private func cacheLengthMatches() -> Bool {
        guard let cacheURL, let cacheLengthURL,
              let recorded = try? String(contentsOf: cacheLengthURL, encoding: .utf8),
              let expected = Int(recorded.trimmingCharacters(in: .whitespacesAndNewlines))
        else { return true }
        let actual = (try? FileManager.default.attributesOfItem(atPath: cacheURL.path))?[.size] as? Int
        return actual == expected
    }

    /// Whether a failed fetch is worth retrying. Transport errors and transient
    /// server conditions are; a clean 4xx (e.g. 404) is not.
    private static func isRetryable(_ error: Error) -> Bool {
        switch error {
        case CatalogFetchError.httpStatus(let code):
            return code == 408 || code == 429 || (500...599).contains(code)
        case is URLError:
            // Timeouts, dropped connections, DNS, offline — all transient.
            return true
        default:
            // Unknown error: assume transient and let the attempt cap bound it.
            return true
        }
    }

    private func backoffDelay(forAttempt attempt: Int) -> TimeInterval {
        guard retryPolicy.baseDelay > 0 else { return 0 }
        let exponential = retryPolicy.baseDelay * pow(2, Double(attempt - 1))
        let jitter = retryPolicy.jitter > 0 ? Double.random(in: 0..<retryPolicy.jitter) : 0
        return exponential + jitter
    }

    // MARK: - Local sources

    private func readCache() -> ToursData? {
        guard let cacheURL else { return nil }
        // Discard a cache written by a different app version (or one missing the
        // version stamp — i.e. written by a pre-stamp build) so a newer bundled
        // seed wins after an update.
        guard cachedVersionMatches() else {
            discardCache()
            return nil
        }
        guard let data = try? Data(contentsOf: cacheURL) else { return nil }
        return decodeCatalog(data, from: "the on-disk cache")
    }

    private func readBundle() -> ToursData? {
        guard let url = bundle.url(forResource: "Tours", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return decodeCatalog(data, from: "the bundled seed")
    }

    private func cachedVersionMatches() -> Bool {
        guard let versionURL,
              let stored = try? String(contentsOf: versionURL, encoding: .utf8) else { return false }
        return stored == appVersion
    }

    /// The cursor the cache corresponds to, or `nil` if we have none — in which
    /// case there is nothing to ask a delta *since*, and the full download is
    /// the only correct answer.
    private func storedCatalogRev() -> Int64? {
        guard let catalogRevURL,
              let stored = try? String(contentsOf: catalogRevURL, encoding: .utf8) else { return nil }
        return Int64(stored.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func storedCatalogVersion() -> String? {
        guard let catalogVersionURL,
              let stored = try? String(contentsOf: catalogVersionURL, encoding: .utf8) else { return nil }
        let trimmed = stored.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Writes the cache and, atomically with it, the token describing what is in
    /// it.
    ///
    /// ⚠️ `catalogVersion: nil` **removes** the token rather than leaving it.
    /// A cache written from the gh-pages mirror (which publishes no version)
    /// must not keep a Supabase token describing content it did not come from —
    /// that stale token would then match a future probe and pin the app to the
    /// mirror's copy.
    private func writeCache(_ data: Data, catalogVersion: String? = nil, rev: Int64? = nil) {
        guard let cacheURL else { return }
        try? data.write(to: cacheURL, options: .atomic)
        // Written AFTER the bytes: a length recorded for a write that then
        // failed would be a false all-clear, which is worse than none.
        if let cacheLengthURL {
            try? String(data.count).write(to: cacheLengthURL, atomically: true, encoding: .utf8)
        }
        // ⚠️ A full fetch passes `rev: nil` and therefore CLEARS the cursor,
        // for the same reason `catalogVersion: nil` clears the token: the bytes
        // just written did not come from a delta exchange and no cursor
        // describes them. A stale cursor left here would make the next refresh
        // ask for "everything since N" against a cache that is not at N — and
        // the rows between would never arrive.
        if let catalogRevURL {
            if let rev {
                try? String(rev).write(to: catalogRevURL, atomically: true, encoding: .utf8)
            } else {
                try? FileManager.default.removeItem(at: catalogRevURL)
            }
        }
        if let versionURL {
            try? appVersion.write(to: versionURL, atomically: true, encoding: .utf8)
        }
        if let catalogVersionURL {
            if let catalogVersion {
                try? catalogVersion.write(to: catalogVersionURL, atomically: true, encoding: .utf8)
            } else {
                try? FileManager.default.removeItem(at: catalogVersionURL)
            }
        }
    }

    private func discardCache() {
        if let cacheURL { try? FileManager.default.removeItem(at: cacheURL) }
        if let versionURL { try? FileManager.default.removeItem(at: versionURL) }
        if let catalogVersionURL { try? FileManager.default.removeItem(at: catalogVersionURL) }
        if let catalogRevURL { try? FileManager.default.removeItem(at: catalogRevURL) }
        if let cacheLengthURL { try? FileManager.default.removeItem(at: cacheLengthURL) }
    }

    /// Throw away the cached catalogue and every sidecar that describes it, so
    /// the next refresh is a full download with nothing to short-circuit on.
    ///
    /// Exposed for Settings → Check for new content. Until 2026-09-16 that button cleared
    /// `URLCache` and the image cache only, so the one cache a user might
    /// actually need to clear was the one it left alone — and the owner, whose
    /// map was wrong, had no way to fix it but to delete the app.
    func clearCachedCatalog() {
        discardCache()
    }
}
