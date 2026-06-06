//
//  OnboardingBadgeView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 25/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct OnboardingBadgeView: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.secondary.opacity(0.07))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.secondary.opacity(0.12), lineWidth: 0.5)
            )
    }
}
