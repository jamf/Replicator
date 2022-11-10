//
//  Globals.swift
//  jamf-migrator
//
//  Created by Leslie Helou on 11/29/19.
//  Copyright © 2019 jamf. All rights reserved.
//

import Cocoa
import Foundation

class appColor: NSColor {
    static let schemes:[String]            = ["casper", "classic"]
    static let background:[String:CGColor] = ["casper":CGColor(red: 0x5D/255.0, green: 0x94/255.0, blue: 0x20/255.0, alpha: 1.0),
                                              "classic":CGColor(red: 0x5C/255.0, green: 0x78/255.0, blue: 0x94/255.0, alpha: 1.0)]
    static let highlight:[String:NSColor]  = ["casper":NSColor(calibratedRed: 0x8C/255.0, green:0x8E/255.0, blue:0x92/255.0, alpha:0xFF/255.0),
                                              "classic":NSColor(calibratedRed: 0x6C/255.0, green:0x86/255.0, blue:0x9E/255.0, alpha:0xFF/255.0)]
}

struct appInfo {
    static let dict            = Bundle.main.infoDictionary!
    static let version         = dict["CFBundleShortVersionString"] as! String
    static let name            = dict["CFBundleExecutable"] as! String
    static var bookmarks       = [URL: Data]()
    static let bookmarksPath   = NSHomeDirectory() + "/Library/Application Support/jamf-migrator/bookmarks"
    static var settings        = [String:Any]()
    static let plistPath       = NSHomeDirectory() + "/Library/Application Support/jamf-migrator/settings.plist"

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
}

struct iconfiles {
    static public var policyDict  = [String:[String:String]]()
    static var pendingDict        = [String:String]()
}

struct JamfProServer {
    static var majorVersion = 0
    static var minorVersion = 0
    static var patchVersion = 0
    static var version      = ["source":"", "destination":""]
    static var build        = ""
    static var source       = ""
    static var destination  = ""
    static var whichServer  = ""
    static var sourceUser   = ""
    static var destUser     = ""
    static var sourcePwd    = ""
    static var destPwd      = ""
    static var storeCreds   = 0
    static var toSite       = false
    static var destSite     = ""
    static var importFiles  = 0
    static var authCreds    = ["source":"", "destination":""]
    static var authExpires  = ["source":"", "destination":""]
    static var authType     = ["source":"Bearer", "destination":"Bearer"]
    static var base64Creds  = ["source":"", "destination":""]               // used if we want to auth with a different account
    static var validToken   = ["source":false, "destination":false]
    static var tokenCreated = [String:Date?]()
    static var pkgsNotFound = 0
    static var sessionCookie = [HTTPCookie]()
    static var stickySession = false
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
    static var refreshInterval:UInt32 = 20*60  // 20 minutes
}

struct wipeData {
    static var on = false
}

public func readSettings() -> [String:Any] {
    appInfo.settings = (NSDictionary(contentsOf: URL(fileURLWithPath: appInfo.plistPath)) as? [String : Any])!
    if appInfo.settings.count == 0 {
        if LogLevel.debug { WriteToLog().message(stringOfText: "Error reading plist: \(appInfo.plistPath)\n") }
    }
//        print("readSettings - appInfo.settings: \(String(describing: appInfo.settings))\n")
    return(appInfo.settings)
}

public func saveSettings(settings: [String:Any]) {
    NSDictionary(dictionary: settings).write(toFile: appInfo.plistPath, atomically: true)
}

public func storeBookmark(theURL: URL) {
    appInfo.bookmarks = NSKeyedUnarchiver.unarchiveObject(withFile: appInfo.bookmarksPath) as? [URL: Data] ?? [:]
    do {
        let data = try theURL.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        appInfo.bookmarks[theURL] = data
        NSKeyedArchiver.archiveRootObject(appInfo.bookmarks, toFile: appInfo.bookmarksPath)
    } catch let error as NSError {
        WriteToLog().message(stringOfText: "[Global] Set Bookmark Failed: \(error.description)\n")
    }
}

public func timeDiff(forWhat: String) -> (Int,Int,Int) {
    var components:DateComponents?
    switch forWhat {
    case "runTime":
        components = Calendar.current.dateComponents([.second, .nanosecond], from: History.startTime, to: Date())
    case "sourceTokenAge","destTokenAge":
        if forWhat == "sourceTokenAge" {
            components = Calendar.current.dateComponents([.second, .nanosecond], from: (JamfProServer.tokenCreated["source"] ?? Date())!, to: Date())
        } else {
            components = Calendar.current.dateComponents([.second, .nanosecond], from: (JamfProServer.tokenCreated["destination"] ?? Date())!, to: Date())
        }
    default:
        break
    }
//          let timeDifference = Double(components.second!) + Double(components.nanosecond!)/1000000000
//          WriteToLog().message(stringOfText: "[Migration Complete] runtime: \(timeDifference) seconds\n")
    let timeDifference = Int(components?.second! ?? 0)
    let (h,r) = timeDifference.quotientAndRemainder(dividingBy: 3600)
    let (m,s) = r.quotientAndRemainder(dividingBy: 60)
    return(h,m,s)
}
