//
//  SelectDomainView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 18/02/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct SelectDomainTypeView: View {
    var onCancel: () -> Void
    var onCreateLink: () -> Void
    var onCreateProxy: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 15) {
                Text("selection.title")
                    .font(.system(size: 16, weight: .bold, design: .default))
                Text("selection.description")
            }.padding(25)

            Divider()

            HStack {
                Button("selection.cancel".localized) {
                    onCancel()
                }
                Spacer()
                SimpleButton(
                    title: "selection.create_link".localized,
                    imageName: "IconLinked",
                    action: { onCreateLink() }
                )
                SimpleButton(
                    title: "selection.create_proxy".localized,
                    imageName: "IconProxy",
                    action: { onCreateProxy() }
                )
            }
            .padding(.all, 20)
            .padding(.top, -10)
        }
        .frame(width: 600)
    }
}

#Preview {
    SelectDomainTypeView(onCancel: {}, onCreateLink: {}, onCreateProxy: {})
}
