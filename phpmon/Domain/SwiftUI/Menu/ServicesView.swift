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
            CGSize(width: view.frame.width, height: rootView.height)
        )
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
        self.chunkCount = manager.services.chunked(by: perRow).count
        self.height = CGFloat((50 * chunkCount) + (5 * perRow))
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                ForEach(manager.services.chunked(by: perRow), id: \.self) { chunk in
                    HStack {
                        ForEach(chunk) { service in
                            ServiceView(service: service)
                                .frame(width: abs((geometry.size.width - 15) / CGFloat(perRow)))
                        }
                    }
                }
            }
            .padding(.top, 10)
        }
        .frame(height: self.height)
        .background(Color.debug)
    }
}

struct ServiceView: View {
    @ObservedObject var service: ServiceWrapper

    var body: some View {
        VStack(spacing: 0) {
            Text(service.name.uppercased())
                .font(.system(size: 10))
                .frame(minWidth: 0, maxWidth: .infinity)
                .padding(.bottom, 4)
                .background(Color.debug)
            if service.status == .loading {
                ProgressView()
                    .scaleEffect(x: 0.5, y: 0.5, anchor: .center)
                    .frame(width: 16.0, height: 20.0)
            }
            if service.status == .missing {
                Button { print("we pressed da button ")} label: {
                    Text("?")
                }
                .buttonStyle(BlueButton())
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
        }
    }
}

public struct BlueButton: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.bottom, 5)
            .padding(.top, 5)
            .padding(.leading, 10)
            .padding(.trailing, 10)
            .background(Color(red: 0, green: 0, blue: 0.5))
            .foregroundColor(.white)
            .clipShape(Capsule())
    }
}

struct ServicesView_Previews: PreviewProvider {
    static var previews: some View {
        ServicesView(manager: FakeServicesManager(), perRow: 3)
            .frame(width: 330.0)
            .previewDisplayName("Loading")

        ServicesView(manager: FakeServicesManager(), perRow: 3)
            .frame(width: 330.0)
            .previewDisplayName("Light Mode")

        ServicesView(manager: FakeServicesManager(), perRow: 3)
            .frame(width: 330.0)
            .previewDisplayName("Dark Mode")
            .preferredColorScheme(.dark)
    }
}
