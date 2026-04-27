//
//  PhpHelper+Templates.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 27/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

extension PhpHelper {

    // TODO: refactor to a struct/enum and add support for bash?
    // Ideally, I'd want different "drivers" for each shell type, which then writes the helpers
    // this removes the need to check if "fish" is the shell and such things
    //
    // Pseudocode:
    // ```
    // let generator = HelperFileGenerator(shell: detected)
    // generator.generate(container, args)
    // ```
    // I think version, dotless args can be a tuple: (version, dotlessVersion) perhaps?
    //
    //
    // or alternatively, we modify the PATH a different way (would that even be possible?)

    // MARK: - General strings

    private static func unavailableMessage(for version: String) -> String {
        return "Error: PHP \(version) is not installed. (You can install it via PHP Monitor to update this helper file.)"
    }

    // MARK: - zsh scripts

    struct Zsh {
        static func installedScript(
            _ path: String,
            _ version: String,
            _ dotless: String
        ) -> String {
            return """
                #!/bin/zsh
                # \(keyPhrase)
                # It reflects the location of PHP \(version)'s binaries on your system.
                # Usage: . pm\(dotless)
                [[ $ZSH_EVAL_CONTEXT =~ :file$ ]] \\
                    && echo "PHP Monitor has enabled this terminal to use PHP \(version)." \\
                    || echo "You must run '. pm\(dotless)' (or 'source pm\(dotless)') instead!";
                export PATH=\(path):$PATH
                """
        }

        static func unavailableScript(_ version: String) -> String {
            let message = unavailableMessage(for: version)

            return """
                #!/bin/zsh
                # \(keyPhrase)
                # This helper reflects that PHP \(version) is currently not installed.
                echo "\(message)"
                return 1 2>/dev/null || exit 1
                """
        }
    }

    // MARK: - Fish scripts

    struct Fish {
        static func installedScript(
            _ container: Container,
            _ path: String,
            _ version: String,
            _ dotless: String
        ) -> String {
            return """
                #!\(container.paths.binPath)/fish
                # \(keyPhrase)
                # It reflects the location of PHP \(version)'s binaries on your system.
                # Usage: . pm\(dotless)
                echo "PHP Monitor has enabled this terminal to use PHP \(version)."; \\
                set -x PATH \(path) $PATH
                """
        }

        static func unavailableScript(_ container: Container, _ version: String) -> String {
            let message = unavailableMessage(for: version)

            return """
                #!\(container.paths.binPath)/fish
                # \(keyPhrase)
                # This helper reflects that PHP \(version) is currently not installed.
                echo "\(message)"
                return 1
                """
        }
    }
}
