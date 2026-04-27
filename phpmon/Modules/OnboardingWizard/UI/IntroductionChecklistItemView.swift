//
//  IntroductionChecklistItemView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 25/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct IntroductionChecklistItemView: View {
    let number: Int
    let title: String
    var badgeTitle: String?
    let description: String
    var isCompleted: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                if isCompleted {
                    Circle()
                        .fill(Color.green.opacity(0.14))
                        .frame(width: 22, height: 22)

                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.green)
                } else {
                    Circle()
                        .fill(Color.accentColor.opacity(0.14))
                        .frame(width: 22, height: 22)

                    Text("\(number)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.top, 1)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))

                    if isCompleted {
                        OnboardingBadgeView(title: "onboarding_wizard.badges.completed".localized)
                    }

                    if let badgeTitle {
                        OnboardingBadgeView(title: badgeTitle)
                    }
                }

                Text(description)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
