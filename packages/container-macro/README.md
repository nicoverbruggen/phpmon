# ContainerMacro

A Swift macro for automatic container dependency injection in PHP Monitor.

## Usage

```swift
import ContainerMacro

@ContainerAccess
class MyClass {
    func doSomething() {
        shell.run("command")
        favorites.add(site)
        warningManager.evaluateWarnings()
    }
}
```

## What it generates

The `@ContainerAccess` macro automatically adds:
- A private `container: Container` property
- An `init(container:)` with default parameter `App.shared.container`
- Computed properties for each Container service you want to access

## Maintenance

When you add new services to `Container`, you must update the service list in:

**`Sources/ContainerMacroPlugin/ContainerAccessMacro.swift`** (lines 14-18):

```swift
let allContainerServices: [(name: String, type: String)] = [
    ("shell", "ShellProtocol"),
    ("favorites", "Favorites"),
    ("warningManager", "WarningManager"),
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
