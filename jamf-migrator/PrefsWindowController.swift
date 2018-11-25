//
//  PrefsWindowController.swift
//  jamf-migrator
//
//  Created by Leslie Helou on 11/25/18.
//  Copyright © 2018 jamf. All rights reserved.
//

import Cocoa

class PrefsWindowController: NSWindowController, NSWindowDelegate {
    
    override func windowDidLoad() {
        super.windowDidLoad()
    
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        self.window?.orderOut(sender)
        return false
    }      

}
