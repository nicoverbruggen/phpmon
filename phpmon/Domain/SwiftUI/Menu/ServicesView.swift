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

    static func asMenuItem(perRow: Int = 4) -> NSMenuItem {
        let item = NSMenuItem()

        let manager = ServicesManager.shared

        let rootView = Self(
            manager: manager,
            perRow: perRow
        )

        let view = NSHostingView(rootView: rootView)
        view.autoresizingMask = [.width, .height]
        view.setFrameSize(
            CGSize(width: view.frame.width, height: rootView.height + 30)
        )
        view.layer?.backgroundColor = CGColor.init(red: 255, green: 0, blue: 0, alpha: 0)
        view.focusRingType = .none

        item.view = view
        return item
    }

    @ObservedObject var manager: ServicesManager
    var perRow: Int
    var height: CGFloat
    var chunkCount: Int

    init(manager: ServicesManager, perRow: Int, height: CGFloat? = nil) {
        self.manager = manager
        self.perRow = perRow
        self.chunkCount = manager.serviceWrappers.chunked(by: perRow).count
        self.height = CGFloat((30 * chunkCount) + (5 * perRow))
    }

    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                ForEach(manager.serviceWrappers.chunked(by: perRow), id: \.self) { chunk in
                    HStack {
                        ForEach(chunk) { service in
                            ServiceView(service: service).frame(minWidth: 70)
                        }
                    }
                }

            }
            .frame(height: self.height)
            .frame(maxWidth: .infinity, alignment: .center)
            // .background(Color.red)

            VStack(alignment: .center) {
                HStack {
                    Circle()
                        .frame(width: 12, height: 12)
                        .foregroundColor(self.manager.statusColor)
                    Text(self.manager.statusMessage)
                        .font(.system(size: 12))
                }
            }
            .frame(height: 25)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

struct ServiceView: View {
    @ObservedObject var service: ServiceWrapper

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Text(service.name.uppercased())
                .font(.system(size: 10))
                .frame(minWidth: 70, alignment: .center)
                .padding(.top, 4)
                .padding(.bottom, 2)
            if service.status == .loading {
                ProgressView()
                    .scaleEffect(x: 0.5, y: 0.5, anchor: .center)
                    .frame(minWidth: 70, alignment: .center)
            }
            if service.status == .missing {
                Button {
                    Task { @MainActor in
                        BetterAlert().withInformation(
                            title: "alert.warnings.service_missing.title".localized,
                            subtitle: "alert.warnings.service_missing.subtitle".localized,
                            description: "alert.warnings.service_missing.description".localized
                        )
                        .withPrimary(text: "OK")
                        .show()
                    }
                } label: {
                    Text("?")
                }
                .focusable(false)
                .buttonStyle(BlueButton())
                .frame(minWidth: 70, alignment: .center)
            }
            if service.status == .active {
                Button {
                    // TODO
                } label: {
                    Image(systemName: "checkmark")
                        .resizable()
                        .frame(width: 12.0, height: 12.0)
                        .foregroundColor(Color("IconColorGreen"))
                }
            }
            if service.status == .inactive {
                Button {
                    // TODO
                } label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .frame(width: 12.0, height: 12.0)
                        .foregroundColor(Color("IconColorRed"))
                }
            }
        }.frame(minWidth: 70)
    }
}

public struct BlueButton: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 30, height: 30)
            .background(configuration.isPressed
                ? Color(red: 0, green: 0, blue: 0.9)
                : Color(red: 0, green: 0, blue: 0.5)
            )
            .foregroundColor(.white)
            .clipShape(Capsule())
    }
}

struct ServicesView_Previews: PreviewProvider {
    static var previews: some View {
        ServicesView(manager: FakeServicesManager(
            formulae: ["php", "nginx", "dnsmasq"],
            status: .loading
        ), perRow: 4)
        .frame(width: 330.0)
        .previewDisplayName("Loading")

        ServicesView(manager: FakeServicesManager(
            formulae: ["php", "nginx", "dnsmasq"],
            status: .active
        ), perRow: 4)
        .frame(width: 330.0)
        .previewDisplayName("Active")
    }
}
