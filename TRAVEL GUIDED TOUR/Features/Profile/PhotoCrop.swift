import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Turning a photo and a transform into the catalog's 1200×900 bytes.
///
/// Lifted out of `PhotoFramingView` when that screen was deleted (owner,
/// 2026-08-20: *"in the current on-device version, there is another screen that
/// asks for a confirmation of the photo. i don't like that. do everything from
/// this screen"*). The maths was always right; only the screen around it was
/// wrong, so the maths moved and the screen went.
///
/// `preview` and `render` share `layer`, so what a maker sees while dragging
/// and what actually ships cannot disagree — that was true of the framing
/// screen and has to stay true of the grid that replaced it.
enum PhotoCrop {
    /// The catalog's image size. Every tour photo ever published is this shape.
    static let outputWidth: CGFloat = 1200
    static let outputHeight: CGFloat = 900
    static let aspect: CGFloat = outputWidth / outputHeight
    static let maxScale: CGFloat = 6

    /// The photo aspect-filled into its box, then zoomed and panned.
    static func layer(_ image: UIImage, scale: CGFloat, offset: CGSize) -> some View {
        Color.clear
            .overlay(
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(scale)
                    .offset(offset)
            )
    }

    /// The framed photo as JPEG bytes.
    ///
    /// Rendered at a fixed 400pt-wide viewport and scaled up to 1200, so the
    /// output never depends on how big the slot happened to be on the device
    /// doing the framing — a 16 Pro and an SE produce identical bytes.
    @MainActor
    static func render(_ image: UIImage, scale: CGFloat, offset: CGSize) -> Data? {
        let viewportWidth: CGFloat = 400
        let viewportHeight = viewportWidth / aspect
        let renderer = ImageRenderer(
            content:
                layer(image, scale: scale, offset: offset)
                    .frame(width: viewportWidth, height: viewportHeight)
                    .clipped()
        )
        renderer.scale = outputWidth / viewportWidth
        return renderer.uiImage?.jpegData(compressionQuality: 0.82)
    }

    /// Aspect-fill and take the middle — what a photo gets on the way in,
    /// before anyone has adjusted anything.
    ///
    /// ⚠️ This is the crop the framing screen existed to save makers from: a
    /// tower or a spire loses its top to it, which is why the image pipeline's
    /// own notes call for top-biased crops on tall subjects. It is acceptable
    /// as a *starting point* now only because the grid lets you fix it in
    /// place. It was not acceptable as the last word, and must not become one
    /// again.
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
