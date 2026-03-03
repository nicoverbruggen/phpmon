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
    private let codePaddingY: CGFloat = 1
    private let codeCornerRadius: CGFloat = 4

    private lazy var appColor: NSColor = NSColor(named: "AppColor") ?? .systemBlue

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

            // Get the glyph range and bounding rect for this code span
            let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
            var textRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)

            // Trim line spacing from the rect height so the background fits the text tightly
            let font = textStorage.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont
            let lineHeight = font?.ascender ?? 0 + abs(font?.descender ?? 0) + (font?.leading ?? 0)
            if lineHeight > 0 && textRect.height > lineHeight {
                textRect.size.height = lineHeight + 5 // added 5px for optimal size
            }

            // Offset by text container inset
            let rect = textRect.offsetBy(dx: textContainerInset.width, dy: textContainerInset.height)
            let paddedRect = rect.insetBy(dx: -codePaddingX, dy: -codePaddingY)
            let path = NSBezierPath(roundedRect: paddedRect, xRadius: codeCornerRadius, yRadius: codeCornerRadius)

            // Fill
            appColor.withAlphaComponent(0.15).setFill()
            path.fill()
        }
    }
}
