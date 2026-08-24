// Generates a 1920x1080 landscape test clip for the fullscreen video viewer.
//
// The catalogue has no landscape video, so the viewer's rotation path — the
// one design decision in it that matters — has never run against real
// content on any device. This makes something it can run against.
//
// Deliberately covered in diagnostic markings, exactly like the vertical
// stand-in: TOP / BOTTOM / L / R at the edges, a running countdown, and a
// border. A crop or a rotation applied the wrong way is then obvious on
// sight rather than something you have to squint at.
//
//   swift make-landscape-test-clip.swift <output.mp4>
import AVFoundation
import CoreGraphics
import Foundation
import CoreText

let out = URL(fileURLWithPath: CommandLine.arguments.count > 1
              ? CommandLine.arguments[1] : "landscape-test.mp4")
try? FileManager.default.removeItem(at: out)

let W = 1920, H = 1080, FPS: Int32 = 30, SECONDS = 12

let writer = try AVAssetWriter(outputURL: out, fileType: .mp4)
let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
    AVVideoCodecKey: AVVideoCodecType.h264,
    AVVideoWidthKey: W,
    AVVideoHeightKey: H,
])
input.expectsMediaDataInRealTime = false
let adaptor = AVAssetWriterInputPixelBufferAdaptor(
    assetWriterInput: input,
    sourcePixelBufferAttributes: [
        kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
        kCVPixelBufferWidthKey as String: W,
        kCVPixelBufferHeightKey as String: H,
    ])
writer.add(input)
writer.startWriting()
writer.startSession(atSourceTime: .zero)

let brass = CGColor(red: 0.545, green: 0.459, blue: 0.208, alpha: 1)   // #8B7535
let ground = CGColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1)

func draw(_ ctx: CGContext, second: Int) {
    ctx.setFillColor(ground)
    ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))

    // Border + an inner rule, so a crop shows as a missing edge.
    ctx.setStrokeColor(brass); ctx.setLineWidth(8)
    ctx.stroke(CGRect(x: 12, y: 12, width: W - 24, height: H - 24))
    ctx.setLineWidth(2)
    ctx.stroke(CGRect(x: 48, y: 48, width: W - 96, height: H - 96))

    func text(_ s: String, _ size: CGFloat, _ colour: CGColor, centreX: CGFloat, y: CGFloat) {
        let font = CTFontCreateWithName("Helvetica" as CFString, size, nil)
        // kCTForegroundColorAttributeName rather than the AppKit/UIKit key:
        // this is a plain CoreText tool with neither framework linked.
        let attr = NSAttributedString(string: s, attributes: [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): colour,
        ])
        let line = CTLineCreateWithAttributedString(attr)
        let b = CTLineGetBoundsWithOptions(line, [])
        ctx.textPosition = CGPoint(x: centreX - b.width / 2, y: y)
        CTLineDraw(line, ctx)
    }

    // Core Graphics origin is bottom-left, so TOP is drawn high.
    text("TOP", 56, brass, centreX: CGFloat(W) / 2, y: CGFloat(H) - 130)
    text("BOTTOM", 56, brass, centreX: CGFloat(W) / 2, y: 90)
    text("L", 56, brass, centreX: 110, y: CGFloat(H) / 2)
    text("R", 56, brass, centreX: CGFloat(W) - 110, y: CGFloat(H) / 2)

    text("ATLAS LANDSCAPE TEST", 78, CGColor(gray: 1, alpha: 1),
         centreX: CGFloat(W) / 2, y: CGFloat(H) / 2 + 150)
    text("1920 x 1080", 46, CGColor(gray: 0.72, alpha: 1),
         centreX: CGFloat(W) / 2, y: CGFloat(H) / 2 + 80)
    text("\(SECONDS - second)s", 190, CGColor(gray: 1, alpha: 1),
         centreX: CGFloat(W) / 2, y: CGFloat(H) / 2 - 130)
}

let space = CGColorSpaceCreateDeviceRGB()
var frame: Int64 = 0
for second in 0..<SECONDS {
    for _ in 0..<Int(FPS) {
        while !input.isReadyForMoreMediaData { usleep(2000) }
        var pb: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &pb)
        guard let buffer = pb else { fatalError("no pixel buffer") }
        CVPixelBufferLockBaseAddress(buffer, [])
        let ctx = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: W, height: H, bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: space,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)!
        draw(ctx, second: second)
        CVPixelBufferUnlockBaseAddress(buffer, [])
        adaptor.append(buffer, withPresentationTime: CMTime(value: frame, timescale: FPS))
        frame += 1
    }
}
input.markAsFinished()
let done = DispatchSemaphore(value: 0)
writer.finishWriting { done.signal() }
done.wait()
if writer.status == .completed {
    print("wrote \(out.path)")
} else {
    print("FAILED: \(String(describing: writer.error))"); exit(1)
}
