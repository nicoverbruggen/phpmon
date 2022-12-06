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
