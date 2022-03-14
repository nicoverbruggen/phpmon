//
//  SiteListCell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 03/12/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Cocoa
import AppKit

class SiteListCell: NSTableCellView
{
    var site: ValetSite? = nil
    
    @IBOutlet weak var labelSiteName: NSTextField!
    @IBOutlet weak var labelPathName: NSTextField!
    @IBOutlet weak var labelDriverType: NSTextField!
    
    @IBOutlet weak var imageViewLock: NSImageView!
    @IBOutlet weak var imageViewType: NSImageView!
    
    @IBOutlet weak var labelDriver: NSTextField!
    
    @IBOutlet weak var buttonPhpVersion: NSButton!
    @IBOutlet weak var imageViewPhpVersionOK: NSImageView!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    func populateCell(with site: ValetSite) {
        self.site = site
        
        // Make sure to show the TLD
        labelSiteName.stringValue = "\(site.name).\(Valet.shared.config.tld)"
        
        // Show the absolute path, except make sure to replace the /Users/username segment with ~ for readability
        labelPathName.stringValue = site.absolutePathRelative
        
        // If the `aliasPath` is nil, we're dealing with a parked site (otherwise: linked).
        imageViewType.image = NSImage(
            named: site.aliasPath == nil
            ? "IconParked"
            : "IconLinked"
        )
        imageViewType.contentTintColor = NSColor.tertiaryLabelColor
        
        // Show the green or red lock based on whether the site was secured
        imageViewLock.contentTintColor = site.secured ?
            NSColor(named: "IconColorGreen") // green
            : NSColor(named: "IconColorRed")
        
        // Show the current driver
        labelDriverType.stringValue = site.driverDeterminedByComposer
            ? "Project Type".uppercased()
            : "Driver Type".uppercased()
        
        labelDriver.stringValue = site.driver ?? "driver.not_detected".localized
        
        // Determine the Laravel version
        if site.driver == "Laravel" && site.notableComposerDependencies.keys.contains("laravel/framework") {
            let constraint = site.notableComposerDependencies["laravel/framework"]!
            labelDriver.stringValue = "Laravel (\(constraint))"
        }
        
        // Show the PHP version
        buttonPhpVersion.title = " PHP \(site.composerPhp) "
        buttonPhpVersion.isHidden = (site.composerPhp == "???")
        

        imageViewPhpVersionOK.isHidden = (site.composerPhp == "???" || !site.composerPhpCompatibleWithLinked)
    }
    
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
}
