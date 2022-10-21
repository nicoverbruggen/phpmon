//
//  DomainListable.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 12/04/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

protocol DomainListable {

    func getListableName() -> String

    func getListableSecured() -> Bool

    func getListableAbsolutePath() -> String

    func getListablePhpVersion() -> String

    func getListableKind() -> String

    func getListableType() -> String

    func getListableUrl() -> URL?

}
