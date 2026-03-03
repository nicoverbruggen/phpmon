//
//  StartupAlertView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 25/02/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct StartupAlertView: View {
    @ObservedObject var viewModel: StartupAlertViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 60, height: 60)

                VStack(alignment: .leading, spacing: 10) {
                    StartupAlertHeaderView(
                        titleText: viewModel.check.titleText,
                        subtitleText: viewModel.check.subtitleText
                    )
                    .padding(.top, 4)
                    .padding(.bottom, 8)

                    // Fix command description: only shown in idle state when a fix is available
                    if viewModel.state == .idle && viewModel.hasFix {
                        StartupFixCommandView(
                            command: viewModel.check.fixDescription ?? ""
                        )
                    } else if viewModel.state == .idle && !viewModel.hasFix {
                        Divider()
                    }

                    // Terminal output: shown during and after fix execution
                    if !viewModel.outputLines.isEmpty
                        && (viewModel.state == .running || viewModel.state == .completed || viewModel.state == .failed) {
                        StartupOutputView(
                            lines: viewModel.outputLines,
                            isRunning: viewModel.state == .running
                        )
                    }

                    // Description text: shown in idle state
                    if !viewModel.check.descriptionText.isEmpty && viewModel.state == .idle {
                        MarkdownTextView(viewModel.check.descriptionText, fontSize: 12, textColor: NSColor.secondaryLabelColor)
                            .padding(.vertical, 5)
                    }
                }
                .padding(.trailing, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(15)
            .padding(.top, -5)

            Divider()

            StartupAlertButtonRow(
                state: viewModel.state,
                hasFix: viewModel.hasFix,
                onQuit: { viewModel.quit() },
                onRetry: { viewModel.retryAllChecks() },
                onFix: { viewModel.runFix() }
            )
        }
        .frame(width: 520)
    }
}

// MARK: - Previews

#Preview("No Fix Available") {
    return StartupAlertView(
        viewModel: StartupAlertViewModel(check: EnvironmentCheck(
            command: { _ in return true },
            fix: nil,
            name: "preview_php_binary",
            titleText: "startup.errors.php_binary.title".localized,
            subtitleText: "startup.errors.php_binary.subtitle".localized,
            descriptionText: "startup.errors.php_binary.desc".localized(
                App.shared.container.paths.php
            )
        ))
    )
}

#Preview("Fix Available") {
    return StartupAlertView(
        viewModel: StartupAlertViewModel(check: EnvironmentCheck(
            command: { _ in return true },
            fix: { _, output in output("Running brew link php...", .stdOut) },
            fixDescription: "brew link php",
            name: "preview_php_binary",
            titleText: "startup.errors.php_binary.title".localized,
            subtitleText: "startup.errors.php_binary.subtitle".localized,
            descriptionText: "startup.errors.php_binary.desc".localized(
                App.shared.container.paths.php
            )
        ))
    )
}

#Preview("Fix Running") {
    StartupAlertView(viewModel: StartupAlertViewModel(
        check: EnvironmentCheck(
            command: { _ in return true },
            fix: { _, output in output("Running...", .stdOut) },
            fixDescription: "brew link php",
            name: "preview_php_binary_running",
            titleText: "startup.errors.php_binary.title".localized,
            subtitleText: "startup.errors.php_binary.subtitle".localized,
            descriptionText: "startup.errors.php_binary.desc".localized(
                App.shared.container.paths.php
            )
        ),
        state: .running,
        outputLines: [
            OutputLine(text: "==> Linking Binary 'php' to '/opt/homebrew/bin/php'", stream: .stdOut),
            OutputLine(text: "==> Linking php... linked 25 files", stream: .stdOut)
        ]
    ))
}

#Preview("Fix Failed") {
    StartupAlertView(viewModel: StartupAlertViewModel(
        check: EnvironmentCheck(
            command: { _ in return true },
            fix: { _, output in output("Running brew link php...", .stdOut) },
            fixDescription: "brew link php",
            name: "preview_php_binary_failed",
            titleText: "startup.errors.php_binary.title".localized,
            subtitleText: "startup.errors.php_binary.subtitle".localized,
            descriptionText: "startup.errors.php_binary.desc".localized(
                App.shared.container.paths.php
            )
        ),
        state: .failed,
        outputLines: [
            OutputLine(text: "==> Linking Binary 'php' to '/opt/homebrew/bin/php'", stream: .stdOut),
            OutputLine(text: "Warning: php is keg-only and must be linked with --force", stream: .stdErr),
            OutputLine(text: "", stream: .stdOut),
            OutputLine(text: "\nFix did not resolve the issue.", stream: .stdOut)
        ]
    ))
}

#Preview("Fix Completed") {
    StartupAlertView(viewModel: StartupAlertViewModel(
        check: EnvironmentCheck(
            command: { _ in return true },
            fix: { _, output in output("Running brew link php...", .stdOut) },
            fixDescription: "brew link php",
            name: "preview_php_binary_completed",
            titleText: "startup.errors.php_binary.title".localized,
            subtitleText: "startup.errors.php_binary.subtitle".localized,
            descriptionText: "startup.errors.php_binary.desc".localized(
                App.shared.container.paths.php
            )
        ),
        state: .completed,
        outputLines: [
            OutputLine(text: "==> Linking Binary 'php' to '/opt/homebrew/bin/php'", stream: .stdOut),
            OutputLine(text: "==> Linking php... linked 25 files", stream: .stdOut),
            OutputLine(text: "\nFix applied successfully! Continuing...", stream: .stdOut)
        ]
    ))
}
