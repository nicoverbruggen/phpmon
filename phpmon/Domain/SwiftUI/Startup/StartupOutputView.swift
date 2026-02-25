//
//  StartupOutputView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 25/02/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct StartupOutputView: View {
    let lines: [OutputLine]
    let isRunning: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 1) {
                        ForEach(lines) { line in
                            Text(line.text)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(line.stream == .stdErr ? Color.red : .white)
                                .textSelection(.enabled)
                                .id(line.id)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                }
                .frame(height: 160)
                .background(Color.black)
                .foregroundStyle(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .onChange(of: lines.count) { _ in
                    if let last = lines.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }
}

#Preview("With output") {
    StartupOutputView(
        lines: [
            OutputLine(text: "==> Linking Binary 'php' to '/opt/homebrew/bin/php'", stream: .stdOut),
            OutputLine(text: "==> Downloading https://formulae.brew.sh/api/formula.jws.json", stream: .stdOut),
            OutputLine(text: "Already downloaded: /Users/nico/Library/Caches/Homebrew/downloads/abc123.json", stream: .stdOut),
            OutputLine(text: "Warning: php is keg-only and must be linked with --force", stream: .stdErr),
            OutputLine(text: "==> Linking php... linked 25 files", stream: .stdOut),
        ],
        isRunning: true
    )
    .padding(20)
    .frame(width: 460)
}

#Preview("Idle with prior output") {
    StartupOutputView(
        lines: [
            OutputLine(text: "==> Linking php... linked 25 files", stream: .stdOut),
            OutputLine(text: "\nFix did not resolve the issue.", stream: .stdErr),
        ],
        isRunning: false
    )
    .padding(20)
    .frame(width: 460)
}
