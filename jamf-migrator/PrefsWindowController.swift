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
                pwc?.showWindow(self)
            } else {
                pwc?.window?.makeKeyAndOrderFront(self)
//                self.window?.makeKey()
//                PreferencesViewController().view.window?.becomeFirstResponder()
//                DispatchQueue.main.async {
//                    PreferencesViewController().view.window?.makeKeyAndOrderFront(self)
//                }
//                pwc?.close()
//                PrefsWindowController().close()
//                print("[PreferenceWindowController] pref window already visible, bring to front - close/reopen")
            }
        }
        
    }

}
