//
//  HelpButton.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 07/01/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import SwiftUI

struct HelpButton: View {
    @State var frameSize: CGFloat = 14
    @State var textSize: CGFloat = 12
    @State var shadowOpacity: CGFloat = 0.3
    @State var shadowRadius: CGFloat = 1

    var action: () -> Void

    var body: some View {
        Button(action: action, label: {
            ZStack {
                Circle()
                    .strokeBorder(Color(NSColor.separatorColor), lineWidth: 0.5)
                    .background(Circle().foregroundColor(Color(NSColor.controlColor)).opacity(0.7))
                    .shadow(color: Color(NSColor.separatorColor)
                        .opacity(shadowOpacity), radius: shadowRadius)
                    .frame(width: frameSize, height: frameSize)
                Text("?").font(.system(size: textSize, weight: .medium))
                    .foregroundColor(Color(NSColor.labelColor))
            }
        })
        .buttonStyle(BorderlessButtonStyle())
        .focusable(false)
    }
}

#Preview("Light Mode") {
    HelpButton(action: {})
        .padding(100)
}

#Preview("Dark Mode") {
    HelpButton(action: {})
        .padding(100)
        .preferredColorScheme(.dark)
}
