//
//  OnboardingSidebarTimelineMarkerView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 25/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct OnboardingSidebarTimelineMarkerView: View {
    let status: StepStatus
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(isFirst ? Color.clear : Color.secondary.opacity(0.16))
                .frame(width: 1)

            Circle()
                .fill(status.timelineDotColor)
                .frame(width: 7, height: 7)

            Rectangle()
                .fill(isLast ? Color.clear : Color.secondary.opacity(0.16))
                .frame(width: 1)
        }
        .frame(width: 12)
    }
}
