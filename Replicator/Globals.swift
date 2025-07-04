//
//  Globals.swift
//  Replicator
//
//  Created by Leslie Helou on 11/29/19.
//  Copyright 2024 Jamf. All rights reserved.
//

import Cocoa
import Foundation

public let userDefaults = UserDefaults.standard
public var maxConcurrentThreads = 4
public var sourceDestListSize   = 20
//public var pendingGetCount      = 0
public var pageSize             = 1000
public let httpSuccess          = 200...299
public let fm                   = FileManager()
public var didRun               = false
public var dryRun               = false

var jamfAdminId                 = 1
var fileImport                  = false
let backupDate                  = DateFormatter()

// site copy / move pref
var sitePref                    = ""

var dependencyParentId          = 0
var createArray                 = [ObjectInfo]()

var currentObject               = ObjectInfo(endpointType: "", endPointXml: "", endPointJSON: [:], endpointCurrent: -1, endpointCount: -1, action: "", sourceEpId: -1, destEpId: "", ssIconName: "", ssIconId: "", ssIconUri: "", retry: false)

var accountDict                 = [String:String]()
//var counters                    = [String:[String:Int]]()          // summary counters of created, updated, failed, and deleted objects
//var summaryDict                 = [String:[String:[String]]]()    // summary arrays of created, updated, and failed objects
var staticSourceObjectList      = [SelectiveObject]()
var endpointInProgress          = ""     // end point currently in the POST queue (create and remove objects)
var currentEPs                  = [String:Int]()
var currentEPDict               = [String:[String:Int]]()
//let ordered_dependency_array    = ["sites", "buildings", "categories", "computergroups", "dockitems", "departments", "directorybindings", "distributionpoints", "ibeacons", "packages", "printers", "scripts", "softwareupdateservers", "networksegments"]

var nodesMigrated               = 0
var currentLDAPServers          = [String:Int]()
var createDestUrlBase           = ""

class Dependencies: NSObject {
    static let orderedArray = ["sites", "buildings", "categories", "computergroups", "dockitems", "departments", "directorybindings", "distributionpoints", "ibeacons", "packages", "printers", "scripts", "softwareupdateservers", "networksegments"]
    static var current      = [String]()
}

class SourceObjects: NSObject {
    static var list = [SelectiveObject]()
}

// source / destination array / dictionary of items
class DataArray: NSObject {
    static var source       = [String]()
    static var staticSource = [String]()
}

class AvailableObjsToMig: NSObject {
    static var byId   = [Int: String]()
    static var byName = [String: String]()
}

class ToMigrate: NSObject {
    static var total      = 0
    static var objects    = [String]()
    static var rawCount   = 0
}

class Endpoints: NSObject {
    static var countDict = [String:Int]()
    static var read      = 0
}

class AppColor: NSColor, @unchecked Sendable {
    static let schemes:[String]            = ["casper", "classic"]
    static let background:[String:CGColor] = ["casper":CGColor(red: 0x5D/255.0, green: 0x94/255.0, blue: 0x20/255.0, alpha: 1.0),
                                              "classic":CGColor(red: 0x5C/255.0, green: 0x78/255.0, blue: 0x94/255.0, alpha: 1.0)]
    static let highlight:[String:NSColor]  = ["casper":NSColor(calibratedRed: 0x8C/255.0, green:0x8E/255.0, blue:0x92/255.0, alpha:0xFF/255.0),
                                              "classic":NSColor(calibratedRed: 0x6C/255.0, green:0x86/255.0, blue:0x9E/255.0, alpha:0xFF/255.0)]
}

class UiVar: NSObject {
    static var activeTab    = ""
    static var goSender     = ""
    static var changeColor  = true
}

