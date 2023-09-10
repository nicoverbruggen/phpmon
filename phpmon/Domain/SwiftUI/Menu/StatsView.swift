//
//  StatsView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 09/06/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct StatsView: View {

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
            HStack(alignment: .firstTextBaseline, spacing: 30) {
                VStack(alignment: .center, spacing: 3) {
                    SectionHeaderView(text: "mi_memory_limit".localized.uppercased())
                    Text(memoryLimit)
                        .fontWeight(.medium)
                        .font(.system(size: 16))
                }
                VStack(alignment: .center, spacing: 3) {
                    SectionHeaderView(text: "mi_post_max_size".localized.uppercased())
                    Text(maxPostSize)
                        .fontWeight(.medium)
                        .font(.system(size: 16))
                }
                VStack(alignment: .center, spacing: 3) {
                    SectionHeaderView(text: "mi_upload_max_filesize".localized.uppercased())
                    Text(maxUploadSize)
                        .fontWeight(.medium)
                        .font(.system(size: 16))
                }
            }
            .padding(10)
            .background(Color.debug)
        }
    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView(
            memoryLimit: "1024 MB",
            maxPostSize: "1024 MB",
            maxUploadSize: "1024 MB"
        )
    }
}
