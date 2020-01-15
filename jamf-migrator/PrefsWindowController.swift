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
//                print("show new prefs window")
//                pwc?.showWindow(self)

                pwc?.window?.setIsVisible(true)
                
            } else {
                DispatchQueue.main.async {
                    print("[PrefsWindowController] show existing preference window")
                    
//                    pwc?.window?.orderFront(self)   // creates new window
//                    pwc?.window?.orderedIndex = 0   // creates new window
//                    pwc?.window?.center()   // nothing
//                    pwc?.window?.display()  // nothing
//                    pwc?.window?.hidesOnDeactivate = true
//                    windowShouldClose(PrefsWindowController)
//                    pwc?.window?.orderOut(self)
//                    pwc?.window?.close()
//                    pwc?.window?.setIsVisible(false)
//                    pwc?.window?.hidesOnDeactivate = false
//                    pwc?.window?.setIsVisible(true)
                    
                }
//                pwc?.close()
//                NSApp.activate(ignoringOtherApps: true)
//                pwc?.window?.makeKeyAndOrderFront(self) // this opens a second prefs window
            }
        }
        
    }

}
