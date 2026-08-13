import AVFoundation
import Foundation
import Speech
@preconcurrency import Translation

@MainActor
final class AppModel: ObservableObject {
    private struct TranslationJob: Sendable {
        let text: String
        var isFinal: Bool
        let recognitionGeneration: Int
    }

    @Published var audioSource: AudioSource = .system
    @Published var sourceLanguage: CaptionLanguage = .english
    @Published var targetLanguage: CaptionLanguage = .simplifiedChinese
    @Published var sourceText = "播放媒体或对着麦克风说话后，原文会显示在这里"
    @Published var translatedText = "译文会显示在这里"
    @Published var statusText = "准备就绪"
    @Published var isRunning = false
    @Published var showOriginal = true {
        didSet { UserDefaults.standard.set(showOriginal, forKey: "showOriginal") }
    }
    @Published var fontSize = 32.0 {
        didSet { UserDefaults.standard.set(fontSize, forKey: "fontSize") }
    }
    @Published var panelOpacity = 0.86 {
        didSet { UserDefaults.standard.set(panelOpacity, forKey: "panelOpacity") }
    }
    @Published var cs2GlossaryEnabled = false {
        didSet { UserDefaults.standard.set(cs2GlossaryEnabled, forKey: "cs2GlossaryEnabled") }
    }
    @Published var saveTranscripts = true {
        didSet { UserDefaults.standard.set(saveTranscripts, forKey: "saveTranscripts") }
    }

    private let recognizer = SpeechRecognitionService()
    private let microphoneCapture = MicrophoneCapture()
    private let systemCapture = SystemAudioCapture()
    private let transcriptRecorder = TranscriptRecorder()
    private var translationSession: TranslationSession?
    private var translationTask: Task<Void, Never>?
    private var translationWorkerID: UUID?
    private var pendingTranslationJob: TranslationJob?
    private var translationIsPrepared = false
    private var recognitionGeneration = 0

