//
//  PrivilegedCommandAlertWindowController.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 27/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Cocoa
import SwiftUI

final class PrivilegedCommandApprovalPresenter: PrivilegedCommandApprovalPresenting {
    @MainActor
    func requestApproval(for reason: PrivilegedCommandReason) async -> Bool {
        let controller = PrivilegedCommandAlertWindowController.create(reason: reason)
        return await controller.showModal(attachedTo: NSApp.keyWindow ?? NSApp.mainWindow)
    }
}

@MainActor
private final class PrivilegedCommandApprovalViewModel: ObservableObject {
    let reason: PrivilegedCommandReason
    var onApprove: (() -> Void)?
    var onDeny: (() -> Void)?

    init(reason: PrivilegedCommandReason) {
        self.reason = reason
    }
}

private struct PrivilegedCommandApprovalView: View {
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
final class PrivilegedCommandAlertWindowController: NSWindowController, NSWindowDelegate {
    private let viewModel: PrivilegedCommandApprovalViewModel
    private var continuation: CheckedContinuation<Bool, Never>?
    private var didResolve = false
    private weak var presentingWindow: NSWindow?

    private init(viewModel: PrivilegedCommandApprovalViewModel) {
        self.viewModel = viewModel
        super.init(window: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func create(reason: PrivilegedCommandReason) -> PrivilegedCommandAlertWindowController {
        let viewModel = PrivilegedCommandApprovalViewModel(reason: reason)
        let controller = PrivilegedCommandAlertWindowController(viewModel: viewModel)
        let window = NSWindow()

        window.title = ""
        window.styleMask = [.titled]
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.delegate = controller
        window.contentView = NSHostingView(rootView: PrivilegedCommandApprovalView(viewModel: viewModel))
        window.setContentSize(window.contentView!.fittingSize)
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        controller.window = window
        return controller
    }

    func showModal(attachedTo parentWindow: NSWindow?) async -> Bool {
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            self.presentingWindow = parentWindow

            viewModel.onApprove = { [weak self] in
                self?.resolve(approved: true)
            }
            viewModel.onDeny = { [weak self] in
                self?.resolve(approved: false)
            }

            guard let window else {
                self.resolve(approved: false)
                return
            }

            if let parentWindow {
                parentWindow.beginSheet(window)
            } else {
                window.center()
                window.level = .modalPanel
                self.showWindow(nil)
                NSApp.activate(ignoringOtherApps: true)
                window.orderFrontRegardless()
            }
        }
    }

    func windowWillClose(_ notification: Notification) {
        if !didResolve {
            resolve(approved: false)
        }
    }

    private func resolve(approved: Bool) {
        guard !didResolve else { return }

        didResolve = true

        if let presentingWindow, let window, window.sheetParent === presentingWindow {
            presentingWindow.endSheet(window)
        }

        close()
        continuation?.resume(returning: approved)
        continuation = nil
    }
}
