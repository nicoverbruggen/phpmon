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
            ("favorites", "Favorites"),
            ("warningManager", "WarningManager")
        ]

        // Extract the service names from the macro arguments (if provided)
        var requestedServices: [String]? = nil
        if let argumentList = node.arguments?.as(LabeledExprListSyntax.self),
           let firstArgument = argumentList.first,
           let arrayExpr = firstArgument.expression.as(ArrayExprSyntax.self) {
            requestedServices = arrayExpr.elements.compactMap { element -> String? in
                guard let stringLiteral = element.expression.as(StringLiteralExprSyntax.self),
                      let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) else {
                    return nil
                }
                return segment.content.text
            }
        }

        // Determine which services to expose
        let servicesToExpose: [(name: String, type: String)]
        if let requested = requestedServices, !requested.isEmpty {
            // Only expose the requested services
            servicesToExpose = allContainerServices.filter { requested.contains($0.name) }
        } else {
            // No arguments provided - expose ALL services
            servicesToExpose = allContainerServices
        }

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
            private let container: Container
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
        for service in servicesToExpose {
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
struct NVContainerMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ContainerAccessMacro.self,
    ]
}
