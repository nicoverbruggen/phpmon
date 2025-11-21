//
//  CaskFile+API.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 18/11/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

enum CaskFileError: Error {
    case requestFailed
    case invalidData
    case invalidFile
}

extension CaskFile {
    public static func fromUrl(
        _ container: Container,
        _ url: URL
    ) async throws -> CaskFile? {
        // First, determine if we're loading a local URL or not
        if url.scheme == "file" {
            if let string = try? container.filesystem.getStringFromFile(url.relativePath) {
                return CaskFile.from(string)
            } else {
                throw CaskFileError.invalidFile
            }
        }

        // However, for the real deal, we will use the Web API
        guard let response = try? await container.webApi.get(
            url,
            withHeaders: container.webApi.defaultHeaders,
            withTimeout: .seconds(10)
        ) else {
            throw CaskFileError.requestFailed
        }

        guard let text = response.plainText else {
            throw CaskFileError.invalidData
        }

        return CaskFile.from(text)
    }
}