struct AppInfo {
    static let dict            = Bundle.main.infoDictionary!
    static let version         = dict["CFBundleShortVersionString"] as! String
    static let name            = dict["CFBundleExecutable"] as! String
    static var bookmarks       = [URL: Data]()
    static let appSupportPath   = NSHomeDirectory() + "/Library/Application Support/Replicator"
    static let bookmarksPathOld   = NSHomeDirectory() + "/Library/Application Support/jamf-migrator/bookmarks"
    static let bookmarksPath   = AppInfo.appSupportPath + "/bookmarks"
    static var settings        = [String:Any]()
    static let plistPathOld    = NSHomeDirectory() + "/Library/Application Support/jamf-migrator/settings.plist"
    static let plistPath       = AppInfo.appSupportPath + "/settings.plist"
    static let lastUserPath    = AppInfo.appSupportPath + "/lastUser.json"
    static var maskServerNames = userDefaults.integer(forKey: "maskServerNames") == 1 ? true : false

    static let userAgentHeader = "\(String(describing: name.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!))/\(AppInfo.version)"
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
    static var logPath   = (NSHomeDirectory() + "/Library/Logs/Replicator/")
    static var logFile   = ""
    static var startTime = Date()
}

@MainActor struct Iconfiles {
    static public var policyDict  = [String:[String:String]]()
    static var pendingDict        = [String:String]()
}

