//
//  ViewController.swift
//  phpmon
//
//  Created by Nico Verbruggen on 11/06/2019.
//  Copyright © 2019 Nico Verbruggen. All rights reserved.
//

import Cocoa

class LogViewController: NSViewController {
    
    @IBAction func pressed(_ sender: Any) {
        self.view.window?.windowController?.close()
    }
    
}
