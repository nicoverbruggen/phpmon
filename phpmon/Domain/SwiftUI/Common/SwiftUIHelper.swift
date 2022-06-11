//
//  SwiftUIHelper.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 08/06/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation
import SwiftUI

var isRunningSwiftUIPreview: Bool {
    return ProcessInfo.processInfo
        .environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil
}

extension Color {
    public static var debug: Color = {
        if ProcessInfo.processInfo.environment["PAINT_PHPMON_SWIFTUI_VIEWS"] != nil {
            return Color.yellow
        }
        return Color.clear
    }()
}
