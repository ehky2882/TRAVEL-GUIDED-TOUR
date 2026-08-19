import SwiftUI
import AVFoundation

/// Records narration in-app for a tour's audio step (V2 Step 4, increment 2c).
/// Tap to record → stop → hands the recorded file URL back via `onFinish`, which
/// the editor uploads through the same `MakerTourService.attachAudio` path as an
/// imported file. Recording uses the device mic (works partially in the
/// simulator via the host mic; real capture is device-verified).
struct AudioRecordSheet: View {
    /// Called with the recorded m4a file URL when the user keeps a recording.
    let onFinish: (URL) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var recorder = AudioRecorder()
    @State private var review = RecordingReviewPlayer()
    @State private var recordedURL: URL?
    @State private var permissionDenied = false

    /// Live input level, so the screen answers "is it hearing me?" — a running
    /// counter does not: it ticks along just as happily with a muted mic or a
    /// hand over the microphone, and a maker only finds out afterwards.
    ///
    /// Bars scroll right to left, newest at the right, and sit at a visible
    /// floor when idle so the meter reads as a meter rather than as nothing.
    private var levelMeter: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(Array(recorder.levels.enumerated()), id: \.offset) { _, level in
                Capsule()
                    .fill(recorder.isRecording ? AtlasColors.mapPin : AtlasColors.divider)
                    .frame(width: 3, height: max(3, level * 48))
            }
        }
        .frame(height: 48)
        .animation(.linear(duration: 0.05), value: recorder.levels)
        .accessibilityHidden(true)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: AtlasSpacing.xl) {
                Spacer()

                Text(timeString(recorder.isRecording ? recorder.elapsed : (recordedURL != nil ? recorder.lastDuration : 0)))
                    .font(.system(size: 44, weight: .light, design: .monospaced))
                    .foregroundStyle(AtlasColors.primaryText)
                    .contentTransition(.numericText())

                levelMeter

                if permissionDenied {
                    Text("Microphone access is off. Enable it in Settings to record.")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.mapPin)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AtlasSpacing.xl)
                }

                recordButton

                if recordedURL != nil && !recorder.isRecording {
                    // Review the take before keeping it.
                    Button {
                        if let url = recordedURL { review.toggle(url: url) }
                    } label: {
                        HStack(spacing: AtlasSpacing.sm) {
                            Image(systemName: review.isPlaying ? "pause.fill" : "play.fill")
                            Text(review.isPlaying ? "Playing…" : "Play recording")
                        }
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.primaryText)
                        .padding(.horizontal, AtlasSpacing.xl)
                        .padding(.vertical, AtlasSpacing.md)
                        .overlay(Capsule().stroke(AtlasColors.secondaryText.opacity(0.5), lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    Button {
                        review.stop()
                        if let url = recordedURL { onFinish(url); dismiss() }
                    } label: {
                        Text("Use recording")
                            .font(AtlasTypography.caption)
                            .padding(.horizontal, AtlasSpacing.xl)
                            .padding(.vertical, AtlasSpacing.md)
                            .background(AtlasColors.mapPin)
                            .foregroundStyle(AtlasColors.background)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Text("Not happy with it? Tap the record button to try again.")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AtlasSpacing.xl)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AtlasColors.secondaryBackground)
            .navigationTitle("")
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("RECORD").font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.primaryText)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        _ = recorder.stop()
                        review.stop()
                        dismiss()
                    }
                    .font(AtlasTypography.caption)
                    .tint(AtlasColors.primaryText)
                }
            }
        }
    }

    private var recordButton: some View {
        Button {
            if recorder.isRecording {
                recordedURL = recorder.stop()
            } else {
                review.stop()   // stop any review playback before a new take
                Task {
                    let ok = await recorder.start()
                    permissionDenied = !ok
                    if ok { recordedURL = nil }
                }
            }
        } label: {
            ZStack {
                Circle()
                    .stroke(AtlasColors.mapPin, lineWidth: 4)
                    .frame(width: 84, height: 84)
                if recorder.isRecording {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AtlasColors.mapPin)
                        .frame(width: 32, height: 32)
                } else {
                    Circle()
                        .fill(AtlasColors.mapPin)
                        .frame(width: 64, height: 64)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(recorder.isRecording ? "Stop recording" : "Start recording")
    }

    private func timeString(_ t: TimeInterval) -> String {
        let s = Int(t)
        return String(format: "%02d:%02d", s / 60, s % 60)
    }
}

/// Plays back the just-recorded file so the user can review a take before
/// keeping it. Separate from the app's `AudioPlayerService` (which is for tour
/// playback) — this only touches the temp recording inside the record sheet.
@MainActor
@Observable
final class RecordingReviewPlayer: NSObject, AVAudioPlayerDelegate {
    private(set) var isPlaying = false
    private var player: AVAudioPlayer?

    func toggle(url: URL) {
        if isPlaying { pause() } else { play(url: url) }
    }

    private func play(url: URL) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            if player?.url != url {
                player = try AVAudioPlayer(contentsOf: url)
                player?.delegate = self
            }
            player?.play()
            isPlaying = true
        } catch {
            isPlaying = false
        }
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    /// Stop and release the session — call on re-record, keep, or dismiss.
    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in self.isPlaying = false }
    }
}

