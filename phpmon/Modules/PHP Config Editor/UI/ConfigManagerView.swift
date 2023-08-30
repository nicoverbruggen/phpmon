//
//  ConfigManagerView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 18/07/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import SwiftUI

class PhpPreference {
    let key: String

    init(key: String) {
        self.key = key
    }
}

class BoolPhpPreference: PhpPreference {
    @State var value: Bool = true
}

class StringPhpPreference: PhpPreference {
    @State var value: String = ""
}

class BytePhpPreference: PhpPreference {
    @State var value: String = ""
}

enum PhpPreferenceType {
    case byteLimit
    case string
    case boolean
}

struct ConfigManagerView: View {
    var preferences: [PhpPreference] = [
        BytePhpPreference(key: "memory_limit"),
        BytePhpPreference(key: "post_max_size"),
        BoolPhpPreference(key: "file_uploads"),
        BytePhpPreference(key: "upload_max_filesize")
    ]

    var body: some View {
        VStack {
            HStack(alignment: .center, spacing: 15) {
                Image(systemName: "square.and.pencil.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(Color.blue)
                    .padding(12)
                VStack(alignment: .leading, spacing: 5) {
                    Text("confman.title".localizedForSwiftUI)
                        .bold()
                        .font(.system(size: 12))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("confman.description".localizedForSwiftUI)
                        .font(.system(size: 12))
                        .fixedSize(horizontal: false, vertical: true)
                        .scaledToFit()
                        .lineLimit(4)
                }
            }
            .padding(10)

            Divider()

            VStack(spacing: 5) {
                VStack {
                    ForEach(preferences, id: \.key) { preference in
                        PreferenceContainer(
                            name: "php_ini.\(preference.key).title",
                            description: "php_ini.\(preference.key).description"
                        ) {
                            if let preference = preference as? BytePhpPreference {
                                ByteLimitView()
                            }
                            if let preference = preference as? BoolPhpPreference {
                                Toggle("", isOn: preference.$value)
                                    .toggleStyle(.switch)
                                    .padding(.leading, -10)
                            }
                            if let preference = preference as? StringPhpPreference {
                                TextField("Placeholder", text: preference.$value)
                            }
                        }.frame(maxWidth: .infinity)
                    }
                }.padding(10)

                Divider()

                VStack(alignment: .trailing) {
                    Button("Close", action: {

                    })
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 15)
                .frame(
                    minWidth: 0,
                    maxWidth: .infinity,
                    alignment: .topTrailing
                )
            }
        }
    }
}

struct ConfigManagerView_Previews: PreviewProvider {
    static var previews: some View {
        ConfigManagerView()
            .frame(width: 600)
            .previewDisplayName("Live Preview")
    }
}
