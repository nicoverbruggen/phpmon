//
//  SwiftUIHelper.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 08/06/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

var isRunningSwiftUIPreview: Bool {
    return ProcessInfo.processInfo
        .environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil
}
