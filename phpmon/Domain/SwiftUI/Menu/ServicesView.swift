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
        view.autoresizingMask = [.width]
        view.setFrameSize(
            CGSize(width: view.frame.width, height: rootView.height + 30)
        )
        // view.layer?.backgroundColor = CGColor.init(red: 255, green: 0, blue: 0, alpha: 1)
        view.focusRingType = .none

        item.view = view
        return item
    }

    @ObservedObject var manager: ServicesManager
    var perRow: Int
    var rowCount: Int
    var rowSpacing: Int = 0
    var rowHeight: Int = 50
    var statusHeight: Int = 30
    var allRowHeight: CGFloat
    var height: CGFloat

    init(manager: ServicesManager, perRow: Int) {
        self.manager = manager
        self.perRow = perRow
        self.rowCount = manager.formulae.chunked(by: perRow).count
        self.allRowHeight = CGFloat(
            (rowHeight * rowCount) + ((rowCount - 1) * rowSpacing)
        )
        self.height = allRowHeight + CGFloat(statusHeight)
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: CGFloat(self.rowSpacing)) {
                ForEach(manager.services.chunked(by: perRow), id: \.self) { chunk in
                    HStack {
                        ForEach(chunk, id: \.self) { service in
                            ServiceView(service: service)
                                .frame(minWidth: 70)
                        }
                    }
                    .frame(height: CGFloat(self.rowHeight))
                    .padding(CGFloat(self.rowSpacing))
                }
            }
            .frame(height: CGFloat(self.height - CGFloat(self.statusHeight)))
            .frame(maxWidth: .infinity, alignment: .center)
            // .background(Color.red)

            VStack(alignment: .center) {
                HStack {
                    Circle()
                        .frame(width: 12, height: 12)
                        .foregroundColor(self.manager.statusColor)
                    Text(self.manager.statusMessage)
                        .font(.system(size: 12))
                    if self.manager.statusColor == .red {
                        HelpButton {
                            print("oof")
                        }
                    }
                }
            }
            .frame(height: CGFloat(self.statusHeight))
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

struct ServiceView: View {
    var service: Service
    @State var isBusy: Bool = false

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Text(service.name.uppercased())
                .font(.system(size: 10))
                .frame(minWidth: 70, alignment: .center)
                .padding(.top, 4)
                .padding(.bottom, 2)
            if isBusy {
                ProgressView()
                    .scaleEffect(x: 0.4, y: 0.4, anchor: .center)
                    .frame(minWidth: 70, alignment: .center)
                    .frame(width: 25, height: 25)
            } else {
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
                    .frame(minWidth: 70, alignment: .center)
                }
                if service.status == .active || service.status == .inactive {
                    Button {
                        Task {
                            isBusy = true
                            await ServicesManager.shared.toggleService(named: service.name)
                            isBusy = false
                        }
                    } label: {
                        Image(
                            systemName: service.status == .active ? "checkmark" : "xmark"
                        )
                        .resizable()
                        .frame(width: 12.0, height: 12.0)
                        .foregroundColor(
                            service.status == .active
                                ? Color("IconColorGreen")
                                : Color("IconColorRed")
                        )
                    }
                    .focusable(false)
                    .frame(width: 25, height: 25)
                }
            }
        }.frame(minWidth: 70)
    }
}

struct ServicesView_Previews: PreviewProvider {
    static var previews: some View {
        ServicesView(manager: FakeServicesManager(
            formulae: ["php", "nginx", "dnsmasq"],
            status: .active
        ), perRow: 4)
        .frame(width: 330.0)
        .previewDisplayName("Loading")

        ServicesView(manager: FakeServicesManager(
            formulae: ["php", "nginx", "dnsmasq"],
            status: .active
        ), perRow: 4)
        .frame(width: 330.0)
        .previewDisplayName("Active 1")

        ServicesView(manager: FakeServicesManager(
            formulae: [
                "php", "nginx", "dnsmasq", "thing1",
                "thing2", "thing3", "thing4", "thing5"
            ],
            status: .inactive
        ), perRow: 4)
        .frame(width: 330.0)
        .previewDisplayName("Active 2")
    }
}
