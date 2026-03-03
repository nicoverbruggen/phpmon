//
//  CodeBlockTextView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 27/02/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import SwiftUI
import AppKit

/// Note: Written with the help of an LLM.
class CodeBlockTextView: NSTextView {
    private let codePaddingX: CGFloat = 4
    private let codePaddingY: CGFloat = 0
    private let codeCornerRadius: CGFloat = 2

    private lazy var appColor: NSColor = NSColor(named: "AppColor") ?? .systemBlue

    /**
     When we have selected text in a code block, we need to sanitize the output that will be copied to the pasteboard.

     This means stripping thin spaces, no-break spaces and using Markdown's annotation for code blocks.
     */
    override func copy(_ sender: Any?) {
        guard let textStorage, selectedRange().length > 0 else {
            super.copy(sender)
            return
        }

        let selected = textStorage.attributedSubstring(from: selectedRange())
        let codeSpanKey = MarkdownTextViewRepresentable.codeSpanKey

        // Rebuild the string, wrapping code spans in backticks and cleaning up special characters
        let result = NSMutableString()
        selected.enumerateAttribute(codeSpanKey, in: NSRange(location: 0, length: selected.length)) { value, range, _ in
            var fragment = (selected.string as NSString).substring(with: range)
            fragment = fragment
                .replacingOccurrences(of: "\u{2009}", with: "") // Remove thin spaces (leading padding)
                .replacingOccurrences(of: "\u{202F}", with: "") // Remove narrow no-break spaces (trailing padding)
                .replacingOccurrences(of: "\u{2060}", with: "") // Remove word joiners
                .replacingOccurrences(of: "\u{00A0}", with: " ") // Restore regular spaces

            if value != nil {
                result.append("`\(fragment)`")
            } else {
                result.append(fragment)
            }
        }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(result as String, forType: .string)
    }

    override func draw(_ dirtyRect: NSRect) {
        drawCodeBackgrounds()
        super.draw(dirtyRect)
    }

    override var intrinsicContentSize: NSSize {
        guard let textContainer, let layoutManager else {
            return super.intrinsicContentSize
        }
        layoutManager.ensureLayout(for: textContainer)
        let rect = layoutManager.usedRect(for: textContainer)
        return NSSize(width: NSView.noIntrinsicMetric, height: ceil(rect.height))
    }

    private func drawCodeBackgrounds() {
        guard let textStorage, let layoutManager, let textContainer else { return }

        let codeSpanKey = MarkdownTextViewRepresentable.codeSpanKey

        textStorage.enumerateAttribute(codeSpanKey, in: NSRange(location: 0, length: textStorage.length)) { value, range, _ in
            guard value != nil else { return }

            let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)

            // Enumerate per-line rects so wrapped code spans get individual backgrounds
            layoutManager.enumerateEnclosingRects(
                forGlyphRange: glyphRange,
                withinSelectedGlyphRange: NSRange(location: NSNotFound, length: 0),
                in: textContainer
            ) { lineRect, _ in
                let rect = lineRect.offsetBy(dx: self.textContainerInset.width, dy: self.textContainerInset.height)
                let paddedRect = rect.insetBy(dx: -self.codePaddingX, dy: -self.codePaddingY)
                let path = NSBezierPath(roundedRect: paddedRect, xRadius: self.codeCornerRadius, yRadius: self.codeCornerRadius)

                self.appColor.withAlphaComponent(0.15).setFill()
                path.fill()
            }
        }
    }
}
