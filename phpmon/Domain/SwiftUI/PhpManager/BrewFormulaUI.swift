//
//  BrewFormulaUI.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 02/05/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import SwiftUI

extension BrewFormula {
    var icon: String {
        if self.hasUpgrade {
            return "arrow.up.square.fill"
        } else if self.isInstalled {
            return "checkmark.square.fill"
        }
        return "square.dashed"
    }

    var iconColor: Color {
        if self.hasUpgrade {
            return Color("StatusColorBlue")
        } else if self.isInstalled {
            return Color("StatusColorGreen")
        }
        return Color.gray.opacity(0.3)
    }
}
