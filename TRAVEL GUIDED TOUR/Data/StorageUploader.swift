import Foundation

/// Uploads a file to Supabase Storage over a plain `URLSession`, reporting real
/// byte progress as it goes.
///
/// **Why not just use the SDK.** `supabase-swift` 2.48's
/// `storage.from(_:).upload(_:data:options:)` returns only when the whole
/// transfer finishes — it exposes no progress callback. That is fine for a
/// 200 KB photo and wrong for narration, which is the largest thing this app
/// ever sends: a maker who has just recorded three minutes watches an
/// indeterminate spinner with no idea whether it is nearly done or stalled.
///
/// So audio goes through this instead, hitting the same REST endpoint the SDK
/// does (`POST /storage/v1/object/{bucket}/{path}` with `x-upsert`) and using
/// `URLSessionTaskDelegate.didSendBodyData` for the byte counts. Photos keep
/// using the SDK — they are small, and "3 of 5" is the honest unit there anyway.
///
/// **Not a background session.** Uploads survive moving around inside the app,
/// not the app being killed. True background upload needs a background
/// `URLSession` with its own delegate lifecycle and completion handling, which
/// is a materially larger piece of work — deliberately scoped out rather than
/// half-built.
final class StorageUploader: NSObject, @unchecked Sendable {

    /// Fractional progress, 0...1. Called on the main actor.
    typealias ProgressHandler = @Sendable (Double) -> Void

    enum UploadError: LocalizedError {
        case notSignedIn
        case badResponse(status: Int)

        var errorDescription: String? {
            switch self {
            case .notSignedIn:
                return "You're signed out. Sign in and try again."
            case .badResponse(let status):
                return "The upload was rejected (\(status))."
            }
        }
    }

    private var handlers: [Int: ProgressHandler] = [:]
    private let lock = NSLock()
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        // Narration over a phone connection: generous, but not infinite.
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 600
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    /// Upload `data` and return its public URL.
    ///
    /// `accessToken` is the caller's Supabase session token — Storage RLS scopes
    /// the write by the leading `{maker_id}` path segment, so an anonymous or
    /// stale token is rejected server-side rather than silently writing
    /// somewhere it shouldn't.
    func upload(
        data: Data,
        bucket: String,
        path: String,
        contentType: String,
        accessToken: String,
        onProgress: @escaping ProgressHandler
    ) async throws -> String {
        var request = URLRequest(
            url: SupabaseConfig.projectURL
                .appendingPathComponent("storage/v1/object")
                .appendingPathComponent(bucket)
                .appendingPathComponent(path)
        )
        request.httpMethod = "POST"
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        // Re-recording replaces the previous take rather than accumulating
        // orphans under the same tour.
        request.setValue("true", forHTTPHeaderField: "x-upsert")

        let (responseData, response) = try await performUpload(
            request: request, body: data, onProgress: onProgress
        )

        guard let http = response as? HTTPURLResponse else {
            throw UploadError.badResponse(status: -1)
        }
        guard (200..<300).contains(http.statusCode) else {
            // Surface the server's own message when there is one — it is far
            // more useful than the status code alone while debugging RLS.
            if let text = String(data: responseData, encoding: .utf8), !text.isEmpty {
                throw NSError(domain: "StorageUploader", code: http.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: text])
            }
            throw UploadError.badResponse(status: http.statusCode)
        }

        return SupabaseConfig.projectURL
            .appendingPathComponent("storage/v1/object/public")
            .appendingPathComponent(bucket)
            .appendingPathComponent(path)
            .absoluteString
    }

    /// Runs the upload task, registering the progress handler against the task's
    /// identifier so the delegate can find it. Registration happens *before*
    /// `resume()`, or a fast first chunk can report against a handler that isn't
    /// there yet and the bar never moves.
    private func performUpload(
        request: URLRequest,
        body: Data,
        onProgress: @escaping ProgressHandler
    ) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = session.uploadTask(with: request, from: body) { data, response, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let response {
                    continuation.resume(returning: (data ?? Data(), response))
                } else {
                    continuation.resume(throwing: UploadError.badResponse(status: -1))
                }
            }
            lock.lock()
            handlers[task.taskIdentifier] = onProgress
            lock.unlock()
            task.resume()
        }
    }
}

extension StorageUploader: URLSessionTaskDelegate {

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didSendBodyData bytesSent: Int64,
                    totalBytesSent: Int64,
                    totalBytesExpectedToSend: Int64) {
        guard totalBytesExpectedToSend > 0 else { return }
        lock.lock()
        let handler = handlers[task.taskIdentifier]
        lock.unlock()
        guard let handler else { return }
        let fraction = min(1, Double(totalBytesSent) / Double(totalBytesExpectedToSend))
        Task { @MainActor in handler(fraction) }
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        lock.lock()
        handlers[task.taskIdentifier] = nil
        lock.unlock()
    }
}
