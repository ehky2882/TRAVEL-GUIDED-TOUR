import Foundation
#if canImport(UIKit)
import UIKit

/// Resolves a maker's avatar to a `UIImage` for lock-screen /
/// Control-Center now-playing artwork. Resolution order mirrors the
/// in-app avatar (`MakerView` / `MiniPlayerBar`): emoji glyph →
/// remote `avatarURL` → bundled `AtlasStudioAvatar` fallback. Returns
/// `nil` only if even the bundled asset is missing.
enum MakerArtwork {
    /// Side length of the rendered square artwork. 512 is ample for
    /// the lock screen and keeps a rendered emoji crisp.
    private static let side: CGFloat = 512

    static func image(for maker: Maker?) async -> UIImage? {
        // 1. Single-glyph brand mark (e.g. Atlas Studio NYC 🍎).
        if let emoji = maker?.avatarEmoji, !emoji.isEmpty {
            return renderEmoji(emoji)
        }
        // 2. Remote avatar image.
        if let urlString = maker?.avatarURL,
           let url = URL(string: urlString),
           let (data, _) = try? await URLSession.shared.data(from: url),
           let image = UIImage(data: data) {
            return image
        }
        // 3. Bundled studio mark.
        return UIImage(named: "AtlasStudioAvatar")
    }

    /// Render a single emoji centered on a neutral square plate so the
    /// lock screen shows the glyph rather than a blank tile.
    private static func renderEmoji(_ emoji: String) -> UIImage {
        let size = CGSize(width: side, height: side)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.secondarySystemBackground.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            let font = UIFont.systemFont(ofSize: side * 0.6)
            let str = NSAttributedString(string: emoji, attributes: [.font: font])
            let textSize = str.size()
            str.draw(in: CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            ))
        }
    }
}
#endif
