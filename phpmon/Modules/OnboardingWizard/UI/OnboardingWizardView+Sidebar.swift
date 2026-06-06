//
//  OnboardingWizardView+Sidebar.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 22/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import SwiftUI

extension OnboardingWizardView {
    var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            sidebarHeader
                .padding(.horizontal, 14)
                .padding(.bottom, 16)
                .padding(.top, -5) // slight adjustment

            ForEach(viewState.sidebarItems) { item in
                OnboardingSidebarStepView(
                    status: item.status,
                    title: item.title,
                    badgeTitle: item.badgeTitle,
                    isFirst: item.isFirst,
                    isLast: item.isLast
                )
            }

            Spacer()

            HStack {
                quitButton

                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 18)
        .frame(width: 260)
        .frame(maxHeight: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    var sidebarHeader: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 12) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 3) {
                    Text("onboarding_wizard.title".localized)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(viewState.currentProgressText)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.vertical, 6)

            Divider()
        }
    }
}
