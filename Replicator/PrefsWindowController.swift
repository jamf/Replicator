//
//  PrefsWindowController.swift
//  Replicator
//
//  Created by Leslie Helou on 11/25/18.
//  Copyright 2024 Jamf. All rights reserved.
//

import Cocoa

class PrefsWindowController: NSWindowController, NSWindowDelegate {
    
    var pwc: NSWindowController?
    var pvc: NSViewController?
    var ptv = PreferencesTabVC()
    
    override func windowDidLoad() {
        super.windowDidLoad()
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        DistributedNotificationCenter.default.removeObserver(self, name: .saveOnlyButtonToggle, object: nil)
        self.window?.orderOut(sender)
        return false
    }
    
    func show() {
        var prefsVisible = false
        let tabs = ["Copy", "Export", "Site", "App", "Computer", "Password"]
        
        if !(pwc != nil) {
            let storyboard = NSStoryboard(name: "Preferences", bundle: nil)
            pwc = storyboard.instantiateInitialController() as? NSWindowController
        }

        if (pwc != nil) {
            DispatchQueue.main.async { [self] in
                let windowsCount = NSApp.windows.count
                for i in (0..<windowsCount) {
                    if tabs.firstIndex(of: NSApp.windows[i].title) != nil {
                        print("window title: \(NSApp.windows[i].title)")
                        print("SitePreferences.show: \(SitePreferences.show)")
                        if SitePreferences.show {
                            print("close preferences")
                            NSApp.windows[i].orderOut(self)
                        } else {NSApp.windows[i].makeKeyAndOrderFront(self)
                            print("is visible preferences")
                            prefsVisible = true
                        }
                    }
                }
                if !prefsVisible {
                    pwc?.window?.setIsVisible(true)
                }
            }
        }
    }
}
