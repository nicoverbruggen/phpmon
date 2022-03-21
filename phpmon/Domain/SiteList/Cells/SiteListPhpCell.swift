//
//  SiteListPhpCell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/03/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Cocoa
import AppKit

class SiteListPhpCell: NSTableCellView, SiteListCellProtocol
{
    static let reusableName = "siteListPhpCell"
    
    var site: ValetSite? = nil
    
    @IBOutlet weak var buttonPhpVersion: NSButton!
    @IBOutlet weak var imageViewPhpVersionOK: NSImageView!
    
    func populateCell(with site: ValetSite) {
        self.site = site
        
        buttonPhpVersion.title = " PHP \(site.servingPhpVersion)"
        
        if site.isolatedPhpVersion != nil {
            imageViewPhpVersionOK.isHidden = false
            imageViewPhpVersionOK.image = NSImage(named: "Isolated")
        } else {
            imageViewPhpVersionOK.isHidden = (site.composerPhp == "???" || !site.composerPhpCompatibleWithLinked)
            imageViewPhpVersionOK.image = NSImage(named: "Checkmark")
        }
    }
    
    @IBAction func pressedPhpVersion(_ sender: Any) {
        guard let site = self.site else { return }
        
        let alert = NSAlert.init()
        alert.alertStyle = .informational
        
        var information = ""
        
        if (self.site?.isolatedPhpVersion != nil) {
            information += "alert.composer_php_isolated.desc".localized(
                self.site!.isolatedPhpVersion!.versionNumber.homebrewVersion,
                PhpEnv.phpInstall.version.short
            )
            information += "\n\n"
        }
        
        information += "alert.composer_php_requirement.type.\(site.composerPhpSource.rawValue)"
            .localized
        
        alert.messageText = "alert.composer_php_requirement.title"
            .localized("\(site.name).\(Valet.shared.config.tld)", site.composerPhp)
        alert.informativeText = information
        
        alert.addButton(withTitle: "site_link.close".localized)
        
        var mapIndex: Int = NSApplication.ModalResponse.alertSecondButtonReturn.rawValue
        var map: [Int: String] = [:]
        
        if site.isolatedPhpVersion == nil {
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
        } else {
            alert.beginSheetModal(for: App.shared.siteListWindowController!.window!) { response in
                //
            }
        }
    }
    
}
