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
    var site: Valet.Site? = nil
    
    @IBOutlet weak var labelSiteName: NSTextField!
    @IBOutlet weak var labelPathName: NSTextField!
    
    @IBOutlet weak var imageViewLock: NSImageView!
    @IBOutlet weak var imageViewType: NSImageView!
    
    @IBOutlet weak var labelDriver: NSTextField!
    
    @IBOutlet weak var buttonPhpVersion: NSButton!
    @IBOutlet weak var imageViewPhpVersionOK: NSImageView!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    func populateCell(with site: Valet.Site) {
        self.site = site
        
        // Make sure to show the TLD
        labelSiteName.stringValue = "\(site.name!).\(Valet.shared.config.tld)"
        
        // Show the absolute path, except make sure to replace the /Users/username segment with ~ for readability
        labelPathName.stringValue = site.absolutePath
            .replacingOccurrences(of: "/Users/\(Paths.whoami)", with: "~")
        
        // If the `aliasPath` is nil, we're dealing with a parked site (otherwise: linked).
        imageViewType.image = NSImage(
            named: site.aliasPath == nil
            ? "IconParked"
            : "IconLinked"
        )
        imageViewType.contentTintColor = NSColor.tertiaryLabelColor
        
        // Show the green or red lock based on whether the site was secured
        imageViewLock.image = NSImage(named: site.secured ? "Lock" : "LockUnlocked")
        imageViewLock.contentTintColor = site.secured ?
            NSColor.init(red: 63/255, green: 195/255, blue: 128/255, alpha: 1.0) // green
            : NSColor.init(red: 246/255, green: 71/255, blue: 71/255, alpha: 1.0) // red
        
        // Show the current driver
        labelDriver.stringValue = "\(site.driver ?? "???")"
        
        // Determine the Laravel version
        if site.driver == "Laravel" && site.notableComposerDependencies.keys.contains("laravel/framework") {
            let constraint = site.notableComposerDependencies["laravel/framework"]!
            labelDriver.stringValue = "Laravel (\(constraint))"
        }
        
        // Show the PHP version
        buttonPhpVersion.title = " PHP \(site.composerPhp) "
        buttonPhpVersion.isHidden = (site.composerPhp == "???")
        
        // Split the composer list (on "|") to evaluate multiple constraints
        // For example, for Laravel 8 projects the value is "^7.3|^8.0"
        let matchesConstraint = site.composerPhp.split(separator: "|").map { string in
            return PhpVersionNumberCollection.make(from: [PhpEnv.phpInstall.version.long])
                .matching(constraint: string.trimmingCharacters(in: .whitespacesAndNewlines))
                .count > 0
        }.contains(true)
        
        imageViewPhpVersionOK.isHidden = (site.composerPhp == "???" || !matchesConstraint)
    }
    
    @IBAction func pressedPhpVersion(_ sender: Any) {
        guard let site = self.site else { return }
        
        let alert = NSAlert.init()
        alert.alertStyle = .informational
        
        alert.messageText = "alert.composer_php_requirement.title"
            .localized("\(site.name!).\(Valet.shared.config.tld)", site.composerPhp)
        alert.informativeText = "alert.composer_php_requirement.info"
            .localized(site.composerPhpSource)
        
        alert.addButton(withTitle: "Close")
        
        var mapIndex: Int = NSApplication.ModalResponse.alertSecondButtonReturn.rawValue
        var map: [Int: String] = [:]
        
        // Determine which installed versions would be ideal to switch to,
        // but make sure to exclude the currently linked version
        site.composerPhp.split(separator: "|").flatMap { string in
            return PhpEnv.shared.validVersions(for: string.trimmingCharacters(in: .whitespacesAndNewlines))
        }.filter({ version in
            version.homebrewVersion != PhpEnv.phpInstall.version.short
        }).forEach { version in
            alert.addButton(withTitle: "Switch to PHP \(version.homebrewVersion)")
            map[mapIndex] = version.homebrewVersion
            mapIndex += 1
        }
        
        alert.beginSheetModal(for: App.shared.siteListWindowController!.window!) { response in
            if response.rawValue > NSApplication.ModalResponse.alertFirstButtonReturn.rawValue {
                if map.keys.contains(response.rawValue) {
                    let version = map[response.rawValue]!
                    print("Pressed button to switch to \(version)")
                    MainMenu.shared.switchToPhpVersion(version)
                }
            }
        }
    }
}
