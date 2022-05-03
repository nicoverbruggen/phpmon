//
//  PMHeaderView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 15/04/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import SwiftUI

@available(OSX 11.0, *)
struct PMHeaderView: View {
    @State var content: String = "Your Title Here"

    var body: some View {
        PMHeader(labelText: $content).frame(minWidth: 0, maxWidth: 450, minHeight: 0, maxHeight: 50)
    }
}

@available(OSX 11.0, *)
struct PMHeader: NSViewRepresentable {
    @Binding var labelText: String

    func makeNSView(context: Context) -> some NSView {
        return HeaderView.asMenuItem(text: labelText).view!
    }

    func updateNSView(_ nsView: NSViewType, context: Context) {}
}
