//
//  Globals.swift
//  jamf-migrator
//
//  Created by Leslie Helou on 11/29/19.
//  Copyright © 2019 jamf. All rights reserved.
//

import Foundation

struct jamfProVersion {
    static var major = 0
    static var minor = 0
    static var patch = 0
}

struct dependency {
    static var wait = true
}

struct wipeData {
    static var on = false
}

struct History {
    static var logPath: String? = (NSHomeDirectory() + "/Library/Logs/jamf-migrator/")
    static var logFile = ""
}

struct LogLevel {
    static var debug = false
}

struct summaryHeader {
    static var createDelete = "create"
}

struct export {
    static var saveRawXml      = false
    static var saveTrimmedXml  = false
    static var saveOnly        = false
    static var rawXmlScope     = true
    static var trimmedXmlScope = true
}
