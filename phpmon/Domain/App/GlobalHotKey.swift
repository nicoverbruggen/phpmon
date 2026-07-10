//
//  GlobalHotKey.swift
//  PHP Monitor
//
//  A small, self-contained, Swift 6-native replacement for the previously
//  vendored soffes/HotKey library. It registers a system-wide hot key via
//  Carbon's `RegisterEventHotKey` — the only API that provides a global
//  shortcut without an Accessibility prompt — and invokes a main-actor handler
//  when the combination is pressed.
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import AppKit
import Carbon

// MARK: - KeyCombo

/// A key + modifier combination, expressed in the Carbon terms the hot key API expects.
struct KeyCombo: Equatable, Sendable {
    var carbonKeyCode: UInt32
    var carbonModifiers: UInt32

    init(carbonKeyCode: UInt32, carbonModifiers: UInt32 = 0) {
        self.carbonKeyCode = carbonKeyCode
        self.carbonModifiers = carbonModifiers
    }
}

// MARK: - HotKey

/// A single system-wide hot key. It registers itself on `init` and tears itself
/// down on `deinit`; toggle `isPaused` to temporarily disable it (e.g. while a
/// blocking operation is in progress).
///
/// Intentionally *unannotated* so it adopts the module's default actor isolation —
/// nonisolated under the legacy default, and `@MainActor` once the app moves to
/// main-actor-by-default — matching whatever isolation `App` (which owns it) has.
final class HotKey {
    let keyCombo: KeyCombo
    var keyDownHandler: (() -> Void)?

    var isPaused: Bool = false {
        didSet {
            guard isPaused != oldValue else { return }
            if isPaused {
                GlobalHotKeyCenter.shared.unregister(self)
            } else {
                GlobalHotKeyCenter.shared.register(self)
            }
        }
    }

    /// The Carbon hot key reference. Retained so it can be released in `deinit`,
    /// which is `nonisolated`. Only ever mutated on the main actor (in the center's
    /// register/unregister); the object is only deallocated on the main thread.
    nonisolated(unsafe) fileprivate var carbonHotKey: EventHotKeyRef?

    /// The id this hot key was registered under (0 until it is first registered).
    fileprivate var carbonID: UInt32 = 0

    init(keyCombo: KeyCombo, keyDownHandler: (() -> Void)? = nil) {
        self.keyCombo = keyCombo
        self.keyDownHandler = keyDownHandler
        GlobalHotKeyCenter.shared.register(self)
    }

    deinit {
        // `deinit` is nonisolated; `UnregisterEventHotKey` is a plain C call and is
        // safe here. The center only holds a weak reference, so its bookkeeping entry
        // falls away on its own.
        if let carbonHotKey {
            UnregisterEventHotKey(carbonHotKey)
        }
    }
}

// MARK: - GlobalHotKeyCenter

/// Owns the one shared Carbon event handler and the registry of active hot keys.
/// Unannotated, so it inherits the module's default isolation (see `HotKey`).
final class GlobalHotKeyCenter {
    static let shared = GlobalHotKeyCenter()

    private init() {}

    private struct Registration {
        let carbonHotKey: EventHotKeyRef
        weak var hotKey: HotKey?
    }

    private var registrations: [UInt32: Registration] = [:]
    private var nextID: UInt32 = 0
    private var eventHandler: EventHandlerRef?

    func register(_ hotKey: HotKey) {
        installEventHandlerIfNeeded()

        // Assign a stable id the first time this hot key is registered.
        if hotKey.carbonID == 0 {
            nextID += 1
            hotKey.carbonID = nextID
        }

        var carbonRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: phpMonHotKeySignature, id: hotKey.carbonID)
        let status = RegisterEventHotKey(
            hotKey.keyCombo.carbonKeyCode,
            hotKey.keyCombo.carbonModifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &carbonRef
        )

        guard status == noErr, let carbonRef else {
            Log.err("Failed to register global hot key (OSStatus \(status)).")
            return
        }

        hotKey.carbonHotKey = carbonRef
        registrations[hotKey.carbonID] = Registration(carbonHotKey: carbonRef, hotKey: hotKey)
    }

    func unregister(_ hotKey: HotKey) {
        if let carbonRef = hotKey.carbonHotKey {
            UnregisterEventHotKey(carbonRef)
        }
        hotKey.carbonHotKey = nil
        registrations.removeValue(forKey: hotKey.carbonID)
    }

    /// Called (on the main thread) by the Carbon event handler when one of our hot
    /// keys fires. Ignores hot keys that were released or are currently paused.
    fileprivate func handle(id: UInt32) {
        guard let hotKey = registrations[id]?.hotKey, !hotKey.isPaused else { return }
        hotKey.keyDownHandler?()
    }

    private func installEventHandlerIfNeeded() {
        guard eventHandler == nil else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetEventDispatcherTarget(),
            globalHotKeyEventHandler,
            1,
            &eventType,
            nil,
            &eventHandler
        )
    }
}

// MARK: - Carbon C callback

/// Four-char code ("PHPm") identifying our hot keys, so we ignore events for others.
private nonisolated let phpMonHotKeySignature: FourCharCode = 0x5048_506D

/// The Carbon event handler. It is a top-level `nonisolated` function so a
/// `@convention(c)` pointer can be formed from it. Carbon delivers hot-key events on
/// the main thread, so it is safe to assume main-actor isolation to reach the
/// (main-actor-isolated) registry.
private nonisolated func globalHotKeyEventHandler(
    _ handlerCall: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event else {
        return OSStatus(eventNotHandledErr)
    }

    var hotKeyID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        UInt32(kEventParamDirectObject),
        UInt32(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )

    guard status == noErr, hotKeyID.signature == phpMonHotKeySignature else {
        return OSStatus(eventNotHandledErr)
    }

    MainActor.assumeIsolated {
        GlobalHotKeyCenter.shared.handle(id: hotKeyID.id)
    }

    return noErr
}

// MARK: - Modifier flag conversion

extension NSEvent.ModifierFlags {
    /// The Carbon modifier mask equivalent of these Cocoa modifier flags.
    var carbonFlags: UInt32 {
        var flags: UInt32 = 0
        if contains(.command) { flags |= UInt32(cmdKey) }
        if contains(.option) { flags |= UInt32(optionKey) }
        if contains(.control) { flags |= UInt32(controlKey) }
        if contains(.shift) { flags |= UInt32(shiftKey) }
        return flags
    }
}
