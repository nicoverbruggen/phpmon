//
//  OnboardingCommandBlockView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 25/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct OnboardingCommandBlockView: View {
    let title: String
    let lines: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .foregroundStyle(Color.app)
                .font(.system(size: 10, weight: .semibold))

            VStack(alignment: .leading, spacing: 4) {
                ForEach(lines, id: \.self) { line in
                    Text(line)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.white)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(10)
            .background(Color.black.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }
}
