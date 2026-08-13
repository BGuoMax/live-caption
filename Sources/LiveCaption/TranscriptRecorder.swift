import AppKit
import Foundation

struct TranscriptEntry: Codable, Identifiable, Sendable {
    let id: UUID
    let timestamp: Date
    var original: String
    var translation: String
}

struct TranscriptSession: Codable, Sendable {
    let id: UUID
    let startedAt: Date
    var endedAt: Date?
    let audioSource: String
    let sourceLanguage: String
    let targetLanguage: String
    let cs2GlossaryEnabled: Bool
    var entries: [TranscriptEntry]
}

@MainActor
final class TranscriptRecorder {
    private(set) var session: TranscriptSession?
    private var draft: TranscriptEntry?
    private var markdownURL: URL?
    private var jsonURL: URL?

    static var recordsDirectory: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("Live Caption Records", isDirectory: true)
    }

    func begin(
        audioSource: String,
        sourceLanguage: String,
        targetLanguage: String,
        cs2GlossaryEnabled: Bool
    ) throws {
        try FileManager.default.createDirectory(
            at: Self.recordsDirectory,
            withIntermediateDirectories: true
        )

        let now = Date()
        let id = UUID()
        session = TranscriptSession(
            id: id,
            startedAt: now,
            endedAt: nil,
            audioSource: audioSource,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            cs2GlossaryEnabled: cs2GlossaryEnabled,
            entries: []
        )
        draft = nil

        let filename = "Live Caption \(Self.fileDateFormatter.string(from: now))"
        markdownURL = Self.recordsDirectory.appendingPathComponent(filename).appendingPathExtension("md")
        jsonURL = Self.recordsDirectory.appendingPathComponent(filename).appendingPathExtension("json")
        try persist()
    }

    func update(original: String, translation: String, isFinal: Bool) {
        guard session != nil else { return }
        let normalizedOriginal = Self.normalized(original)
        let normalizedTranslation = Self.normalized(translation)
        guard !normalizedOriginal.isEmpty else { return }

        if draft == nil {
            draft = TranscriptEntry(
                id: UUID(),
                timestamp: Date(),
                original: normalizedOriginal,
                translation: normalizedTranslation
            )
        } else {
            draft?.original = normalizedOriginal
            draft?.translation = normalizedTranslation
        }

        if isFinal {
            finalizeDraft()
        }
        try? persist()
    }

    func finish() {
        guard session != nil else { return }
        finalizeDraft()
        session?.endedAt = Date()
        try? persist()
        session = nil
        draft = nil
        markdownURL = nil
        jsonURL = nil
    }

    func openRecordsFolder() throws {
        try FileManager.default.createDirectory(
            at: Self.recordsDirectory,
            withIntermediateDirectories: true
        )
        NSWorkspace.shared.open(Self.recordsDirectory)
    }

    private func finalizeDraft() {
        guard let draft else { return }
        if session?.entries.last?.original != draft.original
            || session?.entries.last?.translation != draft.translation {
            session?.entries.append(draft)
        }
        self.draft = nil
    }

    private func persist() throws {
        guard var snapshot = session, let markdownURL, let jsonURL else { return }
        if let draft {
            snapshot.entries.append(draft)
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(snapshot).write(to: jsonURL, options: .atomic)
        try Self.markdown(for: snapshot).write(to: markdownURL, atomically: true, encoding: .utf8)
    }

    private static func markdown(for session: TranscriptSession) -> String {
        var lines = [
            "# Live Caption 复盘记录",
            "",
            "- 开始：\(displayDateFormatter.string(from: session.startedAt))",
            "- 结束：\(session.endedAt.map(displayDateFormatter.string(from:)) ?? "记录中")",
            "- 声音来源：\(session.audioSource)",
            "- 原文语言：\(session.sourceLanguage)",
            "- 译文语言：\(session.targetLanguage)",
            "- CS2 词库：\(session.cs2GlossaryEnabled ? "开启" : "关闭")",
            "",
            "---",
            ""
        ]

        for entry in session.entries {
            lines.append("## \(timeFormatter.string(from: entry.timestamp))")
            lines.append("")
            lines.append("**原文**")
            lines.append("")
            lines.append(entry.original)
            lines.append("")
            lines.append("**译文**")
            lines.append("")
            lines.append(entry.translation.isEmpty ? "（等待译文）" : entry.translation)
            lines.append("")
        }
        return lines.joined(separator: "\n") + "\n"
    }

    private static func normalized(_ text: String) -> String {
        text.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }

    private static let fileDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
        return formatter
    }()

    private static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}
