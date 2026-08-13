import AVFoundation

final class MicrophoneCapture: @unchecked Sendable {
    private let engine = AVAudioEngine()
    private var isCapturing = false

    func start(onBuffer: @escaping @Sendable (AVAudioPCMBuffer) -> Void) throws {
        guard !isCapturing else { return }
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw NSError(
                domain: "LiveCaption.Microphone",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "麦克风没有可用的音频格式。"]
            )
        }

        input.installTap(onBus: 0, bufferSize: 2_048, format: format) { buffer, _ in
            onBuffer(buffer)
        }
        engine.prepare()
        try engine.start()
        isCapturing = true
    }

    func stop() {
        guard isCapturing else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isCapturing = false
    }
}
