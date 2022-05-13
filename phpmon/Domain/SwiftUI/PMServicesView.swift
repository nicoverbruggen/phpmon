//
//  PMHeaderView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 15/04/2021.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import SwiftUI

@available(OSX 11.0, *)
struct PMServicesView: View {
    var body: some View {
        PMServices().frame(minWidth: 0, maxWidth: 450, minHeight: 0, maxHeight: 50)
    }
}

@available(OSX 11.0, *)
struct PMServices: NSViewRepresentable {
    func makeNSView(context: Context) -> some NSView {
        return ServicesView.asMenuItem().view!
    }

    func updateNSView(_ nsView: NSViewType, context: Context) {}
}
