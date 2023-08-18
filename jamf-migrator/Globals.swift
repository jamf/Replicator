//
//  Globals.swift
//  jamf-migrator
//
//  Created by Leslie Helou on 11/29/19.
//  Copyright © 2019 jamf. All rights reserved.
//

import Cocoa
import Foundation

public let userDefaults = UserDefaults.standard

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
    static var version      = ["source":"", "dest":""]
    static var build        = ""
    static var source       = ""
    static var destination  = ""
    static var whichServer  = ""
    static var sourceUser   = ""
    static var destUser     = ""
    static var sourcePwd    = ""
    static var destPwd      = ""
    static var storeSourceCreds = 0
    static var storeDestCreds   = 0
    static var sourceUseApiClient  = 0
    static var destUseApiClient    = 0
    static var toSite       = false
    static var destSite     = ""
    static var importFiles  = 0
    static var sourceApiClient  = ["id":"", "secret":""]
    static var destApiClient  = ["id":"", "secret":""]
    static var authCreds    = ["source":"", "dest":""]
    static var authExpires  = ["source":30, "dest":30]
    static var authType     = ["source":"Bearer", "dest":"Bearer"]
    static var base64Creds  = ["source":"", "dest":""]               // used if we want to auth with a different account
    static var validToken   = ["source":false, "dest":false]
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
    static var copyScope             = true
    static var createIsRunning       = false
    static var csa                   = true // cloud services connection
    static var waitingForPackages    = false
    static var ldapId                = -1
    static var hardSetLdapId         = false
    static var migrateDependencies   = false
    static var migrate               = false
    static var objects               = [String]()
    static var fullGUI               = true
}

struct summaryHeader {
    static var createDelete = "create"
}

struct token {
    static var refreshInterval:UInt32 = 29*60  // 29 minutes
}

struct wipeData {
    static var on = false
}

public let helpText = """

Usage: /path/to/jamf-migrator.app/Contents/MacOS/jamf-migrator -parameter1 value(s) -parameter2 values(s)....

Note: Not all parameters have values.

Parameters:
         -export: No value needed but -objects must be used.  Exports object listed to a zipped file in the current export location (defined in the UI).  Must define a source server (-source).

          -debug: No value needed.  Enables debug mode, more verbose logging.

    -destination: Destination server.  Can be entered as either a fqdn or url.  Credentials for the destination server must be saved in the keychain for jamf migrator.

        -migrate: No value needed.  Used if migrating objects from one server/folder to another server.  At least one migration must be performed,
                  saving credentials, between the source and destination before the command line can be successful.  Must also use -objects, -source, and -destination.

        -objects: List of objects to migrate.  Objects are comma separated and the list must not contain any spaces.  Order of the objects listed is not important.
                  Available objects:  sites,userextensionattributes,ldapservers,users,buildings,departments,categories,classes,jamfusers,jamfgroups,
                                      networksegments,advancedusersearches,smartusergroups,staticusergroups,
                                      distributionpoints,directorybindings,diskencryptionconfigurations,dockitems,computers,softwareupdateservers,
                                      computerextensionattributes,scripts,printers,packages,smartcomputergroups,staticcomputergroups,restrictedsoftware,
                                      osxconfigurationprofiles,macapplications,patchpolicies,advancedcomputersearches,policies,
                                      mobiledeviceextensionattributes,mobiledevices,smartmobiledevicegroups,staticmobiledevicegroups,
                                      advancedmobiledevicesearches,mobiledeviceapplications,mobiledeviceconfigurationprofiles

                                      You can use 'allobjects' (without quotes) to migrate all objects.

          -scope: true or false.  Whether or not to migrate the scope/limitations/exclusions of an object.  Option applies to
                  anything with a scope; policies, configuration profiles, restrictions...  By default the scope is copied.

         -source: Source server or folder.  Server can be entered as either a fqdn or url.  If the path to the source folder contains a space the path must be
                  wrapped in quotes.  Credentials for the source server must be saved in the keychain for jamf migrator.

         -sticky: No value needed.  If used jamf migrator will migrate data to the same jamf cloud destination server node, provided the load balancer provides
                  the needed information.  By default sticky sessions are not used.

Examples:
    Create an export of all objects:
    /path/to/jamf-migrator.app/Contents/MacOS/jamf-migrator -export -source your.jamfpro.server -objects allobjects

    Migrate computer configuration profiles from one server to another in debug mode:
    /path/to/jamf-migrator.app/Contents/MacOS/jamf-migrator -migrate -source dev.jamfpro.server -destination prod.jamfpro.server -objects osxconfigurationprofiles -debug

    Migrate smart/static groups, and computer configuration profiles from one server to the same node on another server:
    /path/to/jamf-migrator.app/Contents/MacOS/jamf-migrator -migrate -source dev.jamfpro.server -destination prod.jamfpro.server -objects samrtcomputergroups,staticcomputergroups,osxconfigurationprofles -sticky

    Migrate all policies, scripts, and packages from a folder to a server, without (policy) scope:
    /path/to/jamf-migrator.app/Contents/MacOS/jamf-migrator -migrate -source "/Users/admin/Downloads/Jamf Migrator/raw" -destination prod.jamfpro.server -objects policies,scripts,packages -scope false

    Migrate all objects from a folder to a server:
    /path/to/jamf-migrator.app/Contents/MacOS/jamf-migrator -migrate -source "/Users/admin/Downloads/Jamf Migrator/raw" -destination prod.jamfpro.server -objects allobjects


"""

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
    print("[\(#line)-storeBookmark] store \(theURL) in \(appInfo.bookmarksPath)")
    appInfo.bookmarks = NSKeyedUnarchiver.unarchiveObject(withFile: appInfo.bookmarksPath) as? [URL: Data] ?? [:]
    print("[\(#line)-storeBookmark] current bookmarks:")
    for (theBookmark,_) in appInfo.bookmarks {
        print("[\(#line)-storeBookmark] \(theBookmark)")
    }
    do {
        let data = try theURL.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        appInfo.bookmarks[theURL] = data
        NSKeyedArchiver.archiveRootObject(appInfo.bookmarks, toFile: appInfo.bookmarksPath)
    } catch let error as NSError {
        WriteToLog().message(stringOfText: "[Global] Set Bookmark Failed: \(error.description)\n")
    }
}

