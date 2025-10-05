/// Automatically adds container dependency injection to a class.
///
/// This macro generates:
/// - A private `container` property
/// - An `init(container:)` with a default parameter of `App.shared.container`
/// - Computed properties for Container services
///
/// Usage:
/// ```swift
/// import NVContainer
///
/// // Expose specific services:
/// @ContainerAccess(["shell", "favorites"])
/// class MyClass {
///     func doSomething() {
///         shell.run("command")
///         favorites.add(site)
///     }
/// }
///
/// // Or expose ALL Container services by omitting the array:
/// @ContainerAccess
/// class AnotherClass {
///     func doSomething() {
///         shell.run("command")
///         favorites.add(site)
///         warningManager.evaluateWarnings()
///     }
/// }
/// ```
///
/// - Parameter services: Optional array of service names to expose. If omitted, all Container services are exposed.
@attached(member, names: named(container), named(init(container:)), arbitrary)
public macro ContainerAccess(_ services: [String] = []) = #externalMacro(
    module: "NVContainerMacros",
    type: "ContainerAccessMacro"
)
