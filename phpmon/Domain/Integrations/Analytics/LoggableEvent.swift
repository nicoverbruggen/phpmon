//
//  LoggableEvent.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 12/09/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

enum LoggableEvent: String {
    case menuOpened = "menu_opened"

    case phpVersionSwitched = "php_version_switched"

    case openedDomainManagement = "opened_domain_management"
    case openedPhpInstallations = "opened_php_installations"
    case openedPhpExtensions = "opened_php_extensions"

    case openedSettings = "opened_settings"

    // TODO: Add one for each feature and make sure each feature used actually increments a count somewhere
    // Ensure that the events are broadcast within 24 hrs since launch OR when the app quits
    // If the events are broadcast after 24 hrs of the app being running, reset analytics
    // Alternatively, batch events and dispatch them every hour (and keep track of what was sent)
    // I will think about this some more, these are just ideas for now
}
