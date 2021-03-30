//
//  PrefsVC.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 30/03/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Cocoa

class PrefsVC: NSViewController {
    
    @IBOutlet weak var buttonDynamicIcon: NSButton!
    @IBOutlet weak var labelDynamicIcon: NSTextField!
    @IBOutlet weak var buttonClose: NSButton!
    
    public static func show(delegate: NSWindowDelegate? = nil) {
        if (App.shared.windowController == nil) {
            let vc = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "preferences") as! PrefsVC
            let window = NSWindow(contentViewController: vc)
            window.title = "prefs.title".localized
            window.delegate = delegate
            window.styleMask = [.titled, .closable]
            App.shared.windowController = NSWindowController(window: window)
        }
        App.shared.windowController!.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @IBAction func toggledDynamicIcon(_ sender: Any) {
        Preferences.update(.shouldDisplayDynamicIcon, value: buttonDynamicIcon.state == .on)
        MainMenu.shared.refreshIcon()
    }
    
    override func viewWillAppear() {
        buttonDynamicIcon.title = "prefs.dynamic_icon_title".localized
        labelDynamicIcon.stringValue = "prefs.dynamic_icon_desc".localized
        buttonClose.title = "prefs.close".localized
        
        let prefs = Preferences.preferences
        self.buttonDynamicIcon.state = (prefs[.shouldDisplayDynamicIcon] == true) ? .on : .off
    }
    
    @IBAction func pressed(_ sender: Any) {
        self.view.window?.windowController?.close()
    }
    
    deinit {
        print("VC deallocated")
    }
}
