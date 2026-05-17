import Foundation
import Observation

/// Tour download manager — spec § Flow 2 (offline listening) and
/// roadmap M-offline.
///
/// V1 design choices:
///   - **Foreground `URLSession`.** Downloads run while the app is
///     foregrounded (or briefly backgrounded with the system's grace
///     window). Our V1 tours are a handful of short MP3s, so this is
///     plenty fast; a background-aware upgrade is a polish item.
///   - **One tour at a time.** Tapping Download on tour B while A is
///     downloading is a no-op; the UI shows the Download button
///     disabled for B until A finishes. Matches Spotify/Audible.
///   - **Documents directory.** Cached files live at
///     `<documents>/atlas-tours/<tour-uuid>/<file>` so they persist
///     across launches and survive iOS cache eviction. Files are
///     deleted when the user explicitly removes the download or the
///     app itself is removed.
///   - **Sequential within-tour downloads.** Files (intro + each
///     stop) are downloaded one after another. Simpler progress
///     tracking; finishes in the same wall time for V1's small
///     payloads since the bottleneck is per-file.
///
/// This service owns the file storage and state. It does **not**
/// touch `LibraryStore` directly — views observe `states[tour.id]`
/// and write `markDownloaded` / `clearDownload` themselves. This
/// keeps both shelves on the app environment without an init-order
/// dependency between them.
@Observable
final class TourDownloader: NSObject, URLSessionDownloadDelegate {

    enum DownloadState: Equatable {
        case idle
        case downloading(progress: Double)
        case completed
        case failed(message: String)
    }

    /// Per-tour state, observable by views.
    private(set) var states: [UUID: DownloadState] = [:]
    /// Which tour is currently downloading, if any. The single-active
    /// rule is enforced by checking this in `download(tour:)`.
    private(set) var activeTourId: UUID?

    /// Backing for `session`. Set in `init`; `!` is safe because
    /// we initialize it before `super.init()` would return.
    private var session: URLSession!

    /// Files queued for the active tour. Each tuple: a stable name
    /// used as the on-disk filename (`intro` or stop-UUID) and the
    /// remote URL to fetch.
    private var pendingFiles: [(name: String, url: URL)] = []
    /// How many files we'd queued in total for the active tour —
    /// used to compute aggregate progress as files complete.
    private var totalActiveFiles: Int = 0
    private var completedActiveFileCount: Int = 0
    private var currentTask: URLSessionDownloadTask?
    private var currentFileWrittenBytes: Int64 = 0
    private var currentFileExpectedBytes: Int64 = 0

    override init() {
        super.init()
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
        loadExistingStates()
    }

    // MARK: - Public API

    /// Queue a tour for download. Returns false if another download is
    /// already running, or if the tour is already fully downloaded.
    @discardableResult
    func download(tour: Tour) -> Bool {
        guard activeTourId == nil else { return false }
        if case .completed = states[tour.id] { return false }

        activeTourId = tour.id
        states[tour.id] = .downloading(progress: 0.0)

        pendingFiles = []
        if let urlString = tour.introAudioURL, let url = URL(string: urlString) {
            pendingFiles.append((name: "intro", url: url))
        }
        for stop in tour.stops {
            if let url = URL(string: stop.audioURL) {
                pendingFiles.append((name: stop.id.uuidString, url: url))
            }
        }
        totalActiveFiles = pendingFiles.count
        completedActiveFileCount = 0

        guard !pendingFiles.isEmpty else {
            // Nothing to download — treat as completed.
            finishActiveDownload()
            return true
        }

        do {
            try FileManager.default.createDirectory(
                at: tourFolder(for: tour.id),
                withIntermediateDirectories: true
            )
        } catch {
            failActiveDownload(message: "Could not create download folder.")
            return false
        }

        startNextFile()
        return true
    }

    /// Cancel an in-progress download. Removes any partial files
    /// already written for that tour.
    func cancel(tourId: UUID) {
        guard activeTourId == tourId else { return }
        currentTask?.cancel()
        cleanUpPartial(tourId: tourId)
        states[tourId] = .idle
        resetActiveBookkeeping()
    }

    /// Remove a previously-downloaded tour from disk. Caller is
    /// responsible for also calling `libraryStore.clearDownload(tourId)`
    /// so the Downloaded section in Library reflects the change.
    func deleteDownload(tourId: UUID) {
        try? FileManager.default.removeItem(at: tourFolder(for: tourId))
        states[tourId] = .idle
    }

    func isDownloaded(tourId: UUID) -> Bool {
        if case .completed = states[tourId] { return true }
        return false
    }

    func progress(tourId: UUID) -> Double? {
        if case .downloading(let p) = states[tourId] { return p }
        return nil
    }

    /// Local file URL for a tour's intro audio, if downloaded.
    func localURL(forIntroOf tour: Tour) -> URL? {
        guard isDownloaded(tourId: tour.id), tour.introAudioURL != nil else { return nil }
        return findFile(in: tourFolder(for: tour.id), baseName: "intro")
    }

