//
//  NVAlertExtension.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/07/2024.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation
import NVAlert

extension NVAlert {
    /**
     Shows the modal for a particular error.
     */
    @MainActor public static func show(for error: Error & AlertableError) {
        let key = error.getErrorMessageKey()
        return NVAlert().withInformation(
            title: "\(key).title".localized,
            subtitle: "\(key).description".localized
        ).withPrimary(text: "generic.ok".localized).show()
    }
}
