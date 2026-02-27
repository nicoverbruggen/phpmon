//
//  MarkdownText.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 25/02/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import SwiftUI

extension Text {
    init(markdown string: String, fontSize: CGFloat? = nil) {
        if var attributed = try? AttributedString(
            markdown: string,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            for run in attributed.runs where ((run.inlinePresentationIntent?.contains(.code)) != nil) {
                attributed[run.range].backgroundColor = Color(nsColor: .quaternaryLabelColor)
            }
            self.init(attributed)
        } else {
            self.init(string)
        }
    }
}
