//
//  CustomPrefs.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 03/01/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

struct CustomPrefs: Decodable {
    let scanApps: [String]
    let presets: [Preset]?
    let services: [String]?

    public func hasPresets() -> Bool {
        return self.presets != nil && !self.presets!.isEmpty
    }

    public func hasServices() -> Bool {
        return self.services != nil && !self.services!.isEmpty
    }

    private enum CodingKeys: String, CodingKey {
        case scanApps = "scan_apps"
        case presets = "presets"
        case services = "services"
    }
}
