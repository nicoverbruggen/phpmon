//
//  OnboardingWizardTestSupport.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 27/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation

final class OnboardingTestPrivilegedCommandRunner: PrivilegedCommandRunner {
    enum Response {
        case approve(String)
        case deny
        case fail(Error)
    }

    private(set) var requests: [(String, PrivilegedCommandReason)] = []
    private var responses: [Response]

    init(responses: [Response] = [.approve(""), .approve("")]) {
        self.responses = responses
    }

    @MainActor
    func runSimpleShellAsAdmin(_ script: String, reason: PrivilegedCommandReason) async throws -> String {
        requests.append((script, reason))

        let response = responses.isEmpty ? .approve("") : responses.removeFirst()

        switch response {
        case .approve(let output):
            return output
        case .deny:
            throw AdminPrivilegeError(kind: .userDenied)
        case .fail(let error):
            throw error
        }
    }
}

func makeOnboardingContainer(
    architecture: String,
    configuredShell: String = "/bin/zsh"
) -> Container {
    let container = Container()
    container.withFakeSystemContext(
        architecture: architecture,
        configuredShell: configuredShell
    )
    container.bind(coreOnly: true, commandTracking: false)
    return container
}

func makeOnboardingFakeContainer(
    architecture: String,
    configuredShell: String = "/bin/zsh",
    pathConfigured: Bool = false,
    shell: [String: BatchFakeShellOutput],
    files: [String: FakeFile],
    includeDeveloperTools: Bool = true,
    privilegedCommandRunner: PrivilegedCommandRunner? = nil
) -> Container {
    let container = Container()
    container.withFakeSystemContext(
        architecture: architecture,
        configuredShell: configuredShell
    )
    container.bind(coreOnly: true, commandTracking: false)
    let valetShell: [String: BatchFakeShellOutput] = [
        "cat /private/etc/sudoers.d/brew": .instant(""),
        "cat /private/etc/sudoers.d/valet": .instant("")
    ]
    let developerToolsShell: [String: BatchFakeShellOutput] = includeDeveloperTools
        ? ["/usr/bin/xcode-select -p": .instant("/Library/Developer/CommandLineTools")]
        : [:]

    container.overrideFake(
        shellExpectations: valetShell
            .merging(developerToolsShell) { (_, new) in new }
            .merging(shell) { (_, new) in new },
        fileSystemFiles: files,
        privilegedCommandRunner: privilegedCommandRunner ?? OnboardingTestPrivilegedCommandRunner(),
        commandTracking: false
    )

    if pathConfigured, let shell = container.shell as? TestableShell {
        shell.PATH = [
            "/usr/local/bin",
            "/usr/bin",
            "/bin",
            "/usr/sbin",
            "\(container.paths.homePath)/.config/phpmon/bin",
            "\(container.paths.homePath)/.composer/vendor/bin",
            container.paths.binPath
        ].joined(separator: ":")
    }

    return container
}
