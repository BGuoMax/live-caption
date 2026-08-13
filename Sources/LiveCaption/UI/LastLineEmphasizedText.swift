import AppKit
import SwiftUI

/// Wraps translated captions into visual lines, then emphasizes only the latest line.
struct LastLineEmphasizedText: View {
    let text: String
    let fontSize: Double
    let maximumLines: Int

    var body: some View {
        GeometryReader { proxy in
            let lines = CaptionLineBreaker.lines(
                in: text,
                width: max(proxy.size.width, 1),
                fontSize: fontSize,
                maximumLines: maximumLines
            )

            VStack(spacing: 4) {
                Spacer(minLength: 0)

                ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                    Text(line)
                        .font(
                            .system(
                                size: fontSize,
                                weight: index == lines.count - 1 ? .bold : .regular,
                                design: .rounded
                            )
                        )
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .allowsTightening(true)
                        .frame(maxWidth: .infinity)
                }

                Spacer(minLength: 0)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }
}

@MainActor
enum CaptionLineBreaker {
    static func lines(
        in text: String,
        width: CGFloat,
        fontSize: Double,
        maximumLines: Int
    ) -> [String] {
        let normalized = text
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
        guard !normalized.isEmpty else { return ["…"] }

        let font = NSFont.systemFont(ofSize: fontSize, weight: .regular)
        let attributedText = NSAttributedString(
            string: normalized,
            attributes: [.font: font]
        )
        let ranges = visualLineRanges(in: attributedText, width: width)
        let source = normalized as NSString
        let allLines = ranges.map { range in
            source.substring(with: range)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        .filter { !$0.isEmpty }

        return Array(allLines.suffix(max(1, maximumLines)))
    }

    private static func visualLineRanges(
        in attributedText: NSAttributedString,
        width: CGFloat
    ) -> [NSRange] {
        let storage = NSTextStorage(attributedString: attributedText)
        let layoutManager = NSLayoutManager()
        let container = NSTextContainer(
            size: NSSize(width: max(width, 1), height: .greatestFiniteMagnitude)
        )
        container.lineFragmentPadding = 0
        container.lineBreakMode = .byWordWrapping
        storage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(container)
        layoutManager.ensureLayout(for: container)

        var ranges: [NSRange] = []
        let glyphRange = layoutManager.glyphRange(for: container)
        layoutManager.enumerateLineFragments(forGlyphRange: glyphRange) { _, _, _, lineGlyphRange, _ in
            ranges.append(
                layoutManager.characterRange(
                    forGlyphRange: lineGlyphRange,
                    actualGlyphRange: nil
                )
            )
        }
        return ranges
    }
}