// extract the value between xml tags - start
public func tagValue(xmlString:String, xmlTag:String) -> String {
    var rawValue = ""
    if let start = xmlString.range(of: "<\(xmlTag)>"),
        let end  = xmlString.range(of: "</\(xmlTag)", range: start.upperBound..<xmlString.endIndex) {
        rawValue.append(String(xmlString[start.upperBound..<end.lowerBound]))
    } else {
        if LogLevel.debug { WriteToLog().message(stringOfText: "[tagValue] invalid input for tagValue function or tag not found.\n") }
        if LogLevel.debug { WriteToLog().message(stringOfText: "\t[tagValue] tag: \(xmlTag)\n") }
        if LogLevel.debug { WriteToLog().message(stringOfText: "\t[tagValue] xml: \(xmlString)\n") }
    }
    return rawValue
}
//  extract the value between xml tags - end
// extract the value between (different) tags - start
public func tagValue2(xmlString:String, startTag:String, endTag:String) -> String {
    var rawValue = ""
    if let start = xmlString.range(of: startTag),
        let end  = xmlString.range(of: endTag, range: start.upperBound..<xmlString.endIndex) {
        rawValue.append(String(xmlString[start.upperBound..<end.lowerBound]))
    } else {
        if LogLevel.debug { WriteToLog().message(stringOfText: "[tagValue2] Start, \(startTag), and end, \(endTag), not found.\n") }
    }
    return rawValue
}
//  extract the value between (different) tags - end

public func timeDiff(forWhat: String) -> (Int,Int,Int) {
    var components:DateComponents?
    switch forWhat {
    case "runTime":
        components = Calendar.current.dateComponents([.second, .nanosecond], from: History.startTime, to: Date())
    case "sourceTokenAge","destTokenAge":
        if forWhat == "sourceTokenAge" {
            components = Calendar.current.dateComponents([.second, .nanosecond], from: (JamfProServer.tokenCreated["source"] ?? Date())!, to: Date())
        } else {
            components = Calendar.current.dateComponents([.second, .nanosecond], from: (JamfProServer.tokenCreated["dest"] ?? Date())!, to: Date())
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

func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(  URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
}
