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
        case results([Tour])
        /// 🔴 A FAILURE IS A STATE THE VIEW SHOWS NOTHING FOR. It is kept
        /// rather than discarded so it can be logged and so a retry knows not
        /// to hammer a download that is failing, not so it can be displayed.
        case unavailable(String)
    }

    private(set) var state: State = .idle

    /// Below this, a query is letters rather than meaning, and the model
    /// returns noise with great confidence.
    static let minimumQueryLength = 3
    /// How many smart matches to show. Deliberately short: this section is a
    /// second opinion under a full keyword list, not a second list.
    static let resultLimit = 6
    /// `RELATED_FLOOR` in build-embeddings.py. The same number that decides
    /// whether "More like this" shows a neighbour decides whether a smart
    /// match is worth showing — it was chosen by looking at real pairs.
    static let scoreFloor: Float = 0.45

    private let store = TourEmbeddingStore()
    private let loader = SearchModelLoader()
    private var embedder: QueryEmbedder?
    private var searchTask: Task<Void, Never>?
    /// Set once a load has failed, so a failing download is attempted once per
    /// session rather than once per keystroke.
    private var loadFailure: String?

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
        if let loadFailure {
            state = .unavailable(loadFailure)
            return
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
        let needsPreparing = embedder == nil || !(await store.isLoaded)
        state = needsPreparing ? .preparing : .searching

        do {
            try await prepare()
        } catch {
            // Recorded once. A download that is failing will keep failing for
            // the same reason, and retrying it per keystroke would be the
            // worst version of that.
            let why = "\(error)"
            loadFailure = why
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
            let tours = matches
                // ⚠️ An id in the index that is not in the catalogue is normal,
                // not an error: the index is rebuilt on a content merge and a
                // phone may hold an older catalogue for a while. Skip it.
                .compactMap { byID[$0.tourID] }
            state = .results(tours)
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
        if await !store.isLoaded {
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

    static let remoteURL = URL(
        string: "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/search/AtlasQueryEmbedder.mlpackage.aar"
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

        // The field set has to include the ones that make a directory tree a
        // directory tree: without PAT (path) and TYP (entry type) the extractor
        // has nothing to rebuild.
        guard let selection = ArchiveHeader.FieldKeySet("TYP,PAT,LNK,DEV,DAT,UID,GID,MOD,FLG,MTM,BTM,CTM") else {
            throw SearchModelLoader.Failure.unpack("could not build the field selection")
        }
        guard let extractor = ArchiveStream.extractStream(
            extractingTo: FilePath(destination.path),
            flags: [.ignoreOperationNotPermitted],
            selectUsing: selection
        ) else {
            throw SearchModelLoader.Failure.unpack("could not open the destination")
        }
        defer { try? extractor.close() }

        _ = try ArchiveStream.process(readingFrom: decoded, writingTo: extractor)
    }
}
