import Foundation

/// Abstracts the network fetch so the catalog loader can be unit-tested
/// without hitting the network. Production uses `URLSessionCatalogFetcher`;
/// tests inject a stub.
protocol CatalogFetching: Sendable {
    func fetchData(from url: URL) async throws -> Data
}

struct URLSessionCatalogFetcher: CatalogFetching {
    func fetchData(from url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        // Always go to origin — we manage freshness ourselves via the cache
        // file, and gh-pages/CDN layers can otherwise pin a stale copy.
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 15
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }
}

/// Loads the tour catalog with a **local-first, network-refresh** strategy.
///
/// - `loadLocal()` returns an immediately-available catalog: the on-disk cache
///   from the last good network fetch if present, otherwise the catalog seed
///   bundled in the app. This is what the UI shows at first frame and what
///   keeps the app fully functional offline.
/// - `refresh()` fetches the latest catalog from the remote URL; on success it
///   overwrites the cache and returns the decoded catalog. Any network or
///   decode failure returns `nil`, leaving the existing local copy in place.
///
/// This is the first reusable piece of the eventual backend: swapping
/// `remoteURL` for a live API endpoint is all that changes on the app side.
final class RemoteCatalogLoader {
    /// The published catalog, hosted alongside audio + images on gh-pages.
    static let remoteURL = URL(string: "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/Tours.json")!

    private let fetcher: CatalogFetching
    private let bundle: Bundle
    private let cacheURL: URL?

    init(fetcher: CatalogFetching = URLSessionCatalogFetcher(),
         bundle: Bundle = .main,
         cacheDirectory: URL? = nil) {
        self.fetcher = fetcher
        self.bundle = bundle
        let dir = cacheDirectory
            ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        self.cacheURL = dir?.appendingPathComponent("Tours.cache.json")
    }

    /// Immediately-available catalog: cached copy if valid, else bundled seed.
    ///
    /// Note: in the rare window right after an app update while offline, a
    /// stale cache can shadow a newer bundled seed. The network refresh on the
    /// next online launch resolves it, so we keep cache-first (the cache is the
    /// newest copy in the common case).
    func loadLocal() -> ToursData? {
        readCache() ?? readBundle()
    }

    /// Fetches the latest catalog from the network. On success, writes it to
    /// the cache and returns it. Returns `nil` on any network/decode failure.
    func refresh() async -> ToursData? {
        guard let data = try? await fetcher.fetchData(from: Self.remoteURL),
              let decoded = try? JSONDecoder().decode(ToursData.self, from: data) else {
            return nil
        }
        writeCache(data)
        return decoded
    }

    // MARK: - Local sources

    private func readCache() -> ToursData? {
        guard let cacheURL, let data = try? Data(contentsOf: cacheURL) else { return nil }
        return try? JSONDecoder().decode(ToursData.self, from: data)
    }

    private func readBundle() -> ToursData? {
        guard let url = bundle.url(forResource: "Tours", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(ToursData.self, from: data)
    }

    private func writeCache(_ data: Data) {
        guard let cacheURL else { return }
        try? data.write(to: cacheURL, options: .atomic)
    }
}
