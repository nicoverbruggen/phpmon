/// Automatically adds container dependency injection to a class.
///
/// This macro generates:
/// - A public `container` property
/// - An `init(container:)` with a default parameter of `App.shared.container` (only if no init exists)
/// - Computed properties for all Container services
///
/// Usage:
/// ```swift
/// import ContainerMacro
///
/// @ContainerAccess
/// class MyClass {
///     func doSomething() {
///         shell.run("command")
///         favorites.add(site)
///         warningManager.evaluateWarnings()
///     }
/// }
/// ```
@attached(member, names: named(container), named(init(container:)), arbitrary)
public macro ContainerAccess() = #externalMacro(
    module: "ContainerMacroPlugin",
    type: "ContainerAccessMacro"
)
