import SwiftUI

struct PlaceAnnotationView: View {
    let place: Place
    var isSelected: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(AtlasColors.accent)
                    .frame(width: isSelected ? 40 : 30, height: isSelected ? 40 : 30)
                    .shadow(color: AtlasColors.accent.opacity(0.4), radius: isSelected ? 8 : 4, y: 2)

                Image(systemName: place.category.iconName)
                    .font(.system(size: isSelected ? 18 : 13, weight: .medium))
                    .foregroundStyle(.white)
            }

            // Pin tail
            Image(systemName: "triangle.fill")
                .font(.system(size: isSelected ? 10 : 8))
                .foregroundStyle(AtlasColors.accent)
                .rotationEffect(.degrees(180))
                .offset(y: isSelected ? -3 : -2)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}
