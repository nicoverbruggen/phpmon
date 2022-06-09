//
//  StatsView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 09/06/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
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
        view.frame = CGRect(x: 0, y: 0, width: 330, height: 55)
        item.view = view
        return item
    }

    @State var memoryLimit: String
    @State var maxPostSize: String
    @State var maxUploadSize: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 30) {
            VStack(alignment: .center, spacing: 3) {
                StatHeader(text: "mi_memory_limit".localized.uppercased())
                Text(memoryLimit)
                    .fontWeight(.medium)
                    .font(.system(size: 16))
            }
            VStack(alignment: .center, spacing: 3) {
                StatHeader(text: "mi_post_max_size".localized.uppercased())
                Text(maxPostSize)
                    .fontWeight(.medium)
                    .font(.system(size: 16))
            }
            VStack(alignment: .center, spacing: 3) {
                StatHeader(text: "mi_upload_max_filesize".localized.uppercased())
                Text(maxUploadSize)
                    .fontWeight(.medium)
                    .font(.system(size: 16))
            }
        }.padding(10)
    }
}

struct StatHeader: View {
    @State var text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11))
            .fontWeight(.medium)
            .foregroundColor(.secondary)
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
