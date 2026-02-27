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

    /// Whether the bottom section (description text and/or past output) has content to display.
    /// This is used to conditionally show the section and its divider,
    /// avoiding empty padded sections and double dividers.
    private var hasBottomContent: Bool {
        let hasDescription = !viewModel.check.descriptionText.isEmpty && viewModel.state == .idle

        let hasOutput = !viewModel.outputLines.isEmpty
            && (viewModel.state == .idle || viewModel.state == .completed)

        return hasDescription || hasOutput
    }

    var body: some View {
        VStack(spacing: 0) {
            StartupAlertHeaderView(
                titleText: viewModel.check.titleText,
                subtitleText: viewModel.check.subtitleText
            )

            if viewModel.state == .running || (viewModel.hasFix && viewModel.state == .idle) {
                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    if viewModel.state == .running {
                        StartupOutputView(
                            lines: viewModel.outputLines,
                            isRunning: true
                        )
                    } else {
                        StartupFixCommandView(
                            command: viewModel.check.fixDescription ?? ""
                        )
                    }
                }
                .padding(15)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if hasBottomContent {
                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    if !viewModel.check.descriptionText.isEmpty,
                        viewModel.state == .idle {
                        MarkdownTextView(viewModel.check.descriptionText, fontSize: 12)
                    }

                    if !viewModel.outputLines.isEmpty,
                        viewModel.state == .idle || viewModel.state == .completed {
                        StartupOutputView(
                            lines: viewModel.outputLines,
                            isRunning: false
                        )
                    }
                }
                .padding(15)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            StartupAlertButtonRow(
                state: viewModel.state,
                hasFix: viewModel.hasFix,
                onQuit: { viewModel.quit() },
                onRetry: { viewModel.retryAllChecks() },
                onFix: { viewModel.runFix() }
            )
        }
        .frame(width: 500)
    }
}

// MARK: - Previews

#Preview("Fix Available — brew link php") {
    let check = EnvironmentCheck(
        command: { _ in return true },
        fix: { _, output in output("Running brew link php...", .stdOut) },
        fixDescription: "brew link php",
        name: "preview_php_binary",
        titleText: "startup.errors.php_binary.title".localized,
        subtitleText: "startup.errors.php_binary.subtitle".localized,
        descriptionText: "startup.errors.php_binary.desc".localized(
            App.shared.container.paths.php
        )
    )
    let vm = StartupAlertViewModel(check: check)
    return StartupAlertView(viewModel: vm)
}

#Preview("Fix Available — valet trust") {
    let check = EnvironmentCheck(
        command: { _ in return true },
        fix: { _, output in output("Password required...", .stdOut) },
        fixDescription: "valet trust",
        name: "preview_sudoers_brew",
        titleText: "startup.errors.sudoers_brew.title".localized,
        subtitleText: "startup.errors.sudoers_brew.subtitle".localized,
        descriptionText: "startup.errors.sudoers_brew.desc".localized
    )
    let vm = StartupAlertViewModel(check: check)
    return StartupAlertView(viewModel: vm)
}

#Preview("Fix Running — brew link php") {
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
            OutputLine(text: "==> Downloading https://formulae.brew.sh/api/formula.jws.json", stream: .stdOut),
            OutputLine(text: "Already downloaded: /Users/nico/Library/Caches/Homebrew/downloads/abc123.json", stream: .stdOut),
            OutputLine(text: "Warning: php is keg-only and must be linked with --force", stream: .stdErr),
            OutputLine(text: "==> Linking php... linked 25 files", stream: .stdOut)
        ]
    ))
}

#Preview("No Fix — Valet version unsupported") {
    let check = EnvironmentCheck(
        command: { _ in return true },
        name: "preview_valet_version",
        titleText: "startup.errors.valet_version_not_supported.title".localized,
        subtitleText: "startup.errors.valet_version_not_supported.subtitle".localized,
        descriptionText: "startup.errors.valet_version_not_supported.desc".localized
    )
    let vm = StartupAlertViewModel(check: check)
    return StartupAlertView(viewModel: vm)
}

#Preview("No Fix — Herd running") {
    let check = EnvironmentCheck(
        command: { _ in return true },
        name: "preview_herd_running",
        titleText: "startup.errors.herd_running.title".localized,
        subtitleText: "startup.errors.herd_running.subtitle".localized,
        descriptionText: "startup.errors.herd_running.desc".localized
    )
    let vm = StartupAlertViewModel(check: check)
    return StartupAlertView(viewModel: vm)
}
