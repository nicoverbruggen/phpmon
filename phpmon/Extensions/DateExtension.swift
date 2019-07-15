//
//  Date.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 09/07/2019.
//  Copyright © 2019 Nico Verbruggen. All rights reserved.
//

import Cocoa

extension Date
{
    func toString() -> String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.string(from: self)
    }
}
