//
//  PrivilegedCommandApprovalWindowController.swift
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
        let controller = PrivilegedCommandApprovalWindowController.create(reason: reason)
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
        VStack(alignment: .leading, spacing: 18) {
            Text("privileged_command.modal.title".localized)
                .font(.title2.weight(.semibold))
                .accessibilityIdentifier("PrivilegedCommandApprovalTitle")

            Text("privileged_command.modal.description".localized(viewModel.reason.localizedDescription))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("PrivilegedCommandApprovalMessage")

            Spacer(minLength: 0)

            HStack(spacing: 12) {
                Spacer()

                Button("privileged_command.modal.deny".localized) {
                    viewModel.onDeny?()
                }
                .accessibilityIdentifier("PrivilegedCommandDenyButton")

                Button("privileged_command.modal.approve".localized) {
                    viewModel.onApprove?()
                }
                .keyboardShortcut(.defaultAction)
                .accessibilityIdentifier("PrivilegedCommandApproveButton")
            }
        }
        .padding(24)
        .frame(width: 460, height: 210)
    }
}

@MainActor
final class PrivilegedCommandApprovalWindowController: NSWindowController, NSWindowDelegate {
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

    static func create(reason: PrivilegedCommandReason) -> PrivilegedCommandApprovalWindowController {
        let viewModel = PrivilegedCommandApprovalViewModel(reason: reason)
        let controller = PrivilegedCommandApprovalWindowController(viewModel: viewModel)
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
