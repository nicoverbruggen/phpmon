//
//  ValetInteractable.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/10/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

protocol DomainInteractable {

    func secure() async throws

    func unsecure() async throws

    func isolate(version: PhpVersionNumber) async throws

    func unlink() async throws

}

extension ValetSite: DomainInteractable {

    func secure() async throws {
        try await ValetInteractor.secure(site: self)
    }

    func unsecure() async throws {
        try await ValetInteractor.unsecure(site: self)
    }

    func isolate(version: PhpVersionNumber) async throws {
        try await ValetInteractor.isolate(site: self, version: version)
    }

    func unlink() async throws {
        try await ValetInteractor.unlink(site: self)
    }

}
