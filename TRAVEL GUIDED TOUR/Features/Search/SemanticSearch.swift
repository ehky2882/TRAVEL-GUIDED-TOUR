import AppleArchive
import CoreML
import Foundation
import System

/// Semantic search: the model, the index, and the state a view binds to.
///
/// 🔴 THIS IS ADDITIVE AND MUST STAY THAT WAY. Keyword results are computed
/// synchronously from an in-memory index and are what people already rely on.
/// Nothing here may delay them, and every failure below — no network, no model,
/// a stale index, a refused download — resolves to "no smart section", which is
/// exactly today's behaviour. Search degrading to what it already does is a
/// working outcome; a spinner that never resolves is not.
///
/// ⚠️ THE MODEL IS DOWNLOADED, NOT BUNDLED (owner decision, 2026-09-16). It is
/// ~42 MB, and putting it in the app would add that to the App Store download
/// for everyone including people who never search. gh-pages already serves the
/// audio and the images, so it costs no Supabase egress. Reversible: it changes
/// only where `SearchModelLoader` looks.
@Observable
@MainActor
final class SemanticSearch {

    /// What the view renders. Every case is a finished state except `.loading`.
    enum State {
        /// Nothing typed, or the query is too short to mean anything.
        case idle
        /// Fetching the model or the index. First search only.
        case preparing
        case searching
        case results([Result])
        /// 🔴 A FAILURE IS A STATE THE VIEW SHOWS NOTHING FOR. It is kept
        /// rather than discarded so it can be logged and so a retry knows not
        /// to hammer a download that is failing, not so it can be displayed.
        case unavailable(String)
    }

    /// A tour, plus the sentence that explains why it matched.
    ///
    /// ⚠️ `snippet` is optional and its absence is ordinary — an older index
    /// has no snippet file, and a small share of chunks contain no whole
    /// sentence worth quoting. The row simply renders without one.
    struct Result: Identifiable {
        let tour: Tour
        let snippet: String?
        var id: Tour.ID { tour.id }
    }

    private(set) var state: State = .idle

    /// Below this, a query is letters rather than meaning, and the model
    /// returns noise with great confidence.
    static let minimumQueryLength = 3
    /// How many smart matches to show. Deliberately short: this section is a
    /// second opinion under a full keyword list, not a second list.
    static let resultLimit = 6
    /// 🔴 NOT `RELATED_FLOOR`, AND THE DIFFERENCE IS THE WHOLE POINT.
    ///
    /// This was 0.45, copied from the floor "More like this" uses — and that was
    /// a category error that shipped. `RELATED_FLOOR` compares **two tours**:
    /// mean-to-mean, two long documents, which score high against each other by
    /// construction. This compares a **short typed query** against a long
    /// document, which scores far lower for the same quality of match. Same
    /// number, different measurement, and reusing it looked like consistency.
    ///
    /// At 0.45, measured on the live index, three of nine natural queries
    /// returned NOTHING — including the owner's own first try on build 166:
    ///
    ///     quiet garden away              top 0.4498   (missed by 0.0002)
    ///     quiet garden away from crowds  top 0.4136
    ///     stained glass windows          top 0.4479
    ///     somewhere romantic for a date  top 0.4323
    ///     art deco lobby                 top 0.5444   (6 results)
    ///     brutalist concrete tower       top 0.6455   (46 results)
    ///
    /// ⚠️ A CLEVERER RULE WAS TRIED AND DOES NOT EXIST — do not re-attempt it.
    /// "quiet garden away" (good results) and "stained glass windows" (weak
    /// ones) top out at 0.4498 and 0.4479: indistinguishable. What separates
    /// them is what the catalogue contains, which no score can see, and a
    /// relative rule ("within 0.08 of the best") fires identically on both.
    ///
    /// 0.35 is measured too — a lower floor still has to stay quiet when it
    /// should. Nonsense ("asdfgh qwerty zxcvb", top 0.3361), "my tax return"
    /// (0.2392) and "how do i reset my password" (0.1376) all return nothing,
    /// while "somewhere romantic for a date" starts working.
    static let scoreFloor: Float = 0.35

    private let store = TourEmbeddingStore()
    private let loader = SearchModelLoader()
    private var embedder: QueryEmbedder?
    private var searchTask: Task<Void, Never>?
    /// The last load failure and when it happened.
    ///
    /// ⚠️ A COOLDOWN, NOT A LATCH. Retrying a 42 MB download on every keystroke
    /// would be the worst version of failing; never retrying it would be almost
    /// as bad, because the commonest reason to fail is being briefly offline,
    /// and that resolves on its own. So a failure is remembered for a minute
    /// and then allowed to try again.
    private var loadFailure: (why: String, at: Date)?
    private static let retryAfter: TimeInterval = 60

    // MARK: - Driving it

