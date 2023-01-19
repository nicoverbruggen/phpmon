//
//  CreatedFromFile.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 15/05/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

protocol CreatedFromFile {

    static func from(filePath: String) -> Self?

}
