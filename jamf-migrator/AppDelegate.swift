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

    // allow access to previously selected folder - start
    var folderPath: URL? {
        didSet {
            do {
                let bookmark = try folderPath?.bookmarkData(options: .securityScopeAllowOnlyReadAccess, includingResourceValuesForKeys: nil, relativeTo: nil)
                UserDefaults.standard.set(bookmark, forKey: "bookmark")
            } catch let error as NSError {
                WriteToLog().message(stringOfText: "Set Bookmark Fails: \(error.description)")
            }
        }
    }
    func applicationDidFinishLaunching(_ aNotification: Notification) {
       if let bookmarkData = UserDefaults.standard.object(forKey: "bookmark") as? Data {
           do {
               var bookmarkIsStale = false
               let url = try URL.init(resolvingBookmarkData: bookmarkData as Data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &bookmarkIsStale)
               url.startAccessingSecurityScopedResource()
           } catch let error as NSError {
            WriteToLog().message(stringOfText: "Bookmark Access Fails: \(error.description)")
           }
       }
    }
    // allow access to previously selected folder - end

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
            if let url = URL(string: "https://github.com/jamf/JamfMigrator/releases") {
                    NSWorkspace.shared.open(url)
            }
        }

        //return true
    }   // func alert_dialog - end
    
    @IBAction func showPreferences(_ sender: Any) {
        PrefsWindowController().show()
    }
    
}

