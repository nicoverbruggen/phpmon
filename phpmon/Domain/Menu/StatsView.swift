//
//  StatsView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 04/02/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa

class StatsView: NSView, XibLoadable {
    @IBOutlet weak var titleMemLimit: NSTextField!
    @IBOutlet weak var titleMaxPost: NSTextField!
    @IBOutlet weak var titleMaxUpload: NSTextField!
    
    @IBOutlet weak var labelMemLimit: NSTextField!
    @IBOutlet weak var labelMaxPost: NSTextField!
    @IBOutlet weak var labelMaxUpload: NSTextField!
    
    static func asMenuItem(memory: String, post: String, upload: String) -> NSMenuItem {
        let view = Self.createFromXib()
        view!.titleMemLimit.stringValue = "mi_memory_limit".localized.uppercased()
        view!.titleMaxPost.stringValue = "mi_post_max_size".localized.uppercased()
        view!.titleMaxUpload.stringValue = "mi_upload_max_filesize".localized.uppercased()
        view!.labelMemLimit.stringValue = memory
        view!.labelMaxPost.stringValue = post
        view!.labelMaxUpload.stringValue = upload
        let item = NSMenuItem()
        item.view = view
        item.target = self
        return item
    }
}
