import SwiftUI

struct HeroImageView: View {
    let imageName: String
    let height: CGFloat
    var cornerRadius: CGFloat = 0
    var category: TourCategory? = nil
    /// When true, the loaded image can be pinch-zoomed in place. The
    /// view's frame and corner radius never change — the image scales
    /// within its clip and springs back to fit when the pinch ends.
    var zoomable: Bool = false

    @State private var zoom: CGFloat = 1.0

    // Loads the remote image from `imageName` (an HTTPS URL on the
    // CDN — gh-pages during the prototype phase, R2 post-V1; see
    // docs/cdn-decision.md). The adaptive-grey block is the
    // placeholder while loading, the failure fallback when the
    // network errors, and the empty state when `imageName` isn't a
    // valid URL.

    var body: some View {
        // GeometryReader reads the exact offered width so scaledToFill
        // is clamped to (proxy.size.width × height) — not to maxWidth:
        // .infinity, which lets AsyncImage propose an unconstrained
        // width to the image and causes the 64 pt thumbnail in
        // MakerView to overflow its parent.
        GeometryReader { proxy in
            AsyncImage(url: URL(string: imageName)) { phase in
                switch phase {
                case .success(let image):
                    if zoomable {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: proxy.size.width, height: height)
                            .scaleEffect(zoom)
                            .clipped()
                            .gesture(pinchToZoom)
                    } else {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: proxy.size.width, height: height)
                            .clipped()
                    }
                default:
                    Rectangle()
                        .fill(AtlasColors.placeholderWarm)
                        .frame(width: proxy.size.width, height: height)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    /// Pinch-to-peek: scales the image up to 4× while the fingers are
    /// down, then springs back to fit. The frame and border never move
    /// — only the image content scales, clipped to the same bounds.
    private var pinchToZoom: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                zoom = min(max(value.magnification, 1), 4)
            }
            .onEnded { _ in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    zoom = 1
                }
            }
    }
}