final class JamfProServer {
    static var majorVersion = 0
    static var minorVersion = 0
    static var patchVersion = 0
    static var version      = ["source":"", "dest":""]
    static var build        = ""
    static var source       = ""
    static var destination  = ""
    static var url          = ["source":"", "dest":""]
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
    static var sourceApiClient = ["id":"", "secret":""]
    static var destApiClient  = ["id":"", "secret":""]
    static var authCreds    = ["source":"", "dest":""]
    static var accessToken  = ["source":"", "dest":""]
    static var authExpires  = ["source":20.0, "dest":20.0]
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

struct Setting {
    static var copyScope             = true
    static var createIsRunning       = false
    static var csa                   = true // cloud services connection
    static var waitingForPackages    = false
    static var ldapId                = -1
    static var hardSetLdapId         = false
    static var migrateDependencies   = false
    static var migrate               = false
    static var objects               = [String]()
    static var onlyCopyMissing       = false
    static var onlyCopyExisting      = false
    static var fullGUI               = true
}

struct summaryHeader {
    static var createDelete = "create"
}

struct wipeData {
    static var on = false
}

public let helpText = """

Usage: /path/to/Replicator.app/Contents/MacOS/Replicator -parameter1 value(s) -parameter2 values(s)....

Note: Not all parameters have values.

Parameters:
    -export: No value needed but -objects must be used.  Exports object listed to a zipped file in the current export location (defined in the UI).  Must define a source server (-source).

    -debug: No value needed.  Enables debug mode, more verbose logging.

    -destination: Destination server.  Can be entered as either a fqdn or url.  Credentials for the destination server must be saved in the keychain for Replicator.

    -destUser: username used with the destination server for authentication.

    -migrate: No value needed.  Used if migrating objects from one server/folder to another server.  At least one migration must be performed,
                  saving credentials, between the source and destination before the command line can be successful.  Must also use -objects, -source, and -destination.

    -objects: List of objects to migrate/export.  Objects are comma separated and the list must not contain any spaces.  Order of the objects listed is not important.
                  Available objects:  sites,userextensionattributes,ldapservers,users,buildings,departments,categories,classes,jamfusers,jamfgroups,
                                      networksegments,advancedusersearches,smartusergroups,staticusergroups,api-roles,api-integrations,
                                      distributionpoints,directorybindings,diskencryptionconfigurations,dockitems,computers,softwareupdateservers,
                                      computerextensionattributes,scripts,printers,packages,smartcomputergroups,staticcomputergroups,restrictedsoftware,
                                      osxconfigurationprofiles,macapplications,patchpolicies,advancedcomputersearches,policies,
                                      mobiledeviceextensionattributes,mobiledevices,smartmobiledevicegroups,staticmobiledevicegroups,
                                      advancedmobiledevicesearches,mobiledeviceapplications,mobiledeviceconfigurationprofiles

                                      You can use 'allobjects' (without quotes) to migrate/export all objects.

    -scope: true or false.  Whether or not to migrate the scope/limitations/exclusions of an object.  Option applies to
                  anything with a scope; policies, configuration profiles, restrictions...  By default the scope is copied.

    -source: Source server or folder.  Server can be entered as either a fqdn or url.  If the path to the source folder contains a space the path must be
                  wrapped in quotes.  Credentials for the source server must be saved in the keychain for Replicator.

    -sourceUser: username used with the source server for authentication.

    -sticky: No value needed.  If used Replicator will migrate data to the same jamf cloud destination server node, provided the load balancer provides
                  the needed information.  By default sticky sessions are not used.

    ## API client options ##
    -destUseClientId: true or false.  Whether or not to use Client ID rather than username.  If set to true and -destClientId is not provided the keychain will be queried.

    -destClientId: Client ID from Jamf Pro API Roles and Clients.  If the client ID is provided, -destUseClientId is forced to true.

    -destClientSecret: Client Secret from Jamf Pro API Roles and Clients.
    
    -sourceUseClientId: true or false.  Whether or not to use Client ID rather than username.  If set to true and -sourceClientId is not provided the keychain will be queried.

    -sourceClientId: Client ID from Jamf Pro API Roles and Clients.  If the client ID is provided, -sourceUseClientId is forced to true.

    -sourceClientSecret: Client Secret from Jamf Pro API Roles and Clients.

Examples:
    Create an export of all objects:
    /path/to/Replicator.app/Contents/MacOS/Replicator -export -source your.jamfpro.server -objects allobjects

    Migrate computer configuration profiles from one server to another in debug mode:
    /path/to/Replicator.app/Contents/MacOS/Replicator -migrate -source dev.jamfpro.server -destination prod.jamfpro.server -objects osxconfigurationprofiles -debug

    Migrate smart/static groups, and computer configuration profiles from one server to the same node on another server:
    /path/to/Replicator.app/Contents/MacOS/Replicator -migrate -source dev.jamfpro.server -destination prod.jamfpro.server -objects samrtcomputergroups,staticcomputergroups,osxconfigurationprofles -sticky

    Migrate all policies, scripts, and packages from a folder to a server, without (policy) scope:
    /path/to/Replicator.app/Contents/MacOS/Replicator -migrate -source "/Users/admin/Downloads/Replicator/raw" -destination prod.jamfpro.server -objects policies,scripts,packages -scope false

    Migrate all objects from a folder to a server:
    /path/to/Replicator.app/Contents/MacOS/Replicator -migrate -source "/Users/admin/Downloads/Replicator/raw" -destination prod.jamfpro.server -objects allobjects

    Migrate buildings using an API client for the source server and username/password for the destination server:
    /path/to/Replicator.app/Contents/MacOS/Replicator -migrate -source dev.jamfpro.server -destination prod.jamfpro.server -sourceClientId 5ab18a12-ed10-4jm8-9a21-267fe765ed0b -sourceClientSecret HOojIrWyZ7HuhpnY87M90DsEWYwCEDYifVxBnW8s76NSRnpYRQdQLTqRa3nDCnD3 -objects buildings
"""

public func destinationObjectExists(_ objectName: String, objectType: String) -> Bool {
    logFunctionCall()
    switch objectType {
    case "api-roles":
        return(ApiRoles.destination.contains(where: { $0.displayName == objectName }))
    case "api-integrations":
        return(ApiIntegrations.destination.contains(where: { $0.displayName == objectName }))
    default:
        return(currentEPs[objectName] != nil)
    }
}

public func readSettings(thePath: String = "") -> [String:Any] {
    logFunctionCall()
    let settingsPath = (thePath.isEmpty) ? AppInfo.plistPath:thePath
    if LogLevel.debug { WriteToLog.shared.message("[\(#function.description)] settingsPath: \(settingsPath)") }
    if !FileManager.default.fileExists(atPath: settingsPath) {
        WriteToLog.shared.message("Error reading plist: \(settingsPath)")
        return([:])
    }
    AppInfo.settings = (NSDictionary(contentsOf: URL(fileURLWithPath: settingsPath)) as? [String : Any] ?? [:])
    if AppInfo.settings.count == 0 {
        WriteToLog.shared.message("Error reading plist: \(settingsPath)")
    }
//        print("readSettings - appInfo.settings: \(String(describing: appInfo.settings))")
    return(AppInfo.settings)
}

public func baseUrl(_ url: String, whichServer: String) -> String {
    logFunctionCall()
    var returnedUrl = ""
    
    let tmpArray: [Any] = url.components(separatedBy: "/")
    if tmpArray.count > 2 {
        returnedUrl = "\(tmpArray[0])//\(tmpArray[2])"
        if tmpArray.count > 3, let context = tmpArray[3] as? String, context.contains("?failover") == false {
            return "\(returnedUrl)/\(context)"
        }
    }
    return returnedUrl
}

public func saveSettings(settings: [String:Any]) {
    logFunctionCall()
    NSDictionary(dictionary: settings).write(toFile: AppInfo.plistPath, atomically: true)
}

public func getIconId(iconUri: String, endpoint: String) -> String {
    logFunctionCall()
    var iconId = "0"
    if iconUri != "" {
        if let index = iconUri.firstIndex(of: "=") {
            let iconId_string = iconUri.suffix(from: index).dropFirst()
//                    print("iconId_string: \(iconId_string)")
            if endpoint != "policies" {
                if let index = iconId_string.firstIndex(of: "&") {
                    iconId = String(iconId_string.prefix(upTo: index))
                }
            } else {
                iconId = String(iconId_string)
            }
        } else {
            let iconUriArray = iconUri.split(separator: "/")
            iconId = String("\(iconUriArray.last!)")
        }
    }
    return iconId
}

// replace with tagValue function?
public func getName(endpoint: String, objectXML: String) -> String {
    logFunctionCall()
    var theName: String = ""
    var dropChars: Int = 0
    if let nameTemp = objectXML.range(of: "<name>") {
        let firstPart = String(objectXML.prefix(through: nameTemp.upperBound).dropLast())
        dropChars = firstPart.count
    }
    if let nameTmp = objectXML.range(of: "</name>") {
        let nameTmp2 = String(objectXML.prefix(through: nameTmp.lowerBound))
        theName = String(nameTmp2.dropFirst(dropChars).dropLast())
    }
    return(theName)
}

// extract the value between xml tags - start
public func tagValue(xmlString:String, xmlTag:String) -> String {
    logFunctionCall()
    var rawValue = ""
    if let start = xmlString.range(of: "<\(xmlTag)>"),
        let end  = xmlString.range(of: "</\(xmlTag)", range: start.upperBound..<xmlString.endIndex) {
        rawValue.append(String(xmlString[start.upperBound..<end.lowerBound]))
    } else {
        if LogLevel.debug { WriteToLog.shared.message("[tagValue] invalid input for tagValue function or tag not found.") }
        if LogLevel.debug { WriteToLog.shared.message("\t[tagValue] tag: \(xmlTag)") }
        if LogLevel.debug { WriteToLog.shared.message("\t[tagValue] xml: \(xmlString)") }
    }
    return rawValue
}
// extract the value between xml tags - end
// extract the value between (different) tags - start
public func tagValue2(xmlString:String, startTag:String, endTag:String) -> String {
    logFunctionCall()
    var rawValue = ""
    if let start = xmlString.range(of: startTag),
        let end  = xmlString.range(of: endTag, range: start.upperBound..<xmlString.endIndex) {
        rawValue.append(String(xmlString[start.upperBound..<end.lowerBound]))
    } else {
        if LogLevel.debug { WriteToLog.shared.message("[tagValue2] Start, \(startTag), and end, \(endTag), not found.") }
    }
    return rawValue
}
//  extract the value between (different) tags - end

public func timeDiff(forWhat: String, someDate: Date = Date()) -> (Int,Int,Int,Double) {
    logFunctionCall()
    var components:DateComponents?
    switch forWhat {
    case "tokenExpires":
        components = Calendar.current.dateComponents([.second, .nanosecond], from: Date(), to: someDate)
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

    let totalSeconds = Int(components?.second! ?? 0)
    let (h,r) = totalSeconds.quotientAndRemainder(dividingBy: 3600)
    let (m,s) = r.quotientAndRemainder(dividingBy: 60)
    return(h,m,s,Double(totalSeconds))
}

func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    logFunctionCall()
    completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
}
