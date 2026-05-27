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
                Text(viewState.detailTitle)
                    .font(.system(size: 20, weight: .semibold))

                Text(viewState.detailDescription)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(viewState.introductionItems) { item in
                    IntroductionChecklistItemView(
                        number: item.number,
                        title: item.title,
                        badgeTitle: item.badgeTitle,
                        description: item.description,
                        isCompleted: item.isCompleted
                    )
                }
            }
            .padding(16)
            .background(cardBackground)

            Text(viewState.introductionFooterText)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    var stepContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewState.detailTitle)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.primary)

                Text(viewState.detailDescription)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, 18)

            if viewState.isRunning {
                ProgressView()
                    .progressViewStyle(.linear)
                    .padding(.bottom, 16)
            }

            if let commandBlock = viewState.commandBlock {
                OnboardingCommandBlockView(title: commandBlock.title, lines: commandBlock.lines)
                    .padding(.bottom, 14)
            }

            if let statusBanner = viewState.statusBanner {
                Text(statusBanner.text)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(statusBanner.foregroundColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(statusBanner.backgroundColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(statusBanner.borderColor, lineWidth: 1)
                    )
                    .accessibilityIdentifier("OnboardingStatusBanner")
                    .accessibilityValue(statusBanner.severity.accessibilityValue)
            } else if viewState.showsTerminalOutput {
                StartupOutputView(
                    lines: viewState.outputLines,
                    isRunning: viewState.isRunning
                )
            }
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

private extension OnboardingViewState.StatusBanner {
    var foregroundColor: Color {
        switch severity {
        case .info:
            return .statusColorBlue
        case .warning:
            return .statusColorOrange.opacity(0.95)
        }
    }

    var backgroundColor: Color {
        switch severity {
        case .info:
            return .statusColorBlue.opacity(0.10)
        case .warning:
            return .statusColorOrange.opacity(0.10)
        }
    }

    var borderColor: Color {
        switch severity {
        case .info:
            return .statusColorBlue.opacity(0.24)
        case .warning:
            return .statusColorOrange.opacity(0.24)
        }
    }
}

private extension OnboardingViewState.StatusBannerSeverity {
    var accessibilityValue: String {
        switch self {
        case .info:
            return "info"
        case .warning:
            return "warning"
        }
    }
}
