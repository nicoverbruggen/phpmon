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

            introductionSidebarStep
            sidebarStep(
                step: .developerTools,
                title: "onboarding_wizard.steps.developer_tools".localized
            )
            sidebarStep(
                step: .homebrew,
                title: "onboarding_wizard.steps.homebrew".localized
            )
            sidebarStep(
                step: .phpComposer,
                title: "onboarding_wizard.steps.php_composer".localized
            )
            sidebarStep(
                step: .valet,
                title: "onboarding_wizard.steps.valet".localized
            )
            sidebarStep(
                step: .ready,
                title: "onboarding_wizard.steps.ready".localized
            )

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

                    Text(currentProgressText)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.vertical, 6)

            Divider()
        }
    }

    var introductionSidebarStep: some View {
        return OnboardingSidebarStepView(
            status: stepStatus(for: .introduction),
            title: "onboarding_wizard.steps.introduction".localized,
            isFirst: true,
            isLast: false
        )
    }

    func sidebarStep(
        step: OnboardingWizardViewModel.Step,
        title: String,
        badgeTitle: String? = nil
    ) -> some View {
        let status = stepStatus(for: step)

        return OnboardingSidebarStepView(
            status: status,
            title: title,
            badgeTitle: badgeTitle,
            isFirst: false,
            isLast: step == .ready
        )
    }
}