    init() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "showOriginal") != nil {
            showOriginal = defaults.bool(forKey: "showOriginal")
        }
        if defaults.object(forKey: "fontSize") != nil {
            fontSize = min(max(defaults.double(forKey: "fontSize"), 20), 52)
        }
        if defaults.object(forKey: "panelOpacity") != nil {
            panelOpacity = min(max(defaults.double(forKey: "panelOpacity"), 0.25), 1)
        }
        if defaults.object(forKey: "cs2GlossaryEnabled") != nil {
            cs2GlossaryEnabled = defaults.bool(forKey: "cs2GlossaryEnabled")
        }
        if defaults.object(forKey: "saveTranscripts") != nil {
            saveTranscripts = defaults.bool(forKey: "saveTranscripts")
        }
    }

    var translationSource: Locale.Language { sourceLanguage.language }
    var translationTarget: Locale.Language { targetLanguage.language }

    func configureTranslation(_ session: TranslationSession) async {
        translationTask?.cancel()
        translationTask = nil
        translationWorkerID = nil
        translationIsPrepared = false
        translationSession = session
        do {
            statusText = isRunning ? "正在准备离线翻译…" : "正在准备离线翻译…"
            try await session.prepareTranslation()
            translationIsPrepared = true
            statusText = isRunning ? "正在听取\(audioSource.rawValue)…" : "准备就绪"
            startTranslationWorkerIfNeeded()
        } catch {
            statusText = "翻译语言包尚未就绪：\(error.localizedDescription)"
        }
    }

    func toggleCapture() {
        if isRunning {
            Task { await stop() }
        } else {
            Task { await start() }
        }
    }

    func start() async {
        guard !isRunning else { return }
        do {
            statusText = "正在请求语音识别权限…"
            try await SpeechRecognitionService.requestAuthorization()

            if audioSource == .microphone {
                statusText = "正在请求麦克风权限…"
                guard await AVCaptureDevice.requestAccess(for: .audio) else {
                    throw LiveCaptionError.microphonePermissionDenied
                }
            }

            sourceText = "正在等待语音…"
            translatedText = ""
            recognitionGeneration += 1
            let generation = recognitionGeneration

            if saveTranscripts {
                do {
                    try transcriptRecorder.begin(
                        audioSource: audioSource.rawValue,
                        sourceLanguage: sourceLanguage.name,
                        targetLanguage: targetLanguage.name,
                        cs2GlossaryEnabled: cs2GlossaryEnabled
                    )
                } catch {
                    statusText = "复盘记录创建失败，字幕仍会继续：\(error.localizedDescription)"
                }
            }

            try recognizer.start(
                locale: sourceLanguage.locale,
                contextualStrings: cs2GlossaryEnabled ? CS2Glossary.recognitionHints : []
            ) { [weak self] text, isFinal in
                Task { @MainActor [weak self] in
                    guard let self, self.recognitionGeneration == generation else { return }
                    self.receiveTranscript(text, isFinal: isFinal)
                }
            }

            switch audioSource {
            case .system:
                statusText = "正在连接电脑声音…"
                try await systemCapture.start { [weak self] sampleBuffer in
                    self?.recognizer.append(sampleBuffer)
                }
            case .microphone:
                try microphoneCapture.start { [weak self] buffer in
                    self?.recognizer.append(buffer)
                }
            }

            isRunning = true
            statusText = "正在听取\(audioSource.rawValue)…"
        } catch {
            await stop()
            statusText = error.localizedDescription
        }
    }

    func stop() async {
        recognitionGeneration += 1
        translationTask?.cancel()
        translationTask = nil
        translationWorkerID = nil
        pendingTranslationJob = nil
        microphoneCapture.stop()
        await systemCapture.stop()
        recognizer.stop()
        transcriptRecorder.finish()
        isRunning = false
        if statusText.hasPrefix("正在") {
            statusText = "已停止"
        }
    }

    private func receiveTranscript(_ text: String, isFinal: Bool) {
        let visibleText = CaptionFormatter.tail(text, limit: 140)
        guard !visibleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        sourceText = visibleText
        transcriptRecorder.update(original: visibleText, translation: "", isFinal: false)
        scheduleTranslation(of: visibleText, immediate: isFinal)
    }

    func openRecordsFolder() {
        do {
            try transcriptRecorder.openRecordsFolder()
            statusText = "已打开复盘记录文件夹"
        } catch {
            statusText = "无法打开复盘记录：\(error.localizedDescription)"
        }
    }

    private func scheduleTranslation(of text: String, immediate: Bool) {
        guard sourceLanguage.id != targetLanguage.id else {
            pendingTranslationJob = nil
            translatedText = text
            transcriptRecorder.update(original: text, translation: text, isFinal: immediate)
            return
        }

        let newJob = TranslationJob(
            text: text,
            isFinal: immediate,
            recognitionGeneration: recognitionGeneration
        )
        if var pendingJob = pendingTranslationJob,
           pendingJob.text == text,
           pendingJob.recognitionGeneration == recognitionGeneration {
            pendingJob.isFinal = pendingJob.isFinal || immediate
            pendingTranslationJob = pendingJob
        } else {
            // 快速语音会产生大量部分识别结果。只保留最新一条，避免译文无限落后。
            pendingTranslationJob = newJob
        }

        guard translationSession != nil, translationIsPrepared else {
            translatedText = "正在准备翻译语言包…"
            transcriptRecorder.update(original: text, translation: "", isFinal: false)
            return
        }
        startTranslationWorkerIfNeeded()
    }

    private func startTranslationWorkerIfNeeded() {
        guard translationTask == nil,
              translationSession != nil,
              translationIsPrepared,
              pendingTranslationJob != nil else { return }

        let workerID = UUID()
        translationWorkerID = workerID
        translationTask = Task { @MainActor [weak self] in
            await self?.runTranslationWorker(id: workerID)
        }
    }

    private func runTranslationWorker(id workerID: UUID) async {
        var shouldCoalesceInitialPartial = true

        while !Task.isCancelled, translationWorkerID == workerID {
            guard var job = pendingTranslationJob else { break }
            pendingTranslationJob = nil
            guard job.recognitionGeneration == recognitionGeneration else { continue }

            if shouldCoalesceInitialPartial, !job.isFinal {
                do {
                    try await Task.sleep(for: .milliseconds(80))
                } catch {
                    break
                }
                guard !Task.isCancelled, translationWorkerID == workerID else { break }

                // 在很短的合并窗口内又有新文本时，直接翻译最新版本。
                if let newerJob = pendingTranslationJob,
                   newerJob.recognitionGeneration == recognitionGeneration {
                    job = newerJob
                    pendingTranslationJob = nil
                }
            }
            shouldCoalesceInitialPartial = false

            guard let translationSession, translationIsPrepared else {
                pendingTranslationJob = job
                break
            }

            do {
                let translationInput = cs2GlossaryEnabled
                    ? CS2Glossary.prepareForTranslation(
                        job.text,
                        sourceLanguageID: sourceLanguage.id,
                        targetLanguageID: targetLanguage.id
                    )
                    : job.text
                let response = try await translationSession.translate(translationInput)
                guard !Task.isCancelled,
                      translationWorkerID == workerID,
                      job.recognitionGeneration == recognitionGeneration else { break }

                let normalizedTranslation = cs2GlossaryEnabled
                    ? CS2Glossary.normalizeTranslation(
                        response.targetText,
                        targetLanguageID: targetLanguage.id
                    )
                    : response.targetText
                let fullTranslation = normalizedTranslation
                    .split(whereSeparator: { $0.isWhitespace })
                    .joined(separator: " ")
                translatedText = CaptionFormatter.tail(fullTranslation, limit: 120)
                transcriptRecorder.update(
                    original: job.text,
                    translation: fullTranslation,
                    isFinal: job.isFinal
                )
            } catch is CancellationError {
                break
            } catch {
                statusText = "翻译失败：\(error.localizedDescription)"
            }
        }

        guard translationWorkerID == workerID else { return }
        translationTask = nil
        translationWorkerID = nil
        if pendingTranslationJob != nil {
            startTranslationWorkerIfNeeded()
        }
    }
}

enum LiveCaptionError: LocalizedError {
    case microphonePermissionDenied
    case speechPermissionDenied
    case screenCapturePermissionDenied
    case onDeviceRecognitionUnavailable(String)
    case noDisplayAvailable

    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            "未获得麦克风权限，请到“系统设置 → 隐私与安全性 → 麦克风”中允许。"
        case .speechPermissionDenied:
            "未获得语音识别权限，请到“系统设置 → 隐私与安全性 → 语音识别”中允许。"
        case .screenCapturePermissionDenied:
            "电脑声音权限尚未生效。请到“系统设置 → 隐私与安全性 → 屏幕与系统音频录制”打开 Live Caption，然后完全退出并重新打开应用。"
        case .onDeviceRecognitionUnavailable(let language):
            "\(language)的设备端语音识别不可用，请先在系统设置中下载对应语言。"
        case .noDisplayAvailable:
            "没有找到可用于捕获电脑声音的显示器。"
        }
    }
}