    /// Called on every keystroke. Debounced; safe to call as often as SwiftUI
    /// wants to.
    /// ⚠️ TAKES NO EXCLUSION LIST, ON PURPOSE. Which tours the keyword list is
    /// already showing is a rendering question, answered in the view where that
    /// list is in hand. Passing it here would mean re-deriving `filteredTours`
    /// outside `SearchResults`, which is the exact "derive once, use many"
    /// mistake SearchView has now paid for three times.
    func update(query: String, catalog: [Tour]) {
        searchTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= Self.minimumQueryLength else {
            state = .idle
            return
        }
        if let failure = loadFailure {
            if Date().timeIntervalSince(failure.at) < Self.retryAfter {
                state = .unavailable(failure.why)
                return
            }
            loadFailure = nil
        }

        searchTask = Task { [weak self] in
            // Typing is faster than a model. Let the keystrokes settle before
            // spending anything — and `Task.sleep` throws on cancellation, so
            // a superseded search stops here rather than at the far end.
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            await self?.run(trimmed, catalog: catalog)
        }
    }

    func cancel() {
        searchTask?.cancel()
        state = .idle
    }

    private func run(_ query: String, catalog: [Tour]) async {
        // ⚠️ Not `embedder == nil || !(await store.isLoaded)`. `||` takes its
        // right side as an autoclosure, which cannot await — and the
        // short-circuit is worthless here anyway.
        let indexReady = await store.isLoaded
        let needsPreparing = embedder == nil || !indexReady
        state = needsPreparing ? .preparing : .searching

        do {
            try await prepare()
        } catch {
            let why = "\(error)"
            loadFailure = (why, Date())
            state = .unavailable(why)
            return
        }
        guard !Task.isCancelled else { return }

        do {
            guard let embedder, let vector = try await embedder.vector(for: query) else {
                state = .idle
                return
            }
            let matches = try await store.search(
                vector,
                // Deeper than the section shows, because the view drops the
                // ones the keyword list is already displaying. Without the
                // headroom a good query whose top matches are all above would
                // render an empty section for no visible reason.
                limit: Self.resultLimit * 4,
                floor: Self.scoreFloor
            )
            guard !Task.isCancelled else { return }

            let byID = Dictionary(catalog.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            let results = matches
                // ⚠️ An id in the index that is not in the catalogue is normal,
                // not an error: the index is rebuilt on a content merge and a
                // phone may hold an older catalogue for a while. Skip it.
                .compactMap { match in
                    byID[match.tourID].map { Result(tour: $0, snippet: match.snippet) }
                }
            state = .results(results)
        } catch {
            state = .unavailable("\(error)")
        }
    }

    /// Fetch and open both halves. Idempotent — after the first success it
    /// does nothing.
    private func prepare() async throws {
        if embedder == nil {
            let model = try await loader.model()
            let tokenizer = try WordPieceTokenizer.bundled()
            embedder = try QueryEmbedder(model: model, tokenizer: tokenizer)
        }
        if !(await store.isLoaded) {
            // Cache first: the index is ~3.8 MB and re-downloading it on every
            // launch would be the kind of quiet cost this project has twice
            // been emailed about.
            do {
                try await store.loadFromCache()
            } catch {
                try await store.download()
            }
        }
    }
}

/// Downloads, caches and compiles the Core ML query embedder.
///
/// 🔴 THE ARTIFACT IS AN APPLE ARCHIVE (`.aar`), NOT A ZIP, AND THAT IS FORCED.
/// A `.mlpackage` is a DIRECTORY, so it has to travel as one file — and iOS has
/// no public API for reading a zip. The project allows Apple frameworks only
/// (see CLAUDE.md § Conventions), so a third-party unzip is not an option and
/// hand-rolling one over `Compression` would be a few hundred lines of format
/// parsing standing between the app and its search index.
///
/// `AppleArchive` is Apple's own answer to exactly this, shipped since iOS 14,
/// and `aa archive` on the macOS runner writes it. So the export workflow
/// publishes `.aar` and this extracts it. The alternative — publishing the
/// package's files individually and reassembling them — would mean the app
/// knowing the internal layout of a `.mlpackage`, which is Core ML's business
/// and not ours.
///
/// ⚠️ COMPILED ON DEVICE, DELIBERATELY. `MLModel.compileModel(at:)` could have
/// been run on the Mac runner instead, shipping a ready `.mlmodelc` and saving
/// a moment on first search. A compiled model is tied to what compiled it; the
/// package is the portable form, and one slow first search is a far better
/// trade than a model that fails to load on some future OS.
actor SearchModelLoader {

    enum Failure: Error, CustomStringConvertible {
        case download(Int)
        case unpack(String)

        var description: String {
            switch self {
            case .download(let code): "could not download the search model (HTTP \(code))"
            case .unpack(let why): "could not open the search model: \(why)"
            }
        }
    }

    /// 🔴 THE VERSION IN THIS URL IS LOAD-BEARING, AND IT IS PINNED ON PURPOSE.
    /// The model is fetched once, compiled once, and then read off this phone's
    /// own disk forever — so swapping the bytes behind an unchanged URL would
    /// reach nobody who had already searched. That is the same rule
    /// CLAUDE.md § Image Pipeline step 9 was written for, and paid for.
    ///
    /// A new model therefore means a new tag AND a change to this line, which
    /// is correct rather than inconvenient: a new model needs a new index, and
    /// the two must move together or every ranking is quietly wrong.
    ///
    /// ⚠️ A RELEASE ASSET, NOT gh-pages. Both are free of Supabase egress, but
    /// a git branch keeps what it is given: 42 MB per export would accumulate
    /// in gh-pages history forever, on a branch whose clone already times out.
    static let remoteURL = URL(
        string: "https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/releases/download/"
            + "search-model-v1/AtlasQueryEmbedder.mlpackage.aar"
    )!

    private var loaded: MLModel?

    private var compiledURL: URL {
        URL.cachesDirectory.appending(path: "AtlasQueryEmbedder.mlmodelc")
    }

    func model() async throws -> MLModel {
        if let loaded { return loaded }

        if !FileManager.default.fileExists(atPath: compiledURL.path) {
            try await downloadAndCompile()
        }
        let model = try MLModel(contentsOf: compiledURL)
        loaded = model
        return model
    }

    private func downloadAndCompile() async throws {
        let (temporary, response) = try await URLSession.shared.download(from: Self.remoteURL)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw Failure.download(http.statusCode)
        }

        let fileManager = FileManager.default
        let workspace = fileManager.temporaryDirectory
            .appending(path: "atlas-model-\(UUID().uuidString)")
        try fileManager.createDirectory(at: workspace, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: workspace) }

