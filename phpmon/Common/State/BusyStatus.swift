//
//  BusyStatus.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 02/05/2023.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

class BusyStatus: ObservableObject {
    @Published var busy: Bool
    @Published var title: String
    @Published var description: String

    init(busy: Bool, title: String, description: String) {
        self.busy = busy
        self.title = title
        self.description = description
    }

    public static func notBusy() -> BusyStatus {
        return BusyStatus(busy: false, title: "", description: "")
    }

    public static func busy() -> BusyStatus {
        return BusyStatus(busy: false, title: "", description: "")
    }
}
