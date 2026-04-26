//
//  StartupOutputView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 25/02/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import SwiftUI
import AppKit

struct StartupOutputView: View {
    let lines: [OutputLine]
    let isRunning: Bool

    var body: some View {
        StartupOutputTextView(lines: lines, isRunning: isRunning)
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

private struct StartupOutputTextView: NSViewRepresentable {
    let lines: [OutputLine]
    let isRunning: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = true
        scrollView.backgroundColor = .black

        let textView = NSTextView()
        // Console-style output is append-heavy, so an NSTextView is a better fit than
        // rebuilding a SwiftUI view tree as more shell output arrives.
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.font = Self.font
        textView.textColor = .white
        textView.insertionPointColor = .white
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.textContainer?.lineFragmentPadding = 0
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true

        scrollView.documentView = textView

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else {
            return
        }

        let displayLines = lines.filter { !$0.text.isEmpty }
        let coordinator = context.coordinator
        let didChangeText = sync(textView, with: displayLines, coordinator: coordinator)
        let didChangeRunningState = coordinator.wasRunning != isRunning

        if didChangeText || didChangeRunningState {
            DispatchQueue.main.async {
                textView.scrollToEndOfDocument(nil)
            }
        }

        coordinator.wasRunning = isRunning
    }

    private func sync(
        _ textView: NSTextView,
        with displayLines: [OutputLine],
        coordinator: Coordinator
    ) -> Bool {
        guard let textStorage = textView.textStorage else {
            return false
        }

        if displayLines.isEmpty {
            guard !coordinator.renderedLineIds.isEmpty || textStorage.length > 0 else {
                return false
            }

            textStorage.setAttributedString(NSAttributedString())
            coordinator.renderedLineIds = []
            return true
        }

        if hasMatchingPrefix(displayLines, renderedLineIds: coordinator.renderedLineIds) {
            let newLines = displayLines.dropFirst(coordinator.renderedLineIds.count)

            guard !newLines.isEmpty else {
                return false
            }

            // The normal path is append-only output, so extend the text storage in place
            // instead of rebuilding the full console contents every update.
            for line in newLines {
                textStorage.append(NSAttributedString(string: line.text, attributes: Self.textAttributes))
            }

            coordinator.renderedLineIds = displayLines.map { $0.id }
            return true
        }

        // If output was cleared or replaced, fall back to a full rebuild to keep the
        // text view in sync with the source of truth.
        let rebuiltOutput = displayLines.map { $0.text }.joined()
        textStorage.setAttributedString(NSAttributedString(string: rebuiltOutput, attributes: Self.textAttributes))
        coordinator.renderedLineIds = displayLines.map { $0.id }
        return true
    }

    private func hasMatchingPrefix(
        _ displayLines: [OutputLine],
        renderedLineIds: [UUID]
    ) -> Bool {
        guard renderedLineIds.count <= displayLines.count else {
            return false
        }

        for index in renderedLineIds.indices where renderedLineIds[index] != displayLines[index].id {
            return false
        }

        return true
    }

    private static let font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
    private static let textAttributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white
    ]

    class Coordinator {
        var renderedLineIds: [UUID] = []
        var wasRunning = false
    }
}

#Preview("With output") {
    StartupOutputView(
        lines: [
            OutputLine(text: "==> Linking Binary 'php' to '/opt/homebrew/bin/php'\n", stream: .stdOut),
            OutputLine(text: "==> Downloading https://formulae.brew.sh/api/formula.jws.json\n", stream: .stdOut),
            OutputLine(text: "Already downloaded: /Users/nico/Library/Caches/Homebrew/downloads/abc123.json\n", stream: .stdOut),
            OutputLine(text: "Warning: php is keg-only and must be linked with --force\n", stream: .stdErr),
            OutputLine(text: "==> Linking php... linked 25 files", stream: .stdOut)
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
            OutputLine(text: "\nFix did not resolve the issue.", stream: .stdErr)
        ],
        isRunning: false
    )
    .padding(20)
    .frame(width: 460)
}
