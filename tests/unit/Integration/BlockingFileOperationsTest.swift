//
//  BlockingFileOperationsTest.swift
//  PHP Monitor
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation
import Testing
import os

@MainActor
struct BlockingFileOperationsTest {
    @Test func phpinfo_preparation_leaves_the_main_thread_and_swift_tasks() async {
        let filesystem = RecordingFileSystem(files: [
            "/tmp/phpmon_phpinfo.php": .fake(.text, "old source"),
            "/tmp/phpmon_phpinfo.html": .fake(.text, "old output")
        ])
        let container = prepare(filesystem)
        let command = "\(container.paths.binPath)/php-cgi -q /tmp/phpmon_phpinfo.php > /tmp/phpmon_phpinfo.html"
        (container.shell as! TestableShell).expectations = [command: .instant("")]

        let url = await Actions(container).createTempPhpInfoFile()

        #expect(url.path == "/private/tmp/phpmon_phpinfo.html")
        #expect(filesystem.files["/tmp/phpmon_phpinfo.php"]?.content == "<?php phpinfo();")
        #expect(filesystem.files["/tmp/phpmon_phpinfo.html"] == nil)
        #expect(!filesystem.accesses.isEmpty)
        #expect(filesystem.accesses.allSatisfy { !$0.isMainThread && !$0.hasSwiftTask })
    }

    @Test func updater_preparation_leaves_the_main_thread_and_swift_tasks() async {
        let filesystem = RecordingFileSystem(files: [
            "/opt/homebrew/Caskroom/phpmon": .fake(.directory)
        ])
        let container = prepare(filesystem)
        let directory = "\(container.paths.homePath)/.config/phpmon/updater"
        let updater = "/Applications/PHP Monitor.app/Contents/Resources/PHP Monitor Self-Updater.app"
        (container.shell as! TestableShell).expectations = [
            "mkdir -p \"\(directory)\" 2> /dev/null": .instant(""),
            "cp -R \"\(updater)\" \"\(directory)/PHP Monitor Self-Updater.app\"": .instant("")
        ]

        await AppUpdater().prepareUpdateFiles(container: container, updater: updater, manifest: "test manifest")

        #expect(filesystem.files[container.paths.caskroomPath] == nil)
        #expect(filesystem.files[directory + "/update.json"]?.content == "test manifest")
        #expect(!filesystem.accesses.isEmpty)
        #expect(filesystem.accesses.allSatisfy { !$0.isMainThread && !$0.hasSwiftTask })
    }

    @Test func extension_discovery_leaves_the_main_thread_and_swift_tasks() async {
        let filesystem = RecordingFileSystem(files: [
            "/opt/homebrew/Library/Taps/shivammathur/homebrew-extensions/Formula/redis@8.4.rb": .fake(.text, "depends_on \"shivammathur/extensions/igbinary@8.4\"")
        ])
        let container = prepare(filesystem)

        let formulae = await BrewTapFormulae.from(container, tap: "shivammathur/homebrew-extensions")

        #expect(formulae["8.4"]?.map(\.name) == ["redis"])
        #expect(formulae["8.4"]?.first?.extensionDependencies == ["igbinary"])
        #expect(!filesystem.accesses.isEmpty)
        #expect(filesystem.accesses.allSatisfy { !$0.isMainThread && !$0.hasSwiftTask })
    }

    @Test func existing_zshrc_is_read_outside_swift_tasks_without_appending_duplicate_paths() async {
        let filesystem = RecordingFileSystem(files: [
            "~/.zshrc": .fake(.text, "export PATH=/opt/homebrew/bin:$PATH")
        ])
        let container = prepare(filesystem)

        #expect(await ZshRunCommand(container).addHomebrewBinPath())
        #expect(!filesystem.accesses.isEmpty)
        #expect(filesystem.accesses.allSatisfy { !$0.isMainThread && !$0.hasSwiftTask })
    }

    @Test func missing_valet_files_are_repaired_outside_swift_tasks_without_overwriting_existing_configuration() async {
        let config = "/opt/homebrew/etc/php/8.4/conf.d/"
        let filesystem = RecordingFileSystem(files: [
            "~/.composer/vendor/laravel/valet/cli/stubs/etc-phpfpm-error_log.ini": .fake(.text, "error_log=VALET_HOME_PATH/php.log"),
            "~/.composer/vendor/laravel/valet/cli/stubs/php-memory-limits.ini": .fake(.text, "memory_limit=128M"),
            config + "php-memory-limits.ini": .fake(.text, "memory_limit=512M"),
            "/opt/homebrew/etc/php/8.4/php-fpm.d/valet-fpm.conf": .fake(.text)
        ])
        let container = prepare(filesystem)
        let switcher = InternalSwitcher(container)

        #expect(await switcher.ensureConfigurationFilesExist("8.4"))
        #expect(filesystem.files[config + "error_log.ini"]?.content?.contains("VALET_HOME_PATH") == false)
        #expect(filesystem.files[config + "php-memory-limits.ini"]?.content == "memory_limit=512M")
        #expect(await !switcher.ensureConfigurationFilesExist("8.4"))
        #expect(!filesystem.accesses.isEmpty)
        #expect(filesystem.accesses.allSatisfy { !$0.isMainThread && !$0.hasSwiftTask })
    }

    private func prepare(_ filesystem: RecordingFileSystem) -> Container {
        let container = Container()
        container.withFakeSystemContext(architecture: "arm64")
        container.bind(coreOnly: true, commandTracking: false)
        container.overrideFake(fileSystem: filesystem, commandTracking: false)
        filesystem.reset()
        return container
    }
}

// Record both boundaries: being off the main thread does not rule out blocking a Swift worker.
nonisolated private final class RecordingFileSystem: TestableFileSystem, @unchecked Sendable {
    struct Access: Sendable {
        let isMainThread: Bool
        let hasSwiftTask: Bool
    }

    private let recorded = OSAllocatedUnfairLock(initialState: [Access]())
    var accesses: [Access] { recorded.withLock { $0 } }

    func reset() { recorded.withLock { $0.removeAll() } }

    private func recordAccess() {
        let access = Access(
            isMainThread: Thread.isMainThread,
            hasSwiftTask: withUnsafeCurrentTask { $0 != nil }
        )
        recorded.withLock { $0.append(access) }
    }

    override func getStringFromFile(_ path: String) throws -> String {
        recordAccess()
        return try super.getStringFromFile(path)
    }

    override func getShallowContentsOfDirectory(_ path: String) throws -> [String] {
        recordAccess()
        return try super.getShallowContentsOfDirectory(path)
    }

    override func writeAtomicallyToFile(_ path: String, content: String) throws {
        recordAccess()
        try super.writeAtomicallyToFile(path, content: content)
    }

    override func remove(_ path: String) throws {
        recordAccess()
        try super.remove(path)
    }
}
