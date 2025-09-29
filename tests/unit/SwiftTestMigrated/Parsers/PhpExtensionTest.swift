//
//  ExtensionParserTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 13/02/2021.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Testing
import Foundation

struct PhpExtensionTest {
    static var phpIniFileUrl: URL {
        TestBundle.url(forResource: "php", withExtension: "ini")!
    }

    @Test func can_load_extension() throws {
        let extensions = PhpExtension.from(filePath: Self.phpIniFileUrl.path)

        #expect(!extensions.isEmpty)
    }

    @Test func extension_name_is_correct() throws {
        let extensions = PhpExtension.from(filePath: Self.phpIniFileUrl.path)

        let extensionNames = extensions.map { (ext) -> String in
            return ext.name
        }

        // These 6 should be found
        #expect(extensionNames.contains("xdebug"))
        #expect(extensionNames.contains("imagick"))
        #expect(extensionNames.contains("sodium-next"))
        #expect(extensionNames.contains("opcache"))
        #expect(extensionNames.contains("yaml"))
        #expect(extensionNames.contains("custom"))

        #expect(extensionNames.contains("fake") == false)
        #expect(extensionNames.contains("nice") == false)
    }

    @Test func extension_status_is_correct() throws {
        let extensions = PhpExtension.from(filePath: Self.phpIniFileUrl.path)

        // xdebug should be enabled
        #expect(extensions[0].enabled == true)

        // imagick should be disabled
        #expect(extensions[1].enabled == false)
    }

    @Test func toggle_works_as_expected() async throws {
        let destination = Utility.copyToTemporaryFile(resourceName: "php", fileExtension: "ini")!
        let extensions = PhpExtension.from(filePath: destination.path)
        #expect(extensions.count == 6)

        // Try to disable xdebug (should be detected first)!
        let xdebug = extensions.first!
        #expect(xdebug.name == "xdebug")
        #expect(xdebug.enabled == true)
        await xdebug.toggle()
        #expect(xdebug.enabled == false)

        // Check if the file contains the appropriate data
        let file = try! String(contentsOf: destination, encoding: .utf8)
        #expect(file.contains("; zend_extension=\"xdebug.so\""))

        // Make sure if we load the data again, it's disabled
        #expect(PhpExtension.from(filePath: destination.path).first!.enabled == false)
    }
}
