//
//  Alert.swift
//  jamf-migrator
//
//  Created by lnh on 12/22/21.
//  Copyright © 2016 jamf. All rights reserved.
//

import Cocoa

class Alert: NSObject {
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
}
