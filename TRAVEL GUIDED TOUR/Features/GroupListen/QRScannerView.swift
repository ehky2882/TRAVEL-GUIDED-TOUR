import SwiftUI
import AVFoundation
import UIKit

/// Camera scanner for a Group Listen join code — the fastest way in for people
/// standing next to each other (design §6: "QR is the fastest share for
/// co-located people").
///
/// Accepts both the link QR a leader shows and a bare five-character code, via
/// `DeepLinkParser.groupCode(fromScannedPayload:)`. Anything else is ignored, so
/// pointing the camera at an unrelated QR code does nothing rather than starting
/// a session that could never connect.
struct QRScannerView: View {
    /// Called with a validated join code. The presenter dismisses and joins.
    let onCode: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var authorization = AVCaptureDevice.authorizationStatus(for: .video)
    /// Guards against delivering twice if the camera reports the same code in
    /// consecutive frames.
    @State private var delivered = false

    var body: some View {
        NavigationStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AtlasColors.secondaryBackground)
                .navigationTitle("Scan to join")
                .inlineNavigationBarTitle()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
        }
        .task {
            guard authorization == .notDetermined else { return }
            _ = await AVCaptureDevice.requestAccess(for: .video)
            authorization = AVCaptureDevice.authorizationStatus(for: .video)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch authorization {
        case .authorized:
            if QRScannerController.hasCamera {
                scanner
            } else {
                // The Simulator has no camera — say so instead of showing a
                // black rectangle that looks broken.
                message(
                    icon: "camera.metering.unknown",
                    text: "No camera available on this device. Enter the code by hand instead."
                )
            }
        case .denied, .restricted:
            message(
                icon: "camera.fill",
                text: "Camera access is off. Turn it on in Settings › Privacy & Security › Camera to scan a code — or enter the code by hand instead."
            )
        case .notDetermined:
            ProgressView()
        @unknown default:
            message(
                icon: "camera.fill",
                text: "Camera unavailable. Enter the code by hand instead."
            )
        }
    }

    private var scanner: some View {
        VStack(spacing: AtlasSpacing.md) {
            QRScannerRepresentable { payload in
                guard !delivered,
                      let code = DeepLinkParser.groupCode(fromScannedPayload: payload) else { return }
                delivered = true
                AtlasHaptics.success()
                onCode(code)
                dismiss()
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, AtlasSpacing.lg)
            .padding(.top, AtlasSpacing.md)

            Text("Point the camera at the leader's code.")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.secondaryText)
                .padding(.bottom, AtlasSpacing.lg)
        }
    }

    private func message(icon: String, text: String) -> some View {
        VStack(spacing: AtlasSpacing.md) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(AtlasColors.secondaryText)
            Text(text)
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(.horizontal, AtlasSpacing.lg)
    }
}

/// SwiftUI bridge to the AVFoundation capture session.
private struct QRScannerRepresentable: UIViewControllerRepresentable {
    let onPayload: (String) -> Void

    func makeUIViewController(context: Context) -> QRScannerController {
        let controller = QRScannerController()
        controller.onPayload = onPayload
        return controller
    }

    func updateUIViewController(_ controller: QRScannerController, context: Context) {
        controller.onPayload = onPayload
    }
}

/// Minimal QR capture controller. Kept deliberately plain: one session, one
/// metadata output filtered to `.qr`, torn down when the view goes away so the
/// camera light never lingers.
final class QRScannerController: UIViewController {
    var onPayload: ((String) -> Void)?

    /// False in the Simulator (and on any device without a back camera), so the
    /// UI can explain itself rather than showing black.
    static var hasCamera: Bool {
        AVCaptureDevice.default(for: .video) != nil
    }

    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    /// `startRunning()` blocks, so it never runs on the main thread.
    private let sessionQueue = DispatchQueue(label: "com.dozent.qrscanner.session")

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureSession()
    }

    private func configureSession() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        // Must be set *after* the output is attached to a session, or `.qr`
        // isn't yet an available type.
        if output.availableMetadataObjectTypes.contains(.qr) {
            output.metadataObjectTypes = [.qr]
        }

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)
        previewLayer = preview
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard !session.isRunning else { return }
        sessionQueue.async { [session] in session.startRunning() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard session.isRunning else { return }
        sessionQueue.async { [session] in session.stopRunning() }
    }
}

extension QRScannerController: AVCaptureMetadataObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = object.stringValue else { return }
        onPayload?(value)
    }
}
