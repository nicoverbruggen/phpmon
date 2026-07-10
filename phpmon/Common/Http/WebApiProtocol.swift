//
//  WebApiProtocol.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 30/09/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

typealias HttpHeaders = [String: String]

// `nonisolated` + `Sendable`: this error is thrown out of the (potentially
// main-actor) `WebApiProtocol` methods and caught in actor/off-main callers,
// so it crosses isolation boundaries.
nonisolated enum WebApiError: Error, Sendable {
    case invalidURL
    case networkError
    case timedOut
    case other
}

// `nonisolated` + `Sendable`: returned from the async `WebApiProtocol` methods
// back to actor callers, so it must be safe to send across isolation boundaries.
// All stored properties (Int, [String: String], Data?) are already Sendable.
nonisolated struct WebApiResponse: Sendable {
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
