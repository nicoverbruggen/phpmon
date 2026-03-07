//
//  RealWebApiTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 18/11/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Testing
import Foundation

struct RealWebApiTest {
    private var container: Container

    init() throws {
        self.container = Container.real(minimal: true)
    }

    var WebApi: RealWebApi {
        return container.webApi as! RealWebApi
    }

    @Test(.enabled(if: TestURL.isReachable(url: "https://api.phpmon.test/up"),
                   "Requires api.phpmon.test to be reachable"))
    func requestSucceeds() async {
        let response = try! await WebApi.get(
            url("https://api.phpmon.test/up")
        )

        #expect(response.statusCode == 200)
        #expect(response.plainText!.contains("Response rendered in"))
    }

    @Test(.enabled(if: TestURL.isReachable(url: "https://api.phpmon.test/up"),
                   "Requires api.phpmon.test to be reachable"))
    func requestTimesOut() async {
        await #expect(throws: WebApiError.timedOut) {
            try await WebApi.get(
                url("https://api.phpmon.test/up"),
                withTimeout: .seconds(0.01)
            )
        }
    }
}
