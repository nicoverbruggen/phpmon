//
//  Async.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 23/01/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

/**
 This generic async helper is something I'd like to use in more places.
 
 The `DispatchQueue.global` into `DispatchQueue.main.async` logic is common in the app.
 
 I could also use try `async` support which was introduced in Swift but that would
 require too much refactoring at this time to consider. I also need to read up on async
 in order to properly grasp all the gotchas. Looking into that later at some point.
 */
public func runAsync(_ execute: @escaping () -> Void, completion: @escaping () -> Void = {})
{
    DispatchQueue.global(qos: .userInitiated).async {
        execute()
        
        DispatchQueue.main.async {
            completion()
        }
    }
}
