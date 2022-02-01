//
//  PMStatsView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 15/04/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import SwiftUI

@available(OSX 11.0, *)
struct PMStats: NSViewRepresentable {
    @Binding var labelText: String
    
    func makeNSView(context: Context) -> some NSView {
        return StatsView.asMenuItem(memory: labelText, post: labelText, upload: labelText).view!
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {}
}

@available(OSX 11.0, *)
struct PMStatsView: View {
    @State var content: String = "5 MB"
    
    var body: some View {
        PMStats(labelText: $content).frame(minWidth: 0, maxWidth: 450, minHeight: 0, maxHeight: 80)
    }
}
