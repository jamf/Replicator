//
//  ViewController.swift
//  Jamf Transporter
//
//  Created by lnh on 12/9/16.
//  Copyright 2024 Jamf. All rights reserved.
//

import AppKit
import Cocoa
import Foundation

final class Counter {
    static let shared = Counter()

    private let counterQueue = DispatchQueue(label: "counter.queue", qos: .default, attributes: .concurrent)
    private var _dependencyMigrated = [Int: Int]()
    private var _pendingGet  = 1
    private var _pendingSend = 1
    private var _post = 1

    private init() {}

    // Counter.shared.dependencyMigrated
    var dependencyMigrated: [Int: Int] {
        get {
            var dependencyMigrated: [Int: Int] = [:]
            counterQueue.sync {
                dependencyMigrated = _dependencyMigrated
            }
            return dependencyMigrated
        }
        set {
            counterQueue.async(flags: .barrier) {
                self._dependencyMigrated = newValue
            }
        }
    }
    
    // Counter.shared.pendingGet
    var pendingGet: Int {
        get {
            var pendingGet: Int?
            counterQueue.sync {
                pendingGet = _pendingGet
            }
            return pendingGet ?? 1
        }
        set {
            counterQueue.async(flags: .barrier) {
                self._pendingGet = newValue
            }
        }
    }
    
    // Counter.shared.pendingSend
    var pendingSend: Int {
        get {
            var pendingSend: Int?
            counterQueue.sync {
                pendingSend = _pendingSend
            }
            return pendingSend ?? 1
        }
        set {
            counterQueue.async(flags: .barrier) {
                self._pendingSend = newValue
            }
        }
    }
    
    // Counter.shared.post
    var post: Int {
        get {
            var post: Int?
            counterQueue.sync {
                post = _post
            }
            return post ?? 1
        }
        set {
            counterQueue.async(flags: .barrier) {
                self._post = newValue
            }
        }
    }
}


final class ExistingEndpoints {
    static let shared = ExistingEndpoints()

    private let existingQueue = DispatchQueue(label: "existing.endpoints", qos: .default, attributes: .concurrent)
    private var _completed = 0
    private var _waiting   = false
    private var _packageGetsPending = 0

    private init() {}

    var completed: Int {
        get {
            var completed: Int?
            existingQueue.sync {
                completed = _completed
            }
            return completed ?? 0
        }
        set {
            existingQueue.async(flags: .barrier) {
                self._completed = newValue
            }
        }
    }
    var waiting: Bool {
        get {
            var waiting = false
            existingQueue.sync {
                waiting = _waiting
            }

            return waiting
        }
        set {
            existingQueue.async(flags: .barrier) {
                self._waiting = newValue
            }
        }
    }
}

final class PutLevelIndicator {
    static let shared = PutLevelIndicator()

    private let putIndicatorQueue = DispatchQueue(label: "indicator.color", qos: .default, attributes: .concurrent)
    private var _indicatorColor = [String: NSColor]()
    
    var indicatorColor: [String: NSColor] {
        get {
            var indicatorColor: [String: NSColor] = [:]
            putIndicatorQueue.sync {
                indicatorColor = _indicatorColor
            }

            return indicatorColor
        }
        set {
            putIndicatorQueue.async(flags: .barrier) {
                self._indicatorColor = newValue
            }
        }
    }
}

class ObjectInfo: NSObject {
    @objc var endpointType    : String
    @objc var endPointXml     : String
    @objc var endPointJSON    : [String:Any]
    @objc var endpointCurrent : Int
    @objc var endpointCount   : Int
    @objc var action          : String
    @objc var sourceEpId      : Int
    @objc var destEpId        : Int
    @objc var ssIconName      : String
    @objc var ssIconId        : String
    @objc var ssIconUri       : String
    @objc var retry           : Bool
    
    init(endpointType: String, endPointXml: String, endPointJSON: [String:Any], endpointCurrent: Int, endpointCount: Int, action: String, sourceEpId: Int, destEpId: Int, ssIconName: String, ssIconId: String, ssIconUri: String, retry: Bool) {
        self.endpointType    = endpointType
        self.endPointXml     = endPointXml
        self.endPointJSON    = endPointJSON
        self.endpointCurrent = endpointCurrent
        self.endpointCount   = endpointCount
        self.action          = action
        self.sourceEpId      = sourceEpId
        self.destEpId        = destEpId
        self.ssIconName      = ssIconName
        self.ssIconId        = ssIconId
        self.ssIconUri       = ssIconUri
        self.retry           = retry
    }
}

class SelectiveObject: NSObject {
    @objc var objectName:   String
    @objc var objectId:     String
    @objc var fileContents: String
    
    init(objectName: String, objectId: String, fileContents: String) {
        self.objectName   = objectName
        self.objectId     = objectId
        self.fileContents = fileContents
    }
}

protocol SendMessageDelegate: AnyObject {
    func sendMessage(_ message: String)
}

class ViewController: NSViewController, URLSessionDelegate, NSTabViewDelegate, NSTableViewDelegate, NSTableViewDataSource, NSTextFieldDelegate, SendMessageDelegate {
    
    func sendMessage(_ message: String) {
        print("[sendMessage] message: \(message)")
        message_TextField.stringValue = message
    }
    
    private let lockQueue = DispatchQueue(label: "lock.queue")
    private let putStatusLockQueue = DispatchQueue(label: "putStatusLock.queue")
    
    @IBOutlet weak var selectiveFilter_TextField: NSTextField!
    
    // selective list filter
    func controlTextDidChange(_ obj: Notification) {
        if let textField = obj.object as? NSTextField {
            if textField.identifier!.rawValue == "search" {
                let filter = selectiveFilter_TextField.stringValue
//                print("filter: \(filter)")
                let textPredicate = ( filter == "" ) ? NSPredicate(format: "objectName.length > 0"):NSPredicate(format: "objectName CONTAINS[c] %@", filter)
                
                sourceObjectList_AC.filterPredicate = textPredicate
                self.selectiveListCleared = true
            }
        }
    }
    
    @IBAction func clearFilter_Action(_ sender: Any) {
        selectiveFilter_TextField.stringValue = ""
        let textPredicate = NSPredicate(format: "objectName.length > 0")
        sourceObjectList_AC.filterPredicate = textPredicate
    }
    
    
    // Main Window
    @IBOutlet var migrator_window: NSView!
    @IBOutlet weak var modeTab_TabView: NSTabView!
    
    // Import/export file variables
    var importFilesUrl   = URL(string: "")
    var exportedFilesUrl = URL(string: "")

    var availableFilesToMigDict = [String:[String]]()   // something like xmlID, xmlName
    var displayNameToFilename   = [String: String]()
    
    @IBOutlet weak var objectsToSelect: NSScrollView!
    
    // determine if we're using dark mode
    var isDarkMode: Bool {
        let mode = userDefaults.string(forKey: "AppleInterfaceStyle")
        return mode == "Dark"
    }
    
    // Help Window
    @IBAction func showHelpWindow(_ sender: AnyObject) {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let helpWindowController = storyboard.instantiateController(withIdentifier: "Help View Controller") as! NSWindowController
        if !windowIsVisible(windowName: "Help") {
            helpWindowController.window?.hidesOnDeactivate = false
            helpWindowController.showWindow(self)
        } else {
            let windowsCount = NSApp.windows.count
            for i in (0..<windowsCount) {
                if NSApp.windows[i].title == "Help" {
                    NSApp.windows[i].makeKeyAndOrderFront(self)
                    break
                }
            }
        }
    }
    
    // Show Preferences Window
    @IBAction func showPrefsWindow(_ sender: Any) {
        if NSEvent.modifierFlags.contains(.option) {
//            isDir = true
            let settingsFolder = AppInfo.plistPath.replacingOccurrences(of: "settings.plist", with: "")
            if (fm.fileExists(atPath: settingsFolder)) {
//                NSWorkspace.shared.openFile(settingsFolder)
                NSWorkspace.shared.open(URL(fileURLWithPath: settingsFolder))
            } else {
                alert_dialog(header: "Alert", message: "Unable to open \(settingsFolder)")
            }
        } else {
            PrefsWindowController().show()
        }
    }

    // keychain access
    let Creds2           = Credentials()
    var validCreds       = true     // used to deterine if keychain has valid credentials
    var storedSourceUser = ""       // source user account stored in the keychain
    var storedSourcePwd  = ""       // source user account password stored in the keychain
    var storedDestUser   = ""       // destination user account stored in the keychain
    var storedDestPwd    = ""       // destination user account password stored in the keychain
        
    // Buttons
    // general tab
    @IBOutlet weak var allNone_general_button: NSButton!
    @IBOutlet weak var advusersearch_button: NSButton!
    @IBOutlet weak var building_button: NSButton!
    @IBOutlet weak var categories_button: NSButton!
    @IBOutlet weak var classes_button: NSButton!
    @IBOutlet weak var dept_button: NSButton!
    @IBOutlet weak var userEA_button: NSButton!
    @IBOutlet weak var sites_button: NSButton!
    @IBOutlet weak var ldapservers_button: NSButton!
    @IBOutlet weak var networks_button: NSButton!
    @IBOutlet weak var users_button: NSButton!
    @IBOutlet weak var smartUserGrps_button: NSButton!
    @IBOutlet weak var staticUserGrps_button: NSButton!
    @IBOutlet weak var jamfUserAccounts_button: NSButton!
    @IBOutlet weak var jamfGroupAccounts_button: NSButton!
    // macOS tab
    @IBOutlet weak var advcompsearch_button: NSButton!
    @IBOutlet weak var macapplications_button: NSButton!
    @IBOutlet weak var computers_button: NSButton!
    @IBOutlet weak var directory_bindings_button: NSButton!
    @IBOutlet weak var disk_encryptions_button: NSButton!
    @IBOutlet weak var dock_items_button: NSButton!
    @IBOutlet weak var fileshares_button: NSButton!
    @IBOutlet weak var sus_button: NSButton!
//    @IBOutlet weak var netboot_button: NSButton!
    @IBOutlet weak var osxconfigurationprofiles_button: NSButton!
    @IBOutlet weak var patch_mgmt_button: NSButton!
    @IBOutlet weak var patch_policies_button: NSButton! // unused
    @IBOutlet weak var ext_attribs_button: NSButton!
    @IBOutlet weak var scripts_button: NSButton!
    @IBOutlet weak var smart_comp_grps_button: NSButton!
    @IBOutlet weak var static_comp_grps_button: NSButton!
    @IBOutlet weak var packages_button: NSButton!
    @IBOutlet weak var printers_button: NSButton!
    @IBOutlet weak var policies_button: NSButton!
    @IBOutlet weak var restrictedsoftware_button: NSButton!
    @IBOutlet weak var macPrestages_button: NSButton!
    // iOS tab
    @IBOutlet weak var mobiledevices_button: NSButton!
    @IBOutlet weak var mobiledeviceconfigurationprofiles_button: NSButton!
    @IBOutlet weak var mobiledeviceextensionattributes_button: NSButton!
    @IBOutlet weak var mobiledevicecApps_button: NSButton!
    @IBOutlet weak var smart_ios_groups_button: NSButton!
    @IBOutlet weak var static_ios_groups_button: NSButton!
    @IBOutlet weak var advancedmobiledevicesearches_button: NSButton!
    @IBOutlet weak var iosPrestages_button: NSButton!
    
    var smartUserGrpsSelected      = false
    var staticUserGrpsSelected     = false
    var smartComputerGrpsSelected  = false
    var staticComputerGrpsSelected = false
    var smartIosGrpsSelected       = false
    var staticIosGrpsSelected      = false
    var jamfUserAccountsSelected   = false
    var jamfGroupAccountsSelected  = false
    
    @IBOutlet weak var sourceServerList_button: NSPopUpButton!
    @IBOutlet weak var destServerList_button: NSPopUpButton!
    @IBOutlet weak var siteMigrate_button: NSButton!
    @IBOutlet weak var availableSites_button: NSPopUpButtonCell!
    
    var itemToSite      = false
    var destinationSite = ""
    
    @IBOutlet weak var destinationLabel_TextField: NSTextField!
    @IBOutlet weak var destinationMethod_TextField: NSTextField!
    
    @IBOutlet weak var quit_button: NSButton!
    @IBOutlet weak var go_button: NSButton!
    @IBOutlet weak var stop_button: NSButton!
    
    // Migration mode/platform tabs/var
    @IBOutlet weak var bulk_tabViewItem: NSTabViewItem! // bulk_tabViewItem.tabState.rawValue = 0 if active, 1 if not active
    @IBOutlet weak var selective_tabViewItem: NSTabViewItem!
    @IBOutlet weak var bulk_iOS_tabViewItem: NSTabViewItem!
    @IBOutlet weak var general_tabViewItem: NSTabViewItem!
    @IBOutlet weak var macOS_tabViewItem: NSTabViewItem!
    @IBOutlet weak var iOS_tabViewItem: NSTabViewItem!
    @IBOutlet weak var activeTab_TabView: NSTabView!    // macOS, iOS, general, or selective
    
    @IBOutlet weak var sectionToMigrate_button: NSPopUpButton!
    @IBOutlet weak var iOSsectionToMigrate_button: NSPopUpButton!
    @IBOutlet weak var generalSectionToMigrate_button: NSPopUpButton!
    
    var migrationMode = ""  // either buld or selective
    
    var platform = ""  // either macOS, iOS, or general
    
    var goSender = ""
    
    // button labels
    // macOS button labels
    @IBOutlet weak var advcompsearch_label_field: NSTextField!
    @IBOutlet weak var macapplications_label_field: NSTextField!
    @IBOutlet weak var computers_label_field: NSTextField!
    @IBOutlet weak var directory_bindings_field: NSTextField!
    @IBOutlet weak var disk_encryptions_field: NSTextField!
    @IBOutlet weak var dock_items_field: NSTextField!
    @IBOutlet weak var file_shares_label_field: NSTextField!
    @IBOutlet weak var sus_label_field: NSTextField!
//    @IBOutlet weak var netboot_label_field: NSTextField!
    @IBOutlet weak var osxconfigurationprofiles_label_field: NSTextField!
//    @IBOutlet weak var patch_mgmt_field: NSTextField!
    @IBOutlet weak var patch_policies_field: NSTextField!
    @IBOutlet weak var extension_attributes_label_field: NSTextField!
    @IBOutlet weak var scripts_label_field: NSTextField!
    @IBOutlet weak var smart_groups_label_field: NSTextField!
    @IBOutlet weak var static_groups_label_field: NSTextField!
    @IBOutlet weak var packages_label_field: NSTextField!
    @IBOutlet weak var printers_label_field: NSTextField!
    @IBOutlet weak var policies_label_field: NSTextField!
    @IBOutlet weak var jamfUserAccounts_field: NSTextField!
    @IBOutlet weak var jamfGroupAccounts_field: NSTextField!
    @IBOutlet weak var restrictedsoftware_label_field: NSTextField!
    @IBOutlet weak var macPrestages_label_field: NSTextField!
    @IBOutlet weak var uploadingIcons_textfield: NSTextField!
    // iOS button labels
    @IBOutlet weak var smart_ios_groups_label_field: NSTextField!
    @IBOutlet weak var static_ios_groups_label_field: NSTextField!
    @IBOutlet weak var mobiledeviceconfigurationprofile_label_field: NSTextField!
    @IBOutlet weak var mobiledeviceextensionattributes_label_field: NSTextField!
    @IBOutlet weak var mobiledevices_label_field: NSTextField!
    @IBOutlet weak var mobiledeviceApps_label_field: NSTextField!
    @IBOutlet weak var advancedmobiledevicesearches_label_field: NSTextField!
    @IBOutlet weak var mobiledevicePrestage_label_field: NSTextField!
    @IBOutlet weak var uploadingIcons2_textfield: NSTextField!
    // general button labels
    @IBOutlet weak var advusersearch_label_field: NSTextField!
    @IBOutlet weak var building_label_field: NSTextField!
    @IBOutlet weak var categories_label_field: NSTextField!
    @IBOutlet weak var departments_label_field: NSTextField!
    @IBOutlet weak var userEA_label_field: NSTextField!
    @IBOutlet weak var sites_label_field: NSTextField!
    @IBOutlet weak var ldapservers_label_field: NSTextField!
    @IBOutlet weak var network_segments_label_field: NSTextField!
    @IBOutlet weak var users_label_field: NSTextField!
    @IBOutlet weak var smartUserGrps_label_field: NSTextField!
    @IBOutlet weak var staticUserGrps_label_field: NSTextField!
    
    //    @IBOutlet weak var migrateOrRemove_general_label_field: NSTextField!
    @IBOutlet weak var migrateOrRemove_TextField: NSTextField!
    //    @IBOutlet weak var migrateOrRemove_iOS_label_field: NSTextField!
    
    // GET and POST/PUT (DELETE) fields
    @IBOutlet weak var get_name_field: NSTextField!
//    @IBOutlet weak var get_completed_field: NSTextField!
//    @IBOutlet weak var get_found_field: NSTextField!
    @IBOutlet weak var getSummary_label: NSTextField!
    @IBOutlet weak var get_levelIndicator: NSLevelIndicator!
    //    @IBOutlet weak var get_levelIndicator: NSLevelIndicatorCell!

    @IBOutlet weak var put_name_field: NSTextField!  // object being migrated
//    @IBOutlet weak var objects_completed_field: NSTextField!
//    @IBOutlet weak var objects_found_field: NSTextField!
    @IBOutlet weak var putSummary_label: NSTextField!

    @IBOutlet weak var put_levelIndicator: NSLevelIndicator!
    var put_levelIndicatorFillColor = [String:NSColor]()

    // selective migration items - start
    // source / destination tables
    
    @IBOutlet var selectiveTabelHeader_textview: NSTextField!
    @IBOutlet weak var migrateDependencies: NSButton!
    @IBOutlet weak var srcSrvTableView: NSTableView!
    @IBOutlet var sourceObjectList_AC: NSArrayController!

    
    // selective migration vars
    var advancedMigrateDict     = [Int:[String:[String:String]]]()    // dictionary of dependencies for the object we're migrating - id:category:dictionary of dependencies
    var migratedDependencies    = [String:[Int]]()
    var migratedPkgDependencies = [String:String]()
    var waitForDependencies     = false
    var dependencyParentId      = 0
//    var dependencyMigratedCount = [Int:Int]()   // [policyID:number of dependencies]
    var arrayOfSelected         = [String:[String]]()
    
    
    // source / destination array / dictionary of items
    var sourceDataArray            = [String]()
    var staticSourceDataArray      = [String]()
    
    var staticSourceObjectList    = [SelectiveObject]()
    var targetSelectiveObjectList = [SelectiveObject]()
    
    var availableIDsToMigDict:[String:String] = [:]   // something like xmlName, xmlID
    var availableObjsToMigDict:[Int:String]   = [:]   // something like xmlID, xmlName

    var selectiveListCleared                = false
    var delayInt: UInt32                    = 50000
    var createRetryCount                    = [String:Int]()   // objectType-objectID:retryCount
    
    // destination TextFieldCells
    @IBOutlet weak var destTextCell_TextFieldCell: NSTextFieldCell!
    @IBOutlet weak var dest_TableColumn: NSTableColumn!
    // selective migration items - end
    
    // app version label
    @IBOutlet weak var appVersion_TextField: NSTextField!
    
    // smartgroup vars
    var migrateSmartComputerGroups  = false
    var migrateStaticComputerGroups = false
    var migrateSmartMobileGroups    = false
    var migrateStaticMobileGroups   = false
    var migrateSmartUserGroups      = false
    var migrateStaticUserGroups     = false
    
    var isDir: ObjCBool = false
    
    // command line switches
    var hideGui             = false
    var saveRawXmlScope     = true
    var saveTrimmedXmlScope = true
    
    // plist and log variables
//    var didRun                 = false  // used to determine if the Go! button was selected, if not delete the empty log file only.
    var format                 = PropertyListSerialization.PropertyListFormat.xml //format of the property list

    @IBOutlet weak var message_TextField: NSTextField!
    
    //  Log / backup vars
    let backupDate          = DateFormatter()
    var maxLogFileCount     = 20
    var historyFile: String = ""
    var logFile:     String = ""
    let logPath:    String? = (NSHomeDirectory() + "/Library/Logs/jamf-migrator/")
//    var logFileW:     FileHandle? = FileHandle(forUpdatingAtPath: "")
    // legacy logging (history) path and file
    let historyPath:String? = (NSHomeDirectory() + "/Library/Application Support/jamf-migrator/history/")
    var historyFileW: FileHandle? = FileHandle(forUpdatingAtPath: "")
    
    // scope preferences
    var scopeOptions:           [String:[String: Bool]] = [:]
    var scopeOcpCopy:           Bool = true   // osxconfigurationprofiles copy scope
    var scopeMaCopy:            Bool = true   // macapps copy scope
    var scopeRsCopy:            Bool = true   // restrictedsoftware copy scope
    var scopePoliciesCopy:      Bool = true   // policies copy scope
    var policyPoliciesDisable:  Bool = false  // policies disable on copy
    var scopeMcpCopy:           Bool = true   // mobileconfigurationprofiles copy scope
    var scopeIaCopy:            Bool = true   // iOSapps copy scope
    //    var policyMcpDisable:       Bool = false  // mobileconfigurationprofiles disable on copy
    //    var policyOcpDisable:       Bool = false  // osxconfigurationprofiles disable on copy
    var scopeScgCopy:           Bool = true // static computer groups copy scope
    var scopeSigCopy:           Bool = true // static iOS device groups copy scope
    var scopeUsersCopy:         Bool = true // static user groups copy scope
    
    // command line scope copy
    var copyScope               = true
    
    // xml prefs
    var xmlPrefOptions: [String:Bool] = [:]
    
    // site copy / move pref
    var sitePref = ""
    
    var sourceServerArray   = [String]()
    var destServerArray     = [String]()
    
    // credentials
    var sourceCreds = ""
    var destCreds   = ""
    var jamfAdminId = 1
    var accountDict = [String:String]()
    
    // settings variables
    let safeCharSet                 = CharacterSet.alphanumerics
    var source_pass: String         = ""
    var dest_jp_server: String      = ""
    var dest_user: String           = ""
    var dest_pass: String           = ""
    var sourceBase64Creds: String   = ""
    var destBase64Creds: String     = ""
    
    var sourceURL = ""
    var createDestUrlBase = ""
    var iconDictArray = [String:[[String:String]]]()
    var uploadedIcons = [String:Int]()
    
//    var pendingCount        = 0
//    var pendingGetCount     = 0
//    var existingEpCompleted = 0
    
    // import file vars
    var fileImport      = false
    
    var endpointDefDict = ["computergroups":"computer_groups", "directorybindings":"directory_bindings", "diskencryptionconfigurations":"disk_encryption_configurations", "dockitems":"dock_items","macapplications":"mac_applications", "mobiledeviceapplications":"mobile_device_application", "mobiledevicegroups":"mobile_device_groups", "packages":"packages", "patches":"patch_management_software_titles", "patchpolicies":"patch_policies", "printers":"printers", "scripts":"scripts", "usergroups":"user_groups", "userextensionattributes":"user_extension_attributes", "advancedusersearches":"advanced_user_searches", "restrictedsoftware":"restricted_software"]
    let ordered_dependency_array = ["sites", "buildings", "categories", "computergroups", "dockitems", "departments", "directorybindings", "distributionpoints", "ibeacons", "packages", "printers", "scripts", "softwareupdateservers", "networksegments"]
    var xmlName             = ""
    var destEPs             = [String:Int]()
    var currentEPs          = [String:Int]()
    var currentLDAPServers  = [String:Int]()
    
    var currentEPDict       = [String:[String:Int]]()
    
    var currentEndpointID   = 0
    var progressCountArray  = [String:Int]() // track if post/put was successful
    var endpointCountDict   = [String:Int]() // number of object in a category (sites, buildings, policies...)
    
    var whiteText:NSColor   = NSColor.systemGray
    var greenText:NSColor   = NSColor.green
    var yellowText:NSColor  = NSColor.yellow
    var redText:NSColor     = NSColor.red
    var changeColor:Bool    = true
    
    // This order must match the drop down for selective migration, provide the node name: ../JSSResource/node_name
    var generalEndpointArray: [String] = ["advancedusersearches", "buildings", "categories", "classes", "departments", "jamfusers", "jamfgroups", "ldapservers", "networksegments", "sites", "userextensionattributes", "users", "smartusergroups", "staticusergroups"]
    var macOSEndpointArray: [String] = ["advancedcomputersearches", "macapplications", "smartcomputergroups", "staticcomputergroups", "computers", "osxconfigurationprofiles", "directorybindings", "diskencryptionconfigurations", "dockitems", "computerextensionattributes", "distributionpoints", "packages", "patchmanagement", "policies", "computer-prestages", "printers", "restrictedsoftware", "scripts", "softwareupdateservers"]
    var iOSEndpointArray: [String] = ["advancedmobiledevicesearches", "mobiledeviceapplications", "mobiledeviceconfigurationprofiles", "smartmobiledevicegroups", "staticmobiledevicegroups", "mobiledevices",  "mobiledeviceextensionattributes", "mobile-device-prestages"]
    var AllEndpointsArray = [String]()
    
    
    var getEndpointInProgress = ""     // end point currently in the GET queue
    var endpointInProgress    = ""     // end point currently in the POST queue
    var endpointName          = ""
    var POSTsuccessCount      = 0
    var failedCount           = 0

    var counters              = [String:[String:Int]]()          // summary counters of created, updated, failed, and deleted objects
    var getCounters           = [String:[String:Int]]()          // summary counters of created, updated, failed, and deleted objects
    var putCounters           = [String:[String:Int]]()
    var summaryDict           = [String:[String:[String]]]()    // summary arrays of created, updated, and failed objects
    
    // used in createEndpoints
    var totalCreated    = 0
    var totalUpdated    = 0
    var totalFailed     = 0
    var totalCompleted  = 0
    var getArray        = [ObjectInfo]()
    var getArrayJSON    = [ObjectInfo]()
    var createArray     = [ObjectInfo]()
    var createArrayJson = [ObjectInfo]()
    var removeArray     = [ObjectInfo]()

    @IBOutlet weak var spinner_progressIndicator: NSProgressIndicator!
    
    // group counters
    var smartCount      = 0
    var staticCount     = 0
    //var DeviceGroupType = ""  // either smart or static
    // var groupCheckArray: [Bool] = []
    
    
    // define list of items to migrate
    var objectsToMigrate           = [String]()
    var totalObjectsToMigrate      = 0
    var endpointsRead              = 0
    var nodesMigrated              = 0
    var objectNode                 = "" // link dependency type to object endpoint. ex. (dependency) category to (endpoint) categories
    
    var getNodesComplete           = 0
    var nodesComplete              = 0 // nodes (buildings, categories, scripts...) migrated/exported/removed

    // dictionaries to map id of object on source server to id of same object on destination server
//    var computerconfigs_id_map = [String:[String:Int]]()
    var bindings_id_map   = [String:[String:Int]]()
    var packages_id_map   = [String:[String:Int]]()
    var printers_id_map   = [String:[String:Int]]()
    var scripts_id_map    = [String:[String:Int]]()
    var configObjectsDict = [String:[String:String]]()
    var orphanIds         = [String]()
    var idDict            = [String:[String:Int]]()
    
    var theOpQ        = OperationQueue() // create operation queue for API calls
    var getEndpointsQ = OperationQueue() // create operation queue for API calls
    var endpointsIdQ  = OperationQueue() // create operation queue for API calls
    var theCreateQ    = OperationQueue() // create operation queue for API POST/PUT calls
    var readFilesQ    = OperationQueue() // for reading in data files
    var readNodesQ    = OperationQueue() // for reading in API endpoints
    var removeEPQ     = OperationQueue() //DispatchQueue(label: "com.jamf.removeEPs", qos: DispatchQoS.background)
    var removeMeterQ  = OperationQueue() //DispatchQueue(label: "com.jamf.removeEPs", qos: DispatchQoS.background)
    let theIconsQ     = OperationQueue() // que to upload/download icons
    
    let theSortQ      = OperationQueue()
    
    var theModeQ    = DispatchQueue(label: "com.jamf.addRemove")
    
    var theSpinnerQ = DispatchQueue(label: "com.jamf.spinner")
    
    var destEPQ      = DispatchQueue(label: "com.jamf.destEPs", qos: DispatchQoS.utility)
    var getSourceEPQ = DispatchQueue(label: "com.jamf.destEPs", qos: DispatchQoS.utility)
    var idMapQ       = DispatchQueue(label: "com.jamf.idMap")
    var sortQ        = DispatchQueue(label: "com.jamf.sortQ", qos: DispatchQoS.default)
    var iconHoldQ    = DispatchQueue(label: "com.jamf.iconhold")
        
    var migrateOrWipe: String = ""
    var httpStatusCode: Int   = 0
    var URLisValid: Bool      = true
//    var processGroup          = DispatchGroup()
    
     func setTab_fn(selectedTab: String) {
         DispatchQueue.main.async {
             switch selectedTab {
             case "General":
                 self.activeTab_TabView.selectTabViewItem(at: 0)
//                 self.generalTab_NSButton.image = self.tabImage[1]
//                 self.macosTab_NSButton.image = self.tabImage[2]
//                 self.iosTab_NSButton.image = self.tabImage[4]
//                 self.selectiveTab_NSButton.image = self.tabImage[6]
             case "macOS":
                 self.activeTab_TabView.selectTabViewItem(at: 1)
//                 self.generalTab_NSButton.image = self.tabImage[0]
//                 self.macosTab_NSButton.image = self.tabImage[3]
//                 self.iosTab_NSButton.image = self.tabImage[4]
//                 self.selectiveTab_NSButton.image = self.tabImage[6]
             case "iOS":
                 self.activeTab_TabView.selectTabViewItem(at: 2)
//                 self.generalTab_NSButton.image = self.tabImage[0]
//                 self.macosTab_NSButton.image = self.tabImage[2]
//                 self.iosTab_NSButton.image = self.tabImage[5]
//                 self.selectiveTab_NSButton.image = self.tabImage[6]
             default:
                 self.activeTab_TabView.selectTabViewItem(at: 3)
//                 self.generalTab_NSButton.image = self.tabImage[0]
//                 self.macosTab_NSButton.image = self.tabImage[2]
//                 self.iosTab_NSButton.image = self.tabImage[4]
//                 self.selectiveTab_NSButton.image = self.tabImage[7]
             }   // swtich - end
         }   // DispatchQueue - end
     }   // func setTab_fn - end
    
    @IBAction func toggleAllNone(_ sender: NSButton) {
        if NSEvent.modifierFlags.contains(.option) {
            markAllNone(rawStateValue: sender.state.rawValue)
        }
		  inactiveTabDisable(activeTab: "bulk")
    }
    
    func inactiveTabDisable(activeTab: String) {
	    // disable buttons on inactive tabs - start
        if deviceType() != "macOS" {
            self.advcompsearch_button.state            = NSControl.StateValue(rawValue: 0)
            self.computers_button.state                = NSControl.StateValue(rawValue: 0)
            self.directory_bindings_button.state       = NSControl.StateValue(rawValue: 0)
            self.disk_encryptions_button.state         = NSControl.StateValue(rawValue: 0)
            self.dock_items_button.state               = NSControl.StateValue(rawValue: 0)
            self.fileshares_button.state               = NSControl.StateValue(rawValue: 0)
            self.sus_button.state                      = NSControl.StateValue(rawValue: 0)
//            self.netboot_button.state                = NSControl.StateValue(rawValue: 0)
            self.osxconfigurationprofiles_button.state = NSControl.StateValue(rawValue: 0)
            self.patch_mgmt_button.state               = NSControl.StateValue(rawValue: 0)
            self.patch_policies_button.state           = NSControl.StateValue(rawValue: 0)
            self.smart_comp_grps_button.state          = NSControl.StateValue(rawValue: 0)
            self.static_comp_grps_button.state         = NSControl.StateValue(rawValue: 0)
            self.ext_attribs_button.state              = NSControl.StateValue(rawValue: 0)
            self.scripts_button.state                  = NSControl.StateValue(rawValue: 0)
            self.macapplications_button.state          = NSControl.StateValue(rawValue: 0)
            self.packages_button.state                 = NSControl.StateValue(rawValue: 0)
            self.printers_button.state                 = NSControl.StateValue(rawValue: 0)
            self.restrictedsoftware_button.state       = NSControl.StateValue(rawValue: 0)
            self.policies_button.state                 = NSControl.StateValue(rawValue: 0)
            self.macPrestages_button.state             = NSControl.StateValue(rawValue: 0)
        }
        if deviceType() != "iOS" {
            self.advancedmobiledevicesearches_button.state      = NSControl.StateValue(rawValue: 0)
            self.mobiledevices_button.state                     = NSControl.StateValue(rawValue: 0)
            self.smart_ios_groups_button.state                  = NSControl.StateValue(rawValue: 0)
            self.static_ios_groups_button.state                 = NSControl.StateValue(rawValue: 0)
            self.mobiledevicecApps_button.state                 = NSControl.StateValue(rawValue: 0)
            self.mobiledeviceextensionattributes_button.state   = NSControl.StateValue(rawValue: 0)
            self.mobiledeviceconfigurationprofiles_button.state = NSControl.StateValue(rawValue: 0)
            self.iosPrestages_button.state                      = NSControl.StateValue(rawValue: 0)
        }
        if deviceType() != "general" {
            self.building_button.state          = NSControl.StateValue(rawValue: 0)
            self.categories_button.state        = NSControl.StateValue(rawValue: 0)
            self.classes_button.state           = NSControl.StateValue(rawValue: 0)
            self.dept_button.state              = NSControl.StateValue(rawValue: 0)
            self.advusersearch_button.state     = NSControl.StateValue(rawValue: 0)
            self.userEA_button.state            = NSControl.StateValue(rawValue: 0)
            self.ldapservers_button.state       = NSControl.StateValue(rawValue: 0)
            self.sites_button.state             = NSControl.StateValue(rawValue: 0)
            self.networks_button.state          = NSControl.StateValue(rawValue: 0)
            self.jamfUserAccounts_button.state  = NSControl.StateValue(rawValue: 0)
            self.jamfGroupAccounts_button.state = NSControl.StateValue(rawValue: 0)
            self.smartUserGrps_button.state     = NSControl.StateValue(rawValue: 0)
            self.staticUserGrps_button.state    = NSControl.StateValue(rawValue: 0)
            self.users_button.state             = NSControl.StateValue(rawValue: 0)
        }
        if activeTab == "bulk" {
            generalSectionToMigrate_button.selectItem(at: 0)
            sectionToMigrate_button.selectItem(at: 0)
            iOSsectionToMigrate_button.selectItem(at: 0)

            objectsToMigrate.removeAll()
            endpointCountDict.removeAll()
            sourceDataArray.removeAll()
            srcSrvTableView.reloadData()
            
            clearSourceObjectsList()
            
            targetSelectiveObjectList.removeAll()
        }
        // disable buttons on inactive tabs - end
        srcSrvTableView.isEnabled = true
	}

    func markAllNone(rawStateValue: Int) {

        if deviceType() == "macOS" {
            self.advcompsearch_button.state = NSControl.StateValue(rawValue: rawStateValue)
            self.computers_button.state = NSControl.StateValue(rawValue: rawStateValue)
            self.directory_bindings_button.state = NSControl.StateValue(rawValue: rawStateValue)
            self.disk_encryptions_button.state = NSControl.StateValue(rawValue: rawStateValue)
            self.dock_items_button.state = NSControl.StateValue(rawValue: rawStateValue)
            self.fileshares_button.state = NSControl.StateValue(rawValue: rawStateValue)
            self.sus_button.state = NSControl.StateValue(rawValue: rawStateValue)
//            self.netboot_button.state = NSControl.StateValue(rawValue: rawStateValue)
            self.osxconfigurationprofiles_button.state = NSControl.StateValue(rawValue: rawStateValue)
            self.patch_mgmt_button.state = NSControl.StateValue(rawValue: rawStateValue)
            self.patch_policies_button.state = NSControl.StateValue(rawValue: rawStateValue)
            self.smart_comp_grps_button.state = NSControl.StateValue(rawValue: rawStateValue)
            self.static_comp_grps_button.state = NSControl.StateValue(rawValue: rawStateValue)
            self.ext_attribs_button.state = NSControl.StateValue(rawValue: rawStateValue)
            self.scripts_button.state = NSControl.StateValue(rawValue: rawStateValue)
            self.macapplications_button.state = NSControl.StateValue(rawValue: rawStateValue)
            self.packages_button.state = NSControl.StateValue(rawValue: rawStateValue)
            self.printers_button.state = NSControl.StateValue(rawValue: rawStateValue)
            self.restrictedsoftware_button.state = NSControl.StateValue(rawValue: rawStateValue)
            self.policies_button.state = NSControl.StateValue(rawValue: rawStateValue)
            self.macPrestages_button.state = NSControl.StateValue(rawValue: rawStateValue)
        } else if deviceType() == "iOS" {
            self.advancedmobiledevicesearches_button.state = NSControl.StateValue(rawValue: rawStateValue)
            self.mobiledevices_button.state = NSControl.StateValue(rawValue: rawStateValue)
            self.smart_ios_groups_button.state = NSControl.StateValue(rawValue: rawStateValue)
            self.static_ios_groups_button.state = NSControl.StateValue(rawValue: rawStateValue)
            self.mobiledevicecApps_button.state = NSControl.StateValue(rawValue: rawStateValue)
            self.mobiledeviceextensionattributes_button.state = NSControl.StateValue(rawValue: rawStateValue)
            self.mobiledeviceconfigurationprofiles_button.state = NSControl.StateValue(rawValue: rawStateValue)
            self.iosPrestages_button.state = NSControl.StateValue(rawValue: rawStateValue)
        } else {
            self.building_button.state = NSControl.StateValue(rawValue: rawStateValue)
            self.categories_button.state = NSControl.StateValue(rawValue: rawStateValue)
            self.classes_button.state = NSControl.StateValue(rawValue: rawStateValue)
            self.dept_button.state = NSControl.StateValue(rawValue: rawStateValue)
            self.advusersearch_button.state = NSControl.StateValue(rawValue: rawStateValue)
            self.userEA_button.state = NSControl.StateValue(rawValue: rawStateValue)
            self.ldapservers_button.state = NSControl.StateValue(rawValue: rawStateValue)
            self.sites_button.state = NSControl.StateValue(rawValue: rawStateValue)
            self.networks_button.state = NSControl.StateValue(rawValue: rawStateValue)
            self.jamfUserAccounts_button.state = NSControl.StateValue(rawValue: rawStateValue)
            self.jamfGroupAccounts_button.state = NSControl.StateValue(rawValue: rawStateValue)
            self.smartUserGrps_button.state = NSControl.StateValue(rawValue: rawStateValue)
            self.staticUserGrps_button.state = NSControl.StateValue(rawValue: rawStateValue)
            self.users_button.state = NSControl.StateValue(rawValue: rawStateValue)
        }
    }
    
    fileprivate func clearSourceObjectsList() {
        if setting.fullGUI {
            let textPredicate = NSPredicate(format: "objectName.length > 0")
            sourceObjectList_AC.filterPredicate = textPredicate
            
            let range = 0..<(sourceObjectList_AC.arrangedObjects as AnyObject).count
            sourceObjectList_AC.remove(atArrangedObjectIndexes: IndexSet(integersIn: range))
        }
        staticSourceObjectList.removeAll()
    }
    
    @IBAction func sectionToMigrate(_ sender: NSPopUpButton) {
        
        pref.stopMigration  = false
        goButtonEnabled(button_status: false)

        inactiveTabDisable(activeTab: "selective")
        goSender = "selectToMigrateButton"

        let whichTab = sender.identifier!.rawValue
        
        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "func sectionToMigrate active tab: \(String(describing: whichTab)).") }
        var itemIndex = 0
        switch whichTab {
        case "macOS":
            itemIndex = sectionToMigrate_button.indexOfSelectedItem
        case "iOS":
            itemIndex = iOSsectionToMigrate_button.indexOfSelectedItem
        default:
            itemIndex = generalSectionToMigrate_button.indexOfSelectedItem
        }
        
        if whichTab != "macOS" || JamfProServer.importFiles == 1 {
            DispatchQueue.main.async {
                setting.migrateDependencies       = false
                self.migrateDependencies.state    = NSControl.StateValue(rawValue: 0)
                self.migrateDependencies.isHidden = true
            }
        }
    
        
        if itemIndex > 0 {
            switch whichTab {
            case "macOS":
                iOSsectionToMigrate_button.selectItem(at: 0)
                generalSectionToMigrate_button.selectItem(at: 0)
            case "iOS":
                sectionToMigrate_button.selectItem(at: 0)
                generalSectionToMigrate_button.selectItem(at: 0)
            default:
                iOSsectionToMigrate_button.selectItem(at: 0)
                sectionToMigrate_button.selectItem(at: 0)
            }
            selectiveFilter_TextField.stringValue = ""
            objectsToMigrate.removeAll()
            endpointCountDict.removeAll()
            sourceDataArray.removeAll()
            srcSrvTableView.reloadData()
            targetSelectiveObjectList.removeAll()
            arrayOfSelected.removeAll()
            
            sourceObjectList_AC.clearsFilterPredicateOnInsertion = true
            
            clearSourceObjectsList()
            
            if whichTab == "macOS" {
                AllEndpointsArray = macOSEndpointArray
            } else if whichTab == "iOS" {
                AllEndpointsArray = iOSEndpointArray
            } else {
                AllEndpointsArray = generalEndpointArray
            }
            
            objectsToMigrate.append(AllEndpointsArray[itemIndex-1])
            
            if AllEndpointsArray[itemIndex-1] == "policies" && !wipeData.on {
                DispatchQueue.main.async {
                    self.migrateDependencies.isHidden = false
                }
            } else {
                DispatchQueue.main.async {
                    setting.migrateDependencies       = false
                    self.migrateDependencies.state    = NSControl.StateValue(rawValue: 0)
                    self.migrateDependencies.isHidden = true
                }
            }
            
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "Selectively migrating: \(objectsToMigrate) for \(sender.identifier ?? NSUserInterfaceItemIdentifier(rawValue: ""))") }
            print("[sectionToMigrate] goSender: \(goSender)")
            Go(sender: goSender)
        }
    }
    
    @IBAction func Go_action(sender: NSButton) {
        JamfProServer.validToken["source"] = false
        JamfProServer.validToken["dest"]   = false
        JamfProServer.version["source"]    = ""
        JamfProServer.version["dest"]      = ""
        migrationComplete.isDone           = false
        if sender.title == "Go!" || sender.title == "Delete" {
            go_button.title = "Stop"
            getCounters.removeAll()
            putCounters.removeAll()
            iconfiles.policyDict.removeAll()
            iconfiles.pendingDict.removeAll()
            uploadedIcons.removeAll()
            Go(sender: "goButton")
        } else {
            WriteToLog.shared.message(stringOfText: "Migration was manually stopped.\n")
            pref.stopMigration = true

            goButtonEnabled(button_status: true)
        }
    }
    
    func Go(sender: String) {
//        print("go (before readSettings) scopeOptions: \(String(describing: scopeOptions))")
        
        History.startTime = Date()
        counters.removeAll()
        summaryDict.removeAll()
        
        if setting.fullGUI {
            if wipeData.on && export.saveOnly {
                _ = Alert.shared.display(header: "Attention", message: "Cannot select Save Only while in delete mode.", secondButton: "")
                goButtonEnabled(button_status: true)
                return
            }
            if wipeData.on && sender != "selectToMigrateButton" {
                let deleteResponse = Alert.shared.display(header: "Attention:", message: "You are about remove data from:\n\n\(JamfProServer.destination)\n\nare you sure you with to continue?", secondButton: "Cancel")
                if deleteResponse == "Cancel" {
                    rmDELETE()
                    selectiveListCleared = false
                    clearSelectiveList()
                    clearProcessingFields()
                    resetAllCheckboxes()
                    goButtonEnabled(button_status: true)
                    
                    return
                }
            }
            
            _ = readSettings()
            scopeOptions          = AppInfo.settings["scope"] as! [String:[String:Bool]]
            xmlPrefOptions        = AppInfo.settings["xml"] as! [String:Bool]
            
            export.saveOnly       = (xmlPrefOptions["saveOnly"] == nil) ? false:xmlPrefOptions["saveOnly"]!
            export.saveRawXml     = (xmlPrefOptions["saveRawXml"] == nil) ? false:xmlPrefOptions["saveRawXml"]!
            export.saveTrimmedXml = (xmlPrefOptions["saveTrimmedXml"] == nil) ? false:xmlPrefOptions["saveTrimmedXml"]!
            saveRawXmlScope       = (xmlPrefOptions["saveRawXmlScope"] == nil) ? true:xmlPrefOptions["saveRawXmlScope"]!
            saveTrimmedXmlScope   = (xmlPrefOptions["saveTrimmedXmlScope"] == nil) ? true:xmlPrefOptions["saveRawXmlScope"]!
            
            smartUserGrpsSelected      = smartUserGrps_button.state.rawValue == 1
            staticUserGrpsSelected     = staticUserGrps_button.state.rawValue == 1
            smartComputerGrpsSelected  = smart_comp_grps_button.state.rawValue == 1
            staticComputerGrpsSelected = static_comp_grps_button.state.rawValue == 1
            smartIosGrpsSelected       = smart_ios_groups_button.state.rawValue == 1
            staticIosGrpsSelected      = static_ios_groups_button.state.rawValue == 1
            jamfUserAccountsSelected   = jamfUserAccounts_button.state.rawValue == 1
            jamfGroupAccountsSelected  = jamfGroupAccounts_button.state.rawValue == 1
        } else {
            if export.backupMode {
                backupDate.dateFormat = "yyyyMMdd_HHmmss"
                export.saveOnly       = true
                export.saveRawXml     = true
                export.saveTrimmedXml = false
                saveRawXmlScope       = true
                saveTrimmedXmlScope   = false
                
                smartUserGrpsSelected      = true
                staticUserGrpsSelected     = true
                smartComputerGrpsSelected  = true
                staticComputerGrpsSelected = true
                smartIosGrpsSelected       = true
                staticIosGrpsSelected      = true
                jamfUserAccountsSelected   = true
                jamfGroupAccountsSelected  = true
            }
        }
        
        if JamfProServer.importFiles == 1 && (export.saveOnly || export.saveRawXml) {
            alert_dialog(header: "Attention", message: "Cannot select Export Only or Raw Source XML (Preferneces -> Export) when using File Import.")
            goButtonEnabled(button_status: true)
            return
        }

        didRun = true

        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "Start Migrating/Removal") }
        // check for file that allow deleting data from destination server - start
        if (fm.fileExists(atPath: NSHomeDirectory() + "/Library/Application Support/jamf-migrator/DELETE", isDirectory: &isDir)) && !export.backupMode {
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "Removing data from destination server - \(JamfProServer.destination)") }
            wipeData.on = true
            
            migrateOrWipe = "----------- Starting To Wipe Data -----------\n"
        } else {
            if !export.saveOnly {
                // verify source and destination are not the same - start
//                if (source_jp_server_field.stringValue == dest_jp_server_field.stringValue) && siteMigrate_button.state.rawValue == 0 {
                let sameSite = (JamfProServer.source == JamfProServer.destination) ? true:false
//                if sameSite && (JamfProServer.destSite == "None" || JamfProServer.destSite == "") {
                if sameSite && JamfProServer.destSite == "" {
                    alert_dialog(header: "Alert", message: "Source and destination servers cannot be the same.")
                    self.goButtonEnabled(button_status: true)
                    return
                }
                // verify source and destination are not the same - end
                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "Migrating data from \(JamfProServer.source) to \(JamfProServer.destination).") }
                migrateOrWipe = "----------- Starting Replicating -----------\n"
            } else {
                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "Exporting data from \(JamfProServer.source).") }
                if export.saveOnly  {
                    migrateOrWipe = "----------- Starting Export Only -----------\n"
                } else {
                    migrateOrWipe = "----------- Starting Export -----------\n"
                }
            }
            wipeData.on = false
        }
        // check for file that allow deleting data from destination server - end
        
        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.Go] go sender: \(sender)") }
        // determine if we got here from the Go button, selectToMigrate button, or silently
        goSender = "\(sender)"
//        print("[Go] sender: \(sender)")

        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.Go] Go button pressed from: \(goSender)") }
        
        if setting.fullGUI {
            put_levelIndicator.fillColor = .green
            get_levelIndicator.fillColor = .green
            // which migration mode tab are we on
            if activeTab(fn: "Go") == "selective" {
                migrationMode = "selective"
            } else {
                migrationMode               = "bulk"
                setting.migrateDependencies = false
            }
        } else {
            migrationMode = "bulk"
        }
        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.Go] Migration Mode (Go): \(migrationMode)") }
        
        goButtonEnabled(button_status: false)
        if setting.fullGUI {
//            goButtonEnabled(button_status: false)
            clearProcessingFields()
            
            // credentials were entered check - start
            if JamfProServer.importFiles == 0 && !wipeData.on {
                if (JamfProServer.sourceUser == "" || JamfProServer.sourcePwd == "") && !wipeData.on {
                    alert_dialog(header: "Alert", message: "Must provide both a username and password for the source server.")
                    goButtonEnabled(button_status: true)
                    return
                }
            }
            if !export.saveOnly {
                if JamfProServer.destUser == "" || JamfProServer.destPwd == "" {
                    alert_dialog(header: "Alert", message: "Must provide both a username and password for the destination server.")
                    goButtonEnabled(button_status: true)
                    return
                }
            }
            // credentials check - end

            // set credentials / servers - end
        }
        self.dest_jp_server = JamfProServer.destination
        self.dest_user      = JamfProServer.destUser
        self.dest_pass      = JamfProServer.destPwd
        nodesMigrated       = -1
        currentEPs.removeAll()
        
        // server is reachable - start
        JamfPro.shared.checkURL2(whichServer: "source", serverURL: JamfProServer.source)  {
            (result: Bool) in
//            print("checkURL2 returned result: \(result)")
            if !result {
                if setting.fullGUI {
                    self.alert_dialog(header: "Attention:", message: "Unable to contact the source server:\n\(JamfProServer.source)")
                    self.goButtonEnabled(button_status: true)
                    return
                } else {
                    WriteToLog.shared.message(stringOfText: "Unable to contact the source server:\n\(JamfProServer.source)")
                    NSApplication.shared.terminate(self)
                }
            }
            
            JamfProServer.url["source"] = JamfProServer.source
            
            JamfPro.shared.checkURL2(whichServer: "dest", serverURL: JamfProServer.destination)  { [self]
                (result: Bool) in
    //            print("checkURL2 returned result: \(result)")
                if !result {
                    if setting.fullGUI {
                        self.alert_dialog(header: "Attention:", message: "Unable to contact the destination server:\n\(JamfProServer.destination)")
                        self.goButtonEnabled(button_status: true)
                        return
                    } else {
                        WriteToLog.shared.message(stringOfText: "Unable to contact the destination server:\n\(JamfProServer.destination)")
                        NSApplication.shared.terminate(self)
                    }
                }
                // server is reachable - end
                
                JamfProServer.url["dest"] = JamfProServer.destination
                
                if setting.fullGUI || setting.migrate {
                    if JamfProServer.toSite {
                        destinationSite = JamfProServer.destSite
                        itemToSite = true
                    } else {
                        itemToSite = false
                    }
                }
                
                // don't set if we're importing files or removing data
                if JamfProServer.importFiles == 0 && !wipeData.on {
                    self.sourceCreds = "\(JamfProServer.sourceUser):\(JamfProServer.sourcePwd)"
                } else {
                    self.sourceCreds = ":"
                }
                self.sourceBase64Creds = self.sourceCreds.data(using: .utf8)?.base64EncodedString() ?? ""
                JamfProServer.base64Creds["source"] = self.sourceCreds.data(using: .utf8)?.base64EncodedString() ?? ""
                
                self.destCreds = "\(JamfProServer.destUser):\(JamfProServer.destPwd)"
//                self.destCreds = "\(self.dest_user):\(self.dest_pass)"
                self.destBase64Creds = self.destCreds.data(using: .utf8)?.base64EncodedString() ?? ""
                JamfProServer.base64Creds["dest"] = self.destCreds.data(using: .utf8)?.base64EncodedString() ?? ""
                // set credentials - end
                
                // check authentication - start
                
//                let clientType = (JamfProServer.sourceUseApiClient == 1) ? "API client/secret":"username/password"
//                WriteToLog.shared.message(stringOfText: "[go] Using \(clientType) to generate token for \(JamfProServer.source.fqdnFromUrl).")
                
                let localsource = (JamfProServer.importFiles == 1) ? true:false
                JamfPro.shared.getToken(whichServer: "source", serverUrl: JamfProServer.source, base64creds: JamfProServer.base64Creds["source"] ?? "", localSource: localsource) { [self]
                    (authResult: (Int,String)) in
                    let (authStatusCode, _) = authResult
                    if !pref.httpSuccess.contains(authStatusCode) && !wipeData.on {
                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "Source server authentication failure.") }
                        
                        pref.stopMigration = true
                        goButtonEnabled(button_status: true)
                        
                        return
                    } else {
                        if setting.fullGUI {
                            self.updateServerArray(url: JamfProServer.source, serverList: "source_server_array", theArray: self.sourceServerArray)
                            // update keychain, if marked to save creds
                            if !wipeData.on {
                                print("[ViewController.go] JamfProServer.storeSourceCreds: \(JamfProServer.storeSourceCreds)")
                                if JamfProServer.storeSourceCreds == 1 {
                                    print("[ViewController.go] save credentials for: \(JamfProServer.source.fqdnFromUrl)")
                                    self.Creds2.save(service: JamfProServer.source.fqdnFromUrl, account: JamfProServer.sourceUser, credential: JamfProServer.sourcePwd, whichServer: "source")
                                    self.storedSourceUser = JamfProServer.sourceUser
                                }
                            }
                        }
                        
//                        let clientType = (JamfProServer.destUseApiClient == 1) ? "API client/secret":"username/password"
//                        WriteToLog.shared.message(stringOfText: "[go] Using \(clientType) to generate token for \(JamfProServer.destination.fqdnFromUrl).")
                        JamfPro.shared.getToken(whichServer: "dest", serverUrl: JamfProServer.destination, base64creds: JamfProServer.base64Creds["dest"] ?? "", localSource: localsource) { [self]
                            (authResult: (Int,String)) in
                            let (authStatusCode, _) = authResult
                            if !pref.httpSuccess.contains(authStatusCode) {
                                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.Go] Destination server (\(JamfProServer.destination)) authentication failure.") }
                                
                                pref.stopMigration = true
                                goButtonEnabled(button_status: true)
                                
                                return
                            } else {
                                // update keychain, if marked to save creds
                                if !export.saveOnly && setting.fullGUI {
                                    print("[ViewController.go] JamfProServer.storeDestCreds: \(JamfProServer.storeDestCreds)")
                                    if JamfProServer.storeDestCreds == 1 {
                                        print("[ViewController.go] save credentials for: \(JamfProServer.destination.fqdnFromUrl)")
                                        self.Creds2.save(service: JamfProServer.destination.fqdnFromUrl, account: JamfProServer.destUser, credential: JamfProServer.destPwd, whichServer: "dest")
                                        self.storedDestUser = JamfProServer.destUser
                                    }
                                }
                                // determine if the cloud services connection is enabled
                                var csaMethod = "GET"
                                if export.saveOnly { csaMethod = "skip" }
                                Jpapi.shared.action(whichServer: "dest", endpoint: "csa/token", apiData: [:], id: "", token: JamfProServer.authCreds["dest"]!, method: csaMethod) {
                                    (returnedJSON: [String:Any]) in
//                                            print("CSA: \(returnedJSON)")
                                    if let _ = returnedJSON["scopes"] {
                                        setting.csa = true
                                    } else {
                                        setting.csa = false
                                    }
    //                                print("csa: \(setting.csa)")
                                    
                                    if !export.saveOnly && setting.fullGUI {
                                        self.updateServerArray(url: self.dest_jp_server, serverList: "dest_server_array", theArray: self.destServerArray)
                                    }
            
                                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "call startMigrating().") }
                                    self.startMigrating()
                                }
                            } // else dest auth
                        }   // JamfPro.shared.getToken(whichServer: "dest" - end
                    }   // else check dest URL auth - end
                }   // JamfPro.shared.getToken(whichServer: "source" - end

        // check authentication - end
            }   // checkURL2 (destination server) - end
        }
    }   // @IBAction func Go - end
    
    @IBAction func quit_action(sender: AnyObject) {
        go_button.isEnabled = false
        // check for file that sets mode to delete data from destination server, delete if found - start
        rmDELETE()

        AppDelegate.shared.quitNow(sender: self)
    }
    
    //================================= migration functions =================================//
    func startMigrating() {
        _ = disableSleep(reason: "starting process")
        
        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.startMigrating] enter") }
        pref.stopMigration = false
        createRetryCount.removeAll()
        nodesComplete    = 0
        getNodesComplete = 0
        
        // make sure the labels can change color when we start
                  changeColor = true
        getEndpointInProgress = "start"
        endpointInProgress    = ""
        
        DispatchQueue.main.async { [self] in
            if !export.backupMode {
                fileImport = (JamfProServer.importFiles == 1) ? true:false
                createDestUrlBase = "\(JamfProServer.destination)/JSSResource".urlFix
            } else {
                fileImport = false
                createDestUrlBase = "\(dest_jp_server)/JSSResource".urlFix
            }
                
            if setting.fullGUI {
                // set all the labels to white - start
                AllEndpointsArray = macOSEndpointArray + iOSEndpointArray + generalEndpointArray
                for i in (0..<AllEndpointsArray.count) {
                    labelColor(endpoint: AllEndpointsArray[i], theColor: whiteText)
                }
                // set all the labels to white - end
            }
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.startMigrating] Start Migrating/Removal") }
            if setting.fullGUI {
                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.startMigrating] platform: \(deviceType()).") }
            }
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.startMigrating] Migration Mode (startMigration): \(migrationMode).") }
                        
                // list the items in the order they need to be migrated
            if migrationMode == "bulk" {
                // initialize list of items to migrate then add what we want - start
                objectsToMigrate.removeAll()
                endpointCountDict.removeAll()

                if setting.fullGUI {
                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "Types of objects to migrate: \(deviceType()).") }
                    // macOS
                    switch deviceType() {
                    case "general":
                        if sites_button.state.rawValue == 1 {
                            objectsToMigrate += ["sites"]
                        }
                        
                        if userEA_button.state.rawValue == 1 {
                            objectsToMigrate += ["userextensionattributes"]
                        }
                        
                        if ldapservers_button.state.rawValue == 1 {
                            objectsToMigrate += ["ldapservers"]
                        }
                        
                        if users_button.state.rawValue == 1 {
                            objectsToMigrate += ["users"]
                        }
                        
                        if building_button.state.rawValue == 1 {
                            objectsToMigrate += ["buildings"]
                        }
                        
                        if dept_button.state.rawValue == 1 {
                            objectsToMigrate += ["departments"]
                        }
                        
                        if categories_button.state.rawValue == 1 {
                            objectsToMigrate += ["categories"]
                        }
                        
                        if jamfUserAccounts_button.state.rawValue == 1 {
                            objectsToMigrate += ["jamfusers"]
                        }
                        
                        if jamfGroupAccounts_button.state.rawValue == 1 {
                            objectsToMigrate += ["jamfgroups"]
                        }
                        
                        if networks_button.state.rawValue == 1 {
                            objectsToMigrate += ["networksegments"]
                        }
                        
                        if advusersearch_button.state.rawValue == 1 {
                            objectsToMigrate += ["advancedusersearches"]
                        }
                        
                        if smartUserGrps_button.state.rawValue == 1 || staticUserGrps_button.state.rawValue == 1 {
                            smartUserGrps_button.state.rawValue == 1 ? (migrateSmartUserGroups = true):(migrateSmartUserGroups = false)
                            staticUserGrps_button.state.rawValue == 1 ? (migrateStaticUserGroups = true):(migrateStaticUserGroups = false)
                            if !fileImport || wipeData.on {
                                objectsToMigrate += ["usergroups"]
                            } else {
                                if migrateSmartUserGroups {
                                    objectsToMigrate += ["smartusergroups"]
                                }
                                if migrateStaticUserGroups {
                                    objectsToMigrate += ["staticusergroups"]
                                }
                            }
                        }
                        
                        if classes_button.state.rawValue == 1 {
                            objectsToMigrate += ["classes"]
                        }
                    case "macOS":
                        if fileshares_button.state.rawValue == 1 {
                            objectsToMigrate += ["distributionpoints"]
                        }
                        
                        if directory_bindings_button.state.rawValue == 1 {
                            objectsToMigrate += ["directorybindings"]
                        }
                        
                        if disk_encryptions_button.state.rawValue == 1 {
                            objectsToMigrate += ["diskencryptionconfigurations"]
                        }
                        
                        if dock_items_button.state.rawValue == 1 {
                            objectsToMigrate += ["dockitems"]
                        }
                        
                        if computers_button.state.rawValue == 1 {
                            objectsToMigrate += ["computers"]
                        }
                        
                        if sus_button.state.rawValue == 1 {
                            objectsToMigrate += ["softwareupdateservers"]
                        }
                        
//                        if netboot_button.state.rawValue == 1 {
//                            objectsToMigrate += ["netbootservers"]
//                        }
                        
                        if ext_attribs_button.state.rawValue == 1 {
                            objectsToMigrate += ["computerextensionattributes"]
                        }
                        
                        if scripts_button.state.rawValue == 1 {
                            objectsToMigrate += ["scripts"]
                        }
                        
                        if printers_button.state.rawValue == 1 {
                            objectsToMigrate += ["printers"]
                        }
                        
                        if packages_button.state.rawValue == 1 {
                            objectsToMigrate += ["packages"]
                        }
                        
                        if smart_comp_grps_button.state.rawValue == 1 || static_comp_grps_button.state.rawValue == 1 {
                            smart_comp_grps_button.state.rawValue == 1 ? (migrateSmartComputerGroups = true):(migrateSmartComputerGroups = false)
                            static_comp_grps_button.state.rawValue == 1 ? (migrateStaticComputerGroups = true):(migrateStaticComputerGroups = false)
                            if !fileImport || wipeData.on {
                                objectsToMigrate += ["computergroups"]
                            } else {
                                if migrateSmartComputerGroups {
                                    objectsToMigrate += ["smartcomputergroups"]
                                }
                                if migrateStaticComputerGroups {
                                    objectsToMigrate += ["staticcomputergroups"]
                                }
                            }
                        }
                        
                        if restrictedsoftware_button.state.rawValue == 1 {
                            objectsToMigrate += ["restrictedsoftware"]
                        }
                        
                        if osxconfigurationprofiles_button.state.rawValue == 1 {
                            objectsToMigrate += ["osxconfigurationprofiles"]
                        }
                        
                        if macapplications_button.state.rawValue == 1 {
                            objectsToMigrate += ["macapplications"]
                        }
                        
                        if patch_mgmt_button.state.rawValue == 1 {
                            //                    objectsToMigrate += ["patches"]
                            objectsToMigrate += ["patchmanagement"]
                        }
                        
                        if advcompsearch_button.state.rawValue == 1 {
                            objectsToMigrate += ["advancedcomputersearches"]
                        }
                        
                        if policies_button.state.rawValue == 1 {
                            objectsToMigrate += ["policies"]
                        }
                    case "iOS":
                        if mobiledeviceextensionattributes_button.state.rawValue == 1 {
                            objectsToMigrate += ["mobiledeviceextensionattributes"]
                        }
                        
                        if mobiledevices_button.state.rawValue == 1 {
                            objectsToMigrate += ["mobiledevices"]
                        }

                        if smart_ios_groups_button.state.rawValue == 1 || static_ios_groups_button.state.rawValue == 1 {
                             smart_ios_groups_button.state.rawValue == 1 ? (migrateSmartMobileGroups = true):(migrateSmartMobileGroups = false)
                             static_ios_groups_button.state.rawValue == 1 ? (migrateStaticMobileGroups = true):(migrateStaticMobileGroups = false)
                             if !fileImport || wipeData.on {
                                 objectsToMigrate += ["mobiledevicegroups"]
                             } else {
                                 if migrateSmartMobileGroups {
                                     objectsToMigrate += ["smartmobiledevicegroups"]
                                 }
                                 if migrateStaticMobileGroups {
                                     objectsToMigrate += ["staticmobiledevicegroups"]
                                 }
                             }
                         }

                        if advancedmobiledevicesearches_button.state.rawValue == 1 {
                            objectsToMigrate += ["advancedmobiledevicesearches"]
                        }
                        
                        if mobiledevicecApps_button.state.rawValue == 1 {
                            objectsToMigrate += ["mobiledeviceapplications"]
                        }
                        
                        if mobiledeviceconfigurationprofiles_button.state.rawValue == 1 {
                            objectsToMigrate += ["mobiledeviceconfigurationprofiles"]
                        }
                    default: break
                    }
                    totalObjectsToMigrate = objectsToMigrate.count
                    if !fileImport {
                        if smartUserGrps_button.state.rawValue == 1 && staticUserGrps_button.state.rawValue == 1 {
                            totalObjectsToMigrate += 1
                        } else if smart_comp_grps_button.state.rawValue == 1 && static_comp_grps_button.state.rawValue == 1 {
                            totalObjectsToMigrate += 1
                        } else if smart_ios_groups_button.state.rawValue == 1 && static_ios_groups_button.state.rawValue == 1 {
                            totalObjectsToMigrate += 1
                        }
                    }
                } else {
                    if setting.migrate {
                        // set migration order
                        let allObjects = ["sites", "userextensionattributes", "ldapservers", "users", "buildings", "departments", "categories", "classes", "jamfusers", "jamfgroups", "networksegments", "advancedusersearches", "smartusergroups", "staticusergroups", "distributionpoints", "directorybindings", "diskencryptionconfigurations", "dockitems", "computers", "softwareupdateservers", "computerextensionattributes", "scripts", "printers", "packages", "smartcomputergroups", "staticcomputergroups", "restrictedsoftware", "osxconfigurationprofiles", "macapplications", "patchpolicies", "advancedcomputersearches", "policies", "mobiledeviceextensionattributes", "mobiledevices", "smartmobiledevicegroups", "staticmobiledevicegroups", "advancedmobiledevicesearches", "mobiledeviceapplications", "mobiledeviceconfigurationprofiles"]
                        for theObject in allObjects {
                            if setting.objects.firstIndex(of: theObject) != nil || setting.objects.contains("allobjects") {
                                objectsToMigrate += [theObject]
                            }
                        }
                    } else {
                        // define objects to export
                        let exportObjects = ["sites", "userextensionattributes", "ldapservers", "users", "buildings", "departments", "categories", "classes", "jamfusers", "jamfgroups", "networksegments", "advancedusersearches", "usergroups", "distributionpoints", "directorybindings", "diskencryptionconfigurations", "dockitems", "computers", "softwareupdateservers", "computerextensionattributes", "scripts", "printers", "packages", "computergroups", "restrictedsoftware", "osxconfigurationprofiles", "macapplications", "patchpolicies", "advancedcomputersearches", "policies", "mobiledeviceextensionattributes", "mobiledevices", "mobiledevicegroups", "advancedmobiledevicesearches", "mobiledeviceapplications", "mobiledeviceconfigurationprofiles"]
                        for theObject in exportObjects {
                            if setting.objects.firstIndex(of: theObject) != nil || setting.objects.contains("allobjects") {
                                objectsToMigrate += [theObject]
                            }
                        }
                    }
//                    objectsToMigrate = ["buildings", "departments", "categories", "jamfusers"]    // for testing
                    totalObjectsToMigrate = objectsToMigrate.count
                }
                endpointsRead = 0
            } else {   // if migrationMode == "bulk" - end
                totalObjectsToMigrate = 1
            }
            
            
            
            // initialize list of items to migrate then add what we want - end
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.startMigrating] objects: \(self.objectsToMigrate).") }
                    
            
            if self.objectsToMigrate.count == 0 {
                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.startMigrating] nothing selected to migrate/remove.") }
                self.goButtonEnabled(button_status: true)
                return
            } else {
                self.nodesMigrated = 0
                if wipeData.on {
                    // reverse migration order for removal and set create / delete header for summary table
                    self.objectsToMigrate.reverse()
                    // set server and credentials used for wipe
                    self.sourceBase64Creds = self.destBase64Creds
                    JamfProServer.base64Creds["source"] = self.destBase64Creds
                    JamfProServer.source  = self.dest_jp_server
                    
                    JamfProServer.authCreds["source"]   = JamfProServer.authCreds["dest"]
//                    JamfProServer.authExpires["source"] = JamfProServer.authExpires["dest"]
                    JamfProServer.authType["source"]    = JamfProServer.authType["dest"]
                        
                    summaryHeader.createDelete = "Delete"
                } else {   // if wipeData.on - end
                    summaryHeader.createDelete = "Create"
                }
            }
            
            
            
            WriteToLog.shared.message(stringOfText: self.migrateOrWipe)
            
            // initialize counters
            for currentNode in self.objectsToMigrate {
                if setting.fullGUI {
                    PutLevelIndicator.shared.indicatorColor[currentNode] = .green
//                    self.put_levelIndicatorFillColor[currentNode] = .green
                }
                print("[startMigrating] currentNode: \(currentNode)")
                switch currentNode {
                case "computergroups", "smartcomputergroups", "staticcomputergroups":
                    if self.smartComputerGrpsSelected {
                        self.progressCountArray["smartcomputergroups"] = 0
                        self.counters["smartcomputergroups"]           = ["create":0, "update":0, "fail":0, "skipped":0, "total":0]
                        self.summaryDict["staticcomputergroups"]       = ["create":[], "update":[], "fail":[]]
                        self.getCounters["smartcomputergroups"]        = ["get":0]
                        self.putCounters["smartcomputergroups"]        = ["put":0]
                    }
                    if self.staticComputerGrpsSelected {
                        self.progressCountArray["staticcomputergroups"] = 0
                        self.counters["staticcomputergroups"]           = ["create":0, "update":0, "fail":0, "skipped":0, "total":0]
                        self.summaryDict["staticcomputergroups"]        = ["create":[], "update":[], "fail":[]]
                        self.getCounters["staticcomputergroups"]        = ["get":0]
                        self.putCounters["staticcomputergroups"]        = ["put":0]
                    }
                    self.progressCountArray["computergroups"] = 0 // this is the recognized end point
                case "mobiledevicegroups":
                    if self.smartIosGrpsSelected {
                        self.progressCountArray["smartmobiledevicegroups"] = 0
                        self.counters["smartmobiledevicegroups"]           = ["create":0, "update":0, "fail":0, "skipped":0, "total":0]
                        self.summaryDict["smartmobiledevicegroups"]        = ["create":[], "update":[], "fail":[]]
                        self.getCounters["smartmobiledevicegroups"]        = ["get":0]
                        self.putCounters["smartmobiledevicegroups"]        = ["put":0]
                    }
                    if self.staticIosGrpsSelected {
                        self.progressCountArray["staticmobiledevicegroups"] = 0
                        self.counters["staticmobiledevicegroups"]           = ["create":0, "update":0, "fail":0, "skipped":0, "total":0]
                        self.summaryDict["staticmobiledevicegroups"]        = ["create":[], "update":[], "fail":[]]
                        self.getCounters["staticmobiledevicegroups"]        = ["get":0]
                        self.putCounters["staticmobiledevicegroups"]        = ["put":0]
                    }
                    self.progressCountArray["mobiledevicegroups"] = 0 // this is the recognized end point
                case "usergroups":
                    if self.smartUserGrpsSelected {
                        self.progressCountArray["smartusergroups"] = 0
                        self.counters["smartusergroups"]           = ["create":0, "update":0, "fail":0, "skipped":0, "total":0]
                        self.summaryDict["smartusergroups"]        = ["create":[], "update":[], "fail":[]]
                        self.getCounters["smartusergroups"]        = ["get":0]
                        self.putCounters["smartusergroups"]        = ["put":0]
                    }
                    if self.staticUserGrpsSelected {
                        self.progressCountArray["staticusergroups"] = 0
                        self.counters["staticusergroups"]           = ["create":0, "update":0, "fail":0, "skipped":0, "total":0]
                        self.summaryDict["staticusergroups"]        = ["create":[], "update":[], "fail":[]]
                        self.getCounters["staticusergroups"]        = ["get":0]
                        self.putCounters["staticusergroups"]        = ["put":0]
                    }
                    self.progressCountArray["usergroups"] = 0 // this is the recognized end point
                case "accounts":
                    if self.jamfUserAccountsSelected {
                        self.progressCountArray["jamfusers"] = 0
                        self.counters["jamfusers"]           = ["create":0, "update":0, "fail":0, "skipped":0, "total":0]
                        self.summaryDict["jamfusers"]        = ["create":[], "update":[], "fail":[]]
                        self.getCounters["jamfusers"]        = ["get":0]
                        self.putCounters["jamfusers"]        = ["put":0]
                    }
                    if self.jamfGroupAccountsSelected {
                        self.progressCountArray["jamfgroups"] = 0
                        self.counters["jamfgroups"]           = ["create":0, "update":0, "fail":0, "skipped":0, "total":0]
                        self.summaryDict["jamfgroups"]        = ["create":[], "update":[], "fail":[]]
                        self.getCounters["jamfgroups"]        = ["get":0]
                        self.putCounters["jamfgroups"]        = ["put":0]
                    }
                    self.progressCountArray["accounts"] = 0 // this is the recognized end point
                case "patchmanagement":
                    self.progressCountArray["patch-software-title-configurations"] = 0
                    self.counters["patch-software-title-configurations"]           = ["create":0, "update":0, "fail":0, "skipped":0, "total":0]
                    self.summaryDict["patch-software-title-configurations"]        = ["create":[], "update":[], "fail":[]]
                    self.getCounters["patch-software-title-configurations"]        = ["get":0]
                    self.putCounters["patch-software-title-configurations"]        = ["put":0]
                default:
                    self.progressCountArray["\(currentNode)"] = 0
                    self.counters[currentNode] = ["create":0, "update":0, "fail":0, "skipped":0, "total":0]
                    self.summaryDict[currentNode] = ["create":[], "update":[], "fail":[]]
                    self.getCounters[currentNode] = ["get":0]
                    self.putCounters[currentNode] = ["put":0]
                }
            }

            // get scope copy / policy disable options
            self.scopeOptions = readSettings()["scope"] as! [String: [String: Bool]]
//            print("startMigrating scopeOptions: \(String(describing: self.scopeOptions))")
            
            if setting.fullGUI {
                // get scope preference settings - start
                if self.scopeOptions["osxconfigurationprofiles"]!["copy"] != nil {
                    self.scopeOcpCopy = self.scopeOptions["osxconfigurationprofiles"]!["copy"]!
                }
                if self.scopeOptions["macapps"] != nil {
                    if self.scopeOptions["macapps"]!["copy"] != nil {
                        self.scopeMaCopy = self.scopeOptions["macapps"]!["copy"]!
                    } else {
                        self.scopeMaCopy = true
                    }
                } else {
                    self.scopeMaCopy = true
                }
                if self.scopeOptions["restrictedsoftware"]!["copy"] != nil {
                    self.scopeRsCopy = self.scopeOptions["restrictedsoftware"]!["copy"]!
                }
                if self.scopeOptions["policies"]!["copy"] != nil {
                    self.scopePoliciesCopy = self.scopeOptions["policies"]!["copy"]!
                }
                if self.scopeOptions["policies"]!["disable"] != nil {
                    self.policyPoliciesDisable = self.scopeOptions["policies"]!["disable"]!
                }
                if self.scopeOptions["mobiledeviceconfigurationprofiles"]!["copy"] != nil {
                    self.scopeMcpCopy = self.scopeOptions["mobiledeviceconfigurationprofiles"]!["copy"]!
                }
                if self.scopeOptions["iosapps"] != nil {
                    if self.scopeOptions["iosapps"]!["copy"] != nil {
                        self.scopeIaCopy = self.scopeOptions["iosapps"]!["copy"]!
                    } else {
                        self.scopeIaCopy = true
                    }
                } else {
                    self.scopeIaCopy = true
                }
                if self.scopeOptions["scg"]!["copy"] != nil {
                    self.scopeScgCopy = self.scopeOptions["scg"]!["copy"]!
                }
                if self.scopeOptions["sig"]!["copy"] != nil {
                    self.scopeSigCopy = self.scopeOptions["sig"]!["copy"]!
                }
                if self.scopeOptions["users"]!["copy"] != nil {
                    self.scopeUsersCopy = self.scopeOptions["users"]!["copy"]!
                }
                // get scope preference settings - end
            }
            
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.startMigrating] migrating/removing \(self.objectsToMigrate.count) sections") }
            // loop through process of migrating or removing - start
            self.readNodesQ.addOperation {
                let currentNode = self.objectsToMigrate[0]

                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.startMigrating] Starting to process \(currentNode)") }
                                
                if (self.goSender == "goButton" && self.migrationMode == "bulk") || (self.goSender == "selectToMigrateButton") || (self.goSender == "silent") {
                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.startMigrating] getting endpoint: \(currentNode)") }
                    
                    // this will populate list for selective migration or start migration of bulk operations
                    self.readNodes(nodesToMigrate: self.objectsToMigrate, nodeIndex: 0)
                    
                } else {
                    // **************************************** selective migration - start ****************************************
                    var selectedEndpoint = ""
                    switch self.objectsToMigrate[0] {
                    case "jamfusers":
                        selectedEndpoint = "accounts/userid"
                    case "jamfgroups":
                        selectedEndpoint = "accounts/groupid"
                    default:
                        selectedEndpoint = self.objectsToMigrate[0]
                    }
                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.startMigrating] Look for existing endpoints for: \(self.objectsToMigrate[0])") }
//                    print("call self.existingEndpoints")
                    
                    self.existingEndpoints(skipLookup: false, theDestEndpoint: "\(self.objectsToMigrate[0])")  { [self]
                        (result: (String,String)) in
                        
                        let (resultMessage, resultEndpoint) = result
                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.startMigrating] Returned from existing endpoints: \(resultMessage)") }
                        
//                        print("build list of objects selected")
                        
                        // clear targetSelectiveObjectList - needed to handle switching tabs
                        if !setting.migrateDependencies || resultEndpoint == "policies" {
                            targetSelectiveObjectList.removeAll()
                            
                            DispatchQueue.main.async { [self] in
                                // create targetSelectiveObjectList, list of objects to migrate/remove - start
                                for k in (0..<(sourceObjectList_AC.arrangedObjects as AnyObject).count) {
                                    if srcSrvTableView.isRowSelected(k) {
//                                        print("add \((sourceObjectList_AC.arrangedObjects as! [SelectiveObject])[k].objectName) to selective migration")
                                        targetSelectiveObjectList.append((sourceObjectList_AC.arrangedObjects as! [SelectiveObject])[k])
                                    }
                                }
                                
                                if targetSelectiveObjectList.count == 0 {
                                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.startMigrating] nothing selected to migrate/remove.") }
                                    self.alert_dialog(header: "Alert:", message: "Nothing was selected.")
                                    self.goButtonEnabled(button_status: true)
                                    return
                                }
                            
                                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.startMigrating] Item(s) chosen from selective: \(sourceObjectList_AC.arrangedObjects as! [SelectiveObject])") }

                                advancedMigrateDict.removeAll()
                                migratedDependencies.removeAll()
                                migratedPkgDependencies.removeAll()
                                waitForDependencies  = false
                                
                                startSelectiveMigration(objectIndex: 0, selectedEndpoint: selectedEndpoint)
                            }
                        }
                    }
                }   //  if (self.goSender == "goButton"... - else - end
            // **************************************** selective migration - end ****************************************
            }   // self.readFiles.async - end
        }   //DispatchQueue.main.async - end
    }   // func startMigrating - end
    
    func startSelectiveMigration(objectIndex: Int, selectedEndpoint: String) {
//        print("[startSelectiveMigration] objectIndex: \(objectIndex), selectedEndpoint: \(selectedEndpoint)")
        
        var idPath             = ""  // adjust for jamf users/groups that use userid/groupid instead of id
        var alreadyMigrated    = false
        var theButton          = ""

//        print("[startMigrating] availableIDsToMigDict: \(availableIDsToMigDict)")
        // todo - consolidate these 2 vars
        let primaryObjToMigrateID = Int(targetSelectiveObjectList[objectIndex].objectId)
        let objToMigrateID        = targetSelectiveObjectList[objectIndex].objectId
        
        dependencyParentId        = primaryObjToMigrateID!
        dependency.isRunning      = true
        Counter.shared.dependencyMigrated[dependencyParentId] = 0
        
        switch selectedEndpoint {
        case "accounts/userid", "accounts/groupid":
            idPath = "/"
        default:
            idPath = "id/"
        }
        
        // adjust the endpoint used for the lookup
        var rawEndpoint = ""
        switch selectedEndpoint {
            case "smartcomputergroups", "staticcomputergroups":
                rawEndpoint = "computergroups"
            case "smartmobiledevicegroups", "staticmobiledevicegroups":
                rawEndpoint = "mobiledevicegroups"
            case "smartusergroups", "staticusergroups":
                rawEndpoint = "usergroups"
            case "accounts/userid":
                rawEndpoint = "jamfusers"
            case "accounts/groupid":
                rawEndpoint = "jamfgroups"
            case "patchmanagement":
                rawEndpoint = "patch-software-title-configurations"
            default:
                rawEndpoint = selectedEndpoint
        }
        
//        let endpointToLookup = fileImport ? "skip":"\(rawEndpoint)/\(idPath)\(String(describing: primaryObjToMigrateID!))"
        
        var endpointToLookup = fileImport ? "skip":"\(rawEndpoint)/\(idPath)\(String(describing: primaryObjToMigrateID!))"
        if fileImport || wipeData.on {
            endpointToLookup = "skip"
        }
        
        print("[startSelectiveMigration] selectedEndpoint: \(selectedEndpoint)")
        if !wipeData.on {
            Json().getRecord(whichServer: "source", theServer: JamfProServer.source, base64Creds: JamfProServer.base64Creds["source"] ?? "", theEndpoint: endpointToLookup, endpointBase: selectedEndpoint, endpointId: objToMigrateID)  { [self]
                (objectRecord: Any) in
                
                switch selectedEndpoint {
                case "patchmanagement":
                    let existingPatch = objectRecord as? PatchSoftwareTitleConfiguration
                    print("[startSelectiveMigration] patch management title name: \(existingPatch?.displayName ?? "")")
                    
                    let selectedObject = targetSelectiveObjectList[objectIndex].objectName
                    print("[startSelectiveMigration] patch management selectedEndpoint: \(selectedEndpoint)")
                    print("[startSelectiveMigration] patch management selectedObject: \(selectedObject)")
                    print("[startSelectiveMigration] selected currentEPDict: \(self.currentEPDict[selectedEndpoint]?[selectedObject] ?? 0)")
                    print("[startSelectiveMigration] currentEPDict: \(self.currentEPDict)")
                    if !fileImport {
                        // export policy details if export.saveRawXml
                        if export.saveRawXml {
                            DispatchQueue.main.async { [self] in
                                WriteToLog.shared.message(stringOfText: "[getEndpoints] Exporting raw JSON for patch policy details")
                                let exportFormat = (export.backupMode) ? "\(JamfProServer.source.fqdnFromUrl)_export_\(backupDate.string(from: History.startTime))":"raw"
                                ExportItems.shared.patchmanagement(node: "patchPolicyDetails", object: PatchPoliciesDetails.source, format: exportFormat)
                            }
                        }
                    }
                default:
                    break
                }
                let result = objectRecord as? [String: AnyObject] ?? [:]
                print("[startSelectiveMigration] result.count: \(result.count)")
                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.startMigration] Returned from Json.getRecord: \(result)") }
                
                if pref.stopMigration {
//                    print("[\(#function)] \(#line) stopMigration")
                    stopButton(self)
                    return
                }
                //                print("call getDependencies for \(rawEndpoint)/\(idPath)\(primaryObjToMigrateID)")
                self.getDependencies(object: "\(selectedEndpoint)", json: result) { [self]
                    (returnedDependencies: [String:[String:String]]) in
//                    print("returned from getDependencies for \(rawEndpoint)/\(idPath)\(primaryObjToMigrateID)")
//                    print("returned getDependencies: \(returnedDependencies)")
                    if returnedDependencies.count > 0 {
                        advancedMigrateDict[primaryObjToMigrateID!] = returnedDependencies
                    } else {
                        advancedMigrateDict = [:]
                    }
                    
                    let selectedObject = targetSelectiveObjectList[objectIndex].objectName
//                    print("[startSelectiveMigration] selectedObject: \(selectedObject)")
                    // include dependencies - start
//                    print("advancedMigrateDict with policy: \(advancedMigrateDict)")
                    
                    self.destEPQ.async { [self] in
                        
                        // how many dependencies; categories, buildings, scripts, packages,...
                        var totalDependencies = 0
                        for (_, arrayOfDependencies) in returnedDependencies {
                            totalDependencies += arrayOfDependencies.count
                        }
                        //                                print("[ViewController.startSelectiveMigration] total dependencies for \(rawEndpoint)/\(idPath)\(primaryObjToMigrateID): \(totalDependencies)")
                        
                        if !fileImport {
                            for (object, arrayOfDependencies) in returnedDependencies {
                                if nil == self.getCounters[object] {
                                    getCounters[object]         = ["get":0]
                                    putCounters[object]         = ["put":0]
                                    progressCountArray[object]  = 0
                                    counters[object]?["create"] = 0
                                    counters[object]?["update"] = 0
                                    counters[object]?["fail"]   = 0
                                }
                                
                                let dependencyCount = returnedDependencies[object]!.count
                                
                                if dependencyCount > 0 {
                                    var dependencyCounter = 0
                                    
                                    for (theName, theId) in arrayOfDependencies {
                                        let dependencySubcount = arrayOfDependencies[theName]?.count
                                        alreadyMigrated = false
                                        //
                                        var theDependencyAction     = "create"
                                        var theDependencyEndpointID = 0
                                        dependencyCounter += 1
                                        WriteToLog.shared.message(stringOfText: "[ViewController.startSelectiveMigration] check for existing \(object): \(theName)")
                                        
                                        // see if we've migrated the dependency already
                                        switch object {
                                        case "packages":
                                            if let _ = migratedPkgDependencies[theName] {
                                                Counter.shared.dependencyMigrated[dependencyParentId]! += 1
                                                alreadyMigrated = true
                                                //                                                    print("[dependencies] Counter.shared.dependencyMigrated incremented: \(String(describing: Counter.shared.dependencyMigrated[dependencyParentId]))")
                                                //                                                    print("[dependencies] \(object) \(theName) has already been migrated")
                                                if theId != migratedPkgDependencies[theName] {
                                                    WriteToLog.shared.message(stringOfText: "[ViewController.startSelectiveMigration] Duplicate references to the same package were found on \(JamfProServer.source).  Package with filename \(theName) has id: \(theId) and \(String(describing: migratedPkgDependencies[theName]!))")
                                                    DispatchQueue.main.async {
                                                        print("[startSelectiveMigration] \(#line) server: \(JamfProServer.source)")
                                                        theButton = Alert.shared.display(header: "Warning:", message: "Several packages on \(JamfProServer.source), having unique display names, are linked to a single file.  Check the log for 'Duplicate references to the same package' for details.", secondButton: "Stop")
                                                        if theButton == "Stop" {
                                                            self.stopButton(self)
                                                        }
                                                    }
                                                }
                                            }
                                        default:
                                            if let _ = migratedDependencies[object]?.firstIndex(of: Int(theId)!) {
                                                Counter.shared.dependencyMigrated[dependencyParentId]! += 1
                                                alreadyMigrated = true
                                                //                                                    print("[dependencies] Counter.shared.dependencyMigrated incremented: \(String(describing: Counter.shared.dependencyMigrated[dependencyParentId]))")
                                                //                                                    print("[dependencies] \(object) \(theName) has already been migrated")
                                            }
                                        }
                                        
                                        if !alreadyMigrated {
                                            if self.currentEPDict[object]?[theName] != nil && !export.saveOnly {
                                                theDependencyAction     = "update"
                                                theDependencyEndpointID = Int(self.currentEPDict[object]![theName]!)
                                            }
                                            
                                            WriteToLog.shared.message(stringOfText: "[ViewController.startSelectiveMigration] \(object): \(theDependencyAction) \(theName)")
                                            
                                            self.endPointByIDQueue(endpoint: object, endpointID: theId, endpointCurrent: dependencyCounter, endpointCount: dependencySubcount!, action: theDependencyAction, destEpId: theDependencyEndpointID, destEpName: selectedObject)
                                            
                                            // update list of dependencies migrated
                                            switch object {
                                            case "packages":
                                                migratedPkgDependencies[theName] = theId
                                            default:
                                                if migratedDependencies[object] != nil {
                                                    migratedDependencies[object]!.append(Int(theId)!)
                                                } else {
                                                    migratedDependencies[object] = [Int(theId)!]
                                                }
                                            }
                                        }
                                    }   // for (theName, theId) in advancedMigrateDict[object]! - end
                                }
                            }   // for (object, arrayOfDependencies) in returnedDependencies - end
                        }
                        
                        // migrate the policy or selected object now the dependencies are done
                        DispatchQueue.global(qos: .utility).async { [self] in
                            if !fileImport {
                                var step = 0
                                while Counter.shared.dependencyMigrated[dependencyParentId] != totalDependencies && theButton != "Stop" && setting.migrateDependencies && !export.saveOnly {
                                    if theButton == "Stop" { setting.migrateDependencies = false }
                                    //                                        if step % 10 == 0 { print("Counter.shared.dependencyMigrated[\(dependencyParentId)] \(String(describing: Counter.shared.dependencyMigrated[dependencyParentId]!)) of \(totalDependencies)")}
                                    usleep(10000)
                                    step += 1
                                }
                                //                                    print("Counter.shared.dependencyMigrated[\(dependencyParentId)] \(String(describing: Counter.shared.dependencyMigrated[dependencyParentId]!)) of \(totalDependencies)")
                                Counter.shared.dependencyMigrated[dependencyParentId] = 0
                            }
                            
                            if theButton == "Stop" { return }
                            
                            var theAction = "update"

                            if !export.saveOnly { WriteToLog.shared.message(stringOfText: "check destination for existing object: \(selectedObject)") }
                            
                            let existingObjectId = (selectedEndpoint == "patchmanagement") ? self.currentEPDict[selectedEndpoint]?[selectedObject] ?? 0:self.currentEPDict[rawEndpoint]?[selectedObject] ?? 0
                            if existingObjectId == 0 && !export.saveOnly {
                                theAction     = "create"
                            }
                            print("[startSelectiveMigration] existingObjectId: \(existingObjectId), theAction: \(theAction)")
                            
                            WriteToLog.shared.message(stringOfText: "[ViewController.startSelectiveMigration] \(theAction) \(selectedObject) \(selectedEndpoint) dependency")
                            
                            if !fileImport {
                                self.endPointByIDQueue(endpoint: selectedEndpoint, endpointID: objToMigrateID, endpointCurrent: (objectIndex+1), endpointCount: targetSelectiveObjectList.count, action: theAction, destEpId: existingObjectId, destEpName: selectedObject)
                            } else {
                                //                                   print("[ViewController.startSelectiveMigration-fileImport] \(selectedObject), all items: \(self.availableFilesToMigDict)")
                                
                                let fileToMigrate = displayNameToFilename[selectedObject]
//                                print("[ViewController.startSelectiveMigration-fileImport] selectedObject: \(selectedObject), fileToMigrate: \(String(describing: fileToMigrate))")
//                                print("[ViewController.startSelectiveMigration-fileImport] objectIndex+1: \(objectIndex+1), targetSelectiveObjectList.count: \(targetSelectiveObjectList.count)")
                                
                                arrayOfSelected[selectedObject] = self.availableFilesToMigDict[fileToMigrate!]!
//                                print("[ViewController.startSelectiveMigration] selectedObject: \(selectedObject)")
//                                print("[ViewController.startSelectiveMigration-fileImport] arrayOfSelected: \(arrayOfSelected[selectedObject] ?? [])")
                                
                                //                                    if arrayOfSelected.count == targetSelectiveObjectList.count {
                                if objectIndex+1 == targetSelectiveObjectList.count {
//                                    print("[ViewController.startSelectiveMigration] processFiles)")
                                    self.processFiles(endpoint: selectedEndpoint, fileCount: targetSelectiveObjectList.count, itemsDict: arrayOfSelected) {
                                        (result: String) in
                                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[readDataFiles] Returned from processFile (\(String(describing: fileToMigrate))).") }
                                    }
                                }
                            }
                            
                            // call next item
                            if objectIndex+1 < targetSelectiveObjectList.count {
                                //                                        print("[ViewController.startSelectiveMigration] call next \(selectedEndpoint)")
                                startSelectiveMigration(objectIndex: objectIndex+1, selectedEndpoint: selectedEndpoint)
                            } else if objectIndex+1 == targetSelectiveObjectList.count {
                                dependency.isRunning = false
                            }
                        }
                    }
                    // include dependencies - end
                    //                    }
                    
                }
            }
        } else {
            // selective removal
//            print("[removeEndpoints] counters[\(selectedEndpoint)]: \(counters[selectedEndpoint])")
            counters[selectedEndpoint] = ["create": counters[selectedEndpoint]?["create"] ?? 0, "update": counters[selectedEndpoint]?["update"] ?? 0, "fail": counters[selectedEndpoint]?["fail"] ?? 0, "skipped": counters[selectedEndpoint]?["skipped"] ?? 0, "total": counters[selectedEndpoint]?["total"] ?? 0]
            
            counters[selectedEndpoint]!["total"] = targetSelectiveObjectList.count

            if summaryDict[selectedEndpoint] == nil {
                summaryDict[selectedEndpoint] = ["create":[], "update":[], "fail":[]]
            }
            for i in 0..<targetSelectiveObjectList.count {
                let theObject = targetSelectiveObjectList[i]
                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "remove - endpoint: \(targetSelectiveObjectList[objectIndex].objectName)\t endpointID: \(objToMigrateID)\t endpointName: \(self.targetSelectiveObjectList[objectIndex].objectName)") }
                
                removeEndpointsQueue(endpointType: selectedEndpoint, endPointID: "\(theObject.objectId)", endpointName: theObject.objectName, endpointCurrent: (i+1), endpointCount: targetSelectiveObjectList.count)
//                removeEndpoints(endpointType: selectedEndpoint, endPointID: "\(theObject.objectId)", endpointName: theObject.objectName, endpointCurrent: (i+1), endpointCount: targetSelectiveObjectList.count) { [self]
//                    (result: String) in
//                    print("[startSelectiveMigration] removed id: \(result) - \(i+1) of \(targetSelectiveObjectList.count)")
//                }
            }
            removeEndpointsQueue(endpointType: selectedEndpoint, endPointID: "-1", endpointName: "", endpointCurrent: -1, endpointCount: 0)
            dependency.isRunning = false
        }   // if !wipeData.on else - end
//        }   // Json().getRecord - end
    }
    
    
    func readNodes(nodesToMigrate: [String], nodeIndex: Int) {
        
        if pref.stopMigration {
//            print("[\(#function)] \(#line) stopMigration")
            stopButton(self)
            return
        }
        
        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.readNodes] enter search for \(nodesToMigrate[nodeIndex])") }
        
        switch nodesToMigrate[nodeIndex] {
        case "computergroups", "smartcomputergroups", "staticcomputergroups":
            self.progressCountArray["smartcomputergroups"]  = 0
            self.progressCountArray["staticcomputergroups"] = 0
            self.progressCountArray["computergroups"]       = 0 // this is the recognized end point
        case "mobiledevicegroups", "smartmobiledevicegroups", "staticmobiledevicegroups":
            self.progressCountArray["smartmobiledevicegroups"]     = 0
            self.progressCountArray["staticmobiledevicegroups"]    = 0
            self.progressCountArray["mobiledevicegroups"] = 0 // this is the recognized end point
        case "usergroups", "smartusergroups", "staticusergroups":
            self.progressCountArray["smartusergroups"] = 0
            self.progressCountArray["staticusergroups"] = 0
            self.progressCountArray["usergroups"] = 0 // this is the recognized end point
        case "accounts":
            self.progressCountArray["jamfusers"] = 0
            self.progressCountArray["jamfgroups"] = 0
            self.progressCountArray["accounts"] = 0 // this is the recognized end point
        default:
            self.progressCountArray["\(nodesToMigrate[nodeIndex])"] = 0
        }
        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.readNodes] getting endpoint: \(nodesToMigrate[nodeIndex])") }
        
        if nodeIndex == 0 {
            // see if the source is a folder, is so allow access
            if JamfProServer.source.first == "/" {
                if JamfProServer.source.last != "/" {
                    JamfProServer.source = JamfProServer.source + "/"
                }
                
                if SecurityScopedBookmarks.shared.allowAccess(for: JamfProServer.source) {
                    WriteToLog.shared.message(stringOfText: "[ViewController.readNodes] set access permissions to \(JamfProServer.source)")
                } else {
                    WriteToLog.shared.message(stringOfText: "[ViewController.readNodes] Bookmark Access Failed for \(JamfProServer.source)")
                }
                
                if !FileManager.default.isReadableFile(atPath: JamfProServer.source) {
                    WriteToLog.shared.message(stringOfText: "[ViewController.readNodes] Unable to read from \(JamfProServer.source).  Reselect it using the File Import or Browse button and try again.")
                    pref.stopMigration = true
                    if setting.fullGUI {
                        DispatchQueue.main.async {
                            _ = Alert.shared.display(header: "Attention:", message: "Unable to read \(JamfProServer.source).  Reselect it using the File Import or Browse button and try again.", secondButton: "")
                            return
                        }
                    } else {
                        NSApplication.shared.terminate(self)
                    }
                }
            }
            if export.saveRawXml {
                if export.saveLocation.last != "/" {
                    export.saveLocation = export.saveLocation + "/"
                }
                
                if SecurityScopedBookmarks.shared.allowAccess(for: export.saveLocation) {
                    WriteToLog.shared.message(stringOfText: "[ViewController.readNodes] set access permissions to \(export.saveLocation)")
                } else {
                    WriteToLog.shared.message(stringOfText: "[ViewController.readNodes] Bookmark Access Failed for \(export.saveLocation)")
                }
                
                if !FileManager.default.isWritableFile(atPath: export.saveLocation) {
                    WriteToLog.shared.message(stringOfText: "[ViewController.readNodes] Unable to write to \(export.saveLocation), setting export location to \(NSHomeDirectory())/Downloads/Jamf Transporter/")
                    export.saveLocation = (NSHomeDirectory() + "/Downloads/Jamf Transporter/")
                    userDefaults.set("\(export.saveLocation)", forKey: "saveLocation")
                }
            }   // if export.saveRawXml - end
        }   // if nodeIndex == 0 - end
            
        
        if self.fileImport && !wipeData.on && !pref.stopMigration {
            
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.readNodes] reading files for: \(nodesToMigrate)") }
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.readNodes]         nodeIndex: \(nodeIndex)") }
//            print("call readDataFiles for \(nodesToMigrate)")   // called too often
            self.readDataFiles(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex) {
                (result: String) in
                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.readNodes] processFiles result: \(result)") }
                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.readNodes] exit") }
            }
        } else {
            
            clearSourceObjectsList()
            availableObjsToMigDict.removeAll()
            
            self.getEndpoints(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex)  {
                (result: [String]) in
//                print("[ViewController.readNodes] getEndpoints result: \(result)")
                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.readNodes] getEndpoints result: \(result)") }
                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.readNodes] exit") }
                if setting.fullGUI {
                    if self.activeTab(fn: "readNodes") == "selective" {
                        self.goButtonEnabled(button_status: true)
                    }
                }
            }
        }
    }   // func readNodes - end
    
    fileprivate func updateSelectiveList(objectName: String, objectId: String, fileContents: String) {
        DispatchQueue.main.async { [self] in
            sourceObjectList_AC.addObject(SelectiveObject(objectName: objectName, objectId: objectId, fileContents: fileContents))
            // sort printer list
            sourceObjectList_AC.rearrangeObjects()
            staticSourceObjectList = sourceObjectList_AC.arrangedObjects as! [SelectiveObject]
            
//            srcSrvTableView.reloadData()
            srcSrvTableView.scrollRowToVisible(staticSourceObjectList.count-1)
            // srcSrvTableView.scrollToEndOfDocument(nil)
        }
    }
    
    func getEndpoints(nodesToMigrate: [String], nodeIndex: Int, completion: @escaping (_ result: [String]) -> Void) {
        // get objects from source server (query source server) - destination server if removing
        print("[getEndpoints] nodesToMigrate: \(nodesToMigrate)")
        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] enter") }
//        pendingGetCount = 0
        Counter.shared.pendingGet = 0

        if pref.stopMigration {
//            print("[\(#function)] \(#line) stopMigration")
            stopButton(self)
            completion([])
            return
        }
        
        var duplicatePackages      = false
        var duplicatePackagesDict  = [String:[String]]()
        var failedPkgNameLookup    = [String]()
        
        URLCache.shared.removeAllCachedResponses()
        var endpoint       = nodesToMigrate[nodeIndex]
        var endpointParent = ""
        var node           = ""
        var endpointCount  = 0
        var groupType      = ""
        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] Getting \(endpoint)") }
//        print("[ViewController.getEndpoints] Getting \(endpoint), index \(nodeIndex)")
        
        if endpoint.contains("smart") {
            groupType = "smart"
        } else if endpoint.contains("static") {
            groupType = "static"
        }
        
        switch endpoint {
        // macOS items
        case "advancedcomputersearches":
            endpointParent = "advanced_computer_searches"
        case "computerextensionattributes":
            endpointParent = "computer_extension_attributes"
        case "computergroups", "smartcomputergroups", "staticcomputergroups":
            endpoint       = "computergroups"
            endpointParent = "computer_groups"
        case "directorybindings":
            endpointParent = "directory_bindings"
        case "diskencryptionconfigurations":
            endpointParent = "disk_encryption_configurations"
        case "distributionpoints":
            endpointParent = "distribution_points"
        case "dockitems":
            endpointParent = "dock_items"
        case "macapplications":
            endpointParent = "mac_applications"
//        case "netbootservers":
//            endpointParent = "netboot_servers"
        case "osxconfigurationprofiles":
            endpointParent = "os_x_configuration_profiles"
        case "patchmanagement":
            endpoint = "patch-software-title-configurations"
//        case "patches":
//            endpointParent = "patch_management_software_titles"
//        case "patchpolicies":
//            endpointParent = "patch_policies"
        case "restrictedsoftware":
            endpointParent = "restricted_software"
        case "softwareupdateservers":
            endpointParent = "software_update_servers"
        // iOS items
        case "advancedmobiledevicesearches":
            endpointParent = "advanced_mobile_device_searches"
        case "mobiledeviceconfigurationprofiles":
            endpointParent = "configuration_profiles"
        case "mobiledeviceextensionattributes":
            endpointParent = "mobile_device_extension_attributes"
        case "mobiledeviceapplications":
            endpointParent = "mobile_device_applications"
        case "mobiledevicegroups", "smartmobiledevicegroups", "staticmobiledevicegroups":
            endpoint       = "mobiledevicegroups"
            endpointParent = "mobile_device_groups"
        case "mobiledevices":
            endpointParent = "mobile_devices"
        // general items
        case "advancedusersearches":
            endpointParent = "advanced_user_searches"
        case "ldapservers":
            endpointParent = "ldap_servers"
        case "networksegments":
            endpointParent = "network_segments"
        case "userextensionattributes":
            endpointParent = "user_extension_attributes"
        case "usergroups", "smartusergroups", "staticusergroups":
            endpoint       = "usergroups"
            endpointParent = "user_groups"
        case "jamfusers":
            endpointParent = "users"
        case "jamfgroups":
            endpointParent = "groups"
        default:
            endpointParent = "\(endpoint)"
        }
        
        var myURL = "\(JamfProServer.source)"
            
        switch endpoint {
        case "patch-software-title-configurations":
            myURL = myURL.appending("/api/v2/\(endpoint)").urlFix
        default:
            (endpoint == "jamfusers" || endpoint == "jamfgroups") ? (node = "accounts"):(node = endpoint)
            myURL = myURL.appending("/JSSResource/\(node)").urlFix
        }
//        print("myURL: \(myURL)")

        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] URL: \(myURL)") }
        
        getEndpointsQ.maxConcurrentOperationCount = maxConcurrentThreads
        let semaphore = DispatchSemaphore(value: 0)
        
        if setting.fullGUI {
            DispatchQueue.main.async {
                self.srcSrvTableView.isEnabled = true
            }
        }
        self.sourceDataArray.removeAll()
        self.availableIDsToMigDict.removeAll()
        
        clearSourceObjectsList()
        
        getEndpointsQ.addOperation {
                    
                    let encodedURL = URL(string: myURL)
                    let request = NSMutableURLRequest(url: encodedURL! as URL)
                    request.httpMethod = "GET"
                    let configuration = URLSessionConfiguration.ephemeral
                    
                    configuration.httpAdditionalHeaders = ["Authorization" : "\(JamfProServer.authType["source"] ?? "Bearer") \(JamfProServer.authCreds["source"] ?? "")", "Content-Type" : "application/json", "Accept" : "application/json", "User-Agent" : AppInfo.userAgentHeader]
                    
                    let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
                    let task = session.dataTask(with: request as URLRequest, completionHandler: { [self]
                        (data, response, error) -> Void in
                        session.finishTasksAndInvalidate()
                        //                print("[getEndpoints] fetched endpoint: \(nodesToMigrate[nodeIndex])")
//                        if nodesToMigrate.last == nodesToMigrate[nodeIndex] {
                            //                    print("[getEndpoints] last node")
//                        }
                        if let httpResponse = response as? HTTPURLResponse {
//                            print("httpResponse: \(httpResponse.statusCode)")
                            if httpResponse.statusCode > 199 && httpResponse.statusCode < 300 {

                                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] Getting all endpoints from: \(myURL)") }
                                switch endpoint {
                                case "patch-software-title-configurations":
                                    PatchTitleConfigurations.source = try! JSONDecoder().decode(PatchSoftwareTitleConfigurations.self, from: data ?? Data())

                                    availableObjsToMigDict.removeAll()
                                    
                                    var displayNames = [String]()
                                    for patchObject in PatchTitleConfigurations.source as [PatchSoftwareTitleConfiguration] {
                                        var displayName = patchObject.displayName
                                        if patchObject.softwareTitlePublisher.range(of: "(Deprecated Definition)") != nil {
                                            displayName.append(" (Deprecated Definition)")
                                        }
//                                        print("displayName: \(displayName)")
                                        displayNames.append(displayName)
                                        
                                        if displayName.isEmpty {
                                            availableObjsToMigDict[Int(patchObject.id ?? "") ?? 0] = ""
                                        } else {
                                            availableObjsToMigDict[Int(patchObject.id ?? "") ?? 0] = displayName
                                        }
                                    }
                                    endpointsRead += 1
                                    
                                    endpointCountDict["patchmanagement"] = availableObjsToMigDict.count
                                    
                                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] Found total of \(availableObjsToMigDict.count) \(endpoint) to process") }
                                    
                                    if endpoint == "patch-software-title-configurations" {
                                        print("[getEndpoints] fetch patch management dependencies from source server")
                                        PatchDelegate.shared.getDependencies(whichServer: "source") { [self] result in
                                            message_TextField.stringValue = ""
                                            PatchDelegate.shared.getDependencies(whichServer: "dest") { [self] result in
                                                message_TextField.stringValue = ""
                                                
                                                var counter = 1
                                                if goSender == "goButton" || !setting.fullGUI {
                                                    // export policy details if export.saveRawXml
                                                    if export.saveRawXml {
                                                        DispatchQueue.main.async { [self] in
                                                            WriteToLog.shared.message(stringOfText: "[getEndpoints] Exporting raw JSON for patch policy details")
                                                            let exportFormat = (export.backupMode) ? "\(JamfProServer.source.fqdnFromUrl)_export_\(backupDate.string(from: History.startTime))":"raw"
                                                            ExportItems.shared.patchmanagement(node: "patchPolicyDetails", object: PatchPoliciesDetails.source, format: exportFormat)
                                                        }
                                                    }
                                                    
                                                    print("[getEndpoints] counters: \(counters)")
                                                    counters[endpoint]!["total"] = availableObjsToMigDict.count
                                                    //                                                counters["patchmanagement"]!["total"] = availableObjsToMigDict.count
                                                    
                                                    for (l_xmlID, l_xmlName) in availableObjsToMigDict {
                                                        if pref.stopMigration { break }
                                                        if !wipeData.on  {
                                                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] check for ID on \(l_xmlName): \(currentEPs[l_xmlName] ?? 0)") }
                                                            
                                                            if currentEPDict[endpoint]?[l_xmlName] != nil {
                                                                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] \(l_xmlName) already exists") }
                                                                
                                                                if setting.onlyCopyMissing {
                                                                    getStatusUpdate2(endpoint: endpoint, total: availableObjsToMigDict.count)
                                                                    createEndpointsQueue(endpointType: endpoint, endpointName: l_xmlName, endPointXML: "", endpointCurrent: counter, endpointCount: availableObjsToMigDict.count, action: "update", sourceEpId: 0, destEpId: 0, ssIconName: "", ssIconId: "0", ssIconUri: "", retry: false) {
                                                                        (result: String) in
                                                                        completion(["skipped endpoint - \(endpoint)", "\(self.availableObjsToMigDict.count)"])
                                                                    }
                                                                } else {
                                                                    endPointByIDQueue(endpoint: endpoint, endpointID: "\(l_xmlID)", endpointCurrent: counter, endpointCount: availableObjsToMigDict.count, action: "update", destEpId: currentEPDict[endpoint]![l_xmlName]!, destEpName: l_xmlName)
                                                                }
                                                            } else {
                                                                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] \(l_xmlName) - create") }
                                                                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] function - endpoint: \(endpoint), endpointID: \(l_xmlID), endpointCurrent: \(counter), endpointCount: \(endpointCount), action: \"create\", destEpId: 0") }
                                                                //                                                                    if (userDefaults.integer(forKey: "copyExisting") != 1) {
                                                                if setting.onlyCopyExisting {
                                                                    getStatusUpdate2(endpoint: endpoint, total: availableObjsToMigDict.count)
                                                                    createEndpointsQueue(endpointType: endpoint, endpointName: l_xmlName, endPointXML: "", endpointCurrent: counter, endpointCount: availableObjsToMigDict.count, action: "create", sourceEpId: 0, destEpId: 0, ssIconName: "", ssIconId: "0", ssIconUri: "", retry: false) {
                                                                        (result: String) in
                                                                        completion(["skipped endpoint - \(endpoint)", "\(self.availableObjsToMigDict.count)"])
                                                                    }
                                                                } else {
                                                                    endPointByIDQueue(endpoint: endpoint, endpointID: "\(l_xmlID)", endpointCurrent: counter, endpointCount: availableObjsToMigDict.count, action: "create", destEpId: 0, destEpName: l_xmlName)
                                                                }
                                                            }
                                                        } else {
                                                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] remove - endpoint: \(endpoint)\t endpointID: \(l_xmlID)\t endpointName: \(l_xmlName)") }
                                                            removeEndpointsQueue(endpointType: endpoint, endPointID: "\(l_xmlID)", endpointName: l_xmlName, endpointCurrent: counter, endpointCount: availableObjsToMigDict.count)
                                                        }   // if !wipeData.on else - end
                                                        counter+=1
                                                    }   // for (l_xmlID, l_xmlName) in availableObjsToMigDict
                                                    if wipeData.on {
                                                        removeEndpointsQueue(endpointType: endpoint, endPointID: "-1", endpointName: "", endpointCurrent: -1, endpointCount: 0)
                                                    }
                                                } else {
                                                    // populate source server under the selective tab
                                                    // print("populate (\(endpoint)) source server under the selective tab")
                                                    delayInt = listDelay(itemCount: availableObjsToMigDict.count)
                                                    for (l_xmlID, l_xmlName) in availableObjsToMigDict {
                                                        sortQ.async { [self] in
                                                            //                                                                print("adding \(l_xmlName) to array")
                                                            availableIDsToMigDict[l_xmlName] = "\(l_xmlID)"
                                                            sourceDataArray.append(l_xmlName)
                                                            
                                                            sourceDataArray = sourceDataArray.sorted{ $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
                                                            
                                                            staticSourceDataArray = sourceDataArray
                                                            updateSelectiveList(objectName: l_xmlName, objectId: "\(l_xmlID)", fileContents: "")
                                                            
                                                            DispatchQueue.main.async { [self] in
                                                                srcSrvTableView.reloadData()
                                                            }
                                                            // slight delay in building the list - visual effect
                                                            usleep(delayInt)
                                                            
                                                            if counter == availableObjsToMigDict.count {
                                                                nodesMigrated += 1
                                                                print("[\(#function)] \(#line) - finished getting \(endpoint)")
                                                                goButtonEnabled(button_status: true)
                                                            }
                                                            counter+=1
                                                        }   // sortQ.async - end
                                                    }   // for (l_xmlID, l_xmlName) in availableObjsToMigDict
                                                }   // if goSender else - end
                                                
                                                completion(displayNames)
                                            }
                                        }
                                    }
                                    
                                    
                                default:
                                    let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                                    if let endpointJSON = json as? [String: Any] {
                                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] endpointJSON: \(endpointJSON))") }
                                        
                                        switch endpoint {
                                        case "packages":
                                            var lookupCount    = 0
                                            var uniquePackages = [String]()
                                            
                                            if let endpointInfo = endpointJSON[endpointParent] as? [Any] {
                                                endpointCount = endpointInfo.count
                                                
                                                
                                                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] Initial count for \(endpoint) found: \(endpointCount)") }
                                                
                                                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] Verify empty dictionary of objects - availableObjsToMigDict count: \(self.availableObjsToMigDict.count)") }
                                                
                                                if endpointCount > 0 {
                                                    
                                                    self.existingEndpoints(skipLookup: false, theDestEndpoint: "\(endpoint)")  { [self]
                                                        (result: (String,String)) in
                                                        if pref.stopMigration {
                                                            rmDELETE()
                                                            completion(["migration stopped", "0"])
                                                            return
                                                        }
                                                        let (resultMessage, _) = result
                                                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] Returned from existing \(endpoint): \(resultMessage)") }
                                                        
                                                        endpointsRead += 1
                                                        // print("[endpointsRead += 1] \(endpoint)")
                                                        endpointCountDict[endpoint] = endpointCount
                                                        
                                                        
                                                        for i in (0..<endpointCount) {
                                                            if i == 0 { availableObjsToMigDict.removeAll() }
                                                            
                                                            let record      = endpointInfo[i] as! [String : AnyObject]
                                                            let packageID   = record["id"] as! Int
                                                            let displayName = record["name"] as! String
                                                            
    //                                                        print("[getEndpoint] \(#line) call PackagesDelegate().getFilename for source")
                                                            PackagesDelegate.shared.getFilename(whichServer: "source", theServer: JamfProServer.source, base64Creds: JamfProServer.base64Creds["source"] ?? "", theEndpoint: "packages", theEndpointID: packageID, skip: wipeData.on, currentTry: 1) { [self]
                                                                (result: (Int,String)) in
                                                                let (_,packageFilename) = wipeData.on ? (packageID,displayName):result
    //                                                        let (_,packageFilename) = wipeData.on ? (packageID,record["name"] as! String):result
    //                                                        print("[ViewController.getEndpoints] result: \(result)")
                                                                lookupCount += 1
                                                                if lookupCount % 50 == 0 {
                                                                    WriteToLog.shared.message(stringOfText: "scanned \(lookupCount) of \(endpointCount) packages on \(JamfProServer.source)")
                                                                }
                                                                if packageFilename != "" && uniquePackages.firstIndex(of: packageFilename) == nil {
                                                                    uniquePackages.append(packageFilename)
                                                                    availableObjsToMigDict[packageID] = packageFilename
                                                                    duplicatePackagesDict[packageFilename] = [displayName]
                                                                }  else {
                                                                    if endpointCountDict[endpoint]! > 0 {
                                                                        endpointCountDict[endpoint]! -= 1
                                                                    }
                                                                    if packageFilename != "" {
                                                                        duplicatePackages = true
                                                                        duplicatePackagesDict[packageFilename]!.append(displayName)
                                                                    } else {
                                                                        // catch packages where the filename could not be looked up
                                                                        if failedPkgNameLookup.firstIndex(of: displayName) == nil {
                                                                            failedPkgNameLookup.append(displayName)
                                                                        }
                                                                    }
                                                                }
                                                                if lookupCount == endpointCount {
                                                                    WriteToLog.shared.message(stringOfText: "scanned \(lookupCount) of \(endpointCount) packages on \(JamfProServer.source)")
                                                                    if duplicatePackages {
                                                                        var message = "\tFilename : Display Name\n"
                                                                        for (pkgFilename, displayNames) in duplicatePackagesDict {
                                                                            if displayNames.count > 1 {
                                                                                for dup in displayNames {
                                                                                    message = "\(message)\t\(pkgFilename) : \(dup)\n"
                                                                                }
                                                                            }
                                                                        }
                                                                        WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] Duplicate references to the same package were found on \(JamfProServer.source)\n\(message)")
                                                                        if setting.fullGUI {
    //                                                                        print("[getEndoints] \(#line) server: \(JamfProServer.source)")
    //                                                                        print("[getEndoints] \(#line) message: \(message)")
                                                                            let theButton = Alert.shared.display(header: "Warning:", message: "Several packages on \(JamfProServer.source), having unique display names, are linked to a single file.  Check the log for 'Duplicate references to the same package' for details.", secondButton: "Stop")
                                                                            if theButton == "Stop" {
                                                                                stopButton(self)
                                                                            }
                                                                        }
                                                                    }
                                                                    if failedPkgNameLookup.count > 0 {
                                                                        WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] 1 or more package filenames on \(JamfProServer.source) could not be verified")
                                                                        WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] Failed package filename lookup: \(failedPkgNameLookup)")
                                                                        if setting.fullGUI {
                                                                            let theButton = Alert.shared.display(header: "Warning:", message: "1 or more package filenames on \(JamfProServer.source) could not be verified and will not be available to migrate.  Check the log for 'Failed package filename lookup' for details.", secondButton: "Stop")
                                                                            if theButton == "Stop" {
                                                                                stopButton(self)
                                                                            }
                                                                        }
                                                                    }
                                                                    
    //                                                              currentEPDict[destEndpoint] = currentEPs
                                                                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] returning existing packages endpoints: \(availableObjsToMigDict)") }
                                                                    
    //                                                            completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
    //                                                            return
                                                                    // make into a func - start
                                                                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] Found total of \(availableObjsToMigDict.count) \(endpoint) to process") }
                                                                    
                                                                    var counter = 1
                                                                    print("[getEndpoints] goSender: \(goSender)")
                                                                    if goSender == "goButton" || goSender == "silent" {
                                                                        
                                                                        counters[endpoint]!["total"] = availableObjsToMigDict.count
                                                                        
                                                                        for (l_xmlID, l_xmlName) in availableObjsToMigDict {
                                                                            if !wipeData.on  {
                                                                                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] check for ID of \(l_xmlName): \(currentEPs[l_xmlName] ?? 0)") }
                                                                                
                                                                                if currentEPDict[endpoint]?[l_xmlName] != nil {
                                                                                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] \(l_xmlName) already exists") }
                                                                                    if setting.onlyCopyMissing {
                                                                                        getStatusUpdate2(endpoint: endpoint, total: availableObjsToMigDict.count)
                                                                                        createEndpointsQueue(endpointType: endpoint, endpointName: l_xmlName, endPointXML: "", endpointCurrent: counter, endpointCount: availableObjsToMigDict.count, action: "update", sourceEpId: 0, destEpId: 0, ssIconName: "", ssIconId: "0", ssIconUri: "", retry: false) {
                                                                                            (result: String) in
                                                                                            completion(["skipped endpoint - \(endpoint)", "\(self.availableObjsToMigDict.count)"])
                                                                                        }
                                                                                    } else {
                                                                                        endPointByIDQueue(endpoint: endpoint, endpointID: "\(l_xmlID)", endpointCurrent: counter, endpointCount: availableObjsToMigDict.count, action: "update", destEpId: currentEPDict[endpoint]![l_xmlName]!, destEpName: l_xmlName)
                                                                                    }
                                                                                } else {
                                                                                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] \(l_xmlName) - create") }
                                                                                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] function - endpoint: \(endpoint), endpointID: \(l_xmlID), endpointCurrent: \(counter), endpointCount: \(endpointCount), action: \"create\", destEpId: 0") }
                                                                                    if setting.onlyCopyExisting {
                                                                                        getStatusUpdate2(endpoint: endpoint, total: availableObjsToMigDict.count)
                                                                                        createEndpointsQueue(endpointType: endpoint, endpointName: l_xmlName, endPointXML: "", endpointCurrent: counter, endpointCount: availableObjsToMigDict.count, action: "create", sourceEpId: 0, destEpId: 0, ssIconName: "", ssIconId: "0", ssIconUri: "", retry: false) {
                                                                                            (result: String) in
                                                                                            completion(["skipped endpoint - \(endpoint)", "\(self.availableObjsToMigDict.count)"])
                                                                                        }
                                                                                    } else {
                                                                                        endPointByIDQueue(endpoint: endpoint, endpointID: "\(l_xmlID)", endpointCurrent: counter, endpointCount: availableObjsToMigDict.count, action: "create", destEpId: 0, destEpName: l_xmlName)
                                                                                    }
                                                                                }
                                                                            } else {
                                                                                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] remove - endpoint: \(endpoint)\t endpointID: \(l_xmlID)\t endpointName: \(l_xmlName)") }
                                                                                if wipeData.on {
                                                                                    removeEndpointsQueue(endpointType: endpoint, endPointID: "\(l_xmlID)", endpointName: l_xmlName, endpointCurrent: counter, endpointCount: availableObjsToMigDict.count)
                                                                                }
                                                                            }   // if !wipeData.on else - end
                                                                            counter+=1
                                                                        }   // for (l_xmlID, l_xmlName) in availableObjsToMigDict
                                                                        removeEndpointsQueue(endpointType: endpoint, endPointID: "-1", endpointName: "", endpointCurrent: -1, endpointCount: 0)
                                                                    } else {
                                                                        // populate source server under the selective tab - bulk
//                                                                        print("[getEndpoints] availableObjsToMigDict: \(availableObjsToMigDict)")
                                                                        if !pref.stopMigration {
    //                                                                      print("-populate (\(endpoint)) source server under the selective tab")
                                                                            delayInt = (availableObjsToMigDict.count > 1000) ? 0:listDelay(itemCount: availableObjsToMigDict.count)
                                                                            for (l_xmlID, l_xmlName) in availableObjsToMigDict {
                                                                                sortQ.async { [self] in
    //                                                                              print("[getEndpoints] adding \(l_xmlName) to array")
                                                                                    availableIDsToMigDict[l_xmlName] = "\(l_xmlID)"
                                                                                    sourceDataArray.append(l_xmlName)
                                                                                    sourceDataArray = sourceDataArray.sorted{$0.localizedCaseInsensitiveCompare($1) == .orderedAscending}
                                                                                    
                                                                                    staticSourceDataArray = sourceDataArray
                                                                                    
                                                                                    updateSelectiveList(objectName: l_xmlName, objectId: "\(l_xmlID)", fileContents: "")
                                                                                    // slight delay in building the list - visual effect
                                                                                    usleep(delayInt)
                                                                                    
                                                                                    if counter == availableObjsToMigDict.count {
                                                                                        nodesMigrated += 1
                                                                                        print("[\(#function)] \(#line) - finished getting \(endpoint)")
                                                                                        goButtonEnabled(button_status: true)
                                                                                    }
                                                                                    counter+=1
                                                                                }   // sortQ.async - end
                                                                            }   // for (l_xmlID, l_xmlName) in availableObjsToMigDict
                                                                        }   // if !pref.stopMigration
                                                                    }   // if goSender else - end
                                                                    // make into a func - end
                                                                    
                                                                    if nodeIndex < nodesToMigrate.count - 1 {
                                                                        readNodes(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1)
                                                                    }
                                                                    if !(setting.onlyCopyMissing || setting.onlyCopyExisting) {
                                                                        completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                                                                    }
                                                                    
                                                                }
                                                            }
                                                        } // for i - end
                                                    } // existingEndpoints(skipLookup: false, theDestEndpoint - end
                                                } else {
                                                    // no packages were found
                                                    endpointsRead += 1
                                                    // print("[endpointsRead += 1] \(endpoint)")
                                                    
                                                    //                                            self.nodesMigrated+=1
                                                    getStatusUpdate2(endpoint: endpoint, total: 0)
                                                    putStatusUpdate2(endpoint: endpoint, total: 0)
                                                    
                                                    
                                                    //                                            if endpoint == self.objectsToMigrate.last {
                                                    //                                                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] Reached last object to migrate: \(endpoint)") }
                                                    //                                                self.rmDELETE()
                                                    //                                                completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                                                    //                                            }
                                                    if nodeIndex < nodesToMigrate.count - 1 {
                                                        self.readNodes(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1)
                                                    }
                                                    completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                                                }   // if endpointCount > 0 - end
                                            } else {   // end if let endpointInfo
                                                if nodeIndex < nodesToMigrate.count - 1 {
                                                    self.readNodes(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1)
                                                }
                                                completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                                            }
                                            
                                        case "buildings", "advancedcomputersearches", "macapplications", "categories", "classes", "computers", "computerextensionattributes", "departments", "distributionpoints", "directorybindings", "diskencryptionconfigurations", "dockitems", "ldapservers", "networksegments", "osxconfigurationprofiles", "patchpolicies", "printers", "scripts", "sites", "softwareupdateservers", "users", "mobiledeviceconfigurationprofiles", "mobiledeviceapplications", "advancedmobiledevicesearches", "mobiledeviceextensionattributes", "mobiledevices", "userextensionattributes", "advancedusersearches", "restrictedsoftware":
                                            if let endpointInfo = endpointJSON[endpointParent] as? [Any] {
                                                endpointCount = endpointInfo.count
                                                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] Initial count for \(endpoint) found: \(endpointCount)") }
                                                
                                                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] Verify empty dictionary of objects - availableObjsToMigDict count: \(self.availableObjsToMigDict.count)") }
                                                
                                                if endpointCount > 0 {
                                                    
                                                    self.existingEndpoints(skipLookup: false, theDestEndpoint: "\(endpoint)")  { [self]
                                                        (result: (String,String)) in
                                                        if pref.stopMigration {
                                                            rmDELETE()
                                                            completion(["migration stopped", "0"])
                                                            return
                                                        }
                                                        let (resultMessage, _) = result
                                                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] Returned from existing \(endpoint): \(resultMessage)") }
                                                        
                                                        endpointsRead += 1
                                                        // print("[endpointsRead += 1] \(endpoint)")
                                                        
                                                        endpointCountDict[endpoint] = endpointCount
                                                        for i in (0..<endpointCount) {
                                                            if i == 0 { availableObjsToMigDict.removeAll() }
                                                            
                                                            let record = endpointInfo[i] as! [String : AnyObject]
                                                            
                                                            if record["name"] != nil {
                                                                availableObjsToMigDict[record["id"] as! Int] = record["name"] as! String?
                                                            } else {
                                                                availableObjsToMigDict[record["id"] as! Int] = ""
                                                            }
                                                            
                                                        }   // for i in (0..<endpointCount) end
                                                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] Found total of \(availableObjsToMigDict.count) \(endpoint) to process") }
                                                        
                                                        var counter = 1
                                                        if goSender == "goButton" || !setting.fullGUI {
                                                            
                                                            counters[endpoint]!["total"] = availableObjsToMigDict.count
                                                            
                                                            for (l_xmlID, l_xmlName) in availableObjsToMigDict {
                                                                if pref.stopMigration { break }
                                                                if !wipeData.on  {
                                                                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] check for ID on \(l_xmlName): \(currentEPs[l_xmlName] ?? 0)") }
                                                                    
                                                                    if currentEPDict[endpoint]?[l_xmlName] != nil {
                                                                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] \(l_xmlName) already exists") }
                                                                        
                                                                        if setting.onlyCopyMissing {
                                                                            getStatusUpdate2(endpoint: endpoint, total: availableObjsToMigDict.count)
                                                                            createEndpointsQueue(endpointType: endpoint, endpointName: l_xmlName, endPointXML: "", endpointCurrent: counter, endpointCount: availableObjsToMigDict.count, action: "update", sourceEpId: 0, destEpId: 0, ssIconName: "", ssIconId: "0", ssIconUri: "", retry: false) {
                                                                                (result: String) in
                                                                                completion(["skipped endpoint - \(endpoint)", "\(self.availableObjsToMigDict.count)"])
                                                                            }
                                                                        } else {
                                                                            endPointByIDQueue(endpoint: endpoint, endpointID: "\(l_xmlID)", endpointCurrent: counter, endpointCount: availableObjsToMigDict.count, action: "update", destEpId: currentEPDict[endpoint]![l_xmlName]!, destEpName: l_xmlName)
                                                                        }
                                                                    } else {
                                                                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] \(l_xmlName) - create") }
                                                                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] function - endpoint: \(endpoint), endpointID: \(l_xmlID), endpointCurrent: \(counter), endpointCount: \(endpointCount), action: \"create\", destEpId: 0") }
    //                                                                    if (userDefaults.integer(forKey: "copyExisting") != 1) {
                                                                        if setting.onlyCopyExisting {
                                                                            getStatusUpdate2(endpoint: endpoint, total: availableObjsToMigDict.count)
                                                                            createEndpointsQueue(endpointType: endpoint, endpointName: l_xmlName, endPointXML: "", endpointCurrent: counter, endpointCount: availableObjsToMigDict.count, action: "create", sourceEpId: 0, destEpId: 0, ssIconName: "", ssIconId: "0", ssIconUri: "", retry: false) {
                                                                                (result: String) in
                                                                                completion(["skipped endpoint - \(endpoint)", "\(self.availableObjsToMigDict.count)"])
                                                                            }
                                                                        } else {
                                                                            endPointByIDQueue(endpoint: endpoint, endpointID: "\(l_xmlID)", endpointCurrent: counter, endpointCount: availableObjsToMigDict.count, action: "create", destEpId: 0, destEpName: l_xmlName)
                                                                        }
                                                                    }
                                                                } else {
                                                                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] remove - endpoint: \(endpoint)\t endpointID: \(l_xmlID)\t endpointName: \(l_xmlName)") }
                                                                    removeEndpointsQueue(endpointType: endpoint, endPointID: "\(l_xmlID)", endpointName: l_xmlName, endpointCurrent: counter, endpointCount: availableObjsToMigDict.count)
                                                                }   // if !wipeData.on else - end
                                                                counter+=1
                                                            }   // for (l_xmlID, l_xmlName) in availableObjsToMigDict
                                                            if wipeData.on {
                                                                removeEndpointsQueue(endpointType: endpoint, endPointID: "-1", endpointName: "", endpointCurrent: -1, endpointCount: 0)
                                                            }
                                                        } else {
                                                            // populate source server under the selective tab
                                                            // print("populate (\(endpoint)) source server under the selective tab")
                                                            delayInt = listDelay(itemCount: availableObjsToMigDict.count)
                                                            for (l_xmlID, l_xmlName) in availableObjsToMigDict {
                                                                sortQ.async { [self] in
    //                                                                print("adding \(l_xmlName) to array")
                                                                    availableIDsToMigDict[l_xmlName] = "\(l_xmlID)"
                                                                    sourceDataArray.append(l_xmlName)
                                                                    //                                                        if availableIDsToMigDict.count == sourceDataArray.count {
                                                                    sourceDataArray = sourceDataArray.sorted{$0.localizedCaseInsensitiveCompare($1) == .orderedAscending}
                                                                    
                                                                    staticSourceDataArray = sourceDataArray
                                                                    updateSelectiveList(objectName: l_xmlName, objectId: "\(l_xmlID)", fileContents: "")
                                                                    
                                                                    
                                                                    DispatchQueue.main.async { [self] in
                                                                        srcSrvTableView.reloadData()
                                                                    }
                                                                    // slight delay in building the list - visual effect
                                                                    usleep(delayInt)
                                                                    
                                                                    if counter == availableObjsToMigDict.count {
                                                                        nodesMigrated += 1
                                                                        print("[\(#function)] \(#line) - finished getting \(endpoint)")
                                                                        goButtonEnabled(button_status: true)
                                                                    }
                                                                    counter+=1
                                                                }   // sortQ.async - end
                                                            }   // for (l_xmlID, l_xmlName) in availableObjsToMigDict
                                                            
                                                        }   // if goSender else - end
                                                    }   // existingEndpoints - end
                                                } else {
                                                    //                                            self.nodesMigrated+=1
                                                    getStatusUpdate2(endpoint: endpoint, total: 0)
                                                    putStatusUpdate2(endpoint: endpoint, total: 0)
                                                    
                                                    self.endpointsRead += 1
                                                }   // if endpointCount > 0 - end
                                                if nodeIndex < nodesToMigrate.count - 1 {
                                                    self.readNodes(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1)
                                                }
                                                completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                                            } else {   // end if let endpointInfo
                                                if nodeIndex < nodesToMigrate.count - 1 {
                                                    self.readNodes(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1)
                                                }
                                                completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                                            }
                                            
                                        case "computergroups", "mobiledevicegroups", "usergroups":
                                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] processing device groups") }
                                            if let endpointInfo = endpointJSON[self.endpointDefDict["\(endpoint)"]!] as? [Any] {
                                                
                                                endpointCount = endpointInfo.count
                                                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] groups found: \(endpointCount)") }
                                                
                                                var smartGroupDict: [Int: String] = [:]
                                                var staticGroupDict: [Int: String] = [:]
                                                
                                                if endpointCount > 0 {
                                                    self.existingEndpoints(skipLookup: false, theDestEndpoint: "\(endpoint)")  { [self]
                                                        (result: (String,String)) in
                                                        if pref.stopMigration {
                                                            rmDELETE()
                                                            completion(["migration stopped", "0"])
                                                            return
                                                        }
                                                        //                                                let (resultMessage, _) = result
                                                        // find number of groups
                                                        smartCount = 0
                                                        staticCount = 0
                                                        var excludeCount = 0
                                                        
                                                        endpointsRead += 1
                                                        // print("[endpointsRead += 1] \(endpoint)")
                                                        
                                                        // split computergroups into smart and static - start
                                                        for i in (0..<endpointCount) {
                                                            let record = endpointInfo[i] as! [String : AnyObject]
                                                            
                                                            let smart: Bool = (record["is_smart"] as! Bool)
                                                            if smart {
                                                                //smartCount += 1
                                                                if (record["name"] as! String? != "All Managed Clients" && record["name"] as! String? != "All Managed Servers" && record["name"] as! String? != "All Managed iPads" && record["name"] as! String? != "All Managed iPhones" && record["name"] as! String? != "All Managed iPod touches") || export.backupMode {
                                                                    smartGroupDict[record["id"] as! Int] = record["name"] as! String?
                                                                }
                                                            } else {
                                                                //staticCount += 1
                                                                staticGroupDict[record["id"] as! Int] = record["name"] as! String?
                                                            }
                                                        }
                                                        
                                                        if (smartGroupDict.count == 0 || staticGroupDict.count == 0) && !(smartGroupDict.count == 0 && staticGroupDict.count == 0) {
                                                            nodesMigrated+=1
                                                        }
                                                        // split devicegroups into smart and static - end
                                                        
                                                        // groupType is "" for bulk migrations, smart/static for selective
                                                        switch endpoint {
                                                        case "computergroups":
                                                            if (!smartComputerGrpsSelected && groupType == "") || groupType == "static" {
                                                                excludeCount += smartGroupDict.count
                                                            }
                                                            if (!staticComputerGrpsSelected && groupType == "") || groupType == "smart" {
                                                                excludeCount += staticGroupDict.count
                                                            }
                                                            if smartComputerGrpsSelected && staticComputerGrpsSelected && groupType == "" {
                                                                nodesMigrated-=1
                                                            }
                                                        case "mobiledevicegroups":
                                                            if (!smartIosGrpsSelected && groupType == "") || groupType == "static" {
                                                                excludeCount += smartGroupDict.count
                                                            }
                                                            if (!staticIosGrpsSelected && groupType == "") || groupType == "smart" {
                                                                excludeCount += staticGroupDict.count
                                                            }
                                                            if smartIosGrpsSelected && staticIosGrpsSelected {
                                                                nodesMigrated-=1
                                                            }
                                                        case "usergroups":
                                                            if (!smartUserGrpsSelected && groupType == "") || groupType == "static" {
                                                                excludeCount += smartGroupDict.count
                                                            }
                                                            if (!staticUserGrpsSelected && groupType == "") || groupType == "smart" {
                                                                excludeCount += staticGroupDict.count
                                                            }
                                                            if smartUserGrpsSelected && staticUserGrpsSelected && groupType == "" {
                                                                nodesMigrated-=1
                                                            }
                                                            
                                                        default: break
                                                        }
                                                        
                                                        //                                                print(" smart_comp_grps_button.state.rawValue: \(smart_comp_grps_button.state.rawValue)")
                                                        //                                                print("static_comp_grps_button.state.rawValue: \(static_comp_grps_button.state.rawValue)")
                                                        //                                                print("                                  groupType: \(groupType)")
                                                        //                                                print("                               excludeCount: \(excludeCount)")
                                                        
                                                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] \(smartGroupDict.count) smart groups") }
                                                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] \(staticGroupDict.count) static groups") }
                                                        var currentGroupDict: [Int: String] = [:]
                                                        
                                                        // verify we have some groups
                                                        for g in (0...1) {
                                                            currentGroupDict.removeAll()
                                                            var groupCount = 0
                                                            var localEndpoint = endpoint
                                                            switch endpoint {
                                                            case "computergroups":
                                                                if (smartComputerGrpsSelected || (goSender != "goButton" && groupType == "smart")) && (g == 0) {
                                                                    currentGroupDict = smartGroupDict
                                                                    groupCount = currentGroupDict.count
                                                                    localEndpoint = "smartcomputergroups"
                                                                }
                                                                if (staticComputerGrpsSelected || (goSender != "goButton" && groupType == "static")) && (g == 1) {
                                                                    currentGroupDict = staticGroupDict
                                                                    groupCount = currentGroupDict.count
                                                                    localEndpoint = "staticcomputergroups"
                                                                }
                                                            case "mobiledevicegroups":
                                                                if ((smartIosGrpsSelected) || (goSender != "goButton" && groupType == "smart")) && (g == 0) {
                                                                    currentGroupDict = smartGroupDict
                                                                    groupCount = currentGroupDict.count
                                                                    localEndpoint = "smartmobiledevicegroups"
                                                                }
                                                                if ((staticIosGrpsSelected) || (goSender != "goButton" && groupType == "static")) && (g == 1) {
                                                                    currentGroupDict = staticGroupDict
                                                                    groupCount = currentGroupDict.count
                                                                    localEndpoint = "staticmobiledevicegroups"
                                                                }
                                                            case "usergroups":
                                                                if ((smartUserGrpsSelected) || (goSender != "goButton" && groupType == "smart")) && (g == 0) {
                                                                    currentGroupDict = smartGroupDict
                                                                    groupCount = currentGroupDict.count
                                                                    //                                                        DeviceGroupType = "smartcomputergroups"
                                                                    //                                                        print("usergroups smart - DeviceGroupType: \(DeviceGroupType)")
                                                                    localEndpoint = "smartusergroups"
                                                                }
                                                                if ((staticUserGrpsSelected) || (goSender != "goButton" && groupType == "static")) && (g == 1) {
                                                                    currentGroupDict = staticGroupDict
                                                                    groupCount = currentGroupDict.count
                                                                    //                                                        DeviceGroupType = "staticcomputergroups"
                                                                    //                                                        print("usergroups static - DeviceGroupType: \(DeviceGroupType)")
                                                                    localEndpoint = "staticusergroups"
                                                                }
                                                            default: break
                                                            }
                                                            
                                                            var counter = 1
                                                            delayInt = listDelay(itemCount: currentGroupDict.count)
                                                            
                                                            endpointCountDict[localEndpoint] = groupCount
                                                            
                                                            if currentGroupDict.count == 0 && (localEndpoint == "smartcomputergroups" || localEndpoint == "staticcomputergroups" || localEndpoint == "smartmobiledevicegroups" || localEndpoint == "staticmobiledevicegroups") {
                                                                getStatusUpdate2(endpoint: localEndpoint, total: 0)
                                                                putStatusUpdate2(endpoint: localEndpoint, total: 0)
                                                            }
                                                            
                                                            counters[endpoint]!["total"] = currentGroupDict.count
                                                            
                                                            for (l_xmlID, l_xmlName) in currentGroupDict {
                                                                availableObjsToMigDict[l_xmlID] = l_xmlName
                                                                if goSender == "goButton" || goSender == "silent" {
                                                                    if !wipeData.on  {
                                                                        //need to call existingEndpoints here to keep proper order?
                                                                        if currentEPs[l_xmlName] != nil {
                                                                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] \(l_xmlName) already exists") }
                                                                            
                                                                            if setting.onlyCopyMissing {
                                                                                    getStatusUpdate2(endpoint: endpoint, total: availableObjsToMigDict.count)
                                                                                    createEndpointsQueue(endpointType: endpoint, endpointName: l_xmlName, endPointXML: "", endpointCurrent: counter, endpointCount: availableObjsToMigDict.count, action: "update", sourceEpId: 0, destEpId: 0, ssIconName: "", ssIconId: "0", ssIconUri: "", retry: false) {
                                                                                        (result: String) in
                                                                                        completion(["skipped endpoint - \(endpoint)", "\(self.availableObjsToMigDict.count)"])
                                                                                    }
                                                                                } else {
                                                                                    endPointByIDQueue(endpoint: localEndpoint, endpointID: "\(l_xmlID)", endpointCurrent: counter, endpointCount: groupCount, action: "update", destEpId: currentEPs[l_xmlName]!, destEpName: l_xmlName)
                                                                                }
                                                                            
                                                                        } else {
                                                                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] \(l_xmlName) - create") }
                                                                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] function - endpoint: \(localEndpoint), endpointID: \(l_xmlID), endpointCurrent: \(counter), endpointCount: \(groupCount), action: \"create\", destEpId: 0") }
                                                                            
                                                                            if setting.onlyCopyExisting {
                                                                                getStatusUpdate2(endpoint: endpoint, total: availableObjsToMigDict.count)
                                                                                createEndpointsQueue(endpointType: endpoint, endpointName: l_xmlName, endPointXML: "", endpointCurrent: counter, endpointCount: availableObjsToMigDict.count, action: "create", sourceEpId: 0, destEpId: 0, ssIconName: "", ssIconId: "0", ssIconUri: "", retry: false) {
                                                                                    (result: String) in
                                                                                    completion(["skipped endpoint - \(endpoint)", "\(self.availableObjsToMigDict.count)"])
                                                                                }
                                                                            } else {
                                                                                endPointByIDQueue(endpoint: localEndpoint, endpointID: "\(l_xmlID)", endpointCurrent: counter, endpointCount: groupCount, action: "create", destEpId: 0, destEpName: l_xmlName)
                                                                            }
                                                                            
                                                                        }
                                                                    } else {
                                                                        removeEndpointsQueue(endpointType: localEndpoint, endPointID: "\(l_xmlID)", endpointName: l_xmlName, endpointCurrent: counter, endpointCount: groupCount)
                                                                    }   // if !wipeData.on else - end
                                                                    counter += 1
                                                                } else {
                                                                    // populate source server under the selective tab
                                                                    sortQ.async { [self] in
    //                                                                print("adding \(l_xmlName) to array")
                                                                        availableIDsToMigDict[l_xmlName] = "\(l_xmlID)"
                                                                        sourceDataArray.append(l_xmlName)
                                                                        
                                                                        staticSourceDataArray = sourceDataArray
                                                                        updateSelectiveList(objectName: l_xmlName, objectId: "\(l_xmlID)", fileContents: "")
                                                                        
    //                                                                    DispatchQueue.main.async { [self] in
    //                                                                        srcSrvTableView.reloadData()
    //                                                                    }
                                                                        // slight delay in building the list - visual effect
                                                                        usleep(delayInt)
                                                                        
                                                                        if counter == sourceDataArray.count {
                                                                            
                                                                            sortList(theArray: sourceDataArray) { [self]
                                                                                (result: [String]) in
                                                                                sourceDataArray = result
                                                                                DispatchQueue.main.async { [self] in
                                                                                    srcSrvTableView.reloadData()
                                                                                }
                                                                                print("[\(#function)] \(#line) - finished getting \(endpoint)")
                                                                                goButtonEnabled(button_status: true)
                                                                            }
                                                                        }
                                                                        counter += 1
                                                                    }   // sortQ.async - end
                                                                }   // if goSender else - end
                                                            }   // for (l_xmlID, l_xmlName) - end
                                                            
                                                            nodesMigrated+=1
                                                            if wipeData.on && (goSender == "goButton" || goSender == "silent") {
                                                                removeEndpointsQueue(endpointType: endpoint, endPointID: "-1", endpointName: "", endpointCurrent: -1, endpointCount: 0)
                                                            }
                                                            
                                                        }   //for g in (0...1) - end
                                                    }   // existingEndpoints(skipLookup: false, theDestEndpoint: "\(endpoint)") - end
                                                } else {    //if endpointCount > 0 - end
                                                    //                                            self.nodesMigrated+=1
                                                    getStatusUpdate2(endpoint: endpoint, total: 0)
                                                    putStatusUpdate2(endpoint: endpoint, total: 0)
                                                    
                                                    self.endpointsRead += 1
                                                    // print("[endpointsRead += 1] \(endpoint)")
                                                    //                                            if endpoint == self.objectsToMigrate.last {
                                                    //                                                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] Reached last object to migrate: \(endpoint)") }
                                                    //                                                self.rmDELETE()
                                                    //                                            }
                                                }   // else if endpointCount > 0 - end
                                                if nodeIndex < nodesToMigrate.count - 1 {
                                                    self.readNodes(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1)
                                                }
                                                completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                                            } else {  // if let endpointInfo = endpointJSON["computer_groups"] - end
                                                if nodeIndex < nodesToMigrate.count - 1 {
                                                    self.readNodes(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1)
                                                }
                                                completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                                            }
                                            
                                        case "policies":
                                            //                                    print("[ViewController.getEndpoints] processing policies")
                                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] processing policies") }
                                            if let endpointInfo = endpointJSON[endpoint] as? [Any] {
                                                endpointCount = endpointInfo.count
                                                
                                                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] policies found: \(endpointCount)") }
                                                
                                                var computerPoliciesDict: [Int: String] = [:]
                                                
                                                if endpointCount > 0 {
                                                    if pref.stopMigration {
                                                        self.rmDELETE()
                                                        completion(["migration stopped", "0"])
                                                        return
                                                    }
                                                    if setting.fullGUI {
                                                        // display migrateDependencies button
                                                        DispatchQueue.main.async {
                                                            if !wipeData.on {
                                                                self.migrateDependencies.isHidden = false
                                                            }
                                                        }
                                                    }
                                                    
                                                    // create dictionary of existing policies
                                                    self.existingEndpoints(skipLookup: false, theDestEndpoint: "policies")  { [self]
                                                        (result: (String,String)) in
                                                        let (resultMessage, _) = result
                                                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] policies - returned from existing endpoints: \(resultMessage)") }
                                                        
                                                        // filter out policies created from jamf remote (casper remote) - start
                                                        for i in (0..<endpointCount) {
                                                            let record = endpointInfo[i] as! [String : AnyObject]
                                                            let nameCheck = record["name"] as! String
                                                            
                                                            if nameCheck.range(of:"[0-9]{4}-[0-9]{2}-[0-9]{2} at [0-9]", options: .regularExpression) == nil && nameCheck != "Update Inventory" {
                                                                computerPoliciesDict[record["id"] as! Int] = nameCheck
                                                            }
                                                        }
                                                        // filter out policies created from casper remote - end
                                                        
                                                        availableObjsToMigDict = computerPoliciesDict
                                                        let nonRemotePolicies = computerPoliciesDict.count
                                                        var counter = 1
                                                        
                                                        delayInt = listDelay(itemCount: computerPoliciesDict.count)
                                                        //                                                print("[ViewController.getEndpoints] [policies] policy count: \(nonRemotePolicies)")    // appears 2
                                                        
                                                        endpointsRead += 1
                                                        // print("[endpointsRead += 1] \(endpoint)")
                                                        endpointCountDict[endpoint] = computerPoliciesDict.count
                                                        if computerPoliciesDict.count == 0 {
                                                            endpointsRead += 1
                                                            nodesMigrated+=1    // ;print("added node: \(endpoint) - getEndpoints2")
                                                            // print("[endpointsRead += 1] \(endpoint)")
                                                        } else {
                                                            
                                                            counters[endpoint]!["total"] = computerPoliciesDict.count
                                                            
                                                            for (l_xmlID, l_xmlName) in computerPoliciesDict {
                                                                if goSender == "goButton" || goSender == "silent" {
                                                                    if !wipeData.on  {
                                                                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] check for ID on \(l_xmlName): \(String(describing: currentEPs[l_xmlName]))") }
                                                                        //                                                        if currentEPs[l_xmlName] != nil {
                                                                        if currentEPDict[endpoint]?[l_xmlName] != nil {
                                                                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] \(l_xmlName) already exists") }
                                                                            
                                                                            if setting.onlyCopyMissing {
                                                                                getStatusUpdate2(endpoint: endpoint, total: availableObjsToMigDict.count)
                                                                                createEndpointsQueue(endpointType: endpoint, endpointName: l_xmlName, endPointXML: "", endpointCurrent: counter, endpointCount: nonRemotePolicies, action: "update", sourceEpId: 0, destEpId: 0, ssIconName: "", ssIconId: "0", ssIconUri: "", retry: false) {
                                                                                    (result: String) in
                                                                                    completion(["skipped endpoint - \(endpoint)", "\(self.availableObjsToMigDict.count)"])
                                                                                }
                                                                            } else {
                                                                                endPointByIDQueue(endpoint: endpoint, endpointID: "\(l_xmlID)", endpointCurrent: counter, endpointCount: nonRemotePolicies, action: "update", destEpId: currentEPDict[endpoint]![l_xmlName]!, destEpName: l_xmlName)
                                                                            }
                                                                            
                                                                        } else {
                                                                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] \(l_xmlName) - create") }
                                                                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] function - endpoint: \(endpoint), endpointID: \(l_xmlID), endpointCurrent: \(counter), endpointCount: \(endpointCount), action: \"create\", destEpId: 0") }
                                                                            
                                                                            if setting.onlyCopyExisting {
                                                                                getStatusUpdate2(endpoint: endpoint, total: availableObjsToMigDict.count)
                                                                                createEndpointsQueue(endpointType: endpoint, endpointName: l_xmlName, endPointXML: "", endpointCurrent: counter, endpointCount: nonRemotePolicies, action: "create", sourceEpId: 0, destEpId: 0, ssIconName: "", ssIconId: "0", ssIconUri: "", retry: false) {
                                                                                    (result: String) in
                                                                                    completion(["skipped endpoint - \(endpoint)", "\(self.availableObjsToMigDict.count)"])
                                                                                }
                                                                            } else {
                                                                                endPointByIDQueue(endpoint: endpoint, endpointID: "\(l_xmlID)", endpointCurrent: counter, endpointCount: nonRemotePolicies, action: "create", destEpId: 0, destEpName: l_xmlName)
                                                                            }
                                                                            
                                                                        }
                                                                    } else {
                                                                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] remove - endpoint: \(endpoint)\t endpointID: \(l_xmlID)\t endpointName: \(l_xmlName)") }
                                                                        removeEndpointsQueue(endpointType: endpoint, endPointID: "\(l_xmlID)", endpointName: l_xmlName, endpointCurrent: counter, endpointCount: nonRemotePolicies)
                                                                    }   // if !wipeData.on else - end
                                                                    counter += 1
                                                                } else {
                                                                    // populate source server under the selective tab
                                                                    sortQ.async { [self] in
                                                                        availableIDsToMigDict[l_xmlName+" (\(l_xmlID))"] = "\(l_xmlID)"
                                                                        sourceDataArray.append(l_xmlName+" (\(l_xmlID))")
                                                                        sourceDataArray = sourceDataArray.sorted{$0.localizedCaseInsensitiveCompare($1) == .orderedAscending}
                                                                        
                                                                        staticSourceDataArray = sourceDataArray
                                                                        updateSelectiveList(objectName: l_xmlName, objectId: "\(l_xmlID)", fileContents: "")
                                                                        
    //                                                                    DispatchQueue.main.async { [self] in
    //                                                                        srcSrvTableView.reloadData()
    //                                                                    }
                                                                        // slight delay in building the list - visual effect
                                                                        usleep(delayInt)
                                                                        
                                                                        if counter == computerPoliciesDict.count {
                                                                            nodesMigrated += 1
                                                                            print("[\(#function)] \(#line) - finished getting \(endpoint)")
                                                                            goButtonEnabled(button_status: true)
                                                                        }
                                                                        counter+=1
                                                                    }   // sortQ.async - end
                                                                    
                                                                }   // if goSender else - end
                                                            }   // for (l_xmlID, l_xmlName) in computerPoliciesDict - end
                                                        }   // else for (l_xmlID, l_xmlName) - end
                                                        if wipeData.on && (goSender == "goButton" || goSender == "silent") {
                                                            removeEndpointsQueue(endpointType: endpoint, endPointID: "-1", endpointName: "", endpointCurrent: -1, endpointCount: 0)
                                                        }
                                                    }   // existingEndpoints - end
                                                } else {
                                                    //                                            self.nodesMigrated+=1
                                                    getStatusUpdate2(endpoint: endpoint, total: 0)
                                                    putStatusUpdate2(endpoint: endpoint, total: 0)
                                                    
                                                    endpointsRead += 1
                                                    // print("[endpointsRead += 1] \(endpoint)")
                                                    //                                            if endpoint == self.objectsToMigrate.last {
                                                    //                                                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] Reached last object to migrate: \(endpoint)") }
                                                    //                                                self.rmDELETE()
                                                    ////                                                completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                                                    //                                            }
                                                    if nodeIndex < nodesToMigrate.count - 1 {
                                                        self.readNodes(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1)
                                                    }
                                                    completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                                                }   // if endpointCount > 0
                                                if nodeIndex < nodesToMigrate.count - 1 {
                                                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] Read next node: \(nodesToMigrate[nodeIndex+1])") }
                                                    self.readNodes(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1)
                                                }
                                                //                                        print("[ViewController.getEndpoints] [policies] Got endpoint - \(endpoint)", "\(endpointCount)")
                                                completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                                            } else {   //if let endpointInfo = endpointJSON - end
                                                if nodeIndex < nodesToMigrate.count - 1 {
                                                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] Unable to read \(endpoint).  Read next node: \(nodesToMigrate[nodeIndex+1])") }
                                                    self.readNodes(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1)
                                                }
                                                completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                                            }
                                            
                                        case "jamfusers", "jamfgroups":
                                            let accountsDict = endpointJSON as [String: Any]
                                            let usersGroups = accountsDict["accounts"] as! [String: Any]
                                            
                                            if let endpointInfo = usersGroups[endpointParent] as? [Any] {
                                                endpointCount = endpointInfo.count
                                                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] Initial count for \(endpoint) found: \(endpointCount)") }
                                                
                                                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] Verify empty dictionary of objects - availableObjsToMigDict count: \(self.availableObjsToMigDict.count)") }
                                                
                                                if endpointCount > 0 {
                                                    
                                                    self.existingEndpoints(skipLookup: false, theDestEndpoint: "ldapservers")  {
                                                        (result: (String,String)) in
                                                        if pref.stopMigration {
                                                            self.rmDELETE()
                                                            completion(["migration stopped", "0"])
                                                            return
                                                        }
                                                        let (resultMessage, _) = result
                                                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[getEndpoints-LDAP] Returned from existing ldapservers: \(resultMessage)") }
                                                        
                                                        self.existingEndpoints(skipLookup: false, theDestEndpoint: endpoint)  { [self]
                                                            (result: (String,String)) in
                                                            let (resultMessage, _) = result
                                                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] Returned from existing \(node): \(resultMessage)") }
                                                            
                                                            endpointsRead += 1
                                                            // print("[endpointsRead += 1] \(endpoint)")
                                                            endpointCountDict[endpoint] = endpointCount
                                                            
                                                            counters[endpoint]!["total"] = endpointCount
                                                            
                                                            for i in (0..<endpointCount) {
                                                                if i == 0 { availableObjsToMigDict.removeAll() }
                                                                
                                                                let record = endpointInfo[i] as! [String : AnyObject]
                                                                if !(endpoint == "jamfusers" && record["name"] as! String? == dest_user) {
                                                                    availableObjsToMigDict[record["id"] as! Int] = record["name"] as! String?
                                                                }
                                                                
                                                                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] Current number of \(endpoint) to process: \(availableObjsToMigDict.count)") }
                                                            }   // for i in (0..<endpointCount) end
                                                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] Found total of \(availableObjsToMigDict.count) \(endpoint) to process") }
                                                            
                                                            var counter = 1
                                                            if goSender == "goButton" || goSender == "silent" {
                                                                if availableObjsToMigDict.count == 0 && endpoint == "jamfusers"{
                                                                    getStatusUpdate2(endpoint: endpoint, total: 0)
                                                                    putStatusUpdate2(endpoint: endpoint, total: 0)
                                                                }
                                                                for (l_xmlID, l_xmlName) in availableObjsToMigDict {
                                                                    if !wipeData.on  {
                                                                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] check for ID on \(l_xmlName): \(String(describing: currentEPs[l_xmlName]))") }
                                                                        
                                                                        if currentEPs[l_xmlName] != nil {
                                                                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] \(l_xmlName) already exists") }
                                                                            
                                                                            endPointByIDQueue(endpoint: endpoint, endpointID: "\(l_xmlID)", endpointCurrent: counter, endpointCount: availableObjsToMigDict.count, action: "update", destEpId: currentEPs[l_xmlName]!, destEpName: l_xmlName)
                                                                        } else {
                                                                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] \(l_xmlName) - create") }
                                                                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] function - endpoint: \(endpoint), endpointID: \(l_xmlID), endpointCurrent: \(counter), endpointCount: \(endpointCount), action: \"create\", destEpId: 0") }
                                                                            endPointByIDQueue(endpoint: endpoint, endpointID: "\(l_xmlID)", endpointCurrent: counter, endpointCount: availableObjsToMigDict.count, action: "create", destEpId: 0, destEpName: l_xmlName)
                                                                        }
                                                                    } else {
                                                                        if !(endpoint == "jamfusers" && "\(l_xmlName)".lowercased() == dest_user.lowercased()) {
                                                                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] remove - endpoint: \(endpoint)\t endpointID: \(l_xmlID)\t endpointName: \(l_xmlName)") }
                                                                            removeEndpointsQueue(endpointType: endpoint, endPointID: "\(l_xmlID)", endpointName: l_xmlName, endpointCurrent: counter, endpointCount: availableObjsToMigDict.count)
                                                                        }
                                                                        
                                                                    }   // if !wipeData.on else - end
                                                                    counter+=1
                                                                }   // for (l_xmlID, l_xmlName) in availableObjsToMigDict
                                                                if wipeData.on {
                                                                    removeEndpointsQueue(endpointType: endpoint, endPointID: "-1", endpointName: "", endpointCurrent: -1, endpointCount: 0)
                                                                }
                                                            } else {
                                                                // populate source server under the selective tab
                                                                delayInt = listDelay(itemCount: availableObjsToMigDict.count)
                                                                for (l_xmlID, l_xmlName) in availableObjsToMigDict {
                                                                    sortQ.async { [self] in
    //                                                                    print("adding \(l_xmlName) to array")
                                                                        availableIDsToMigDict[l_xmlName] = "\(l_xmlID)"
                                                                        sourceDataArray.append(l_xmlName)
                                                                        
                                                                        sourceDataArray = sourceDataArray.sorted{$0.localizedCaseInsensitiveCompare($1) == .orderedAscending}
                                                                        
                                                                        staticSourceDataArray = sourceDataArray
                                                                        
                                                                        updateSelectiveList(objectName: l_xmlName, objectId: "\(l_xmlID)", fileContents: "")
                                                                        
    //                                                                    DispatchQueue.main.async { [self] in
    //                                                                        srcSrvTableView.reloadData()
    //                                                                    }
                                                                        // slight delay in building the list - visual effect
                                                                        usleep(delayInt)
                                                                        
                                                                        if counter == availableObjsToMigDict.count {
                                                                            nodesMigrated += 1
                                                                            print("[\(#function)] \(#line) - finished getting \(endpoint)")
                                                                            goButtonEnabled(button_status: true)
                                                                        }
                                                                        counter+=1
                                                                    }   // sortQ.async - end
                                                                }   // for (l_xmlID, l_xmlName) in availableObjsToMigDict
                                                            }   // if goSender else - end
                                                            
                                                            // fix reading next endpoint for other endpoints - lnh
                                                            if nodeIndex < nodesToMigrate.count - 1 {
                                                                self.readNodes(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1)
                                                            }
                                                            completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                                                            
                                                        }   // existingEndpoints - end
                                                    }
                                                    
                                                } else {
                                                    getStatusUpdate2(endpoint: endpoint, total: 0)
                                                    putStatusUpdate2(endpoint: endpoint, total: 0)
                                                    
                                                    endpointsRead += 1
                                                    // print("[endpointsRead += 1] \(endpoint)")
                                                    //                                            if endpoint == self.objectsToMigrate.last {
                                                    //                                                self.rmDELETE()
                                                    ////                                                completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                                                    //                                            }
                                                    if nodeIndex < nodesToMigrate.count - 1 {
                                                        self.readNodes(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1)
                                                    }
                                                    completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                                                }   // if endpointCount > 0 - end
                                            } else {   // end if let buildings, departments...
                                                if nodeIndex < nodesToMigrate.count - 1 {
                                                    self.readNodes(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1)
                                                }
                                                completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                                            }
                                        default:
                                            break
                                        }   // switch - end
                                    }   // if let endpointJSON - end
                                    

                                }
                                                                
                            } else {
                                // failed to look-up item
                                self.nodesMigrated+=1    // ;print("added node: \(endpoint) - getEndpoints4")
                                if endpoint == self.objectsToMigrate.last {
                                    self.rmDELETE()
                                }
                                if nodeIndex < nodesToMigrate.count - 1 {
                                    self.readNodes(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1)
                                }
                                if httpResponse.statusCode == 401 {
                                    WriteToLog.shared.message(stringOfText: "[readDataFiles] verify \(JamfProServer.sourceUser) has permission to read \(endpoint) on \(myURL)")
                                }
                                getStatusUpdate2(endpoint: endpoint, total: 0)
                                putStatusUpdate2(endpoint: endpoint, total: 0)
                                completion(["Unable to get endpoint - \(endpoint).  Status Code: \(httpResponse.statusCode)", "0"])
                            }
                        }   // if let httpResponse as? HTTPURLResponse - end
                        semaphore.signal()
                        if error != nil {
                        }
                    })  // let task = session - end
                    task.resume()
        }   // getEndpointsQ - end
    }   // func getEndpoints - end
    
    func readDataFiles(nodesToMigrate: [String], nodeIndex: Int, completion: @escaping (_ result: String) -> Void) {
        
        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[readDataFiles] enter") }
        
        if JamfProServer.source.last != "/" {
            JamfProServer.source = JamfProServer.source + "/"
        }
        importFilesUrl = URL(string: "file://\(JamfProServer.source.replacingOccurrences(of: " ", with: "%20"))")
        
        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[readDataFiles] JamfProServer.source: \(JamfProServer.source)") }
        
        var local_general       = ""
        let endpoint            = nodesToMigrate[nodeIndex]
        print("[readDataFiles] endpoint: \(endpoint)")
        
        switch endpoint {
        case "computergroups", "smartcomputergroups", "staticcomputergroups":
            self.progressCountArray["smartcomputergroups"]  = 0
            self.progressCountArray["staticcomputergroups"] = 0
            self.progressCountArray["computergroups"]       = 0 // this is the recognized end point
        case "mobiledevicegroups", "smartmobiledevicegroups", "staticmobiledevicegroups":
            self.progressCountArray["smartmobiledevicegroups"]  = 0
            self.progressCountArray["staticmobiledevicegroups"] = 0
            self.progressCountArray["mobiledevicegroups"]       = 0 // this is the recognized end point
        case "usergroups", "smartusergroups", "staticusergroups":
            self.progressCountArray["smartusergroups"]  = 0
            self.progressCountArray["staticusergroups"] = 0
            self.progressCountArray["usergroups"]       = 0 // this is the recognized end point
        case "accounts", "jamfusers", "jamfgroups":
            self.progressCountArray["jamfusers"]  = 0
            self.progressCountArray["jamfgroups"] = 0
            self.progressCountArray["accounts"]   = 0 // this is the recognized end point
        default:
            self.progressCountArray["\(nodesToMigrate[nodeIndex])"] = 0
        }

        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[readDataFiles]       Data files root: \(JamfProServer.source)") }
        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[readDataFiles] Working with endpoint: \(endpoint)") }

//        self.availableFilesToMigDict.removeAll()
//        targetSelectiveObjectList.removeAll()
        
        self.displayNameToFilename.removeAll()
        
        theOpQ.maxConcurrentOperationCount = 1
//        let semaphore = DispatchSemaphore(value: 0)
        self.theOpQ.addOperation { [self] in
//            print("[readDataFiles] local_endpointArray: \(local_endpointArray)")
            let local_folder = nodesToMigrate[nodeIndex]
            availableFilesToMigDict.removeAll()
            targetSelectiveObjectList.removeAll()
            
            clearSourceObjectsList()
            
            var directoryPath = "\(JamfProServer.source)/\(local_folder)"
            directoryPath = directoryPath.replacingOccurrences(of: "//\(local_folder)", with: "/\(local_folder)")

            WriteToLog.shared.message(stringOfText: "[readDataFiles] scanning: \(directoryPath) for files.")
            do {
                let allFiles = FileManager.default.enumerator(atPath: "\(directoryPath)")

                if let allFilePaths = allFiles?.allObjects {
                    let allFilePathsArray = allFilePaths as! [String]
                    var xmlFilePaths      = [String]()
                    
//                        print("[ViewController.files] looking for files in \(local_folder)")
                    switch local_folder {
                    case "buildings", "patchmanagement":
                        xmlFilePaths = allFilePathsArray.filter{$0.contains(".json")} // filter for only files with json extension
                        if local_folder == "patchmanagement" {
                            PatchPoliciesDetails.source.removeAll()
                            if fm.fileExists(atPath: "\(JamfProServer.source)/patchPolicyDetails/patch-policies-policy-details.json") {
                                print("found patch-policies-policy-details.json")
                                
                                do {
                                    let fileUrl = importFilesUrl?.appendingPathComponent("patchPolicyDetails/patch-policies-policy-details.json", isDirectory: false)
                                    let fileContents = try String(contentsOf: fileUrl!)
                                    let data = fileContents.data(using: .utf8) ?? Data()
                                    PatchPoliciesDetails.source = try JSONDecoder().decode([PatchPolicyDetail].self, from: data)
                                    print("[readDataFiles] patchPolicyDetails.count: \(PatchPoliciesDetails.source.count)")
                                } catch let error as NSError {
                                    WriteToLog.shared.message(stringOfText: "[readDataFiles] patch-policies-policy-details.json - issue converting to json")
                                    print(error)
                                }
                                
                                
                            } else {
                                print("\(JamfProServer.source)/patchPolicyDetails/patch-policies-policy-details.json was not found")
                            }
                        }
                    default:
                        xmlFilePaths = allFilePathsArray.filter{$0.contains(".xml")}  // filter for only files with xml extension
                    }
                    
                    let dataFilesCount = xmlFilePaths.count
//                        print("[ViewController.files] found \(dataFilesCount) files in \(local_folder)")
                    var counter = 1
                    
                    if dataFilesCount < 1 {
//                        if setting.fullGUI {
//                            DispatchQueue.main.async {
//                                self.alert_dialog(header: "Attention:", message: "No files found.  If the folder exists outside the Downloads directory, reselect it with the Browse button and try again.")
//                            }
//                        } else {
                            WriteToLog.shared.message(stringOfText: "[readDataFiles] No files found.  If the import folder exists outside the Downloads directory and files are expected, reselect the import folder with with either the File Imprort or the Browse button and try again.")
//                            DispatchQueue.main.async {
//                                NSApplication.shared.terminate(self)
//                            }
//                        }
                        completion("no files found for: \(endpoint)")
                    } else {
                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[readDataFiles] Found \(dataFilesCount) files for endpoint: \(endpoint)") }
                        for i in 1...dataFilesCount {
                            let dataFile = xmlFilePaths[i-1]
    //                        let dataFile = dataFiles[i-1]
                            let fileUrl = importFilesUrl?.appendingPathComponent("\(local_folder)/\(dataFile)", isDirectory: false)
                            print("[readDataFiles] reading: \(String(describing: fileUrl?.path))")
                            
                            do {
                                // remove 'extra' data so we can get name and id from between general tags
                                var fileContents = try String(contentsOf: fileUrl!)
//                                    var fileJSON     = [String:Any]()
                                var name         = ""
                                var id           = ""
                                
                                switch endpoint {
                                case "buildings":
                                    let data = fileContents.data(using: .utf8)!
                                    do {
                                        if let jsonData = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as? [String:Any]
                                        {
//                                                fileJSON = jsonData
                                            name     = "\(jsonData["name"] ?? "")"
                                            id       = "\(jsonData["id"] ?? "")"
                                        } else {
                                            WriteToLog.shared.message(stringOfText: "[readDataFiles] buildings - issue with string format, not json")
                                        }
                                    } catch let error as NSError {
                                        print(error)
                                    }
                                case "patchmanagement":
                                    let data = fileContents.data(using: .utf8) ?? Data()
                                    do {
                                        let patchObject = try JSONDecoder().decode(PatchSoftwareTitleConfiguration.self, from: data)
//                                        if let jsonData = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as? [String:Any]
//                                        {
//                                                fileJSON = jsonData
                                            name = patchObject.displayName //"\(jsonData["name"] ?? "")"
                                            id   = patchObject.id ?? "" //"\(jsonData["id"] ?? "")"
//                                        } else {
//                                            WriteToLog.shared.message(stringOfText: "[readDataFiles] buildings - issue with string format, not json")
//                                        }
                                    } catch let error as NSError {
                                        WriteToLog.shared.message(stringOfText: "[readDataFiles] \(endpoint) - issue converting to json")
                                        print(error)
                                    }
                                    
                                case "advancedcomputersearches", "advancedmobiledevicesearches", "categories", "computerextensionattributes", "computergroups", "distributionpoints", "dockitems", "accounts", "jamfusers", "jamfgroups", "ldapservers", "mobiledeviceextensionattributes", "mobiledevicegroups", "networksegments", "packages", "printers", "scripts", "softwareupdateservers", "usergroups", "users":
                                    local_general = fileContents
                                    for xmlTag in ["site", "criterion", "computers", "mobile_devices", "image", "path", "contents", "privilege_set", "privileges", "members", "groups", "script_contents", "script_contents_encoded"] {
                                        local_general = rmXmlData(theXML: local_general, theTag: xmlTag, keepTags: false)
                                    }
                                    if endpoint == "scripts" {
                                        let theScript = tagValue(xmlString: fileContents, xmlTag: "script_contents")
//                                        print("readDataFiles] theScript: \(theScript)")
                                        if theScript != "" {
                                            fileContents = rmXmlData(theXML: fileContents, theTag: "script_contents", keepTags: true)
                                            fileContents = fileContents.replacingOccurrences(of: "<script_contents/>", with: "<script_contents>\(theScript.xmlEncode)</script_contents>")
                                        }
                                    }
                                case "advancedusersearches", "smartcomputergroups", "staticcomputergroups", "smartmobiledevicegroups", "staticmobiledevicegroups", "smartusergroups", "staticusergroups":
                                    local_general = fileContents
                                    for xmlTag in ["criteria", "users", "display_fields", "site"] {
                                        local_general = rmXmlData(theXML: local_general, theTag: xmlTag, keepTags: false)
                                    }
                                case "departments", "sites", "directorybindings":
                                    local_general = fileContents
                                case "classes":
                                    local_general = tagValue2(xmlString:fileContents, startTag:"<class>", endTag:"</class>")
                                    for xmlTag in ["student_ids", "teacher_ids", "student_group_ids", "teacher_group_ids", "mobile_device_group_ids"] {
                                        local_general = rmXmlData(theXML: local_general, theTag: xmlTag, keepTags: false)
                                    }
                                    for xmlTag in ["student_ids/", "teacher_ids/", "student_group_ids/", "teacher_group_ids/", "mobile_device_group_ids/"] {
                                        local_general = local_general.replacingOccurrences(of: "<\(xmlTag)>", with: "")
                                    }
                                case "userextensionattributes":
                                    local_general = tagValue2(xmlString:fileContents, startTag:"<user_extension_attribute>", endTag:"</user_extension_attribute>")
                                case "diskencryptionconfigurations":
                                    local_general = tagValue2(xmlString:fileContents, startTag:"<disk_encryption_configuration>", endTag:"</disk_encryption_configuration>")
                                default:
                                    local_general = tagValue2(xmlString:fileContents, startTag:"<general>", endTag:"</general>")
                                    for xmlTag in ["site", "category", "payloads"] {
                                        local_general = rmXmlData(theXML: local_general, theTag: xmlTag, keepTags: false)
                                    }
                                }

                                if !["buildings", "patchmanagement"].contains(endpoint) {
                                    id   = tagValue2(xmlString:local_general, startTag:"<id>", endTag:"</id>")
                                    name = tagValue2(xmlString:local_general, startTag:"<name>", endTag:"</name>")
                                }
                                
                                displayNameToFilename[name]       = dataFile
                                availableFilesToMigDict[dataFile] = [id, name, fileContents]
                                targetSelectiveObjectList.append(SelectiveObject(objectName: name, objectId: id, fileContents: fileContents))
                                
                                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[readDataFiles] read \(local_folder): file name : object name - \(dataFile)  :  \(name), id: \(id)") }
                                // populate selective list, when appropriate
                                if goSender == "selectToMigrateButton" {
//                                  print("fileImport - goSender: \(goSender)")
//                                        print("adding \(name) to array")
                                          
                                    availableIDsToMigDict[name] = id
                                    sourceDataArray.append(name)
                                    sourceDataArray = sourceDataArray.sorted{$0.localizedCaseInsensitiveCompare($1) == .orderedAscending}

                                    staticSourceDataArray = sourceDataArray
                                    
                                    print("[readDataFiles] add \(name) (id: \(id)) to sourceObjectList_AC")
                                    updateSelectiveList(objectName: name, objectId: id, fileContents: fileContents)
                                    
                                    // slight delay in building the list - visual effect
                                    usleep(delayInt)

                                    if counter == dataFilesCount {
                                        nodesMigrated += 1
                                        DispatchQueue.main.async { [self] in
                                            spinner_progressIndicator.stopAnimation(self)
                                        }
                                        print("[\(#function)] \(#line) - finished reading \(endpoint)")
                                        goButtonEnabled(button_status: true)
                                    }
                                    counter+=1
                                }
                                
                            } catch {
                                //                    print("unable to read \(dataFile)")
                                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[readDataFiles] unable to read \(dataFile)") }
                            }
//                                getStatusUpdate(endpoint: local_folder, current: i, total: dataFilesCount)
                        }   // for i in 1...dataFilesCount - end
                        
                        let fileCount = availableFilesToMigDict.count
                    
                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[readDataFiles] Node: \(local_folder) has \(fileCount) files.") }
                    }
                } else {   // if let allFilePaths - end
                    WriteToLog.shared.message(stringOfText: "[readDataFiles] No files found.  If the import folder exists outside the Downloads directory and files are expected, reselect the import folder with with either the File Imprort or the Browse button and try again.")
                    completion("no files found for: \(endpoint)")
                }
            } //catch {
                //if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[readDataFiles] Node: \(local_folder): unable to get files.") }
            //}

//            var fileCount = self.availableFilesToMigDict.count
            var fileCount = targetSelectiveObjectList.count
         
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[readDataFiles] Node: \(local_folder) has \(fileCount) files.") }
             
            if fileCount > 0 {
            //                    print("[readDataFiles] call processFiles for \(endpoint), nodeIndex \(nodeIndex) of \(nodesToMigrate)")
             if self.goSender == "goButton" || self.goSender == "silent" {
                 self.processFiles(endpoint: endpoint, fileCount: fileCount, itemsDict: self.availableFilesToMigDict) {
                     (result: String) in
                     if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[readDataFiles] Returned from processFiles.") }
            //                        print("[readDataFiles] returned from processFiles for \(endpoint), nodeIndex \(nodeIndex) of \(nodesToMigrate)")
                     self.availableFilesToMigDict.removeAll()
                     targetSelectiveObjectList.removeAll()
                     
                     if nodeIndex < nodesToMigrate.count - 1 {
                         self.readDataFiles(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1) {
                             (result: String) in
                             if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.readDataFiles] processFiles result: \(result)") }
                         }
                     }
                     completion("fetched xml for: \(endpoint)")
                 }
             }
            } else {   // if fileCount - end
             WriteToLog.shared.message(stringOfText: "[readDataFiles] \(endpoint) fileCount = 0.")
             
            //                 self.nodesMigrated+=1    // ;print("added node: \(endpoint) - readDataFiles2")
             getStatusUpdate2(endpoint: endpoint, total: fileCount)
             putStatusUpdate2(endpoint: endpoint, total: fileCount)
             
             if nodeIndex < nodesToMigrate.count - 1 {
                 self.readDataFiles(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1) {
                     (result: String) in
                     if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.readDataFiles] no files found for: \(local_folder)") }
                 }
             }
             completion("fetched xml for: \(endpoint)")
            }
            fileCount = 0

        }   // self.theOpQ - end
    }   // func readDataFiles - end
    
    func processFiles(endpoint: String, fileCount: Int, itemsDict: [String:[String]] = [:], completion: @escaping (_ result: String) -> Void) {
        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[processFiles] enter: endpoint - \(endpoint)") }
        
        let skipLookup = (activeTab(fn: "processFiles") == "selective") ? true:false
        self.existingEndpoints(skipLookup: skipLookup, theDestEndpoint: "\(endpoint)") { [self]
            (result: (String,String)) in
            let (resultMessage, _) = result
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[processFiles] Returned from existing \(endpoint): \(resultMessage)") }
            
            readFilesQ.maxConcurrentOperationCount = 1

            var l_index = 1
            for theObject in targetSelectiveObjectList {
//                print("[processFiles] object name: \(theObject.objectName.xmlDecode)")
                readFilesQ.addOperation { [self] in
                    let l_id   = theObject.objectId         // id of object
                    let l_name = theObject.objectName.xmlDecode    // name of object, remove xml encoding
                    let l_xml  = theObject.fileContents
                    
//                    print("[processFiles] l_id: \(l_id), l_name: \(theObject.objectName.xmlDecode), l_xml: \(l_xml)")
                    
                    getStatusUpdate2(endpoint: endpoint, total: targetSelectiveObjectList.count, index: l_index)
                    
//                    if l_id != nil && l_name != "" && l_xml != "" {
                    if l_id != "" && l_name != "" && l_xml != "" {
                        if !wipeData.on  {
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[processFiles] check for ID on \(String(describing: l_name)): \(currentEPs[l_name] ?? 0)") }
                            if currentEPs["\(l_name)"] != nil {
                                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[processFiles] \(endpoint):\(String(describing: l_name)) already exists") }
                                
                                print("[processFiles] update endpoint: \(endpoint)")
                                switch endpoint {
                                case "buildings":
                                    let data = l_xml.data(using: .utf8)!
                                    var jsonData = [String:Any]()
                                    var action = "update"
                                    do {
                                        if let _ = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as? [String: Any] {
                                            jsonData = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as! [String: Any]
                                            WriteToLog.shared.message(stringOfText: "[ViewController.processFiles] JSON file for \(l_name) successfully parsed.")
                                        } else {
                                            WriteToLog.shared.message(stringOfText: "[ViewController.processFiles] JSON file \(theObject.fileContents) failed to parse.")
                                            action = "skip"
                                        }
                                    } catch let error as NSError {
                                        WriteToLog.shared.message(stringOfText: "[ViewController.processFiles] file \(theObject.fileContents) failed to parse. Error: \(error.localizedDescription)")
                                        action = "skip"
                                    }
                                    
                                    cleanupJSON(endpoint: endpoint, JSON: jsonData, endpointID: l_id, endpointCurrent: l_index, endpointCount: fileCount, action: action, destEpId: currentEPs[l_name]!, destEpName: l_name) {
                                        (cleanJSON: String) in
                                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[processFiles] [\(endpoint)]: Returned from cleanupJSON") }
                                        if cleanJSON == "last" {
                                            completion("processed last file")
                                        }
                                    }
                                case "patchmanagement":
                                    PatchDelegate.shared.getDependencies(whichServer: "dest") { result in
                                        self.message_TextField.stringValue = ""
                                        let data = l_xml.data(using: .utf8)!
                                        var jsonData = [String:Any]()
                                        var action = "update"
                                        do {
                                            if let _ = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as? [String: Any] {
                                                jsonData = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as! [String: Any]
                                                WriteToLog.shared.message(stringOfText: "[ViewController.processFiles] JSON file for \(l_name) successfully parsed.")
                                            } else {
                                                WriteToLog.shared.message(stringOfText: "[ViewController.processFiles] JSON file \(theObject.fileContents) failed to parse.")
                                                action = "skip"
                                            }
                                        } catch let error as NSError {
                                            WriteToLog.shared.message(stringOfText: "[ViewController.processFiles] file \(theObject.fileContents) failed to parse.")
                                            //                                        print(error)
                                            action = "skip"
                                        }
                                        
                                        cleanupJSON(endpoint: endpoint, JSON: jsonData, endpointID: l_id, endpointCurrent: l_index, endpointCount: fileCount, action: action, destEpId: currentEPs[l_name]!, destEpName: l_name) {
                                            (cleanJSON: String) in
                                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[processFiles] [\(endpoint)]: Returned from cleanupJSON") }
                                            if cleanJSON == "last" {
                                                completion("processed last file")
                                            }
                                        }
                                    }
                                default:
                                    cleanupXml(endpoint: endpoint, Xml: l_xml, endpointID: l_id, endpointCurrent: l_index, endpointCount: fileCount, action: "update", destEpId: currentEPs[l_name]!, destEpName: l_name) {
                                        (result: String) in
                                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[processFiles] [\(endpoint)]: Returned from cleanupXml") }
                                        if result == "last" {
                                            completion("processed last file")
                                        }
                                    }
                                }
                                
                                /*
                                if endpoint != "buildings" {
                                    cleanupXml(endpoint: endpoint, Xml: l_xml, endpointID: l_id, endpointCurrent: l_index, endpointCount: fileCount, action: "update", destEpId: currentEPs[l_name]!, destEpName: l_name) {
                                        (result: String) in
                                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[processFiles] [\(endpoint)]: Returned from cleanupXml") }
                                        if result == "last" {
                                            completion("processed last file")
                                        }
                                    }
                                } else {
                                    let data = l_xml.data(using: .utf8)!
                                    var jsonData = [String:Any]()
                                    var action = "update"
                                    do {
                                        if let _ = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as? [String:Any] {
                                            jsonData = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as! [String:Any]
                                            WriteToLog.shared.message(stringOfText: "[ViewController.processFiles] JSON file for \(l_name) successfully parsed.")
                                        } else {
                                            WriteToLog.shared.message(stringOfText: "[ViewController.processFiles] JSON file \(theObject.fileContents) failed to parse.")
                                            action = "skip"
                                        }
                                    } catch let error as NSError {
                                        WriteToLog.shared.message(stringOfText: "[ViewController.processFiles] file \(theObject.fileContents) failed to parse.")
//                                        print(error)
                                        action = "skip"
                                    }
                                    
                                    cleanupJSON(endpoint: endpoint, JSON: jsonData, endpointID: l_id, endpointCurrent: l_index, endpointCount: fileCount, action: action, destEpId: currentEPs[l_name]!, destEpName: l_name) {
                                        (cleanJSON: String) in
                                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[processFiles] [\(endpoint)]: Returned from cleanupJSON") }
                                        if cleanJSON == "last" {
                                            completion("processed last file")
                                        }
                                    }
                                }
                                */
                            } else {
                                print("[processFiles] create endpoint: \(endpoint)")
                                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[processFiles] \(endpoint):\(String(describing: l_name)) - create") }
                                
                                switch endpoint {
                                case "buildings":
                                    let data = l_xml.data(using: .utf8)!
                                    var jsonData = [String:Any]()
                                    var action = "create"
                                    do {
                                        if let _ = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as? [String:Any] {
                                            jsonData = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as! [String:Any]
                                            WriteToLog.shared.message(stringOfText: "[ViewController.processFiles] JSON file for \(l_name) successfully parsed.")
                                        } else {
                                            WriteToLog.shared.message(stringOfText: "[ViewController.processFiles] JSON file \(theObject.fileContents) failed to parse.")
                                            action = "skip"
                                        }
                                    } catch let error as NSError {
                                        WriteToLog.shared.message(stringOfText: "[ViewController.processFiles] file \(theObject.fileContents) failed to parse.")
                                        print(error)
                                        action = "skip"
                                    }
                                    
                                    cleanupJSON(endpoint: endpoint, JSON: jsonData, endpointID: l_id, endpointCurrent: l_index, endpointCount: fileCount, action: action, destEpId: 0, destEpName: l_name) {
                                        (cleanJSON: String) in
                                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[processFiles] [\(endpoint)]: Returned from cleanupJSON") }
                                        if cleanJSON == "last" {
                                            completion("processed last file")
                                        }
                                    }
                                case "patchmanagement":
                                    PatchDelegate.shared.getDependencies(whichServer: "dest") { result in
                                        self.message_TextField.stringValue = ""
                                        let data = l_xml.data(using: .utf8)!
                                        var jsonData = [String:Any]()
                                        var action = "create"
                                        do {
                                            if let _ = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as? [String:Any] {
                                                jsonData = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as! [String:Any]
                                                WriteToLog.shared.message(stringOfText: "[ViewController.processFiles] JSON file for \(l_name) successfully parsed.")
                                            } else {
                                                WriteToLog.shared.message(stringOfText: "[ViewController.processFiles] JSON file \(theObject.fileContents) failed to parse.")
                                                action = "skip"
                                            }
                                        } catch let error as NSError {
                                            WriteToLog.shared.message(stringOfText: "[ViewController.processFiles] file \(theObject.fileContents) failed to parse.")
                                            print(error)
                                            action = "skip"
                                        }
                                        
                                        self.cleanupJSON(endpoint: endpoint, JSON: jsonData, endpointID: l_id, endpointCurrent: l_index, endpointCount: fileCount, action: action, destEpId: 0, destEpName: l_name) {
                                            (cleanJSON: String) in
                                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[processFiles] [\(endpoint)]: Returned from cleanupJSON") }
                                            if cleanJSON == "last" {
                                                completion("processed last file")
                                            }
                                        }
                                    }
                                default:
                                    cleanupXml(endpoint: endpoint, Xml: l_xml, endpointID: l_id, endpointCurrent: l_index, endpointCount: fileCount, action: "create", destEpId: 0, destEpName: l_name) {
                                        (result: String) in
                                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[processFiles] [\(endpoint)]: Returned from cleanupXml") }
                                        if result == "last" {
                                            completion("processed last file")
                                        }
                                    }
                                }
                            }
                        }   // if !wipeData.on - end
                    } else {
                        let theName = "name: \(l_name)  id: \(l_id)"
                        if endpoint != "buildings" {
                            cleanupXml(endpoint: endpoint, Xml: l_xml, endpointID: l_id, endpointCurrent: l_index, endpointCount: fileCount, action: "create", destEpId: currentEPs[l_name]!, destEpName: theName) {
                                (result: String) in
                                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[processFiles] [\(endpoint)]: Returned from cleanupXml") }
                                if result == "last" {
                                    completion("processed last file")
                                }
                            }
                        } else {
                            cleanupJSON(endpoint: endpoint, JSON: ["name":theName], endpointID: l_id, endpointCurrent: l_index, endpointCount: fileCount, action: "skip", destEpId: 0, destEpName: l_name) {
                                (cleanJSON: String) in
                                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[processFiles] [\(endpoint)]: Returned from cleanupJSON") }
                                if cleanJSON == "last" {
                                    completion("processed last file")
                                }
                            }
                        }
                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[processFiles] [\(endpoint)]: trouble with \(theObject.fileContents)") }
                    }
                    l_index+=1
                    usleep(25000)  // slow the file read process
                }   // readFilesQ.sync - end
                usleep(25000)  // slow the file read process
            }   // for (_, objectInfo) - end
        }
    }
    
    func endPointByIDQueue(endpoint: String, endpointID: String, endpointCurrent: Int, endpointCount: Int, action: String, destEpId: Int, destEpName: String) {
        
        getSourceEPQ.async { [self] in
            
//            print("[endPointByIDQueue] queue \(endpoint) with name \(destEpName) for get")
            getArray.append(ObjectInfo(endpointType: endpoint, endPointXml: "", endPointJSON: [:], endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, sourceEpId: Int(endpointID)!, destEpId: Int(destEpId), ssIconName: destEpName, ssIconId: "", ssIconUri: "", retry: false))
            
            while Counter.shared.pendingGet > 0 || getArray.count > 0 {
//                print("[endPointByIDQueue] Counter.shared.pendingGet: \(Counter.shared.pendingGet)")
                if Counter.shared.pendingGet < maxConcurrentThreads && getArray.count > 0 {
                    Counter.shared.pendingGet += 1
                    let nextEndpoint = getArray[0]
                    getArray.remove(at: 0)
                    
                    endPointByID(endpoint: nextEndpoint.endpointType, endpointID: "\(nextEndpoint.sourceEpId)", endpointCurrent: nextEndpoint.endpointCurrent, endpointCount: nextEndpoint.endpointCount, action: nextEndpoint.action, destEpId: nextEndpoint.destEpId, destEpName: nextEndpoint.ssIconName) {
                            (result: String) in
                        Counter.shared.pendingGet -= 1
                    }
                } else {
//                    sleep(1)
                    usleep(5000)
                }
            }
        }
    }
    // get full record
    func endPointByID(endpoint: String, endpointID: String, endpointCurrent: Int, endpointCount: Int, action: String, destEpId: Int, destEpName: String, completion: @escaping (_ result: String) -> Void) {
                
        URLCache.shared.removeAllCachedResponses()
        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[endPointByID] endpoint passed to endPointByID: \(endpoint) id \(endpointID)") }
        
        endpointsIdQ.maxConcurrentOperationCount = maxConcurrentThreads
//        let semaphore = DispatchSemaphore(value: 0)
        
        var localEndPointType = ""
//        var theEndpoint       = endpoint
        
        switch endpoint {
//      adjust the lookup endpoint
        case "smartcomputergroups", "staticcomputergroups":
            localEndPointType = "computergroups"
        case "smartmobiledevicegroups", "staticmobiledevicegroups":
            localEndPointType = "mobiledevicegroups"
        case "smartusergroups", "staticusergroups":
            localEndPointType = "usergroups"
//      adjust the where the data is sent
        case "accounts/userid":
            localEndPointType = "jamfusers"
        case "accounts/groupid":
            localEndPointType = "jamfgroups"
        case "patch-software-title-configurations":
            localEndPointType = "patchmanagement"
        default:
            localEndPointType = endpoint
        }

        // split queries between classic and Jamf Pro API
        switch localEndPointType {
        case "buildings":
            // Jamf Pro API
            if !( endpoint == "jamfuser" && endpointID == "\(jamfAdminId)") {
                endpointsIdQ.addOperation {
                    
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[endPointByID] fetching JSON for: \(localEndPointType) with id: \(endpointID)") }
                    Jpapi.shared.action(whichServer: "source", endpoint: localEndPointType, apiData: [:], id: "\(endpointID)", token: JamfProServer.authCreds["source"]!, method: "GET" ) { [self]
                                (returnedJSON: [String:Any]) in
                                completion(destEpName)
//                                if statusCode == 202 {
//                                    print("[endPointByID] \(#line) returnedJSON: \(returnedJSON)")
//                                }
                                //                        print("returnedJSON: \(returnedJSON)")
                                if returnedJSON.count > 0 {
                                    self.getStatusUpdate2(endpoint: endpoint, total: endpointCount)
                                    // save source JSON - start
                                    if export.saveRawXml {
                                        DispatchQueue.main.async { [self] in
                                            let exportRawJson = (export.rawXmlScope) ? rmJsonData(rawJSON: returnedJSON, theTag: ""):rmJsonData(rawJSON: returnedJSON, theTag: "scope")
                                            //                                    print("exportRawJson: \(exportRawJson)")
                                            WriteToLog.shared.message(stringOfText: "[endPointByID] Exporting raw JSON for \(endpoint) - \(destEpName)")
                                            let exportFormat = (export.backupMode) ? "\(JamfProServer.source.fqdnFromUrl)_export_\(backupDate.string(from: History.startTime))":"raw"
                                            exportItems(node: endpoint, objectString: exportRawJson, rawName: destEpName, id: "\(endpointID)", format: "\(exportFormat)")
                                            //                                    SaveDelegate().exportObject(node: endpoint, objectString: exportRawJson, rawName: destEpName, id: "\(endpointID)", format: "\(exportFormat)")
                                        }
                                    }
                                    // save source JSON - end
                                    
                                    if !export.saveOnly {
                                        cleanupJSON(endpoint: endpoint, JSON: returnedJSON, endpointID: "\(endpointID)", endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, destEpId: destEpId, destEpName: destEpName) {
                                            (cleanJSON: String) in
                                        }
                                    } else {
                                        // check progress
                                        //                                print("[endpointById] node: \(endpoint)")
                                        //                                // print("[endpointById] endpoint \(endpointCurrent) of \(endpointCount) complete")
                                        endpointCountDict[endpoint]! -= 1
                                        //                                print("[endpointById] \(String(describing: endpointCountDict[endpoint])) remaining")
                                        if endpointCountDict[endpoint] == 0 {
                                            //                                     print("[endpointById] saved last \(endpoint)")
                                            //                                     print("[endpointById] endpoint \(endpointsRead) of \(objectsToMigrate.count) endpoints complete")
                                            
                                            if endpointsRead == objectsToMigrate.count {
                                                // print("[endpointById] zip it up")
                                                print("[\(#function)] \(#line) - finished getting \(endpoint)")
                                                goButtonEnabled(button_status: true)
                                            }
                                        }
                                    }
                                }
                            }
                            
                }   // endpointsIdQ - end
            }
        case "patchmanagement":
            var sourceObject = PatchTitleConfigurations.source.first(where: { $0.id == endpointID })
            print("[endpointByID] displayName: \(sourceObject?.displayName ?? "unknown")")
            completion(sourceObject?.displayName ?? "unknown")
            
            if !(sourceObject?.id ?? "").isEmpty {
                self.getStatusUpdate2(endpoint: endpoint, total: endpointCount)
                for theSourceObj in JamfProSites.source {
                    print("[endPointByID] sourceObject?.siteId: \(theSourceObj.id),   name: \(theSourceObj.name)")
                }
                print("[endPointByID] sourceObject?.siteId: \(sourceObject?.siteId)")
                let categoryName = Categories.source.filter { $0.id == sourceObject?.categoryId }.first?.name ?? ""
                let siteName     = JamfProSites.source.filter { $0.id == sourceObject?.siteId }.first?.name ?? "None"
                
                let sourcePatchPackages = sourceObject?.packages ?? []
                var updatedPatchPackages: [PatchPackage] = []
                for thePatchPackage in sourcePatchPackages {
                    if let packageName = PatchPackages.source.filter({ $0.packageId == thePatchPackage.packageId }).first?.packageName, !packageName.isEmpty {
                        updatedPatchPackages.append(PatchPackage(packageId: thePatchPackage.packageId, version: thePatchPackage.version, displayName: thePatchPackage.displayName, packageName: packageName))
                    }
                }
                sourceObject?.packages = updatedPatchPackages
                
                let instance = PatchSoftwareTitleConfiguration(id: sourceObject?.id ?? "0", jamfOfficial: sourceObject?.jamfOfficial ?? false, displayName: sourceObject?.displayName ?? "", categoryId: sourceObject?.categoryId ?? "", categoryName: categoryName, siteId: sourceObject?.siteId ?? "", siteName: siteName, uiNotifications: sourceObject?.uiNotifications ?? false, emailNotifications: sourceObject?.emailNotifications ?? false, softwareTitleId: sourceObject?.softwareTitleId ?? "", extensionAttributes: sourceObject?.extensionAttributes ?? [], softwareTitleName: sourceObject?.softwareTitleName ?? "", softwareTitleNameId: sourceObject?.softwareTitleNameId ?? "", softwareTitlePublisher: sourceObject?.softwareTitlePublisher ?? "", patchSourceName: sourceObject?.patchSourceName ?? "", patchSourceEnabled: sourceObject?.patchSourceEnabled ?? false, packages: sourceObject?.packages ?? [])
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted  // Optional: makes the JSON easier to read

                do {
                    let jsonData = try encoder.encode(instance)
                    
                    if let jsonString = String(data: jsonData, encoding: .utf8) {
                        print("[endPointByID] exported jsonString: \(jsonString)")
                        
                        print("[endPointByID] export.saveRawXml: \(export.saveRawXml)")
                        print("[endPointByID] export.backupMode: \(export.backupMode)")
                        // save source JSON - start
                        if export.saveRawXml {
                            DispatchQueue.main.async { [self] in
//                                let exportRawJson = (export.rawXmlScope) ? rmJsonData(rawJSON: jsonString, theTag: ""):rmJsonData(rawJSON: jsonString, theTag: "scope")
                                //                                    print("exportRawJson: \(exportRawJson)")
                                WriteToLog.shared.message(stringOfText: "[endPointByID] Exporting raw JSON for \(endpoint) - \(destEpName)")
                                let exportFormat = (export.backupMode) ? "\(JamfProServer.source.fqdnFromUrl)_export_\(backupDate.string(from: History.startTime))":"raw"
//                                exportItems(node: endpoint, objectString: jsonString, rawName: sourceObject?.displayName ?? "", id: sourceObject?.id ?? "0", format: exportFormat)
                                ExportItems.shared.patchmanagement(node: "patchmanagement", object: instance, rawName: sourceObject?.displayName ?? "", id: sourceObject?.id ?? "0", format: exportFormat)
                            }
                        }
                        // save source JSON - end
                        
                        if !export.saveOnly {
                            do {
                                let objectJson = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] ?? [:]
                                cleanupJSON(endpoint: endpoint, JSON: objectJson, endpointID: "\(endpointID)", endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, destEpId: destEpId, destEpName: destEpName) {
                                    (cleanJSON: String) in
                                }
                            } catch {
                                print(error.localizedDescription)
                            }
                             
                        } else {
                            // check progress
                            //                                print("[endpointById] node: \(endpoint)")
                            //                                print("[endpointById] endpoint \(endpointCurrent) of \(endpointCount) complete")
                            endpointCountDict[localEndPointType]! -= 1
                            //                                print("[endpointById] \(String(describing: endpointCountDict[endpoint])) remaining")
                            if endpointCountDict[localEndPointType] == 0 {
                                //                                     print("[endpointById] saved last \(endpoint)")
                                //                                     print("[endpointById] endpoint \(endpointsRead) of \(objectsToMigrate.count) endpoints complete")
                                
                                if endpointsRead == objectsToMigrate.count {
                                    // print("[endpointById] zip it up")
                                    print("[\(#function)] \(#line) - finished getting \(endpoint)")
                                    goButtonEnabled(button_status: true)
                                }
                            }
                        }
                    }
                } catch {
                    print("Error encoding JSON: \(error)")
                }

            }
            
        default:
            // classic API
            if !( endpoint == "jamfuser" && endpointID == "\(jamfAdminId)") {
                var myURL = "\(JamfProServer.source)/JSSResource/\(localEndPointType)/id/\(endpointID)"
                myURL = myURL.urlFix

                myURL = myURL.replacingOccurrences(of: "/JSSResource/jamfusers/id", with: "/JSSResource/accounts/userid")
                myURL = myURL.replacingOccurrences(of: "/JSSResource/jamfgroups/id", with: "/JSSResource/accounts/groupid")
                myURL = myURL.replacingOccurrences(of: "id/id/", with: "id/")
                
                endpointsIdQ.addOperation {
                    
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[endPointByID] fetching XML from: \(myURL)") }
                            //                print("NSURL line 3")
                            //                if "\(myURL)" == "" { myURL = "https://localhost" }
                            let encodedURL = URL(string: myURL)
                            let request = NSMutableURLRequest(url: encodedURL! as URL)
                            request.httpMethod = "GET"
                            let configuration = URLSessionConfiguration.ephemeral
                            
                            configuration.httpAdditionalHeaders = ["Authorization" : "\(JamfProServer.authType["source"] ?? "Bearer") \(JamfProServer.authCreds["source"] ?? "")", "Content-Type" : "text/xml", "Accept" : "text/xml", "User-Agent" : AppInfo.userAgentHeader]
                            let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
                            let task = session.dataTask(with: request as URLRequest, completionHandler: { [self]
                                (data, response, error) -> Void in
                                session.finishTasksAndInvalidate()
                                completion(destEpName)
                                
//                                if statusCode == 202 {
//                                    print("[endPointByID] \(#line) retrieved object")
//                                }
                                
                                if let httpResponse = response as? HTTPURLResponse {
                                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[endPointByID] HTTP response code of GET for \(destEpName): \(httpResponse.statusCode)") }
                                    let PostXML = String(data: data!, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
                                    
                                    self.getStatusUpdate2(endpoint: endpoint, total: endpointCount)
                                    // save source XML - start
                                    if export.saveRawXml {
                                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[endPointByID] Saving raw XML for \(destEpName) with id: \(endpointID).") }
                                        DispatchQueue.main.async { [self] in
                                            // added option to remove scope
                                            //                                    print("[endPointByID] export.rawXmlScope: \(export.rawXmlScope)")
                                            let exportRawXml = (export.rawXmlScope) ? PostXML:rmXmlData(theXML: PostXML, theTag: "scope", keepTags: false)
                                            WriteToLog.shared.message(stringOfText: "[endPointByID] Exporting raw XML for \(endpoint) - \(destEpName)")
                                            let exportFormat = (export.backupMode) ? "\(JamfProServer.source.fqdnFromUrl)_export_\(backupDate.string(from: History.startTime))":"raw"
                                            XmlDelegate().save(node: endpoint, xml: exportRawXml, rawName: destEpName, id: "\(endpointID)", format: "\(exportFormat)")
                                        }
                                    }
                                    // save source XML - end
                                    if !export.backupMode {
                                        
                                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[endPointByID] Starting to clean-up the XML for \(endpoint) with id \(endpointID).") }
                                        cleanupXml(endpoint: endpoint, Xml: PostXML, endpointID: "\(endpointID)", endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, destEpId: destEpId, destEpName: destEpName) {
                                            (result: String) in
                                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[endPointByID] Returned from cleanupXml") }
                                        }
                                    } else {
                                        // to back-up icons
                                        if endpoint == "policies" {
                                            cleanupXml(endpoint: endpoint, Xml: PostXML, endpointID: endpointID, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, destEpId: destEpId, destEpName: destEpName) {
                                                (result: String) in
                                            }
                                        }
                                        // check progress
                                        //                                print("[endpointById] node: \(endpoint)")
                                        //                                // print("[endpointById] endpoint \(endpointCurrent) of \(endpointCount) complete")
                                        endpointCountDict[endpoint]! -= 1
                                        //                                print("[endpointById] \(String(describing: endpointCountDict[endpoint])) remaining")
                                        if endpointCountDict[endpoint] == 0 {
                                            //                                     print("[endpointById] saved last \(endpoint)")
                                            //                                     print("[endpointById] endpoint \(endpointsRead) of \(objectsToMigrate.count) endpoints complete")
                                            endpointCountDict[endpoint] = nil
                                            //                                    print("[endpointById] nodes remaining \(endpointCountDict)")
                                            if endpointCountDict.count == 0 && endpointsRead == objectsToMigrate.count {
                                                // print("[endpointById] zip it up")
                                                print("[\(#function)] \(#line) - finished getting \(endpoint)")
                                                goButtonEnabled(button_status: true)
                                            }
                                        }
                                    }
                                } else {   // if let httpResponse - end
                                    // check progress
                                    //                            print("[endpointById-error] node: \(endpoint)")
                                    //                            print("[endpointById-error] endpoint \(endpointCurrent) of \(endpointCount) complete")
                                    endpointCountDict[endpoint]! -= 1
                                    //                            print("[endpointById-error] \(String(describing: endpointCountDict[endpoint])) remaining")
                                    if endpointCountDict[endpoint] == 0 {
                                        //                                print("[endpointById-error] saved last \(endpoint)")
                                        //                                print("[endpointById-error] endpoint \(endpointsRead) of \(objectsToMigrate.count) endpoints complete")
                                        endpointCountDict[endpoint] = nil
                                        //                                print("[endpointById-error] nodes remaining \(endpointCountDict)")
                                        if endpointCountDict.count == 0 && endpointsRead == objectsToMigrate.count {
                                            //                                    print("[endpointById-error] zip it up")
                                            print("[\(#function)] \(#line) - finished getting \(endpoint)")
                                            goButtonEnabled(button_status: true)
                                        }
                                    }
                                }
//                                semaphore.signal()
                                if error != nil {
                                }
                            })  // let task = session - end
                            //print("GET")
                            task.resume()
//                            semaphore.wait()
                }   // endpointsIdQ - end
            }
        }
    }
    
    func cleanupJSON(endpoint: String, JSON: [String: Any], endpointID: String, endpointCurrent: Int, endpointCount: Int, action: String, destEpId: Int, destEpName: String, completion: @escaping (_ cleanJSON: String) -> Void) {
        
        var theEndpoint = endpoint
        
        switch endpoint {
        case "accounts/userid":
            theEndpoint = "jamfusers"
        case "accounts/groupid":
            theEndpoint = "jamfgroups"
        default:
            theEndpoint = endpoint
        }
        var JSONData = JSON
        
        switch endpoint {
        case "patchmanagement":
            JSONData["id"] = nil
            print("[cleanJSON - patchmanagement] JSONData[categoryName]: \(JSONData["categoryName"] ?? "")")
            print("[cleanJSON - patchmanagement] Categories.destination.count: \(Categories.destination.count)")
            
            print("[cleanJSON - patchmanagement] JSONData[patchSourceName]: \(JSONData["patchSourceName"] ?? "")")
            
            JSONData["categoryId"] = Categories.destination.first(where: { $0.name == JSONData["categoryName"] as? String })?.id ?? "-1"
            JSONData["categoryName"] = nil
            JSONData["siteId"] = JamfProSites.destination.first(where: { $0.name == JSONData["siteName"] as? String })?.id ?? "-1"
            JSONData["siteName"] = nil
            let patchPackages = JSONData["packages"] as? [[String: Any]]
            var updatedPackages: [[String: String]] = []
            for thePackage in patchPackages ?? [] {
                // get source package (file) name
                print("[cleanJSON - patchmanagement] thePackage: \(thePackage)")
                let sourcePackageName = (fileImport) ? thePackage["packageName"] as? String ?? "unknown": PatchPackages.source.first(where: { $0.packageId == thePackage["packageId"] as? String })?.packageName ?? ""
                print("[cleanJSON - patchmanagement] sourcePackageName: \(sourcePackageName)")
                let packageId = PatchPackages.destination.first(where: { $0.displayName == sourcePackageName })?.packageId ?? ""
                
                if packageId.isEmpty {
                    WriteToLog.shared.message(stringOfText: "Unable to locate patch package \(sourcePackageName) on the destination server.")
                } else {
                    updatedPackages.append(["packageId": packageId, "version": "\(thePackage["version"] ?? "")"])
                    print("[cleanJSON - patchmanagement] packageName: \(sourcePackageName)")
                }
            }
            JSONData["packages"] = updatedPackages
            print("[cleanJSON - patchmanagement] JSON: \(JSONData)")
            
        default:
            if action != "skip" {
                JSONData["id"] = nil
                
                for (key, value) in JSONData {
                    if "\(value)" == "<null>" {
                        JSONData[key] = nil
                    } else {
                        JSONData[key] = "\(value)"
                    }
                }
            }
        }
        
        
        createEndpoints2(endpointType: theEndpoint, endPointJSON: JSONData, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, sourceEpId: endpointID, destEpId: destEpId, ssIconName: "", ssIconId: "", ssIconUri: "", retry: false) {
            (result: String) in
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[endPointByID] \(result)") }
            if endpointCurrent == endpointCount {
                completion("last")
            } else {
                completion("")
            }
        }
    }
        
    
    func cleanupXml(endpoint: String, Xml: String, endpointID: String, endpointCurrent: Int, endpointCount: Int, action: String, destEpId: Int, destEpName: String, completion: @escaping (_ result: String) -> Void) {
        
        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[cleanUpXml] enter") }

        if pref.stopMigration {
//            print("[\(#function)] \(#line) stopMigration")
            stopButton(self)
            completion("")
            return
        }
        
        var PostXML       = Xml
        var knownEndpoint = true

        var iconName       = ""
        var iconId_string  = ""
        var iconId         = "0"
        var iconUri        = ""
        
        var theEndpoint    = endpoint
        
        switch endpoint {
        // adjust the where the data is sent
        case "accounts/userid":
            theEndpoint = "jamfusers"
        case "accounts/groupid":
            theEndpoint = "jamfgroups"
        default:
            theEndpoint = endpoint
        }
        
        // strip out <id> tag from XML
        for xmlTag in ["id"] {
            PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag, keepTags: false)
        }
        
        // check scope options for mobiledeviceconfigurationprofiles, osxconfigurationprofiles, restrictedsoftware... - start
        switch endpoint {
        case "osxconfigurationprofiles":
            if !self.scopeOcpCopy {
                PostXML = self.rmXmlData(theXML: PostXML, theTag: "scope", keepTags: false)
            }
        case "policies":
            if !self.scopePoliciesCopy {
                PostXML = self.rmXmlData(theXML: PostXML, theTag: "scope", keepTags: false)
            }
            if self.policyPoliciesDisable {
                PostXML = self.disable(theXML: PostXML)
            }
        case "macapplications":
            if !self.scopeMaCopy {
                PostXML = self.rmXmlData(theXML: PostXML, theTag: "scope", keepTags: false)
            }
        case "restrictedsoftware":
            if !self.scopeRsCopy {
                PostXML = self.rmXmlData(theXML: PostXML, theTag: "scope", keepTags: false)
            }
        case "mobiledeviceconfigurationprofiles":
            if !self.scopeMcpCopy {
                PostXML = self.rmXmlData(theXML: PostXML, theTag: "scope", keepTags: false)
            }
        case "mobiledeviceapplications":
            if !self.scopeIaCopy {
                PostXML = self.rmXmlData(theXML: PostXML, theTag: "scope", keepTags: false)
            }
        case "usergroups", "smartusergroups", "staticusergroups":
            if !self.scopeUsersCopy {
                PostXML = self.rmXmlData(theXML: PostXML, theTag: "users", keepTags: false)
            }

        default:
            break
        }
        // check scope options for mobiledeviceconfigurationprofiles, osxconfigurationprofiles, and restrictedsoftware - end
        
        switch endpoint {
        case "buildings", "departments", "diskencryptionconfigurations", "sites", "categories", "dockitems", "softwareupdateservers", "scripts", "printers", "osxconfigurationprofiles", "patchpolicies", "mobiledeviceconfigurationprofiles", "advancedmobiledevicesearches", "mobiledeviceextensionattributes", "mobiledevicegroups", "smartmobiledevicegroups", "staticmobiledevicegroups", "mobiledevices", "usergroups", "smartusergroups", "staticusergroups", "userextensionattributes", "advancedusersearches", "restrictedsoftware":
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[cleanupXml] processing \(endpoint) - verbose") }
            //print("\nXML: \(PostXML)")
            
            // clean up PostXML, remove unwanted/conflicting data
            switch endpoint {
            case "advancedusersearches":
                for xmlTag in ["users"] {
                    PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag, keepTags: false)
                }
                
            case "advancedmobiledevicesearches", "mobiledevicegroups", "smartmobiledevicegroups", "staticmobiledevicegroups":
                //                                 !self.scopeSigCopy
                if (PostXML.range(of:"<is_smart>true</is_smart>") != nil || !self.scopeSigCopy) {
                    PostXML = self.rmXmlData(theXML: PostXML, theTag: "mobile_devices", keepTags: false)
                }
                
//                if itemToSite && destinationSite != "" && endpoint != "advancedmobiledevicesearches" {
                if JamfProServer.toSite && destinationSite != "" && endpoint != "advancedmobiledevicesearches" {
                    PostXML = setSite(xmlString: PostXML, site: destinationSite, endpoint: endpoint)
                }
                
            case "mobiledevices":
                for xmlTag in ["initial_entry_date_epoch", "initial_entry_date_utc", "last_enrollment_epoch", "last_enrollment_utc", "certificates", "configuration_profiles", "provisioning_profiles", "mobile_device_groups", "extension_attributes"] {
                    PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag, keepTags: false)
                }
                
                if JamfProServer.toSite && destinationSite != "" {
                    PostXML = setSite(xmlString: PostXML, site: destinationSite, endpoint: endpoint)
                }
                
            case "osxconfigurationprofiles", "mobiledeviceconfigurationprofiles":
                // migrating to another site
                if JamfProServer.toSite && destinationSite != "" {
                    PostXML = setSite(xmlString: PostXML, site: destinationSite, endpoint: endpoint)
                }
                
                if endpoint == "osxconfigurationprofiles" {
                    // check for filevault payload
                    let payload = tagValue2(xmlString: "\(PostXML)", startTag: "<payloads>", endTag: "</payloads>")
                    
                    if payload.range(of: "com.apple.security.FDERecoveryKeyEscrow", options: .caseInsensitive) != nil {
                        let profileName = getName(endpoint: "osxconfigurationprofiles", objectXML: PostXML)
                        knownEndpoint = false

                        let localTmp = (self.counters[endpoint]?["fail"])!
                        self.counters[endpoint]?["fail"] = localTmp + 1
                        if var summaryArray = self.summaryDict[endpoint]?["fail"] {
                            summaryArray.append(profileName)
                            self.summaryDict[endpoint]?["fail"] = summaryArray
                        }
                        WriteToLog.shared.message(stringOfText: "[cleanUpXml] FileVault payloads are not migrated and must be recreated manually, skipping \(profileName)")
                        Counter.shared.post += 1
                        putStatusUpdate2(endpoint: "osxconfigurationprofiles", total: endpointCount)
                        if self.objectsToMigrate.last == endpoint && endpointCount == endpointCurrent {
                            //self.go_button.isEnabled = true
                            self.rmDELETE()
        //                    self.resetAllCheckboxes()
                            print("[\(#function)] \(#line) - finished cleanup")
                            self.goButtonEnabled(button_status: true)
                        }
                    }
                }
                if knownEndpoint {
                    // correct issue when an & is in the name of a macOS configuration profiles - real issue is in the encoded payload
                    PostXML = PostXML.replacingOccurrences(of: "&amp;amp;", with: "%26;")
                    //print("\nXML: \(PostXML)")
                    // fix limitations/exclusions LDAP issue
                    for xmlTag in ["limit_to_users"] {
                        PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag, keepTags: false)
                    }
                }
                
            case "usergroups", "smartusergroups", "staticusergroups":
                for xmlTag in ["full_name", "phone_number", "email_address"] {
                    PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag, keepTags: false)
                }
                
            case "scripts":
                for xmlTag in ["script_contents_encoded"] {
                    PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag, keepTags: false)
                }
                // fix to remove parameter labels that have been deleted from existing scripts
//                    let theScript = tagValue(xmlString: PostXML, xmlTag: "script_contents")
//                    print("[cleanup] theScript: \(theScript)")
//                    if theScript != "" {
//                        PostXML = rmXmlData(theXML: PostXML, theTag: "script_contents", keepTags: true)
//                        PostXML = PostXML.replacingOccurrences(of: "<script_contents/>", with: "<script_contents>\(theScript.xmlEncode)</script_contents>")
//                    }
                PostXML = self.parameterFix(theXML: PostXML)
                
            default: break
            }
            
        case "classes":
            // check for Apple School Manager class
            let source = tagValue2(xmlString: "\(PostXML)", startTag: "<source>", endTag: "</source>")
            if source == "Apple School Manager" {
                let className = getName(endpoint: "classes", objectXML: PostXML)
                knownEndpoint = false
                // Apple School Manager class - handle those here
                // update global counters

                let localTmp = (self.counters[endpoint]?["fail"])!
                self.counters[endpoint]?["fail"] = localTmp + 1
                if var summaryArray = self.summaryDict[endpoint]?["fail"] {
                    summaryArray.append(className)
                    self.summaryDict[endpoint]?["fail"] = summaryArray
                }
                WriteToLog.shared.message(stringOfText: "[cleanUpXml] Apple School Manager classes are not migrated, skipping \(className)")
                Counter.shared.post += 1
                putStatusUpdate2(endpoint: "classes", total: endpointCount)
                if self.objectsToMigrate.last == endpoint && endpointCount == endpointCurrent {
                    //self.go_button.isEnabled = true
                    self.rmDELETE()
//                    self.resetAllCheckboxes()
                    print("[\(#function)] \(#line) - finished cleanup")
                    self.goButtonEnabled(button_status: true)
                }
            } else {
                for xmlTag in ["student_ids", "teacher_ids", "student_group_ids", "teacher_group_ids", "mobile_device_group_ids"] {
                    PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag, keepTags: false)
                }
               for xmlTag in ["student_ids/", "teacher_ids/", "student_group_ids/", "teacher_group_ids/", "mobile_device_group_ids/"] {
                   PostXML = PostXML.replacingOccurrences(of: "<\(xmlTag)>", with: "")
               }
            }

        case "computerextensionattributes":
            if tagValue(xmlString: PostXML, xmlTag: "description") == "Extension Attribute provided by JAMF Nation patch service" {
                knownEndpoint = false
                // Currently patch EAs are not migrated - handle those here
                if self.counters[endpoint]?["fail"] != endpointCount-1 {
                    self.labelColor(endpoint: endpoint, theColor: self.yellowText)
                } else {
                    // every EA failed, and a patch EA was the last on the list
                    self.labelColor(endpoint: endpoint, theColor: self.redText)
                }
                // update global counters
                let patchEaName = self.getName(endpoint: endpoint, objectXML: PostXML)

                let localTmp = (self.counters[endpoint]?["fail"])!
                self.counters[endpoint]?["fail"] = localTmp + 1
                if var summaryArray = self.summaryDict[endpoint]?["fail"] {
                    summaryArray.append(patchEaName)
                    self.summaryDict[endpoint]?["fail"] = summaryArray
                }
                WriteToLog.shared.message(stringOfText: "[cleanUpXml] Patch EAs are not migrated, skipping \(patchEaName)")
                Counter.shared.post += 1
                if self.objectsToMigrate.last == endpoint && endpointCount == endpointCurrent {
                    //self.go_button.isEnabled = true
                    self.rmDELETE()
//                    self.resetAllCheckboxes()
                    print("[\(#function)] \(#line) - finished cleanup")
                    self.goButtonEnabled(button_status: true)
                }
            }
            
        case "directorybindings", "ldapservers","distributionpoints":
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[cleanUpXml] processing \(endpoint) - verbose") }
            var credentialsArray = [String]()
            var newPasswordXml   = ""

            switch endpoint {
            case "directorybindings", "ldapservers":
                let regexPwd = try! NSRegularExpression(pattern: "<password_sha256 since=\"9.23\">(.*?)</password_sha256>", options:.caseInsensitive)
                if userDefaults.integer(forKey: "prefBindPwd") == 1 && endpoint == "directorybindings" {
                    //setPassword = true
                    accountDict = Creds2.retrieve(service: "migrator-bind", account: "")
                    if accountDict.count != 1 {
                        // set password for bind account since one was not found in the keychain
                        newPasswordXml =  "<password>changeM3!</password>"
                    } else {
                        newPasswordXml = "<password>\(accountDict.password)</password>"
                    }
                }
                if userDefaults.integer(forKey: "prefLdapPwd") == 1 && endpoint == "ldapservers" {
                    accountDict = Creds2.retrieve(service: "migrator-ldap", account: "")
                    if accountDict.count != 1 {
                        // set password for LDAP account since one was not found in the keychain
                        newPasswordXml =  "<password>changeM3!</password>"
                    } else {
                        newPasswordXml = "<password>\(accountDict.password)</password>"
                    }
                }
                PostXML = regexPwd.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "\(newPasswordXml)")
            case "distributionpoints":
                var credentialsArray2 = [String]()
                var newPasswordXml2   = ""
                let regexRwPwd = try! NSRegularExpression(pattern: "<read_write_password_sha256 since=\"9.23\">(.*?)</read_write_password_sha256>", options:.caseInsensitive)
                let regexRoPwd = try! NSRegularExpression(pattern: "<read_only_password_sha256 since=\"9.23\">(.*?)</read_only_password_sha256>", options:.caseInsensitive)
                if userDefaults.integer(forKey: "prefFileSharePwd") == 1 && endpoint == "distributionpoints" {
                    accountDict = Creds2.retrieve(service: "migrator-fsrw", account: "")
                    if accountDict.count != 1 {
                        // set password for fileshare RW account since one was not found in the keychain
                        newPasswordXml =  "<read_write_password>changeM3!</read_write_password>"
                    } else {
                        newPasswordXml = "<read_write_password>\(accountDict.password)</read_write_password>"
                    }
                    accountDict  = Creds2.retrieve(service: "migrator-fsro", account: "")
                    if accountDict.count != 1 {
                        // set password for fileshare RO account since one was not found in the keychain
                        newPasswordXml2 =  "<read_only_password>changeM3!</read_only_password>"
                    } else {
                        newPasswordXml2 = "<read_only_password>\(accountDict.password)</read_only_password>"
                    }
                }
                PostXML = regexRwPwd.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "\(newPasswordXml)")
                PostXML = regexRoPwd.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "\(newPasswordXml2)")
            default:
                break
            }

        case "advancedcomputersearches":
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[cleanUpXml] processing advancedcomputersearches - verbose") }
            // clean up some data from XML
            for xmlTag in ["computers"] {
                PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag, keepTags: false)
            }
            
        case "computers":
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[cleanUpXml] processing computers - verbose") }
            // clean up some data from XML
            for xmlTag in ["package", "mapped_printers", "plugins", "report_date", "report_date_epoch", "report_date_utc", "running_services", "licensed_software", "computer_group_memberships"] {
                PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag, keepTags: false)
            }
            // remove Conditional Access ID from record, if selected
            if userDefaults.integer(forKey: "removeCA_ID") == 1 {
                PostXML = self.rmXmlData(theXML: PostXML, theTag: "device_aad_infos", keepTags: false)
            }
            
            if JamfProServer.toSite && destinationSite != "" {
                PostXML = setSite(xmlString: PostXML, site: destinationSite, endpoint: endpoint)
            }
            
            // remote management
            let regexRemote = try! NSRegularExpression(pattern: "<remote_management>(.|\n|\r)*?</remote_management>", options:.caseInsensitive)
            if userDefaults.integer(forKey: "migrateAsManaged") == 1 {
                var accountDict = Creds2.retrieve(service: "migrator-mgmtAcct", account: "")
                if accountDict.count != 1 {
                    // set default management account credentials
                    accountDict["jamfpro_manage"] = "changeM3!"
                }
                PostXML = regexRemote.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: """
            <remote_management>
                <managed>true</managed>
                <management_username>\(accountDict.username)</management_username>
                <management_password>\(accountDict.password)</management_password>
            </remote_management>
""")
            } else {
                PostXML = regexRemote.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: """
            <remote_management>
                <managed>false</managed>
            </remote_management>
""")
            }
//            print("migrate as managed: \(userDefaults.integer(forKey: "migrateAsManaged"))")
//            print("\(PostXML)")



            // change serial number 'Not Available' to blank so machines will migrate
            PostXML = PostXML.replacingOccurrences(of: "<serial_number>Not Available</serial_number>", with: "<serial_number></serial_number>")

            PostXML = PostXML.replacingOccurrences(of: "<xprotect_version/>", with: "")
            PostXML = PostXML.replacingOccurrences(of: "<size>0</size>", with: "")
            PostXML = PostXML.replacingOccurrences(of: "<size>-1</size>", with: "")
            let regexAvailable_mb = try! NSRegularExpression(pattern: "<available_mb>-(.*?)</available_mb>", options:.caseInsensitive)
            PostXML = regexAvailable_mb.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<available_mb>1</available_mb>")
            //print("\nXML: \(PostXML)")
            
        case "networksegments":
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[cleanUpXml] processing network segments - verbose") }
            // remove items not transfered; netboot server, SUS from XML
            let regexDistro1 = try! NSRegularExpression(pattern: "<distribution_server>(.*?)</distribution_server>", options:.caseInsensitive)
//            let regexDistro2 = try! NSRegularExpression(pattern: "<distribution_point>(.*?)</distribution_point>", options:.caseInsensitive)
            let regexDistroUrl = try! NSRegularExpression(pattern: "<url>(.*?)</url>", options:.caseInsensitive)
//            let regexNetBoot = try! NSRegularExpression(pattern: "<netboot_server>(.*?)</netboot_server>", options:.caseInsensitive)
            let regexSUS = try! NSRegularExpression(pattern: "<swu_server>(.*?)</swu_server>", options:.caseInsensitive)
            PostXML = regexDistro1.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<distribution_server/>")
            // clear JCDS url from network segments xml - start
            if tagValue2(xmlString: PostXML, startTag: "<distribution_point>", endTag: "</distribution_point>") == "Cloud Distribution Point" {
                PostXML = regexDistroUrl.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<url/>")
            }
            
            // if not migrating software update server remove then from network segments xml - start
            if self.objectsToMigrate.firstIndex(of: "softwareupdateservers") == 0 {
                PostXML = regexSUS.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<swu_server/>")
//                }
            // if not migrating software update server remove then from network segments xml - end
            }
            
            //print("\nXML: \(PostXML)")
            
        case "computergroups", "smartcomputergroups", "staticcomputergroups":
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[cleanUpXml] processing \(endpoint) - verbose") }
            // remove computers that are a member of a smart group
            if (PostXML.range(of:"<is_smart>true</is_smart>") != nil || !self.scopeScgCopy) {
                // groups containing thousands of computers could not be cleared by only using the computers tag
                PostXML = self.rmXmlData(theXML: PostXML, theTag: "computer", keepTags: false)
                PostXML = self.rmBlankLines(theXML: PostXML)
                PostXML = self.rmXmlData(theXML: PostXML, theTag: "computers", keepTags: false)
            }
            //            print("\n\(endpoint) XML: \(PostXML)")
            
            // migrating to another site
//            DispatchQueue.main.async {
            if JamfProServer.toSite && destinationSite != "" {
                    PostXML = setSite(xmlString: PostXML, site: destinationSite, endpoint: endpoint)
                }
//            }
            
        case "packages":
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[cleanUpXml] processing packages - verbose") }
            // remove 'No category assigned' from XML
            let regexComp = try! NSRegularExpression(pattern: "<category>No category assigned</category>", options:.caseInsensitive)
            PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<category/>")// clean up some data from XML
            for xmlTag in ["hash_type", "hash_value"] {
                PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag, keepTags: false)
            }
            //print("\nXML: \(PostXML)")
            
        case "policies", "macapplications", "mobiledeviceapplications":
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[cleanUpXml] processing \(endpoint) - verbose") }
            // check for a self service icon and grab name and id if present - start
            // also used for exporting items - iOS
            if PostXML.range(of: "</self_service_icon>") != nil {
                let selfServiceIconXml = tagValue(xmlString: PostXML, xmlTag: "self_service_icon")
                iconName = tagValue(xmlString: selfServiceIconXml, xmlTag: "filename")
                iconUri = tagValue(xmlString: selfServiceIconXml, xmlTag: "uri").replacingOccurrences(of: "//iconservlet", with: "/iconservlet")

                iconId = getIconId(iconUri: iconUri, endpoint: endpoint)
            }
            // check for a self service icon and grab name and id if present - end
            
            if (endpoint == "macapplications") || (endpoint == "mobiledeviceapplications") {  // "vpp_admin_account_id", "total_vpp_licenses", "remaining_vpp_licenses"
                if let index = iconUri.firstIndex(of: "&") {
                    iconUri = String(iconUri.prefix(upTo: index))
                    //                    print("[cleanupXml] adjusted - self service icon name: \(iconName) \t uri: \(iconUri)")
                }
                let regexVPP = try! NSRegularExpression(pattern: "<vpp>(.*?)</vpp>", options:.caseInsensitive)
                PostXML = regexVPP.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<vpp><assign_vpp_device_based_licenses>false</assign_vpp_device_based_licenses><vpp_admin_account_id>-1</vpp_admin_account_id></vpp>")
            }
            
            // fix names that start with spaces - convert space to hex: &#xA0;
            let regexPolicyName = try! NSRegularExpression(pattern: "<name> ", options:.caseInsensitive)
            PostXML = regexPolicyName.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<name>&#xA0;")
            
            for xmlTag in ["limit_to_users","open_firmware_efi_password","self_service_icon"] {
                PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag, keepTags: false)
            }
            
            // update references to the Jamf server - skip if migrating files
            if JamfProServer.source.prefix(4) == "http" {
                let regexServer = try! NSRegularExpression(pattern: JamfProServer.source.urlToFqdn, options:.caseInsensitive)
                PostXML = regexServer.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: self.dest_jp_server.urlToFqdn)
            }
            
            // set the password used in the accounts payload to jamfchangeme - start
            let regexAccounts = try! NSRegularExpression(pattern: "<password_sha256 since=\"9.23\">(.*?)</password_sha256>", options:.caseInsensitive)
            PostXML = regexAccounts.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<password>jamfchangeme</password>")
            // set the password used in the accounts payload to jamfchangeme - end
            
            let regexComp = try! NSRegularExpression(pattern: "<management_password_sha256 since=\"9.23\">(.*?)</management_password_sha256>", options:.caseInsensitive)
            PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "")
            //print("\nXML: \(PostXML)")
            
            // resets distribution point (to default) used for policies that deploy packages
//            if endpoint == "policies" {
//                let regexDistro = try! NSRegularExpression(pattern: "<distribution_point>(.*?)</distribution_point>", options:.caseInsensitive)
//                PostXML = regexDistro.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<distribution_point>default</distribution_point>")
//            }
            
            // migrating to another site
            if JamfProServer.toSite && destinationSite != "" && endpoint == "policies" {
                PostXML = setSite(xmlString: PostXML, site: destinationSite, endpoint: endpoint)
            }
            
        case "users":
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[cleanUpXml] processing users - verbose") }
            
            let regexComp = try! NSRegularExpression(pattern: "<self_service_icon>(.*?)</self_service_icon>", options:.caseInsensitive)
            PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<self_service_icon/>")
            // remove photo reference from XML
            for xmlTag in ["enable_custom_photo_url", "custom_photo_url", "links", "ldap_server"] {
                PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag, keepTags: false)
            }
            if JamfProServer.toSite && destinationSite != "" {
                PostXML = setSite(xmlString: PostXML, site: destinationSite, endpoint: endpoint)
            }
            
        case "jamfusers", "jamfgroups", "accounts/userid", "accounts/groupid":
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[cleanUpXml] processing jamf users/groups (\(endpoint)) - verbose") }
            // remove password from XML, since it doesn't work on the new server
            let regexComp = try! NSRegularExpression(pattern: "<password_sha256 since=\"9.32\">(.*?)</password_sha256>", options:.caseInsensitive)
            PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "")
            //print("\nXML: \(PostXML)")
            // check for LDAP account/group, make adjustment for v10.17+ which needs id rather than name - start
            if tagValue(xmlString: PostXML, xmlTag: "ldap_server") != "" {
                let ldapServerInfo = tagValue(xmlString: PostXML, xmlTag: "ldap_server")
                let ldapServerName = tagValue(xmlString: ldapServerInfo, xmlTag: "name")
                let regexLDAP      = try! NSRegularExpression(pattern: "<ldap_server>(.|\n|\r)*?</ldap_server>", options:.caseInsensitive)
                if !setting.hardSetLdapId {
                    setting.ldapId = currentLDAPServers[ldapServerName] ?? -1
                }
                PostXML = regexLDAP.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<ldap_server><id>\(setting.ldapId)</id></ldap_server>")
            } else if setting.hardSetLdapId && setting.ldapId > 0 {
                let ldapObjectUsername = tagValue(xmlString: PostXML, xmlTag: "name").lowercased()
                // make sure we don't change the account we're authenticated to the destination server with
                if ldapObjectUsername != dest_user.lowercased() {
                    let regexNoLdap    = try! NSRegularExpression(pattern: "</full_name>", options:.caseInsensitive)
                    PostXML = regexNoLdap.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "</full_name><ldap_server><id>\(setting.ldapId)</id></ldap_server>")
                }
            }
//            print("PostXML: \(PostXML)")
            // check for LDAP account/group, make adjustment for v10.17+ which needs id rather than name - end
            if action == "create" {
                // newly created local accounts are disabled
                if PostXML.range(of: "<directory_user>false</directory_user>") != nil {
                    let regexComp1 = try! NSRegularExpression(pattern: "<enabled>Enabled</enabled>", options:.caseInsensitive)
                    PostXML = regexComp1.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<enabled>Disabled</enabled>")
                }
            } else {
                // don't change enabled status of existing accounts on destination server.
                for xmlTag in ["enabled"] {
                    PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag, keepTags: false)
                }
            }
            
        default:
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[cleanUpXml] Unknown endpoint: \(endpoint)") }
            knownEndpoint = false
        }   // switch - end
        
        if knownEndpoint {
//            print("\n[cleanupXml] knownEndpoint-PostXML: \(PostXML)")
            var destEndpoint = "skip"
            if (action == "update") && (theEndpoint == "osxconfigurationprofiles") {
                destEndpoint = theEndpoint
            }
            
            XmlDelegate().apiAction(method: "GET", theServer: dest_jp_server, base64Creds: JamfProServer.base64Creds["dest"] ?? "", theEndpoint: "\(destEndpoint)/id/\(destEpId)") {
                (xmlResult: (Int,String)) in
                let (_, fullXML) = xmlResult
                
                if fullXML != "" {
                    var destUUID = tagValue2(xmlString: fullXML, startTag: "<general>", endTag: "</general>")
                    destUUID     = tagValue2(xmlString: destUUID, startTag: "<uuid>", endTag: "</uuid>")
//                    print ("  destUUID: \(destUUID)")
                    var sourceUUID = tagValue2(xmlString: PostXML, startTag: "<general>", endTag: "</general>")
                    sourceUUID     = tagValue2(xmlString: sourceUUID, startTag: "<uuid>", endTag: "</uuid>")
//                    print ("sourceUUID: \(sourceUUID)")

                    // update XML to be posted with original/existing UUID of the configuration profile
                    PostXML = PostXML.replacingOccurrences(of: sourceUUID, with: destUUID)
                }
                
                self.createEndpointsQueue(endpointType: theEndpoint, endpointName: destEpName, endPointXML: PostXML, endpointCurrent: Int(endpointCurrent), endpointCount: endpointCount, action: action, sourceEpId: Int(endpointID)!, destEpId: destEpId, ssIconName: iconName, ssIconId: iconId, ssIconUri: iconUri, retry: false) {
                    (result: String) in
                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[cleanUpXml] call to createEndpointsQueue result: \(result)") }
                    if endpointCurrent == endpointCount {
//                        print("completed \(endpointCurrent) of \(endpointCount) - created last endpoint")
                        completion("last")
                    } else {
//                        print("completed \(endpointCurrent) of \(endpointCount) - created next endpoint")
                        completion("")
                    }
                }
            }
        } else {    // if knownEndpoint - end
            if endpointCurrent == endpointCount {
                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[cleanupXml] Last item in \(theEndpoint) was unkown.") }
                self.nodesMigrated+=1
                completion("last")
                // ;print("added node: \(localEndPointType) - createEndpoints")
                //                    print("nodes complete: \(self.nodesMigrated)")
            } else {
                completion("")
            }
        }
    }
    
    func createEndpointsQueue(endpointType: String, endpointName: String = "", endPointXML: String = "", endPointJSON: [String:Any] = [:], endpointCurrent: Int, endpointCount: Int, action: String, sourceEpId: Int, destEpId: Int, ssIconName: String, ssIconId: String, ssIconUri: String, retry: Bool, completion: @escaping (_ result: String) -> Void) {
        
        completion("return from createEndpointsQueue")
//        print("[createEndpointsQueue]                   action: \(action)")
//        print("[createEndpointsQueue] setting.onlyCopyExisting: \(setting.onlyCopyExisting)")
//        print("[createEndpointsQueue]  setting.onlyCopyMissing: \(setting.onlyCopyMissing)")

        if (setting.onlyCopyExisting && action == "create") || (setting.onlyCopyMissing && action == "update") {
            WriteToLog.shared.message(stringOfText: "[createEndpointsQueue] skip \(action) for \(endpointType) with name: \(endpointName)")
            counters[endpointType]?["skipped"]! += 1
            putStatusUpdate2(endpoint: endpointType, total: endpointCount)
            return
        }
        
        
        destEPQ.async { [self] in
            
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[createEndpointsQueue] que \(endpointType) with id \(sourceEpId) for upload")}
            createArray.append(ObjectInfo(endpointType: endpointType, endPointXml: endPointXML, endPointJSON: endPointJSON, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, sourceEpId: sourceEpId, destEpId: destEpId, ssIconName: ssIconName, ssIconId: ssIconId, ssIconUri: ssIconUri, retry: retry))
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "\n[createEndpointQueue] createArray.count: \(createArray.count)\n")}
            
            switch endpointType {
            case "buildings":
                while createArray.count > 0 {
                    if Counter.shared.pendingSend < maxConcurrentThreads && createArray.count > 0 {
                        Counter.shared.pendingSend += 1
//                        updatePendingCounter(caller: #function.short, change: 1)
                        let nextEndpoint = createArray[0]
                        createArray.remove(at: 0)
 
                        createEndpoints2(endpointType: nextEndpoint.endpointType, endPointJSON: nextEndpoint.endPointJSON, endpointCurrent: nextEndpoint.endpointCurrent, endpointCount: nextEndpoint.endpointCount, action: nextEndpoint.action, sourceEpId: "\(nextEndpoint.sourceEpId)", destEpId: nextEndpoint.destEpId, ssIconName: "", ssIconId: "", ssIconUri: "", retry: false) {
                            (result: String) in
                            Counter.shared.pendingSend -= 1
//                            updatePendingCounter(caller: #function.short, change: -1)
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[endPointByID] \(result)") }
                            if endpointCurrent == endpointCount {
                                completion("last")
                            } else {
                                completion("")
                            }
                        }
                    } else {
                        sleep(1)
                    }
                }
            default:
//                while Counter.shared.pendingSend > 0 || createArray.count > 0 {
                while createArray.count > 0 {
                    if Counter.shared.pendingSend < maxConcurrentThreads && createArray.count > 0 {
                        Counter.shared.pendingSend += 1
//                        updatePendingCounter(caller: #function.short, change: 1)
                        let nextEndpoint = createArray[0]
                        createArray.remove(at: 0)
                        
                        createEndpoints(endpointType: nextEndpoint.endpointType, endPointXML: nextEndpoint.endPointXml, endpointCurrent: nextEndpoint.endpointCurrent, endpointCount: nextEndpoint.endpointCount, action: nextEndpoint.action, sourceEpId: nextEndpoint.sourceEpId, destEpId: nextEndpoint.destEpId, ssIconName: nextEndpoint.ssIconName, ssIconId: nextEndpoint.ssIconId, ssIconUri: nextEndpoint.ssIconUri, retry: nextEndpoint.retry) {
                                (result: String) in
                            Counter.shared.pendingSend -= 1
//                            self.updatePendingCounter(caller: #function.short, change: -1)
                        }
                    } else {
                        sleep(1)
                    }
                }
            }
        }
    }

    func updatePendingCounter(caller: String, change: Int) {
        DispatchQueue.global().async {
//            self.lockQueue.async {
//                print("[updatePendingCounter] called from: \(caller), change: \(change)")
                Counter.shared.pendingSend += change
//            }
        }
    }
    
    func createEndpoints(endpointType: String, endPointXML: String, endpointCurrent: Int, endpointCount: Int, action: String, sourceEpId: Int, destEpId: Int, ssIconName: String, ssIconId: String, ssIconUri: String, retry: Bool, completion: @escaping (_ result: String) -> Void) {
        
                if pref.stopMigration {
//                    print("[\(#function)] \(#line) stopMigration")
                    stopButton(self)
                    completion("stop")
                    return
                }
                
                setting.createIsRunning = true
                
                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[CreateEndpoints] enter for \(endpointType), id \(sourceEpId)") }

                if counters[endpointType] == nil {
                    counters[endpointType] = ["create":0, "update":0, "fail":0, "skipped":0, "total":0]
        //            self.summaryDict[endpointType] = ["create":[], "update":[], "fail":[]]
                } else {
                    counters[endpointType]!["total"] = endpointCount
                }
                if summaryDict[endpointType] == nil {
        //            counters[endpointType] = ["create":0, "update":0, "fail":0, "skipped":0, "total":0]
                    summaryDict[endpointType] = ["create":[], "update":[], "fail":[]]
                }

                var destinationEpId = destEpId
                var apiAction       = action
                var sourcePolicyId  = ""
                
                // counterts for completed endpoints
                if endpointCurrent == 1 {
        //            print("[CreateEndpoints] reset counters")
                    labelColor(endpoint: endpointType, theColor: self.greenText)
                    totalCreated   = 0
                    totalUpdated   = 0
                    totalFailed    = 0
                    totalCompleted = 0
                }
                
                // if working a site migrations within a single server force create when copying an item
                if JamfProServer.toSite && sitePref == "Copy" {
                    if endpointType != "users"{
                        destinationEpId = 0
                        apiAction       = "create"
                    }
                }
                
                // this is where we create the new endpoint
                if !export.saveOnly {
                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[CreateEndpoints] Creating new: \(endpointType)") }
                } else {
                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[CreateEndpoints] Save only selected, skipping \(apiAction) for: \(endpointType)") }
                }
                //if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[CreateEndpoints] ----- Posting #\(endpointCurrent): \(endpointType) -----") }
                
                theCreateQ.maxConcurrentOperationCount = maxConcurrentThreads
//                let semaphore = DispatchSemaphore(value: 0)
                
        //        print("endPointXML:\n\(endPointXML)")
                
                let encodedXML = endPointXML.data(using: String.Encoding.utf8)
                var localEndPointType = ""
                var whichError        = ""
                
                switch endpointType {
                case "smartcomputergroups", "staticcomputergroups":
                    localEndPointType = "computergroups"
                case "smartmobiledevicegroups", "staticmobiledevicegroups":
                    localEndPointType = "mobiledevicegroups"
                case "smartusergroups", "staticusergroups":
                    localEndPointType = "usergroups"
                default:
                    localEndPointType = endpointType
                }
                var responseData = ""
                
                var createDestUrl = "\(createDestUrlBase)/" + localEndPointType + "/id/\(destinationEpId)"
                
                // for computers/mobile devices POST to unique identifier
                let identifier = tagValue2(xmlString:endPointXML, startTag:"<udid>", endTag:"</udid>")
                if apiAction == "update" && (endpointType == "computers" || endpointType == "mobiledevices") {
//                    print("[createEndpoints] xml: \(endPointXML)")
                    createDestUrl = createDestUrl.replacingOccurrences(of: "/id/\(destinationEpId)", with: "/udid/\(identifier)")
                }
//                print("[createEndpoints] createDestUrl: \(createDestUrl)")
                
                
                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[CreateEndpoints] Original Dest. URL: \(createDestUrl)") }
                createDestUrl = createDestUrl.urlFix
        //        createDestUrl = createDestUrl.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
                createDestUrl = createDestUrl.replacingOccurrences(of: "/JSSResource/jamfusers/id", with: "/JSSResource/accounts/userid")
                createDestUrl = createDestUrl.replacingOccurrences(of: "/JSSResource/jamfgroups/id", with: "/JSSResource/accounts/groupid")
                        
                theCreateQ.addOperation {
                    
                    // save trimmed XML - start
                    if export.saveTrimmedXml {
                        let endpointName = self.getName(endpoint: endpointType, objectXML: endPointXML)
                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[CreateEndpoints] Saving trimmed XML for \(endpointName) with id: \(sourceEpId).") }
                        DispatchQueue.main.async {
                            let exportTrimmedXml = (export.trimmedXmlScope) ? endPointXML:self.rmXmlData(theXML: endPointXML, theTag: "scope", keepTags: false)
                            WriteToLog.shared.message(stringOfText: "[CreateEndpoints] Exporting trimmed XML for \(endpointType) - \(endpointName).")
                            XmlDelegate().save(node: endpointType, xml: exportTrimmedXml, rawName: endpointName, id: "\(sourceEpId)", format: "trimmed")
                        }
                    }
                    // save trimmed XML - end
        //            print("[\(#line)-CreateEndpoints] endpointName: \(self.endpointName)")
        //            print("[\(#line)-CreateEndpoints] objectsToMigrate: \(self.objectsToMigrate)")
                    if export.saveOnly {
                        if (((endpointType == "policies") || (endpointType == "mobiledeviceapplications")) && (action == "create" || setting.csa)) || export.backupMode {
                            sourcePolicyId = (endpointType == "policies") ? "\(sourceEpId)":""

                            let ssInfo: [String: String] = ["ssIconName": ssIconName, "ssIconId": ssIconId, "ssIconUri": ssIconUri, "ssXml": ""]
                            self.icons(endpointType: endpointType, action: action, ssInfo: ssInfo, f_createDestUrl: createDestUrl, responseData: responseData, sourcePolicyId: sourcePolicyId)
                        }
                        if self.objectsToMigrate.last!.contains(localEndPointType) && endpointCount == endpointCurrent {
                            self.rmDELETE()
                            print("[\(#function)] \(#line) - finished creating \(endpointType)")
                            self.goButtonEnabled(button_status: true)
                        }
                        completion("")
                        return
                    }
                    
                    // don't create object if we're removing objects
                    if !wipeData.on {
                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[CreateEndpoints] Action: \(apiAction)     URL: \(createDestUrl)     Object \(endpointCurrent) of \(endpointCount)") }
                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[CreateEndpoints] Object XML: \(endPointXML)") }
                        
                        if endpointCurrent == 1 {
                            if !retry {
                                Counter.shared.post = 1
                            }
                        } else {
                            if !retry {
                                Counter.shared.post += 1
                            }
                        }
                        if retry {
                            DispatchQueue.main.async {
                                WriteToLog.shared.message(stringOfText: "    [CreateEndpoints] [\(localEndPointType)] retrying: \(self.getName(endpoint: endpointType, objectXML: endPointXML))")
                            }
                        }
                        
                        let encodedURL = URL(string: createDestUrl)
                        let request = NSMutableURLRequest(url: encodedURL! as URL)
                        if apiAction == "create" {
                            request.httpMethod = "POST"
                        } else {
                            request.httpMethod = "PUT"
                        }
                        let configuration = URLSessionConfiguration.default

                        configuration.httpAdditionalHeaders = ["Authorization" : "\(JamfProServer.authType["dest"] ?? "Bearer") \(JamfProServer.authCreds["dest"] ?? "")", "Content-Type" : "text/xml", "Accept" : "text/xml", "User-Agent" : AppInfo.userAgentHeader]
                        
                        // sticky session
                        let cookieUrl = self.createDestUrlBase.replacingOccurrences(of: "JSSResource", with: "")
                        if JamfProServer.sessionCookie.count > 0 && JamfProServer.stickySession {
                            URLSession.shared.configuration.httpCookieStorage!.setCookies(JamfProServer.sessionCookie, for: URL(string: cookieUrl), mainDocumentURL: URL(string: cookieUrl))
                        }
                        
                        request.httpBody = encodedXML!
                        let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
                        let task = session.dataTask(with: request as URLRequest, completionHandler: { [self]
                            (data, response, error) -> Void in
                            session.finishTasksAndInvalidate()
                            if let httpResponse = response as? HTTPURLResponse {
                                
                                if let _ = String(data: data!, encoding: .utf8) {
                                    responseData = String(data: data!, encoding: .utf8)!
            //                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[CreateEndpoints] \n\nfull response from create:\n\(responseData)") }
            //                        print("create data response: \(responseData)")
                                } else {
                                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "\n\n[CreateEndpoints] No data was returned from post/put.") }
                                }
                                
                                // look to see if we are processing the next endpointType - start
                                if endpointInProgress != endpointType || endpointInProgress == "" {
                                    WriteToLog.shared.message(stringOfText: "[CreateEndpoints] Migrating \(endpointType)")
                                    endpointInProgress = endpointType
                                    POSTsuccessCount = 0
                                }   // look to see if we are processing the next localEndPointType - end
                                
        //                        DispatchQueue.main.async {
                                if let _ = createRetryCount["\(localEndPointType)-\(sourceEpId)"] {
                                    createRetryCount["\(localEndPointType)-\(sourceEpId)"]! += 1
                                    if createRetryCount["\(localEndPointType)-\(sourceEpId)"]! > 3 {
                                        whichError = "skip"
                                        createRetryCount["\(localEndPointType)-\(sourceEpId)"] = 0
                                        WriteToLog.shared.message(stringOfText: "    [CreateEndpoints] [\(localEndPointType)] migration of id:\(sourceEpId) failed, retry count exceeded.")
                                    }
                                } else {
                                    createRetryCount["\(localEndPointType)-\(sourceEpId)"] = 0
                                }
                                                            
                                if httpResponse.statusCode > 199 && httpResponse.statusCode <= 299 {
                                    WriteToLog.shared.message(stringOfText: "    [CreateEndpoints] [\(localEndPointType)] \(action) succeeded: \(getName(endpoint: endpointType, objectXML: endPointXML).xmlDecode)")
                                    
                                    createRetryCount["\(localEndPointType)-\(sourceEpId)"] = 0
                                    
                                    if endpointCurrent == 1 && !retry {
                                        migrationComplete.isDone = false
                                        if !setting.migrateDependencies || endpointType == "policies" {
                                            setLevelIndicatorFillColor(fn: "CreateEndpoints-\(endpointCurrent)", endpointType: endpointType, fillColor: .green)
                                        }
                                    } else if !retry {
                                        if let _ = PutLevelIndicator.shared.indicatorColor[endpointType] /*put_levelIndicatorFillColor[endpointType]*/ {
                                            setLevelIndicatorFillColor(fn: "CreateEndpoints-\(endpointCurrent)", endpointType: endpointType, fillColor: PutLevelIndicator.shared.indicatorColor[endpointType] ?? .green /*put_levelIndicatorFillColor[endpointType]!*/)
                                        }
                                    }
                                    
                                    POSTsuccessCount += 1
                                                                            
                                    if let _ = progressCountArray["\(endpointType)"] {
                                        progressCountArray["\(endpointType)"] = progressCountArray["\(endpointType)"]!+1
                                    }
                                    
                                    if localEndPointType != "policies" && dependency.isRunning {
                                        Counter.shared.dependencyMigrated[dependencyParentId]! += 1
                                    }
                                    
                                    counters[endpointType]?["\(apiAction)"]! += 1
                                    
                                    if var summaryArray = summaryDict[endpointType]?["\(apiAction)"] {
                                        summaryArray.append(getName(endpoint: endpointType, objectXML: endPointXML))
                                        summaryDict[endpointType]?["\(apiAction)"] = summaryArray
                                    }
                                    
                                    // currently there is no way to upload mac app store icons; no api endpoint
                                    // removed check for those -  || (endpointType == "macapplications")
                                    // mobiledeviceapplication icon data is in the object xml
    //                                print("setting.csa: \(setting.csa)")
    //                                if ((endpointType == "policies") || (endpointType == "mobiledeviceapplications")) && (action == "create" || setting.csa) {
                                    if (endpointType == "policies") && (action == "create" || setting.csa) {
                                        sourcePolicyId = (endpointType == "policies") ? "\(sourceEpId)":""

                                        let ssInfo: [String: String] = ["ssIconName": ssIconName, "ssIconId": ssIconId, "ssIconUri": ssIconUri, "ssXml": "\(tagValue2(xmlString: endPointXML, startTag: "<self_service>", endTag: "</self_service>"))"]
                                        icons(endpointType: endpointType, action: action, ssInfo: ssInfo, f_createDestUrl: createDestUrl, responseData: responseData, sourcePolicyId: sourcePolicyId)
                                    }
                                    
                                } else {
                                    // create failed
                                    labelColor(endpoint: endpointType, theColor: yellowText)
                                    if !setting.migrateDependencies || endpointType == "policies" {
                                        setLevelIndicatorFillColor(fn: "CreateEndpoints-\(endpointCurrent)", endpointType: endpointType, fillColor: .systemYellow)
                                    }
                                    
                                    var localErrorMsg = ""
                                    
                                    print("[createEndpoints]   identifier: \(identifier)")
                                    print("[createEndpoints] responseData: \(responseData)")
                                    print("[createEndpoints]       status: \(httpResponse.statusCode)")
                                    
                                    if httpResponse.statusCode == 404 {
                                        // retry doing a POST
                                        whichError = "device not found"
//                                            return
                                    } else {
                                        let errorMsg = tagValue2(xmlString: responseData, startTag: "<p>Error: ", endTag: "</p>")

                                        errorMsg != "" ? (localErrorMsg = "\(action.capitalized) error: \(errorMsg)"):(localErrorMsg = "\(action.capitalized) error: \(tagValue2(xmlString: responseData, startTag: "<p>", endTag: "</p>"))")
                                        
                                        // Write xml for degugging - end
                                        
                                        if whichError != "skip" {
                                            if errorMsg.lowercased().range(of:"no match found for category") != nil || errorMsg.lowercased().range(of:"problem with category") != nil {
                                                whichError = "category"
                                            } else {
                                                whichError = errorMsg
                                            }
                                        }
                                    }
                                    
                                    print("[createEndpoints] whichError: \(whichError)")
                                    // retry computers with dublicate serial or MAC - start
                                    switch whichError {
                                    case "device not found":
                                        print("[createEndpoints] device not found, try to create")
                                        createEndpoints(endpointType: endpointType, endPointXML: endPointXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: "create", sourceEpId: sourceEpId, destEpId: 0, ssIconName: ssIconName, ssIconId: ssIconId, ssIconUri: ssIconUri, retry: true) {
                                            (result: String) in
                                            //                                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[CreateEndpoints] \(result)") }
                                        }
                                        
                                    case "Duplicate UDID":
                                        print("[createEndpoints] Duplicate UDID, try to update")
                                        createEndpoints(endpointType: endpointType, endPointXML: endPointXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: "update", sourceEpId: sourceEpId, destEpId: -1, ssIconName: ssIconName, ssIconId: ssIconId, ssIconUri: ssIconUri, retry: true) {
                                            (result: String) in
                                            //                                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[CreateEndpoints] \(result)") }
                                        }
                                            
                                    case "Duplicate serial number", "Duplicate MAC address":
                                        WriteToLog.shared.message(stringOfText: "    [CreateEndpoints] [\(localEndPointType)] \(getName(endpoint: endpointType, objectXML: endPointXML)) - Conflict (\(httpResponse.statusCode)).  \(localErrorMsg).  Will retry without serial and MAC address (retry count: \(createRetryCount["\(localEndPointType)-\(sourceEpId)"]!)).")
                                        var tmp_endPointXML = endPointXML
                                        for xmlTag in ["alt_mac_address", "mac_address", "serial_number"] {
                                            tmp_endPointXML = rmXmlData(theXML: tmp_endPointXML, theTag: xmlTag, keepTags: false)
                                        }
                                        createEndpoints(endpointType: endpointType, endPointXML: tmp_endPointXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, sourceEpId: sourceEpId, destEpId: destEpId, ssIconName: ssIconName, ssIconId: ssIconId, ssIconUri: ssIconUri, retry: true) {
                                            (result: String) in
                                            //                                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[CreateEndpoints] \(result)") }
                                        }
                                        
                                    case "category":
                                        WriteToLog.shared.message(stringOfText: "    [CreateEndpoints] [\(localEndPointType)] \(getName(endpoint: endpointType, objectXML: endPointXML)) - Conflict (\(httpResponse.statusCode)).  \(localErrorMsg).  Will retry without the category (retry count: \(createRetryCount["\(localEndPointType)-\(sourceEpId)"]!)).")
                                        var tmp_endPointXML = endPointXML
                                        for xmlTag in ["category"] {
                                            tmp_endPointXML = rmXmlData(theXML: tmp_endPointXML, theTag: xmlTag, keepTags: false)
                                        }
                                        createEndpoints(endpointType: endpointType, endPointXML: tmp_endPointXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, sourceEpId: sourceEpId, destEpId: destEpId, ssIconName: ssIconName, ssIconId: ssIconId, ssIconUri: ssIconUri, retry: true) {
                                            (result: String) in
                                        }
                                        
                                    case "Problem with department in location":
                                        WriteToLog.shared.message(stringOfText: "    [CreateEndpoints] [\(localEndPointType)] \(getName(endpoint: endpointType, objectXML: endPointXML)) - Conflict (\(httpResponse.statusCode)).  \(localErrorMsg).  Will retry without the department (retry count: \(createRetryCount["\(localEndPointType)-\(sourceEpId)"]!)).")
                                        var tmp_endPointXML = endPointXML
                                        for xmlTag in ["department"] {
                                            tmp_endPointXML = rmXmlData(theXML: tmp_endPointXML, theTag: xmlTag, keepTags: false)
                                        }
                                        createEndpoints(endpointType: endpointType, endPointXML: tmp_endPointXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, sourceEpId: sourceEpId, destEpId: destEpId, ssIconName: ssIconName, ssIconId: ssIconId, ssIconUri: ssIconUri, retry: true) {
                                            (result: String) in
                                        }
                                        
                                    case "Problem with building in location":
                                        WriteToLog.shared.message(stringOfText: "    [CreateEndpoints] [\(localEndPointType)] \(getName(endpoint: endpointType, objectXML: endPointXML)) - Conflict (\(httpResponse.statusCode)).  \(localErrorMsg).  Will retry without the building (retry count: \(createRetryCount["\(localEndPointType)-\(sourceEpId)"]!)).")
                                        var tmp_endPointXML = endPointXML
                                        for xmlTag in ["building"] {
                                            tmp_endPointXML = rmXmlData(theXML: tmp_endPointXML, theTag: xmlTag, keepTags: false)
                                        }
                                        createEndpoints(endpointType: endpointType, endPointXML: tmp_endPointXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, sourceEpId: sourceEpId, destEpId: destEpId, ssIconName: ssIconName, ssIconId: ssIconId, ssIconUri: ssIconUri, retry: true) {
                                            (result: String) in
                                            //                                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[CreateEndpoints] \(result)") }
                                        }

                                    // retry network segment without distribution point
                                    case "Problem in assignment to distribution point":
                                        WriteToLog.shared.message(stringOfText: "    [CreateEndpoints] [\(localEndPointType)] \(getName(endpoint: endpointType, objectXML: endPointXML)) - Conflict (\(httpResponse.statusCode)).  \(localErrorMsg).  Will retry without the distribution point (retry count: \(createRetryCount["\(localEndPointType)-\(sourceEpId)"]!)).")
                                        var tmp_endPointXML = endPointXML
                                        for xmlTag in ["distribution_point", "url"] {
                                            tmp_endPointXML = rmXmlData(theXML: tmp_endPointXML, theTag: xmlTag, keepTags: true)
                                        }
                                        createEndpoints(endpointType: endpointType, endPointXML: tmp_endPointXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, sourceEpId: sourceEpId, destEpId: destEpId, ssIconName: ssIconName, ssIconId: ssIconId, ssIconUri: ssIconUri, retry: true) {
                                            (result: String) in
//                                              if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[CreateEndpoints] \(result)") }
                                        }

                                    default:
    //                                    createRetryCount["\(localEndPointType)-\(sourceEpId)"] = 0
                                        WriteToLog.shared.message(stringOfText: "[CreateEndpoints] [\(localEndPointType)] \(getName(endpoint: endpointType, objectXML: endPointXML)) - Failed (\(httpResponse.statusCode)).  \(localErrorMsg).\n")
                                        
    //                                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "\n") }
                                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[CreateEndpoints]  ---------- xml of failed upload ----------\n\(endPointXML)") }
                                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[CreateEndpoints] ---------- status code ----------") }
                                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[CreateEndpoints] \(httpResponse.statusCode)") }
                                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[CreateEndpoints] ---------- response data ----------\n\(responseData)") }
                                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[CreateEndpoints] -----------------------------------\n") }
                                        // 400 - likely the format of the xml is incorrect or wrong endpoint
                                        // 401 - wrong username and/or password
                                        // 409 - unable to create object; already exists or data missing or xml error
                        
                        //                print("create func: \(endpointCurrent) of \(endpointCount) complete.  \(nodesMigrated) nodes migrated.")
                                        if localEndPointType != "policies" && dependency.isRunning {
                                            Counter.shared.dependencyMigrated[dependencyParentId]! += 1
                    //                        print("[CreateEndpoints] Counter.shared.dependencyMigrated incremented: \(Counter.shared.dependencyMigrated[dependencyParentId]!)")
                                        }
                                        
                                        // update global counters
                                        let localTmp = (counters[endpointType]?["fail"])!
                                        counters[endpointType]?["fail"] = localTmp + 1
                                        if var summaryArray = summaryDict[endpointType]?["fail"] {
                                            summaryArray.append(getName(endpoint: endpointType, objectXML: endPointXML))
                                            summaryDict[endpointType]?["fail"] = summaryArray
                                        }
                                    }
                                }   // create failed - end

                                totalCreated   = counters[endpointType]?["create"] ?? 0
                                totalUpdated   = counters[endpointType]?["update"] ?? 0
                                totalFailed    = counters[endpointType]?["fail"] ?? 0
                                totalCompleted = totalCreated + totalUpdated + totalFailed
                                
                                if createRetryCount["\(localEndPointType)-\(sourceEpId)"] == 0 && totalCompleted > 0  {
    //                                print("[CreateEndpoints] counters: \(counters)")
                                    if !setting.migrateDependencies || endpointType == "policies" {
                                        putStatusUpdate2(endpoint: endpointType, total: counters[endpointType]!["total"]!)
                                    }
                                }
                                
                                if setting.fullGUI && totalCompleted == endpointCount {
    //                                migrationComplete.isDone = true

                                    if totalFailed == 0 {   // removed  && changeColor from if condition
                                        labelColor(endpoint: endpointType, theColor: greenText)
                                    } else if totalFailed == endpointCount {
                                        labelColor(endpoint: endpointType, theColor: redText)
                                        if !setting.migrateDependencies || endpointType == "policies" {
                                            PutLevelIndicator.shared.indicatorColor[endpointType] = .systemRed
                                            put_levelIndicator.fillColor = PutLevelIndicator.shared.indicatorColor[endpointType]
//                                            put_levelIndicatorFillColor[endpointType] = .systemRed
//                                            put_levelIndicator.fillColor = put_levelIndicatorFillColor[endpointType]
                                        }
                                    }
                                }
                                completion("create func: \(endpointCurrent) of \(endpointCount) complete.")
                            
                            
    //                        }   // DispatchQueue.main.async - end
                        } else {  // if let httpResponse = response - end
                            if localEndPointType != "policies" && dependency.isRunning {
                                Counter.shared.dependencyMigrated[dependencyParentId]! += 1
        //                        print("[CreateEndpoints] Counter.shared.dependencyMigrated incremented: \(Counter.shared.dependencyMigrated[dependencyParentId]!)")
                            }
                            
                            // update global counters
                            let localTmp = (counters[endpointType]?["fail"])!
                            counters[endpointType]?["fail"] = localTmp + 1
                            if var summaryArray = summaryDict[endpointType]?["fail"] {
                                summaryArray.append(getName(endpoint: endpointType, objectXML: endPointXML))
                                summaryDict[endpointType]?["fail"] = summaryArray
                            }
                            
                            totalCreated   = counters[endpointType]?["create"] ?? 0
                            totalUpdated   = counters[endpointType]?["update"] ?? 0
                            totalFailed    = counters[endpointType]?["fail"] ?? 0
                            totalCompleted = totalCreated + totalUpdated + totalFailed
                            
                            if createRetryCount["\(localEndPointType)-\(sourceEpId)"] == 0 && totalCompleted > 0  {
//                                print("[CreateEndpoints] counters: \(counters)")
                                if !setting.migrateDependencies || endpointType == "policies" {
                                    putStatusUpdate2(endpoint: endpointType, total: counters[endpointType]!["total"]!)
                                }
                            }
                            
                            if setting.fullGUI && totalCompleted == endpointCount {
//                                migrationComplete.isDone = true

                                if totalFailed == 0 {   // removed  && changeColor from if condition
                                    labelColor(endpoint: endpointType, theColor: greenText)
                                } else if totalFailed == endpointCount {
                                    labelColor(endpoint: endpointType, theColor: redText)
                                    if !setting.migrateDependencies || endpointType == "policies" {
                                        PutLevelIndicator.shared.indicatorColor[endpointType] = .systemRed
                                        put_levelIndicator.fillColor = PutLevelIndicator.shared.indicatorColor[endpointType]
//                                        put_levelIndicatorFillColor[endpointType] = .systemRed
//                                        put_levelIndicator.fillColor = put_levelIndicatorFillColor[endpointType]
                                    }
                                }
                            }
                            completion("create func: \(endpointCurrent) of \(endpointCount) complete.")
                            
                        }
                            
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[CreateEndpoints] POST or PUT Operation for \(endpointType): \(request.httpMethod)") }
                            
                            if endpointCurrent > 0 {
                                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[CreateEndpoints] endpoint: \(localEndPointType)-\(endpointCurrent)\t Total: \(endpointCount)\t Succeeded: \(POSTsuccessCount)\t Failed: \(totalFailed)\t SuccessArray \(String(describing: progressCountArray["\(localEndPointType)"]!))") }
                            }
//                            semaphore.signal()
                            if error != nil {
                            }

                            if endpointCurrent == endpointCount {
                                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[CreateEndpoints] Last item in \(localEndPointType) complete.") }
                                nodesMigrated+=1    // ;print("added node: \(localEndPointType) - createEndpoints")
            //                    print("nodes complete: \(nodesMigrated)")
                            }
                        })
                        task.resume()
//                        semaphore.wait()
                    }   // if !wipeData.on - end
                    
                }   // theCreateQ.addOperation - end
    }   // func createEndpoints - end
    
    // for the Jamf Pro API - used for buildings
    func createEndpoints2(endpointType: String, endPointJSON: [String: Any], policyDetails: [PatchPolicyDetail] = [], endpointCurrent: Int, endpointCount: Int, action: String, sourceEpId: String, destEpId: Int, ssIconName: String, ssIconId: String, ssIconUri: String, retry: Bool, completion: @escaping (_ result: String) -> Void) {
        
        if pref.stopMigration {
//                    print("[\(#function)] \(#line) stopMigration")
            stopButton(self)
            completion("stop")
            return
        }

        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[CreateEndpoints2] enter") }

        if counters[endpointType] == nil {
            counters[endpointType] = ["create":0, "update":0, "fail":0, "skipped":0, "total":0]
//            self.summaryDict[endpointType] = ["create":[], "update":[], "fail":[]]
        } else {
            counters[endpointType]!["total"] = endpointCount
        }
        if summaryDict[endpointType] == nil {
//            counters[endpointType] = ["create":0, "update":0, "fail":0, "skipped":0, "total":0]
            summaryDict[endpointType] = ["create":[], "update":[], "fail":[]]
        }
        
        var destinationEpId = destEpId
        var apiAction       = action
        print("[createEndpoints2] destinationEpId: \(destinationEpId) action: \(action)")
        
        // counterts for completed endpoints
        if endpointCurrent == 1 {
//            print("[CreateEndpoints2] reset counters")
            totalCreated   = 0
            totalUpdated   = 0
            totalFailed    = 0
            totalCompleted = 0
        }
        
        // if working a site migrations within a single server force create/POST when copying an item
        if JamfProServer.toSite && sitePref == "Copy" {
            if endpointType != "users" {
                destinationEpId = 0
                apiAction       = "create"
            }
        }
        
        
        // this is where we create the new endpoint
        if !export.saveOnly {
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[CreateEndpoints2] Creating new: \(endpointType)") }
        } else {
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[CreateEndpoints2] Save only selected, skipping \(apiAction) for: \(endpointType)") }
        }
        //if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[CreateEndpoints2] ----- Posting #\(endpointCurrent): \(endpointType) -----") }
        
        theCreateQ.maxConcurrentOperationCount = maxConcurrentThreads

        var localEndPointType = ""
        
        switch endpointType {
        case "smartcomputergroups", "staticcomputergroups":
            localEndPointType = "computergroups"
        case "smartmobiledevicegroups", "staticmobiledevicegroups":
            localEndPointType = "mobiledevicegroups"
        case "smartusergroups", "staticusergroups":
            localEndPointType = "usergroups"
        default:
            localEndPointType = endpointType
        }
                
        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[CreateEndpoints2] Original Dest. URL: \(createDestUrlBase)") }
       
        theCreateQ.addOperation { [self] in
            
            // save trimmed JSON - start
            if export.saveTrimmedXml {
                let endpointName = endPointJSON["name"] as! String   //self.getName(endpoint: endpointType, objectXML: endPointJSON)
                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[CreateEndpoints2] Saving trimmed JSON for \(endpointName) with id: \(sourceEpId).") }
                DispatchQueue.main.async {
                    let exportTrimmedJson = (export.trimmedXmlScope) ? self.rmJsonData(rawJSON: endPointJSON, theTag: ""):self.rmJsonData(rawJSON: endPointJSON, theTag: "scope")
//                    print("exportTrimmedJson: \(exportTrimmedJson)")
                    WriteToLog.shared.message(stringOfText: "[CreateEndpoints2] Exporting raw JSON for \(endpointType) - \(endpointName)")
                    self.exportItems(node: endpointType, objectString: exportTrimmedJson, rawName: endpointName, id: "\(sourceEpId)", format: "trimmed")
//                    SaveDelegate().exportObject(node: endpointType, objectString: exportTrimmedJson, rawName: endpointName, id: "\(sourceEpId)", format: "trimmed")
                }
                
            }
            // save trimmed JSON - end
            
            if export.saveOnly {
                if self.objectsToMigrate.last == localEndPointType && endpointCount == endpointCurrent {
                    //self.go_button.isEnabled = true
                    self.rmDELETE()
//                    self.resetAllCheckboxes()
                    print("[\(#function)] \(#line) - finished creating \(endpointType)")
                    self.goButtonEnabled(button_status: true)
                }
                return
            }
            
            // don't create object if we're removing objects
            if !wipeData.on {
                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[CreateEndpoints2] Action: \(apiAction)\t URL: \(createDestUrlBase)\t Object \(endpointCurrent) of \(endpointCount)") }
                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[CreateEndpoints2] Object JSON: \(endPointJSON)") }
    //            print("[CreateEndpoints2] [\(localEndPointType)] process start: \(self.getName(endpoint: endpointType, objectXML: endPointXML))")
                
                if endpointCurrent == 1 {
                    if !retry {
                        Counter.shared.post = 1
                    }
                } else {
                    if !retry {
                        Counter.shared.post += 1
                    }
                }
                
                if endpointType == "patchmanagement" {
                    PatchManagementApi.shared.createUpdate(serverUrl: createDestUrlBase.replacingOccurrences(of: "/JSSResource", with: ""), endpoint: endpointType, apiData: endPointJSON, sourceEpId: sourceEpId, destEpId: "\(destinationEpId)", token: JamfProServer.authCreds["dest"] ?? "", method: apiAction) { [self]
                        (jpapiResonse: [String:Any]) in
    //                    print("[CreateEndpoints2] returned from Jpapi.action, jpapiResonse: \(jpapiResonse)")
                        var jpapiResult = "succeeded"
                        if let _ = jpapiResonse["JPAPI_result"] as? String {
                            jpapiResult = jpapiResonse["JPAPI_result"] as! String
                        }
    //                    if let httpResponse = response as? HTTPURLResponse {
                        var apiMethod = apiAction
                        if apiAction.lowercased() == "skip" || jpapiResult != "succeeded" {
                            apiMethod = "fail"
                            DispatchQueue.main.async {
                                if setting.fullGUI && apiAction.lowercased() != "skip" {
                                    self.labelColor(endpoint: endpointType, theColor: self.yellowText)
                                    if !setting.migrateDependencies || endpointType == "policies" {
                                        self.setLevelIndicatorFillColor(fn: "CreateEndpoints2-\(endpointCurrent)", endpointType: endpointType, fillColor: .systemYellow)
                                    }
                                }
                            }
                            WriteToLog.shared.message(stringOfText: "    [CreateEndpoints2] [\(localEndPointType)]    failed: \(endPointJSON["name"] ?? "unknown")")
                        } else {
                            WriteToLog.shared.message(stringOfText: "    [CreateEndpoints2] [\(localEndPointType)] succeeded: \(endPointJSON["name"] ?? "unknown")")
                            
                            if endpointCurrent == 1 && !retry {
                                migrationComplete.isDone = false
                                if !setting.migrateDependencies || endpointType == "policies" {
                                    self.setLevelIndicatorFillColor(fn: "CreateEndpoints2-\(endpointCurrent)", endpointType: endpointType, fillColor: .green)
                                }
                            } else if !retry {
                                if let _ = PutLevelIndicator.shared.indicatorColor[endpointType] /*self.put_levelIndicatorFillColor[endpointType]*/ {
                                    self.setLevelIndicatorFillColor(fn: "CreateEndpoints-\(endpointCurrent)", endpointType: endpointType, fillColor: PutLevelIndicator.shared.indicatorColor[endpointType] ?? .green)
                                }
                            }
                        }
                        
                            // look to see if we are processing the next endpointType - start
                            if self.endpointInProgress != endpointType || self.endpointInProgress == "" {
                                WriteToLog.shared.message(stringOfText: "[CreateEndpoints2] Migrating \(endpointType)")
                                self.endpointInProgress = endpointType
                                self.POSTsuccessCount = 0
                            }   // look to see if we are processing the next localEndPointType - end
                            
    //                    DispatchQueue.main.async { [self] in
                            
                                // ? remove creation of counters dict defined earlier ?
                                if counters[endpointType] == nil {
                                    counters[endpointType] = ["create":0, "update":0, "fail":0, "skipped":0, "total":0]
                                    summaryDict[endpointType] = ["create":[], "update":[], "fail":[]]
                                }
                            
                                                            
                                POSTsuccessCount += 1
                                
    //                            print("endpointType: \(endpointType)")
    //                            print("progressCountArray: \(String(describing: self.progressCountArray["\(endpointType)"]))")
                                
                                if let _ = progressCountArray["\(endpointType)"] {
                                    progressCountArray["\(endpointType)"] = self.progressCountArray["\(endpointType)"]!+1
                                }
                                
                                let localTmp = (counters[endpointType]?["\(apiMethod)"])!
        //                        print("localTmp: \(localTmp)")
                                counters[endpointType]?["\(apiMethod)"] = localTmp + 1
                                
                                
                                if var summaryArray = summaryDict[endpointType]?["\(apiMethod)"] {
                                    summaryArray.append("\(endPointJSON["name"] ?? "unknown")")
                                    summaryDict[endpointType]?["\(apiMethod)"] = summaryArray
                                }
                                /*
                                // currently there is no way to upload mac app store icons; no api endpoint
                                // removed check for those -  || (endpointType == "macapplications")
                                if ((endpointType == "policies") || (endpointType == "mobiledeviceapplications")) && (action == "create") {
                                    sourcePolicyId = (endpointType == "policies") ? "\(sourceEpId)":""
                                    self.icons(endpointType: endpointType, action: action, ssIconName: ssIconName, ssIconId: ssIconId, ssIconUri: ssIconUri, f_createDestUrl: createDestUrl, responseData: responseData, sourcePolicyId: sourcePolicyId)
                                }
                                */

                                totalCreated   = counters[endpointType]?["create"] ?? 0
                                totalUpdated   = counters[endpointType]?["update"] ?? 0
                                totalFailed    = counters[endpointType]?["fail"] ?? 0
                                totalCompleted = totalCreated + totalUpdated + totalFailed
                                
                                // update counters
                                if totalCompleted > 0 {
                                    if !setting.migrateDependencies || endpointType == "policies" {
                                        putStatusUpdate2(endpoint: endpointType, total: counters[endpointType]!["total"]!)
                                    }
                                }
                                
                                if setting.fullGUI && totalCompleted == endpointCount {

                                    if totalFailed == 0 {   // removed  && self.changeColor from if condition
                                        labelColor(endpoint: endpointType, theColor: self.greenText)
                                    } else if totalFailed == endpointCount {
                                        DispatchQueue.main.async {
                                            self.labelColor(endpoint: endpointType, theColor: self.redText)
                                            
                                            if !setting.migrateDependencies || endpointType == "policies" {
                                                PutLevelIndicator.shared.indicatorColor[endpointType] = .systemRed
                                                self.put_levelIndicator.fillColor = PutLevelIndicator.shared.indicatorColor[endpointType]
    //                                                    self.put_levelIndicatorFillColor[endpointType] = .systemRed
    //                                                    self.put_levelIndicator.fillColor = self.put_levelIndicatorFillColor[endpointType]
                                            }
                                        }
                                        
                                    }
                                }
    //                        }   // DispatchQueue.main.async - end
                            completion("create func: \(endpointCurrent) of \(endpointCount) complete.")
    //                    }   // if let httpResponse = response - end
                        
                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[CreateEndpoints2] POST, PUT, or skip - operation: \(apiAction)") }
                        
                        if endpointCurrent > 0 {
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[CreateEndpoints2] endpoint: \(localEndPointType)-\(endpointCurrent)\t Total: \(endpointCount)\t Succeeded: \(self.POSTsuccessCount)\t Failed: \(totalFailed)\t SuccessArray \(String(describing: self.progressCountArray["\(localEndPointType)"]!))") }
                        }
                        
                        if localEndPointType != "policies" && dependency.isRunning {
                            Counter.shared.dependencyMigrated[dependencyParentId]! += 1
    //                        print("[CreateEndpoints2] Counter.shared.dependencyMigrated incremented: \(Counter.shared.dependencyMigrated[dependencyParentId]!)")
                        }

        //                print("create func: \(endpointCurrent) of \(endpointCount) complete.  \(self.nodesMigrated) nodes migrated.")
                        if endpointCurrent == endpointCount {
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[CreateEndpoints2] Last item in \(localEndPointType) complete.") }
                            self.nodesMigrated+=1
                            // print("added node: \(localEndPointType) - createEndpoints")
        //                    print("nodes complete: \(self.nodesMigrated)")
                        }
                    }
                } else {
                    Jpapi.shared.action(whichServer: "dest", endpoint: endpointType, apiData: endPointJSON, id: "\(destinationEpId)", token: JamfProServer.authCreds["dest"] ?? "", method: apiAction) { [self]
                        (jpapiResonse: [String:Any]) in
    //                    print("[CreateEndpoints2] returned from Jpapi.action, jpapiResonse: \(jpapiResonse)")
                        var jpapiResult = "succeeded"
                        if let _ = jpapiResonse["JPAPI_result"] as? String {
                            jpapiResult = jpapiResonse["JPAPI_result"] as! String
                        }
    //                    if let httpResponse = response as? HTTPURLResponse {
                        var apiMethod = apiAction
                        if apiAction.lowercased() == "skip" || jpapiResult != "succeeded" {
                            apiMethod = "fail"
                            DispatchQueue.main.async {
                                if setting.fullGUI && apiAction.lowercased() != "skip" {
                                    self.labelColor(endpoint: endpointType, theColor: self.yellowText)
                                    if !setting.migrateDependencies || endpointType == "policies" {
                                        self.setLevelIndicatorFillColor(fn: "CreateEndpoints2-\(endpointCurrent)", endpointType: endpointType, fillColor: .systemYellow)
                                    }
                                }
                            }
                            WriteToLog.shared.message(stringOfText: "    [CreateEndpoints2] [\(localEndPointType)]    failed: \(endPointJSON["name"] ?? "unknown")")
                        } else {
                            WriteToLog.shared.message(stringOfText: "    [CreateEndpoints2] [\(localEndPointType)] succeeded: \(endPointJSON["name"] ?? "unknown")")
                            
                            if endpointCurrent == 1 && !retry {
                                migrationComplete.isDone = false
                                if !setting.migrateDependencies || endpointType == "policies" {
                                    self.setLevelIndicatorFillColor(fn: "CreateEndpoints2-\(endpointCurrent)", endpointType: endpointType, fillColor: .green)
                                }
                            } else if !retry {
                                if let _ = PutLevelIndicator.shared.indicatorColor[endpointType] /*self.put_levelIndicatorFillColor[endpointType]*/ {
                                    self.setLevelIndicatorFillColor(fn: "CreateEndpoints-\(endpointCurrent)", endpointType: endpointType, fillColor: PutLevelIndicator.shared.indicatorColor[endpointType] ?? .green)
                                }
                            }
                        }
                        
                        
                            /*
                            if let _ = String(data: data!, encoding: .utf8) {
                                responseData = String(data: data!, encoding: .utf8)!
        //                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[CreateEndpoints2] \n\nfull response from create:\n\(responseData)") }
        //                        print("create data response: \(responseData)")
                            } else {
                                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "\n\n[CreateEndpoints2] No data was returned from post/put.") }
                            }
                            */
                            // look to see if we are processing the next endpointType - start
                            if self.endpointInProgress != endpointType || self.endpointInProgress == "" {
                                WriteToLog.shared.message(stringOfText: "[CreateEndpoints2] Migrating \(endpointType)")
                                self.endpointInProgress = endpointType
                                self.POSTsuccessCount = 0
                            }   // look to see if we are processing the next localEndPointType - end
                            
    //                    DispatchQueue.main.async { [self] in
                            
                                // ? remove creation of counters dict defined earlier ?
                                if counters[endpointType] == nil {
                                    counters[endpointType] = ["create":0, "update":0, "fail":0, "skipped":0, "total":0]
                                    summaryDict[endpointType] = ["create":[], "update":[], "fail":[]]
                                }
                            
                                                            
                                POSTsuccessCount += 1
                                
    //                            print("endpointType: \(endpointType)")
    //                            print("progressCountArray: \(String(describing: self.progressCountArray["\(endpointType)"]))")
                                
                                if let _ = progressCountArray["\(endpointType)"] {
                                    progressCountArray["\(endpointType)"] = self.progressCountArray["\(endpointType)"]!+1
                                }
                                
                                let localTmp = (counters[endpointType]?["\(apiMethod)"])!
        //                        print("localTmp: \(localTmp)")
                                counters[endpointType]?["\(apiMethod)"] = localTmp + 1
                                
                                
                                if var summaryArray = summaryDict[endpointType]?["\(apiMethod)"] {
                                    summaryArray.append("\(endPointJSON["name"] ?? "unknown")")
                                    summaryDict[endpointType]?["\(apiMethod)"] = summaryArray
                                }
                                /*
                                // currently there is no way to upload mac app store icons; no api endpoint
                                // removed check for those -  || (endpointType == "macapplications")
                                if ((endpointType == "policies") || (endpointType == "mobiledeviceapplications")) && (action == "create") {
                                    sourcePolicyId = (endpointType == "policies") ? "\(sourceEpId)":""
                                    self.icons(endpointType: endpointType, action: action, ssIconName: ssIconName, ssIconId: ssIconId, ssIconUri: ssIconUri, f_createDestUrl: createDestUrl, responseData: responseData, sourcePolicyId: sourcePolicyId)
                                }
                                */

                                totalCreated   = counters[endpointType]?["create"] ?? 0
                                totalUpdated   = counters[endpointType]?["update"] ?? 0
                                totalFailed    = counters[endpointType]?["fail"] ?? 0
                                totalCompleted = totalCreated + totalUpdated + totalFailed
                                
                                // update counters
                                if totalCompleted > 0 {
                                    if !setting.migrateDependencies || endpointType == "policies" {
                                        putStatusUpdate2(endpoint: endpointType, total: counters[endpointType]!["total"]!)
                                    }
                                }
                                
                                if setting.fullGUI && totalCompleted == endpointCount {

                                    if totalFailed == 0 {   // removed  && self.changeColor from if condition
                                        labelColor(endpoint: endpointType, theColor: self.greenText)
                                    } else if totalFailed == endpointCount {
                                        DispatchQueue.main.async {
                                            self.labelColor(endpoint: endpointType, theColor: self.redText)
                                            
                                            if !setting.migrateDependencies || endpointType == "policies" {
                                                PutLevelIndicator.shared.indicatorColor[endpointType] = .systemRed
                                                self.put_levelIndicator.fillColor = PutLevelIndicator.shared.indicatorColor[endpointType]
    //                                                    self.put_levelIndicatorFillColor[endpointType] = .systemRed
    //                                                    self.put_levelIndicator.fillColor = self.put_levelIndicatorFillColor[endpointType]
                                            }
                                        }
                                        
                                    }
                                }
    //                        }   // DispatchQueue.main.async - end
                            completion("create func: \(endpointCurrent) of \(endpointCount) complete.")
    //                    }   // if let httpResponse = response - end
                        
                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[CreateEndpoints2] POST, PUT, or skip - operation: \(apiAction)") }
                        
                        if endpointCurrent > 0 {
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[CreateEndpoints2] endpoint: \(localEndPointType)-\(endpointCurrent)\t Total: \(endpointCount)\t Succeeded: \(self.POSTsuccessCount)\t Failed: \(totalFailed)\t SuccessArray \(String(describing: self.progressCountArray["\(localEndPointType)"]!))") }
                        }
                        
                        if localEndPointType != "policies" && dependency.isRunning {
                            Counter.shared.dependencyMigrated[dependencyParentId]! += 1
    //                        print("[CreateEndpoints2] Counter.shared.dependencyMigrated incremented: \(Counter.shared.dependencyMigrated[dependencyParentId]!)")
                        }

        //                print("create func: \(endpointCurrent) of \(endpointCount) complete.  \(self.nodesMigrated) nodes migrated.")
                        if endpointCurrent == endpointCount {
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[CreateEndpoints2] Last item in \(localEndPointType) complete.") }
                            self.nodesMigrated+=1
                            // print("added node: \(localEndPointType) - createEndpoints")
        //                    print("nodes complete: \(self.nodesMigrated)")
                        }
                    }
                }
                
                
                
            }   // if !wipeData.on - end
        }   // theCreateQ.addOperation - end
    }
    
    
    func removeEndpointsQueue(endpointType: String, endPointID: String, endpointName: String, endpointCurrent: Int, endpointCount: Int) {

        if endpointCurrent == 1 {
            counters[endpointType]!["total"] = endpointCount
        }
        
        removeMeterQ.maxConcurrentOperationCount = 3
        let semaphore = DispatchSemaphore(value: 0)
        
        removeMeterQ.addOperation { [self] in
            lockQueue.async { [self] in
                print("[removeEndpointQueue] add \(endpointType) with id \(endPointID) to removeArray")
                removeArray.append(ObjectInfo(endpointType: endpointType, endPointXml: endpointName, endPointJSON: [:], endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: "", sourceEpId: -1, destEpId: Int(endPointID)!, ssIconName: "", ssIconId: "", ssIconUri: "", retry: false))
                print("[removeEndpointQueue] added \(endpointType) with id \(endPointID) to removeArray, removeArray.count: \(removeArray.count)")
            }
            var breakQueue = false
            lockQueue.async { [self] in
                while removeArray.count > 0 {
                    print("[removeEndpointsQueue] 1 Counter.shared.pendingSend: \(Counter.shared.pendingSend), removeArray.count: \(removeArray.count)")
                    if Counter.shared.pendingSend < maxConcurrentThreads /*&& removeArray.count > 0*/ {
                        Counter.shared.pendingSend += 1
//                        updatePendingCounter(caller: #function.short, change: 1)
                        usleep(10)
                        let nextEndpoint = removeArray.remove(at: 0)
                        
                        print("[removeEndpointsQueue] call removeEndpoints to removed id: \(nextEndpoint.destEpId)")
                        removeEndpoints(endpointType: nextEndpoint.endpointType, endPointID: "\(nextEndpoint.destEpId)", endpointName: nextEndpoint.endPointXml, endpointCurrent: nextEndpoint.endpointCurrent, endpointCount: nextEndpoint.endpointCount) { [self]
                            (result: String) in
                            
                            if result == "-1" {
                                breakQueue = true
                            } else {
                                Counter.shared.pendingSend -= 1
//                                updatePendingCounter(caller: #function.short, change: -1)
                                print("[removeEndpointsQueue] removed id: \(result)")
                            }
                            semaphore.signal()
                        }
                    } else {
                        print("[removeEndpointsQueue] 2 Counter.shared.pendingSend: \(Counter.shared.pendingSend), removeArray.count: \(removeArray.count)")
                        sleep(1)
                        if Counter.shared.pendingSend == 0 && removeArray.count == 0 && breakQueue { break }
                    }
                    semaphore.wait()
                }   // while Counter.shared.pendingSend > 0 || removeArray.count > 0
            }
        }
    }
    
    func removeEndpoints(endpointType: String, endPointID: String, endpointName: String, endpointCurrent: Int, endpointCount: Int, completion: @escaping (_ result: String) -> Void) {
        
        if endPointID == "-1" && activeTab(fn: "RemoveEndpoints") == "selective" {
            print("[removeEndpoints] selective - finished removing \(endpointType)")
            completion("-1")
            return
        }

        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[RemoveEndpoints] enter") }

        var removeDestUrl = ""
                
        if endpointCurrent == 1 {
            if !setting.migrateDependencies || endpointType == "policies" {
                setLevelIndicatorFillColor(fn: "RemoveEndpoints-\(endpointCurrent), line: \(#line)", endpointType: endpointType, fillColor: .green)
            }
        } else {
//            putStatusLockQueue.async {
                if let _ = PutLevelIndicator.shared.indicatorColor[endpointType] /* self.put_levelIndicatorFillColor[endpointType] */{
                    if setting.migrateDependencies {
                        self.setLevelIndicatorFillColor(fn: "RemoveEndpoints-\(endpointCurrent), line: \(#line)", endpointType: endpointType, fillColor: PutLevelIndicator.shared.indicatorColor[endpointType] ?? .green /* self.put_levelIndicatorFillColor[endpointType]!*/)
                    }
                }
//            }
        }
        
        // whether the operation was successful or not, either delete or fail
        var methodResult = "create"
        
        // counters for completed objects
        var totalDeleted   = 0
        var totalFailed    = 0
        var totalCompleted = 0
        
        removeEPQ.maxConcurrentOperationCount = maxConcurrentThreads
        
//        let semaphore = DispatchSemaphore(value: 0)
        var localEndPointType = ""
        switch endpointType {
        case "smartcomputergroups", "staticcomputergroups":
            localEndPointType = "computergroups"
        case "smartmobiledevicegroups", "staticmobiledevicegroups":
            localEndPointType = "mobiledevicegroups"
        case "smartusergroups", "staticusergroups":
            localEndPointType = "usergroups"
        default:
            localEndPointType = endpointType
        }

        if endpointName != "All Managed Clients" && endpointName != "All Managed Servers" && endpointName != "All Managed iPads" && endpointName != "All Managed iPhones" && endpointName != "All Managed iPod touches" {
            
            removeDestUrl = "\(JamfProServer.destination)/JSSResource/" + localEndPointType + "/id/\(endPointID)"
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "\n[RemoveEndpoints] [CreateEndpoints] raw removal URL: \(removeDestUrl)") }
            removeDestUrl = removeDestUrl.urlFix
//            removeDestUrl = removeDestUrl.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
            removeDestUrl = removeDestUrl.replacingOccurrences(of: "/JSSResource/jamfusers/id", with: "/JSSResource/accounts/userid")
            removeDestUrl = removeDestUrl.replacingOccurrences(of: "/JSSResource/jamfgroups/id", with: "/JSSResource/accounts/groupid")
            removeDestUrl = removeDestUrl.replacingOccurrences(of: "id/id/", with: "id/")
            
            if export.saveRawXml {
                //change to endpointByIDQueue?
                endPointByID(endpoint: endpointType, endpointID: "\(endPointID)", endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: "", destEpId: 0, destEpName: endpointName) {
                    (result: String) in
                }
            }
            if export.saveOnly {
                if endpointCurrent == endpointCount {
                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[removeEndpoints] Last item in \(localEndPointType) complete.") }
                    nodesMigrated+=1    // ;print("added node: \(localEndPointType) - removeEndpoints")
                    //            print("remove nodes complete: \(nodesMigrated)")
                }
                return
            }
            
            removeEPQ.addOperation {
                        
                DispatchQueue.main.async { [self] in
                    // look to see if we are processing the next endpointType - start
                    if self.endpointInProgress != endpointType || self.endpointInProgress == "" {
                        endpointInProgress = endpointType
                        changeColor = true
                        POSTsuccessCount = 0
                        WriteToLog.shared.message(stringOfText: "[RemoveEndpoints] Removing \(endpointType)")
                    }   // look to see if we are processing the next endpointType - end
                }
                
                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[RemoveEndpoints] removing \(endpointType) with ID \(endPointID)  -  Object \(endpointCurrent) of \(endpointCount)") }
                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[RemoveEndpoints] removal URL: \(removeDestUrl)") }
                
                let encodedURL = URL(string: removeDestUrl)
                let request = NSMutableURLRequest(url: encodedURL! as URL)
                request.httpMethod = "DELETE"
                let configuration = URLSessionConfiguration.ephemeral
                
                configuration.httpAdditionalHeaders = ["Authorization" : "\(JamfProServer.authType["dest"] ?? "Bearer") \(JamfProServer.authCreds["dest"] ?? "")", "Content-Type" : "text/xml", "Accept" : "text/xml", "User-Agent" : AppInfo.userAgentHeader]
                
                let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
                let task = session.dataTask(with: request as URLRequest, completionHandler: { [self]
                    (data, response, error) -> Void in
                    session.finishTasksAndInvalidate()
                    
                    completion("\(endPointID)")
                    
                    print("[RemoveEndpoints] \(#line) removeEPQ.operationCount: \(removeEPQ.operationCount)")
                    if let httpResponse = response as? HTTPURLResponse {
                        print("[RemoveEndpoints] \(#line) removed response code: \(httpResponse.statusCode)")
                        //print(httpResponse)
                        if httpResponse.statusCode >= 199 && httpResponse.statusCode <= 299 {
                            // remove items from the list as they are removed from the server
                            if activeTab(fn: "RemoveEndpoints") == "selective" {
                                //                                print("endPointID: \(endPointID)")
                                let lineNumber = (sourceObjectList_AC.arrangedObjects as! [SelectiveObject]).firstIndex(where: {$0.objectId == endPointID})!
                                let objectToRemove = (sourceObjectList_AC.arrangedObjects as! [SelectiveObject])[lineNumber].objectName
                                
//                                        print("[removeEndpoints] staticSourceDataArray:\(staticSourceDataArray)")
                                let staticLineNumber = ( endpointType == "policies" ) ? staticSourceDataArray.firstIndex(of: "\(objectToRemove) (\(endPointID))")!:staticSourceDataArray.firstIndex(of: objectToRemove)!
                                staticSourceDataArray.remove(at: staticLineNumber)
                                
                                DispatchQueue.main.async { [self] in
                                    
                                    var objectIndex = (self.sourceObjectList_AC.arrangedObjects as! [SelectiveObject]).firstIndex(where: { $0.objectName == objectToRemove })
                                    sourceObjectList_AC.remove(atArrangedObjectIndex: objectIndex!)
                                    objectIndex = self.staticSourceObjectList.firstIndex(where: { $0.objectId == endPointID })
                                    staticSourceObjectList.remove(at: objectIndex!)
                                    
                                    srcSrvTableView.isEnabled = false
                                }
                            }
                            
                            WriteToLog.shared.message(stringOfText: "    [RemoveEndpoints] [\(endpointType)] \(endpointName) (id: \(endPointID))")
                            POSTsuccessCount += 1
                        } else {
                            methodResult = "fail"
                            labelColor(endpoint: endpointType, theColor: self.yellowText)
                            if !setting.migrateDependencies || endpointType == "policies" {
                                PutLevelIndicator.shared.indicatorColor[endpointType]  = .systemYellow
                                put_levelIndicator.fillColor = PutLevelIndicator.shared.indicatorColor[endpointType]
//                                put_levelIndicatorFillColor[endpointType] = .systemYellow
//                                put_levelIndicator.fillColor = self.put_levelIndicatorFillColor[endpointType]
                            }
                            changeColor = false
                            WriteToLog.shared.message(stringOfText: "    [RemoveEndpoints] [\(endpointType)] **** Failed to remove: \(endpointName) (id: \(endPointID)), statusCode: \(httpResponse.statusCode)")
                            
                            if httpResponse.statusCode == 400 {
                                WriteToLog.shared.message(stringOfText: "    [RemoveEndpoints] [\(endpointType)]      Verify other items are not dependent on \(endpointName) (id: \(endPointID))")
                                WriteToLog.shared.message(stringOfText: "    [RemoveEndpoints] [\(endpointType)]      For example, \(endpointName) is not used in a policy")
                            }
                            
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "\n") }
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[RemoveEndpoints] ---------- endpoint info ----------") }
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[RemoveEndpoints] Type: \(endpointType)\t Name: \(endpointName)\t id: \(endPointID)") }
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[RemoveEndpoints] ---------- status code ----------") }
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[RemoveEndpoints] \(httpResponse.statusCode)") }
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[RemoveEndpoints] ---------- response ----------") }
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[RemoveEndpoints] \(httpResponse)") }
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[RemoveEndpoints] ---------- response ----------\n") }
                        }
                        
                        // update global counters
                        let localTmp = (self.counters[endpointType]?[methodResult])!
                        counters[endpointType]?[methodResult] = localTmp + 1
                        if var summaryArray = self.summaryDict[endpointType]?[methodResult] {
                            summaryArray.append(endpointName)
                            summaryDict[endpointType]?[methodResult] = summaryArray
                        }
                        
                        totalDeleted   = self.counters[endpointType]?["create"] ?? 0
                        totalFailed    = self.counters[endpointType]?["fail"] ?? 0
                        totalCompleted = totalDeleted + totalFailed
                        
                        putStatusLockQueue.async { [self] in
//                        DispatchQueue.main.async { [self] in
                            if totalCompleted > 0 {
                                print("[\(#function)] total: \(self.counters[endpointType]!["total"]!)")
                                putStatusUpdate2(endpoint: endpointType, total: self.counters[endpointType]!["total"]!)
                            }
                            
                            if totalDeleted == endpointCount && changeColor {
                                labelColor(endpoint: endpointType, theColor: greenText)
                            } else if totalFailed == endpointCount {
                                labelColor(endpoint: endpointType, theColor: redText)
                                setLevelIndicatorFillColor(fn: "RemoveEndpoints-\(endpointCurrent)", endpointType: endpointType, fillColor: .systemRed)
                            }
                        }
                    }
                    
                    if activeTab(fn: "RemoveEndpoints") != "selective" {
                        //                        print("localEndPointType: \(localEndPointType) \t count: \(endpointCount)")
                        if objectsToMigrate.last == localEndPointType && endPointID == "-1" /*(endpointCount == endpointCurrent || endpointCount == 0)*/ {
                            // check for file that allows deleting data from destination server, delete if found - start
                            rmDELETE()
                            JamfProServer.validToken["source"] = false
                            JamfProServer.version["source"]    = ""
                            //                            print("[removeEndpoints] endpoint: \(endpointType)")
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[removeEndpoints] endpoint: \(endpointType)") }
                            //                            self.resetAllCheckboxes()
                            // check for file that allows deleting data from destination server, delete if found - end
                            print("[\(#function)] bulk - finished removing \(endpointType)")
                            goButtonEnabled(button_status: true)
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "Done") }
                        }
                        if error != nil {
                        }
                    } else {
                        // selective
                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[removeEndpoints] endpointCount: \(endpointCount)\t endpointCurrent: \(endpointCurrent)") }
                        
                        if endpointCount == endpointCurrent {
                            // check for file that allows deleting data from destination server, delete if found - start
                            rmDELETE()
                            JamfProServer.validToken["source"] = false
                            JamfProServer.version["source"]    = ""
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[removeEndpoints] endpoint: \(endpointType)") }
                            //                            print("[removeEndpoints] endpoint: \(endpointType)")
                            //                            self.resetAllCheckboxes()
                            // check for file that allows deleting data from destination server, delete if found - end
                            //self.go_button.isEnabled = true
                            print("[\(#function)] \(#line) selective - finished removing \(endpointType)")
                            goButtonEnabled(button_status: true)
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "Done") }
                        }
                    }
                    if endpointCurrent == endpointCount {
                        WriteToLog.shared.message(stringOfText: "[removeEndpoints] Last item in \(localEndPointType) complete.")
                        nodesMigrated += 1
                        //            print("remove nodes complete: \(nodesMigrated)")
                    }
                })  // let task = session.dataTask - end
                task.resume()
            }   // removeEPQ.addOperation - end
        }
        // moved 241026
//        if endpointCurrent == endpointCount {
//            WriteToLog.shared.message(stringOfText: "[removeEndpoints] Last item in \(localEndPointType) complete.")
//            nodesMigrated += 1
//            //            print("remove nodes complete: \(nodesMigrated)")
//        }
    }   // func removeEndpoints - end
    
    func existingEndpoints(skipLookup: Bool, theDestEndpoint: String, completion: @escaping (_ result: (String,String)) -> Void) {
        // query destination server
        if skipLookup {
            completion(("skipping lookup","skipping lookup"))
            return
        }
        if pref.stopMigration {
//            print("[\(#function)] \(#line) stopMigration")
            stopButton(self)
            completion(("",""))
            return
        }
                
                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[existingEndpoints] enter - destination endpoint: \(theDestEndpoint)") }
                
                if pref.stopMigration {
//                    print("[\(#function)] \(#line) stopMigration")
                    stopButton(self)
                    completion(("",""))
                    return
                }
                
                if !export.saveOnly {
                    URLCache.shared.removeAllCachedResponses()
                    currentEPs.removeAll()
                    currentEPDict.removeAll()
                    
                    var destEndpoint         = theDestEndpoint
                    var existingDestUrl      = "\(JamfProServer.destination)"
                    var destXmlName          = ""
                    var destXmlID:Int?
                    var existingEndpointNode = ""
                    var een                  = ""
                    
        //            var duplicatePackages      = false
        //            var duplicatePackagesDict  = [String:[String]]()
                    
                    if self.counters[destEndpoint] == nil {
                        self.counters[destEndpoint] = ["create":0, "update":0, "fail":0, "skipped":0, "total":0]
                        self.summaryDict[destEndpoint] = ["create":[], "update":[], "fail":[]]
                    }

                    switch destEndpoint {
                    case "smartusergroups", "staticusergroups":
                        destEndpoint = "usergroups"
                        existingEndpointNode = "usergroups"
                    case "smartcomputergroups", "staticcomputergroups":
                        destEndpoint = "computergroups"
                        existingEndpointNode = "computergroups"
                    case "smartmobiledevicegroups", "staticmobiledevicegroups":
                        destEndpoint = "mobiledevicegroups"
                        existingEndpointNode = "mobiledevicegroups"
                    case "jamfusers", "jamfgroups":
                        existingEndpointNode = "accounts"
                    case "patchmanagement":
                        existingEndpointNode = "patch-software-title-configurations"
                    default:
                        existingEndpointNode = destEndpoint
                    }
                    
            //        print("\nGetting existing endpoints: \(existingEndpointNode)")
                    var destEndpointDict:(Any)? = nil
                    var endpointParent = ""
                    switch destEndpoint {
                    // macOS items
                    case "advancedcomputersearches":
                        endpointParent = "advanced_computer_searches"
                    case "macapplications":
                        endpointParent = "mac_applications"
                    case "computerextensionattributes":
                        endpointParent = "computer_extension_attributes"
                    case "computergroups":
                        endpointParent = "computer_groups"
        //            case "computerconfigurations":
        //                endpointParent = "computer_configurations"
                    case "diskencryptionconfigurations":
                        endpointParent = "disk_encryption_configurations"
                    case "distributionpoints":
                        endpointParent = "distribution_points"
                    case "directorybindings":
                        endpointParent = "directory_bindings"
                    case "dockitems":
                        endpointParent = "dock_items"
        //            case "netbootservers":
        //                endpointParent = "netboot_servers"
                    case "osxconfigurationprofiles":
                        endpointParent = "os_x_configuration_profiles"
                    case "patches":
                        endpointParent = "patch_management_software_titles"
                    case "patchpolicies":
                        endpointParent = "patch_policies"
                    case "restrictedsoftware":
                        endpointParent = "restricted_software"
                    case "softwareupdateservers":
                        endpointParent = "software_update_servers"
                    // iOS items
                    case "advancedmobiledevicesearches":
                        endpointParent = "advanced_mobile_device_searches"
                    case "mobiledeviceconfigurationprofiles":
                        endpointParent = "configuration_profiles"
                    case "mobiledeviceextensionattributes":
                        endpointParent = "mobile_device_extension_attributes"
                    case "mobiledevicegroups":
                        endpointParent = "mobile_device_groups"
                    case "mobiledeviceapplications":
                        endpointParent = "mobile_device_applications"
                    case "mobiledevices":
                        endpointParent = "mobile_devices"
                    // general items
                    case "advancedusersearches":
                        endpointParent = "advanced_user_searches"
                    case "ldapservers":
                        endpointParent = "ldap_servers"
                    case "networksegments":
                        endpointParent = "network_segments"
                    case "userextensionattributes":
                        endpointParent = "user_extension_attributes"
                    case "usergroups":
                        endpointParent = "user_groups"
                    case "jamfusers", "jamfgroups":
                        endpointParent = "accounts"
                    default:
                        endpointParent = "\(destEndpoint)"
                    }
                    
                    var endpointDependencyArray = ordered_dependency_array
//                    var waiting                 = false
                    ExistingEndpoints.shared.waiting   = false
                    ExistingEndpoints.shared.completed = 0
//                    updateExistingCounter(change: -existingEpCompleted)
                    
                    /*
                    switch endpointParent {
                    case "policies":
                        endpointDependencyArray.append(existingEndpointNode)
                    default:
                        endpointDependencyArray = ["\(existingEndpointNode)"]
                    }
                    */
                    
                    if self.activeTab(fn: "existingEndpoints") == "selective" && endpointParent == "policies" && setting.migrateDependencies && goSender == "goButton" {
                        endpointDependencyArray.append(existingEndpointNode)
                    } else {
                        endpointDependencyArray = ["\(existingEndpointNode)"]
                    }
                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[existingEndpoints] endpointDependencyArray: \(endpointDependencyArray)") }
                    
        //            print("                    completed: \(completed)")
        //            print("endpointDependencyArray.count: \(endpointDependencyArray.count)")
        //            print("                      waiting: \(waiting)")
                    
                    let semaphore = DispatchSemaphore(value: 1)
                    destEPQ.async { [self] in
                        while (ExistingEndpoints.shared.completed < endpointDependencyArray.count) {
                            
                            if !ExistingEndpoints.shared.waiting && (ExistingEndpoints.shared.completed < endpointDependencyArray.count) {
                                
                                URLCache.shared.removeAllCachedResponses()
                                ExistingEndpoints.shared.waiting = true
                                
                                existingEndpointNode = endpointDependencyArray[ExistingEndpoints.shared.completed]   // endpoint to look up
                                                                    
                                switch existingEndpointNode {
                                case "patch-software-title-configurations":
                                    existingDestUrl = existingDestUrl.appending("/api/v2/\(existingEndpointNode)").urlFix
                                default:
                                    existingDestUrl = existingDestUrl.appending("/JSSResource/\(existingEndpointNode)").urlFix
                                }
                                
                                print("[\(#function)] \(#line) - existingDestUrl: \(existingDestUrl)")
                                
                                let destEncodedURL = URL(string: existingDestUrl)
                                let destRequest    = NSMutableURLRequest(url: destEncodedURL! as URL)
                                
                                destRequest.httpMethod = "GET"
                                let destConf = URLSessionConfiguration.default

                                destConf.httpAdditionalHeaders = ["Authorization" : "\(JamfProServer.authType["dest"] ?? "Bearer") \(JamfProServer.authCreds["dest"] ?? "")", "Content-Type" : "application/json", "Accept" : "application/json", "User-Agent" : AppInfo.userAgentHeader]
                                
                                // sticky session
        //                        print("[existingEndpoints] JamfProServer.sessionCookie.count: \(JamfProServer.sessionCookie.count)")
        //                        print("[existingEndpoints]       JamfProServer.stickySession: \(JamfProServer.stickySession)")
                                if JamfProServer.sessionCookie.count > 0 && JamfProServer.stickySession {
        //                            print("[existingEndpoints] sticky session for \(self.dest_jp_server)")
                                    URLSession.shared.configuration.httpCookieStorage!.setCookies(JamfProServer.sessionCookie, for: URL(string: self.dest_jp_server), mainDocumentURL: URL(string: self.dest_jp_server))
                                }
                                
                                let destSession = Foundation.URLSession(configuration: destConf, delegate: self, delegateQueue: OperationQueue.main)
                                let task = destSession.dataTask(with: destRequest as URLRequest, completionHandler: {
                                    (data, response, error) -> Void in
                                    destSession.finishTasksAndInvalidate()
                                    if let httpResponse = response as? HTTPURLResponse {
                                        print("[\(#function)] \(#line) - httpResponse.statusCode: \(httpResponse.statusCode)")
                                        if !pref.httpSuccess.contains(httpResponse.statusCode) {
                                            if setting.fullGUI {
                                                _ = Alert.shared.display(header: "Attention:", message: "Failed to get existing \(existingEndpointNode)\nStatus code: \(httpResponse.statusCode)", secondButton: "")
                                            } else {
                                                WriteToLog.shared.message(stringOfText: "[existingEndpoints] Failed to get existing \(existingEndpointNode)    Status code: \(httpResponse.statusCode)")
                                            }
                                            pref.stopMigration = true
                                            DispatchQueue.main.async { [self] in
                                                sourceDataArray.removeAll()
                                                staticSourceDataArray.removeAll()
                                                
                                                clearSourceObjectsList()
                                                staticSourceObjectList.removeAll()

                                                print("[\(#function)] \(#line) - finished getting \(existingEndpointNode)")
                                                goButtonEnabled(button_status: true)
                                                completion(("Failed to get existing \(existingEndpointNode)\nStatus code: \(httpResponse.statusCode)",""))
                                                return
                                            }
                                        }
                                                                                
                                        do {
                                            
                                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[existingEndpoints]  --------------- Getting all \(destEndpoint) ---------------") }
                                            
                                            print("[\(#function)] \(#line) - existingEndpointNode: \(existingEndpointNode)")
                                            switch existingEndpointNode {
                                            case "patch-software-title-configurations":
                                                PatchTitleConfigurations.destination = try! JSONDecoder().decode(PatchSoftwareTitleConfigurations.self, from: data ?? Data())
                                                
                                                // add site name to patch title config
                                                for i in 0..<PatchTitleConfigurations.destination.count {
                                                    PatchTitleConfigurations.destination[i].siteName = JamfProSites.destination.first(where: {$0.id == PatchTitleConfigurations.destination[i].siteId})?.name ?? "NONE"
                                                }
                                                
                                                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[existingEndpoints] Found \(PatchTitleConfigurations.destination.count) patch configurations.") }
                                                
                                                for patchObject in PatchTitleConfigurations.destination as [PatchSoftwareTitleConfiguration] {
//                                                    let displayName = patchObject.displayName
                                                    let softwareTitleName = patchObject.softwareTitleName
//                                                    if patchObject.softwareTitlePublisher.range(of: "(Deprecated Definition)") != nil {
//                                                        displayName.append(" (Deprecated Definition)")
//                                                    }
                                                    print("[existingEndpoints] softwareTitleName: \(softwareTitleName)")
//                                                    displayNames.append(displayName)
                                                    
                                                    if softwareTitleName.isEmpty {
                                                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[existingEndpoints] skipping id: \(Int(patchObject.id ?? "") ?? 0), could not determine the display name.") }
                                                    } else {
                                                        self.currentEPs[softwareTitleName] = Int(patchObject.id ?? "") ?? 0
                                                    }
                                                }
                                                
                                                self.currentEPDict[destEndpoint] = self.currentEPs
//                                                print("[existingEndpoints] \(destEndpoint) current endpoints: \(self.currentEPDict[destEndpoint] ?? [:])")
                                                
                                            default:
                                                let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                                                if let destEndpointJSON = json as? [String: Any] {
            //                                        print("destEndpointJSON: \(destEndpointJSON)")
                                                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[existingEndpoints] existing destEndpointJSON: \(destEndpointJSON)") }
                                                    switch existingEndpointNode {
                                                        
                                                    /*
                                                    // need to revisit as name isn't the best indicatory on whether or not a computer exists
                                                    case "-computers":
                                                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[existingEndpoints] getting current computers") }
                                                        if let destEndpointInfo = destEndpointJSON["computers"] as? [Any] {
                                                            let destEndpointCount: Int = destEndpointInfo.count
                                                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[existingEndpoints] existing \(destEndpoint) found: \(destEndpointCount)") }
                                                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[existingEndpoints] destEndpointInfo: \(destEndpointInfo)") }
                                                            
                                                            if destEndpointCount > 0 {
                                                                for i in (0..<destEndpointCount) {
                                                                    let destRecord = destEndpointInfo[i] as! [String : AnyObject]
                                                                    destXmlID = (destRecord["id"] as! Int)
                                                                    //                                            print("computer ID: \(destXmlID)")
                                                                    if let destEpGeneral = destEndpointJSON["computers/id/\(String(describing: destXmlID))/subset/General"] as? [Any] {
                    //                                                    print("destEpGeneral: \(destEpGeneral)")
                                                                        let destRecordGeneral = destEpGeneral[0] as! [String : AnyObject]
                    //                                                    print("destRecordGeneral: \(destRecordGeneral)")
                                                                        let destXmlUdid: String = (destRecordGeneral["udid"] as! String)
                                                                        self.currentEPs[destXmlUdid] = destXmlID
                                                                    }
                                                                    //print("Dest endpoint name: \(destXmlName)")
                                                                }
                                                            }   // if destEndpointCount > 0
                                                        }   //if let destEndpointInfo = destEndpointJSON - end
                                                        */
                                                    case "packages":
                                                        self.destEPQ.suspend()
                                                        var destRecord      = [String:AnyObject]()
                                                        var packageIDsNames = [Int:String]()
                                                        setting.waitingForPackages = true
                                                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[existingEndpoints] getting current packages") }
                                                        if let destEndpointInfo = destEndpointJSON["packages"] as? [Any] {
                                                            let destEndpointCount: Int = destEndpointInfo.count
                                                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[existingEndpoints] existing \(destEndpoint) found: \(destEndpointCount)") }
                                                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[existingEndpoints] destEndpointInfo: \(destEndpointInfo)") }
                                                            
                                                            if destEndpointCount > 0 {
                                                                for i in (0..<destEndpointCount) {
                                                                    destRecord = destEndpointInfo[i] as! [String : AnyObject]
            //                                                        packageIDs.append(destRecord["id"] as! Int)
                                                                    packageIDsNames[destRecord["id"] as! Int] = destRecord["name"] as? String
                                                                    //print("package ID: \(destRecord["id"] as! Int)")
                                                                }
                                                                
                                                                PackagesDelegate.shared.filenameIdDict(whichServer: "dest", theServer: self.dest_jp_server, base64Creds: JamfProServer.base64Creds["dest"] ?? "", currentPackageIDsNames: packageIDsNames, currentPackageNamesIDs: [:], currentDuplicates: [:], currentTry: 1, maxTries: 3) {
                                                                    (currentDestinationPackages: [String:Int]) in
                                                                    self.currentEPs = currentDestinationPackages
                                                                    setting.waitingForPackages = false
                                                                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[existingEndpoints] returning existing packages: \(currentDestinationPackages)") }
                                                                    
                                                                    ExistingEndpoints.shared.completed += 1
    //                                                                self.updateExistingCounter(change: 1)
                                                                    ExistingEndpoints.shared.waiting = (ExistingEndpoints.shared.completed < endpointDependencyArray.count) ? false:true
                                                                    
                                                                    if !pref.stopMigration {
                                                                        self.currentEPDict["packages"] = currentDestinationPackages
            //                                                            self.currentEPDict["packages"] = self.currentEPs
            //                                                            self.currentEPs.removeAll()
                                                                        if endpointParent != "policies" {
                                                                            completion(
                                                                                ("[ViewController.existingEndpoints] Current packages on \(self.dest_jp_server) - \(currentDestinationPackages)\n","packages"))
                                                                        }
                                                                    } else {
                                                                        self.currentEPDict["packages"] = [:]
                                                                        if endpointParent != "policies" {
                                                                            completion(("[ViewController.existingEndpoints] Migration process was stopped\n","packages"))
                                                                        }
    //                                                                    print("[\(#function)] \(#line) stopMigration")
                                                                        self.stopButton(self)
                                                                    }
                                                                    
                                                                    self.destEPQ.resume()
                //                                                    return
                                                                }
                                                                
                                                            } else {   // if destEndpointCount > 0
                                                                // no packages were found
                                                                self.currentEPDict["packages"] = [:]
                                                                ExistingEndpoints.shared.completed += 1
    //                                                            self.updateExistingCounter(change: 1)
                                                                
                                                                ExistingEndpoints.shared.waiting = (ExistingEndpoints.shared.completed < endpointDependencyArray.count) ? false:true
                                                                self.destEPQ.resume()
                                                                completion(("[ViewController.existingEndpoints] No packages were found on \(self.dest_jp_server)\n","packages"))
                                                            }
                                                            
                                                        } else {  //if let destEndpointInfo = destEndpointJSON - end
                                                            WriteToLog.shared.message(stringOfText: "[existingEndpoints] failed to get packages")
                                                            self.destEPQ.resume()
                                                            ExistingEndpoints.shared.completed += 1
    //                                                        self.updateExistingCounter(change: 1)
                                                            ExistingEndpoints.shared.waiting = (ExistingEndpoints.shared.completed < endpointDependencyArray.count) ? false:true
                                                            completion(("[ViewController.existingEndpoints] failed to get packages\n","packages"))
                                                        }
                                                        
                                                    default:
                                                        if destEndpoint == "jamfusers" || destEndpoint == "jamfgroups" {
                                                            let accountsDict = destEndpointJSON as [String: Any]
                                                            let usersGroups = accountsDict["accounts"] as! [String: Any]
                        //                                    print("users: \(String(describing: usersGroups["users"]))")
                        //                                    print("groups: \(String(describing: usersGroups["groups"]))")
                                                            destEndpoint == "jamfusers" ? (destEndpointDict = usersGroups["users"] as Any):(destEndpointDict = usersGroups["groups"] as Any)
                                                        } else {
                                                            switch endpointParent {
                                                            case "policies":
                                                                switch existingEndpointNode {
                                                                case "computergroups":
                                                                    een = "computer_groups"
                                                                case "directorybindings":
                                                                    een = "directory_bindings"
                                                                case "distributionpoints":
                                                                    een = "distribution_points"
                                                                case "dockitems":
                                                                    een = "dock_items"
                                                                case "networksegments":
                                                                    een = "network_segments"
                                                                default:
                                                                    een = existingEndpointNode
                                                                }
                                                                destEndpointDict = destEndpointJSON["\(een)"]
                                                            default:
                                                                destEndpointDict = destEndpointJSON["\(endpointParent)"]
                                                            }
                                                        }
                                                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[existingEndpoints] getting current \(existingEndpointNode) on destination server") }
                                                        if let destEndpointInfo = destEndpointDict as? [Any] {
                                                            let destEndpointCount: Int = destEndpointInfo.count
                                                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[existingEndpoints] existing \(existingEndpointNode) found: \(destEndpointCount) on destination server") }
                                                            
                                                            if destEndpointCount > 0 {
                                                                for i in (0..<destEndpointCount) {
                                                                    
                                                                    let destRecord = destEndpointInfo[i] as! [String : AnyObject]
                                                                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[existingEndpoints] Processing: \(destRecord).") }
                                                                    destXmlID = (destRecord["id"] as! Int)
                                                                    if destRecord["name"] != nil {
                                                                        destXmlName = destRecord["name"] as! String
                                                                    } else {
                                                                        destXmlName = ""
                                                                    }
                                                                    if destXmlName != "" {
                                                                        if "\(String(describing: destXmlID))" != "" {
                                                                            
                                                                            // filter out policies created from casper remote - start
                                                                                if destXmlName.range(of:"[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] at", options: .regularExpression) == nil && destXmlName != "Update Inventory" {
        //                                                                            print("[ViewController.existingEndpoints] [\(existingEndpointNode)] adding \(destXmlName) (id: \(String(describing: destXmlID!))) to currentEP array.")
                                                                                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[existingEndpoints] adding \(destXmlName) (id: \(String(describing: destXmlID!))) to currentEP array.") }
                                                                                    self.currentEPs[destXmlName] = destXmlID
                                                                                }
                                                                            // filter out policies created from casper remote - end
                                                                            
                                                                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[existingEndpoints]    Array has \(self.currentEPs.count) entries.") }
                                                                        } else {
                                                                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[existingEndpoints] skipping object: \(destXmlName), could not determine its id.") }
                                                                        }
                                                                    } else {
                                                                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[existingEndpoints] skipping id: \(String(describing: destXmlID)), could not determine its name.") }
                                                                    }
                                                                    
                                                                }   // for i in (0..<destEndpointCount) - end
                                                            } else {   // if destEndpointCount > 0 - end
                                                                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[existingEndpoints] No endpoints found, clearing entries.") }
                                                                self.currentEPs.removeAll()
                                                            }
                                                            
            //                                                print("\n[existingEndpoints] endpointParent: \(endpointParent) \t existingEndpointNode: \(existingEndpointNode) \t destEndpoint: \(destEndpoint)\ncurrentEPs: \(self.currentEPs)")
                                                            switch endpointParent {
                                                            case "policies":
                                                                self.currentEPDict[existingEndpointNode] = self.currentEPs
                                                            default:
                                                                self.currentEPDict[destEndpoint] = self.currentEPs
                                                            }
                                                            
    //                                                        self.currentEPs.removeAll()
                                                            
                                                        }   // if let destEndpointInfo - end
                                                    }   // switch - end
                                                } else {
                                                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[existingEndpoints] current endpoint dict: \(self.currentEPs)") }
                                                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[existingEndpoints] clearing existing current endpoints: \(existingEndpointNode)") }
                                                    self.currentEPs.removeAll()
                                                    self.currentEPDict[existingEndpointNode] = [:]
            //                                        completion("error parsing JSON")
                                                }   // if let destEndpointJSON - end

                                            }

                                            
                                                                                        
                                        }   // end do/catch
                                        
                                        if existingEndpointNode != "packages" {
                                            
                                            ExistingEndpoints.shared.completed += 1
                                            
                                            if httpResponse.statusCode > 199 && httpResponse.statusCode <= 299 {
            //                                    print(httpResponse.statusCode)
                                                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[existingEndpoints] returning existing \(existingEndpointNode) endpoints: \(self.currentEPs)") }
                    //                            print("returning existing endpoints: \(self.currentEPs)")
                                                ExistingEndpoints.shared.completed += 1
//                                                self.updateExistingCounter(change: 1)
                                                ExistingEndpoints.shared.waiting = (ExistingEndpoints.shared.completed < endpointDependencyArray.count) ? false:true
                                                if ExistingEndpoints.shared.completed >= endpointDependencyArray.count {
                                                    if endpointParent == "ldap_servers" {
                                                        self.currentLDAPServers = self.currentEPDict[destEndpoint]!
                                                    }
                                                    if let _ =  self.currentEPDict[destEndpoint] {
                                                        self.currentEPs = self.currentEPDict[destEndpoint]!
                                                    } else {
                                                        self.currentEPs = [:]
                                                    }
                                                    completion(("[existingEndpoints] Current \(destEndpoint) - \(self.currentEPs)\n","\(existingEndpointNode)"))
                                                }
                                            } else {
                                                // something went wrong
                                                ExistingEndpoints.shared.completed += 1
//                                                self.updateExistingCounter(change: 1)
                                                ExistingEndpoints.shared.waiting = (ExistingEndpoints.shared.completed < endpointDependencyArray.count) ? false:true
                                                if ExistingEndpoints.shared.completed == endpointDependencyArray.count {
            //                                        print("status code: \(httpResponse.statusCode)")
            //                                        print("currentEPDict[] - error: \(String(describing: self.currentEPDict))")
                                                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[existingEndpoints] endpoint: \(destEndpoint)") }
                                                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[existingEndpoints] error - status code: \(httpResponse.statusCode)") }
                                                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[existingEndpoints] xml: \(String(describing: self.currentEPDict))") }
                                                    self.currentEPs = self.currentEPDict[destEndpoint]!
                                                    completion(("\ndestination count error","\(existingEndpointNode)"))
                                                }
                                                
                                            }   // if httpResponse/else - end
                                        } //else {
        //                                    return
        //                                }
                                        
                                    } else {   // if let httpResponse - end
                                        completion(("Failed to get response for existing \(existingEndpointNode)",""))
                                        return
                                    }
                                    semaphore.signal()
                                    if error != nil {
                                        completion(("error for existing \(existingEndpointNode) - error: \(String(describing: error))",""))
                                        return
                                    }
                                })  // let task = destSession - end
                                //print("GET")
                                task.resume()
                            } else {  //if !waiting - end
                                usleep(100)
                            }
                            
                            // single completion after waiting...
                            
        //                    print("completed: \(completed) of \(endpointDependencyArray.count) dependencies")
                        }   // while (ExistingEndpoints.shared.completed < endpointDependencyArray.count)
                        
        //                print("[\(endpointParent)] ExistingEndpoints.shared.completed \(completed) of \(endpointDependencyArray.count)")
                    }   // destEPQ - end
                } else {
                    self.currentEPs["_"] = 0
                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[existingEndpoints] exit - save only enabled, endpoint: \(theDestEndpoint) not needed.") }
                    completion(("Current endpoints - export.saveOnly, not needed.","\(theDestEndpoint)"))
                }
    }   // func existingEndpoints - end

    func getDependencies(object: String, json: [String:AnyObject], completion: @escaping (_ returnedDependencies: [String:[String:String]]) -> Void) {
        WriteToLog.shared.message(stringOfText: "[getDependencies] enter")
        
        if json.count == 0 {
            completion([:])
            return
        }
        
        var objectDict           = [String:Any]()
        var fullDependencyDict   = [String: [String:String]]()    // full list of dependencies of a single policy
//        var allDependencyDict  = [String: [String:String]]()    // all dependencies of all selected policies
        var dependencyArray      = [String:String]()
        var waitForPackageLookup = false
        
        if setting.migrateDependencies {
            var dependencyNode = ""
            
//            print("look up dependencies for \(object)")
            
            switch object {
            case "policies":
                objectDict      = json["policy"] as! [String:Any]
                let general     = objectDict["general"] as! [String:Any]
                let bindings    = objectDict["account_maintenance"] as! [String:Any]
                let scope       = objectDict["scope"] as! [String:Any]
                let scripts     = objectDict["scripts"] as! [[String:Any]]
                let packages    = objectDict["package_configuration"] as! [String:Any]
                let exclusions  = scope["exclusions"] as! [String:Any]
                let limitations = scope["limitations"] as! [String:Any]
                
                for the_dependency in ordered_dependency_array {
                    switch the_dependency {
                    case "categories":
                        dependencyNode = "category"
                    case "computergroups":
                        dependencyNode = "computer_groups"
                    case "directorybindings":
                        dependencyNode = "directory_bindings"
                    case "diskencryption":
                        dependencyNode = "disk_encryption"
                    case "dockitems":
                        dependencyNode = "dock_items"
                    case "networksegments":
                        dependencyNode = "network_segments"
                    case "sites":
                        dependencyNode = "site"
                    default:
                        dependencyNode = the_dependency
                    }
                    
                    dependencyArray.removeAll()
                    switch dependencyNode {
                    case "computer_groups", "buildings", "departments", "ibeacons", "network_segments":
                        if (self.scopePoliciesCopy && dependencyNode == "computer_groups") || (dependencyNode != "computer_groups") {
                            if let _ = scope[dependencyNode] {
                                let scope_dep = scope[dependencyNode] as! [AnyObject]
                                for theObject in scope_dep {
                                    let local_name = (theObject as! [String:Any])["name"]
                                    let local_id   = (theObject as! [String:Any])["id"]
                                    dependencyArray["\(local_name!)"] = "\(local_id!)"
                                }
                            }
                            
                            if dependencyNode == "computer_groups" {
                                print("check for exclusions: \(exclusions)")
                                if let _ = exclusions[dependencyNode] {
                                    let scope_excl_compGrp_dep = exclusions[dependencyNode] as! [[String:Any]]
                                    //                                let scope_excl_compGrp_dep = scope_excl_dep["computer_groups"] as! [String:Any]
                                    print("exclusions: \(scope_excl_compGrp_dep)")
                                    for theObject in scope_excl_compGrp_dep {
                                        print("theObject: \(theObject)")
                                        let local_name = theObject["name"] as! String
                                        let local_id   = theObject["id"] as! Int
                                        dependencyArray["\(local_name)"] = "\(local_id)"
                                        print("dependencyArray: \(dependencyArray)")
                                    }
                                }
                                
                                if let _ = limitations[dependencyNode] {
                                    let scope_excl_dep = limitations[dependencyNode] as! [AnyObject]
                                    for theObject in scope_excl_dep {
                                        let local_name = (theObject as! [String:Any])["name"]
                                        let local_id   = (theObject as! [String:Any])["id"]
                                        dependencyArray["\(local_name!)"] = "\(local_id!)"
                                    }
                                }
                            }
                        }
                        
                    case "directory_bindings":
                    if let _ = bindings[dependencyNode] {
                        let scope_limit_dep = bindings[dependencyNode] as! [AnyObject]
                        for theObject in scope_limit_dep {
                            let local_name = (theObject as! [String:Any])["name"]
                            let local_id   = (theObject as! [String:Any])["id"]
                            dependencyArray["\(local_name!)"] = "\(local_id!)"
                        }
                    }

                    case "dock_items", "disk_encryption":
                    if let _ = objectDict[dependencyNode] {
                        let scope_item = objectDict[dependencyNode] as! [AnyObject]
                        for theObject in scope_item {
                            let local_name = (theObject as! [String:Any])["name"]
                            let local_id   = (theObject as! [String:Any])["id"]
                            dependencyArray["\(local_name!)"] = "\(local_id!)"
                        }
                    }
                         
                     case "packages":
                     if let _ = packages[dependencyNode] {
                         let packages_dep = packages[dependencyNode] as! [AnyObject]
                         if packages_dep.count > 0 { waitForPackageLookup = true }
                         var completedPackageLookups = 0
                         for theObject in packages_dep {
//                             let local_name = (theObject as! [String:Any])["name"]
//                             print("lookup package filename for display name \(String(describing: local_name!))")
                             let local_id   = (theObject as! [String:Any])["id"]
                             
                             PackagesDelegate.shared.getFilename(whichServer: "source", theServer: JamfProServer.source, base64Creds: JamfProServer.base64Creds["source"] ?? "", theEndpoint: "packages", theEndpointID: local_id as! Int, skip: wipeData.on, currentTry: 1) {
                                 (result: (Int,String)) in
                                 let (_,packageFilename) = result
                                 if packageFilename != "" {
                                     dependencyArray["\(packageFilename)"] = "\(local_id!)"
                                 } else {
                                     WriteToLog.shared.message(stringOfText: "[getDependencies] package filename lookup failed for package ID \(String(describing: local_id))")
                                 }
                                 completedPackageLookups += 1
                                 if completedPackageLookups == packages_dep.count {
                                     waitForPackageLookup = false
                                     fullDependencyDict[the_dependency] = dependencyArray.count == 0 ? nil:dependencyArray
                                 }
                             }
                         }
                     }

                     case "printers":
                     let jsonPrinterArray = objectDict[dependencyNode] as! [Any]
                     for i in 0..<jsonPrinterArray.count {
                        if "\(jsonPrinterArray[i])" != "" {
                            let scope_item = jsonPrinterArray[i] as! [String:Any]
                            let local_name = scope_item["name"]
                            let local_id   = scope_item["id"]
                            dependencyArray["\(local_name!)"] = "\(local_id!)"
                        }
                    }
                        
                    case "scripts":
                        for theObject in scripts {
                            let local_name = theObject["name"]
                            let local_id   = theObject["id"]
                            dependencyArray["\(local_name!)"] = "\(local_id!)"
                        }

                        
                    default:
                        if let _ = general[dependencyNode] {
                            let general_dep = general[dependencyNode]! as! [String:Any]
                            let local_name = general_dep["name"] as! String
                            let local_id   = general_dep["id"] as! Int
                            if local_id != -1 {
                                dependencyArray["\(local_name)"] = "\(local_id)"
                            }
                        }
                    }
                    if the_dependency != "buildings" {
                        fullDependencyDict[the_dependency] = dependencyArray.count == 0 ? nil:dependencyArray
                    }
    //                fullDependencyDict[the_dependency] = dependencyArray
    //                allDependencyDict = allDependencyDict.merging(fullDependencyDict) { (_, new) in new}
                }
//              print("fullDependencyDict: \(fullDependencyDict)")

            default:
                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[getDependencies] not implemented for \(object).") }
//                print("return empty fullDependencyDict")
                completion([:])
            }
            
        }
        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[getDependencies] dependencies: \(fullDependencyDict)") }
        WriteToLog.shared.message(stringOfText: "[getDependencies] complete")
        var tmpCount = 1
        DispatchQueue.global(qos: .utility).async {
            while waitForPackageLookup && tmpCount <= 60 {
//                print("trying to resolve package filename(s), attempt \(tmpCount)")
                sleep(1)
                tmpCount += 1
            }
            
//            print("return fullDependencyDict: \(fullDependencyDict)")
            completion(fullDependencyDict)
        }
    }
    
    @IBAction func migrateDependencies_fn(_ sender: Any) {
        setting.migrateDependencies = migrateDependencies.state.rawValue == 1 ? true:false
    }
    
    //==================================== Utility functions ====================================
    
    func activeTab(fn: String) -> String {
        var activeTab = ""
        if !setting.migrate {
            if macOS_tabViewItem.tabState.rawValue == 0 {
                activeTab =  "macOS"
            } else if iOS_tabViewItem.tabState.rawValue == 0 {
                activeTab = "iOS"
            } else if selective_tabViewItem.tabState.rawValue == 0 {
                activeTab = "selective"
            }
        } else {
            activeTab = ""
        }
        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.activeTab] Active tab caller: \(fn) - activeTab: \(activeTab)") }
        return activeTab
    }
    
    func alert_dialog(header: String, message: String) {
        NSApplication.shared.activate(ignoringOtherApps: true)
        let dialog: NSAlert = NSAlert()
        dialog.messageText = header
        dialog.informativeText = message
        dialog.alertStyle = NSAlert.Style.warning
        dialog.addButton(withTitle: "OK")
        dialog.runModal()
        //return true
    }   // func alert_dialog - end
    
    /*
    func checkURL2(whichServer: String, serverURL: String, completion: @escaping (Bool) -> Void) {
//        print("enter checkURL2")
        if (whichServer == "dest" && export.saveOnly) || (whichServer == "source" && (wipeData.on || JamfProServer.importFiles == 1)) {
            completion(true)
        } else {
            var available:Bool = false
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[checkURL2] --- checking availability of server: \(serverURL)") }
        
            authQ.sync {
                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[checkURL2] checking: \(serverURL)") }
                
                var healthCheckURL = "\(serverURL)/healthCheck.html"
                healthCheckURL = healthCheckURL.replacingOccurrences(of: "//healthCheck.html", with: "/healthCheck.html")
                
                guard let encodedURL = URL(string: healthCheckURL) else {
                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[checkURL2] --- Cannot cast to URL: \(healthCheckURL)") }
                    completion(false)
                    return
                }
                let configuration = URLSessionConfiguration.ephemeral

                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[checkURL2] --- checking healthCheck page.") }
                var request = URLRequest(url: encodedURL)
                request.httpMethod = "GET"

                let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
                let task = session.dataTask(with: request as URLRequest, completionHandler: {
                    (data, response, error) -> Void in
                    session.finishTasksAndInvalidate()
                    if let httpResponse = response as? HTTPURLResponse {
                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[checkURL2] Server check: \(healthCheckURL), httpResponse: \(httpResponse.statusCode)") }
                        
                        //                    print("response: \(response)")
                        if let responseData = String(data: data!, encoding: .utf8) {
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[checkURL2] checkURL2 data: \(responseData)") }
                        } else {
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[checkURL2] checkURL2 data: none") }
                        }
                        available = true
                        
                    } // if let httpResponse - end
                    // server is not reachable - availability is still false
                    completion(available)
                })  // let task = session - end
                task.resume()
            }   // authQ - end
        }
    }   // func checkURL2 - end
    */
    
    func clearProcessingFields() {
        DispatchQueue.main.async {
            self.get_name_field.stringValue    = ""
            self.put_name_field.stringValue    = ""

            self.getSummary_label.stringValue  = ""
            self.get_levelIndicator.floatValue = 0.0
            self.get_levelIndicator.isEnabled  = false

            self.putSummary_label.stringValue  = ""
            self.put_levelIndicator.floatValue = 0.0
            self.put_levelIndicator.isEnabled  = false

        }
    }
    
    func clearSelectiveList() {
        DispatchQueue.main.async { [self] in
            if !selectiveListCleared && srcSrvTableView.isEnabled {
                
                generalSectionToMigrate_button.selectItem(at: 0)
                sectionToMigrate_button.selectItem(at: 0)
                iOSsectionToMigrate_button.selectItem(at: 0)
                selectiveFilter_TextField.stringValue = ""

                objectsToMigrate.removeAll()
                endpointCountDict.removeAll()
                sourceDataArray.removeAll()
                srcSrvTableView.reloadData()
                targetSelectiveObjectList.removeAll()
                srcSrvTableView.reloadData()
                
                clearSourceObjectsList()
                
                selectiveListCleared = true
            } else {
                selectiveListCleared = true
                srcSrvTableView.isEnabled = true
            }
        }
    }
    
    func serverChanged(whichserver: String) {
        if (whichserver == "source" && !wipeData.on) || (whichserver == "dest" && wipeData.on) || (srcSrvTableView.isEnabled == false) {
            srcSrvTableView.isEnabled = true
            selectiveListCleared      = false
            clearSelectiveList()
            clearProcessingFields()
        }
        JamfProServer.version[whichserver] = ""
        JamfProServer.validToken[whichserver] = false
    }
    
    // which platform mode tab are we on - start
    func deviceType() -> String {

            if self.macOS_tabViewItem.tabState.rawValue == 0 {
                self.platform = "macOS"
            } else if self.iOS_tabViewItem.tabState.rawValue == 0 {
                self.platform = "iOS"
            } else if self.general_tabViewItem.tabState.rawValue == 0 {
                self.platform = "general"
            } else {
                if self.sectionToMigrate_button.indexOfSelectedItem > 0 {
                    self.platform = "macOS"
                } else if self.iOSsectionToMigrate_button.indexOfSelectedItem > 0 {
                    self.platform = "iOS"
                } else {
                    self.platform = "general"
                }
        }
//        print("platform: \(platform)")
        return platform
    }
    // which platform mode tab are we on - end
    
//    func dd(value: Int) -> String {
//        let formattedValue = (value < 10) ? "0\(value)":"\(value)"
//        return formattedValue
//    }
    
    func disable(theXML: String) -> String {
        let regexDisable    = try? NSRegularExpression(pattern: "<enabled>true</enabled>", options:.caseInsensitive)
        let newXML          = (regexDisable?.stringByReplacingMatches(in: theXML, options: [], range: NSRange(0..<theXML.utf16.count), withTemplate: "<enabled>false</enabled>"))!
  
        return newXML
    }
    
    func runComplete() {
//        print("[runComplete] enter")
//        DispatchQueue.main.async { [self] in
            migrationComplete.isDone = true
            if theIconsQ.operationCount == 0 {
                nodesComplete = 0
                AllEndpointsArray.removeAll()
                availableObjsToMigDict.removeAll()
                
                iconfiles.policyDict.removeAll()
                iconfiles.pendingDict.removeAll()
                
                if setting.fullGUI {
                    DispatchQueue.main.async { [self] in
                        let (h,m,s, _) = timeDiff(forWhat: "runTime")
                        WriteToLog.shared.message(stringOfText: "[Migration Complete] runtime: \(Utilities.shared.dd(value: h)):\(Utilities.shared.dd(value: m)):\(Utilities.shared.dd(value: s)) (h:m:s)")
                        spinner_progressIndicator.stopAnimation(self)
                        resetAllCheckboxes()
                    }
                }

                if wipeData.on {
                    rmDELETE()
                }
                print("[\(#function)] \(#line) - finished")
                goButtonEnabled(button_status: true)
                
                if setting.fullGUI {
                    DispatchQueue.main.async { [self] in
                        spinner_progressIndicator.stopAnimation(self)
                        go_button.title = "Go!"
                        _ = enableSleep()
                    }
                } else {
                    // silent run complete
                    Headless.shared.runComplete(backupDate: backupDate, nodesMigrated: nodesMigrated, objectsToMigrate: objectsToMigrate, counters: counters)
                    
//                    print("[runComplete] nodes migrated: \(nodesMigrated+1)")
//                    
//                    if export.backupMode {
//        //                if theOpQ.operationCount == 0 && nodesMigrated > 0 {
//                        zipIt(args: "cd \"\(export.saveLocation)\" ; /usr/bin/zip -rm -o \(JamfProServer.source.fqdnFromUrl)_export_\(backupDate.string(from: History.startTime)).zip \(JamfProServer.source.fqdnFromUrl)_export_\(backupDate.string(from: History.startTime))/") { [self]
//                                (result: String) in
//        //                            print("zipIt result: \(result)")
//                                do {
//                                    if fm.fileExists(atPath: "\"\(export.saveLocation)\(JamfProServer.source.fqdnFromUrl)_export_\(backupDate.string(from: History.startTime))\"") {
//                                        try fm.removeItem(at: URL(string: "\"\(export.saveLocation)\(JamfProServer.source.fqdnFromUrl)_export_\(backupDate.string(from: History.startTime))\"")!)
//                                    }
//                                    WriteToLog.shared.message(stringOfText: "[Backup Complete] Backup created: \(export.saveLocation)\(JamfProServer.source.fqdnFromUrl)_export_\(backupDate.string(from: History.startTime)).zip")
//                                    
//                                    let (h,m,s, _) = timeDiff(forWhat: "runTime")
//                                    WriteToLog.shared.message(stringOfText: "[Backup Complete] runtime: \(Utilities.shared.dd(value: h)):\(Utilities.shared.dd(value: m)):\(Utilities.shared.dd(value: s)) (h:m:s)")
//                                } catch let error as NSError {
//                                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "Unable to delete backup folder! Something went wrong: \(error)") }
//                                }
//                            }
//                            
//                            logCleanup()
//                            NSApplication.shared.terminate(self)
//        //                }   //zipIt(args: "cd - end
//                    } else {
//                        if nodesMigrated > 0 {
//        //                        print("summaryDict: \(summaryDict)")
//        //                        print("counters: \(counters)")
//                            var summary = ""
//                            var otherLine: Bool = true
//                            var paddingChar = " "
//                            let sortedObjects = objectsToMigrate.sorted()
//                            // find longest length of objects migrated
//                            var column1Padding = ""
//                            for theObject in objectsToMigrate {
//                                if theObject.count+1 > column1Padding.count {
//                                    column1Padding = "".padding(toLength: theObject.count+1, withPad: " ", startingAt: 0)
//                                }
//                            }
//                            let leading = LogLevel.debug ? "                             ":"                 "
//                            
//                            summary = " ".padding(toLength: column1Padding.count-7, withPad: " ", startingAt: 0) + "Object".padding(toLength: 7, withPad: " ", startingAt: 0) +
//                                  "created".padding(toLength: 10, withPad: " ", startingAt: 0) +
//                                  "updated".padding(toLength: 10, withPad: " ", startingAt: 0) +
//                                  "failed".padding(toLength: 10, withPad: " ", startingAt: 0) +
//                                  "total".padding(toLength: 10, withPad: " ", startingAt: 0) + "\n"
//                            for theObject in sortedObjects {
//                                if counters[theObject] != nil {
//                                    let counts = counters[theObject]!
//                                    let rightJustify = leading.padding(toLength: leading.count+(column1Padding.count-theObject.count-2), withPad: " ", startingAt: 0)
//                                    otherLine.toggle()
//                                    paddingChar = otherLine ? " ":"."
//                                    summary = summary.appending(rightJustify + "\(theObject)".padding(toLength: column1Padding.count+(7-"\(counts["create"]!)".count-(column1Padding.count-theObject.count-1)), withPad: paddingChar, startingAt: 0) +
//                                                                "\(String(describing: counts["create"]!))".padding(toLength: (10-"\(counts["update"]!)".count+"\(counts["create"]!)".count), withPad: paddingChar, startingAt: 0) +
//                                                                "\(String(describing: counts["update"]!))".padding(toLength: (9-"\(counts["fail"]!)".count+"\(counts["update"]!)".count), withPad: paddingChar, startingAt: 0) +
//                                                                "\(String(describing: counts["fail"]!))".padding(toLength: (9-"\(counts["total"]!)".count+"\(counts["fail"]!)".count), withPad: paddingChar, startingAt: 0) +
//                                                                "\(String(describing: counts["total"]!))".padding(toLength: 10, withPad: " ", startingAt: 0) + "")
//                                }
//                            }
//                            WriteToLog.shared.message(stringOfText: summary)
//                            let (h,m,s, _) = timeDiff(forWhat: "runTime")
//                            WriteToLog.shared.message(stringOfText: "[Migration Complete] runtime: \(Utilities.shared.dd(value: h)):\(Utilities.shared.dd(value: m)):\(Utilities.shared.dd(value: s)) (h:m:s)")
//                            
//                            logCleanup()
//                            NSApplication.shared.terminate(self)
//                        }
//                    }
                }
            }
//        }
    }
    
    func goButtonEnabled(button_status: Bool) {
        if setting.fullGUI {
            DispatchQueue.main.async { [self] in
                if button_status {
                    spinner_progressIndicator.stopAnimation(self)
                } else {
                    spinner_progressIndicator.startAnimation(self)
                }
                if button_status {
                    if wipeData.on {
                        go_button.title = "Delete"
                    } else {
                        go_button.title = "Go!"
                        go_button.bezelColor = nil
                    }
                } else {
                    go_button.title = "Stop"
                }
            }
        }
    }
    
    // scale the delay when listing items with selective migrations based on the number of items
    func listDelay(itemCount: Int) -> UInt32 {
        if itemCount > 1000 { return 0 }
        
        let delayFactor = (itemCount < 10) ? 10:itemCount
        
        let factor = (50000000/delayFactor/delayFactor)
        if factor > 50000 {
            return 50000
        } else {
            return UInt32(factor)
        }
    }
    
    func exportItems(node: String, objectString: String, rawName: String, id: String, format: String) {
        
        var baseFolder = ""
        var saveFolder = ""
        var endpointPath  = ""
        
        var name = rawName.replacingOccurrences(of: ":", with: ";")
        name     = name.replacingOccurrences(of: "/", with: ":")
        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.exportItems] saving \(name), format: \(format), to folder \(node)") }
        // Create folder to store objectString files if needed - start
        baseFolder = userDefaults.string(forKey: "saveLocation") ?? ""
        if baseFolder == "" {
            baseFolder = (NSHomeDirectory() + "/Downloads/Jamf Transporter/")
        } else {
            baseFolder = baseFolder.pathToString
//            baseFolder = baseFolder.replacingOccurrences(of: "file://", with: "")
//            baseFolder = baseFolder.replacingOccurrences(of: "%20", with: " ")
        }
        
        saveFolder = baseFolder+format+"/"
        
        if !(fm.fileExists(atPath: saveFolder)) {
            do {
                try fm.createDirectory(atPath: saveFolder, withIntermediateDirectories: true, attributes: nil)
            } catch {
                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.exportItems] Problem creating \(saveFolder) folder: Error \(error)") }
                return
            }
        }
        // Create folder to store objectString files if needed - end
        
//        print("[ViewController] node: \(node)")
        
        // Create endpoint type to store objectString files if needed - start
        switch node {
        case "selfservicepolicyicon", "macapplicationsicon", "mobiledeviceapplicationsicon":
            endpointPath = saveFolder+node+"/\(id)"
        case "accounts/groupid":
            endpointPath = saveFolder+"jamfgroups"
        case "accounts/userid":
            endpointPath = saveFolder+"jamfusers"
        case "computergroups":
            let isSmart = tagValue2(xmlString: objectString, startTag: "<is_smart>", endTag: "</is_smart>")
            if isSmart == "true" {
                endpointPath = saveFolder+"smartcomputergroups"
            } else {
                endpointPath = saveFolder+"staticcomputergroups"
            }
        default:
            endpointPath = saveFolder+node
        }
        if !(fm.fileExists(atPath: endpointPath)) {
            do {
                try fm.createDirectory(atPath: endpointPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.exportItems] Problem creating \(endpointPath) folder: Error \(error)") }
                return
            }
        }
        // Create endpoint type to store objectString files if needed - end
        
        switch node {
        case "buildings":
            let jsonFile = "\(name)-\(id).json"
            var jsonString = objectString.dropFirst().dropLast()
            jsonString = "{\(jsonString)}"
            do {
                try jsonString.write(toFile: endpointPath+"/"+jsonFile, atomically: true, encoding: .utf8)
                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.exportItems] saved to: \(endpointPath)") }
            } catch {
                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.exportItems] Problem writing \(endpointPath) folder: Error \(error)") }
                return
            }
            
        case "patchmanagement":
            print("[exportItems] should not see this")
//            let jsonFile = "\(name)-\(id).json"
//            var jsonString = objectString.dropFirst().dropLast()
//            jsonString = "{\(jsonString)}"
//            print("[exportItems] jsonString: \(jsonString)")
//            do {
//                let data = jsonString.data(using: .utf8) ?? Data()
////                let objectJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
//                
//                let objectJson = try! JSONDecoder().decode(PatchSoftwareTitleConfiguration.self, from: data)
//                
//                let patchSoftwareTitle = """
//                        <patch_software_title>
//                            <name>"\(objectJson.softwareTitleName)"</name>
//                            <name_id>"\(objectJson.softwareTitleNameId)"</name_id>
//                            <source_id>"\(objectJson.id)"</source_id>
//                            <notifications>
//                                <web_notification>"\(objectJson.uiNotifications)"</web_notification>
//                                <email_notification>"\(objectJson.emailNotifications)"</email_notification>
//                            </notifications>
//                            <categories>
//                                <id>-1</id>
//                                <name>"\(objectJson.categoryId)"</name>
//                            </categories>
//                        </patch_software_title>
//                        """
//                print("[exportItems] patchSoftwareTitle: \(patchSoftwareTitle)")
//                
//                
//                try jsonString.write(toFile: endpointPath+"/"+jsonFile, atomically: true, encoding: .utf8)
//                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.exportItems] saved to: \(endpointPath)") }
//            } catch {
//                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.exportItems] Problem writing \(endpointPath) folder: Error \(error)") }
//                return
//            }

        case "selfservicepolicyicon", "macapplicationsicon", "mobiledeviceapplicationsicon":
            
            var copyIcon   = true
            let iconSource = "\(objectString)"
            let iconDest   = "\(endpointPath)/\(name)"

//            print("copy from \(iconSource) to: \(iconDest)")
            if fm.fileExists(atPath: iconDest) {
                do {
                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.exportItems] removing currently saved icon: \(iconDest)") }
                    try FileManager.default.removeItem(at: URL(fileURLWithPath: iconDest))
                }
                catch let error as NSError {
                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.exportItems] unable to delete cached icon: \(iconDest).  Error \(error).") }
                    copyIcon = false
                }
            }
            if copyIcon {
                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.exportItems] saving icon to: \(iconDest)") }
                do {
                    try fm.copyItem(atPath: iconSource, toPath: iconDest)
                    if export.saveOnly {
                        do {
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.exportItems] removing cached icon: \(iconSource)/") }
                            try FileManager.default.removeItem(at: URL(fileURLWithPath: "\(iconSource)/"))
                        }
                        catch let error as NSError {
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.exportItems] unable to delete \(iconSource)/.  Error \(error)") }
                        }
                    }
                    
                }
                catch let error as NSError {
                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.exportItems] unable to save icon: \(iconDest).  Error \(error).") }
                    copyIcon = false
                }
            }
//                print("Copied \(iconSource) to: \(iconDest)")
            
        default:
            let xmlFile = "\(name)-\(id).xml"
            if let xmlDoc = try? XMLDocument(xmlString: objectString, options: .nodePrettyPrint) {
                if let _ = try? XMLElement.init(xmlString:"\(objectString)") {
                    let data = xmlDoc.xmlData(options:.nodePrettyPrint)
                    let formattedXml = String(data: data, encoding: .utf8)!
                    //                print("policy xml:\n\(formattedXml)")
                    
                    do {
                        try formattedXml.write(toFile: endpointPath+"/"+xmlFile, atomically: true, encoding: .utf8)
                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.exportItems] saved to: \(endpointPath)") }
                    } catch {
                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.exportItems] Problem writing \(endpointPath) folder: Error \(error)") }
                        return
                    }
                }   // if let prettyXml - end
            }
        }
    }
    
    // replace with tagValue function?
    func getName(endpoint: String, objectXML: String) -> String {
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
    
    func getStatusUpdate2(endpoint: String, total: Int, index: Int = -1) {
        var adjEndpoint = ""
        switch endpoint {
        case "accounts/userid":
            adjEndpoint = "jamfusers"
        case "accounts/groupid":
            adjEndpoint = "jamfgroups"
        default:
            adjEndpoint = endpoint
        }
        
        if index == -1 {
            if getCounters[adjEndpoint] == nil {
                getCounters[adjEndpoint] = ["get":1]
            } else {
                getCounters[adjEndpoint]!["get"]! += 1
            }
        } else {
                getCounters[adjEndpoint] = ["get":index]
        }
        
        let totalCount = (fileImport && activeTab(fn: "getStatusUpdate2") == "selective") ? targetSelectiveObjectList.count:total
        
        if getCounters[adjEndpoint]!["get"]! == totalCount || total == 0 {
            getNodesComplete += 1
            if getNodesComplete == totalObjectsToMigrate && export.saveOnly {
                runComplete()
            }
        }
        
        if setting.fullGUI && totalCount > 0 {
            DispatchQueue.main.async { [self] in
//                print("[getStatusUpdate2] count: \(String(describing: getCounters[adjEndpoint]?["get"]))")
                if let currentCount = getCounters[adjEndpoint]?["get"], currentCount > 0 {
//                if getCounters[adjEndpoint]!["get"]! > 0 {
                    if !setting.migrateDependencies || adjEndpoint == "policies" {
                        get_name_field.stringValue    = adjEndpoint
                        get_levelIndicator.floatValue = Float(currentCount)/Float(totalCount)
//                        get_levelIndicator.floatValue = Float(getCounters[adjEndpoint]!["get"]!)/Float(totalCount)
                        getSummary_label.stringValue  = "\(currentCount) of \(totalCount)"
                    }
                }
            }
        }
    }
    func putStatusUpdate2(endpoint: String, total: Int) {
        var adjEndpoint = ""
        
        switch endpoint {
        case "accounts/userid":
            adjEndpoint = "jamfusers"
        case "accounts/groupid":
            adjEndpoint = "jamfgroups"
        default:
            adjEndpoint = endpoint
        }
        
        if putCounters[adjEndpoint] == nil {
            putCounters[adjEndpoint] = ["put":1]
        } else {
            putCounters[adjEndpoint]!["put"]! += 1
        }
        
//        let totalCount = (fileImport && activeTab(fn: "putStatusUpdate2") == "selective") ? totalObjectsToMigrate:total
        let totalCount = (fileImport && activeTab(fn: "putStatusUpdate2") == "selective") ? targetSelectiveObjectList.count:total
                    
        var newPutTotal = (counters[adjEndpoint]?["create"] ?? 0) + (counters[adjEndpoint]?["update"] ?? 0) + (counters[adjEndpoint]?["fail"] ?? 0)
        newPutTotal += (counters[adjEndpoint]?["skipped"] ?? 0)
//        let theTask = wipeData.on ? "removal":"create/update"
        if newPutTotal == totalCount || total == 0 {
            nodesComplete += 1
            WriteToLog.shared.message(stringOfText: "[ViewController.putStatusUpdate2] \(adjEndpoint): \(nodesComplete) of \(totalObjectsToMigrate) complete")
            if nodesComplete == totalObjectsToMigrate {
                if !setting.fullGUI {
                    nodesMigrated = nodesComplete
                }
                runComplete()
            }
        }
        
        DispatchQueue.main.async { [self] in
            if setting.fullGUI && totalCount > 0 {
                if counters[adjEndpoint]?["fail"] == 0 {
                    PutLevelIndicator.shared.indicatorColor[adjEndpoint] = .green
//                    put_levelIndicatorFillColor[adjEndpoint] = .green
                    put_levelIndicator.fillColor = .green
                } else if ((counters[adjEndpoint]?["fail"] ?? 0)! > 0 && (counters[adjEndpoint]?["fail"] ?? 0)! < totalCount) {
                    PutLevelIndicator.shared.indicatorColor[adjEndpoint]/*put_levelIndicatorFillColor[adjEndpoint]*/ = .yellow
                    put_levelIndicator.fillColor = .yellow
                } else {
                    PutLevelIndicator.shared.indicatorColor[adjEndpoint]/* put_levelIndicatorFillColor[adjEndpoint]*/ = .red
                    put_levelIndicator.fillColor = .red
                }
                if let currentPutCount = putCounters[adjEndpoint]?["put"], currentPutCount > 0 {
                    if !setting.migrateDependencies || adjEndpoint == "policies" {
                        put_name_field.stringValue    = adjEndpoint
                        put_levelIndicator.floatValue = Float(newPutTotal)/Float(totalCount)
                        putSummary_label.stringValue  = "\(newPutTotal) of \(totalCount)"
                    }
                }
            }
        }
    }
    
    func getIconId(iconUri: String, endpoint: String) -> String {
        var iconId = "0"
        if iconUri != "" {
            if let index = iconUri.firstIndex(of: "=") {
                let iconId_string = iconUri.suffix(from: index).dropFirst()
//                    print("iconId_string: \(iconId_string)")
                if endpoint != "policies" {
                    if let index = iconId_string.firstIndex(of: "&") {
//                            iconId = Int(iconId_string.prefix(upTo: index))!
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
    
    func icons(endpointType: String, action: String, ssInfo: [String: String], f_createDestUrl: String, responseData: String, sourcePolicyId: String) {

        var createDestUrl        = f_createDestUrl
        var iconToUpload         = ""
        var action               = "GET"
        var newSelfServiceIconId = 0
        var iconXml              = ""
        
        let ssIconName           = ssInfo["ssIconName"]!
        let ssIconUri            = ssInfo["ssIconUri"]!
        let ssIconId             = ssInfo["ssIconId"]!
        let ssXml                = ssInfo["ssXml"]!
//        print("[ViewController] ssIconId: \(ssIconId)")

        if (ssIconName != "") && (ssIconUri != "") {
            
            var iconNode     = "policies"
            var iconNodeSave = "selfservicepolicyicon"
            switch endpointType {
            case "macapplications":
                iconNode     = "macapplicationsicon"
                iconNodeSave = "macapplicationsicon"
            case "mobiledeviceapplications":
                iconNode     = "mobiledeviceapplicationsicon"
                iconNodeSave = "mobiledeviceapplicationsicon"
            default:
                break
            }
//          print("new policy id: \(tagValue(xmlString: responseData, xmlTag: "id"))")
//          print("iconName: "+ssIconName+"\tURL: \(ssIconUri)")

            // set icon source
            if fileImport {
                action         = "SKIP"
                let sourcePath = JamfProServer.source.suffix(1) != "/" ? "\(JamfProServer.source)/":JamfProServer.source
                iconToUpload   = "\(sourcePath)\(iconNodeSave)/\(ssIconId)/\(ssIconName)"
            } else {
                iconToUpload = "\(NSHomeDirectory())/Library/Caches/icons/\(ssIconId)/\(ssIconName)"
            }
            
            // set icon destination
            if setting.csa {
                // cloud connector
                createDestUrl = "\(self.createDestUrlBase)/v1/icon"
                createDestUrl = createDestUrl.replacingOccurrences(of: "/JSSResource", with: "/api")
            } else {
                createDestUrl = "\(self.createDestUrlBase)/fileuploads/\(iconNode)/id/\(tagValue(xmlString: responseData, xmlTag: "id"))"
            }
            createDestUrl = createDestUrl.urlFix
            
            // Get or skip icon from Jamf Pro
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.icons] before icon download.") }

            if iconfiles.pendingDict["\(ssIconId.fixOptional)"] != "pending" {
                if iconfiles.pendingDict["\(ssIconId.fixOptional)"] != "ready" {
                    iconfiles.pendingDict["\(ssIconId.fixOptional)"] = "pending"
                    WriteToLog.shared.message(stringOfText: "[ViewController.icons] marking icon for \(iconNode) id \(sourcePolicyId) as pending")
                } else {
                    action = "SKIP"
                }
                
                // download the icon - action = "GET"
                iconMigrate(action: action, ssIconUri: ssIconUri, ssIconId: ssIconId, ssIconName: ssIconName, _iconToUpload: "", createDestUrl: "") {
                    (result: Int) in
//                    print("action: \(action)")
//                    print("Icon url: \(ssIconUri)")
                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.icons] after icon download.") }
                    
                    if result > 199 && result < 300 {
                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.icons] retuned from icon id \(ssIconId) GET with result: \(result)") }
//                        print("\ncreateDestUrl: \(createDestUrl)")

                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.icons] retrieved icon from \(ssIconUri)") }
                        if export.saveRawXml || export.saveTrimmedXml {
                            var saveFormat = export.saveRawXml ? "raw":"trimmed"
                            if export.backupMode {
                                saveFormat = "\(JamfProServer.source.fqdnFromUrl)_export_\(self.backupDate.string(from: History.startTime))"
                            }
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.icons] saving icon: \(ssIconName) for \(iconNode).") }
                            DispatchQueue.main.async {
                                XmlDelegate().save(node: iconNodeSave, xml: "\(NSHomeDirectory())/Library/Caches/icons/\(ssIconId)/\(ssIconName)", rawName: ssIconName, id: ssIconId, format: "\(saveFormat)")
                            }
                        }   // if export.saveRawXml - end
                        // upload icon if not in save only mode
                        if !export.saveOnly {
                            
                            // see if the icon has been downloaded
//                            if iconfiles.policyDict["\(ssIconId)"]?["policyId"] == nil || iconfiles.policyDict["\(ssIconId)"]?["policyId"] == "" {
                            let downloadedIcon = iconfiles.policyDict["\(ssIconId)"]?["policyId"]
                            if downloadedIcon?.fixOptional == nil || downloadedIcon?.fixOptional == "" {
//                                print("[ViewController.icons] iconfiles.policyDict value for icon id \(ssIconId.fixOptional): \(String(describing: iconfiles.policyDict["\(ssIconId)"]?["policyId"]))")
                                iconfiles.policyDict["\(ssIconId)"] = ["policyId":"", "destinationIconId":""]
                                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.icons] upload icon (id=\(ssIconId)) to: \(createDestUrl)") }
//                                        print("createDestUrl: \(createDestUrl)")
                                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.icons] POST icon (id=\(ssIconId)) to: \(createDestUrl)") }
                                
                                self.iconMigrate(action: "POST", ssIconUri: "", ssIconId: ssIconId, ssIconName: ssIconName, _iconToUpload: "\(iconToUpload)", createDestUrl: createDestUrl) {
                                        (iconMigrateResult: Int) in

                                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.icons] result of icon POST: \(iconMigrateResult).") }
                                        // verify icon uploaded successfully
                                        if iconMigrateResult != 0 {
                                            // associate self service icon to new policy id
                                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.icons] source icon (id=\(ssIconId)) successfully uploaded and has id=\(iconMigrateResult).") }

//                                            iconfiles.policyDict["\(ssIconId)"] = ["policyId":"\(iconMigrateResult)", "destinationIconId":""]
                                            iconfiles.policyDict["\(ssIconId)"]?["policyId"]          = "\(iconMigrateResult)"
                                            iconfiles.policyDict["\(ssIconId)"]?["destinationIconId"] = ""
                                            
                                            
                                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.icons] future usage of source icon id \(ssIconId) should reference new policy id \(iconMigrateResult) for the icon id") }
//                                            print("iconfiles.policyDict[\(ssIconId)]: \(String(describing: iconfiles.policyDict["\(ssIconId)"]!))")
                                            
                                            usleep(100)

                                            // removed cached icon
                                            if fm.fileExists(atPath: "\(NSHomeDirectory())/Library/Caches/icons/\(ssIconId)/") {
                                                do {
                                                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.icons] removing cached icon: \(NSHomeDirectory())/Library/Caches/icons/\(ssIconId)/") }
                                                    try FileManager.default.removeItem(at: URL(fileURLWithPath: "\(NSHomeDirectory())/Library/Caches/icons/\(ssIconId)/"))
                                                }
                                                catch let error as NSError {
                                                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.icons] unable to delete \(NSHomeDirectory())/Library/Caches/icons/\(ssIconId)/.  Error \(error).") }
                                                }
                                            }
                                            
                                            if setting.csa {
                                                switch endpointType {
                                                case "policies":
                                                    iconXml = "<?xml version='1.0' encoding='UTF-8' standalone='yes'?><policy><self_service>\(ssXml)<self_service_icon><id>\(iconMigrateResult)</id></self_service_icon></self_service></policy>"
                                                case "mobiledeviceapplications":
//                                                    let newAppIcon = iconfiles.policyDict["\(ssIconId)"]?["policyId"] ?? "0"
                                                    iconXml = "<?xml version='1.0' encoding='UTF-8' standalone='yes'?><mobile_device_application><general><icon><id>\(iconMigrateResult)</id><name>\(ssIconName)</name><uri>\(ssIconUri)</uri></icon></general></mobile_device_application>"
                                                default:
                                                    break
                                                }
                                                
                                                let policyUrl = "\(self.createDestUrlBase)/\(endpointType)/id/\(tagValue(xmlString: responseData, xmlTag: "id"))"
                                                self.iconMigrate(action: "PUT", ssIconUri: "", ssIconId: ssIconId, ssIconName: "", _iconToUpload: iconXml, createDestUrl: policyUrl) {
                                                    (result: Int) in
                                                
                                                    if result > 199 && result < 300 {
                                                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.icons] successfully updated policy (id: \(tagValue(xmlString: responseData, xmlTag: "id"))) with icon id \(iconMigrateResult)") }
//                                                        print("successfully used new icon id \(newSelfServiceIconId)")
                                                    }
                                                }
                                                
                                            }
                                        } else {
                                            // icon failed to upload
                                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.icons] source icon (id=\(ssIconId)) failed to upload") }
                                            iconfiles.policyDict["\(ssIconId)"] = ["policyId":"", "destinationIconId":""]
                                        }

                                    }
                            
                            } else {    // if !(iconfiles.policyDict["\(ssIconId)"]?["policyId"] == nil - else
                                // icon has been downloaded
//                                print("already defined icon/policy icon id \(ssIconId)")
//                                print("iconfiles.policyDict: \(String(describing: iconfiles.policyDict["\(ssIconId)"]!["policyID"]))")
//                                while iconfiles.policyDict["\(ssIconId)"]!["policyID"] == "-1" || iconfiles.policyDict["\(ssIconId)"]!["policyID"] != nil {
//                                    sleep(1)
//                                    print("waiting for icon id \(ssIconId)")
//                                }

                                // destination policy to upload icon to
                                let thePolicyID = "\(tagValue(xmlString: responseData, xmlTag: "id"))"
                                let policyUrl   = "\(self.createDestUrlBase)/\(endpointType)/id/\(thePolicyID)"
//                                print("\n[ViewController.icons] iconfiles.policyDict value for icon id \(ssIconId.fixOptional): \(String(describing: iconfiles.policyDict["\(ssIconId)"]?["policyId"]))")
//                                print("[ViewController.icons] policyUrl: \(policyUrl)")
                                
                                if iconfiles.policyDict["\(ssIconId.fixOptional)"]!["destinationIconId"]! == "" {
                                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.icons] getting downloaded icon id from destination server, policy id: \(String(describing: iconfiles.policyDict["\(ssIconId.fixOptional)"]!["policyId"]!))") }
                                    var policyIconDict = iconfiles.policyDict

                                    Json().getRecord(whichServer: "dest", theServer: self.dest_jp_server, base64Creds: JamfProServer.base64Creds["dest"] ?? "", theEndpoint: "\(endpointType)/id/\(thePolicyID)/subset/SelfService")  {
                                        (objectRecord: Any) in
                                        let result = objectRecord as? [String: AnyObject] ?? [:]
//                                        print("[icons] result of Json().getRecord: \(result)")
                                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.icons] Returned from Json.getRecord.  Retreived Self Service info.") }
                                        
//                                        if !setting.csa {
                                            if result.count > 0 {
                                                let theKey = (endpointType == "policies") ? "policy":"mobile_device_application"
                                                let selfServiceInfoDict = result[theKey]?["self_service"] as! [String:Any]
//                                                print("[icons] selfServiceInfoDict: \(selfServiceInfoDict)")
                                                let selfServiceIconDict = selfServiceInfoDict["self_service_icon"] as! [String:Any]
                                                newSelfServiceIconId = selfServiceIconDict["id"] as? Int ?? 0
                                                
                                                if newSelfServiceIconId != 0 {
                                                    policyIconDict["\(ssIconId)"]!["destinationIconId"] = "\(newSelfServiceIconId)"
                                                    iconfiles.policyDict = policyIconDict
            //                                        iconfiles.policyDict["\(ssIconId)"]!["destinationIconId"] = "\(newSelfServiceIconId)"
                                                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.icons] Returned from Json.getRecord: \(result)") }
                                                                                            
                                                    iconXml = "<?xml version='1.0' encoding='UTF-8' standalone='yes'?><policy><self_service>\(ssXml)<self_service_icon><id>\(newSelfServiceIconId)</id></self_service_icon></self_service></policy>"
                                                } else {
                                                    WriteToLog.shared.message(stringOfText: "[ViewController.icons] Unable to locate icon on destination server for: policies/id/\(thePolicyID)")
                                                    iconXml = "<?xml version='1.0' encoding='UTF-8' standalone='yes'?><policy><self_service>\(ssXml)<self_service_icon></self_service_icon></self_service></policy>"
                                                }
                                            } else {
                                                iconXml = "<?xml version='1.0' encoding='UTF-8' standalone='yes'?><policy><self_service>\(ssXml)<self_service_icon></self_service_icon></self_service></policy>"
                                            }
                                        
                                            self.iconMigrate(action: "PUT", ssIconUri: "", ssIconId: ssIconId, ssIconName: "", _iconToUpload: iconXml, createDestUrl: policyUrl) {
                                            (result: Int) in
                                                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.icons] after updating policy with icon id.") }
                                            
                                                if result > 199 && result < 300 {
                                                    WriteToLog.shared.message(stringOfText: "[ViewController.icons] successfully used new icon id \(newSelfServiceIconId)")
                                                }
                                            }
//                                        }
                                        
                                    }
                                } else {
                                    WriteToLog.shared.message(stringOfText: "[ViewController.icons] using new icon id from destination server")
                                    newSelfServiceIconId = Int(iconfiles.policyDict["\(ssIconId)"]!["destinationIconId"]!) ?? 0
                                    
                                        switch endpointType {
                                        case "policies":
                                            iconXml = "<?xml version='1.0' encoding='UTF-8' standalone='yes'?><policy><self_service>\(ssXml)<self_service_icon><id>\(newSelfServiceIconId)</id></self_service_icon></self_service></policy>"
                                        case "mobiledeviceapplications":
//                                                    let newAppIcon = iconfiles.policyDict["\(ssIconId)"]?["policyId"] ?? "0"
                                            iconXml = "<?xml version='1.0' encoding='UTF-8' standalone='yes'?><mobile_device_application><general><icon><id>\(newSelfServiceIconId)</id><uri>\(ssIconUri)</uri></icon></general></mobile_device_application>"
                                        default:
                                            break
                                        }
                                    
                                    iconXml = "<?xml version='1.0' encoding='UTF-8' standalone='yes'?><policy><self_service><self_service_icon><id>\(newSelfServiceIconId)</id></self_service_icon></self_service></policy>"
        //                                            print("iconXml: \(iconXml)")
                                    self.iconMigrate(action: "PUT", ssIconUri: "", ssIconId: ssIconId, ssIconName: "", _iconToUpload: iconXml, createDestUrl: policyUrl) {
                                        (result: Int) in
                                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[CreateEndpoints.icon] after updating policy with icon id.") }
                                        
                                            if result > 199 && result < 300 {
                                                WriteToLog.shared.message(stringOfText: "[ViewController.icons] successfully used new icon id \(newSelfServiceIconId)")
                                            }
                                        }
                                }
                            }
                        }  // if !export.saveOnly - end
                    } else {
                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[CreateEndpoints.icon] failed to retrieved icon from \(ssIconUri).") }
                    }
                }   // iconMigrate - end
                
            } else {
                // hold processing already used icon until it's been uploaded to the new server
                if !export.saveOnly {
                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[CreateEndpoints.icon] sending policy id \(sourcePolicyId) to icon queue while icon id \(ssIconId) is processed") }
                    iconMigrationHold(ssIconId: "\(ssIconId)", newIconDict: ["endpointType": endpointType, "action": action, "ssIconId": "\(ssIconId)", "ssIconName": ssIconName, "ssIconUri": ssIconUri, "f_createDestUrl": f_createDestUrl, "responseData": responseData, "sourcePolicyId": sourcePolicyId])
                }
            }//                }   // if !(iconfiles.policyDict["\(ssIconId)"]?["policyId"] - end
        }   // if (ssIconName != "") && (ssIconUri != "") - end
    }   // func icons - end
    
    func iconMigrate(action: String, ssIconUri: String, ssIconId: String, ssIconName: String, _iconToUpload: String, createDestUrl: String, completion: @escaping (Int) -> Void) {
        
        // fix id/hash being passed as optional
        let iconToUpload = _iconToUpload.fixOptional
        var curlResult   = 0
//        print("[ViewController] iconToUpload: \(iconToUpload)")
        
        var moveIcon     = true
        var savedURL:URL!
        
        iconNotification()

        switch action {
        case "GET":

//            print("checking iconfiles.policyDict[\(ssIconId)]: \(String(describing: iconfiles.policyDict["\(ssIconId)"]))")
                iconfiles.policyDict["\(ssIconId)"] = ["policyId":"", "destinationIconId":""]
//                print("icon id \(ssIconId) is marked for download/cache")
                WriteToLog.shared.message(stringOfText: "[iconMigrate.\(action)] fetching icon: \(ssIconUri)")
                // https://developer.apple.com/documentation/foundation/url_loading_system/downloading_files_from_websites
                let url = URL(string: "\(ssIconUri)")!
                            
                let downloadTask = URLSession.shared.downloadTask(with: url) {
                    urlOrNil, responseOrNil, errorOrNil in
                    // check for and handle errors:
                    // * errorOrNil should be nil
                    // * responseOrNil should be an HTTPURLResponse with statusCode in 200..<299
                    // create folder to download/cache icon if it doesn't exist
                    URLSession.shared.finishTasksAndInvalidate()
                    do {
                        let documentsURL = try
                            FileManager.default.url(for: .libraryDirectory,
                                                    in: .userDomainMask,
                                                    appropriateFor: nil,
                                                    create: false)
                        savedURL = documentsURL.appendingPathComponent("Caches/icons/\(ssIconId)/")
                        
                        if !(fm.fileExists(atPath: savedURL.path)) {
                            do {if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[iconMigrate.\(action)] creating \(savedURL.path) folder to cache icon") }
                                try fm.createDirectory(atPath: savedURL.path, withIntermediateDirectories: true, attributes: nil)
//                                usleep(1000)
                            } catch {
                                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[iconMigrate.\(action)] problem creating \(savedURL.path) folder: Error \(error)") }
                                moveIcon = false
                            }
                        }
                    } catch {
                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[iconMigrate.\(action)] failed to set cache location: Error \(error)") }
                    }
                    
                    guard let fileURL = urlOrNil else { return }
                    do {
                        if moveIcon {
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[iconMigrate.\(action)] saving icon to \(savedURL.appendingPathComponent("\(ssIconName)"))") }
                            if !FileManager.default.fileExists(atPath: savedURL.appendingPathComponent("\(ssIconName)").path) {
                                try FileManager.default.moveItem(at: fileURL, to: savedURL.appendingPathComponent("\(ssIconName)"))
                            }
                            
                            // Mark the icon as cached
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[iconMigrate.\(action)] icon id \(ssIconId) is downloaded/cached to \(savedURL.appendingPathComponent("\(ssIconName)"))") }
//                            usleep(100)
                        }
                    } catch {
                        WriteToLog.shared.message(stringOfText: "[iconMigrate.\(action)] Problem moving icon: Error \(error)")
                    }
                    let curlResponse = responseOrNil as! HTTPURLResponse
                    curlResult = curlResponse.statusCode
                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[iconMigrate.\(action)] result of Swift icon GET: \(curlResult).") }
                    completion(curlResult)
                }
                downloadTask.resume()
                // swift file download - end
            
        case "POST":
            if uploadedIcons[ssIconId.fixOptional] == nil || setting.csa {
                // upload icon to fileuploads endpoint / icon server
                WriteToLog.shared.message(stringOfText: "[iconMigrate.\(action)] sending icon: \(ssIconName)")
               
                var fileURL: URL!
                
                fileURL = URL(fileURLWithPath: iconToUpload)

                let boundary = "----WebKitFormBoundary\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"

                var httpResponse:HTTPURLResponse?
                var statusCode = 0
                
                theIconsQ.maxConcurrentOperationCount = 2
                let semaphore = DispatchSemaphore(value: 0)
                
                    self.theIconsQ.addOperation {

                        WriteToLog.shared.message(stringOfText: "[iconMigrate.\(action)] uploading icon: \(iconToUpload)")

                        let startTime = Date()
                        var postData  = Data()
                        var newId     = 0
                        
    //                    WriteToLog.shared.message(stringOfText: "[iconMigrate.\(action)] fileURL: \(String(describing: fileURL!))")
                        let fileType = NSURL(fileURLWithPath: "\(String(describing: fileURL!))").pathExtension
                    
                        WriteToLog.shared.message(stringOfText: "[iconMigrate.\(action)] uploading \(ssIconName)")
                        
                        let serverURL = URL(string: createDestUrl)!
                        WriteToLog.shared.message(stringOfText: "[iconMigrate.\(action)] uploading to: \(createDestUrl)")
                        
                        let sessionConfig = URLSessionConfiguration.default
                        let session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: OperationQueue.main)
                        
                        var request = URLRequest(url:serverURL)
                        request.addValue("\(String(describing: JamfProServer.authType["dest"] ?? "Bearer")) \(String(describing: JamfProServer.authCreds["dest"] ?? ""))", forHTTPHeaderField: "Authorization")
                        request.addValue("\(AppInfo.userAgentHeader)", forHTTPHeaderField: "User-Agent")
                        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                        
                        // prep the data for uploading
                        do {
                            postData.append("------\(boundary)\r\n".data(using: .utf8)!)
                            postData.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(ssIconName)\"\r\n".data(using: .utf8)!)
                            postData.append("Content-Type: image/\(fileType ?? "png")\r\n\r\n".data(using: .utf8)!)
                            let fileData = try Data(contentsOf:fileURL, options:[])
                            postData.append(fileData)

                            let closingBoundary = "\r\n--\(boundary)--\r\n"
                            if let d = closingBoundary.data(using: .utf8) {
                                postData.append(d)
                                WriteToLog.shared.message(stringOfText: "[iconMigrate.\(action)] loaded \(ssIconName) to data.")
                            }
                            let dataLen = postData.count
                            request.addValue("\(dataLen)", forHTTPHeaderField: "Content-Length")
                            
                        } catch {
                            WriteToLog.shared.message(stringOfText: "[iconMigrate.\(action)] unable to get file: \(iconToUpload)")
                        }

                        request.httpBody   = postData
                        request.httpMethod = action
                        
                        // start upload process
                        URLCache.shared.removeAllCachedResponses()
                        let task = session.dataTask(with: request, completionHandler: { [self] (data, response, error) -> Void in
                            session.finishTasksAndInvalidate()
            //                if let httpResponse = response as? HTTPURLResponse {
                            if let _ = (response as? HTTPURLResponse)?.statusCode {
                                httpResponse = response as? HTTPURLResponse
                                statusCode = httpResponse!.statusCode
                                WriteToLog.shared.message(stringOfText: "[iconMigrate.\(action)] \(ssIconName) - Response from server - Status code: \(statusCode)")
                                WriteToLog.shared.message(stringOfText: "[iconMigrate.\(action)] Response data string: \(String(data: data!, encoding: .utf8)!)")
                            } else {
                                WriteToLog.shared.message(stringOfText: "[iconMigrate.\(action)] \(ssIconName) - No response from the server.")
                                
                                completion(statusCode)
                            }

                            switch statusCode {
                            case 200, 201:
                                WriteToLog.shared.message(stringOfText: "[iconMigrate.\(action)] file successfully uploaded.")
                                if let dataResponse = String(data: data!, encoding: .utf8) {
    //                                print("[ViewController.iconMigrate] dataResponse: \(dataResponse)")
                                    if setting.csa {
                                        let jsonResponse = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String:Any]
                                        if let _ = jsonResponse?["id"] as? Int {
                                            newId = jsonResponse?["id"] as? Int ?? 0
                                        }
                                        
                                        uploadedIcons[ssIconId.fixOptional] = newId
                                        
                                    } else {
                                        newId = Int(tagValue2(xmlString: dataResponse, startTag: "<id>", endTag: "</id>")) ?? 0
                                    }
                                }
                                iconfiles.pendingDict["\(ssIconId.fixOptional)"] = "ready"
                            case 401:
                                WriteToLog.shared.message(stringOfText: "[iconMigrate.\(action)] **** Authentication failed.")
                            case 404:
                                WriteToLog.shared.message(stringOfText: "[iconMigrate.\(action)] **** server / file not found.")
                            default:
                                WriteToLog.shared.message(stringOfText: "[iconMigrate.\(action)] **** unknown error occured.")
                                WriteToLog.shared.message(stringOfText: "[iconMigrate.\(action)] **** Error took place while uploading a file.")
                            }

                            let endTime = Date()
                            let components = Calendar.current.dateComponents([.second], from: startTime, to: endTime)

                            let timeDifference = Int(components.second!)
                            let (h,r) = timeDifference.quotientAndRemainder(dividingBy: 3600)
                            let (m,s) = r.quotientAndRemainder(dividingBy: 60)

                            WriteToLog.shared.message(stringOfText: "[iconMigrate.\(action)] upload time: \(Utilities.shared.dd(value: h)):\(Utilities.shared.dd(value: m)):\(Utilities.shared.dd(value: s)) (h:m:s)")
                            
                            iconNotification()

                            completion(newId)
                            // upload checksum - end
                            
                            semaphore.signal()
                        })   // let task = session - end

    //                    let uploadObserver = task.progress.observe(\.fractionCompleted) { progress, _ in
    //                        let uploadPercentComplete = (round(progress.fractionCompleted*1000)/10)
    //                    }
                        task.resume()
                        semaphore.wait()
    //                    NotificationCenter.default.removeObserver(uploadObserver)
                    }   // theUploadQ.addOperation - end
            } else {
//                if let _ = uploadedIcons[ssIconId.fixOptional] {
                    completion(uploadedIcons[ssIconId.fixOptional]!)
//                } else {
//                    completion(0)
//                }
            }
            
        case "PUT":
            
            WriteToLog.shared.message(stringOfText: "[iconMigrate.\(action)] setting icon for \(createDestUrl)")
            
            theIconsQ.maxConcurrentOperationCount = 2
            let semaphore    = DispatchSemaphore(value: 0)
            let encodedXML   = iconToUpload.data(using: String.Encoding.utf8)
                
            self.theIconsQ.addOperation {
            
                let encodedURL = URL(string: createDestUrl)
                let request = NSMutableURLRequest(url: encodedURL! as URL)

                request.httpMethod = action
               
                let configuration = URLSessionConfiguration.default

                configuration.httpAdditionalHeaders = ["Authorization" : "\(JamfProServer.authType["dest"] ?? "Bearer") \(JamfProServer.authCreds["dest"] ?? "")", "Content-Type" : "text/xml", "Accept" : "text/xml", "User-Agent" : AppInfo.userAgentHeader]
                request.httpBody = encodedXML!
                let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
                let task = session.dataTask(with: request as URLRequest, completionHandler: { [self]
                    (data, response, error) -> Void in
                    session.finishTasksAndInvalidate()
                    if let httpResponse = response as? HTTPURLResponse {
                        
                            if httpResponse.statusCode > 199 && httpResponse.statusCode <= 299 {
                                WriteToLog.shared.message(stringOfText: "[iconMigrate.\(action)] icon updated on \(createDestUrl)")
//                                WriteToLog.shared.message(stringOfText: "[iconMigrate.\(action)] posted xml: \(iconToUpload)")
                            } else {
                                WriteToLog.shared.message(stringOfText: "[iconMigrate.\(action)] **** error code: \(httpResponse.statusCode) failed to update icon on \(createDestUrl)")
                                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[iconMigrate.\(action)] posted xml: \(iconToUpload)") }
//                                print("[iconMigrate.\(action)] iconToUpload: \(iconToUpload)")
                                
                            }
                        completion(httpResponse.statusCode)
                    } else {   // if let httpResponse = response - end
                        WriteToLog.shared.message(stringOfText: "[iconMigrate.\(action)] no response from server")
                        completion(0)
                    }
                    
                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[iconMigrate.\(action)] POST or PUT Operation: \(request.httpMethod)") }
                    
                    iconNotification()
                    
                    semaphore.signal()
                })
                task.resume()
                semaphore.wait()

            }   // theUploadQ.addOperation - end
            // end upload procdess
                    
                        
        default:
            WriteToLog.shared.message(stringOfText: "[iconMigrate.\(action)] skipping icon: \(ssIconName).")
            completion(200)
        }
     
    }
    
    func iconNotification() {
        DispatchQueue.main.async { [self] in
            if setting.fullGUI {
                uploadingIcons_textfield.isHidden = (theIconsQ.operationCount > 0) ? false:true
                uploadingIcons2_textfield.isHidden = (theIconsQ.operationCount > 0) ? false:true
            }
            if migrationComplete.isDone == true && theIconsQ.operationCount == 0 {
                runComplete()
            }
        }
    }
    
    // hold icon migrations while icon is being cached/uploaded to the new server
    func iconMigrationHold(ssIconId: String, newIconDict: [String:String]) {
        if iconDictArray["\(ssIconId)"] == nil {
            iconDictArray["\(ssIconId)"] = [newIconDict]
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.iconMigration] first entry for iconDictArray[\(ssIconId)]: \(newIconDict)") }
        } else {
            iconDictArray["\(ssIconId)"]?.append(contentsOf: [newIconDict])
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.iconMigration] updated iconDictArray[\(ssIconId)]: \(String(describing: iconDictArray["\(ssIconId)"]))") }
        }
        iconHoldQ.async {
            while iconfiles.pendingDict.count > 0 {
                if pref.stopMigration {
                    break
                }
                sleep(1)
                for (iconId, state) in iconfiles.pendingDict {
                    if (state == "ready") {
                        if let _ = self.iconDictArray["\(iconId)"] {
                            for iconDict in self.iconDictArray["\(iconId)"]! {
                                if let endpointType = iconDict["endpointType"], let action = iconDict["action"], let ssIconName = iconDict["ssIconName"], let ssIconUri = iconDict["ssIconUri"], let f_createDestUrl = iconDict["f_createDestUrl"], let responseData = iconDict["responseData"], let sourcePolicyId = iconDict["sourcePolicyId"] {
                                
//                                    let ssIconUriArray = ssIconUri.split(separator: "/")
//                                    let ssIconId = String("\(ssIconUriArray.last)")
                                    let ssIconId = self.getIconId(iconUri: ssIconUri, endpoint: endpointType)
                                    
                                    let ssInfo: [String: String] = ["ssIconName": ssIconName, "ssIconId": ssIconId, "ssIconUri": ssIconUri, "ssXml": ""]
                                    self.icons(endpointType: endpointType, action: action, ssInfo: ssInfo, f_createDestUrl: f_createDestUrl, responseData: responseData, sourcePolicyId: sourcePolicyId)
                                }
                            }
                            self.iconDictArray.removeValue(forKey: iconId)
                        }
                    } else {
//                        print("waiting for icon id \(iconId) to become ready (uploaded to destination server)")
                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.iconMigration] waiting for icon id \(iconId) to become ready (uploaded to destination server)") }
                    }
                }   // for (pending, state) - end
            }   // while - end
        }   // DispatchQueue.main.async - end
    }
    
    // func labelColor - start
    func labelColor(endpoint: String, theColor: NSColor) {
        if setting.fullGUI {
            DispatchQueue.main.async {
                switch endpoint {
                    // general tab
                    case "advancedusersearches":
                        self.advusersearch_label_field.textColor = theColor
                    case "buildings":
                        self.building_label_field.textColor = theColor
                    case "categories":
                        self.categories_label_field.textColor = theColor
                    case "departments":
                        self.departments_label_field.textColor = theColor
                    case "userextensionattributes":
                        self.userEA_label_field.textColor = theColor
                    case "ldapservers":
                        self.ldapservers_label_field.textColor = theColor
                    case "sites":
                        self.sites_label_field.textColor = theColor
                    case "networksegments":
                        self.network_segments_label_field.textColor = theColor
                    case "users":
                        self.users_label_field.textColor = theColor
                    case "usergroups":
                        self.smartUserGrps_label_field.textColor = theColor
                        self.staticUserGrps_label_field.textColor = theColor
                    case "jamfusers", "accounts/userid":
                        self.jamfUserAccounts_field.textColor = theColor
                    case "jamfgroups", "accounts/groupid":
                        self.jamfGroupAccounts_field.textColor = theColor
                    case "smartusergroups":
                        self.smartUserGrps_label_field.textColor = theColor
                    case "staticusergroups":
                        self.staticUserGrps_label_field.textColor = theColor
                // macOS tab
                case "advancedcomputersearches":
                    self.advcompsearch_label_field.textColor = theColor
                case "computers":
                    self.computers_label_field.textColor = theColor
                case "directorybindings":
                    self.directory_bindings_field.textColor = theColor
                case "diskencryptionconfigurations":
                    self.file_shares_label_field.textColor = theColor
                case "distributionpoints":
                    self.file_shares_label_field.textColor = theColor
                case "dockitems":
                    self.dock_items_field.textColor = theColor
                case "softwareupdateservers":
                    self.sus_label_field.textColor = theColor
//                case "netbootservers":
//                    self.netboot_label_field.textColor = theColor
                case "osxconfigurationprofiles":
                    self.osxconfigurationprofiles_label_field.textColor = theColor
                case "patchpolicies":
                    self.patch_policies_field.textColor = theColor
//                case "patchManagement":
//                    self.patch_mgmt_button.textColor = theColor
                case "computerextensionattributes":
                    self.extension_attributes_label_field.textColor = theColor
                case "scripts":
                    self.scripts_label_field.textColor = theColor
                case "macapplications":
                    self.macapplications_label_field.textColor = theColor
                case "computergroups":
                    self.smart_groups_label_field.textColor = theColor
                    self.static_groups_label_field.textColor = theColor
                case "smartcomputergroups":
                    self.smart_groups_label_field.textColor = theColor
                case "staticcomputergroups":
                    self.static_groups_label_field.textColor = theColor
                case "packages":
                    self.packages_label_field.textColor = theColor
                case "printers":
                    self.printers_label_field.textColor = theColor
                case "policies":
                    self.policies_label_field.textColor = theColor
                case "restrictedsoftware":
                    self.restrictedsoftware_label_field.textColor = theColor
                case "computer-prestages":
                    self.macPrestages_label_field.textColor = theColor
                // iOS tab
                case "advancedmobiledevicesearches":
                    self.advancedmobiledevicesearches_label_field.textColor = theColor
                case "mobiledeviceapplications":
                    self.mobiledeviceApps_label_field.textColor = theColor
                case "mobiledeviceconfigurationprofiles":
                    self.mobiledeviceconfigurationprofile_label_field.textColor = theColor
                case "mobiledeviceextensionattributes":
                    self.mobiledeviceextensionattributes_label_field.textColor = theColor
                case "mobiledevices":
                    self.mobiledevices_label_field.textColor = theColor
                case "mobiledevicegroups":
                    self.smart_ios_groups_label_field.textColor = theColor
                    self.static_ios_groups_label_field.textColor = theColor
                case "smartmobiledevicegroups":
                    self.smart_ios_groups_label_field.textColor = theColor
                case "staticmobiledevicegroups":
                    self.static_ios_groups_label_field.textColor = theColor
                case "mobile-device-prestages":
                    self.mobiledevicePrestage_label_field.textColor = theColor
                default:
                    break
//                    print("function labelColor: unknown label - \(endpoint)")
                }
            }
        }
    }
    // func labelColor - end
    
    // move history to log - start
    func moveHistoryToLog (source: String, destination: String) {
        var allClear = true

        do {
            let historyFiles = try fm.contentsOfDirectory(atPath: source)
            
            for historyFile in historyFiles {
                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "Moving: " + source + historyFile + " to " + destination) }
                do {
                    try fm.moveItem(atPath: source + historyFile, toPath: destination + historyFile.replacingOccurrences(of: ".txt", with: ".log"))
                }
                catch let error as NSError {
                    WriteToLog.shared.message(stringOfText: "Ooops! Something went wrong moving the history file: \(error)")
                    allClear = false
                }
            }
        } catch {
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "no history to display") }
        }
        if allClear {
            do {
                try fm.removeItem(atPath: source)
            } catch {
                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "Unable to remove \(source)") }
            }
        }
    }
    // move history to logs - end
    
    // script parameter label fix
    func parameterFix(theXML: String) -> String {

        let parameterRegex  = try! NSRegularExpression(pattern: "</parameters>", options:.caseInsensitive)
        var updatedScript   = theXML
        var scriptParameter = ""
        
        // add parameter keys for those with no value
        for i in (4...11) {
            scriptParameter = tagValue2(xmlString: updatedScript, startTag: "parameter\(i)", endTag: "parameter\(i)")
            if scriptParameter == "" {
                updatedScript = parameterRegex.stringByReplacingMatches(in: updatedScript, options: [], range: NSRange(0..<theXML.utf16.count), withTemplate: "<parameter\(i)></parameter\(i)></parameters>")
            }
        }

        return updatedScript
    }
    
    func rmDELETE() {
        var isDir: ObjCBool = false
        if (fm.fileExists(atPath: NSHomeDirectory() + "/Library/Application Support/jamf-migrator/DELETE", isDirectory: &isDir)) {
            do {
                try fm.removeItem(atPath: NSHomeDirectory() + "/Library/Application Support/jamf-migrator/DELETE")
                wipeData.on = false
//                _ = serverOrFiles()
//                DispatchQueue.main.async {
//                    self.selectiveTabelHeader_textview.stringValue = "Select object(s) to migrate"
//                }
                // re-enable source server, username, and password fields (to finish later)
//                source_jp_server_field.isEnabled = true
//                sourceServerList_button.isEnabled = true
            }
            catch let error as NSError {
                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "Unable to delete file! Something went wrong: \(error)") }
            }
        }
    }
    
    func rmBlankLines(theXML: String) -> String {
        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "Removing blank lines.") }
        let f_regexComp = try! NSRegularExpression(pattern: "\n\n", options:.caseInsensitive)
        let newXML = f_regexComp.stringByReplacingMatches(in: theXML, options: [], range: NSRange(0..<theXML.utf16.count), withTemplate: "")
//        let newXML_trimmed = newXML.replacingOccurrences(of: "\n\n", with: "")
        return newXML
    }
    
    func rmJsonData(rawJSON: [String:Any], theTag: String) -> String {
        var newJSON  = rawJSON
                // remove keys with <null> as the value
                for (key, value) in newJSON {
                    if "\(value)" == "<null>" || "\(value)" == ""  {
                        newJSON[key] = nil
                    } else {
                        newJSON[key] = "\(value)"
                    }
                }
                if theTag != "" {
                    if let _ = newJSON[theTag] {
                        newJSON[theTag] = nil
                    }
                }
        
        return "\(newJSON)"
    }
    
    func rmXmlData(theXML: String, theTag: String, keepTags: Bool) -> String {
        var newXML         = ""
        var newXML_trimmed = ""
        let f_regexComp = try! NSRegularExpression(pattern: "<\(theTag)>(.|\n|\r)*?</\(theTag)>", options:.caseInsensitive)
        if keepTags {
            newXML = f_regexComp.stringByReplacingMatches(in: theXML, options: [], range: NSRange(0..<theXML.utf16.count), withTemplate: "<\(theTag)/>")
        } else {
            newXML = f_regexComp.stringByReplacingMatches(in: theXML, options: [], range: NSRange(0..<theXML.utf16.count), withTemplate: "")
        }

        // prevent removing blank lines from scripts
        if (theTag == "script_contents_encoded") || (theTag == "id") {
            newXML_trimmed = newXML
        } else {
//            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "Removing blank lines.") }
            newXML_trimmed = newXML.replacingOccurrences(of: "\n\n", with: "")
            newXML_trimmed = newXML.replacingOccurrences(of: "\r\r", with: "\r")
        }
        return newXML_trimmed
    }
    
    func stopButton(_ sender: Any) {
        getArray.removeAll()
        createArray.removeAll()
        objectsToMigrate.removeAll()
        getEndpointsQ.cancelAllOperations()
        endpointsIdQ.cancelAllOperations()
        theCreateQ.cancelAllOperations()
        theIconsQ.cancelAllOperations()
        readFilesQ.cancelAllOperations()
        
        XmlDelegate().getRecordQ.cancelAllOperations()
        
        if setting.fullGUI {
            WriteToLog.shared.message(stringOfText: "Migration was manually stopped.\n")
            pref.stopMigration = true

            goButtonEnabled(button_status: true)
        } else {
            WriteToLog.shared.message(stringOfText: "Migration was stopped due to an issue.\n")
        }
    }
    
    func setLevelIndicatorFillColor(fn: String, endpointType: String, fillColor: NSColor) {
//        print("set levelIndicator from \(fn), endpointType: \(endpointType), color: \(fillColor)")
        if setting.fullGUI {
            DispatchQueue.main.async { [self] in
                if put_levelIndicator.fillColor == .green || /*put_levelIndicatorFillColor[endpointType]*/PutLevelIndicator.shared.indicatorColor[endpointType] == .systemRed {
                    /*put_levelIndicatorFillColor[endpointType]*/PutLevelIndicator.shared.indicatorColor[endpointType] = fillColor
                    put_levelIndicator.fillColor = PutLevelIndicator.shared.indicatorColor[endpointType]/*put_levelIndicatorFillColor[endpointType]*/
                }
            }
        }
    }
    
    func setSite(xmlString:String, site:String, endpoint:String) -> String {
        var rawValue = ""
        var startTag = ""
        let siteEncoded = XmlDelegate().encodeSpecialChars(textString: site)
        
        // get copy / move preference - start
        switch endpoint {
        case "computergroups", "smartcomputergroups", "staticcomputergroups", "mobiledevicegroups", "smartmobiledevicegroups", "staticmobiledevicegroups":
            sitePref = userDefaults.string(forKey: "siteGroupsAction") ?? "Copy"
            
        case "policies":
            sitePref = userDefaults.string(forKey: "sitePoliciesAction") ?? "Copy"
            
        case "osxconfigurationprofiles", "mobiledeviceconfigurationprofiles":
            sitePref = userDefaults.string(forKey: "siteProfilesAction") ?? "Copy"
            
        case "computers","mobiledevices":
            sitePref = "Move"
            
        default:
            sitePref = "Copy"
        }
        
        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[siteSet] site operation for \(endpoint): \(sitePref)") }
        // get copy / move preference - end
        
        switch endpoint {
        case "computergroups", "smartcomputergroups", "staticcomputergroups":
            rawValue = tagValue2(xmlString: xmlString, startTag: "<computer_group>", endTag: "</computer_group>")
            startTag = "computer_group"
            
        case "mobiledevicegroups", "smartmobiledevicegroups", "staticmobiledevicegroups":
            rawValue = tagValue2(xmlString: xmlString, startTag: "<mobile_device_group>", endTag: "</mobile_device_group>")
            startTag = "mobile_device_group"
            
        default:
            rawValue = tagValue2(xmlString: xmlString, startTag: "<general>", endTag: "</general>")
            startTag = "general"
        }
        let itemName = tagValue2(xmlString: rawValue, startTag: "<name>", endTag: "</name>")
        
        // update site
        //WriteToLog.shared.message(stringOfText: "[siteSet] endpoint \(endpoint) to site \(siteEncoded)")
        if endpoint != "users" {
            let siteInfo = tagValue2(xmlString: xmlString, startTag: "<site>", endTag: "</site>")
            let currentSiteName = tagValue2(xmlString: siteInfo, startTag: "<name>", endTag: "</name>")
            rawValue = xmlString.replacingOccurrences(of: "<site><name>\(currentSiteName)</name></site>", with: "<site><name>\(siteEncoded)</name></site>")
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[siteSet] changing site from \(currentSiteName) to \(siteEncoded)") }
        } else {
            // remove current sites info
            rawValue = self.rmXmlData(theXML: xmlString, theTag: "sites", keepTags: true)

//            let siteInfo = tagValue2(xmlString: xmlString, startTag: "<sites>", endTag: "</sites>")
            if siteEncoded != "None" {
                rawValue = xmlString.replacingOccurrences(of: "<sites></sites>", with: "<sites><site><name>\(siteEncoded)</name></site></sites>")
                rawValue = xmlString.replacingOccurrences(of: "<sites/>", with: "<sites><site><name>\(siteEncoded)</name></site></sites>")
            }
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[siteSet] changing site to \(siteEncoded)") }
        }
        
        // do not redeploy profile to existing scope
        if endpoint == "osxconfigurationprofiles" || endpoint == "mobiledeviceconfigurationprofiles" {
            let regexComp = try! NSRegularExpression(pattern: "<redeploy_on_update>(.*?)</redeploy_on_update>", options:.caseInsensitive)
            rawValue = regexComp.stringByReplacingMatches(in: rawValue, options: [], range: NSRange(0..<rawValue.utf16.count), withTemplate: "<redeploy_on_update>Newly Assigned</redeploy_on_update>")
        }
        
        if sitePref == "Copy" && endpoint != "users" && endpoint != "computers" {
            // update item Name - ...<name>currentName - site</name>
            rawValue = rawValue.replacingOccurrences(of: "<\(startTag)><name>\(itemName)</name>", with: "<\(startTag)><name>\(itemName) - \(siteEncoded)</name>")
//            print("[setSite]  rawValue: \(rawValue)")
            
            // generate a new uuid for configuration profiles - start -- needed?  New profiles automatically get new UUID?
            if endpoint == "osxconfigurationprofiles" || endpoint == "mobiledeviceconfigurationprofiles" {
                let profileGeneral = tagValue2(xmlString: xmlString, startTag: "<general>", endTag: "</general>")
                let payloadUuid    = tagValue2(xmlString: profileGeneral, startTag: "<uuid>", endTag: "</uuid>")
                let newUuid        = UUID().uuidString
                
                rawValue = rawValue.replacingOccurrences(of: payloadUuid, with: newUuid)
//                print("[setSite] rawValue2: \(rawValue)")
            }
            // generate a new uuid for configuration profiles - end
            
            // update scope - start
            rawValue = rawValue.replacingOccurrences(of: "><", with: ">\n<")
            let rawValueArray = rawValue.split(separator: "")
            rawValue = ""
            var currentLine = 0
            let numberOfLines = rawValueArray.count
            while true {
                rawValue.append("\(rawValueArray[currentLine])")
                if currentLine+1 < numberOfLines {
                    currentLine+=1
                } else {
                    break
                }
                if rawValueArray[currentLine].contains("<scope>") {
                    while !rawValueArray[currentLine].contains("</scope>") {
                        if rawValueArray[currentLine].contains("<computer_group>") || rawValueArray[currentLine].contains("<mobile_device_group>") {
                            rawValue.append("\(rawValueArray[currentLine])")
                            if currentLine+1 < numberOfLines {
                                currentLine+=1
                            } else {
                                break
                            }
                            let siteGroupName = rawValueArray[currentLine].replacingOccurrences(of: "</name>", with: " - \(siteEncoded)</name>")
                            
                            //                print("siteGroupName: \(siteGroupName)")
                            
                            rawValue.append("\(siteGroupName)")
                            if currentLine+1 < numberOfLines {
                                currentLine+=1
                            } else {
                                break
                            }
                        } else {  // if rawValueArray[currentLine].contains("<computer_group>") - end
                            rawValue.append("\(rawValueArray[currentLine])")
                            if currentLine+1 < numberOfLines {
                                currentLine+=1
                            } else {
                                break
                            }
                        }
                    }   // while !rawValueArray[currentLine].contains("</scope>")
                }   // if rawValueArray[currentLine].contains("<scope>")
            }   // while true - end
            // update scope - end
        }   // if sitePref - end
                
        return rawValue
    }
    
    func myExitValue(cmd: String, args: String...) -> String {
        var theCmdArray  = [String]()
        var theCmd       = ""
        var status       = "unknown"
        var statusArray  = [String]()
        let pipe         = Pipe()
        let task         = Process()
        
        task.launchPath     = cmd
        task.arguments      = args
        task.standardOutput = pipe

        task.launch()
        
        let outdata = pipe.fileHandleForReading.readDataToEndOfFile()
        if var string = String(data: outdata, encoding: .utf8) {
            string = string.trimmingCharacters(in: .newlines)
            if args.count > 1 {
                theCmdArray = args[1].components(separatedBy: " ")
                if theCmdArray.count > 0 {
                    theCmd = theCmdArray[0]
                }
            }
            if theCmd == "/usr/bin/curl" {
                status = string
            } else {
                statusArray = string.components(separatedBy: "")
                status = statusArray[0]
            }
        }
        
        task.waitUntilExit()
        
        return(status)
    }
    
    func resetAllCheckboxes() {
        DispatchQueue.main.async {
        // Sellect all items to be migrated
            // macOS tab
            self.advcompsearch_button.state = NSControl.StateValue(rawValue: 0)
            self.macapplications_button.state = NSControl.StateValue(rawValue: 0)
            self.computers_button.state = NSControl.StateValue(rawValue: 0)
            self.directory_bindings_button.state = NSControl.StateValue(rawValue: 0)
            self.disk_encryptions_button.state = NSControl.StateValue(rawValue: 0)
            self.dock_items_button.state = NSControl.StateValue(rawValue: 0)
//            self.netboot_button.state = NSControl.StateValue(rawValue: 0)
            self.osxconfigurationprofiles_button.state = NSControl.StateValue(rawValue: 0)
    //        patch_mgmt_button.state = 1
            self.patch_policies_button.state = NSControl.StateValue(rawValue: 0)
            self.sus_button.state = NSControl.StateValue(rawValue: 0)
            self.fileshares_button.state = NSControl.StateValue(rawValue: 0)
            self.ext_attribs_button.state = NSControl.StateValue(rawValue: 0)
            self.smart_comp_grps_button.state = NSControl.StateValue(rawValue: 0)
            self.static_comp_grps_button.state = NSControl.StateValue(rawValue: 0)
            self.scripts_button.state = NSControl.StateValue(rawValue: 0)
            self.packages_button.state = NSControl.StateValue(rawValue: 0)
            self.policies_button.state = NSControl.StateValue(rawValue: 0)
            self.printers_button.state = NSControl.StateValue(rawValue: 0)
            self.restrictedsoftware_button.state = NSControl.StateValue(rawValue: 0)
            self.macPrestages_button.state = NSControl.StateValue(rawValue: 0)
            // iOS tab
            self.advancedmobiledevicesearches_button.state = NSControl.StateValue(rawValue: 0)
            self.mobiledevicecApps_button.state = NSControl.StateValue(rawValue: 0)
            self.mobiledevices_button.state = NSControl.StateValue(rawValue: 0)
            self.smart_ios_groups_button.state = NSControl.StateValue(rawValue: 0)
            self.static_ios_groups_button.state = NSControl.StateValue(rawValue: 0)
            self.mobiledeviceconfigurationprofiles_button.state = NSControl.StateValue(rawValue: 0)
            self.mobiledeviceextensionattributes_button.state = NSControl.StateValue(rawValue: 0)
            self.iosPrestages_button.state = NSControl.StateValue(rawValue: 0)
            // general tab
            self.advusersearch_button.state = NSControl.StateValue(rawValue: 0)
            self.building_button.state = NSControl.StateValue(rawValue: 0)
            self.categories_button.state = NSControl.StateValue(rawValue: 0)
            self.classes_button.state = NSControl.StateValue(rawValue: 0)
            self.dept_button.state = NSControl.StateValue(rawValue: 0)
            self.userEA_button.state = NSControl.StateValue(rawValue: 0)
            self.sites_button.state = NSControl.StateValue(rawValue: 0)
            self.ldapservers_button.state = NSControl.StateValue(rawValue: 0)
            self.networks_button.state = NSControl.StateValue(rawValue: 0)
            self.users_button.state = NSControl.StateValue(rawValue: 0)
            self.jamfUserAccounts_button.state = NSControl.StateValue(rawValue: 0)
            self.jamfGroupAccounts_button.state = NSControl.StateValue(rawValue: 0)
            self.smartUserGrps_button.state = NSControl.StateValue(rawValue: 0)
            self.staticUserGrps_button.state = NSControl.StateValue(rawValue: 0)
        }
    }
    
    func setConcurrentThreads() {
        maxConcurrentThreads = (userDefaults.integer(forKey: "concurrentThreads") < 1) ? 2:userDefaults.integer(forKey: "concurrentThreads")
//        print("[ViewController] ConcurrentThreads: \(concurrent)")
        maxConcurrentThreads = (maxConcurrentThreads > 5) ? 2:maxConcurrentThreads
        userDefaults.set(maxConcurrentThreads, forKey: "concurrentThreads")
    }
    
    // add notification - run fn in SourceDestVC
    func updateServerArray(url: String, serverList: String, theArray: [String]) {
        switch serverList {
        case "source_server_array":
            NotificationCenter.default.post(name: .updateSourceServerList, object: self)
        case "dest_server_array":
            NotificationCenter.default.post(name: .updateDestServerList, object: self)
        default:
            break
        }
    }
    
   
    func windowIsVisible(windowName: String) -> Bool {
        let options = CGWindowListOption(arrayLiteral: CGWindowListOption.excludeDesktopElements, CGWindowListOption.optionOnScreenOnly)
        let windowListInfo = CGWindowListCopyWindowInfo(options, CGWindowID(0))
        let infoList = windowListInfo as NSArray? as? [[String: AnyObject]]
        for item in infoList! {
            if let _ = item["kCGWindowOwnerName"], let _ = item["kCGWindowName"] {
                if "\(item["kCGWindowOwnerName"]!)" == "jamf-migrator" && "\(item["kCGWindowName"]!)" == windowName {
                    return true
                }
            }
        }
        return false
    }
    
    func zipIt(args: String..., completion: @escaping (_ result: String) -> Void) {

        var cmdArgs = ["-c"]
        for theArg in args {
            cmdArgs.append(theArg)
        }
        var status  = ""
        var statusArray  = [String]()
        let pipe    = Pipe()
        let task    = Process()
        
        task.launchPath     = "/bin/sh"
        task.arguments      = cmdArgs
        task.standardOutput = pipe
        
        task.launch()
        
        let outdata = pipe.fileHandleForReading.readDataToEndOfFile()
        if var string = String(data: outdata, encoding: .utf8) {
            string = string.trimmingCharacters(in: .newlines)
            statusArray = string.components(separatedBy: "")
            status = statusArray[0]
        }
        
        task.waitUntilExit()
        completion(status)
    }
    
    func tabView(_ tabView: NSTabView, didSelect: NSTabViewItem?) {
        userDefaults.set("\(didSelect!.label)", forKey: "activeTab")
    }
    
    // selective migration functions - start
    func numberOfRows(in tableView: NSTableView) -> Int
    {
        var numberOfRows:Int = 0;
        if (tableView == srcSrvTableView)
        {
            numberOfRows = sourceDataArray.count
        }
        
        return numberOfRows
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
//  func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
    //        print("tableView: \(tableView)\t\ttableColumn: \(tableColumn)\t\trow: \(row)")
        var newString:String = ""
        if (tableView == srcSrvTableView) && row < sourceDataArray.count
        {
            if row < sourceDataArray.count {
                newString = sourceDataArray[row]
            } else {
                newString = sourceDataArray.last ?? ""
            }
        }
//      rowView.wantsLayer = true
//            rowView.backgroundColor = (row % 2 == 0)
//                ? NSColor(calibratedRed: 0x6F/255.0, green: 0x8E/255.0, blue: 0x9D/255.0, alpha: 0xFF/255.0)
//                : NSColor(calibratedRed: 0x8C/255.0, green: 0xB5/255.0, blue: 0xC8/255.0, alpha: 0xFF/255.0)

        return newString;
    }
    // selective migration functions - end

    override func viewDidAppear() {
        // display app version
        appVersion_TextField.stringValue = "v\(AppInfo.version)"
        
//        let def_plist = Bundle.main.path(forResource: "settings", ofType: "plist")!
        var isDir: ObjCBool = true
        
        // Create Application Support folder for the app if missing - start
        let app_support_path = NSHomeDirectory() + "/Library/Application Support/jamf-migrator"
        if !(fm.fileExists(atPath: app_support_path, isDirectory: &isDir)) {
//            let manager = FileManager.default
            do {
                try fm.createDirectory(atPath: app_support_path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "Problem creating '/Library/Application Support/jamf-migrator' folder:  \(error)") }
            }
        }
        // Create Application Support folder for the app if missing - end
        
        // read stored values from plist, if it exists
        initVars()
        
    }   //viewDidAppear - end

    @objc func setColorScheme_VC(_ notification: Notification) {
        
            let whichColorScheme = userDefaults.string(forKey: "colorScheme") ?? ""
            if AppColor.schemes.firstIndex(of: whichColorScheme) != nil {
                self.view.wantsLayer = true
                selectiveFilter_TextField.drawsBackground = true
                selectiveFilter_TextField.backgroundColor = AppColor.highlight[whichColorScheme]
                self.view.layer?.backgroundColor          = AppColor.background[whichColorScheme]
                srcSrvTableView.backgroundColor           = AppColor.highlight[whichColorScheme]!
                srcSrvTableView.usesAlternatingRowBackgroundColors = false
            }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        PatchDelegate.shared.messageDelegate = self
//        PatchDelegate.shared.updateViewController("")
        
        srcSrvTableView.delegate = self
        srcSrvTableView.tableColumns.forEach { (column) in
            column.headerCell.attributedStringValue = NSAttributedString(string: column.title, attributes: [NSAttributedString.Key.font: NSFont.boldSystemFont(ofSize: 14)])
        }
        
        /* test data for selective migration
        let testObjects = SelectiveObjectList(objectName: "iPad", objectId: "iPad-16.xml")
        sourceObjectList_AC.addObject(testObjects)
        let testObjects2 = SelectiveObjectList(objectName: "iPad", objectId: "iPad-77.xml")
        sourceObjectList_AC.addObject(testObjects2)
         */
        
        // Do any additional setup after loading the view.
        NotificationCenter.default.addObserver(self, selector: #selector(setColorScheme_VC(_:)), name: .setColorScheme_VC, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resetListFields(_:)), name: .resetListFields, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showSummaryWindow(_:)), name: .showSummaryWindow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showLogFolder(_:)), name: .showLogFolder, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deleteMode(_:)), name: .deleteMode, object: nil)
        
        NotificationCenter.default.post(name: .setColorScheme_VC, object: self)
        
//        jamfpro = JamfPro(controller: self)
        
        exportedFilesUrl = URL(string: userDefaults.string(forKey: "saveLocation") ?? "")
        
        // read maxConcurrentOperationCount setting
        setConcurrentThreads()

        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "----- Debug Mode -----") }
        
        if !hideGui {
            
            activeTab_TabView.delegate           = self
            
            selectiveFilter_TextField.delegate   = self
            selectiveFilter_TextField.wantsLayer = true
            selectiveFilter_TextField.isBordered = true
            selectiveFilter_TextField.layer?.borderWidth  = 0.5
            selectiveFilter_TextField.layer?.cornerRadius = 0.0
            selectiveFilter_TextField.layer?.borderColor  = .black
            
            
//            siteMigrate_button.attributedTitle = NSMutableAttributedString(string: "Site", attributes: [NSAttributedString.Key.foregroundColor: NSColor.white, NSAttributedString.Key.font: NSFont.systemFont(ofSize: 14)])

            let whichTab = userDefaults.object(forKey: "activeTab") as? String ?? "General"
            setTab_fn(selectedTab: whichTab)
        
            // Set all checkboxes off
            resetAllCheckboxes()
            
            go_button.isEnabled = true
            
            // bring app to foreground
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }   //override func viewDidLoad() - end
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    override func viewDidDisappear() {
        // Insert code here to tear down your application
        _ = readSettings()
        saveSettings(settings: AppInfo.settings)
        WriteToLog.shared.logCleanup()
    }
    
    func initVars() {
        
        if setting.fullGUI {
            setting.onlyCopyMissing  = (userDefaults.integer(forKey: "copyMissing")  == 1) ? true:false
            setting.onlyCopyExisting = (userDefaults.integer(forKey: "copyExisting") == 1) ? true:false
            
            if !FileManager.default.fileExists(atPath: AppInfo.plistPath) {
                do {
                    try FileManager.default.copyItem(atPath: Bundle.main.path(forResource: "settings", ofType: "plist")!, toPath: AppInfo.plistPath)
                    WriteToLog.shared.message(stringOfText: "[ViewController] Created default setting from  \(Bundle.main.path(forResource: "settings", ofType: "plist")!)")
                } catch {
                    WriteToLog.shared.message(stringOfText: "[ViewController] Unable to find/create \(AppInfo.plistPath)")
                    WriteToLog.shared.message(stringOfText: "[ViewController] Try to manually copy the file from path_to/jamf-migrator.app/Contents/Resources/settings.plist to \(AppInfo.plistPath)")
                    NSApplication.shared.terminate(self)
                }
            }
            
            
            // read environment settings from plist - start
            _ = readSettings()

            // read scope settings - start
            if AppInfo.settings["scope"] != nil {
                scopeOptions = AppInfo.settings["scope"] as! [String:[String: Bool]]

                if scopeOptions["mobiledeviceconfigurationprofiles"]!["copy"] != nil {
                    scopeMcpCopy = scopeOptions["mobiledeviceconfigurationprofiles"]!["copy"]!
                }
                if self.scopeOptions["macapps"] != nil {
                    if self.scopeOptions["macapps"]!["copy"] != nil {
                        self.scopeMaCopy = self.scopeOptions["macapps"]!["copy"]!
                    } else {
                        self.scopeMaCopy = true
                    }
                } else {
                    self.scopeMaCopy = true
                }
                if scopeOptions["policies"]!["copy"] != nil {
                    scopePoliciesCopy = scopeOptions["policies"]!["copy"]!
                }
                if scopeOptions["policies"]!["disable"] != nil {
                    policyPoliciesDisable = scopeOptions["policies"]!["disable"]!
                }
                if scopeOptions["osxconfigurationprofiles"]!["copy"] != nil {
                    scopeOcpCopy = scopeOptions["osxconfigurationprofiles"]!["copy"]!
                }
                if scopeOptions["restrictedsoftware"]!["copy"] != nil {
                    scopeRsCopy = scopeOptions["restrictedsoftware"]!["copy"]!
                }
                if self.scopeOptions["iosapps"] != nil {
                    if self.scopeOptions["iosapps"]!["copy"] != nil {
                        self.scopeIaCopy = self.scopeOptions["iosapps"]!["copy"]!
                    } else {
                        self.scopeIaCopy = true
                    }
                } else {
                    self.scopeIaCopy = true
                }
            } else {
                // reset/initialize new settings
                _ = readSettings()
                AppInfo.settings["scope"] = ["osxconfigurationprofiles":["copy":true],
                                      "macapps":["copy":true],
                                      "policies":["copy":true,"disable":false],
                                      "restrictedsoftware":["copy":true],
                                      "mobiledeviceconfigurationprofiles":["copy":true],
                                      "iosapps":["copy":true],
                                      "scg":["copy":true],
                                      "sig":["copy":true],
                                      "users":["copy":true]] as Any
                
                NSDictionary(dictionary: AppInfo.settings).write(toFile: AppInfo.plistPath, atomically: true)
            }
            // read scope settings - end
            
            if scopeOptions["scg"] != nil && scopeOptions["sig"] != nil && scopeOptions["users"] != nil  {

                if (scopeOptions["scg"]!["copy"] != nil) {
                    scopeScgCopy = scopeOptions["scg"]!["copy"]!
                } else {
                    scopeScgCopy                  = true
                    scopeOptions["scg"]!["copy"] = scopeScgCopy
                }

                if (scopeOptions["sig"]!["copy"] != nil) {
                    scopeSigCopy = scopeOptions["sig"]!["copy"]!
                } else {
                    scopeSigCopy                  = true
                    scopeOptions["sig"]!["copy"] = scopeSigCopy
                }

                if (scopeOptions["sig"]!["users"] != nil) {
                    scopeUsersCopy = scopeOptions["sig"]!["users"]!
                } else {
                    scopeUsersCopy                 = true
                    scopeOptions["sig"]!["users"] = scopeUsersCopy
                }
            } else {
                // reset/initialize scope preferences
                _ = readSettings()
                AppInfo.settings["scope"] = ["osxconfigurationprofiles":["copy":true],
                                      "macapps":["copy":true],
                                      "policies":["copy":true,"disable":false],
                                      "restrictedsoftware":["copy":true],
                                      "mobiledeviceconfigurationprofiles":["copy":true],
                                      "iosapps":["copy":true],
                                      "scg":["copy":true],
                                      "sig":["copy":true],
                                      "users":["copy":true]] as Any
            }
            
            // read xml settings - start
            if AppInfo.settings["xml"] != nil {
                xmlPrefOptions       = AppInfo.settings["xml"] as! Dictionary<String,Bool>

                if (xmlPrefOptions["saveRawXml"] != nil) {
                    export.saveRawXml = xmlPrefOptions["saveRawXml"]!
                } else {
                    export.saveRawXml                   = false
                    xmlPrefOptions["saveRawXml"] = export.saveRawXml
                }
                
                if (xmlPrefOptions["saveTrimmedXml"] != nil) {
                    export.saveTrimmedXml = xmlPrefOptions["saveTrimmedXml"]!
                } else {
                    export.saveTrimmedXml                   = false
                    xmlPrefOptions["saveTrimmedXml"] = export.saveTrimmedXml
                }

                if (xmlPrefOptions["saveOnly"] != nil) {
                    export.saveOnly = xmlPrefOptions["saveOnly"]!
                } else {
                    export.saveOnly                   = false
                    xmlPrefOptions["saveOnly"] = export.saveOnly
                }
//                disableSource()
                
                if xmlPrefOptions["saveRawXmlScope"] == nil {
                    xmlPrefOptions["saveRawXmlScope"] = true
                    saveRawXmlScope = true
                }
                if xmlPrefOptions["saveTrimmedXmlScope"] == nil {
                    xmlPrefOptions["saveTrimmedXmlScope"] = true
                    saveTrimmedXmlScope = true
                }
            } else {
                // set default values
                _ = readSettings()
                AppInfo.settings["xml"] = ["saveRawXml":false,
                                    "saveTrimmedXml":false,
                                    "export.saveOnly":false,
                                    "saveRawXmlScope":true,
                                    "saveTrimmedXmlScope":true] as Any
            }
            // update plist
            NSDictionary(dictionary: AppInfo.settings).write(toFile: AppInfo.plistPath, atomically: true)
            // read xml settings - end
            // read environment settings - end
            
            // see if we last migrated from files or a server
            // no need to backup local files, add later?
//            _ = serverOrFiles()
        } else {
            didRun = true
            
            scopeOcpCopy          = setting.copyScope   // osxconfigurationprofiles copy scope
            scopeMaCopy           = setting.copyScope   // macapps copy scope
            scopeRsCopy           = setting.copyScope   // restrictedsoftware copy scope
            scopePoliciesCopy     = setting.copyScope   // policies copy scope
//            policyPoliciesDisable = setting.copyScope  // policies disable on copy
            scopeMcpCopy          = setting.copyScope   // mobileconfigurationprofiles copy scope
            scopeIaCopy           = setting.copyScope   // iOSapps copy scope
            scopeScgCopy          = setting.copyScope   // static computer groups copy scope
            scopeSigCopy          = setting.copyScope   // static iOS device groups copy scope
            scopeUsersCopy        = setting.copyScope   // static user groups copy scope
            
        }
        
        let appVersion = AppInfo.version
        let appBuild   = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
        WriteToLog.shared.message(stringOfText: "\(AppInfo.name) Version: \(appVersion) Build: \(appBuild )")
        
        if !setting.fullGUI {
            WriteToLog.shared.message(stringOfText: "Running silently")
            Go(sender: "silent")
        }
    }
    
    @objc func resetListFields(_ notification: Notification) {
        if (JamfProServer.whichServer == "source" && !wipeData.on) || (JamfProServer.whichServer == "dest" && !export.saveOnly) || (srcSrvTableView.isEnabled == false) {
            srcSrvTableView.isEnabled = true
            selectiveListCleared      = false
            clearSelectiveList()
            clearSourceObjectsList()
            clearProcessingFields()
        }
        JamfProServer.version[JamfProServer.whichServer]    = ""
        JamfProServer.validToken[JamfProServer.whichServer] = false
    }
    // Log Folder - start
    @objc func showLogFolder(_ notification: Notification) {
        isDir = true
        if (fm.fileExists(atPath: logPath!, isDirectory: &isDir)) {
//            NSWorkspace.shared.openFile(logPath!)
            NSWorkspace.shared.open(URL(fileURLWithPath: logPath!))
        } else {
            alert_dialog(header: "Alert", message: "There are currently no log files to display.")
        }
    }
    // Log Folder - end
    // Summary Window - start
    @objc func showSummaryWindow(_ notification: Notification) {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let summaryWindowController = storyboard.instantiateController(withIdentifier: "Summary Window Controller") as! NSWindowController
        if let summaryWindow = summaryWindowController.window {
            let summaryViewController = summaryWindow.contentViewController as! SummaryViewController
            
            URLCache.shared.removeAllCachedResponses()
            summaryViewController.summary_WebView.loadHTMLString(summaryXml(theSummary: counters, theSummaryDetail: summaryDict), baseURL: nil)
            
            let application = NSApplication.shared
            application.runModal(for: summaryWindow)
            summaryWindow.close()
        }
    }
    // Summary Window - end
    
    @objc func deleteMode(_ notification: Notification) {
        var isDir: ObjCBool = false
//        var isRed           = false

        resetAllCheckboxes()
        clearProcessingFields()
        if srcSrvTableView.isEnabled {
            self.generalSectionToMigrate_button.selectItem(at: 0)
            self.sectionToMigrate_button.selectItem(at: 0)
            self.iOSsectionToMigrate_button.selectItem(at: 0)
            self.selectiveFilter_TextField.stringValue = ""
        }
        
        DispatchQueue.main.async {
            self.clearSelectiveList()
        }
        JamfProServer.validToken["source"] = false
        JamfProServer.validToken["dest"]   = false
        
        if (fm.fileExists(atPath: NSHomeDirectory() + "/Library/Application Support/jamf-migrator/DELETE", isDirectory: &isDir)) {
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "Disabling delete mode") }
            do {
                try fm.removeItem(atPath: NSHomeDirectory() + "/Library/Application Support/jamf-migrator/DELETE")
                sourceDataArray.removeAll()
                srcSrvTableView.stringValue = ""
                srcSrvTableView.reloadData()
                selectiveListCleared = true
                
                clearSourceObjectsList()
                
//                _ = serverOrFiles()
                
                NotificationCenter.default.post(name: .deleteMode_sdvc, object: self)
                
                DispatchQueue.main.async { [self] in
                    migrateOrRemove_TextField.stringValue = "Migrate"
//                    migrateOrRemove_TextField.textColor = self.whiteText
                    destinationMethod_TextField.stringValue = "SEND:"
                    go_button.title = "Go!"
                    go_button.bezelColor = nil
                    selectiveTabelHeader_textview.stringValue = "Select object(s) to migrate"
                }
                wipeData.on = false
            } catch let error as NSError {
                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "Unable to delete file! Something went wrong: \(error)") }
            }
        } else {
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "Enabling delete mode to removing data from destination server - \(JamfProServer.destination)") }
            fm.createFile(atPath: NSHomeDirectory() + "/Library/Application Support/jamf-migrator/DELETE", contents: nil)
            
            NotificationCenter.default.post(name: .deleteMode_sdvc, object: self)

            DispatchQueue.main.async { [self] in
                wipeData.on = true
                selectiveTabelHeader_textview.stringValue = "Select object(s) to remove from the destination"
                setting.migrateDependencies        = false
                migrateDependencies.state     = NSControl.StateValue(rawValue: 0)
                migrateDependencies.isHidden  = true
                if srcSrvTableView.isEnabled {
                    sourceDataArray.removeAll()
                    srcSrvTableView.stringValue = ""
                    srcSrvTableView.reloadData()
                    selectiveListCleared = true
                    
                    clearSourceObjectsList()
                }
                // Set the text for the operation
                migrateOrRemove_TextField.stringValue = "--- Removing ---"
                // Set the text for destination method
                destinationMethod_TextField.stringValue = "DELETE:"
                                
                go_button.title = "Delete"
                go_button.bezelColor = NSColor.systemRed
                
                theModeQ.async { [self] in
                    while true {
                        if !(fm.fileExists(atPath: NSHomeDirectory() + "/Library/Application Support/jamf-migrator/DELETE", isDirectory: &isDir)) {
                            DispatchQueue.main.async { [self] in
                                NotificationCenter.default.post(name: .deleteMode_sdvc, object: self)
                                migrateOrRemove_TextField.stringValue = "Migrate"
                                destinationMethod_TextField.stringValue = "SEND:"
                            }
                            break
                        }
                        
                        usleep(500000)  // 0.5 seconds
                    }

                }
                
            }   // DispatchQueue.main.async - end
            
            
        }
    }
    
    func summaryXml(theSummary: [String: [String:Int]], theSummaryDetail: [String: [String:[String]]]) -> String {
        var cellDetails = ""
        var summaryResult = "<!DOCTYPE html>" +
            "<html>" +
            "<head>" +
            "<style>" +
            "body { background-color: #5C7894; }" +
            "div div {" +
//                "width: 110px;" +
                "height: 100%;" +
                "overflow-x: auto;" +
                "overflow-y: auto;" +
            "}" +
            ".button {" +
                "font-size: 1em;" +
                "padding: 2px;" +
                "color: #fff;" +
                "border: 0px solid #06D85F;" +
                "text-decoration: none;" +
                "cursor: pointer;" +
                "transition: all 0.3s ease-out;" +
            "}" +
            ".button:hover {" +
                "color: greenyellow;" +
            "}" +
            ".overlay {" +
                "position: fixed;" +
                "top: 0;" +
                "bottom: 0;" +
                "left: 0;" +
                "right: 0;" +
                "background: #5C7894;" +
                "transition: opacity 500ms;" +
                "visibility: hidden;" +
                "opacity: 0;" +
            "}" +
            ".overlay:target {" +
                "visibility: visible;" +
                "opacity: 1;" +
            "}" +
            ".popup {" +
            "font-size: 18px;" +
                "margin: 15px auto;" +
                "padding: 5px;" +
            "background: #E7E7E7;" +
                "border-radius: 5px;" +
                "max-width: 60%;" +
                "position: relative;" +
            "transition: all 5s ease-in-out;" +
            "}" +
            ".popup .close {" +
                "position: absolute;" +
                "top: 5px;" +
                "left: 5px;" +
                "transition: all 200ms;" +
                "font-size: 20px;" +
                "font-weight: bold;" +
                "text-decoration: none;" +
                "color: #0B5876;" +
            "overflow-x: auto;" +
            "overflow-y: auto;" +
            "}" +
            ".popup .close:hover {" +
                "color: #E64E59;" +
            "}" +
        ".popup .content {" +
        "background: #E9E9E9;" +
                "font-size: 14px;" +
        "max-height: 100%;" +
//        "max-height: 190px;" +
            "}" +
            "tr:nth-child(even) {background-color: #607E9B;}" +
            "</style>" +
            "</head>" +
        "<body>"
        var endpointSummary = ""
        var createIndex = 1
        var updateIndex = 0
        var failIndex = 0
        
        
        if theSummary.count > 0 {
            var sortedObjectsArray = [String]()
            for (theObject, _) in theSummary {
                sortedObjectsArray.append(theObject)
            }
            sortedObjectsArray = sortedObjectsArray.sorted()
            for key in sortedObjectsArray {
                
                let values = theSummary[key]!
                if key != "computergroups" && key != "mobiledevicegroups" && key != "usergroups" {
                    var createHtml = ""
                    var updateHtml = ""
                    var failHtml = ""
                    if let summaryCreateArray = theSummaryDetail[key]?["create"] {
                        for name in summaryCreateArray.sorted(by: {$0.caseInsensitiveCompare($1) == .orderedAscending}) {
                            createHtml.append("• " + name + "<br>")
                        }
                    }
                    updateIndex = createIndex + 1
                    if let summaryUpdateArray = theSummaryDetail[key]?["update"] {
                        for name in summaryUpdateArray.sorted(by: {$0.caseInsensitiveCompare($1) == .orderedAscending}) {
                            updateHtml.append("• " + name + "<br>")
                        }
                    }
                    failIndex = createIndex + 2
                    if let summaryFailArray = theSummaryDetail[key]?["fail"] {
                        for name in summaryFailArray.sorted(by: {$0.caseInsensitiveCompare($1) == .orderedAscending}) {
                            failHtml.append("• " + name + "<br>")
                        }
                    }
                    createIndex += 3
                    
                    endpointSummary.append("<tr>")
                    endpointSummary.append("<td style='text-align:right; width: 35%;'>\(String(describing: key))</td>")
                    endpointSummary.append("<td style='text-align:right; width: 20%;'><a class='button' href='#\(createIndex)'>\(values["create"] ?? 0)</a></td>")
                    endpointSummary.append("<td style='text-align:right; width: 20%;'><a class='button' href='#\(updateIndex)'>\(values["update"] ?? 0)</a></td>")
                    endpointSummary.append("<td style='text-align:right; width: 20%;'><a class='button' href='#\(failIndex)'>\(values["fail"] ?? 0)</a></td>")
                    endpointSummary.append("</tr>")
                    cellDetails.append(popUpHtml(id: createIndex, column: "\(String(describing: key)) \(summaryHeader.createDelete)d", values: createHtml))
                    cellDetails.append(popUpHtml(id: updateIndex, column: "\(String(describing: key)) Updated", values: updateHtml))
                    cellDetails.append(popUpHtml(id: failIndex, column: "\(String(describing: key)) Failed", values: failHtml))
                }
            }
            summaryResult.append("<table style='table-layout:fixed; border-collapse: collapse; margin-left: auto; margin-right: auto; width: 95%;'>" +
            "<tr>" +
                "<th style='text-align:right; width: 35%;'>Endpoint</th>" +
                "<th style='text-align:right; width: 20%;'>\(summaryHeader.createDelete)d</th>" +
                "<th style='text-align:right; width: 20%;'>Updated</th>" +
                "<th style='text-align:right; width: 20%;'>Failed</th>" +
            "</tr>" +
                endpointSummary +
            "</table>" +
            cellDetails)
        } else {
            summaryResult.append("<p>No Results")
        }
        
        summaryResult.append("</body></html>")
        return summaryResult
    }
    // code for pop up window - start
    func popUpHtml (id: Int, column: String, values: String) -> String {
        let popUpBlock = "<div id='\(id)' class='overlay'>" +
            "<div class='popup'>" +
            "<br>\(column)<br>" +
            "<a class='close' href='#'>&times;</a>" +
            "<div class='content'>" +
            "\(values)" +
            "</div><br>" +
            "</div>" +
        "</div>"
        return popUpBlock
    }
    // code for pop up window - end
    
    func sortList(theArray: [String], completion: @escaping ([String]) -> Void) {
        let newArray = theArray.sorted{$0.localizedCaseInsensitiveCompare($1) == .orderedAscending}
        completion(newArray)
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
    
}

extension Dictionary {
    var username: String {
        get {
            var username = ""
            for (key, _) in self {
                username = "\(key)"
            }
            return username
        }
    }
    var password: String {
        get {
            var password = ""
            for (_, value) in self {
                password = "\(value)"
            }
            return password
        }
    }
}

extension String {
    var fixOptional: String {
        get {
            var newString = self.replacingOccurrences(of: "Optional(\"", with: "")
            newString     = newString.replacingOccurrences(of: "\")", with: "")
            return newString
        }
    }
    var fqdnFromUrl: String {
        get {
            var fqdn = ""
            let nameArray = self.components(separatedBy: "://")
            if nameArray.count > 1 {
                fqdn = nameArray[1]
            } else {
                fqdn =  self
            }
            if fqdn.contains("/") {
                let fqdnArray = fqdn.components(separatedBy: "/")
                fqdn = fqdnArray[0]
            }
            if fqdn.contains(":") {
                let fqdnArray = fqdn.components(separatedBy: ":")
                fqdn = fqdnArray[0]
            }
            while fqdn.last == "/" {
                fqdn = "\(fqdn.dropLast(1))"
            }
            return fqdn
        }
    }
    var baseUrl: String {
        get {
            let tmpArray: [Any] = self.components(separatedBy: "/")
            if tmpArray.count > 2 {
                if let serverUrl = tmpArray[2] as? String {
                    return "\(tmpArray[0])//\(serverUrl)"
                }
            }
            return ""
        }
    }
//    var noPort: String {
//        get {
//            let stringArray = self.components(separatedBy: ":")
//            return stringArray[0]
//        }
//    }
    var pathToString: String {
        get {
            var newPath = ""
            newPath = self.replacingOccurrences(of: "file://", with: "")
            newPath = newPath.replacingOccurrences(of: "%20", with: " ")
            return newPath
        }
    }
    var short: String {
        get {
            var functionName = self
            if let index = self.firstIndex(of: "(") {
                functionName = String(self[..<index])
            }
            return functionName
        }
    }
    var urlFix: String {
        get {
            var fixedUrl = self.replacingOccurrences(of: "//api", with: "/api")
            fixedUrl     = self.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
            fixedUrl     = fixedUrl.replacingOccurrences(of: "/?failover", with: "")
            return fixedUrl
        }
    }
    var urlToFqdn: String {
        get {
            var fqdn = self
            if fqdn != "" {
                fqdn = fqdn.replacingOccurrences(of: "http://", with: "")
                fqdn = fqdn.replacingOccurrences(of: "https://", with: "")
                let fqdnArray = fqdn.split(separator: "/")
                fqdn = "\(fqdnArray[0])"
            }
            return fqdn
        }
    }
    var xmlDecode: String {
        get {
            let newString = self.replacingOccurrences(of: "&amp;", with: "&")
                .replacingOccurrences(of: "&quot;", with: "\"")
                .replacingOccurrences(of: "&apos;", with: "'")
                .replacingOccurrences(of: "&lt;", with: "<")
                .replacingOccurrences(of: "&gt;", with: ">")
            return newString
        }
    }
    var xmlEncode: String {
        get {
            var newString = self
            newString = newString.replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "'", with: "&apos;")
                .replacingOccurrences(of: "\"", with: "&quot;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
            return newString
        }
    }
}

extension Notification.Name {
    public static let setColorScheme_VC    = Notification.Name("setColorScheme_VC")
    public static let resetListFields      = Notification.Name("resetListFields")
    public static let showSummaryWindow    = Notification.Name("showSummaryWindow")
    public static let showLogFolder        = Notification.Name("showLogFolder")
    public static let deleteMode           = Notification.Name("deleteMode")
}
