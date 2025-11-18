//
//  RealApi.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 30/09/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

class RealWebApi: WebApiProtocol {
    var container: Container

    init(container: Container) {
        self.container = container
    }
}
