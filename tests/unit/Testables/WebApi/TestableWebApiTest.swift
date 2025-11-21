//
//  TestableWebApiTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 29/09/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Testing
import Foundation

struct TestableWebApiTest {
    private var container: Container

    init() throws {
        self.container = Container.fake(getResponses: [
            url("https://api.phpmon.test"): FakeWebApiResponse(
                statusCode: 200,
                headers: [:],
                text: "{\"success\": true}",
                duration: .milliseconds(150)
            ),
            url("https://api.phpmon.test/up"): FakeWebApiResponse(
                statusCode: 200,
                headers: [:],
                text: "{\"success\": true}",
                duration: .milliseconds(40)
            ),
            url("https://api.phpmon.test/woop"): FakeWebApiResponse(
                statusCode: 404,
                headers: [:],
                text: "PAGE NOT FOUND",
                duration: .seconds(2)
            )
        ])
    }

    var WebApi: TestableWebApi {
        return container.webApi as! TestableWebApi
    }

    @Test func requestSucceeds() async {
        #expect(WebApi.hasGetResponse(for: url("https://api.phpmon.test")) == true)

        let response = try! await WebApi.get(
            url("https://api.phpmon.test/up"),
            withTimeout: .seconds(1.0)
        )

        #expect(response.statusCode == 200)
        #expect(response.plainText!.contains("success"))
    }

    @Test func requestTimesOut() async {
        await #expect(throws: WebApiError.timedOut) {
            try await WebApi.get(
                url("https://api.phpmon.test/woop"),
                withTimeout: .seconds(1.0)
            )
        }
    }

    @Test func requestTimesOutInSlowMode() async {
        WebApi.setSlowMode(true)

        await #expect(throws: WebApiError.timedOut) {
            try await WebApi.get(
                url("https://api.phpmon.test/woop"),
                withTimeout: .seconds(1.0)
            )
        }

        WebApi.setSlowMode(false)
    }

    @Test func invalidUrl() async {
        await #expect(throws: WebApiError.invalidURL) {
            try await WebApi.get(
                url("https://api.phpmon.test/woop/nice"),
                withTimeout: .seconds(1.0)
            )
        }
    }
}
