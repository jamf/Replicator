//
//  Alert.swift
//  Replicator
//
//  Created by lnh on 12/22/21.
//  Copyright 2024 Jamf. All rights reserved.
//

import Cocoa

class Alert: NSObject {
    
    static let shared = Alert()
    
    func display(header: String, message: String, secondButton: String) -> String {
        NSApplication.shared.activate(ignoringOtherApps: true)
        var selected = ""
        let dialog: NSAlert = NSAlert()
        dialog.messageText = header
        dialog.informativeText = message
        dialog.alertStyle = NSAlert.Style.warning
        if secondButton != "" {
            let otherButton = dialog.addButton(withTitle: secondButton)
            otherButton.keyEquivalent = "\r"
        }
        let okButton = dialog.addButton(withTitle: "OK")
        okButton.keyEquivalent = "o"
        
        let theButton = dialog.runModal()
        switch theButton {
        case .alertFirstButtonReturn:
            selected = secondButton
        default:
            selected = "OK"
        }
        return selected
    }
    
    func versionDialog(header: String, message: String, updateAvail: Bool, manualCheck: Bool = false) {
        NSApp.activate(ignoringOtherApps: true)
        if userDefaults.bool(forKey: "hideVersionAlert") == false || manualCheck {
            let dialog: NSAlert = NSAlert()
            dialog.messageText = header
            dialog.informativeText = message
            dialog.alertStyle = NSAlert.Style.informational
            dialog.showsSuppressionButton = !manualCheck
            if updateAvail {
                dialog.addButton(withTitle: "View")
                dialog.addButton(withTitle: "Later")
            } else {
                dialog.addButton(withTitle: "OK")
            }
            
            let clicked:NSApplication.ModalResponse = dialog.runModal()
            
            if let supress = dialog.suppressionButton {
                let state = supress.state
                switch state {
                case .on:
                    userDefaults.set(true, forKey: "hideVersionAlert")
                default: break
                }
            }
            
            if clicked.rawValue == 1000 && updateAvail {
                if let url = URL(string: "https://github.com/jamf/Replicator/releases") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}
