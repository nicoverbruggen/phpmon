//
//  PrivilegedCommandView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 27/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Cocoa
import SwiftUI

struct PrivilegedCommandApprovalView: View {
    @ObservedObject var viewModel: PrivilegedCommandApprovalViewModel

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    // swiftlint:disable line_length
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.orange)
                        Text("Administrative Access Required")
                            .font(.headline)
                    }

                    Text("This is a UI test convenience only. Normally, macOS will present a dialog that asks for your password. Clicking on 'Approve' will mimic correct password entry.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    // swiftlint:enable line_length
                }
                .padding(5)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(10)

            Divider()

            HStack(spacing: 12) {
                Spacer()

                Button("Deny".localized) {
                    viewModel.onDeny?()
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("PrivilegedCommandDenyButton")

                Button("Approve".localized) {
                    viewModel.onApprove?()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .accessibilityIdentifier("PrivilegedCommandApproveButton")
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .frame(width: 500)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

#Preview("Temporary sudoers install") {
    PrivilegedCommandApprovalView(
        viewModel: PrivilegedCommandApprovalViewModel(
            reason: .onboardingValetTemporarySudoersInstall
        )
    )
}

#Preview("Temporary sudoers cleanup") {
    PrivilegedCommandApprovalView(
        viewModel: PrivilegedCommandApprovalViewModel(
            reason: .onboardingValetTemporarySudoersCleanup
        )
    )
}

@MainActor
final class PrivilegedCommandApprovalViewModel: ObservableObject {
    let reason: PrivilegedCommandReason
    var onApprove: (() -> Void)?
    var onDeny: (() -> Void)?

    init(reason: PrivilegedCommandReason) {
        self.reason = reason
    }
}

final class PrivilegedCommandApprovalPresenter: PrivilegedCommandApprovalPresenting {
    @MainActor
    func requestApproval(for reason: PrivilegedCommandReason) async -> Bool {
        let controller = PrivilegedCommandAlertWindowController.create(reason: reason)
        return await controller.showModal(attachedTo: NSApp.keyWindow ?? NSApp.mainWindow)
    }
}
