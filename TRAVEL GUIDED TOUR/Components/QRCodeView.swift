import SwiftUI
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

/// Renders a string as a QR code. Uses Core Image's built-in generator, so this
/// adds **no dependency** (V1 rule: Apple frameworks only).
///
/// Used by Group Listen so a leader can show a code for others to scan instead
/// of reading five characters aloud across a noisy room.
struct QRCodeView: View {
    /// What the code encodes — for Group Listen, the https join link.
    let content: String
    /// Rendered edge length in points.
    var size: CGFloat = 170

    var body: some View {
        Group {
            if let image = Self.qrImage(from: content) {
                Image(uiImage: image)
                    // QR codes are hard-edged bitmaps — smoothing them softens
                    // the modules and can make scanning less reliable.
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
            } else {
                // Generation realistically can't fail for our tiny payload, but
                // never render a blank hole: fall back to something legible.
                RoundedRectangle(cornerRadius: 8)
                    .fill(AtlasColors.placeholderWarm.opacity(0.35))
                    .overlay(
                        Image(systemName: "qrcode")
                            .font(.system(size: size * 0.4))
                            .foregroundStyle(AtlasColors.secondaryText)
                    )
            }
        }
        .frame(width: size, height: size)
        // A quiet zone (white margin) is part of the QR spec — scanners need it,
        // and the code must stay light-on-dark-agnostic, so we always draw the
        // code on white regardless of app theme.
        .padding(AtlasSpacing.sm)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityHidden(true)
    }

    /// Renders `string` to a QR bitmap, or nil if Core Image can't encode it.
    /// Scaled up before rasterising because the filter emits roughly one pixel
    /// per module, which would look like mush when stretched to view size.
    static func qrImage(from string: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        // Medium error correction: still scannable if a finger clips a corner,
        // without inflating the module count for a short payload.
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let upscaled = output.transformed(by: CGAffineTransform(scaleX: 12, y: 12))
        guard let cgImage = CIContext().createCGImage(upscaled, from: upscaled.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}
