//
//  OutputLine.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 27/02/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation

struct OutputLine: Identifiable {
    let id = UUID()
    let text: String
    let stream: ShellStream
}
