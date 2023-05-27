//
//  ProgressViewSubject.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 11/03/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import SwiftUI

class ProgressViewSubject: ObservableObject {
    @Published var title: String
    @Published var description: String?
    @Published var progress: Double

    init(title: String, description: String) {
        self.title = title
        self.description = description
        self.progress = 0
    }
}
