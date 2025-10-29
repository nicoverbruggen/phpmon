//
//  ValetListable.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 12/04/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

protocol ValetListable {

    func getListableName() -> String

    func getListableSecured() -> Bool

    func getListableCertificateExpiryDate() -> Date?

    func getListableAbsolutePath() -> String

    func getListablePhpVersion() -> String

    func getListableKind() -> String

    func getListableType() -> String

    func getListableUrl() -> URL?

    func getListableFavorited() -> Bool

}
