//
//  PrivilegedTestIsolationTest.swift
//  PHP Monitor
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Testing

@MainActor
struct PrivilegedTestIsolationTest {
    @Test func fake_containers_deny_privileged_execution_by_default() async {
        let container = Container.fake()
        #expect(container.privilegedCommandRunner is DisabledPrivilegedCommandRunner)

        await #expect(throws: AdminPrivilegeError(kind: .userDenied)) {
            try await container.privilegedCommandRunner.runSimpleShellAsAdmin(
                "exit 0", reason: .onboardingValetTemporarySudoersInstall
            )
        }
    }

    @Test func fake_permission_repair_discards_stale_host_paths() async throws {
        let fixer = BrewPermissionFixer(Container.fake())
        fixer.broken = [.init(formula: "php", path: "/a-host-path-that-must-not-be-inspected")]

        try await fixer.fixPermissions()
        try await fixer.fixPermissions()

        #expect(fixer.broken.isEmpty)
    }

    @Test func direct_applescript_entry_points_refuse_to_launch_in_tests() {
        #expect(throws: AdminPrivilegeError(kind: .applescriptNilError)) {
            try AppleScript.runSimpleShellAsAdmin("exit 0")
        }
        #expect(throws: AdminPrivilegeError(kind: .applescriptNilError)) {
            try AppleScript.runShellAsAdmin("exit 0", asUser: "fake", appendToPATH: "/fake/bin")
        }
    }
}
