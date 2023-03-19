//
//  BlockingOverlayView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 19/03/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import SwiftUI

struct BlockingOverlayView<Content: View>: View {
    var isBlocking: Bool
    var titleText: String
    var detailText: String
    var content: () -> Content

    init(
        busy: Bool,
        title: String,
        text: String,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.isBlocking = busy
        self.titleText = title
        self.detailText = text
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .center) {
            content().opacity(isBlocking ? 0.2 : 1)
            if isBlocking {
                VStack {
                    ActivityIndicator()
                    Text(titleText)
                        .font(.system(size: 14))
                        .bold()
                        .foregroundColor(.primary)
                        .padding(.top, 8)
                    Text(detailText)
                        .font(.system(size: 11))
                        .foregroundColor(.primary)
                        .padding(.top, -4)
                }
            }
        }
        .disabled(isBlocking)
    }
}

struct ActivityIndicator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSProgressIndicator {
        let nsView = NSProgressIndicator()
        nsView.style = .spinning
        nsView.startAnimation(nil)
        return nsView
    }

    func updateNSView(_ nsView: NSProgressIndicator, context: Context) {
    }
}
