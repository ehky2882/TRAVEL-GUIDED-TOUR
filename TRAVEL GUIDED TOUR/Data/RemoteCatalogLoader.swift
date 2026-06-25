import Foundation

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
    /// The published catalog, hosted alongside audio + images on gh-pages.
    static let remoteURL = URL(string: "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/Tours.json")!

    /// The running app's build number (`CFBundleVersion`), used to stamp the
    /// cache so an update can discard a cache written by the previous build.
    static var currentAppVersion: String {
        (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "unknown"
    }

    private let fetcher: CatalogFetching
    private let bundle: Bundle
    private let cacheURL: URL?
    private let retryPolicy: CatalogRetryPolicy
    private let appVersion: String

    init(fetcher: CatalogFetching = URLSessionCatalogFetcher(),
         bundle: Bundle = .main,
         cacheDirectory: URL? = nil,
         retryPolicy: CatalogRetryPolicy = .default,
         appVersion: String = RemoteCatalogLoader.currentAppVersion) {
        self.fetcher = fetcher
        self.bundle = bundle
        self.retryPolicy = retryPolicy
        self.appVersion = appVersion
        let dir = cacheDirectory
            ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        self.cacheURL = dir?.appendingPathComponent("Tours.cache.json")
    }

    /// Sidecar file recording which app version wrote the cache.
    private var versionURL: URL? {
        cacheURL?.deletingLastPathComponent().appendingPathComponent("Tours.cache.version")
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

    /// Fetches the latest catalog from the network, retrying transient failures
    /// with exponential backoff. On success, writes it to the cache (stamped
    /// with the current app version) and returns it. Returns `nil` only after
    /// all attempts fail, leaving the local copy untouched.
    func refresh() async -> ToursData? {
        var attempt = 0
        while true {
            attempt += 1
            do {
                let data = try await fetcher.fetchData(from: Self.remoteURL)
                guard let decoded = try? JSONDecoder().decode(ToursData.self, from: data) else {
                    // A 2xx with undecodable bytes is a bad published file, not
                    // a transient glitch — a retry returns the same bytes. Give
                    // up and keep the good local copy.
                    return nil
                }
                writeCache(data)
                return decoded
            } catch {
                if attempt >= retryPolicy.maxAttempts || !Self.isRetryable(error) {
                    return nil
                }
                let delay = backoffDelay(forAttempt: attempt)
                if delay > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
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
        return try? JSONDecoder().decode(ToursData.self, from: data)
    }

    private func readBundle() -> ToursData? {
        guard let url = bundle.url(forResource: "Tours", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(ToursData.self, from: data)
    }

    private func cachedVersionMatches() -> Bool {
        guard let versionURL,
              let stored = try? String(contentsOf: versionURL, encoding: .utf8) else { return false }
        return stored == appVersion
    }

    private func writeCache(_ data: Data) {
        guard let cacheURL else { return }
        try? data.write(to: cacheURL, options: .atomic)
        if let versionURL {
            try? appVersion.write(to: versionURL, atomically: true, encoding: .utf8)
        }
    }

    private func discardCache() {
        if let cacheURL { try? FileManager.default.removeItem(at: cacheURL) }
        if let versionURL { try? FileManager.default.removeItem(at: versionURL) }
    }
}
