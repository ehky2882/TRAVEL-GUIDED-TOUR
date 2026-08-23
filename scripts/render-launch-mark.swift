// Regenerates `Assets.xcassets/LaunchMark.imageset` — the static launch screen
// iOS paints before the app's first frame.
//
// Run from the repo root:
//   swift scripts/render-launch-mark.swift "TRAVEL GUIDED TOUR/Assets.xcassets/LaunchMark.imageset"
//
// 🔴 THE GEOMETRY HERE MUST MATCH `SplashView` EXACTLY, because the two are
// shown back to back and any difference reads as a jump: a 44pt brass disc at
// the CENTRE of the screen (`LaunchZoom.originFraction` is 0.5), with the
// wordmark's centre 38pt below it (the disc's own radius, 22, plus
// `AtlasSpacing.md`, 16). The image is symmetric about the disc so that
// centring the image centres the disc.
//
// The wordmark is drawn from the real face — New York, the system serif, at
// 15pt tracked 2 — rather than approximated, and in two colours: black for the
// light appearance, white for dark. A launch screen cannot resolve a semantic
// colour, so the light/dark split is done with two renditions in the asset
// catalog instead.

import AppKit

// Draws the resting splash exactly as `SplashView` does: a 44pt brass disc
// centred on the image, and the "Dozent" wordmark — New York serif 15pt,
// tracked 2 — with its CENTRE 38pt below the disc's centre (the disc's own
// radius, 22, plus AtlasSpacing.md, 16).
let markDiameter: CGFloat = 44
let wordmarkDrop: CGFloat = 22 + 16
let halfHeight: CGFloat = 49          // symmetric, so the image centre IS the disc centre
let size = CGSize(width: 120, height: halfHeight * 2)
let brass = NSColor(srgbRed: 139/255.0, green: 117/255.0, blue: 53/255.0, alpha: 1)

let base = NSFont.systemFont(ofSize: 15)
guard let serifDescriptor = base.fontDescriptor.withDesign(.serif),
      let serif = NSFont(descriptor: serifDescriptor, size: 15) else {
    fatalError("no serif face")
}

func render(scale: CGFloat, textColor: NSColor, to path: String) {
    let pxW = Int(size.width * scale), pxH = Int(size.height * scale)
    guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pxW, pixelsHigh: pxH,
                                     bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                     isPlanar: false, colorSpaceName: .deviceRGB,
                                     bytesPerRow: 0, bitsPerPixel: 0) else { fatalError() }
    rep.size = size
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current?.cgContext.setShouldAntialias(true)

    // AppKit's origin is bottom-left; the geometry above is top-down.
    let centre = CGPoint(x: size.width / 2, y: size.height / 2)
    brass.setFill()
    NSBezierPath(ovalIn: CGRect(x: centre.x - markDiameter / 2,
                                y: centre.y - markDiameter / 2,
                                width: markDiameter, height: markDiameter)).fill()

    let attrs: [NSAttributedString.Key: Any] = [
        .font: serif, .foregroundColor: textColor, .tracking: 2.0,
    ]
    let text = NSAttributedString(string: "Dozent", attributes: attrs)
    let bounds = text.size()
    // `.tracking` adds trailing space after the last glyph; SwiftUI centres the
    // laid-out run, so drop half of it to keep the optical centre true.
    let drawn = CGSize(width: bounds.width - 1, height: bounds.height)
    text.draw(at: CGPoint(x: centre.x - drawn.width / 2,
                          y: centre.y - wordmarkDrop - drawn.height / 2))

    NSGraphicsContext.restoreGraphicsState()
    guard let png = rep.representation(using: .png, properties: [:]) else { fatalError() }
    try! png.write(to: URL(fileURLWithPath: path))
}

let out = CommandLine.arguments[1]
for scale in [1, 2, 3] {
    render(scale: CGFloat(scale), textColor: .black, to: "\(out)/launch-mark@\(scale)x.png")
    render(scale: CGFloat(scale), textColor: .white, to: "\(out)/launch-mark-dark@\(scale)x.png")
}
print("rendered")