/// Thin wrapper around `AVAudioRecorder` for the record sheet.
@MainActor
@Observable
final class AudioRecorder {
    private(set) var isRecording = false
    private(set) var elapsed: TimeInterval = 0
    private(set) var lastDuration: TimeInterval = 0

    /// The last second or so of input level, newest last, each 0...1. Drives
    /// the visualiser — without it the only sign a recording is happening is a
    /// counter, which ticks along just as happily with a muted mic.
    private(set) var levels: [CGFloat] = Array(repeating: 0, count: Self.levelCount)
    static let levelCount = 28

    private var recorder: AVAudioRecorder?
    private var url: URL?
    private var tickTask: Task<Void, Never>?

    /// Request mic permission and begin recording to a temp m4a. Returns false
    /// if permission is denied or setup fails.
    func start() async -> Bool {
        let granted = await withCheckedContinuation { cont in
            AVAudioApplication.requestRecordPermission { cont.resume(returning: $0) }
        }
        guard granted else { return false }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
            let fileURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("recording-\(UUID().uuidString).m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            let rec = try AVAudioRecorder(url: fileURL, settings: settings)
            rec.isMeteringEnabled = true
            rec.record()
            recorder = rec
            url = fileURL
            isRecording = true
            elapsed = 0
            levels = Array(repeating: 0, count: Self.levelCount)
            startTimer()
            return true
        } catch {
            return false
        }
    }

    /// Stop recording; returns the recorded file URL (nil if nothing recorded).
    @discardableResult
    func stop() -> URL? {
        guard isRecording else { return url }
        lastDuration = recorder?.currentTime ?? elapsed
        recorder?.stop()
        tickTask?.cancel()
        tickTask = nil
        isRecording = false
        levels = Array(repeating: 0, count: Self.levelCount)
        try? AVAudioSession.sharedInstance().setActive(false)
        return url
    }

    /// Main-actor async loop that mirrors the recorder's clock into `elapsed`
    /// and its input level into `levels` (avoids a `Timer` closure crossing the
    /// concurrency boundary). 20 Hz — fast enough that the bars track speech,
    /// slow enough to cost nothing.
    private func startTimer() {
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 50_000_000)
                guard let self, let rec = self.recorder, rec.isRecording else { break }
                self.elapsed = rec.currentTime
                rec.updateMeters()
                self.levels.removeFirst()
                self.levels.append(Self.normalised(rec.averagePower(forChannel: 0)))
            }
        }
    }

    /// Turn decibels into a bar height. `averagePower` runs from about -160 dB
    /// (silence) to 0 dB (clipping), but speech at a sane distance sits around
    /// -35 to -10 — so a linear map of the full range would leave every bar
    /// flat against the floor. This treats -50 as the bottom and curves the
    /// result so quiet speech still visibly moves.
    nonisolated static func normalised(_ decibels: Float) -> CGFloat {
        let floorDB: Float = -50
        guard decibels.isFinite else { return 0 }
        let clamped = max(floorDB, min(0, decibels))
        let linear = (clamped - floorDB) / -floorDB          // 0...1
        return CGFloat(pow(linear, 1.5))
    }
}
