import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(ContainerMacroPlugin)
import ContainerMacroPlugin

final class ContainerAccessMacroTests: XCTestCase {
    let testMacros: [String: Macro.Type] = [
        "ContainerAccess": ContainerAccessMacro.self,
    ]

    func testContainerAccessWithSpecificServices() throws {
        assertMacroExpansion(
            """
            @ContainerAccess(["shell"])
            class InternalSwitcher {
                func doSomething() {
                    print("Hello")
                }
            }
            """,
            expandedSource: """
            class InternalSwitcher {
                func doSomething() {
                    print("Hello")
                }

                private let container: Container

                init(container: Container = App.shared.container) {
                    self.container = container
                }

                private var shell: ShellProtocol {
                    return container.shell
                }
            }
            """,
            macros: testMacros
        )
    }

    func testContainerAccessWithMultipleServices() throws {
        assertMacroExpansion(
            """
            @ContainerAccess(["shell", "favorites"])
            class MyClass {
            }
            """,
            expandedSource: """
            class MyClass {

                private let container: Container

                init(container: Container = App.shared.container) {
                    self.container = container
                }

                private var shell: ShellProtocol {
                    return container.shell
                }

                private var favorites: Favorites {
                    return container.favorites
                }
            }
            """,
            macros: testMacros
        )
    }

    func testContainerAccessWithAllServices() throws {
        assertMacroExpansion(
            """
            @ContainerAccess
            class MyClass {
            }
            """,
            expandedSource: """
            class MyClass {

                private let container: Container

                init(container: Container = App.shared.container) {
                    self.container = container
                }

                private var shell: ShellProtocol {
                    return container.shell
                }

                private var favorites: Favorites {
                    return container.favorites
                }

                private var warningManager: WarningManager {
                    return container.warningManager
                }
            }
            """,
            macros: testMacros
        )
    }
}
#endif
