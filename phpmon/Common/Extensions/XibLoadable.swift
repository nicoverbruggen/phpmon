//
//  NibLoadable.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 04/02/2021.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa

// Adapted from: https://stackoverflow.com/a/46268778

protocol XibLoadable {

    static var xibName: String? { get }
    static func createFromXib(in bundle: Bundle) -> Self?

}

extension XibLoadable where Self: NSView {

    static var xibName: String? {
        return String(describing: Self.self)
    }

    static func createFromXib(in bundle: Bundle = Bundle.main) -> Self? {
        guard let xibName = xibName else { return nil }
        var topLevelArray: NSArray?
        bundle.loadNibNamed(NSNib.Name(xibName), owner: self, topLevelObjects: &topLevelArray)
        guard let results = topLevelArray else { return nil }
        let views = [Any](results).filter { $0 is Self }
        return views.last as? Self
    }

}
