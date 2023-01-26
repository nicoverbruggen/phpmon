//
//  TimeExtension.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 29/09/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

extension TimeInterval {
    public static func minutes(_ amount: Int) -> TimeInterval {
        return Double(amount * 60)
    }
}
