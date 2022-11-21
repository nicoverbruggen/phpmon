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
    @State var perRow: Int = 3

    static func asMenuItem(perRow: Int = 3) -> NSMenuItem {
        let item = NSMenuItem()
        var services = [
            Homebrew.Formulae.php.name,
            Homebrew.Formulae.nginx.name,
            Homebrew.Formulae.dnsmasq.name
        ]

        if Preferences.custom.hasServices() {
            services += Preferences.custom.services!
        }

        let view = NSHostingView(
            rootView: Self(
                manager: ServicesManager.shared,
                servicesToDisplay: services,
                perRow: perRow
            )
        )

        view.autoresizingMask = [.width, .height]
        let height = CGFloat(45 * services.chunked(by: perRow).count)
        view.setFrameSize(CGSize(width: view.frame.width, height: height))
        item.view = view
        return item
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(servicesToDisplay.chunked(by: self.perRow), id: \.self) { chunk in
                HStack {
                    ForEach(0...self.perRow - 1, id: \.self) { index in
                        if chunk.indices.contains(index) {
                            // A service exists to fill the cell
                            let service = chunk[index]
                            VStack(alignment: .center, spacing: 3) {
                                SectionHeaderView(text: service.uppercased())
                                CheckmarkView(serviceName: service)
                                    .environmentObject(manager)
                            }.frame(minWidth: 0, maxWidth: .infinity)
                        } else {
                            // Empty cell
                            VStack {
                                EmptyView()
                            }.frame(minWidth: 0, maxWidth: .infinity)
                        }
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
    @State var busy: Bool = false
    @EnvironmentObject var manager: ServicesManager

    public func hasAnyServices() -> Bool {
        return !manager.services.isEmpty
    }

    public func active() -> Bool? {
        if manager.services.keys.contains(serviceName) {
            return manager.services[serviceName]!.service?.running ?? nil
        }

        return nil
    }

    public func toggleService() async {
        if active()! {
            await Actions.stopService(name: serviceName)
            busy = false
        } else {
            await Actions.startService(name: serviceName)
            busy = false
        }
    }

    var body: some View {
        if !hasAnyServices() {
            Image(systemName: "hourglass.circle")
                .resizable()
                .frame(width: 16.0, height: 16.0)
                .foregroundColor(.appSecondary)
        } else {
            if busy {
                ProgressView()
                    .scaleEffect(x: 0.5, y: 0.5, anchor: .center)
                    .frame(width: 16.0, height: 20.0)
            } else if active() == nil {
                Button { } label: {
                    Text("?")
                }.disabled(true)
            } else {
                Button {
                    busy = true
                    Task { await toggleService() }
                } label: {
                    Image(systemName: active()! ? "checkmark" : "xmark")
                        .resizable()
                        .frame(width: 12.0, height: 12.0)
                        .foregroundColor(active()! ? Color.primary : Color("IconColorRed"))
                }
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
                                "mysql", "redis", "php@7.4"],
            perRow: 3
        )
        .frame(width: 330.0)
        .previewDisplayName("Dark Mode")
        .preferredColorScheme(.dark)
    }
}
