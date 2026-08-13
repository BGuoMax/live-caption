import Foundation

enum AudioSource: String, CaseIterable, Identifiable {
    case system = "电脑声音"
    case microphone = "麦克风"

    var id: Self { self }

    var symbol: String {
        switch self {
        case .system: "speaker.wave.2.fill"
        case .microphone: "mic.fill"
        }
    }
}

struct CaptionLanguage: Identifiable, Hashable {
    let id: String
    let name: String

    var locale: Locale { Locale(identifier: id) }
    var language: Locale.Language { Locale.Language(identifier: id) }

    static let supported: [CaptionLanguage] = [
        .init(id: "en-US", name: "英语"),
        .init(id: "zh-Hans", name: "简体中文"),
        .init(id: "zh-Hant", name: "繁体中文"),
        .init(id: "ja-JP", name: "日语"),
        .init(id: "ko-KR", name: "韩语"),
        .init(id: "es-ES", name: "西班牙语"),
        .init(id: "fr-FR", name: "法语"),
        .init(id: "de-DE", name: "德语"),
        .init(id: "it-IT", name: "意大利语"),
        .init(id: "pt-BR", name: "葡萄牙语"),
        .init(id: "ru-RU", name: "俄语")
    ]

    static let english = supported[0]
    static let simplifiedChinese = supported[1]
}

enum CaptionFormatter {
    static func tail(_ text: String, limit: Int = 140) -> String {
        let normalized = text
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")

        guard normalized.count > limit else { return normalized }
        let start = normalized.index(normalized.endIndex, offsetBy: -limit)
        let suffix = normalized[start...]
        if let boundary = suffix.firstIndex(where: { $0.isWhitespace || "，。！？,.!?".contains($0) }) {
            return String(suffix[suffix.index(after: boundary)...])
        }
        return String(suffix)
    }
}
