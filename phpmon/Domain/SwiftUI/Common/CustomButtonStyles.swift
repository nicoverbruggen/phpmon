//
//  CustomButtonStyles.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 15/03/2024.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import SwiftUI

public struct CustomButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled

    public func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .foregroundStyle(.white)
            .background(.statusColorBlue, in: .rect(cornerRadius: 8, style: .continuous))
            .opacity({
                if configuration.isPressed {
                    return 0.4
                }

                if !isEnabled {
                    return 0.2
                }

                return 1.0
            }())
    }
}

extension ButtonStyle where Self == CustomButtonStyle {
    static var custom: CustomButtonStyle { .init() }
}
