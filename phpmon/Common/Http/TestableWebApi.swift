//
//  TestableWebApi.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 29/09/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

class TestableWebApi: WebApiProtocol {
    private var fakeGetResponses: [URL: FakeWebApiResponse] = [:]
    private var fakePostResponses: [URL: FakeWebApiResponse] = [:]
    private var slow: Bool = false

    public func setSlowMode(_ slow: Bool) {
        self.slow = slow
    }

    init(
        getResponses: [URL: FakeWebApiResponse],
        postResponses: [URL: FakeWebApiResponse]
    ) {
        self.fakeGetResponses = getResponses
        self.fakePostResponses = postResponses
    }

    public func hasGetResponse(for url: URL) -> Bool {
        return fakeGetResponses.keys.contains(url)
    }

    public func hasPostResponse(for url: URL) -> Bool {
        return fakePostResponses.keys.contains(url)
    }

    func get(
        _ url: URL,
        withHeaders headers: HttpHeaders = [:],
        withTimeout timeout: TimeInterval = .seconds(10)
    ) async throws -> WebApiResponse {
        if hasGetResponse(for: url) {
            let response = fakeGetResponses[url]!

            if response.requestDuration > timeout {
                if slow {
                    await delay(seconds: timeout)
                }
                throw WebApiError.timedOut
            } else {
                if slow {
                    await delay(seconds: response.requestDuration)
                }
                return response.toWebApiResponse()
            }
        } else {
            throw WebApiError.invalidURL
        }
    }

    func post(
        _ url: URL,
        withHeaders headers: HttpHeaders = [:],
        withData data: String,
        withTimeout timeout: TimeInterval
    ) async throws -> WebApiResponse {
        if hasPostResponse(for: url) {
            let response = fakePostResponses[url]!

            if response.requestDuration > timeout {
                await delay(seconds: timeout)
                throw WebApiError.timedOut
            } else {
                await delay(seconds: response.requestDuration)
                return response.toWebApiResponse()
            }
        } else {
            throw WebApiError.invalidURL
        }
    }
}

struct FakeWebApiResponse {
    let statusCode: Int
    let headers: [String: String]
    let data: Data?
    let requestDuration: TimeInterval

    init(
        statusCode: Int,
        headers: [String: String],
        text: String,
        duration: TimeInterval
    ) {
        self.statusCode = statusCode
        self.headers = headers
        self.data = text.data(using: .utf8)
        self.requestDuration = duration
    }

    var text: String {
        guard let data = self.data else {
            return ""
        }

        return String(data: data, encoding: .utf8) ?? ""
    }

    func toWebApiResponse() -> WebApiResponse {
        WebApiResponse(
            statusCode: self.statusCode,
            headers: self.headers,
            data: self.data
        )
    }
}
