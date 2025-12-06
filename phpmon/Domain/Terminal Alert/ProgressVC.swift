//
//  ProgressVC.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 26/07/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation
import AppKit

class ProgressViewController: NSViewController {

    @IBOutlet weak var labelTitle: NSTextField!
    @IBOutlet weak var labelDescription: NSTextField!

    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var imageViewType: NSImageView!

    deinit {
        Log.perf("deinit: \(String(describing: self)).\(#function)")
    }

}
