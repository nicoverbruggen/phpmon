//
//  OnboardingWizardView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 22/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct OnboardingWizardView: View {
    let completedSteps: Set<Int>
    let onContinue: () -> Void
    let onQuit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 60, height: 60)

                VStack(alignment: .leading, spacing: 8) {
                    Text("onboarding_wizard.title".localized)
                        .font(.system(size: 20, weight: .semibold))

                    Text(
                        "onboarding_wizard.description".localized
                    )
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                wizardStep(
                    number: 1,
                    title: "onboarding_wizard.steps.developer_tools".localized,
                    isCompleted: completedSteps.contains(1)
                )
                wizardStep(
                    number: 2,
                    title: "onboarding_wizard.steps.homebrew".localized,
                    isCompleted: completedSteps.contains(2)
                )
                wizardStep(
                    number: 3,
                    title: "onboarding_wizard.steps.php_composer".localized,
                    isCompleted: completedSteps.contains(3)
                )
                wizardStep(
                    number: 4,
                    title: "onboarding_wizard.steps.valet".localized,
                    badgeTitle: "onboarding_wizard.badges.optional".localized,
                    isCompleted: completedSteps.contains(4)
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
            .padding(.leading, 74)

            HStack {
                Button("onboarding_wizard.buttons.quit".localized) {
                    onQuit()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("onboarding_wizard.buttons.continue".localized) {
                    onContinue()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 540)
    }

    @ViewBuilder
    private func wizardStep(
        number: Int,
        title: String,
        badgeTitle: String? = nil,
        isCompleted: Bool = false
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.14))
                    .frame(width: 26, height: 26)

                Text("\(number)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }

            HStack(alignment: .center, spacing: 8) {
                Text(title)
                    .font(.system(size: 13))
                    .fixedSize(horizontal: false, vertical: true)

                if let badgeTitle {
                    Text(badgeTitle)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.secondary.opacity(0.08))
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(Color.secondary.opacity(0.12), lineWidth: 0.5)
                        )
                }
            }

            Spacer(minLength: 0)

            statusIndicator(isCompleted: isCompleted)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func statusIndicator(isCompleted: Bool) -> some View {
        HStack(spacing: 6) {
            Text(
                isCompleted
                    ? "onboarding_wizard.status.ok".localized
                    : "onboarding_wizard.status.pending".localized
            )
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.secondary)

            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.green.opacity(0.85))
                    .frame(width: 14, height: 14)
            } else {
                Circle()
                    .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
                    .frame(width: 14, height: 14)
            }
        }
        .frame(width: 68, alignment: .trailing)
    }
}

#Preview {
    OnboardingWizardView(
        completedSteps: [1],
        onContinue: {},
        onQuit: {}
    )
}
