//
//  OnboardingWizardView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 22/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct OnboardingWizardView: View {
    let onContinue: () -> Void
    let onQuit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("onboarding_wizard.title".localized)
                .font(.system(size: 26, weight: .semibold))

            Text(
                "onboarding_wizard.description".localized
            )
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 10) {
                wizardStep(
                    number: 1,
                    title: "onboarding_wizard.steps.developer_tools".localized
                )
                wizardStep(
                    number: 2,
                    title: "onboarding_wizard.steps.homebrew".localized
                )
                wizardStep(
                    number: 3,
                    title: "onboarding_wizard.steps.php_composer".localized
                )
                wizardStep(
                    number: 4,
                    title: "onboarding_wizard.steps.valet".localized
                )
            }

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
    private func wizardStep(number: Int, title: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number).")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 18, alignment: .leading)

            Text(title)
                .font(.system(size: 13))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
