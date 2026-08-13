import Testing
@testable import LiveCaption

@Suite("Caption formatting")
struct CaptionFormatterTests {
    @Test("Short captions are unchanged")
    func shortCaption() {
        #expect(CaptionFormatter.tail("Hello world", limit: 20) == "Hello world")
    }

    @Test("Long captions retain only a readable tail")
    func longCaption() {
        let result = CaptionFormatter.tail("one two three four five", limit: 14)
        #expect(result == "four five")
    }

    @Test("Whitespace is normalized for smooth wrapping")
    func normalizesWhitespace() {
        #expect(CaptionFormatter.tail("one\n  two\tthree") == "one two three")
    }

    @Test("Caption tails never exceed the requested budget")
    func respectsBudget() {
        let result = CaptionFormatter.tail(String(repeating: "word ", count: 80), limit: 120)
        #expect(result.count <= 120)
        #expect(!result.hasPrefix(" "))
    }
}
