//
//  MiniHeaderView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 10/06/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
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
        minimumWidth: CGFloat? = nil
    ) -> NSMenuItem {
        let view = NSHostingView(rootView: Self(text: text))
        view.autoresizingMask = [.width, .height]

        var finalWidth = view.frame.width
        if minimumWidth != nil && minimumWidth! > finalWidth {
            finalWidth = minimumWidth!
        }

        view.setFrameSize(CGSize(width: finalWidth, height: 24))

        let item = NSMenuItem()
        item.view = view

        return item
    }
}

#Preview {
    HeaderView(text: "Hello world")
        .frame(width: 330.0)
}
