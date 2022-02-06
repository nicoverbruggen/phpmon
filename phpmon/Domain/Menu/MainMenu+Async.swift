//
//  MainMenu+Async.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 06/02/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

extension MainMenu {
    
    // MARK: - Nicer callbacks
    
    enum AsyncBehaviour {
        case setsBusyUI
        case reloadsPhpInstallation
        case updatesMenuBarContents
        case broadcastServicesUpdate
    }
    
    /**
     Attempts asynchronous execution of a callback that may throw an Error.
     While the callback is being executed, the UI will be marked as busy.
     
     - Parameter execute: Callback of the work that needs to happen.
     - Parameter success: Callback that is fired when all was OK.
     - Parameter failure: Callback that is fired when an Error was thrown.
     - Parameter behaviours: Various behaviours that can be tweaked, but usually best left to the default.
     */
    func asyncExecution(
        _ execute: @escaping () throws -> Void,
        success: @escaping () -> Void = {},
        failure: @escaping (Error) -> Void = { _ in },
        behaviours: [AsyncBehaviour] = [
            .setsBusyUI,
            .reloadsPhpInstallation,
            .updatesMenuBarContents,
            .broadcastServicesUpdate
        ]
    ) {
        if behaviours.contains(.reloadsPhpInstallation) {
            PhpEnv.shared.isBusy = true
        }
        if behaviours.contains(.setsBusyUI) {
            setBusyImage()
        }
        DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
            var error: Error? = nil
            
            do { try execute() } catch let e { error = e }
            
            if behaviours.contains(.setsBusyUI) {
                PhpEnv.shared.isBusy = false
            }
            
            DispatchQueue.main.async { [self] in
                if behaviours.contains(.reloadsPhpInstallation) {
                    PhpEnv.shared.currentInstall = ActivePhpInstallation()
                }
                
                if behaviours.contains(.updatesMenuBarContents) {
                    // Refresh the entire menu bar menu's contents
                    updatePhpVersionInStatusBar()
                } else {
                    // We do still need to refresh the icon based on the busy state
                    if behaviours.contains(.setsBusyUI) {
                        refreshIcon()
                    }
                }
                
                if behaviours.contains(.broadcastServicesUpdate) {
                    NotificationCenter.default.post(name: Events.ServicesUpdated, object: nil)
                }
                
                error == nil ? success() : failure(error!)
            }
        }
    }
    
    func asyncWithBusyUI(
        _ execute: @escaping () throws -> Void,
        completion: @escaping () -> Void = {}
    ) {
        asyncExecution({
            try! execute()
        }, success: {
            completion()
        }, behaviours: [.setsBusyUI])
    }
    
}
