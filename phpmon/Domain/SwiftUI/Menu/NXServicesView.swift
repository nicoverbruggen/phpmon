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
    @ObservedObject var serviceManager: ServicesManager

    @State var serviceNames: [String] = {
        return [
            PhpEnv.phpInstall.formula,
            "nginx",
            "dnsmasq"
        ]
    }()

    static func asMenuItem() -> NSMenuItem {
        let item = NSMenuItem()
        let view = NSHostingView(rootView: Self(serviceManager: ServicesManager.shared))
        view.frame = CGRect(x: 0, y: 0, width: 330, height: 55)
        item.view = view
        return item
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            ForEach(serviceNames, id: \.self) { service in
                VStack(alignment: .center, spacing: 3) {
                    MiniHeaderView(text: service.uppercased())
                    CheckmarkView(serviceName: service).environmentObject(serviceManager)
                }.frame(width: 90)
            }
        }.padding(10)
    }
}

struct CheckmarkView: View {
    @State var serviceName: String
    @EnvironmentObject var serviceManager: ServicesManager

    public func hasAnyServices() -> Bool {
        return !serviceManager.services.isEmpty
    }

    public func active() -> Bool {
        guard let service = serviceManager.services[serviceName] else {
            return false
        }

        return service.running
    }

    var body: some View {
        if !hasAnyServices() {
            Image(systemName: "questionmark.circle")
                .resizable()
                .frame(width: 16.0, height: 16.0)
                .foregroundColor(.black)
        } else {
            Image(systemName: "checkmark.circle")
                .resizable()
                .frame(width: 16.0, height: 16.0)
                .foregroundColor(active() ? Color.black : Color("IconColorRed"))
        }
    }
}

struct NXServicesView_Previews: PreviewProvider {
    static var previews: some View {
        NXServicesView(serviceManager: ServicesManager.shared)
    }
}
