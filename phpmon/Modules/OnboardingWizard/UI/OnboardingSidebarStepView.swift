//
//  OnboardingSidebarStepView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 25/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct OnboardingSidebarStepView: View {
    let status: StepStatus
    let title: String
    var badgeTitle: String?
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        HStack {
            OnboardingSidebarTimelineMarkerView(status: status, isFirst: isFirst, isLast: isLast)

            HStack(alignment: .center, spacing: 7) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)

                if let badgeTitle {
                    OnboardingBadgeView(title: badgeTitle)
                }
            }
            .layoutPriority(1)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .frame(height: 42)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(status.isActive ? Color.accentColor.opacity(0.13) : Color.clear)
        )
        .padding(.horizontal, 8)
    }
}
