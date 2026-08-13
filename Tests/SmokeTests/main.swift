import Foundation

private func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

expect(
    CaptionFormatter.tail("Hello world", limit: 20) == "Hello world",
    "short captions should be unchanged"
)

expect(
    CaptionFormatter.tail("one two three four five", limit: 14) == "four five",
    "long captions should retain a readable tail"
)

expect(
    CaptionLanguage.supported.contains(.simplifiedChinese),
    "Simplified Chinese should be available"
)

expect(
    CaptionFormatter.tail("one\n  two\tthree") == "one two three",
    "caption whitespace should be normalized"
)

expect(
    CaptionFormatter.tail(String(repeating: "word ", count: 80), limit: 120).count <= 120,
    "caption tails should remain inside their character budget"
)

expect(
    CS2Glossary.prepareForTranslation(
        "They win the force buy and now save the AWP",
        sourceLanguageID: "en-US",
        targetLanguageID: "zh-Hans"
    ).contains("[强起]"),
    "CS2 glossary should protect known terms before translation"
)

expect(
    CS2Glossary.recognitionHints.contains("AWP"),
    "CS2 recognition hints should include equipment names"
)

print("All Live Caption smoke tests passed.")
