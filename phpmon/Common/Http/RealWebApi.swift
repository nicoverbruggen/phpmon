//
//  RealWebApi.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 30/09/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

class RealWebApi: WebApiProtocol {
    var container: Container

    var defaultHeaders: HttpHeaders {
        return [
            "User-Agent": "phpmon-nur/2.0",
            "X-phpmon-version": "\(App.shortVersion) (\(App.bundleVersion))",
            "X-phpmon-os-version": "\(App.macVersion)",
            "X-phpmon-bundle-id": "\(App.identifier)"
        ]
    }

    init(container: Container) {
        self.container = container
    }

    private func request(
        url: URL,
        method: String,
        data: Data?,
        headers: HttpHeaders,
        timeout: TimeInterval
    ) async throws -> WebApiResponse {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = timeout
        for header in headers {
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let response = response as? HTTPURLResponse else {
                throw WebApiError.networkError
            }

            return WebApiResponse(
                statusCode: response.statusCode,
                headers: response.allHeaderFields as! HttpHeaders,
                data: data
            )
        } catch {
            if let urlError = error as? URLError {
                if urlError.code == .timedOut {
                    throw WebApiError.timedOut
                }
            }
            throw WebApiError.networkError
        }
    }

    func get(
        _ url: URL,
        withHeaders headers: HttpHeaders = [:],
        withTimeout timeout: TimeInterval = URLSession.shared.configuration.timeoutIntervalForRequest
    ) async throws -> WebApiResponse {
        try await self.request(
            url: url,
            method: "GET",
            data: nil,
            headers: headers,
            timeout: timeout
        )
    }

    func post(
        _ url: URL,
        withHeaders headers: HttpHeaders,
        withData data: String,
        withTimeout timeout: TimeInterval
    ) async throws -> WebApiResponse {
        try await self.request(
            url: url,
            method: "POST",
            data: data.data(using: .utf8),
            headers: headers,
            timeout: timeout
        )
    }
}
