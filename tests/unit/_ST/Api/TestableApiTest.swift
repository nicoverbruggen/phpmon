//
//  Untitled.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 29/09/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Testing
import Foundation

@Suite("Api")
struct TestableApiTest {

    @Test
    func createFakeApi() {
        let api = TestableApi(responses: [
            url("https://api.phpmon.test"): FakeApiResponse(statusCode: 200, headers: [:], text: "{\"success\": true}")
        ])

        #expect(api.hasResponse(for: url("https://api.phpmon.test")) == true)

        let response = api.getResponse(for: url("https://api.phpmon.test"))

        #expect(response.statusCode == 200)
        #expect(response.text.contains("success"))
    }

}
