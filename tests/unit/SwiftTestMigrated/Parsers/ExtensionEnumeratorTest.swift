//
//  ExtensionEnumeratorTest.swift
//  Unit Tests
//
//  Created by Nico Verbruggen on 30/10/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Testing
import Foundation

struct ExtensionEnumeratorTest {
    init() async throws {
        ActiveFileSystem.useTestable([
            "\(Paths.tapPath)/shivammathur/homebrew-extensions/Formula/xdebug@8.1.rb": .fake(.text, "<test>"),
            "\(Paths.tapPath)/shivammathur/homebrew-extensions/Formula/xdebug@8.2.rb": .fake(.text, "<test>"),
            "\(Paths.tapPath)/shivammathur/homebrew-extensions/Formula/xdebug@8.3.rb": .fake(.text, "<test>"),
            "\(Paths.tapPath)/shivammathur/homebrew-extensions/Formula/xdebug@8.4.rb": .fake(.text, "<test>")
        ])
    }

    @Test func can_read_formulae() throws {
        let directory = "\(Paths.tapPath)/shivammathur/homebrew-extensions/Formula"
        let files = try FileSystem.getShallowContentsOfDirectory(directory)

        #expect(Set(files) == Set(["xdebug@8.1.rb", "xdebug@8.2.rb", "xdebug@8.3.rb", "xdebug@8.4.rb"]))
    }

    @Test func can_parse_formulae_based_on_syntax() throws {
        let formulae = BrewTapFormulae.from(tap: "shivammathur/homebrew-extensions")

        #expect(formulae["8.1"] == [BrewPhpExtension(path: "/", name: "xdebug", phpVersion: "8.1")])
        #expect(formulae["8.2"] == [BrewPhpExtension(path: "/", name: "xdebug", phpVersion: "8.2")])
        #expect(formulae["8.3"] == [BrewPhpExtension(path: "/", name: "xdebug", phpVersion: "8.3")])
        #expect(formulae["8.4"] == [BrewPhpExtension(path: "/", name: "xdebug", phpVersion: "8.4")])
    }
}
