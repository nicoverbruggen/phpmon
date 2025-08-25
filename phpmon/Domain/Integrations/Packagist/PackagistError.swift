//
//  PackagistError.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 25/08/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

enum PackagistError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case jsonDecodingError(Error)
    case noStableVersions
    case unexpectedResponseStructure

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The provided URL is invalid."
        case .networkError(let error):
            return "A network error occurred: \(error.localizedDescription)"
        case .jsonDecodingError(let error):
            return "Failed to decode JSON: \(error.localizedDescription)"
        case .noStableVersions:
            return "No stable versions were found for the package."
        case .unexpectedResponseStructure:
            return "The API response structure was not as expected."
        }
    }
}