    /// Local file URL for a specific stop's audio, if its tour is
    /// downloaded. Falls back to nil for non-downloaded tours so the
    /// caller can use the remote URL instead.
    func localURL(forStop stop: Stop, in tour: Tour) -> URL? {
        guard isDownloaded(tourId: tour.id) else { return nil }
        return findFile(in: tourFolder(for: tour.id), baseName: stop.id.uuidString)
    }

    func diskUsage(tourId: UUID) -> Int64 {
        let folder = tourFolder(for: tourId)
        guard let enumerator = FileManager.default.enumerator(
            at: folder,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else { return 0 }
        var total: Int64 = 0
        for case let url as URL in enumerator {
            if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                total += Int64(size)
            }
        }
        return total
    }

    func allDownloadedTourIds() -> [UUID] {
        let root = atlasRoot()
        guard let entries = try? FileManager.default.contentsOfDirectory(atPath: root.path) else {
            return []
        }
        return entries.compactMap { UUID(uuidString: $0) }
    }

    // MARK: - Download state machine

    private func startNextFile() {
        guard activeTourId != nil else { return }
        guard let next = pendingFiles.first else {
            finishActiveDownload()
            return
        }

        currentFileExpectedBytes = 0
        currentFileWrittenBytes = 0

        let task = session.downloadTask(with: next.url)
        currentTask = task
        task.resume()
    }

    private func finishActiveDownload() {
        guard let tourId = activeTourId else { return }
        states[tourId] = .completed
        resetActiveBookkeeping()
        // Views observing `states[tourId]` are responsible for
        // calling `libraryStore.markDownloaded(tourId)` so the
        // Library → Downloaded section updates.
    }

    private func failActiveDownload(message: String) {
        guard let tourId = activeTourId else { return }
        cleanUpPartial(tourId: tourId)
        states[tourId] = .failed(message: message)
        resetActiveBookkeeping()
    }

    private func resetActiveBookkeeping() {
        activeTourId = nil
        pendingFiles = []
        totalActiveFiles = 0
        completedActiveFileCount = 0
        currentTask = nil
        currentFileWrittenBytes = 0
        currentFileExpectedBytes = 0
    }

    private func cleanUpPartial(tourId: UUID) {
        try? FileManager.default.removeItem(at: tourFolder(for: tourId))
    }

    private func recomputeProgress() {
        guard let tourId = activeTourId, totalActiveFiles > 0 else { return }
        let perFile = 1.0 / Double(totalActiveFiles)
        let completedPortion = Double(completedActiveFileCount) * perFile
        let currentPortion: Double
        if currentFileExpectedBytes > 0 {
            currentPortion = perFile * (Double(currentFileWrittenBytes) / Double(currentFileExpectedBytes))
        } else {
            currentPortion = 0
        }
        states[tourId] = .downloading(progress: min(completedPortion + currentPortion, 1.0))
    }

    // MARK: - Paths

    private func atlasRoot() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let root = docs.appendingPathComponent("atlas-tours", isDirectory: true)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    private func tourFolder(for tourId: UUID) -> URL {
        atlasRoot().appendingPathComponent(tourId.uuidString, isDirectory: true)
    }

    private func findFile(in folder: URL, baseName: String) -> URL? {
        guard let entries = try? FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: nil
        ) else { return nil }
        return entries.first { $0.deletingPathExtension().lastPathComponent == baseName }
    }

    private func loadExistingStates() {
        for tourId in allDownloadedTourIds() {
            states[tourId] = .completed
        }
    }

    // MARK: - URLSessionDownloadDelegate

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let tourId = activeTourId, let next = pendingFiles.first else { return }

        let folder = tourFolder(for: tourId)
        let ext = next.url.pathExtension.isEmpty ? "mp3" : next.url.pathExtension
        let destination = folder.appendingPathComponent("\(next.name).\(ext)")

        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: location, to: destination)
        } catch {
            failActiveDownload(message: "Could not save \(next.name): \(error.localizedDescription)")
            return
        }

        pendingFiles.removeFirst()
        completedActiveFileCount += 1
        // Reset per-file byte counters BEFORE recomputing — otherwise
        // the just-finished file's `written == expected` contributes a
        // full `perFile` to currentPortion on top of the bumped
        // completedPortion, causing the progress ring to overshoot
        // and then snap back when the next file starts at 0 bytes.
        currentFileWrittenBytes = 0
        currentFileExpectedBytes = 0
        recomputeProgress()
        startNextFile()
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        currentFileWrittenBytes = totalBytesWritten
        currentFileExpectedBytes = totalBytesExpectedToWrite
        recomputeProgress()
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        // Successful completion is handled in didFinishDownloadingTo.
        // We only care here about errors. Cancellations come through
        // as NSURLErrorCancelled; treat them as a no-op since
        // `cancel(tourId:)` already cleaned up state.
        guard let error else { return }
        if (error as NSError).code == NSURLErrorCancelled { return }
        failActiveDownload(message: error.localizedDescription)
    }
}
