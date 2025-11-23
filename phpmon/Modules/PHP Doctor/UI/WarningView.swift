//
//  WarningView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 31/07/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct WarningView: View {
    @State var title: String
    @State var paragraphs: [String]
    @State var documentationUrl: String?
    @State var automaticFix: (() async -> Void)?
    @State var busyFixing: Bool = false

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "bandage.fill")
                    .resizable()
                    .frame(width: 18, height: 18)
                    .foregroundColor(Color.orange)
                    .padding(.trailing, 5)
                VStack(alignment: .leading, spacing: 15) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(title.localizedForSwiftUI)
                            .fontWeight(.bold)
                        ForEach(paragraphs, id: \.self) { paragraph in
                            Text(paragraph.localizedForSwiftUI)
                                .font(.system(size: 13))
                        }
                    }
                    .fixedSize(horizontal: false, vertical: false)
                    .frame(
                        minWidth: 0, maxWidth: .infinity,
                        minHeight: 0, maxHeight: .infinity,
                        alignment: .topLeading
                    )

                    HStack {
                        if let automaticFix {
                            Button(
                                action: {
                                    Task {
                                        busyFixing = true
                                        await automaticFix()
                                        busyFixing = false
                                    }
                                },
                                label: {
                                    Text("Fix Automatically")
                                }
                            )
                            .disabled(busyFixing)                        }

                        if let documentationUrl {
                            Button("Learn More") {
                                NSWorkspace.shared.open(URL(string: documentationUrl)!)
                            }
                        }
                    }

                    if busyFixing {
                        HStack {
                            ProgressView()
                               .progressViewStyle(CircularProgressViewStyle())
                               .scaleEffect(0.6)
                            Text("warnings.being_fixed.description".localizedForSwiftUI)
                                .font(.system(size: 12))
                                .foregroundStyle(Color.secondary)
                        }
                    }
                }
            }.padding(5)
        }
    }
}

#Preview("Light Mode") {
    WarningView(
        title: "warnings.helper_permissions.title",
        paragraphs: ["warnings.helper_permissions.description"],
        documentationUrl: "https://nicoverbruggen.be"
    )
    .frame(width: 600, height: 105)
    .padding(25)
}

#Preview("Dark Mode") {
    WarningView(
        title: "warnings.helper_permissions.title",
        paragraphs: ["warnings.helper_permissions.description"],
        documentationUrl: "https://nicoverbruggen.be"
    )
    .preferredColorScheme(.dark)
    .frame(width: 600, height: 105)
    .padding(25)
}
