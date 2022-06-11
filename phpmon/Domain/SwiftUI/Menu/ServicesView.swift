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
    @ObservedObject var manager: ServicesManager
    @State var servicesToDisplay: [String]

    static func asMenuItem() -> NSMenuItem {
        let item = NSMenuItem()
        let view = NSHostingView(
            rootView: Self(
                manager: ServicesManager.shared,
                servicesToDisplay: [
                    PhpEnv.phpInstall.formula,
                    "nginx",
                    "dnsmasq"
                ]
            )
        )
        view.frame = CGRect(x: 0, y: 0, width: 330, height: 45)
        item.view = view
        return item
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            ForEach(servicesToDisplay, id: \.self) { service in
                VStack(alignment: .center, spacing: 3) {
                    MiniHeaderView(text: service.uppercased())
                    CheckmarkView(serviceName: service)
                        .environmentObject(manager)
                }.frame(minWidth: 0, maxWidth: .infinity)
            }
        }.padding(10)
    }
}

struct CheckmarkView: View {
    @State var serviceName: String
    @EnvironmentObject var manager: ServicesManager

    public func hasAnyServices() -> Bool {
        return !manager.services.isEmpty
    }

    public func active() -> Bool {
        guard let service = manager.services[serviceName] else {
            return false
        }

        return service.running
    }

    var body: some View {
        if !hasAnyServices() {
            Image(systemName: "questionmark.circle")
                .resizable()
                .frame(width: 16.0, height: 16.0)
                .foregroundColor(.secondary)
        } else {
            Image(systemName: active() ? "checkmark.circle" : "exclamationmark.triangle")
                .resizable()
                .frame(width: 16.0, height: 16.0)
                .foregroundColor(active() ? Color("IconColorGreen") : Color("IconColorRed"))
        }
    }
}

struct ServicesView_Previews: PreviewProvider {
    static var previews: some View {
        ServicesView(
            manager: ServicesManager()
                .withDummyServices([:]),
            servicesToDisplay: ["php", "nginx", "dnsmasq"]
        )
        .frame(width: 330.0)
        .previewDisplayName("Loading")

        ServicesView(
            manager: ServicesManager()
                .withDummyServices([
                    "php": false,
                    "nginx": true,
                    "dnsmasq": true
                ]),
            servicesToDisplay: ["php", "nginx", "dnsmasq"]
        )
        .frame(width: 330.0)
        .previewDisplayName("Light Mode")

        ServicesView(
            manager: ServicesManager()
                .withDummyServices([
                    "php": false,
                    "nginx": true,
                    "dnsmasq": true,
                    "mysql": false
                ]),
            servicesToDisplay: ["php", "nginx", "dnsmasq", "mysql"]
        )
        .frame(width: 330.0)
        .previewDisplayName("Dark Mode")
        .preferredColorScheme(.dark)
    }
}
