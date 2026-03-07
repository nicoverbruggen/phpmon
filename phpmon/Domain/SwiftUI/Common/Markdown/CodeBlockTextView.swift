//
//  CodeBlockTextView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 27/02/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import SwiftUI
import AppKit

/**
 A text view that draws rounded backgrounds behind inline code spans.

 Code spans are identified by the `.codeSpan` attributed string key,
 which is set by `MarkdownTextViewRepresentable` during string building.
 */
class CodeBlockTextView: NSTextView {

    // MARK: - Appearance

    // Color
    private lazy var appColor: NSColor = NSColor(named: "AppColor") ?? .systemBlue

    // Padding
    private let codePaddingX: CGFloat = 4
    private let codePaddingY: CGFloat = 0

    // Corner radius
    private let codeCornerRadius: CGFloat = 2

    // MARK: - Copy

    /**
     When copying selected text, we sanitize it so special layout characters
     are stripped and code spans are wrapped in backticks again.
     */
    override func copy(_ sender: Any?) {
        guard let textStorage, selectedRange().length > 0 else {
            super.copy(sender)
            return
        }

        let selected = textStorage.attributedSubstring(from: selectedRange())

        let result = NSMutableString()
        selected.enumerateAttribute(.codeSpan, in: NSRange(location: 0, length: selected.length)) { value, range, _ in
            let fragment = (selected.string as NSString).substring(with: range)
                .filter { $0 != .thinSpace && $0 != .nbThinSpace && $0 != .wordJoiner }
                .map { $0 == .nbSpace ? " " : String($0) }
                .joined()

            if value != nil {
                result.append("`\(fragment)`")
            } else {
                result.append(fragment)
            }
        }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(result as String, forType: .string)
    }

    // MARK: - Drawing

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

    /**
     Draws a rounded background rect behind each code span, using per-line
     rects so a wrapped span still gets tight individual backgrounds.
     */
    private func drawCodeBackgrounds() {
        guard let textStorage, let layoutManager, let textContainer else { return }

        textStorage.enumerateAttribute(.codeSpan, in: NSRange(location: 0, length: textStorage.length)) { value, range, _ in
            guard value != nil else { return }

            let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)

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
