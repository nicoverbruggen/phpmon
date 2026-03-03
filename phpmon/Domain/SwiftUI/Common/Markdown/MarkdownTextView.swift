//
//  MarkdownTextView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 27/02/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct MarkdownTextView: View {
    let string: String
    let fontSize: CGFloat
    let textColor: NSColor

    init(_ string: String, fontSize: CGFloat = 12, textColor: NSColor = .labelColor) {
        self.string = string
        self.fontSize = fontSize
        self.textColor = textColor
    }

    var body: some View {
        MarkdownTextViewRepresentable(string: string, fontSize: fontSize, textColor: textColor)
    }
}

// MARK: - Previews

#Preview("Inline code") {
    MarkdownTextView("startup.errors.php_binary.desc".localized(
        "/opt/homebrew/bin/php"
    ))
    .frame(width: 460)
    .padding()
}

#Preview("No code") {
    MarkdownTextView("startup.errors.valet_version_not_supported.desc".localized)
    .frame(width: 460)
    .padding()
}
