# Agent instructions

Read this file before working, then read the instructions and source relevant to the area you will change. This file covers architecture and project-wide conventions. Follow links for implementation details.

## Keep this file current

Review this file with every code change. Update affected guidance and links in the same change, without waiting for a separate request. Verify updates against the source. If the guidance remains accurate, leave it unchanged.

Keep notes broad and durable. Dependency injection and container lifecycle deserve explicit detail here; individual features, commands, compatibility workarounds and test cases belong in their implementation or dedicated documentation. Do not add task history or a running changelog.

## Architecture and navigation

PHP Monitor is a native macOS menu bar app built with SwiftUI and AppKit. It manages a local PHP environment through external tools and supports operation with or without Laravel Valet. Preserve the existing platform support and integration boundaries when changing a feature.

| Area | Start here |
| --- | --- |
| App lifecycle and shared state | [App.swift](phpmon/Domain/App/App.swift) |
| Dependency injection and service ownership | [Container.swift](phpmon/Container/Container.swift) |
| System identity and paths | [SystemContext.swift](phpmon/Container/SystemContext.swift), [Paths.swift](phpmon/Common/Core/Paths.swift) |
| Feature orchestration | [Modules](phpmon/Modules/), [Domain integrations](phpmon/Domain/Integrations/) |
| External command definitions | [CommandCatalog.swift](phpmon/Common/Core/CommandCatalog.swift) |
| Privileged operations and their test substitutes | [PrivilegedCommandRunner.swift](phpmon/Domain/PrivilegedCommand/PrivilegedCommandRunner.swift) |
| Code shared with the updater | [phpmon-shared](phpmon-shared/), [updater entry point](phpmon-updater/main.swift) |
| Target membership, dependencies and compiler settings | [Xcode project](PHP%20Monitor.xcodeproj/project.pbxproj) |

Keep views, feature orchestration and system access in their existing layers. Read nearby implementations before introducing a new abstraction. Shared source can compile in multiple targets, so check target membership and compiler settings when changing it.

## Dependency injection and the container

Use the injected `Container` for shell, filesystem, command, web API, preferences and integration dependencies. Pass the same container through collaborating objects. Do not reach back into `App.shared.container` from code that already has an injected container.

Use `SystemContext` and `Paths` for machine-dependent values instead of hardcoding a Homebrew prefix, username or architecture. Set fake system context before binding a container.

A new container must be bound before its services are used. Call `bind` only once and preserve the dependency order inside it. Services that depend on other services must be initialized after them. Container bindings are established during setup; do not replace them while background work can still hold references to the old services.

Keep real and fake service setup consistent. Read [Container+Real.swift](phpmon/Container/Container+Real.swift) and [Container+Fake.swift](phpmon/Container/Container+Fake.swift) when adding or changing a dependency. Extend the existing protocols and test doubles so a feature can run without touching the host environment. Preserve the boundary that lets privileged operations use a substitute approval runner in tests.

Tests should own their containers and model instances. Do not replace global app dependencies or use shared host state as a fixture. When a dependency contract changes, update its real implementation, fake implementation and affected fixtures together.

## Swift 6 and concurrency

The project uses Swift 6 with default main-actor isolation and strict concurrency checking. Some targets use different language settings; consult the [Xcode project](PHP%20Monitor.xcodeproj/project.pbxproj) and [developer guide](DEVELOPER.md) before changing them.

Keep UI and app-model state on the main actor. Make isolation boundaries explicit where services need to run elsewhere. Do not assume that `async` or `nonisolated` moves work to a background thread. Blocking operations must also stay off Swift's cooperative thread pool; `@concurrent` and `Task.detached` do not provide that guarantee. Use the [blocking-work helper](phpmon/Common/Helpers/RunBlocking.swift), and read its contract for captures, cancellation and task-local state.

Pass data safely between isolation domains. Give mutable state a clear owner and use the existing actor or synchronization patterns when sharing it. An unchecked conformance must have a documented safety invariant; it does not provide synchronization by itself. Preserve cancellation, ordering and lifetime guarantees when changing asynchronous flows.

Treat concurrency diagnostics as design feedback. Do not weaken compiler checks or add unchecked annotations merely to silence warnings. Test the behavior of affected isolation boundaries and shared state.

## Development and validation

Use [DEVELOPER.md](DEVELOPER.md) for build and test instructions, [CI](.github/workflows/tests.yml) for automated commands, and [.swiftlint.yml](.swiftlint.yml) for lint rules. Follow nearby tests and keep validation proportional to the change. Check configuration and source if documentation appears inconsistent, and report the disagreement.

Always get fresh confirmation before running UI tests that control the desktop. Use test doubles for external integrations rather than changing the host environment to make tests pass.

Follow [scripts/README.md](scripts/README.md) for localization and development scripts. Keep user-facing guidance in [README.md](README.md), developer workflows in [DEVELOPER.md](DEVELOPER.md), and architectural guidance here. Read the [contribution guidelines](.github/contributing.md) and [PR template](.github/pull_request_template.md) when preparing a contribution.

Preserve unrelated changes and follow the maintainer's permission rules. Change Git state only when explicitly instructed. Before finishing, review the diff, check companion fixtures and documentation, and perform the maintenance review above. Report what changed, what was verified and what was not run.
