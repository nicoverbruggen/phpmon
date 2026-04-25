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
            HStack(spacing: 10) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: 2) {
                    Text("onboarding_wizard.title".localized)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)

                    Text(currentProgressText)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 18)

            introductionSidebarStep
            sidebarStep(
                number: 1,
                title: "onboarding_wizard.steps.developer_tools".localized
            )
            sidebarStep(
                number: 2,
                title: "onboarding_wizard.steps.homebrew".localized
            )
            sidebarStep(
                number: 3,
                title: "onboarding_wizard.steps.php_composer".localized
            )
            sidebarStep(
                number: 4,
                title: "onboarding_wizard.steps.valet".localized,
                badgeTitle: "onboarding_wizard.badges.optional".localized
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

    var introductionSidebarStep: some View {
        let status: StepStatus = isShowingIntroduction ? .active : .completed

        return OnboardingSidebarStepView(
            status: status,
            title: "onboarding_wizard.steps.introduction".localized,
            isFirst: true,
            isLast: false
        )
    }

    func sidebarStep(
        number: Int,
        title: String,
        badgeTitle: String? = nil
    ) -> some View {
        let status = stepStatus(for: number)

        return OnboardingSidebarStepView(
            status: status,
            title: title,
            badgeTitle: badgeTitle,
            isFirst: false,
            isLast: number == totalWizardSteps
        )
    }
}
