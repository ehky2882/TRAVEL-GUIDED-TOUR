import SwiftUI

struct SplashView: View {
    @State private var opacity: Double = 1.0

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Circle()
                    .fill(Color(red: 0.22, green: 1.0, blue: 0.08))
                    .frame(width: 24, height: 24)
                    .opacity(opacity)
                    .animation(
                        .easeInOut(duration: 0.8)
                            .repeatForever(autoreverses: true),
                        value: opacity
                    )
                    .onAppear {
                        opacity = 0.2
                    }

                Text("atlas")
                    .font(.system(size: 18, weight: .medium, design: .default))
                    .foregroundStyle(.white)
                    .tracking(4)
            }
        }
    }
}
