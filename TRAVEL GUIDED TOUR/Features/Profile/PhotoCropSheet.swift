import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Frames each picked photo to the catalog's 1200×900 before upload.
///
/// **Why this exists.** Photos were previously centre-cropped with no preview.
/// That is exactly the failure the image pipeline works around by hand: a tall
/// subject — a tower, a spire, a column — loses its top to a centre crop, which
/// is why the pipeline notes call for top-biased crops on those. The avatar
/// editor already solved the interaction; tour photos never got it.
///
/// Walks a queue one photo at a time, so picking five doesn't mean five separate
/// sheets appearing and dismissing. **Skip is always available** — for the
/// common case where the centre is fine, framing shouldn't cost four extra taps
/// per photo — and it produces exactly the same centre crop the old code did.
struct PhotoCropSheet: View {
    let images: [UIImage]
    /// Called once with every processed photo, in the order they were picked.
    let onFinish: ([Data]) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var index = 0
    @State private var results: [Data] = []
    /// Committed transform for the photo currently on screen.
    @State private var scale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @GestureState private var pinch: CGFloat = 1
    @GestureState private var drag: CGSize = .zero

    /// The catalog's image size. The renderer scales the on-screen viewport up
    /// to exactly this, so what is framed is what ships.
    private static let outputWidth: CGFloat = 1200
    private static let outputHeight: CGFloat = 900
    private let maxScale: CGFloat = 6

    private var liveScale: CGFloat { max(1, min(scale * pinch, maxScale)) }
    private var liveOffset: CGSize {
        CGSize(width: offset.width + drag.width, height: offset.height + drag.height)
    }
    private var current: UIImage? {
        images.indices.contains(index) ? images[index] : nil
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                // Viewport is as wide as the sheet allows, at 4:3 — the same
                // shape as the output, so the preview cannot lie about framing.
                let width = min(geo.size.width - AtlasSpacing.lg * 2, 420)
                let height = width * (Self.outputHeight / Self.outputWidth)

                VStack(spacing: AtlasSpacing.lg) {
                    Spacer()

                    if let current {
                        imageLayer(current, scale: liveScale, offset: liveOffset)
                            .frame(width: width, height: height)
                            .clipped()
                            .overlay(
                                Rectangle()
                                    .stroke(AtlasColors.secondaryText.opacity(0.5), lineWidth: 1)
                            )
                            .gesture(SimultaneousGesture(magnify, move))
                    }

                    VStack(spacing: AtlasSpacing.xs) {
                        Text("Pinch to zoom · drag to reposition")
                            .font(AtlasTypography.caption)
                            .foregroundStyle(AtlasColors.secondaryText)
                        if images.count > 1 {
                            Text("Photo \(index + 1) of \(images.count)")
                                .font(AtlasTypography.caption)
                                .foregroundStyle(AtlasColors.tertiaryText)
                        }
                    }

                    Button { advance(using: nil) } label: {
                        Text("Skip — use the centre")
                            .font(AtlasTypography.caption)
                            .foregroundStyle(AtlasColors.primaryText)
                            .padding(.horizontal, AtlasSpacing.xl)
                            .padding(.vertical, AtlasSpacing.md)
                            .overlay(
                                Capsule().stroke(AtlasColors.secondaryText.opacity(0.5), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(AtlasColors.secondaryBackground)
            .navigationTitle("")
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("FRAME PHOTO")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.primaryText)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(AtlasTypography.caption)
                        .tint(AtlasColors.primaryText)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(index == images.count - 1 ? "Use photo" : "Next") {
                        advance(using: (scale, offset))
                    }
                    .font(AtlasTypography.caption)
                    .tint(AtlasColors.mapPin)
                }
            }
        }
    }

    /// The photo aspect-filled into the viewport, then zoomed and panned. Drives
    /// both the live preview and the final render, so they cannot disagree.
    private func imageLayer(_ image: UIImage, scale: CGFloat, offset: CGSize) -> some View {
        Color.clear
            .overlay(
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(scale)
                    .offset(offset)
            )
    }

    private var magnify: some Gesture {
        MagnificationGesture()
            .updating($pinch) { value, state, _ in state = value }
            .onEnded { scale = max(1, min(scale * $0, maxScale)) }
    }

    private var move: some Gesture {
        DragGesture()
            .updating($drag) { value, state, _ in state = value.translation }
            .onEnded {
                offset.width += $0.translation.width
                offset.height += $0.translation.height
            }
    }

    /// Render the current photo (framed, or centred when skipped), then move to
    /// the next — or hand everything back and close.
    @MainActor
    private func advance(using transform: (scale: CGFloat, offset: CGSize)?) {
        if let image = current {
            let data = transform.map { render(image, scale: $0.scale, offset: $0.offset) }
                ?? Self.centreCrop(image)
            if let data { results.append(data) }
        }

        if index + 1 < images.count {
            index += 1
            // Reset the transform for the next photo, or it inherits the last
            // one's zoom and opens looking wrong.
            scale = 1
            offset = .zero
        } else {
            onFinish(results)
            dismiss()
        }
    }

    @MainActor
    private func render(_ image: UIImage, scale: CGFloat, offset: CGSize) -> Data? {
        // Render at the viewport's own aspect, scaled up to the output size.
        let viewportWidth: CGFloat = 400
        let viewportHeight = viewportWidth * (Self.outputHeight / Self.outputWidth)
        let renderer = ImageRenderer(
            content:
                imageLayer(image, scale: scale, offset: offset)
                    .frame(width: viewportWidth, height: viewportHeight)
                    .clipped()
        )
        renderer.scale = Self.outputWidth / viewportWidth
        return renderer.uiImage?.jpegData(compressionQuality: 0.82)
    }

    /// The old behaviour, kept for Skip: aspect-fill and take the centre.
    nonisolated static func centreCrop(_ image: UIImage) -> Data? {
        #if canImport(UIKit)
        let target = CGSize(width: outputWidth, height: outputHeight)
        let scale = max(target.width / image.size.width, target.height / image.size.height)
        let scaled = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let origin = CGPoint(x: (target.width - scaled.width) / 2,
                             y: (target.height - scaled.height) / 2)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let rendered = UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: origin, size: scaled))
        }
        return rendered.jpegData(compressionQuality: 0.82)
        #else
        return nil
        #endif
    }
}
