//
//  App+UUID.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 01/12/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

struct Api {
    /**
    How long a API ID (uuid) is valid.

    Currently set to this length to accomodate potential failures
    for the update check.
    */
    static let uuidValidityDuration: TimeInterval = .hours(36)

    static let uuidKey = "api.uuid"
    static let uuidTimestampKey = "api.uuid.timestamp"
}

extension App {
    /**
     Returns a unique UUID that automatically refreshes every 36 hours.
     It is used to more accurately throttle requests for a given IP, since
     multiple users could be coming from one residential or business IP.

     This UUID is NOT used for tracking purposes, only to identify unique
     users of PHP Monitor to properly scale the server and throttle the API.

     The UUID is stored in UserDefaults and regenerated when expired.
     */
    func getApiId() -> String {
        let defaults = UserDefaults.standard

        // Check if we have a stored UUID and timestamp
        if let storedUUID = defaults.string(forKey: Api.uuidKey),
           let storedTimestamp = defaults.object(forKey: Api.uuidTimestampKey) as? Date {

            // Check if the UUID is still valid (less than X hours old)
            if Date().timeIntervalSince(storedTimestamp) < Api.uuidValidityDuration {
                return storedUUID
            }
        }

        // Generate a new UUID if we don't have one or it's expired
        return regenerate()
    }

    /**
     Regenerates a UUID for a given duration.
     */
    private func regenerate() -> String {
        let newUUID = UUID().uuidString
        let defaults = UserDefaults.standard

        defaults.set(newUUID, forKey: Api.uuidKey)
        defaults.set(Date(), forKey: Api.uuidTimestampKey)

        return newUUID
    }
}
