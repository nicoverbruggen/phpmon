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

            // Filter for stable versions using the version_normalized string.
            // A stable version typically does not have a hyphen (-) indicating a pre-release.
            let stableVersions = versionsArray.filter { version in
                guard let versionNormalized = version.version_normalized else {
                    return false
                }

                // Filter out versions with a hyphen, which are usually unstable.
                return !versionNormalized.contains("-")
            }

            // Sort the filtered versions using version_normalized, which is designed for lexicographical sorting.
            let sortedVersions = stableVersions.sorted { (version1, version2) -> Bool in
                guard let v1 = version1.version_normalized, let v2 = version2.version_normalized else {
                    return false
                }
                return v1.lexicographicallyPrecedes(v2)
            }

            // The last element of the sorted array is the latest version
            guard let latestVersionInfo = sortedVersions.last,
                  let latestVersion = latestVersionInfo.version else {
                throw PackagistError.noStableVersions
            }

            return try! VersionNumber.parse(latestVersion)
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
