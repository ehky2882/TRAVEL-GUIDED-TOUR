import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct HeroImageView: View {
    let imageName: String
    let height: CGFloat
    var cornerRadius: CGFloat = 0
    var category: TourCategory? = nil
    var zoomable: Bool = false
    /// When true, the placeholder → image transition is NOT animated.
    /// Used on tour detail (slide-up presentation) so the image either
    /// renders frame-zero on cache hit or snaps in cleanly on miss,
    /// rather than crossfading mid-slide. Defaults to false so the
    /// gentle fade still runs on surfaces that appear in place.
    var disableLoadAnimation: Bool = false

    #if canImport(UIKit)
    @State private var cachedImage: UIImage?
    #endif
    @State private var zoom: CGFloat = 1.0

    init(
        imageName: String,
        height: CGFloat,
        cornerRadius: CGFloat = 0,
        category: TourCategory? = nil,
        zoomable: Bool = false,
        disableLoadAnimation: Bool = false
    ) {
        self.imageName = imageName
        self.height = height
        self.cornerRadius = cornerRadius
        self.category = category
        self.zoomable = zoomable
        self.disableLoadAnimation = disableLoadAnimation
        #if canImport(UIKit)
        // Pre-populate from the in-memory cache so the image renders
        // on the first frame with zero placeholder flash on cache hits.
        let cached = URL(string: imageName).flatMap { ImageCache.shared.image(for: $0) }
        self._cachedImage = State(initialValue: cached)
        #endif
    }

    var body: some View {
        GeometryReader { proxy in
            #if canImport(UIKit)
            cachedContent(proxy: proxy)
                // Animate only the nil → non-nil transition (first load).
                // If cachedImage was pre-set in init, the value never
                // changes and no animation fires — zero flash on cache hits.
                .animation(
                    disableLoadAnimation ? nil : .easeIn(duration: 0.15),
                    value: cachedImage != nil
                )
            #else
            asyncContent(proxy: proxy)
            #endif
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        #if canImport(UIKit)
        .task(id: imageName) { await fetchIfNeeded() }
        #endif
    }

    // MARK: - UIKit path (iOS / visionOS)

    #if canImport(UIKit)
    @ViewBuilder
    private func cachedContent(proxy: GeometryProxy) -> some View {
        if let uiImage = cachedImage {
            renderedImage(Image(uiImage: uiImage), proxy: proxy)
        } else {
            placeholder(proxy: proxy)
        }
    }

    private func fetchIfNeeded() async {
        guard let url = URL(string: imageName) else { return }
        if ImageCache.shared.image(for: url) != nil { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let uiImage = UIImage(data: data) else { return }
            ImageCache.shared.store(uiImage, for: url)
            cachedImage = uiImage
        } catch {
            // Network error or task cancelled — placeholder stays.
        }
    }
    #endif

    // MARK: - macOS fallback (AsyncImage)

    @ViewBuilder
    private func asyncContent(proxy: GeometryProxy) -> some View {
        AsyncImage(
            url: URL(string: imageName),
            transaction: disableLoadAnimation
                ? Transaction(animation: nil)
                : Transaction()
        ) { phase in
            switch phase {
            case .success(let image):
                renderedImage(image, proxy: proxy)
            default:
                placeholder(proxy: proxy)
            }
        }
    }

    // MARK: - Shared helpers

    @ViewBuilder
    private func renderedImage(_ image: Image, proxy: GeometryProxy) -> some View {
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
    }

    private func placeholder(proxy: GeometryProxy) -> some View {
        Rectangle()
            .fill(AtlasColors.placeholderWarm)
            .frame(width: proxy.size.width, height: height)
    }

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
