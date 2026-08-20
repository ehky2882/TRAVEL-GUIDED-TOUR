import SwiftUI
import AVFoundation

/// The moving parts of the Audio step: the level meter, the record button,
/// and the two engines behind them.
///
/// **The layout that uses these lives in `TourAudioSection`**, deliberately.
/// This file used to hold a whole panel that appeared *while* recording and
/// vanished afterwards — which is why the step looked like four unrelated
/// screens depending on what you had done to it. Owner, 2026-08-20: *"all
/// steps should look like a version of 'reviewing a take'. it should not
/// differ so much which step you're on."* A single skeleton can only be read
/// in one place, so the skeleton moved to the step and these stayed here.

/// The live input level, drawn.
///
/// Not decoration: without it the only sign a recording is happening is a
/// counter, and a counter ticks along just as happily with a muted microphone
/// or a thumb over it — the maker finds out afterwards. Bars run oldest to
/// newest and sit at a visible floor when idle, so the meter reads as a meter
/// rather than as nothing.
struct AudioLevelMeter: View {
    let levels: [CGFloat]
    let isLive: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(Array(levels.enumerated()), id: \.offset) { _, level in
                Capsule()
                    .fill(isLive ? AtlasColors.mapPin : AtlasColors.divider)
                    .frame(width: 3, height: max(3, level * 44))
            }
        }
        .frame(height: 44)
        .animation(.linear(duration: 0.05), value: levels)
        .accessibilityHidden(true)
    }
}

/// The one control that is in the same place in every state of the step.
struct RecordButton: View {
    let isRecording: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(AtlasColors.mapPin, lineWidth: 4)
                    .frame(width: 72, height: 72)
                if isRecording {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AtlasColors.mapPin)
                        .frame(width: 26, height: 26)
                } else {
                    Circle()
                        .fill(AtlasColors.mapPin)
                        .frame(width: 54, height: 54)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isRecording ? "Stop recording" : "Start recording")
    }
}

/// Plays back the just-recorded file so the user can review a take before
/// keeping it. Separate from the app's `AudioPlayerService` (which is for tour
/// playback) — this only touches the temp recording on the Audio step.
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

/// Thin wrapper around `AVAudioRecorder` for the Audio step.
@MainActor
@Observable
final class AudioRecorder {
    private(set) var isRecording = false
    private(set) var elapsed: TimeInterval = 0
    private(set) var lastDuration: TimeInterval = 0

    /// The last second or so of input level, newest last, each 0...1. Drives
    /// the visualiser — without it the only sign a recording is happening is a
    /// counter, which ticks along just as happily with a muted mic.
    private(set) var levels: [CGFloat] = Array(repeating: 0, count: AudioRecorder.levelCount)
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
