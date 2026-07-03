import SwiftUI

/// The single source of truth for how a maker's avatar renders everywhere —
/// profile header, mini-player, Library saved list, Search rows, share sheets.
///
/// Resolution order (owner direction 2026-07-03 — "type initials, specify bg
/// color, or upload a pic"):
///   1. uploaded photo (`avatarURL`)
///   2. emoji brand mark (`avatarEmoji`; seed studios only, e.g. 🍎)
///   3. custom initials on a chosen colour (`avatarInitials` + `avatarColor`)
///   4. initials derived from the display name, on a colour hashed from the id
///
/// Always clipped to a circle at `size`. Because every surface goes through
/// this view, a maker who's set nothing still shows a tidy coloured monogram
/// instead of a blank/person icon (the "no icon in the saved list" report).
struct MakerAvatarView: View {
    let maker: Maker
    var size: CGFloat

    var body: some View {
        Group {
            if let urlString = maker.avatarURL,
               !urlString.isEmpty,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        // While loading / on failure, show the monogram rather
                        // than a blank plate.
                        initialsCircle
                    }
                }
            } else if let emoji = maker.avatarEmoji, !emoji.isEmpty {
                ZStack {
                    Circle().fill(AtlasColors.placeholderWarm)
                    Text(emoji).font(.system(size: size * 0.6))
                }
            } else {
                initialsCircle
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var initialsCircle: some View {
        ZStack {
            Circle().fill(Self.color(for: maker))
            Text(Self.initials(for: maker))
                .font(.system(size: size * 0.42, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
    }

    // MARK: - Resolution helpers (static so other renderers — e.g. lock-screen
    // artwork — can reuse the exact same logic).

    /// The initials to draw: the maker's explicit `avatarInitials` (≤2 chars),
    /// else derived from the display name.
    static func initials(for maker: Maker) -> String {
        if let ini = maker.avatarInitials?.trimmingCharacters(in: .whitespacesAndNewlines),
           !ini.isEmpty {
            return String(ini.prefix(2)).uppercased()
        }
        return derivedInitials(from: maker.displayName)
    }

    /// The circle colour: the maker's explicit `avatarColor` hex, else a stable
    /// palette colour chosen from the id so each maker keeps the same colour.
    static func color(for maker: Maker) -> Color {
        if let hex = maker.avatarColor, let c = Color(atlasHex: hex) { return c }
        return paletteColor(for: maker.id)
    }

    /// Up to two initials from a name ("Atlas Studio NYC" → "AS", "edward" → "E").
    static func derivedInitials(from name: String) -> String {
        let letters = name
            .split(whereSeparator: { $0 == " " || $0 == "-" })
            .prefix(2)
            .compactMap { $0.first }
        let s = String(letters).uppercased()
        return s.isEmpty ? "?" : s
    }

    /// The colour palette offered in the editor + used for the derived fallback.
    static let palette: [String] = [
        "#EF4444", "#F97316", "#EAB308", "#22C55E", "#14B8A6",
        "#3B82F6", "#6366F1", "#A855F7", "#EC4899", "#78716C"
    ]

    static func paletteColor(for id: UUID) -> Color {
        let idx = abs(id.uuidString.hashValue) % palette.count
        return Color(atlasHex: palette[idx]) ?? .gray
    }
}

extension Color {
    /// Parse a `#RRGGBB` (or `RRGGBB`) hex string. Returns nil on a malformed
    /// value so callers can fall back. Named `atlasHex` to avoid clashing with
    /// any future SwiftUI `Color(hex:)`.
    init?(atlasHex hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt64(s, radix: 16) else { return nil }
        self.init(
            .sRGB,
            red: Double((v >> 16) & 0xFF) / 255,
            green: Double((v >> 8) & 0xFF) / 255,
            blue: Double(v & 0xFF) / 255,
            opacity: 1
        )
    }
}
