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
        configure(textView)
        return textView
    }

    func updateNSView(_ textView: CodeBlockTextView, context: Context) {
        configure(textView)
    }

    private func configure(_ textView: CodeBlockTextView) {
        let attributed = Self.buildAttributedString(from: string, fontSize: fontSize)
        textView.textStorage?.setAttributedString(attributed)
        textView.invalidateIntrinsicContentSize()
    }

    // MARK: - Attributed String Builder

    static func buildAttributedString(from string: String, fontSize: CGFloat) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let font = NSFont.systemFont(ofSize: fontSize)
        let codeFont = NSFont.monospacedSystemFont(ofSize: fontSize - 1, weight: .regular)

        // Add additional spacing for code blocks w/ thin spaces
        let thinSpace = "\u{2009}\u{2009}\u{2009}"

        let defaultAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.labelColor
        ]

        var current = string.startIndex

        while let backtickStart = string[current...].firstIndex(of: "`") {
            if current < backtickStart {
                result.append(NSAttributedString(
                    string: String(string[current..<backtickStart]),
                    attributes: defaultAttributes
                ))
            }

            let afterBacktick = string.index(after: backtickStart)
            if afterBacktick < string.endIndex,
               let backtickEnd = string[afterBacktick...].firstIndex(of: "`") {
                // Thin space before
                result.append(NSAttributedString(string: thinSpace, attributes: defaultAttributes))

                // Code span with marker attribute
                let codeAttributes: [NSAttributedString.Key: Any] = [
                    .font: codeFont,
                    .foregroundColor: NSColor.labelColor,
                    Self.codeSpanKey: true
                ]
                result.append(NSAttributedString(
                    string: String(string[afterBacktick..<backtickEnd]),
                    attributes: codeAttributes
                ))

                // Thin space after
                result.append(NSAttributedString(string: thinSpace, attributes: defaultAttributes))

                current = string.index(after: backtickEnd)
            } else {
                result.append(NSAttributedString(
                    string: String(string[backtickStart...]),
                    attributes: defaultAttributes
                ))
                current = string.endIndex
            }
        }

        if current < string.endIndex {
            result.append(NSAttributedString(
                string: String(string[current...]),
                attributes: defaultAttributes
            ))
        }

        return result
    }

    static let codeSpanKey = NSAttributedString.Key("PHPMonitorCodeSpan")
}
