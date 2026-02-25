//
//  StartupFixCommandView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 25/02/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct StartupFixCommandView: View {
    let command: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AUTOMATIC FIX")
                .foregroundStyle(Color.app)
                .font(.system(size: 10))
            HStack(spacing: 8) {
                Image(systemName: "terminal")
                    .foregroundStyle(.secondary)
                Text(command)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.primary)
                Spacer()
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(command, forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(Color.black)
        .foregroundStyle(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

#Preview("brew link php") {
    StartupFixCommandView(command: "brew link php")
        .padding(20)
        .frame(width: 460)
}

#Preview("valet trust") {
    StartupFixCommandView(command: "valet trust")
        .padding(20)
        .frame(width: 460)
}

#Preview("Long command") {
    StartupFixCommandView(command: "brew tap shivammathur/php && brew install shivammathur/php/php")
        .padding(20)
        .frame(width: 460)
}
