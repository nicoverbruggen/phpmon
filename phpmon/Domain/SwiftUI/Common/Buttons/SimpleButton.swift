//
//  SimpleButton.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 18/02/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import SwiftUI

public struct SimpleButton: View {
    public let title: String
    public let imageName: String
    public let action: () -> Void

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14) // Standard macOS icon size
                Text(title)
            }
        }
    }
}
