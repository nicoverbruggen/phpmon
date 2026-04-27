//
//  PrivilegedCommandRunner.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 27/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation

protocol PrivilegedCommandRunner: AnyObject {
    @MainActor
    func runSimpleShellAsAdmin(_ script: String, reason: PrivilegedCommandReason) async throws -> String
}

enum PrivilegedCommandReason {
    case onboardingValetTemporarySudoersInstall
    case onboardingValetTemporarySudoersCleanup

    var localizedDescription: String {
        switch self {
        case .onboardingValetTemporarySudoersInstall:
            return "privileged_command.reason.onboarding_valet_temporary_sudoers_install".localized
        case .onboardingValetTemporarySudoersCleanup:
            return "privileged_command.reason.onboarding_valet_temporary_sudoers_cleanup".localized
        }
    }
}

protocol AdminScriptExecuting {
    func runSimpleShellAsAdmin(_ script: String) throws -> String
}

struct AppleScriptAdminScriptExecutor: AdminScriptExecuting {
    func runSimpleShellAsAdmin(_ script: String) throws -> String {
        try AppleScript.runSimpleShellAsAdmin(script)
    }
}

final class RealPrivilegedCommandRunner: PrivilegedCommandRunner {
    private let executor: AdminScriptExecuting

    init(executor: AdminScriptExecuting = AppleScriptAdminScriptExecutor()) {
        self.executor = executor
    }

    @MainActor
    func runSimpleShellAsAdmin(_ script: String, reason _: PrivilegedCommandReason) async throws -> String {
        return try executor.runSimpleShellAsAdmin(script)
    }
}

protocol PrivilegedCommandApprovalPresenting {
    @MainActor
    func requestApproval(for reason: PrivilegedCommandReason) async -> Bool
}

final class UITestPrivilegedCommandRunner: PrivilegedCommandRunner {
    private let presenter: PrivilegedCommandApprovalPresenting
    private let approvedOutput: String

    init(
        presenter: PrivilegedCommandApprovalPresenting? = nil,
        approvedOutput: String = ""
    ) {
        self.presenter = presenter ?? PrivilegedCommandApprovalPresenter()
        self.approvedOutput = approvedOutput
    }

    @MainActor
    func runSimpleShellAsAdmin(_ script: String, reason: PrivilegedCommandReason) async throws -> String {
        guard await presenter.requestApproval(for: reason) else {
            throw AdminPrivilegeError(kind: .userDenied)
        }

        return approvedOutput
    }
}
