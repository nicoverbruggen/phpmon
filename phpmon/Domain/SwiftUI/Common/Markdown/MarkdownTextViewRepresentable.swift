//
//  MarkdownTextViewRepresentable.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 27/02/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import SwiftUI
import AppKit

/**
 Bridges a `CodeBlockTextView` into SwiftUI and builds an attributed string
 from a simplified Markdown subset (inline code, bold and italic).
 */
struct MarkdownTextViewRepresentable: NSViewRepresentable {
    let string: String
    let fontSize: CGFloat
    let textColor: NSColor

    // MARK: - NSViewRepresentable

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> CodeBlockTextView {
        let textView = CodeBlockTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.textContainerInset = .zero
        textView.textContainer?.lineFragmentPadding = 0
        textView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
        configure(textView, coordinator: context.coordinator)
        return textView
    }

    func updateNSView(
        _ textView: CodeBlockTextView,
        context: Context
    ) {
        let coordinator = context.coordinator
        guard string != coordinator.lastString || fontSize != coordinator.lastFontSize || textColor != coordinator.lastTextColor else { return }
        configure(textView, coordinator: coordinator)
    }

    private func configure(
        _ textView: CodeBlockTextView,
        coordinator: Coordinator
    ) {
        coordinator.lastString = string
        coordinator.lastFontSize = fontSize
        coordinator.lastTextColor = textColor
        let attributed = Self.buildAttributedString(from: string, fontSize: fontSize, textColor: textColor)
        textView.textStorage?.setAttributedString(attributed)
        textView.invalidateIntrinsicContentSize()
    }

    class Coordinator {
        var lastString: String?
        var lastFontSize: CGFloat?
        var lastTextColor: NSColor?
    }

    // MARK: - Attributed String Builder

    // swiftlint:disable force_try
    private static let codeRegex = try! NSRegularExpression(pattern: "`([^`]+)`")
    private static let boldRegex = try! NSRegularExpression(pattern: "\\*\\*([^*]+)\\*\\*")
    private static let italicRegex = try! NSRegularExpression(pattern: "(?<!\\*)\\*([^*]+)\\*(?!\\*)")
    // swiftlint:enable force_try

    static func buildAttributedString(
        from string: String,
        fontSize: CGFloat,
        textColor: NSColor = .labelColor
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let font = NSFont.systemFont(ofSize: fontSize)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2
        paragraphStyle.paragraphSpacing = -4

        let defaultAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle
        ]

        result.append(NSAttributedString(string: string, attributes: defaultAttributes))

        // Apply markup passes (order matters: code first to avoid matching * inside code spans)
        handleCodeMarkup(in: result, fontSize: fontSize, paragraphStyle: paragraphStyle)

        // Collect code span ranges once for bold and italic passes
        let codeRanges = codeSpanRanges(in: result)

        // Handle bold markup
        handleStyledMarkup(
            in: result,
            regex: boldRegex,
            font: NSFont.boldSystemFont(ofSize: fontSize),
            paragraphStyle: paragraphStyle,
            textColor: textColor,
            codeRanges: codeRanges
        )

        // Handle italic markup
        handleStyledMarkup(
            in: result,
            regex: italicRegex,
            font: NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask),
            paragraphStyle: paragraphStyle,
            textColor: textColor,
            codeRanges: codeRanges
        )

        return result
    }

    // MARK: - Markup Handlers

    /**
     Replaces `` `code` `` with monospaced font and padding spaces.

     The leading thin space is breakable so the code span can shift to the next line
     as a whole, while the trailing narrow no-break space stays glued to the span.
     Spaces and hyphens inside the code span are made non-breaking so the layout
     engine never splits the code span across lines.
     */
    private static func handleCodeMarkup(
        in result: NSMutableAttributedString,
        fontSize: CGFloat,
        paragraphStyle: NSParagraphStyle
    ) {
        let codeFont = NSFont.monospacedSystemFont(ofSize: fontSize - 1, weight: .regular)

        let fullRange = NSRange(location: 0, length: result.length)
        let matches = codeRegex.matches(in: result.string, range: fullRange).reversed()

        for match in matches {
            let innerRange = match.range(at: 1)

            // Make the code span non-breaking by replacing spaces and joining hyphens
            let innerText = (result.string as NSString).substring(with: innerRange)
                .replacingOccurrences(of: " ", with: String(Character.nbSpace))
                .replacingOccurrences(of: "-", with: "-\(Character.wordJoiner)")

            let spaceAttributes: [NSAttributedString.Key: Any] = [
                .font: codeFont,
                .foregroundColor: NSColor.labelColor,
                .paragraphStyle: paragraphStyle
            ]

            let replacement = NSMutableAttributedString()
            replacement.append(NSAttributedString(string: String(Character.thinSpace), attributes: spaceAttributes))
            replacement.append(NSAttributedString(
                string: innerText,
                attributes: spaceAttributes.merging([.codeSpan: true]) { _, new in new }
            ))
            replacement.append(NSAttributedString(string: String(Character.nbThinSpace), attributes: spaceAttributes))

            result.replaceCharacters(in: match.range, with: replacement)
        }
    }

    /**
     Collects all ranges marked as code spans.
     */
    private static func codeSpanRanges(
        in result: NSMutableAttributedString
    ) -> [NSRange] {
        var ranges: [NSRange] = []
        result.enumerateAttribute(.codeSpan, in: NSRange(location: 0, length: result.length)) { value, range, _ in
            if value != nil { ranges.append(range) }
        }
        return ranges
    }

    /**
     Replaces markup like `**bold**` or `*italic*` with the appropriate font,
     skipping any matches that overlap with an already-processed code span.
     */
    private static func handleStyledMarkup(
        in result: NSMutableAttributedString,
        regex: NSRegularExpression,
        font: NSFont,
        paragraphStyle: NSParagraphStyle,
        textColor: NSColor,
        codeRanges: [NSRange]
    ) {
        let fullRange = NSRange(location: 0, length: result.length)
        let matches = regex.matches(in: result.string, range: fullRange).filter { match in
            !codeRanges.contains { NSIntersectionRange(match.range, $0).length > 0 }
        }

        for match in matches.reversed() {
            let innerRange = match.range(at: 1)
            let innerText = (result.string as NSString).substring(with: innerRange)

            let replacement = NSAttributedString(
                string: innerText,
                attributes: [
                    .font: font,
                    .foregroundColor: textColor,
                    .paragraphStyle: paragraphStyle
                ]
            )

            result.replaceCharacters(in: match.range, with: replacement)
        }
    }
}

// MARK: - Shared Constants

extension NSAttributedString.Key {
    /// Marks a range as being part of an inline code span, used by `CodeBlockTextView` to draw backgrounds.
    static let codeSpan = NSAttributedString.Key("PHPMonitorCodeSpan")
}

extension Character {
    static let thinSpace: Character = "\u{2009}"
    static let nbThinSpace: Character = "\u{202F}"
    static let nbSpace: Character = "\u{00A0}"
    static let wordJoiner: Character = "\u{2060}"
}
