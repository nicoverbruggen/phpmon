//
//  Untitled.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 25/08/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

class Packagist {
    static func getLatestStableVersion(packageName: String) async throws -> VersionNumber {
        guard let url = URL(string: "https://repo.packagist.org/p2/\(packageName).json") else {
            throw PackagistError.invalidURL
        }

        let agent = "phpmon/\(App.shortVersion)"

        var request = URLRequest(url: url)
        request.setValue(agent, forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                throw PackagistError.networkError(NSError(domain: "", code: code, userInfo: nil))
            }

            let decodedResponse = try JSONDecoder()
                .decode(PackagistP2Response.self, from: data)

            guard let versionsArray = decodedResponse.packages[packageName] else {
                throw PackagistError.unexpectedResponseStructure
            }

            // Packagist v2 API returns versions in descending order (newest first).
            // Filter for stable versions - those without a hyphen in version_normalized.
            let stableVersions = versionsArray.filter { version in
                guard let versionNormalized = version.version_normalized else {
                    return false
                }
                // Filter out pre-release versions (alpha, beta, RC, etc.)
                return !versionNormalized.contains("-")
            }

            // Get the first stable version (which is the latest)
            guard let latestVersionInfo = stableVersions.first,
                  let latestVersion = latestVersionInfo.version else {
                throw PackagistError.noStableVersions
            }

            return try VersionNumber.parse(latestVersion)
        } catch {
            // Catch any errors that occurred and re-throw them as our custom error type for better diagnostics.
            if let decodingError = error as? DecodingError {
                throw PackagistError.jsonDecodingError(decodingError)
            } else if let urlError = error as? URLError {
                throw PackagistError.networkError(urlError)
            } else {
                throw error
            }
        }
    }
}
