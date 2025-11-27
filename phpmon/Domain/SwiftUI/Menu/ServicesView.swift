//
//  ServicesView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 10/06/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation
import SwiftUI
import NVAlert

struct ServicesView: View {

    @MainActor
    static func asMenuItem(perRow: Int = 4) -> NSMenuItem {
        let view = {
            let rootView = Self(manager: ServicesManager.shared, perRow: perRow)
            let view = NSHostingView(rootView: rootView)
            view.autoresizingMask = [.width]
            view.setFrameSize(CGSize(width: view.frame.width, height: rootView.height))
            view.focusRingType = .none
            return view
        }()

        let menuItem = {
            let item = NSMenuItem()
            item.view = view
            return item
        }()

        return menuItem
    }

    @ObservedObject var manager: ServicesManager

    var perRow: Int
    var rowCount: Int
    var rowSpacing: Int = 0
    var rowHeight: Int = 48
    var statusHeight: Int = 20
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

            VStack(alignment: .center) {
                HStack {
                    Circle()
                        .frame(width: 10, height: 10)
                        .foregroundColor(self.manager.statusColor)
                    Text(self.manager.statusMessage)
                        .font(.system(size: 11))
                    if self.manager.statusColor == Color("StatusColorRed") {
                        HelpButton {
                            let type = manager.hasError
                                ? "key_service_has_error"
                                : "key_service_not_running"

                            // Show an alert with more information
                            NVAlert().withInformation(
                                title: "alert.\(type).title".localized,
                                subtitle: "alert.\(type).subtitle".localized,
                                description: "alert.\(type).desc".localized
                            )
                            .withPrimary(text: "generic.ok".localized)
                            .show(urgency: .bringToFront)
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

    @MainActor
    private func toggleService() async {
        isBusy = true
        await ServicesManager.shared.toggleService(named: service.name)
        isBusy = false
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Text(service.name.uppercased())
                .font(.system(size: 10))
                .frame(minWidth: 70, alignment: .center)
            if isBusy {
                ProgressView()
                    .scaleEffect(x: 0.4, y: 0.4, anchor: .center)
                    .frame(minWidth: 70, alignment: .center)
                    .frame(width: 25, height: 25)
            } else {
                if service.status == .missing {
                    Button {
                        Task { @MainActor in
                            NVAlert().withInformation(
                                title: "alert.warnings.service_missing.title".localized,
                                subtitle: "alert.warnings.service_missing.subtitle".localized,
                                description: "alert.warnings.service_missing.description".localized
                            )
                            .withPrimary(text: "generic.ok".localized)
                            .show(urgency: .bringToFront)
                        }
                    } label: {
                        Text("?")
                    }
                    .focusable(false)
                    .frame(minWidth: 70, alignment: .center)
                }
                if service.status == .error {
                    Button {
                        Task { await toggleService() }
                    } label: {
                        Text("E")
                            .frame(width: 12.0, height: 12.0)
                            .foregroundColor(Color("StatusColorRed"))
                    }
                    .focusable(false)
                    .frame(width: 25, height: 25)
                }
                if service.status == .active || service.status == .inactive {
                    Button {
                        Task { await toggleService() }
                    } label: {
                        Image(
                            systemName: service.status == .active ? "checkmark" : "xmark"
                        )
                        .resizable()
                        .frame(width: 12.0, height: 12.0)
                        .foregroundColor(
                            service.status == .active
                                ? Color.primary
                                : Color("StatusColorRed")
                        )
                    }
                    .focusable(false)
                    .frame(width: 25, height: 25)
                }
            }
        }.frame(minWidth: 70)
    }
}

#Preview("Active 1") {
    ServicesView(manager: FakeServicesManager(
        App.shared.container,
        formulae: ["php", "nginx", "dnsmasq"],
        status: .active
    ), perRow: 4)
    .frame(width: 330.0)
}

#Preview("Active 2") {
    ServicesView(manager: FakeServicesManager(
        App.shared.container,
        formulae: [
            "php", "nginx", "dnsmasq", "thing1",
            "thing2", "thing3", "thing4", "thing5"
        ],
        status: .inactive
    ), perRow: 4)
    .frame(width: 330.0)
}
