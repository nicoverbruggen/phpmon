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

    init(container: Container) {
        self.container = container
    }

    func get(_ url: URL, withHeaders: HttpHeaders, withTimeout: TimeInterval) async throws -> WebApiResponse {
        return WebApiResponse(statusCode: 200, headers: [:], data: Data())
    }

    func post(_ url: URL, withHeaders: HttpHeaders, withData: String, withTimeout: TimeInterval) async throws -> WebApiResponse {
        return WebApiResponse(statusCode: 200, headers: [:], data: Data())
    }
}
