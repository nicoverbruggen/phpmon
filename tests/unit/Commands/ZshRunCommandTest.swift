//
//  ZshRunCommandTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 26/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Testing

struct ZshRunCommandTest {
    // Bare home-directory aliases should normalize to the resolved home path.
    @Test func path_entry_normalization_resolves_bare_home_aliases() {
        #expect(PathEntry.normalize("~", homePath: "/Users/fake") == "/Users/fake")
        #expect(PathEntry.normalize("$HOME", homePath: "/Users/fake") == "/Users/fake")
    }

    // Home-directory prefixes should normalize whether they use ~ or $HOME.
    @Test func path_entry_normalization_resolves_home_prefixed_paths() {
        #expect(PathEntry.normalize("~/.composer/vendor/bin", homePath: "/Users/fake") == "/Users/fake/.composer/vendor/bin")
        #expect(PathEntry.normalize("$HOME/.config/phpmon/bin", homePath: "/Users/fake") == "/Users/fake/.config/phpmon/bin")
    }

    // Extra trailing slashes should not make equivalent PATH entries compare differently.
    @Test func path_entry_normalization_removes_trailing_slashes() {
        #expect(PathEntry.normalize("/opt/homebrew/bin///", homePath: "/Users/fake") == "/opt/homebrew/bin")
        #expect(PathEntry.normalize("$HOME/.config/phpmon/bin/", homePath: "/Users/fake") == "/Users/fake/.config/phpmon/bin")
    }

    // Root itself should remain stable even though other trailing slashes are removed.
    @Test func path_entry_normalization_preserves_root_path() {
        #expect(PathEntry.normalize("/", homePath: "/Users/fake") == "/")
    }

    // Non-home absolute paths should remain untouched apart from harmless slash cleanup.
    @Test func path_entry_normalization_preserves_non_home_paths() {
        #expect(PathEntry.normalize("/usr/local/bin", homePath: "/Users/fake") == "/usr/local/bin")
        #expect(PathEntry.normalize("/usr/local/bin/", homePath: "/Users/fake") == "/usr/local/bin")
    }

    // Existing ~/.zshrc PATH entries should make onboarding writes idempotent.
    @Test func zsh_path_updates_skip_normalized_existing_entries() async {
        let container = prepareContainer(
            withFiles: [
                "~/.zshrc": .fake(.text, """
                export PATH="$HOME/bin:$HOME/.config/phpmon/bin:$PATH"
                export PATH="$HOME/bin:$HOME/.composer/vendor/bin:$PATH"
                export PATH="$HOME/bin:/opt/homebrew/bin:$PATH"
                """)
            ]
        )

        let originalContents = try? container.filesystem.getStringFromFile("~/.zshrc")

        #expect(await ZshRunCommand(container).addPhpMonitorBinPath())
        #expect(await ZshRunCommand(container).addComposerBinPath())
        #expect(await ZshRunCommand(container).addHomebrewBinPath())
        #expect((try? container.filesystem.getStringFromFile("~/.zshrc")) == originalContents)
    }

    // Similar-looking backup paths should still allow the real onboarding export to be appended once.
    @Test func zsh_path_updates_append_when_only_similar_entries_exist() async {
        let container = prepareContainer(
            withFiles: [
                "~/.zshrc": .fake(.text, """
                export PATH="$HOME/bin:$HOME/.config/phpmon/bin-backup:$PATH"
                export PATH="$HOME/bin:$HOME/.composer/vendor/bin-old:$PATH"
                export PATH="$HOME/bin:/opt/homebrew/bin-old:$PATH"
                """)
            ]
        )

        let exportLine = ShellEnvironment(container).phpMonitorBinPathExport
        let expectedCommand = ZshRunCommand.append(for: exportLine)
        let expectedContents = [
            "export PATH=\"$HOME/bin:$HOME/.config/phpmon/bin-backup:$PATH\"",
            "export PATH=\"$HOME/bin:$HOME/.composer/vendor/bin-old:$PATH\"",
            "export PATH=\"$HOME/bin:/opt/homebrew/bin-old:$PATH\"",
            exportLine
        ].joined(separator: "\n")

        (container.shell as? TestableShell)?.expectations[expectedCommand] = BatchFakeShellOutput(
            items: [.instant("")],
            transactions: [.write(expectedContents, to: "~/.zshrc")]
        )

        #expect(await ZshRunCommand(container).addPhpMonitorBinPath())
        #expect((try? container.filesystem.getStringFromFile("~/.zshrc")) == expectedContents)
    }

    private func prepareContainer(withFiles files: [String: FakeFile]) -> Container {
        let container = Container()
        container.withFakeSystemContext(architecture: "arm64")
        container.bind(coreOnly: true, commandTracking: false)

        container.overrideFake(
            fileSystemFiles: files,
            commandTracking: false
        )

        return container
    }

}
