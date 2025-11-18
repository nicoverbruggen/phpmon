//
//  WebApiProtocol.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 30/09/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

typealias HttpHeaders = [String: String]

enum WebApiError: Error {
    case invalidURL
    case networkError
    case timedOut
    case other
}

struct WebApiResponse {
    let statusCode: Int
    let headers: HttpHeaders
    let data: Data?

    var plainText: String? {
        guard let data = self.data else {
            assertionFailure("Response data is unexpectedly empty")
            return nil
        }

        guard let string = String(data: data, encoding: .utf8) else {
            assertionFailure("Response unexpectedly cannot be decoded")
            return nil
        }

        return string
    }
}

protocol WebApiProtocol {
    var defaultHeaders: HttpHeaders { get }

    func get(
        _ url: URL,
        withHeaders headers: HttpHeaders,
        withTimeout timeout: TimeInterval
    ) async throws -> WebApiResponse

    func post(
        _ url: URL,
        withHeaders headers: HttpHeaders,
        withData data: String,
        withTimeout timeout: TimeInterval
    ) async throws -> WebApiResponse
}
