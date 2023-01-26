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
    var action: () -> Void

    var body: some View {
        Button(action: action, label: {
            ZStack {
                Circle()
                    .strokeBorder(Color(NSColor.separatorColor), lineWidth: 0.5)
                    .background(Circle().foregroundColor(Color(NSColor.controlColor)).opacity(0.7))
                    .shadow(color: Color(NSColor.separatorColor).opacity(0.3), radius: 1)
                    .frame(width: 14, height: 14)
                Text("?").font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(NSColor.labelColor))
            }
        })
        .buttonStyle(BorderlessButtonStyle())
        .focusable(false)
    }

    struct HelpButton_Previews: PreviewProvider {
        static var previews: some View {
            Group {
                HelpButton(action: {}).padding()
                    .previewDisplayName("Light Mode")
                HelpButton(action: {}).padding().preferredColorScheme(.dark)
                    .previewDisplayName("Dark Mode")
            }
        }
    }
}
