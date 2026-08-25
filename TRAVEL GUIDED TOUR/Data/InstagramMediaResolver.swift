import Foundation

/// Resolves an Instagram post to the video file behind it, so a Reel can play
/// inline in Atlas's own player instead of sending the viewer to Instagram.
///
/// 🔴 WHY THIS EXISTS AT ALL — the embed cannot be made to play.
///
/// Instagram's embed serves a **static poster wrapped in a link**: an
/// `<img class="EmbeddedMediaImage">` inside an `<a class="EmbeddedMedia">`,
/// plus a `PlayButtonSprite` that is a CSS sprite rather than a control.
/// There is no `<video>` element in it. A player only exists if Instagram's
/// own JavaScript builds one after load, inside a cross-origin frame we are
/// not permitted to script — so from outside, a tap either navigates to
/// Instagram or does nothing. Both were shipped and both were wrong.
///
/// ⚠️ TikTok and YouTube are NOT resolved this way and must not be. They serve
/// real players that work embedded, and TikTok's API exposes no video-file
/// field at all. This is an Instagram-shaped answer to an Instagram-shaped
/// problem.
///
/// 🔴 THE URL CANNOT BE STORED. The file is signed with an `oe` expiry a few
/// days out, so a URL written into `Tours.json` would be dead before anyone
/// walked past the pin. It has to be resolved at play time, which is why this
/// is a runtime lookup rather than something the authoring tool bakes in.
///
/// ⚠️ This reads keys out of Instagram's page HTML. They are internal and can
/// be renamed without notice, so **every failure path returns nil** and the
/// caller falls back to the poster-and-link embed. A broken resolve must
/// degrade the pin, never break it.
@MainActor
@Observable
final class InstagramMediaResolver {

    /// Resolved media, keyed by post URL. Session-lifetime only: the signed
    /// URL expires in days, and a cache that outlived the app would hand back
    /// a dead link on the next launch.
    private var cache: [String: URL] = [:]
    /// Posts already tried and failed, so a private or deleted post doesn't
    /// re-fetch the page on every re-render of the detail view.
    private var failed: Set<String> = []

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// The playable file for a post, or nil when we cannot get one.
    /// - Parameter postURL: the canonical post URL stored on the pin.
    func mediaURL(for postURL: String) async -> URL? {
        if let hit = cache[postURL] { return hit }
        if failed.contains(postURL) { return nil }

        guard let embed = Self.embedURL(for: postURL) else {
            failed.insert(postURL)
            return nil
        }
        var request = URLRequest(url: embed)
        // Instagram serves the desktop shell to an unknown agent; this is the
        // same page a browser is given, and it is where the payload lives.
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 26_0 like Mac OS X) "
            + "AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148",
            forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 20

        guard let (data, response) = try? await session.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let html = String(data: data, encoding: .utf8),
              let media = Self.videoURL(inEmbedHTML: html) else {
            failed.insert(postURL)
            return nil
        }
        cache[postURL] = media
        return media
    }

    // MARK: - Pure parsing, so it is testable without a network
    //
    // ⚠️ `nonisolated` deliberately: these touch no state, and leaving them
    // bound to the main actor made them uncallable from a test.

    /// `instagram.com/{p|reel|tv}/{code}/embed` for a post URL.
    /// Matched on whole path components, so a code that merely contains
    /// "reel" cannot be mistaken for the marker.
    nonisolated static func embedURL(for postURL: String) -> URL? {
        guard let url = URL(string: postURL) else { return nil }
        let parts = url.pathComponents.filter { $0 != "/" }
        for marker in ["p", "reel", "tv"] {
            if let i = parts.firstIndex(of: marker), i + 1 < parts.count {
                let code = parts[i + 1]
                if !code.isEmpty {
                    return URL(string: "https://www.instagram.com/\(marker)/\(code)/embed")
                }
            }
        }
        return nil
    }

    /// Digs `video_url` out of the embed page's JSON blob.
    ///
    /// ⚠️ The blob is DOUBLE-escaped — JSON inside JSON inside a script tag —
    /// so one unescaping pass leaves `\/` in the URL and the request is
    /// rejected as a malformed port. Two passes land on a real URL.
    nonisolated static func videoURL(inEmbedHTML html: String) -> URL? {
        guard let raw = firstMatch(in: html,
                                   pattern: #"\\"video_url\\":\\"(.*?)\\""#)
                ?? firstMatch(in: html, pattern: #""video_url":"(.*?)""#)
        else { return nil }

        var s = raw
        for _ in 0..<2 {
            s = s.replacingOccurrences(of: "\\/", with: "/")
                 .replacingOccurrences(of: "\\\\", with: "\\")
            s = decodeUnicodeEscapes(s)
        }
        guard s.hasPrefix("https://") else { return nil }
        return URL(string: s)
    }

    nonisolated private static func decodeUnicodeEscapes(_ s: String) -> String {
        guard s.contains("\\u") else { return s }
        var out = ""
        var i = s.startIndex
        while i < s.endIndex {
            if s[i] == "\\", s.index(after: i) < s.endIndex, s[s.index(after: i)] == "u",
               let end = s.index(i, offsetBy: 6, limitedBy: s.endIndex) {
                let hex = String(s[s.index(i, offsetBy: 2)..<end])
                if let v = UInt32(hex, radix: 16), let scalar = Unicode.Scalar(v) {
                    out.append(Character(scalar))
                    i = end
                    continue
                }
            }
            out.append(s[i])
            i = s.index(after: i)
        }
        return out
    }

    nonisolated private static func firstMatch(in s: String, pattern: String) -> String? {
        guard let re = try? NSRegularExpression(pattern: pattern),
              let m = re.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)),
              m.numberOfRanges > 1,
              let r = Range(m.range(at: 1), in: s) else { return nil }
        return String(s[r])
    }
}
