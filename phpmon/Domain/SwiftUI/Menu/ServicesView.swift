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
        var services = [
            PhpEnv.phpInstall.formula,
            "nginx",
            "dnsmasq"
        ]

        if Preferences.custom.hasServices() {
            services += Preferences.custom.services!
        }

        let view = NSHostingView(
            rootView: Self(
                manager: ServicesManager.shared,
                servicesToDisplay: services
            )
        )

        view.autoresizingMask = [.width, .height]
        let height = CGFloat(45 * services.chunked(by: 3).count)
        view.setFrameSize(CGSize(width: view.frame.width, height: height))
        item.view = view
        return item
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(servicesToDisplay.chunked(by: 3), id: \.self) { chunk in
                HStack {
                    ForEach(chunk, id: \.self) { service in
                        VStack(alignment: .center, spacing: 3) {
                            SectionHeaderView(text: service.uppercased())
                            CheckmarkView(serviceName: service)
                                .environmentObject(manager)
                        }.frame(minWidth: 0, maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(10)
        .frame(minWidth: 0, maxWidth: .infinity)
        .background(Color.debug)
    }
}

struct CheckmarkView: View {
    @State var serviceName: String
    @EnvironmentObject var manager: ServicesManager

    public func hasAnyServices() -> Bool {
        return !manager.rootServices.isEmpty
    }

    public func active() -> Bool? {
        if manager.rootServices.keys.contains(serviceName) {
            return manager.rootServices[serviceName]!.running
        }

        if manager.userServices.keys.contains(serviceName) {
            return manager.userServices[serviceName]!.running
        }

        return nil
    }

    var body: some View {
        if !hasAnyServices() {
            Image(systemName: "hourglass.circle")
                .resizable()
                .frame(width: 16.0, height: 16.0)
                .foregroundColor(.secondary)
        } else {
            if active() == nil {
                Image(systemName: "questionmark.square.dashed")
                    .resizable()
                    .frame(width: 16.0, height: 16.0)
                    .foregroundColor(Color("IconColorRed"))
            } else {
                Image(systemName: active()! ? "checkmark.circle" : "xmark.circle")
                    .resizable()
                    .frame(width: 16.0, height: 16.0)
                    .foregroundColor(active()! ? Color.primary : Color("IconColorRed"))
            }
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
            servicesToDisplay: ["php", "nginx", "dnsmasq",
                                "mysql", "redis", "mailhog"]
        )
        .frame(width: 330.0)
        .previewDisplayName("Dark Mode")
        .preferredColorScheme(.dark)
    }
}