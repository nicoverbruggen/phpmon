# ContainerMacro

A Swift macro for automatic container dependency injection in PHP Monitor.

## Usage

```swift
import ContainerMacro

@ContainerAccess
class MyClass {
    func doSomething() {
        container.shell.run("command")
        container.favorites.add(site)
    }
}
```

## What it generates

The `@ContainerAccess` macro automatically adds:
- A private `container: Container` property
- An `init(_ container:)` initializer
- Computed properties for each Container service you want to access

## Maintenance

When you add new services to `Container`, you must update the service list in:

**`Sources/ContainerMacroPlugin/ContainerAccessMacro.swift`** (lines 14-18):

```swift
let allContainerServices: [(name: String, type: String)] = [
    ("shell", "ShellProtocol"),
    // Add your new service here:
    // ("myNewService", "MyServiceType"),
]
```

## Testing

Run tests with:
```bash
cd packages/container-macro
swift test
```

## Integration

The package is added as a local Swift Package in Xcode:
- File → Add Package Dependencies → Add Local...
- Select `packages/container-macro`
