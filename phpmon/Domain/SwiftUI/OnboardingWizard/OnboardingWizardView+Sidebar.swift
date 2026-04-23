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

        return HStack {
            sidebarTimelineMarker(status: status, isFirst: true, isLast: false)

            Text("onboarding_wizard.steps.introduction".localized)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
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

    func sidebarStep(
        number: Int,
        title: String,
        badgeTitle: String? = nil
    ) -> some View {
        let status = stepStatus(for: number)

        return HStack {
            sidebarTimelineMarker(status: status, isFirst: false, isLast: number == totalWizardSteps)

            sidebarStepLabel(title: title, badgeTitle: badgeTitle)
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

    func sidebarTimelineMarker(status: StepStatus, isFirst: Bool, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(isFirst ? Color.clear : timelineLineColor)
                .frame(width: 1)

            Circle()
                .fill(status.timelineDotColor)
                .frame(width: 7, height: 7)

            Rectangle()
                .fill(isLast ? Color.clear : timelineLineColor)
                .frame(width: 1)
        }
        .frame(width: 12)
    }

    func sidebarStepLabel(title: String, badgeTitle: String?) -> some View {
        HStack(alignment: .center, spacing: 7) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)

            if let badgeTitle {
                badge(badgeTitle)
            }
        }
    }

    func badge(_ title: String) -> some View {
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
