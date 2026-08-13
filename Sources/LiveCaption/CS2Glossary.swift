import Foundation

enum CS2Glossary {
    struct Term: Sendable {
        let source: String
        let translated: String
    }

    /// Longer phrases come first so "force buy" is handled before "buy".
    static let terms: [Term] = [
        .init(source: "counter-terrorist side", translated: "CT方"),
        .init(source: "terrorist side", translated: "T方"),
        .init(source: "anti-eco round", translated: "反经济局"),
        .init(source: "economic damage", translated: "经济打击"),
        .init(source: "ninja defuse", translated: "偷拆"),
        .init(source: "opening duel", translated: "首杀对位"),
        .init(source: "spray transfer", translated: "压枪转火"),
        .init(source: "incendiary grenade", translated: "燃烧弹"),
        .init(source: "high explosive grenade", translated: "高爆手雷"),
        .init(source: "counter-terrorist", translated: "CT"),
        .init(source: "pistol round", translated: "手枪局"),
        .init(source: "trade frag", translated: "补枪"),
        .init(source: "trade kill", translated: "补枪"),
        .init(source: "entry frag", translated: "首杀"),
        .init(source: "entry fragger", translated: "突破手"),
        .init(source: "exit frag", translated: "断枪"),
        .init(source: "force buy", translated: "强起"),
        .init(source: "full buy", translated: "长枪局"),
        .init(source: "half buy", translated: "半起"),
        .init(source: "anti-eco", translated: "反经济局"),
        .init(source: "eco round", translated: "经济局"),
        .init(source: "save round", translated: "保枪局"),
        .init(source: "match point", translated: "赛点"),
        .init(source: "map point", translated: "地图点"),
        .init(source: "bomb site", translated: "包点"),
        .init(source: "bombsite", translated: "包点"),
        .init(source: "post-plant", translated: "下包后"),
        .init(source: "dry peek", translated: "干拉"),
        .init(source: "jiggle peek", translated: "小身位侦查"),
        .init(source: "wide swing", translated: "大拉"),
        .init(source: "double peek", translated: "双拉"),
        .init(source: "one tap", translated: "一发爆头"),
        .init(source: "crossfire", translated: "交叉火力"),
        .init(source: "flash assist", translated: "闪光助攻"),
        .init(source: "flashbang", translated: "闪光弹"),
        .init(source: "smoke grenade", translated: "烟雾弹"),
        .init(source: "molotov", translated: "燃烧弹"),
        .init(source: "incendiary", translated: "燃烧弹"),
        .init(source: "HE grenade", translated: "高爆手雷"),
        .init(source: "defuse kit", translated: "拆弹器"),
        .init(source: "bomb plant", translated: "下包"),
        .init(source: "counter-strike 2", translated: "CS2"),
        .init(source: "MR12", translated: "MR12赛制"),
        .init(source: "best of one", translated: "一局定胜负"),
        .init(source: "best of three", translated: "三局两胜"),
        .init(source: "best of five", translated: "五局三胜"),
        .init(source: "AWPer", translated: "狙击手"),
        .init(source: "in-game leader", translated: "场上指挥"),
        .init(source: "IGL", translated: "指挥"),
        .init(source: "utility", translated: "道具"),
        .init(source: "execute", translated: "爆弹"),
        .init(source: "default", translated: "默认控图"),
        .init(source: "rotate", translated: "转点"),
        .init(source: "rotation", translated: "转点"),
        .init(source: "retake", translated: "回防"),
        .init(source: "clutch", translated: "残局"),
        .init(source: "ace", translated: "五杀"),
        .init(source: "entry", translated: "突破"),
        .init(source: "trade", translated: "补枪"),
        .init(source: "lurker", translated: "单摸选手"),
        .init(source: "lurk", translated: "单摸"),
        .init(source: "flank", translated: "绕后"),
        .init(source: "fake", translated: "假打"),
        .init(source: "save", translated: "保枪"),
        .init(source: "eco", translated: "经济局"),
        .init(source: "peek", translated: "拉枪"),
        .init(source: "prefire", translated: "提前枪"),
        .init(source: "wallbang", translated: "穿射"),
        .init(source: "dink", translated: "叮头"),
        .init(source: "collateral", translated: "一枪双杀"),
        .init(source: "headshot", translated: "爆头"),
        .init(source: "boost", translated: "架人"),
        .init(source: "overtime", translated: "加时"),
        .init(source: "map veto", translated: "地图禁选"),
        .init(source: "Major", translated: "Major大赛"),
        .init(source: "RMR", translated: "RMR预选赛")
    ]

    static let recognitionHints: [String] = {
        let equipment = [
            "CS2", "Counter-Strike 2", "AWP", "AWPer", "AK-47", "M4A1-S", "M4A4",
            "Desert Eagle", "Deagle", "Glock-18", "USP-S", "P250", "Tec-9",
            "Five-SeveN", "Galil AR", "FAMAS", "MP9", "MAC-10", "UMP-45",
            "SSG 08", "Scout", "XM1014", "MAG-7", "Nova", "Negev"
        ]
        let maps = [
            "Ancient", "Anubis", "Dust II", "Inferno", "Mirage", "Nuke",
            "Overpass", "Train", "Vertigo", "Cache"
        ]
        let formats = ["BO1", "BO3", "BO5", "MR12", "Major", "RMR", "map veto"]
        return Array(Set(terms.map(\.source) + equipment + maps + formats)).sorted()
    }()

    static func prepareForTranslation(
        _ text: String,
        sourceLanguageID: String,
        targetLanguageID: String
    ) -> String {
        guard sourceLanguageID.hasPrefix("en"), targetLanguageID.hasPrefix("zh") else {
            return text
        }

        var result = text
        for term in terms.sorted(by: { $0.source.count > $1.source.count }) {
            result = replacingTerm(term.source, with: "[\(term.translated)]", in: result)
        }
        return result
    }

    static func normalizeTranslation(_ text: String, targetLanguageID: String) -> String {
        guard targetLanguageID.hasPrefix("zh") else { return text }
        return text
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
            .replacingOccurrences(of: "【", with: "")
            .replacingOccurrences(of: "】", with: "")
    }

    private static func replacingTerm(_ term: String, with replacement: String, in text: String) -> String {
        let escaped = NSRegularExpression.escapedPattern(for: term)
        let pattern = "(?i)(?<![A-Za-z0-9])\(escaped)(?![A-Za-z0-9])"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.stringByReplacingMatches(in: text, range: range, withTemplate: replacement)
    }
}
