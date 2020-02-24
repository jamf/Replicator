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
    
    func show() {
        
        let vc = ViewController()
        var pwc: NSWindowController?
        
        if !(pwc != nil) {
            let storyboard = NSStoryboard(name: "Preferences", bundle: nil)
            pwc = storyboard.instantiateInitialController() as? NSWindowController
        }

        if (pwc != nil) {
            if !(vc.windowIsVisible(windowName: "Copy") || vc.windowIsVisible(windowName: "Export") || vc.windowIsVisible(windowName: "Site")) {
                pwc?.window?.setIsVisible(true)
                
            } else {
                DispatchQueue.main.async {
                    print("[PrefsWindowController] show existing preference window")
                    NSApp.windows[1].makeKeyAndOrderFront(self)
                    
                }
            }
        }
        
    }

}
