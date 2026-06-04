import SwiftUI

struct SplashView: View {
    @State private var opacity: Double = 1.0

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Circle()
                    .fill(AtlasColors.mapPin)
                    .frame(width: 44, height: 44)
                    .opacity(opacity)
                    .animation(
                        .easeInOut(duration: 0.8)
                            .repeatForever(autoreverses: true),
                        value: opacity
                    )
                    .onAppear {
                        opacity = 0.2
                    }

                // Wordmark in iOS's New York serif system font —
                // editorial register matches the gold map-pin palette.
                Text("Dozent")
                    .font(.system(size: 15, weight: .regular, design: .serif))
                    .foregroundStyle(.white)
                    .tracking(2)
            }
        }
    }
}
