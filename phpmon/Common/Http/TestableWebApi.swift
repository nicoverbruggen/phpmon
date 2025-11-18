//
//  TestableWebApi.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 29/09/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

class TestableWebApi: WebApiProtocol {
    private var fakeResponses: [URL: FakeWebApiResponse] = [:]

    init(responses: [URL: FakeWebApiResponse]) {
        self.fakeResponses = responses
    }

    public func hasResponse(for url: URL) -> Bool {
        return fakeResponses.keys.contains(url)
    }

    public func getResponse(for url: URL) -> FakeWebApiResponse {
        return fakeResponses[url]!
    }
}

struct FakeWebApiResponse {
    let statusCode: Int
    let headers: [String: String]
    let data: Data?

    init(statusCode: Int, headers: [String: String], text: String) {
        self.statusCode = statusCode
        self.headers = headers
        self.data = text.data(using: .utf8)
    }

    var text: String {
        return String(data: self.data!, encoding: .utf8) ?? ""
    }
}
