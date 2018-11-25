//
//  AppDelegate.swift
//  jamf-migrator
//
//  Created by Leslie N. Helou on 12/9/16.
//  Copyright © 2016 jamf. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let vc = ViewController()
    var prefWindowController: NSWindowController?

    @IBAction func checkForUpdates(_ sender: AnyObject) {
        let verCheck = VersionCheck()
        
        let appInfo = Bundle.main.infoDictionary!
        let version = appInfo["CFBundleShortVersionString"] as! String
        
        verCheck.versionCheck() {
            (result: Bool) in
            if result {
                self.alert_dialog(header: "Running Jamf Migrator: \(version)", message: "A new versions is available.", updateAvail: result)
            } else {
                self.alert_dialog(header: "Running Jamf Migrator: \(version)", message: "No updates are currently available.", updateAvail: result)
            }
        }
    }
    
    func alert_dialog(header: String, message: String, updateAvail: Bool) {
        let dialog: NSAlert = NSAlert()
        dialog.messageText = header
        dialog.informativeText = message
        dialog.alertStyle = NSAlert.Style.informational
        if updateAvail {
            dialog.addButton(withTitle: "View")
            dialog.addButton(withTitle: "Ignore")
        } else {
            dialog.addButton(withTitle: "OK")
        }
        
        let clicked:NSApplication.ModalResponse = dialog.runModal()

        if clicked.rawValue == 1000 && updateAvail {
            if let url = URL(string: "https://github.com/jamfprofessionalservices/JamfMigrator/releases") {
                    NSWorkspace.shared.open(url)
            }
        }

        //return true
    }   // func alert_dialog - end
    
    @IBAction func showPreferences(_ sender: Any) {
        if !(prefWindowController != nil) {
            let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Preferences"), bundle: nil)
            prefWindowController = storyboard.instantiateInitialController() as? NSWindowController
        }

        if (prefWindowController != nil) {
            prefWindowController?.showWindow(sender)
        }
    }
    
    // disabled to prevent multiple preference windows from opening
    func showPrefsWindow() {
        if !(prefWindowController != nil) {
            let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Preferences"), bundle: nil)
            prefWindowController = storyboard.instantiateInitialController() as? NSWindowController
        }
        if !(vc.windowIsVisible(windowName: "Copy") || vc.windowIsVisible(windowName: "Export")) {
            if (prefWindowController != nil) {
                prefWindowController?.showWindow(self)
            }
        }
    }
    
}

