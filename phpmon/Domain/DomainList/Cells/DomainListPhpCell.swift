//
//  DomainListPhpCell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/03/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Cocoa
import AppKit

class DomainListPhpCell: NSTableCellView, DomainListCellProtocol {
    static let reusableName = "domainListPhpCell"

    var site: ValetSite?

    @IBOutlet weak var buttonPhpVersion: NSButton!
    @IBOutlet weak var imageViewPhpVersionOK: NSImageView!

    func populateCell(with site: ValetSite) {
        self.site = site

        buttonPhpVersion.title = " PHP \(site.servingPhpVersion)"

        imageViewPhpVersionOK.toolTip = nil

        if site.isolatedPhpVersion != nil {
            imageViewPhpVersionOK.isHidden = false
            imageViewPhpVersionOK.image = NSImage(named: "Isolated")
            imageViewPhpVersionOK.toolTip = "domain_list.tooltips.isolated".localized(site.servingPhpVersion)
        } else {
            imageViewPhpVersionOK.isHidden = (site.composerPhp == "???" || !site.composerPhpCompatibleWithLinked)
            imageViewPhpVersionOK.image = NSImage(named: "Checkmark")
            imageViewPhpVersionOK.toolTip = "domain_list.tooltips.checkmark".localized(site.composerPhp)
        }

        buttonPhpVersion.isHidden = false
        imageViewPhpVersionOK.isHidden = false
    }

    func populateCell(with proxy: ValetProxy) {
        buttonPhpVersion.isHidden = true
        imageViewPhpVersionOK.isHidden = true
        return
    }

    @IBAction func pressedPhpVersion(_ sender: Any) {
        guard let site = self.site else { return }

        let alert = NSAlert.init()
        alert.alertStyle = .informational

        var information = ""

        if self.site?.isolatedPhpVersion != nil {
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

            // Site is not isolated, show options to switch global PHP version
            alert.beginSheetModal(for: App.shared.domainListWindowController!.window!) { response in
                if response.rawValue > NSApplication.ModalResponse.alertFirstButtonReturn.rawValue {
                    if map.keys.contains(response.rawValue) {
                        let version = map[response.rawValue]!
                        Log.info("Pressed button to switch to \(version)")
                        MainMenu.shared.switchToPhpVersion(version)
                    }
                }
            }
        } else {
            // Site is isolated, do not show any options to switch
            alert.beginSheetModal(for: App.shared.domainListWindowController!.window!)
        }
    }

}
