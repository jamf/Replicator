//
//  SummaryViewController.swift
//  Replicator
//
//  Created by Leslie Helou on 12/24/17.
//  Copyright 2024 Jamf. All rights reserved.
//

import Cocoa
import WebKit

class SummaryViewController: NSViewController {
    
    @IBOutlet weak var summary_WebView: WKWebView!
    
    @IBOutlet weak var summary_TextField: NSTextField!
    override func viewDidLoad() {
        logFunctionCall()
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func dismissSummaryWindow(_ sender: NSButton) {
        logFunctionCall()
        let application = NSApplication.shared
        application.stopModal()
    }

    
}
