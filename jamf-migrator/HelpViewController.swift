//
//  HelpViewController.swift
//  jamf-migrator
//
//  Created by Leslie Helou on 7/19/17.
//  Copyright © 2017 jamf. All rights reserved.
//

import Cocoa
import WebKit

@available(OSX 10.11, *)
class HelpViewController: NSViewController {

    @IBOutlet weak var help_WebView: WKWebView!
    
    
//    @IBAction func dismissHelpWindow(_ sender: NSButton) {
//        let application = NSApplication.shared()
//        application.stopModal()
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        let filePath = Bundle.main.path(forResource: "index", ofType: "html")
        let folderPath = Bundle.main.resourcePath
        
        let fileUrl = NSURL(fileURLWithPath: filePath!)
        let baseUrl = NSURL(fileURLWithPath: folderPath!, isDirectory: true)
        
        help_WebView.loadFileURL(fileUrl as URL, allowingReadAccessTo: baseUrl as URL)
    }
}
