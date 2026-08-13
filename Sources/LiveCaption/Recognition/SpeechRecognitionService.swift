import AVFoundation
import CoreMedia
import Foundation
import Speech

final class SpeechRecognitionService: @unchecked Sendable {
    private let lock = NSLock()
    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var locale: Locale?
    private var contextualStrings: [String] = []
    private var resultHandler: (@Sendable (String, Bool) -> Void)?
    private var intentionallyStopped = false

    static func requestAuthorization() async throws {
        let status: SFSpeechRecognizerAuthorizationStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        guard status == .authorized else {
            throw LiveCaptionError.speechPermissionDenied
        }
    }

    func start(
        locale: Locale,
        contextualStrings: [String] = [],
        onResult: @escaping @Sendable (String, Bool) -> Void
    ) throws {
        stop()
        guard let recognizer = SFSpeechRecognizer(locale: locale),
              recognizer.supportsOnDeviceRecognition else {
            throw LiveCaptionError.onDeviceRecognitionUnavailable(locale.localizedString(forIdentifier: locale.identifier) ?? locale.identifier)
        }

        lock.lock()
        self.locale = locale
        self.contextualStrings = contextualStrings
        self.recognizer = recognizer
        self.resultHandler = onResult
        intentionallyStopped = false
        lock.unlock()
        beginRecognitionTask()
    }

    func append(_ buffer: AVAudioPCMBuffer) {
        lock.lock()
        let request = request
        lock.unlock()
        request?.append(buffer)
    }

    func append(_ sampleBuffer: CMSampleBuffer) {
        lock.lock()
        let request = request
        lock.unlock()
        request?.appendAudioSampleBuffer(sampleBuffer)
    }

    func stop() {
        lock.lock()
        intentionallyStopped = true
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        recognizer = nil
        locale = nil
        contextualStrings = []
        resultHandler = nil
        lock.unlock()
    }

    private func beginRecognitionTask() {
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true
        request.taskHint = .dictation
        lock.lock()
        request.contextualStrings = contextualStrings
        lock.unlock()

        lock.lock()
        guard !intentionallyStopped, let recognizer else {
            lock.unlock()
            return
        }
        self.request = request
        lock.unlock()

        let task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result {
                self.lock.lock()
                let handler = self.resultHandler
                self.lock.unlock()
                handler?(result.bestTranscription.formattedString, result.isFinal)
            }

            if result?.isFinal == true || error != nil {
                self.restartAfterCompletion()
            }
        }

        lock.lock()
        if intentionallyStopped {
            task.cancel()
        } else {
            self.task = task
        }
        lock.unlock()
    }

    private func restartAfterCompletion() {
        lock.lock()
        guard !intentionallyStopped else {
            lock.unlock()
            return
        }
        request = nil
        task = nil
        lock.unlock()
        beginRecognitionTask()
    }
}
