//
//  Utility.swift
//  phpmon-tests
//
//  Created by Nico Verbruggen on 14/02/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

class Utility {
    
    public static func copyToTemporaryFile(resourceName: String, fileExtension: String) -> URL? {
        if let bundleURL = Bundle(for: Self.self).url(forResource: resourceName, withExtension: fileExtension) {
            let tempDirectoryURL = NSURL.fileURL(withPath: NSTemporaryDirectory(), isDirectory: true)
            let targetURL = tempDirectoryURL.appendingPathComponent("\(UUID().uuidString).\(fileExtension)")
            
            do {
                try FileManager.default.copyItem(at: bundleURL, to: targetURL)
                return targetURL
            } catch let error {
                print("Unable to copy file: \(error)")
            }
        }
        
        return nil
    }
}
