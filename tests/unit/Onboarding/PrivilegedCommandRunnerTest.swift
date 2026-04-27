//
//  PrivilegedCommandRunnerTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 27/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Testing

@MainActor
struct PrivilegedCommandRunnerTest {
    @Test func real_runner_delegates_to_the_admin_script_executor() async throws {
        let executor = StubAdminScriptExecutor(result: "OK")
        let runner = RealPrivilegedCommandRunner(executor: executor)

        let result = try await runner.runSimpleShellAsAdmin(
            "sudo whoami",
            reason: .onboardingValetTemporarySudoersInstall
        )

        #expect(result == "OK")
        #expect(executor.receivedScripts == ["sudo whoami"])
    }

    @Test func ui_test_runner_returns_success_when_approved() async throws {
        let runner = UITestPrivilegedCommandRunner(
            presenter: StubPrivilegedCommandApprovalPresenter(approved: true),
            approvedOutput: "Approved"
        )

        let result = try await runner.runSimpleShellAsAdmin(
            "sudo whoami",
            reason: .onboardingValetTemporarySudoersCleanup
        )

        #expect(result == "Approved")
    }

    @Test func ui_test_runner_throws_user_denied_when_denied() async {
        let runner = UITestPrivilegedCommandRunner(
            presenter: StubPrivilegedCommandApprovalPresenter(approved: false)
        )

        await #expect(throws: AdminPrivilegeError(kind: .userDenied)) {
            try await runner.runSimpleShellAsAdmin(
                "sudo whoami",
                reason: .onboardingValetTemporarySudoersInstall
            )
        }
    }
}

private final class StubAdminScriptExecutor: AdminScriptExecuting {
    private(set) var receivedScripts: [String] = []
    private let result: String

    init(result: String) {
        self.result = result
    }

    func runSimpleShellAsAdmin(_ script: String) throws -> String {
        receivedScripts.append(script)
        return result
    }
}

@MainActor
private final class StubPrivilegedCommandApprovalPresenter: PrivilegedCommandApprovalPresenting {
    private let approved: Bool

    init(approved: Bool) {
        self.approved = approved
    }

    func requestApproval(for _: PrivilegedCommandReason) async -> Bool {
        approved
    }
}
