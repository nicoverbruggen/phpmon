//
//  StatsView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 04/02/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa

class ServicesView: NSView, XibLoadable {
    
    @IBOutlet weak var imageViewPhp: NSImageView!
    @IBOutlet weak var imageViewNginx: NSImageView!
    @IBOutlet weak var imageViewDnsmasq: NSImageView!
    
    @IBOutlet weak var textFieldPhp: NSTextField!
    
    var services: [String: HomebrewService] = [:]
    
    static func asMenuItem() -> NSMenuItem {
        let view = Self.createFromXib()
        let item = NSMenuItem()
        item.view = view
        item.target = self
        NotificationCenter.default.addObserver(
            view!, selector: #selector(self.updateInformation),
            name: Events.ServicesUpdated,
            object: nil
        )
        return item
    }
    
    override func viewWillDraw() {
        super.viewWillDraw()
        self.loadData()
    }

    @objc func updateInformation() {
        self.loadData()
    }
    
    func loadData() {
        runAsync {
            let servicesList = try! JSONDecoder().decode(
                [HomebrewService].self,
                from: Shell.pipe(
                    "sudo \(Paths.brew) services info --all --json",
                    requiresPath: true
                ).data(using: .utf8)!
            ).filter({ service in
                return [PhpEnv.phpInstall.formula, "nginx", "dnsmasq"].contains(service.name)
            })
            
            self.services = Dictionary(uniqueKeysWithValues: servicesList.map{ ($0.name, $0) })
        } completion: {
            self.textFieldPhp.stringValue = PhpEnv.phpInstall.formula.uppercased()
            self.applyServiceStyling(PhpEnv.phpInstall.formula, self.imageViewPhp)
            self.applyServiceStyling("nginx", self.imageViewNginx)
            self.applyServiceStyling("dnsmasq", self.imageViewDnsmasq)
        }
    }
    
    func applyServiceStyling(_ serviceName: String, _ imageView: NSImageView) {
        if services[serviceName] != nil && services[serviceName]!.running {
            imageView.image = NSImage(named: "ServiceOn")
            imageView.contentTintColor = NSColor.black
        } else {
            imageView.image = NSImage(named: "ServiceOff")
            imageView.contentTintColor = NSColor.init(red: 246/255, green: 71/255, blue: 71/255, alpha: 1.0)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Events.ServicesUpdated, object: nil)
    }
}
