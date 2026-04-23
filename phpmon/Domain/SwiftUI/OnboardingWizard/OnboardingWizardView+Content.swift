//
//  OnboardingWizardView+Content.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 22/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import SwiftUI

extension OnboardingWizardView {
    var introductionContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("onboarding_wizard.title".localized)
                    .font(.system(size: 20, weight: .semibold))

                Text("onboarding_wizard.description".localized)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 10) {
                introductionChecklistItem(
                    number: 1,
                    title: "onboarding_wizard.steps.developer_tools".localized,
                    description: "onboarding_wizard.intro.developer_tools".localized
                )
                introductionChecklistItem(
                    number: 2,
                    title: "onboarding_wizard.steps.homebrew".localized,
                    description: "onboarding_wizard.intro.homebrew".localized
                )
                introductionChecklistItem(
                    number: 3,
                    title: "onboarding_wizard.steps.php_composer".localized,
                    description: "onboarding_wizard.intro.php_composer".localized
                )
                introductionChecklistItem(
                    number: 4,
                    title: "onboarding_wizard.steps.valet".localized,
                    badgeTitle: "onboarding_wizard.badges.optional".localized,
                    description: "onboarding_wizard.intro.valet".localized
                )
            }
            .padding(16)
            .background(cardBackground)

            Text("onboarding_wizard.intro.footer".localized)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    var stepContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text(displayedDetailTitle)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(detailTitleColor)

                Text(displayedDetailDescription)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, 18)

            if viewModel.state == .running {
                ProgressView()
                    .progressViewStyle(.linear)
                    .padding(.bottom, 16)
            }

            if !isDisplayingCompletedStep,
               let commandTitle = viewModel.commandTitle,
               !viewModel.commandLines.isEmpty {
                commandBlock(title: commandTitle, lines: viewModel.commandLines)
                    .padding(.bottom, 14)
            }

            if viewModel.showsOutput {
                StartupOutputView(
                    lines: viewModel.outputLines,
                    isRunning: viewModel.state == .running
                )
            }
        }
    }

    func introductionChecklistItem(
        number: Int,
        title: String,
        badgeTitle: String? = nil,
        description: String
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.14))
                    .frame(width: 22, height: 22)

                Text("\(number)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .padding(.top, 1)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))

                    if let badgeTitle {
                        badge(badgeTitle)
                    }
                }

                Text(description)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    func commandBlock(title: String, lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .foregroundStyle(Color.app)
                .font(.system(size: 10, weight: .semibold))

            VStack(alignment: .leading, spacing: 4) {
                ForEach(lines, id: \.self) { line in
                    Text(line)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.white)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(10)
            .background(Color.black.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }

    var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color(nsColor: .controlBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
    }
}
