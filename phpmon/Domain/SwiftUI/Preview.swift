//
//  Preview.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 15/04/2021.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import SwiftUI
import Cocoa

@available(OSX 11.0, *)
struct Preview_Previews: PreviewProvider {
    static var previews: some View {
        PMHeaderView(content: "You are running PHP 8.1")
        PMStatsView(content: "15 MB")
        PMStatsView(content: "2 GB")
        PMServicesView() // uses live services data!
    }
}
