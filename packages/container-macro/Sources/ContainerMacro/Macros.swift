/// Automatically adds container dependency injection to a class.
///
/// This macro generates:
/// - A public `container` property
/// - An `init(_ container:)` initializer
/// - Computed properties for all Container services
///
/// Usage:
/// ```swift
/// import ContainerMacro
///
/// @ContainerAccess
/// class MyClass {
///     func doSomething() {
///         container.shell.run("command")
///         container.favorites.add(site)
///     }
/// }
/// ```
@attached(member, names: named(container), named(init(container:)), arbitrary)
public macro ContainerAccess() = #externalMacro(
    module: "ContainerMacroPlugin",
    type: "ContainerAccessMacro"
)
