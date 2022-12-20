//
//  ServicesView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 10/06/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation
import SwiftUI

struct ServicesView: View {
    static func asMenuItem(perRow: Int = 3) -> NSMenuItem {
        let item = NSMenuItem()

        let view = NSHostingView(
            rootView: Self()
        )

        view.autoresizingMask = [.width, .height]

        let height = CGFloat(45 * ["a", "b", "c", "d", "e", "f"]
            .chunked(by: perRow).count)

        view.setFrameSize(CGSize(width: view.frame.width, height: height))
        item.view = view
        return item
    }

    var body: some View {
        Text("WIP")
        .padding(10)
        .frame(minWidth: 0, maxWidth: .infinity)
        .background(Color.debug)
    }
}

struct ServicesView_Previews: PreviewProvider {
    static var previews: some View {
        ServicesView()
        .frame(width: 330.0)
        .previewDisplayName("Loading")

        ServicesView()
        .frame(width: 330.0)
        .previewDisplayName("Light Mode")

        ServicesView()
        .frame(width: 330.0)
        .previewDisplayName("Dark Mode")
        .preferredColorScheme(.dark)
    }
}
