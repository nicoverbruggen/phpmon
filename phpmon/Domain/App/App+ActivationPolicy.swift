//
//  App+ActivationPolicy.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 05/12/2021.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Cocoa
import Foundation

extension App {

    // MARK: - Application State

    /**
     Registers a window as currently open.
     */
    public func register(window name: String) {
        if !openWindows.contains(name) {
            openWindows.append(name)
        }
        updateActivationPolicy()
    }

    /**
     Removes a window, assuming it was closed.
     */
    public func remove(window name: String) {
        openWindows.removeAll { window in
            window == name
        }
        updateActivationPolicy()
    }

    /**
     If there are any open windows, the app will be a regular app.
     If there are no windows open, the app will be an accessory (toolbar) app.
     */
    public func updateActivationPolicy() {
        NSApp.setActivationPolicy(!openWindows.isEmpty ? .regular : .accessory)
    }

}
