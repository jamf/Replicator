//
//  SummaryViewController.swift
//  jamf-migrator
//
//  Created by Leslie Helou on 12/24/17.
//  Copyright © 2017 jamf. All rights reserved.
//

import Cocoa
import WebKit

class SummaryViewController: NSViewController {
    
    @IBOutlet weak var summary_WebView: WKWebView!
    var summaryDict = Dictionary<String, Dictionary<String,Int>>()     // summary counters of created, updated, and failed objects
    
    @IBOutlet weak var summary_TextField: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func dismissSummaryWindow(_ sender: NSButton) {
        let application = NSApplication.shared
        application.stopModal()
    }

    
}
