//
//  SiteListCell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 03/12/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Cocoa
import AppKit

protocol SiteListCellProtocol {
    func populateCell(with site: ValetSite)
}

class SiteListCell: NSTableCellView
{
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    func populateCell(with site: ValetSite) {
    }
    
    /*
    @IBAction func pressedPhpVersion(_ sender: Any) {
        guard let site = self.site else { return }
        
        let alert = NSAlert.init()
        alert.alertStyle = .informational
        
        alert.messageText = "alert.composer_php_requirement.title"
            .localized("\(site.name).\(Valet.shared.config.tld)", site.composerPhp)
        alert.informativeText = "alert.composer_php_requirement.type.\(site.composerPhpSource.rawValue)"
            .localized
        
        alert.addButton(withTitle: "site_link.close".localized)
        
        var mapIndex: Int = NSApplication.ModalResponse.alertSecondButtonReturn.rawValue
        var map: [Int: String] = [:]
        
        // Determine which installed versions would be ideal to switch to,
        // but make sure to exclude the currently linked version
        PhpEnv.shared.validVersions(for: site.composerPhp).filter({ version in
            version.homebrewVersion != PhpEnv.phpInstall.version.short
        }).forEach { version in
            alert.addButton(withTitle: "site_link.switch_to_php".localized(version.homebrewVersion))
            map[mapIndex] = version.homebrewVersion
            mapIndex += 1
        }
        
        alert.beginSheetModal(for: App.shared.siteListWindowController!.window!) { response in
            if response.rawValue > NSApplication.ModalResponse.alertFirstButtonReturn.rawValue {
                if map.keys.contains(response.rawValue) {
                    let version = map[response.rawValue]!
                    Log.info("Pressed button to switch to \(version)")
                    MainMenu.shared.switchToPhpVersion(version)
                }
            }
        }
    }
    */
}
