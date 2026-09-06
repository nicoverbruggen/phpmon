//
//  MainMenuRefreshTest.swift
//  PHP Monitor
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import AppKit
import Combine
import Testing

@Suite(.serialized)
struct MainMenuRefreshTest {
    @Test func an_old_refresh_does_not_replace_a_completed_php_switch() async throws {
        let container = makeContainer(version: "8.4.0")
        let switchedInstall = try #require(makeContainer(version: "8.5.0").phpEnvs.currentInstall)
        let previousContainer = App.shared.container
        App.shared.container = container
        let menu = InstallationRefreshMenu()
        menu.statusItem.isVisible = false
        defer {
            NSStatusBar.system.removeStatusItem(menu.statusItem)
            App.shared.container = previousContainer
        }

        let probe = "/opt/homebrew/bin/php --ini | grep -E -o '(/[^ ]+\\.ini)'"
        let shell = container.shell as! TestableShell
        shell.expectations[probe] = .delayed(1, "")
        shell.allowsDelayedCommands = true

        let refresh = Task { await menu.refreshActiveInstallation() }
        // The first probe belongs to Container.fake's initial load.
        for await commands in container.commandTracker.$commands.values
            where commands.filter({ $0.command == probe }).count == 2 {
            break
        }

        // The switcher publishes its new installation while the older refresh is suspended.
        container.phpEnvs.currentInstall = switchedInstall
        await refresh.value

        #expect(container.phpEnvs.currentInstall?.version.short == "8.5")
    }

    @Test(arguments: [true, false])
    func overlapping_refreshes_keep_new_configuration(olderFinishesFirst: Bool) async throws {
        let container = makeContainer(version: "8.4.0")
        try container.filesystem.writeAtomicallyToFile("/old.ini", content: "memory_limit = 128M")
        try container.filesystem.writeAtomicallyToFile("/new.ini", content: "memory_limit = 256M")
        let previousContainer = App.shared.container
        App.shared.container = container
        let menu = InstallationRefreshMenu()
        menu.statusItem.isVisible = false
        defer {
            NSStatusBar.system.removeStatusItem(menu.statusItem)
            App.shared.container = previousContainer
        }

        let probe = "/opt/homebrew/bin/php --ini | grep -E -o '(/[^ ]+\\.ini)'"
        let shell = container.shell as! TestableShell
        shell.expectations[probe] = .delayed(olderFinishesFirst ? 1 : 2, "/old.ini")
        shell.allowsDelayedCommands = true
        let first = Task { await menu.refreshActiveInstallation() }
        for await commands in container.commandTracker.$commands.values
            where commands.filter({ $0.command == probe }).count == 2 {
            break
        }

        shell.expectations[probe] = .delayed(olderFinishesFirst ? 2 : 1, "/new.ini")
        let second = Task { await menu.refreshActiveInstallation() }
        for await commands in container.commandTracker.$commands.values
            where commands.filter({ $0.command == probe }).count == 3 {
            break
        }

        await first.value
        await second.value
        #expect(container.phpEnvs.currentInstall?.iniFiles.map(\.filePath) == ["/new.ini"])
    }

    private func makeContainer(version: String) -> Container {
        Container.fake(
            shell: ["/opt/homebrew/bin/php --ini | grep -E -o '(/[^ ]+\\.ini)'": .instant("")],
            files: ["/opt/homebrew/bin/php-config": .fake(.binary)],
            commands: [
                "/opt/homebrew/bin/php-config --version": version,
                "/opt/homebrew/bin/php -r echo ini_get('memory_limit');": "128M",
                "/opt/homebrew/bin/php -r echo ini_get('upload_max_filesize');": "2M",
                "/opt/homebrew/bin/php -r echo ini_get('post_max_size');": "8M"
            ]
        )
    }
}

private class InstallationRefreshMenu: MainMenu {
    override func refreshIcon() {}
    override func rebuild() {}
}
