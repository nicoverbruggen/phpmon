//
//  ProgressWindowView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 11/03/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct ProgressWindowView: View {
    @ObservedObject var subject: ProgressViewSubject

    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text(subject.title)
                    .font(.system(size: 14))
                    .bold()
                if subject.description != nil {
                    Text(subject.description!)
                        .font(.system(size: 13))
                }
            }
            .padding(.leading, 20)
            .padding(.top, 12)
            ProgressView(value: subject.progress)
                .padding(.top, 0)
                .padding(.bottom, 12)
                .padding(.horizontal, 20)
        }
    }

    @MainActor static func display(_ subject: ProgressViewSubject) async -> NSWindowController {
        let view = ProgressWindowView(subject: subject)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 240),
            styleMask: [.titled, .closable, .utilityWindow],
            backing: .buffered,
            defer: false
        )

        window.title = ""
        window.titlebarAppearsTransparent = true
        window.contentView = NSHostingView(rootView: view)
        let controller = NSWindowController(window: window)
        controller.showWindow(nil)
        controller.positionWindowInTopLeftCorner()
        controller.window?.makeKeyAndOrderFront(self)
        // NSApp.activate(ignoringOtherApps: true)
        return controller
    }
}

struct ProgressWindowView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressWindowView(
            subject: ProgressViewSubject(
                title: "Long running task",
                description: "Please be patient"
            )
        )
    }
}
