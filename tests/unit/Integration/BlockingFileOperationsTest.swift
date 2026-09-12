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
    @Test func extension_discovery_leaves_the_main_thread() async {
        let filesystem = RecordingFileSystem(files: [
            "/opt/homebrew/Library/Taps/shivammathur/homebrew-extensions/Formula/redis@8.4.rb": .fake(.text, "depends_on \"shivammathur/extensions/igbinary@8.4\"")
        ])
        let container = prepare(filesystem)

        let formulae = await BrewTapFormulae.from(container, tap: "shivammathur/homebrew-extensions")

        #expect(formulae["8.4"]?.map(\.name) == ["redis"])
        #expect(formulae["8.4"]?.first?.extensionDependencies == ["igbinary"])
        #expect(!filesystem.accesses.isEmpty)
        #expect(filesystem.accesses.allSatisfy { !$0 })
    }

    @Test func existing_zshrc_is_read_off_the_main_thread_without_appending_duplicate_paths() async {
        let filesystem = RecordingFileSystem(files: [
            "~/.zshrc": .fake(.text, "export PATH=/opt/homebrew/bin:$PATH")
        ])
        let container = prepare(filesystem)

        #expect(await ZshRunCommand(container).addHomebrewBinPath())
        #expect(!filesystem.accesses.isEmpty)
        #expect(filesystem.accesses.allSatisfy { !$0 })
    }

    @Test func missing_valet_files_are_repaired_off_the_main_thread_without_overwriting_existing_configuration() async {
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
        #expect(filesystem.accesses.allSatisfy { !$0 })
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

// Record the thread at the same filesystem boundary that traps in Debug builds.
nonisolated private final class RecordingFileSystem: TestableFileSystem, @unchecked Sendable {
    private let recorded = OSAllocatedUnfairLock(initialState: [Bool]())
    var accesses: [Bool] { recorded.withLock { $0 } }

    func reset() { recorded.withLock { $0.removeAll() } }

    override func getStringFromFile(_ path: String) throws -> String {
        recorded.withLock { $0.append(Thread.isMainThread) }
        return try super.getStringFromFile(path)
    }

    override func getShallowContentsOfDirectory(_ path: String) throws -> [String] {
        recorded.withLock { $0.append(Thread.isMainThread) }
        return try super.getShallowContentsOfDirectory(path)
    }

    override func writeAtomicallyToFile(_ path: String, content: String) throws {
        recorded.withLock { $0.append(Thread.isMainThread) }
        try super.writeAtomicallyToFile(path, content: content)
    }
}
