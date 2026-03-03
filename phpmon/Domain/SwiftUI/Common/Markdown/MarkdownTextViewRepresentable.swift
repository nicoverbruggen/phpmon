//
//  MarkdownTextViewRepresentable.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 27/02/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import SwiftUI
import AppKit

/// Note: Written with the help of an LLM.
struct MarkdownTextViewRepresentable: NSViewRepresentable {
    let string: String
    let fontSize: CGFloat
    let textColor: NSColor

    // MARK: - Static Properties

    static let codeSpanKey = NSAttributedString.Key("PHPMonitorCodeSpan")

    // swiftlint:disable force_try
    private static let codeRegex = try! NSRegularExpression(pattern: "`([^`]+)`")
    private static let boldRegex = try! NSRegularExpression(pattern: "\\*\\*([^*]+)\\*\\*")
    private static let italicRegex = try! NSRegularExpression(pattern: "(?<!\\*)\\*([^*]+)\\*(?!\\*)")
    // swiftlint:enable force_try

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

    func updateNSView(_ textView: CodeBlockTextView, context: Context) {
        let coordinator = context.coordinator
        guard string != coordinator.lastString || fontSize != coordinator.lastFontSize || textColor != coordinator.lastTextColor else { return }
        configure(textView, coordinator: coordinator)
    }

    private func configure(_ textView: CodeBlockTextView, coordinator: Coordinator) {
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

    static func buildAttributedString(from string: String, fontSize: CGFloat, textColor: NSColor = .labelColor) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let font = NSFont.systemFont(ofSize: fontSize)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 3
        paragraphStyle.paragraphSpacing = -4

        let defaultAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle
        ]

        // Plain text first
        result.append(NSAttributedString(string: string, attributes: defaultAttributes))

        // Apply markup passes (order matters: code first to avoid matching * inside code spans)
        handleCodeMarkup(in: result, fontSize: fontSize, paragraphStyle: paragraphStyle)

        // Collect code span ranges once for bold and italic passes
        let codeRanges = codeSpanRanges(in: result)
        handleBoldMarkup(in: result, fontSize: fontSize, paragraphStyle: paragraphStyle, textColor: textColor, codeRanges: codeRanges)
        handleItalicMarkup(in: result, fontSize: fontSize, paragraphStyle: paragraphStyle, textColor: textColor, codeRanges: codeRanges)

        return result
    }

    // MARK: - Markup Handlers

    /// Replaces `` `code` `` with monospaced font and kern-based padding.
    private static func handleCodeMarkup(
        in result: NSMutableAttributedString,
        fontSize: CGFloat,
        paragraphStyle: NSParagraphStyle
    ) {
        let codeFont = NSFont.monospacedSystemFont(ofSize: fontSize - 1, weight: .regular)
        let thinSpace = "\u{2009}" // Thin space for visual padding around code spans

        let fullRange = NSRange(location: 0, length: result.length)
        let matches = codeRegex.matches(in: result.string, range: fullRange).reversed()

        for match in matches {
            let innerRange = match.range(at: 1)
            let innerText = (result.string as NSString).substring(with: innerRange)

            let spaceAttributes: [NSAttributedString.Key: Any] = [
                .font: codeFont,
                .foregroundColor: NSColor.labelColor,
                .paragraphStyle: paragraphStyle
            ]

            // Build: thin space + code span (with marker) + thin space
            let replacement = NSMutableAttributedString()
            replacement.append(NSAttributedString(string: thinSpace, attributes: spaceAttributes))
            replacement.append(NSAttributedString(
                string: innerText,
                attributes: spaceAttributes.merging([Self.codeSpanKey: true]) { _, new in new }
            ))
            replacement.append(NSAttributedString(string: thinSpace, attributes: spaceAttributes))

            result.replaceCharacters(in: match.range, with: replacement)
        }
    }

    /// Collects all ranges marked as code spans.
    private static func codeSpanRanges(in result: NSMutableAttributedString) -> [NSRange] {
        var ranges: [NSRange] = []
        result.enumerateAttribute(codeSpanKey, in: NSRange(location: 0, length: result.length)) { value, range, _ in
            if value != nil { ranges.append(range) }
        }
        return ranges
    }

    /// Returns matches from the regex that don't overlap with any of the provided code span ranges.
    private static func nonCodeSpanMatches(
        in result: NSMutableAttributedString,
        regex: NSRegularExpression,
        codeRanges: [NSRange]
    ) -> [NSTextCheckingResult] {
        let fullRange = NSRange(location: 0, length: result.length)
        return regex.matches(in: result.string, range: fullRange).filter { match in
            !codeRanges.contains { codeRange in
                NSIntersectionRange(match.range, codeRange).length > 0
            }
        }
    }

    /// Replaces `**bold**` with bold font.
    private static func handleBoldMarkup(
        in result: NSMutableAttributedString,
        fontSize: CGFloat,
        paragraphStyle: NSParagraphStyle,
        textColor: NSColor,
        codeRanges: [NSRange]
    ) {
        let boldFont = NSFont.boldSystemFont(ofSize: fontSize)

        for match in nonCodeSpanMatches(in: result, regex: boldRegex, codeRanges: codeRanges).reversed() {
            let innerRange = match.range(at: 1)
            let innerText = (result.string as NSString).substring(with: innerRange)

            let replacement = NSAttributedString(
                string: innerText,
                attributes: [
                    .font: boldFont,
                    .foregroundColor: textColor,
                    .paragraphStyle: paragraphStyle
                ]
            )

            result.replaceCharacters(in: match.range, with: replacement)
        }
    }

    /// Replaces `*italic*` with italic font.
    private static func handleItalicMarkup(
        in result: NSMutableAttributedString,
        fontSize: CGFloat,
        paragraphStyle: NSParagraphStyle,
        textColor: NSColor,
        codeRanges: [NSRange]
    ) {
        let italicFont = NSFontManager.shared.convert(
            NSFont.systemFont(ofSize: fontSize),
            toHaveTrait: .italicFontMask
        )

        for match in nonCodeSpanMatches(in: result, regex: italicRegex, codeRanges: codeRanges).reversed() {
            let innerRange = match.range(at: 1)
            let innerText = (result.string as NSString).substring(with: innerRange)

            let replacement = NSAttributedString(
                string: innerText,
                attributes: [
                    .font: italicFont,
                    .foregroundColor: textColor,
                    .paragraphStyle: paragraphStyle
                ]
            )

            result.replaceCharacters(in: match.range, with: replacement)
        }
    }
}
