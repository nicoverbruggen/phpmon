//
//  UpdateManifest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 02/02/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

struct ReleaseManifest: Codable {
    let url: String
    let sha256: String
}
