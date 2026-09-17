import Foundation

/// The catalog's vectors on disk, and the scoring that ranks them.
///
/// `scripts/build-embeddings.py` writes an `ATLSEMB2` sidecar — one int8 vector
/// per text chunk, grouped by tour, with a self-describing header. This reads
/// it back, refusing anything whose header disagrees with what the app expects,
/// and reimplements `tour_scores` so the phone ranks exactly as Python does.
///
/// 🔴 THE HEADER IS VALIDATED BEFORE A SINGLE NUMBER IS TRUSTED. A sidecar built
/// from a different model produces vectors that are all plausible and all
/// wrong — no crash, no log, just worse answers forever. The model id travels
/// in the header for exactly this reason, and `QueryEmbedder` checks the same
/// id on the model side, so the pair can only ever match or be rejected.
///
/// ⚠️ THE INDEX IS int8 AND THAT IS NOT A DETAIL. Quantization costs ~0.9990
/// cosine per vector, which `scripts/verify-coreml-parity.py` deliberately
/// includes in its ranking check: it compares Python full-precision against
/// Core ML query + *this* dequantized index, because that pairing is the one a
/// phone actually runs.
actor TourEmbeddingStore {

    enum Failure: Error, CustomStringConvertible {
        case notDownloaded
        case malformed(String)
        case modelMismatch(expected: String, found: String)

        var description: String {
            switch self {
            case .notDownloaded:
                "the search index has not been downloaded"
            case .malformed(let why):
                "the search index is unusable: \(why)"
            case .modelMismatch(let expected, let found):
                "index was built with \(found), the app embeds with \(expected)"
            }
        }
    }

    /// `MAGIC` / `FORMAT_VERSION` / `HEADER_STRUCT` in `build-embeddings.py`.
    /// "<8sIIIIIf64s" — magic, version, tours, chunks, dims, flags, scale, model.
    private static let magic = Array("ATLSEMB2".utf8)
    private static let formatVersion: UInt32 = 2
    private static let flagInt8: UInt32 = 1
    private static let headerSize = 8 + 4 * 5 + 4 + 64   // 96

    /// `BEST_CHUNK_WEIGHT`. The blend is the contract with Python: the best
    /// chunk finds a tour that mentions the thing once, the mean finds one
    /// that is about it throughout.
    static let bestChunkWeight: Float = 0.6

    struct Index {
        /// Tour ids in sidecar order. Scores come back in this same order.
        let tourIDs: [UUID]
        /// `chunkOffsets[i]` is where tour `i`'s chunks start; a tour's count
        /// is the next offset minus this one, which is why there are n+1.
        let chunkOffsets: [Int]
        /// Dequantized and re-normalised, `chunks × dims`, row-major.
        let chunks: [Float]
        let dims: Int
        let modelID: String
    }

    private var index: Index?

    /// One sentence per chunk, aligned with `index.chunks`.
    ///
    /// ⚠️ OPTIONAL BY DESIGN AT EVERY LEVEL. Absent file, older file,
    /// mismatched pair — all of them mean "no snippets", never an error.
    /// Search without explanations is exactly what shipped before this, so
    /// degrading to it is a working outcome.
    private var snippets: Snippets?

    struct Snippets {
        /// `bounds[i]..<bounds[i+1]` is snippet `i` inside `blob`.
        let bounds: [Int]
        let blob: [UInt8]
        var count: Int { max(bounds.count - 1, 0) }
    }

    // MARK: - Loading

    /// Where the sidecar is cached. gh-pages is the asset CDN, so this costs no
    /// Supabase egress — the same reasoning that put the model there.
    static let remoteURL = URL(
        string: "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/search/embeddings.bin"
    )!

    static var cacheURL: URL {
        URL.cachesDirectory.appending(path: "atlas-embeddings.bin")
    }

    static let snippetsURL = URL(
        string: "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/search/search-snippets.bin"
    )!

    static var snippetsCacheURL: URL {
        URL.cachesDirectory.appending(path: "atlas-search-snippets.bin")
    }

    var isLoaded: Bool { index != nil }

    /// The sentence for a chunk, if there is one.
    private func snippet(at chunk: Int) -> String? {
        guard let snippets, chunk >= 0, chunk + 1 < snippets.bounds.count else { return nil }
        let start = snippets.bounds[chunk], end = snippets.bounds[chunk + 1]
        guard end > start, end <= snippets.blob.count else { return nil }
        let text = String(decoding: snippets.blob[start..<end], as: UTF8.self)
        return text.isEmpty ? nil : text
    }

    /// Adopt an already-in-memory sidecar. The parse is the same one every
    /// other path uses, so a test exercising this exercises the real reader.
    func load(_ data: Data) throws {
        index = try Self.parse(data)
    }

    /// Parse the cached sidecar, if one is there. Does not download.
    func loadFromCache() throws {
        let url = Self.cacheURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw Failure.notDownloaded
        }
        index = try Self.parse(try Data(contentsOf: url, options: .mappedIfSafe))
        adoptCachedSnippets()
    }

    /// Snippets from the cache, if a usable pair is there.
    ///
    /// Silent on every failure by design — see `parseSnippets`. Search works
    /// without them, and that is the outcome this degrades to.
    private func adoptCachedSnippets() {
        guard let index else { return }
        let url = Self.snippetsCacheURL
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url, options: .mappedIfSafe)
        else { return }
        snippets = Self.parseSnippets(
            data,
            expectedChunks: index.chunks.count / max(index.dims, 1),
            modelID: index.modelID
        )
    }

    /// Fetch the sidecar and cache it. Parsed BEFORE it is written, so a
    /// truncated or wrong-model download never replaces a good cache.
    func download(using session: URLSession = .shared) async throws {
        let (data, response) = try await session.data(from: Self.remoteURL)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw Failure.malformed("server returned HTTP \(http.statusCode)")
        }
        let parsed = try Self.parse(data)
        try data.write(to: Self.cacheURL, options: .atomic)
        index = parsed
        await downloadSnippets(using: session)
    }

    /// Fetch the snippet file. **Never throws.**
    ///
    /// 🔴 A FAILURE HERE MUST NOT FAIL THE SEARCH. The index has already been
    /// downloaded and adopted by the time this runs; letting a second request
    /// throw would throw away a working search index because an explanation
    /// could not be fetched. Parsed before it is cached, so a bad file never
    /// replaces a good one.
    private func downloadSnippets(using session: URLSession) async {
        guard let index else { return }
        guard let (data, response) = try? await session.data(from: Self.snippetsURL),
              (response as? HTTPURLResponse)?.statusCode ?? 200 == 200,
              let parsed = Self.parseSnippets(
                  data,
                  expectedChunks: index.chunks.count / max(index.dims, 1),
                  modelID: index.modelID
              )
        else { return }
        try? data.write(to: Self.snippetsCacheURL, options: .atomic)
        snippets = parsed
    }

    // MARK: - Parsing

    /// `ATLSNIP1` — magic, version, count, 64-byte model id, then count+1
    /// offsets and the utf8 blob.
    ///
    /// 🔴 RETURNS nil RATHER THAN THROWING, and that is the whole contract.
    /// Snippets are an explanation layered on top of search; a bad one must
    /// cost the explanation, never the search. Every rejection below is a
    /// reason to show no snippet, and none of them is a reason to fail.
    ///
    /// ⚠️ `expectedChunks` is the pairing guard. Snippet N describes chunk N,
    /// so a file built from a different catalogue attaches confident, wrong
    /// sentences to every result — plausible, unfalsifiable and completely
    /// wrong, with nothing to say so. Matching counts is not a proof of
    /// identity, but the two are published by the same job in the same run, so
    /// a count mismatch is the realistic way they diverge.
    static func parseSnippets(_ data: Data, expectedChunks: Int, modelID: String) -> Snippets? {
        let headerSize = 8 + 4 + 4 + 64
        guard data.count >= headerSize else { return nil }
        let bytes = [UInt8](data)
        guard Array(bytes[0..<8]) == Array("ATLSNIP1".utf8) else { return nil }

        func word(_ offset: Int) -> Int {
            Int(UInt32(bytes[offset]) | UInt32(bytes[offset + 1]) << 8
                | UInt32(bytes[offset + 2]) << 16 | UInt32(bytes[offset + 3]) << 24)
        }
        guard word(8) == 1 else { return nil }               // format version
        let count = word(12)
        guard count == expectedChunks else { return nil }

        let declared = String(
            decoding: bytes[16..<80].prefix(while: { $0 != 0 }), as: UTF8.self
        )
        guard declared == modelID else { return nil }

        let offsetsStart = headerSize
        let blobStart = offsetsStart + (count + 1) * 4
        guard bytes.count >= blobStart else { return nil }

        var bounds: [Int] = []
        bounds.reserveCapacity(count + 1)
        for index in 0...count {
            bounds.append(word(offsetsStart + index * 4))
        }
        // Offsets must ascend and must land inside the blob, or a lookup reads
        // whatever follows in memory.
        let blob = Array(bytes[blobStart...])
        guard bounds.last == blob.count else { return nil }
        for index in 0..<count where bounds[index] > bounds[index + 1] { return nil }

        return Snippets(bounds: bounds, blob: blob)
    }

    static func parse(_ data: Data) throws -> Index {
        guard data.count >= headerSize else {
            throw Failure.malformed("file is shorter than its own header")
        }
        let bytes = [UInt8](data)

        guard Array(bytes[0..<8]) == magic else {
            throw Failure.malformed("not an Atlas embeddings file")
        }
        func word(_ offset: Int) -> UInt32 {
            // Little-endian, read byte by byte: the file is written by
            // `struct.pack("<…")` and Data slices carry no alignment promise.
            UInt32(bytes[offset]) | UInt32(bytes[offset + 1]) << 8
                | UInt32(bytes[offset + 2]) << 16 | UInt32(bytes[offset + 3]) << 24
        }

        let version = word(8)
        guard version == formatVersion else {
            throw Failure.malformed("format version \(version), expected \(formatVersion)")
        }
        let tourCount = Int(word(12))
        let chunkCount = Int(word(16))
        let dims = Int(word(20))
        let flags = word(24)
        let scale = Float(bitPattern: word(28))

        guard dims == QueryEmbedder.dimensions else {
            throw Failure.malformed("\(dims) dims, the app embeds \(QueryEmbedder.dimensions)")
        }
        guard flags & flagInt8 != 0 else {
            throw Failure.malformed("index is not int8 — this reader only handles int8")
        }
        guard scale.isFinite, scale > 0 else {
            throw Failure.malformed("quantization scale is \(scale)")
        }

        let modelID = String(
            decoding: bytes[32..<96].prefix(while: { $0 != 0 }), as: UTF8.self
        )
        guard modelID == QueryEmbedder.expectedModelID else {
            throw Failure.modelMismatch(
                expected: QueryEmbedder.expectedModelID, found: modelID
            )
        }

        // 🔴 Every size is checked against the file's real length before any of
        // it is read. A truncated download otherwise reads whatever follows in
        // memory and produces rankings from garbage.
        let idsStart = headerSize
        let offsetsStart = idsStart + tourCount * 16
        let chunksStart = offsetsStart + tourCount * 4
        let expected = chunksStart + chunkCount * dims
        guard bytes.count == expected else {
            throw Failure.malformed(
                "expected \(expected) bytes for \(tourCount) tours × \(chunkCount) "
                + "chunks × \(dims) dims, found \(bytes.count)"
            )
        }

        var tourIDs: [UUID] = []
        tourIDs.reserveCapacity(tourCount)
        for index in 0..<tourCount {
            let base = idsStart + index * 16
            tourIDs.append(UUID(uuid: (
                bytes[base], bytes[base + 1], bytes[base + 2], bytes[base + 3],
                bytes[base + 4], bytes[base + 5], bytes[base + 6], bytes[base + 7],
                bytes[base + 8], bytes[base + 9], bytes[base + 10], bytes[base + 11],
                bytes[base + 12], bytes[base + 13], bytes[base + 14], bytes[base + 15]
            )))
        }

        // n+1 offsets: the last is the total, so a tour's chunk count is always
        // `offsets[i+1] - offsets[i]` with no special case for the final tour.
        var offsets: [Int] = []
        offsets.reserveCapacity(tourCount + 1)
        for index in 0..<tourCount {
            offsets.append(Int(word(offsetsStart + index * 4)))
        }
        offsets.append(chunkCount)
        for index in 0..<tourCount where offsets[index] > offsets[index + 1] {
            throw Failure.malformed("chunk offsets are not ascending at tour \(index)")
        }

        // Dequantize and re-normalise, exactly as the parity check's "device
        // side" does: `int8 / scale`, then unit length. Normalising after
        // dequantizing matters — rounding moves the length off 1.
        var chunks = [Float](repeating: 0, count: chunkCount * dims)
        for chunk in 0..<chunkCount {
            let base = chunksStart + chunk * dims
            var sumOfSquares: Float = 0
            for component in 0..<dims {
                let value = Float(Int8(bitPattern: bytes[base + component])) / scale
                chunks[chunk * dims + component] = value
                sumOfSquares += value * value
            }
            let length = max(sumOfSquares.squareRoot(), 1e-12)
            for component in 0..<dims {
                chunks[chunk * dims + component] /= length
            }
        }

        return Index(
            tourIDs: tourIDs, chunkOffsets: offsets, chunks: chunks,
            dims: dims, modelID: modelID
        )
    }

    // MARK: - Scoring

    struct Match {
        let tourID: UUID
        let score: Float
        /// The sentence from the chunk that scored best, when snippets are
        /// loaded and that chunk has one. nil is ordinary, not an error: an
        /// older index has no snippet file, and ~0.6% of chunks contain no
        /// whole sentence to quote.
        let snippet: String?
    }

    /// The `limit` best-scoring tours above `floor`.
    ///
    /// 🔴 THIS IS `tour_scores` FROM `build-embeddings.py`, RE-IMPLEMENTED.
    /// That function's own docstring says "THIS IS THE FUNCTION THE APP
    /// RE-IMPLEMENTS… keep this in step with the Swift side". The blend, the
    /// weight and the handling of a tour with no chunks all have to match, or
    /// the two rank differently with nothing to say so.
    func search(_ query: [Float], limit: Int, floor: Float) throws -> [Match] {
        guard let index else { throw Failure.notDownloaded }
        guard query.count == index.dims else {
            throw Failure.malformed("query is \(query.count) dims, index is \(index.dims)")
        }

        var matches: [Match] = []
        let dims = index.dims
        for tour in 0..<index.tourIDs.count {
            let start = index.chunkOffsets[tour]
            let end = index.chunkOffsets[tour + 1]
            // Python leaves a chunkless tour at 0.0 rather than skipping it.
            guard end > start else { continue }

            var best = -Float.greatestFiniteMagnitude
            var bestChunk = start
            var total: Float = 0
            for chunk in start..<end {
                var similarity: Float = 0
                let base = chunk * dims
                for component in 0..<dims {
                    similarity += index.chunks[base + component] * query[component]
                }
                if similarity > best {
                    best = similarity
                    // The chunk that won is the one worth quoting — it is the
                    // part of the narration the query actually matched.
                    bestChunk = chunk
                }
                total += similarity
            }
            let mean = total / Float(end - start)
            let score = Self.bestChunkWeight * best
                + (1 - Self.bestChunkWeight) * mean

            // ⚠️ `>=`, not `<` negated the other way round: a NaN score must
            // fail this, and `nan >= floor` is false. `QueryEmbedder` already
            // refuses a non-finite query, but a score is a second chance for
            // one to appear and the cost of the guard is nothing.
            if score >= floor {
                matches.append(Match(
                    tourID: index.tourIDs[tour],
                    score: score,
                    snippet: snippet(at: bestChunk)
                ))
            }
        }

        matches.sort { $0.score > $1.score }
        return Array(matches.prefix(limit))
    }
}
