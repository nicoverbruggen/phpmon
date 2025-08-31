//
//  BundleHelper.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 25/08/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

/**
 This file is used to access bundle resources via test structs
 that cannot access the bundle via the previous class syntax.

 After converting a test to Swift Testing, this is no longer possible:

 ```swift
 class MyTest: XCTestCase {
    static var configurationFileUrl: URL {
        return Bundle(for: Self.self).url(
            forResource: "valet-config",
            withExtension: "json"
         )!
    }
 }
 ```

 Normally, we would be able to access the bundle via the class
 itself, but we'd prefer _not_ to make this accessible to other
 classes. Thankfully, this is where `fileprivate` shines.

 The bundle is now accessed via `TestBundleClass`, which is not
 accessible outside the scope of this file. `TestBundle` as a
 global variable, though, is!

 Usage:

 ```swift
 return TestBundle.url(
     forResource: "valet-config",
     withExtension: "json"
 )!
 ```
 */

fileprivate class TestBundleClass {}

public var TestBundle: Bundle {
    return Bundle(for: TestBundleClass.self)
}
