import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ContainerAccessMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Map of ALL Container properties to their types
        // This should be kept in sync with the Container class
        let allContainerServices: [(name: String, type: String)] = [
            ("shell", "ShellProtocol"),
            ("filesystem", "FileSystemProtocol"),
            ("command", "CommandProtocol"),
            ("paths", "Paths"),
            ("phpEnvs", "PhpEnvironments"),
            ("favorites", "Favorites"),
            ("warningManager", "WarningManager")
        ]

        // Check if the class already has an initializer
        let hasExistingInit = declaration.memberBlock.members.contains { member in
            if let initDecl = member.decl.as(InitializerDeclSyntax.self) {
                return true
            }
            return false
        }

        var members: [DeclSyntax] = []

        // Add the container property
        members.append(
            """
            public let container: Container
            """
        )

        // Only add the initializer if one doesn't already exist
        if !hasExistingInit {
            members.append(
                """
                init(container: Container = App.shared.container) {
                    self.container = container
                }
                """
            )
        }

        // Add computed properties for each service
        for service in allContainerServices {
            members.append(
                """
                private var \(raw: service.name): \(raw: service.type) {
                    return container.\(raw: service.name)
                }
                """
            )
        }

        return members
    }
}

@main
struct ContainerMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ContainerAccessMacro.self,
    ]
}
