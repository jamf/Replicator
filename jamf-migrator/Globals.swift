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

struct iconfiles {
    static public var policyDict  = [String:[String:String]]()
    static var pendingDict        = [String:String]()
}

struct migrationComplete {
    static var isDone = false
}

struct wipeData {
    static var on = false
}

struct History {
    static var logPath: String? = (NSHomeDirectory() + "/Library/Logs/jamf-migrator/")
    static var logFile     = ""
    static var startTime   = Date()
    static var endTime     = Date()
}

struct LogLevel {
    static var debug = false
}

struct summaryHeader {
    static var createDelete = "create"
}

struct appInfo {
    static let dict    = Bundle.main.infoDictionary!
    static let version = dict["CFBundleShortVersionString"] as! String
}

struct export {
    static var saveRawXml      = false
    static var saveTrimmedXml  = false
    static var saveOnly        = false
    static var rawXmlScope     = true
    static var trimmedXmlScope = true
}

struct pref {
    static var migrateAsManaged  = 0
    static var mgmtAcct          = ""
    static var mgmtPwd           = ""
    static var removeCA_ID       = 0
    static var stopMigration     = false
    static var concurrentThreads = 5
}

struct q {
    static var getRecord = OperationQueue() // create operation queue for API GET calls
}

struct setting {
    static var uapiToken = ""
}
