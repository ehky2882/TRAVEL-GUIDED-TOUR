import SwiftUI

struct HeroImageView: View {
    let imageName: String
    let height: CGFloat
    var cornerRadius: CGFloat = 0
    var category: PlaceCategory? = nil

    var body: some View {
        ZStack {
            Rectangle()
                .fill(placeholderGradient(for: imageName))

            // Subtle noise texture via overlapping circles
            GeometryReader { geo in
                Canvas { context, size in
                    let step: CGFloat = 40
                    for x in stride(from: 0, to: size.width, by: step) {
                        for y in stride(from: 0, to: size.height, by: step) {
                            let hash = abs((imageName + "\(x)\(y)").hashValue)
                            let opacity = Double(hash % 8) / 100.0
                            let radius = CGFloat(hash % 15) + 10
                            context.fill(
                                Path(ellipseIn: CGRect(x: x - radius/2, y: y - radius/2, width: radius, height: radius)),
                                with: .color(.white.opacity(opacity))
                            )
                        }
                    }
                }
            }

            // Category icon or city icon
            if let category {
                Image(systemName: category.iconName)
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(.white.opacity(0.25))
            } else {
                Image(systemName: cityIcon(for: imageName))
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(.white.opacity(0.2))
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private func placeholderGradient(for name: String) -> LinearGradient {
        let hash = abs(name.hashValue)
        let palettes: [(Color, Color)] = [
            // Warm terracotta
            (Color(red: 0.72, green: 0.33, blue: 0.26), Color(red: 0.50, green: 0.20, blue: 0.15)),
            // Slate blue
            (Color(red: 0.34, green: 0.40, blue: 0.50), Color(red: 0.20, green: 0.25, blue: 0.35)),
            // Warm sand
            (Color(red: 0.62, green: 0.55, blue: 0.42), Color(red: 0.45, green: 0.38, blue: 0.26)),
            // Forest
            (Color(red: 0.32, green: 0.42, blue: 0.36), Color(red: 0.18, green: 0.28, blue: 0.22)),
            // Mauve
            (Color(red: 0.50, green: 0.38, blue: 0.46), Color(red: 0.35, green: 0.22, blue: 0.32)),
            // Steel
            (Color(red: 0.38, green: 0.42, blue: 0.48), Color(red: 0.22, green: 0.26, blue: 0.32)),
            // Ochre
            (Color(red: 0.68, green: 0.52, blue: 0.30), Color(red: 0.48, green: 0.34, blue: 0.18)),
            // Deep teal
            (Color(red: 0.22, green: 0.40, blue: 0.42), Color(red: 0.12, green: 0.26, blue: 0.30)),
        ]
        let pair = palettes[hash % palettes.count]
        return LinearGradient(
            colors: [pair.0, pair.1],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func cityIcon(for name: String) -> String {
        if name.contains("nyc") || name.contains("highline") || name.contains("noguchi") {
            return "building.2.crop.circle"
        } else if name.contains("porto") || name.contains("lello") || name.contains("clerigos") {
            return "building.columns"
        } else if name.contains("london") || name.contains("barbican") {
            return "crown"
        }
        return "photo"
    }
}
