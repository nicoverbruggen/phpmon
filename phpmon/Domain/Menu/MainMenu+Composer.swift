//
//  MainMenu+Composer.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 08/02/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

extension MainMenu {
    
    /**
     Updates the global dependencies and runs the completion callback when done.
     This method should probably be broken up into several smaller methods at some point.
     */
    func updateGlobalDependencies(notify: Bool, completion: @escaping (Bool) -> Void) {
        if !Shell.fileExists("/usr/local/bin/composer") {
            Alert.notify(
                message: "alert.composer_missing.title".localized,
                info: "alert.composer_missing.info".localized
            )
            return
        }
        
        PhpEnv.shared.isBusy = true
        setBusyImage()
        self.rebuild()
        
        let noLongerBusy = {
            PhpEnv.shared.isBusy = false
            DispatchQueue.main.async { [self] in
                self.updatePhpVersionInStatusBar()
                self.rebuild()
            }
        }
        
        var window: ProgressWindowController? = ProgressWindowController.display(
            title: "alert.composer_progress.title".localized,
            description: "alert.composer_progress.info".localized
        )
        window?.setType(info: true)
        
        DispatchQueue.global(qos: .userInitiated).async {
            let task = Shell.user.createTask(
                for: "/usr/local/bin/composer global update", requiresPath: true
            )
            
            DispatchQueue.main.async {
                window?.addToConsole("/usr/local/bin/composer global update\n")
            }
            
            Shell.captureOutput(
                task,
                didReceiveStdOutData: { string in
                    DispatchQueue.main.async {
                        window?.addToConsole(string)
                    }
                    Log.perf("\(string.trimmingCharacters(in: .newlines))")
                },
                didReceiveStdErrData: { string in
                    DispatchQueue.main.async {
                        window?.addToConsole(string)
                    }
                    Log.perf("\(string.trimmingCharacters(in: .newlines))")
                }
            )
            
            task.launch()
            task.waitUntilExit()
            Shell.haltCapturingOutput(task)
            
            DispatchQueue.main.async {
                if task.terminationStatus <= 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        window?.close()
                        if (notify) {
                            LocalNotification.send(
                                title: "alert.composer_success.title".localized,
                                subtitle: "alert.composer_success.info".localized
                            )
                        }
                        window = nil
                        noLongerBusy()
                        completion(true)
                    }
                } else {
                    window?.setType(info: false)
                    window?.progressView?.labelTitle.stringValue = "alert.composer_failure.title".localized
                    window?.progressView?.labelDescription.stringValue = "alert.composer_failure.info".localized
                    window = nil
                    noLongerBusy()
                    completion(false)
                }
            }
        }
    }
}
