//
//  WindowCoordinator.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 23/02/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Cocoa

typealias PreferencesWC = PreferencesWindowController
typealias DomainListWC = DomainListWindowController
typealias OnboardingWC = OnboardingWindowController
typealias PhpConfigManagerWC = PhpConfigManagerWindowController
typealias PhpDoctorWC = PhpDoctorWindowController
typealias PhpVersionManagerWC = PhpVersionManagerWindowController
typealias PhpExtensionManagerWC = PhpExtensionManagerWindowController

let WindowManager = WindowCoordinator.shared

final class WindowCoordinator {
    static let shared = WindowCoordinator()

    private var controllers: [ObjectIdentifier: NSWindowController] = [:]

    private init() {}

    func setController<T: NSWindowController>(_ controller: T) {
        controllers[ObjectIdentifier(T.self)] = controller
    }

    func hasController<T: NSWindowController>(for type: T.Type) -> Bool {
        return controllers[ObjectIdentifier(T.self)] != nil
    }

    func controller<T: NSWindowController>(of type: T.Type) -> T? {
        return controllers[ObjectIdentifier(T.self)] as? T
    }

    func window<T: NSWindowController>(for type: T.Type) -> NSWindow? {
        return controllers[ObjectIdentifier(T.self)]?.window
    }

    func withWindow<T: NSWindowController>(for type: T.Type, _ handler: (NSWindow) -> Void) {
        guard let window = window(for: type) else { return }
        handler(window)
    }

    @discardableResult
    func show<T: NSWindowController>(_ type: T.Type) -> T? {
        guard let controller = controller(of: type) else { return nil }
        controller.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
        controller.window?.orderFrontRegardless()
        return controller
    }

    func close<T: NSWindowController>(_ type: T.Type) {
        controllers[ObjectIdentifier(T.self)]?.close()
        controllers[ObjectIdentifier(T.self)] = nil
    }

    func closeAll(excluding types: [NSWindowController.Type] = []) {
        let excluded = Set(types.map { ObjectIdentifier($0) })

        controllers.keys
            .filter { !excluded.contains($0) }
            .forEach { key in
                controllers[key]?.close()
                controllers[key] = nil
            }
    }
}
