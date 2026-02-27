//
//  ErrorView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 19/02/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct ErrorView: View {
    let message: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.statusColorRed.opacity(0.1))
        .font(.system(size: 11))
    }
}
