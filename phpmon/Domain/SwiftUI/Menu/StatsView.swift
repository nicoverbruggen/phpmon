//
//  StatsView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 09/06/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct StatsView: View {

    @MainActor
    static func asMenuItem(memory: String, post: String, upload: String) -> NSMenuItem {
        let item = NSMenuItem()
        let view = NSHostingView(
            rootView: Self(
                memoryLimit: memory,
                maxPostSize: post,
                maxUploadSize: upload
            )
        )
        view.autoresizingMask = [.width, .height]
        view.setFrameSize(CGSize(width: view.frame.width, height: 55))
        item.view = view
        return item
    }

    @State var memoryLimit: String
    @State var maxPostSize: String
    @State var maxUploadSize: String

    init(memoryLimit: String, maxPostSize: String, maxUploadSize: String) {
        self.memoryLimit = memoryLimit
        self.maxPostSize = maxPostSize
        self.maxUploadSize = maxUploadSize
    }

    public func hasErrorState() -> Bool {
        return self.memoryLimit == "⚠️"
            && self.maxPostSize == "⚠️"
            && self.maxUploadSize == "⚠️"
    }

    var body: some View {
        if self.hasErrorState() {
            HStack {
                Text("⚠️")
                    .frame(maxWidth: 20, alignment: .center)
                    .font(.system(size: 16))
                VStack {
                    Text("warnings.limits_error.title".localizedForSwiftUI)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .font(.system(size: 11))
                    Text("warnings.limits_error.steps".localizedForSwiftUI)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .font(.system(size: 11))
                }
            }
            .padding(10)
            .padding(.leading, 30)
            .padding(.trailing, 30)
        } else {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .center, spacing: 3) {
                    SectionHeaderView(text: "mi_memory_limit".localized.uppercased())
                    Text(memoryLimit)
                        .fontWeight(.medium)
                        .font(.system(size: 16))
                }
                Divider()
                VStack(alignment: .center, spacing: 3) {
                    SectionHeaderView(text: "mi_post_max_size".localized.uppercased())
                    Text(maxPostSize)
                        .fontWeight(.medium)
                        .font(.system(size: 16))
                }
                Divider()
                VStack(alignment: .center, spacing: 3) {
                    SectionHeaderView(text: "mi_upload_max_filesize".localized.uppercased())
                    Text(maxUploadSize)
                        .fontWeight(.medium)
                        .font(.system(size: 16))
                }
                Divider().hidden()
                Button {
                    Task { @MainActor in
                        MainMenu.shared.openConfigGUI()
                    }
                } label: {
                    Image(systemName: "gearshape.fill")
                }
                .accessibility(identifier: "phpConfigButton")
                .focusable(false)
                .frame(minWidth: 30, alignment: .center)
            }
            .padding(5)
            .background(Color.debug)
        }
    }
}

#Preview {
    StatsView(
        memoryLimit: "1024 MB",
        maxPostSize: "1024 MB",
        maxUploadSize: "1024 MB"
    ).frame(height: 100)
}
