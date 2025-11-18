//
//  Untitled.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 29/09/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Testing
import Foundation

struct TestableApiTest {
    private var container: Container

    init() throws {
        self.container = Container.fake(apiResponses: [
            url("https://api.phpmon.test"): FakeWebApiResponse(
                statusCode: 200,
                headers: [:],
                text: "{\"success\": true}"
            )
        ])
    }

    var WebApi: TestableWebApi {
        return container.webApi as! TestableWebApi
    }

    @Test func createFakeApi() {
        #expect(WebApi.hasResponse(for: url("https://api.phpmon.test")) == true)

        let response = WebApi.getResponse(for: url("https://api.phpmon.test"))

        #expect(response.statusCode == 200)
        #expect(response.text.contains("success"))
    }
}
