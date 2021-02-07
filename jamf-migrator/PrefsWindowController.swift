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

        var prefsVisible = false
        let tabs = ["Copy", "Export", "Site", "App", "Computer", "Password"]
        let vc = ViewController()
        var pwc: NSWindowController?
        
        if !(pwc != nil) {
            let storyboard = NSStoryboard(name: "Preferences", bundle: nil)
            pwc = storyboard.instantiateInitialController() as? NSWindowController
        }

        if (pwc != nil) {
//            if !(vc.windowIsVisible(windowName: "Copy") || vc.windowIsVisible(windowName: "Export") || vc.windowIsVisible(windowName: "Site") || vc.windowIsVisible(windowName: "App") || vc.windowIsVisible(windowName: "Computer") || vc.windowIsVisible(windowName: "Password")) {
//                pwc?.window?.setIsVisible(true)
//
//            } else {
                DispatchQueue.main.async {
//                    print("[PrefsWindowController] show existing preference window")
//                    NSApp.windows[1].makeKeyAndOrderFront(self)
                    let windowsCount = NSApp.windows.count
                    for i in (0..<windowsCount) {
//                    for theWindow in NSApp.windows {
                        if tabs.firstIndex(of: NSApp.windows[i].title) != nil {
                            NSApp.windows[i].makeKeyAndOrderFront(self)
                            prefsVisible = true
                        }
                    }
                    if !prefsVisible {
                        pwc?.window?.setIsVisible(true)
                    }
                }
//            }
        }
        
    }

}
