//
//  Valet.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 29/11/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

class Valet {
    
    var version: String
    var detectedSites: [String]
    
    init() {
        // Let's see if we can't discern what the Valet version is
        // but in order to do so, we'll need to be able to run Valet
        // which has, historically, been kind of a pain in the butt
        self.version = Actions.valet("--version")
            .replacingOccurrences(of: "Laravel Valet ", with: "")
        
        self.detectedSites = []
    }
    
}
