//
//  PrivilegedCommandRunner.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 27/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation

// MARK: - Protocols

protocol PrivilegedCommandRunner: AnyObject {
    @MainActor
    func runSimpleShellAsAdmin(_ script: String, reason: PrivilegedCommandReason) async throws -> String
}

protocol PrivilegedCommandApprovalPresenting {
    @MainActor
    func requestApproval(for reason: PrivilegedCommandReason) async -> Bool
}

// MARK: - PrivilegedCommandRunner Implementations

final class RealPrivilegedCommandRunner: PrivilegedCommandRunner {
    @MainActor
    func runSimpleShellAsAdmin(_ script: String, reason _: PrivilegedCommandReason) async throws -> String {
        return try AppleScript.runSimpleShellAsAdmin(script)
    }
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
