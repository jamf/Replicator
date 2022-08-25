//
//  Globals.swift
//  jamf-migrator
//
//  Created by Leslie Helou on 11/29/19.
//  Copyright © 2019 jamf. All rights reserved.
//

import Foundation

struct appInfo {
    static let dict    = Bundle.main.infoDictionary!
    static let version = dict["CFBundleShortVersionString"] as! String
    static let name    = dict["CFBundleExecutable"] as! String

    static let userAgentHeader = "\(String(describing: name.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!))/\(appInfo.version)"
}

struct dependency {
    static var isRunning = false
}

struct export {
    static var saveRawXml      = false
    static var saveTrimmedXml  = false
    static var saveOnly        = false
    static var rawXmlScope     = true
    static var trimmedXmlScope = true
    static var backupMode      = false
    static var saveLocation    = ""
}

struct History {
    static var logPath: String? = (NSHomeDirectory() + "/Library/Logs/jamf-migrator/")
    static var logFile          = ""
    static var startTime        = Date()
    static var endTime          = Date()
}

struct iconfiles {
    static public var policyDict  = [String:[String:String]]()
    static var pendingDict        = [String:String]()
}

struct JamfProServer {
    static var majorVersion = 0
    static var minorVersion = 0
    static var patchVersion = 0
    static var build        = ""
    static var source       = ""
    static var destination  = ""
    static var authCreds    = ["source":"", "destination":""]
    static var authExpires  = ["source":"", "destination":""]
    static var authType     = ["source":"Bearer", "destination":"Bearer"]
    static var base64Creds  = ["source":"", "destination":""]               // used if we want to auth with a different account
    static var validToken   = ["source":false, "destination":false]
    static var version      = ["source":"", "destination":""]
    static var pkgsNotFound = 0
}

struct LogLevel {
    static var debug = false
}

struct migrationComplete {
    static var isDone = false
}

struct pref {
    static var migrateAsManaged  = 0
    static var mgmtAcct          = ""
    static var mgmtPwd           = ""
    static var removeCA_ID       = 0
    static var stopMigration     = false
    static var concurrentThreads = 2
    static let httpSuccess       = 200...299
}

struct q {
    static var getRecord = OperationQueue() // create operation queue for API GET calls
}

struct setting {
    static var createIsRunning       = false
    static var waitingForPackages    = false
    static var ldapId                = -1
    static var hardSetLdapId         = false
    static var migrateDependencies   = false
    static var csa                   = true // cloud services connection
    static var fullGUI               = true
}

struct summaryHeader {
    static var createDelete = "create"
}

struct token {
    static var refreshInterval:UInt32 = 15*60  // 15 minutes (15*60)
}

struct wipeData {
    static var on = false
}
