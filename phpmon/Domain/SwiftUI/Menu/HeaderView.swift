//
//  MiniHeaderView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 10/06/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct HeaderView: View {
    @State var text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 12))
            .fontWeight(.bold)
            .foregroundColor(.appSecondary)
            .multilineTextAlignment(.leading)
            .padding(.leading, 14.0)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.debug)
    }

    // MARK: - NSMenuItem

    static func asMenuItem(
        text: String,
        width: Int? = nil
    ) -> NSMenuItem {
        let view = NSHostingView(rootView: Self(text: text))
        view.autoresizingMask = [.width, .height]
        view.setFrameSize(CGSize(width: view.frame.width, height: 24))

        let item = NSMenuItem()
        item.view = view

        return item
    }
}

struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        HeaderView(text: "Hello world")
            .frame(width: 330.0)
    }
}
