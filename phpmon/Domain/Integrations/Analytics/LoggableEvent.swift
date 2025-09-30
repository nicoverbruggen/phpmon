//
//  LoggableEvent.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 12/09/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

// TODO: Add anonymous analytics system
// Batch events and dispatch them every hour.
// Reset the counts when send successfully.
// That's the plan. Currently not implemented!
// Also, there should be an opt-out.

enum LoggableEvent: String {
    case menuOpened = "menu_opened"

    case phpVersionSwitched = "php_version_switched"

    case openedDomainManagement = "opened_domain_management"
    case openedPhpInstallations = "opened_php_installations"
    case openedPhpExtensions = "opened_php_extensions"

    case openedSettings = "opened_settings"

    // TODO: Add more tracked things.
}
