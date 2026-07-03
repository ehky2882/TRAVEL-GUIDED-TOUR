import SwiftUI
import UIKit

/// Interactive avatar cropper. The user pinch-zooms and drags a photo within a
/// circular viewport to choose exactly how it's framed, then "Use photo"
/// renders the visible square region to a 512×512 JPEG for upload.
///
/// The same `imageLayer(scale:offset:)` drives both the on-screen preview and
/// the final `ImageRenderer` snapshot, so what you see is what's saved.
struct AvatarCropSheet: View {
    let image: UIImage
    /// Called with the cropped 512×512 JPEG when the user confirms.
    let onCrop: (Data) -> Void

    @Environment(\.dismiss) private var dismiss

    /// Committed transform (updated when a gesture ends).
    @State private var scale: CGFloat = 1
    @State private var offset: CGSize = .zero
    /// In-flight gesture deltas.
    @GestureState private var pinch: CGFloat = 1
    @GestureState private var drag: CGSize = .zero

    /// On-screen viewport side (points). The render scales this up to 512.
    private let viewport: CGFloat = 300
    private let outputSide: CGFloat = 512
    private let maxScale: CGFloat = 6

    private var liveScale: CGFloat { max(1, min(scale * pinch, maxScale)) }
    private var liveOffset: CGSize {
        CGSize(width: offset.width + drag.width, height: offset.height + drag.height)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: AtlasSpacing.lg) {
                Spacer()

                imageLayer(scale: liveScale, offset: liveOffset)
                    .frame(width: viewport, height: viewport)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AtlasColors.secondaryText.opacity(0.5), lineWidth: 1))
                    .gesture(SimultaneousGesture(magnify, move))

                Text("Pinch to zoom · drag to reposition")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AtlasColors.secondaryBackground)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("ADJUST PHOTO")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.primaryText)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(AtlasTypography.caption)
                        .tint(AtlasColors.primaryText)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Use photo") { cropAndFinish() }
                        .font(AtlasTypography.caption)
                        .tint(AtlasColors.mapPin)
                }
            }
        }
    }

    /// The photo, aspect-filled into the viewport, then zoomed + panned. Used
    /// for both the live preview and the final render.
    private func imageLayer(scale: CGFloat, offset: CGSize) -> some View {
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

    /// Render the committed transform to a square opaque JPEG (avatars display
    /// as circles elsewhere, so a square store with transparent-free corners is
    /// correct — JPEG has no alpha).
    @MainActor
    private func cropAndFinish() {
        let renderer = ImageRenderer(
            content:
                imageLayer(scale: scale, offset: offset)
                    .frame(width: viewport, height: viewport)
                    .clipped()
        )
        renderer.scale = outputSide / viewport
        if let ui = renderer.uiImage, let data = ui.jpegData(compressionQuality: 0.85) {
            onCrop(data)
        }
        dismiss()
    }
}
