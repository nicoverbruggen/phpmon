//
//  ServicesView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 10/06/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

import SwiftUI

struct NXServicesView: View {

    var services: [String] = ["php", "nginx", "dnsmasq"]

    static func asMenuItem(memory: String, post: String, upload: String) -> NSMenuItem {
        let item = NSMenuItem()
        let view = NSHostingView(rootView: Self())
        view.frame = CGRect(x: 0, y: 0, width: 330, height: 55)
        item.view = view
        return item
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 30) {
            VStack(alignment: .center, spacing: 3) {
                MiniHeaderView(text: "hello".uppercased())
                Text("")
                    .fontWeight(.medium)
                    .font(.system(size: 16))
            }
        }.padding(10)
    }
}

struct NXServicesView_Previews: PreviewProvider {
    static var previews: some View {
        NXServicesView()
    }
}