        let archive = workspace.appending(path: "model.aar")
        try fileManager.moveItem(at: temporary, to: archive)

        let unpacked = workspace.appending(path: "unpacked")
        try fileManager.createDirectory(at: unpacked, withIntermediateDirectories: true)
        try AppleArchiveUnpacker.extract(archive, into: unpacked)

        guard let package = try fileManager.contentsOfDirectory(
            at: unpacked, includingPropertiesForKeys: nil
        ).first(where: { $0.pathExtension == "mlpackage" }) else {
            throw Failure.unpack("the archive contains no .mlpackage")
        }

        // Core ML compiles to a temporary location that is deleted when the
        // process exits, so the result is moved into Caches to survive.
        let compiled = try await MLModel.compileModel(at: package)
        try? fileManager.removeItem(at: compiledURL)
        try fileManager.moveItem(at: compiled, to: compiledURL)
    }
}

/// Unpacks an `.aar` produced by `aa archive`, using Apple's own framework.
///
/// Kept separate from the loader because it is pure plumbing with no opinion
/// about Core ML, and because the stream-of-streams shape below is easy to get
/// subtly wrong and worth reading on its own.
enum AppleArchiveUnpacker {

    static func extract(_ archive: URL, into destination: URL) throws {
        guard let readStream = ArchiveByteStream.fileStream(
            path: FilePath(archive.path),
            mode: .readOnly,
            options: [],
            permissions: FilePermissions(rawValue: 0o644)
        ) else {
            throw SearchModelLoader.Failure.unpack("could not open the archive")
        }
        defer { try? readStream.close() }

        // LZFSE is what `aa archive` writes by default and what the export
        // workflow asks for explicitly.
        guard let decompressed = ArchiveByteStream.decompressionStream(
            readingFrom: readStream
        ) else {
            throw SearchModelLoader.Failure.unpack("could not decompress the archive")
        }
        defer { try? decompressed.close() }

        guard let decoded = ArchiveStream.decodeStream(readingFrom: decompressed) else {
            throw SearchModelLoader.Failure.unpack("could not decode the archive")
        }
        defer { try? decoded.close() }

        // ⚠️ NO FIELD SELECTION. A `FieldKeySet` belongs to `encodeStream`,
        // which chooses what to WRITE; extraction's `selectUsing` is an entry
        // filter closure, and every field the archive carries is one the
        // package needs. `.ignoreOperationNotPermitted` is what lets the
        // extraction survive an owner or permission field it cannot honour in
        // the app's sandbox, which is every one of them.
        guard let extractor = ArchiveStream.extractStream(
            extractingTo: FilePath(destination.path),
            flags: [.ignoreOperationNotPermitted]
        ) else {
            throw SearchModelLoader.Failure.unpack("could not open the destination")
        }
        defer { try? extractor.close() }

        _ = try ArchiveStream.process(readingFrom: decoded, writingTo: extractor)
    }
}
