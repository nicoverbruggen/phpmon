//
//  ProgressPanelView.swift
//  PHP Monitor
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import SwiftUI
import AppKit

/**
 The state shown in the terminal progress panel. Owned by
 `TerminalProgressWindowController`, which mutates it as console output
 streams in.
 */
class ProgressPanelModel: ObservableObject {
    @Published var title: String = ""
    @Published var descriptionText: String = ""
    @Published var isInfo: Bool = true

    /// The console starts out with the shell prompt, like the old storyboard's
    /// text view did.
    @Published var consoleText: String = "$ "
}

/**
 The terminal progress panel: an icon, a bold title and small description at
 the top, with a live streaming console below. The layout metrics are
 transcribed from the old `ProgressWindow.storyboard`.
 */
struct ProgressPanelView: View {
    @ObservedObject var model: ProgressPanelModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 15) {
                // The old NSImageView used `proportionallyDown` scaling: the 32pt
                // system icon renders at its natural size, left-aligned in a
                // 36pt box — it is never scaled up.
                Image(nsImage: NSImage(named: model.isInfo ? "NSInfo" : "NSCaution")!)
                    .frame(width: 36, height: 36, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text(model.title)
                        .font(.system(size: 13, weight: .bold))
                        .lineLimit(1)
                        .padding(.top, 2)

                    Text(model.descriptionText)
                        .font(.system(size: 11))
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(.top, 10)
            .padding(.leading, 20)
            .padding(.trailing, 20)
            // The storyboard pinned the console 16pt below the *description label*
            // (which ends 2pt above the taller icon), so the header block ends at
            // 60pt from the top — hence 14pt below this 46pt-tall HStack.
            .padding(.bottom, 14)

            TerminalConsoleView(text: model.consoleText)
        }
        .frame(width: 591, height: 270)
    }
}

/**
 The white-on-black streaming console: a non-rich `NSTextView` in a scroll
 view with hidden scrollers, using the same configuration as the old
 storyboard (Menlo 10, no horizontal elasticity). Scrolls to the end whenever
 new output arrives.
 */
struct TerminalConsoleView: NSViewRepresentable {
    let text: String

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.horizontalScrollElasticity = .none
        scrollView.drawsBackground = false

        let textView = NSTextView()
        textView.isRichText = false
        textView.font = NSFont(name: "Menlo-Regular", size: 10)
        textView.textColor = .white
        textView.backgroundColor = .black
        textView.insertionPointColor = .textColor
        textView.smartInsertDeleteEnabled = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width, .height]
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude,
                                  height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.string = text

        scrollView.documentView = textView

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        if textView.string != text {
            textView.string = text
            textView.scrollToEndOfDocument(nil)
        }
    }
}
