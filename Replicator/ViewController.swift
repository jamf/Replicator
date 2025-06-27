//
//  ViewController.swift
//  Replicator
//
//  Created by lnh on 12/9/16.
//  Copyright 2024 Jamf. All rights reserved.
//

import AppKit
import Cocoa
import Foundation

final class Summary: NSObject {
    // counters for CreateEndpoints
    static var totalCreated    = 0
    static var totalUpdated    = 0
    
    // counters for RemoveEndpoints
    static var totalDeleted    = 0
    
    static var totalFailed     = 0
    static var totalCompleted  = 0
    
    func zeroTotals() {
        logFunctionCall()
        Summary.totalCreated   = 0
        Summary.totalUpdated   = 0
        Summary.totalDeleted   = 0
        Summary.totalFailed    = 0
        Summary.totalCompleted = 0
    }
}

class Queue {
    static let shared = Queue()
    
//    var Queue.shared.create    = OperationQueue() // create operation queue for API POST/PUT calls
    let operation: OperationQueue
    
    private let queue: DispatchQueue
    
    init() {
        operation = OperationQueue()
        queue = DispatchQueue(label: "queue.queue", qos: .default, attributes: .concurrent)
    }
}

final class Counter {
    static let shared = Counter()

    private let counterQueue = DispatchQueue(label: "counter.queue", qos: .default, attributes: .concurrent)
    private var _dependencyMigrated = [Int: Int]()
    private var _pendingGet  = 1
    private var _pendingSend = 1
    private var _post = 1
    private var _send = [String:[String:Int]]()
    private var _get  = [String:[String:Int]]()
    private var _crud = [String:[String:Int]]()
    private var _summary = [String:[String:[String]]]()
    
    var createRetry          = [String:Int]()
    var progressArray        = [String:Int]() // track if post/put was successful
    var postSuccess          = 0

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
    
    var crud: [String:[String:Int]] {
        get {
            var crud: [String:[String:Int]] = [:]
            counterQueue.sync {
                crud = _crud
            }
            return crud
        }
        set {
            counterQueue.async(flags: .barrier) {
                self._crud = newValue
            }
        }
    }
    
    var get: [String:[String:Int]] {
        get {
            var get: [String:[String:Int]] = [:]
            counterQueue.sync {
                get = _get
            }
            return get
        }
        set {
            counterQueue.async(flags: .barrier) {
                self._get = newValue
            }
        }
    }
    
    var send: [String:[String:Int]] {
        get {
            var send: [String:[String:Int]] = [:]
            counterQueue.sync {
                send = _send
            }
            return send
        }
        set {
            counterQueue.async(flags: .barrier) {
                self._send = newValue
            }
        }
    }
    
    var summary: [String:[String:[String]]] {
        get {
            var summary: [String:[String:[String]]] = [:]
            counterQueue.sync {
                summary = _summary
            }
            return summary
        }
        set {
            counterQueue.async(flags: .barrier) {
                self._summary = newValue
            }
        }
    }
}

final class ListDelay {
    static let shared = ListDelay()
    
    private let delayQueue = DispatchQueue(label: "list.delay", qos: .default, attributes: .concurrent)
    private var _milliseconds: UInt32?

    var milliseconds: UInt32 {
        get {
            var milliseconds: UInt32?
            delayQueue.sync {
                milliseconds = _milliseconds
            }
            return milliseconds ?? 50000
        }
        set {
            delayQueue.async(flags: .barrier) {
                self._milliseconds = newValue
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

final class GetLevelIndicator {
    static let shared = GetLevelIndicator()

    private let getIndicatorQueue = DispatchQueue(label: "getIndicator.color", qos: .default, attributes: .concurrent)
    private var _indicatorColor = [String: NSColor]()
    
    var indicatorColor: [String: NSColor] {
        get {
            var indicatorColor: [String: NSColor] = [:]
            getIndicatorQueue.sync {
                indicatorColor = _indicatorColor
            }

            return indicatorColor
        }
        set {
            getIndicatorQueue.async(flags: .barrier) {
                self._indicatorColor = newValue
            }
        }
    }
}

final class PutLevelIndicator {
    static let shared = PutLevelIndicator()

    private let putIndicatorQueue = DispatchQueue(label: "putIndicator.color", qos: .default, attributes: .concurrent)
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

final class WipeData {
    static let state = WipeData()
    
    private let wipeDataQueue = DispatchQueue(label: "wipe.data", qos: .default, attributes: .concurrent)
    private var _on = false
    
    var on: Bool {
        get {
            var on: Bool?
            wipeDataQueue.sync {
                on = _on
            }
            return on ?? false
        }
        set {
            wipeDataQueue.async(flags: .barrier) {
                self._on = newValue
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
    @objc var destEpId        : String
    @objc var ssIconName      : String
    @objc var ssIconId        : String
    @objc var ssIconUri       : String
    @objc var retry           : Bool
    
    init(endpointType: String, endPointXml: String, endPointJSON: [String:Any], endpointCurrent: Int, endpointCount: Int, action: String, sourceEpId: Int, destEpId: String, ssIconName: String, ssIconId: String, ssIconUri: String, retry: Bool) {
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

class Scope: NSObject {
    static var options:           [String:[String: Bool]] = [:]
    static var ocpCopy         = true   // osxconfigurationprofiles copy scope
    static var maCopy          = true   // macapps copy scope
    static var rsCopy          = true   // restrictedsoftware copy scope
    static var policiesCopy    = true   // policies copy scope
    static var policiesDisable = false  // policies disable on copy
    static var mcpCopy         = true   // mobileconfigurationprofiles copy scope
    static var iaCopy          = true   // iOSapps copy scope
    static var scgCopy         = true   // static computer groups copy scope
    static var sigCopy         = true   // static iOS device groups copy scope
    static var usersCopy       = true   // static user groups copy scope
    
    // command line scope copy
//    static var copy            = true
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

protocol GetStatusDelegate: AnyObject {
    func updateGetStatus(endpoint: String, total: Int, index: Int)
}

protocol UpdateUiDelegate: AnyObject {
    func updateUi(info: [String: Any])
}

class ViewController: NSViewController, URLSessionDelegate, NSTabViewDelegate, NSTableViewDelegate, NSTableViewDataSource, NSTextFieldDelegate, SendMessageDelegate, GetStatusDelegate, UpdateUiDelegate {
    
    
    
    func updateUi(info: [String : Any]) {
//        logFunctionCall()
        let function = info["function"] as? String ?? ""
        switch function {
        case "clearSourceObjectsList":
            clearSourceObjectsList()
        case "goButtonEnabled":
            goButtonEnabled(button_status: info["button_status"] as? Bool ?? true)
        case "labelColor":
            if let endpoint = info["endpoint"] as? String, let color = info["theColor"] as? String {
                switch color {
                case "yellow":
                    labelColor(endpoint: endpoint, theColor: self.yellowText)
                case "red":
                    labelColor(endpoint: endpoint, theColor: self.redText)
                default:
                    labelColor(endpoint: endpoint, theColor: self.greenText)
                }
            }
        case "getStatusUpdate":
            if let endpoint = info["endpoint"] as? String, let total = info["total"] as? Int, let index = info["index"] as? Int {
                updateGetStatus(endpoint: endpoint, total: total, index: index)
//                putStatusUpdate(endpoint: endpoint, total: total)
            }
        case "putStatusUpdate":
            if let endpoint = info["endpoint"] as? String, let total = info["total"] as? Int {
                putStatusUpdate(endpoint: endpoint, total: total)
            }
        case "put_levelIndicator":
            if let fillColor = info["fillColor"] as? NSColor {
                put_levelIndicator.fillColor = fillColor
            }
        case "setLevelIndicatorFillColor":
            if let fn = info["fn"] as? String, let endpointType = info["endpointType"] as? String, let fillColor = info["fillColor"] as? NSColor  {
                setLevelIndicatorFillColor(fn: fn, endpointType: endpointType, fillColor: fillColor, indicator: info["indicator"] as? String ?? "put")
            }
        case "sourceObjectList_AC.remove":
                if let arrangedObjects = sourceObjectList_AC.arrangedObjects as? [SelectiveObject], let _ = info["objectId"] as? String, let objectIndex = arrangedObjects.firstIndex(where: { $0.objectId == info["objectId"] as? String }) {
                    // Find the index of the element matching the criteria
                    print("Found element at index: \(objectIndex)")
                    sourceObjectList_AC.remove(atArrangedObjectIndex: objectIndex)
                } else {
                    print("Element not found")
                }
            srcSrvTableView.isEnabled = false
        case "stopButton":
            stopButton(self)
        case "uploadingIcons_textfield":
            uploadingIcons_textfield.isHidden  = info["isHidden"] as? Bool ?? true
            uploadingIcons2_textfield.isHidden = info["isHidden"] as? Bool ?? true
        case "rmDELETE":
            rmDELETE()
        case "runComplete":
            runComplete()
        default:
            print("unknown UI update: \(function)")
        }
    }
    
    
    func sendMessage(_ message: String) {
        logFunctionCall()
        print("[sendMessage] message: \(message)")
        message_TextField.stringValue = message
    }
    
    private let lockQueue = DispatchQueue(label: "lock.queue")
    //    private let putStatusLockQueue = DispatchQueue(label: "putStatusLock.queue")
    private let getStatusLockQueue = DispatchQueue(label: "putStatusLock.queue")
    
    @IBOutlet weak var selectiveFilter_TextField: NSTextField!
    
    // selective list filter
    func controlTextDidChange(_ obj: Notification) {
        logFunctionCall()
        if let textField = obj.object as? NSTextField {
            if textField.identifier!.rawValue == "search" {
                let filter = selectiveFilter_TextField.stringValue
//                print("filter: \(filter)")
                let textPredicate = ( filter == "" ) ? NSPredicate(format: "objectName.length > 0"):NSPredicate(format: "objectName CONTAINS[c] %@", filter)
                
                sourceObjectList_AC.filterPredicate = textPredicate
                SourceObjects.list = sourceObjectList_AC.arrangedObjects as? [SelectiveObject] ?? [SelectiveObject]()
                self.selectiveListCleared = true
            }
        }
    }
    
    @IBAction func clearFilter_Action(_ sender: Any) {
        logFunctionCall()
        selectiveFilter_TextField.stringValue = ""
        let textPredicate = NSPredicate(format: "objectName.length > 0")
        sourceObjectList_AC.filterPredicate = textPredicate
        SourceObjects.list = sourceObjectList_AC.arrangedObjects as? [SelectiveObject] ?? [SelectiveObject]()
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
        logFunctionCall()
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
        logFunctionCall()
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
//    let Creds2           = Credentials()
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
    @IBOutlet weak var apiRoles_button: NSButton!
    @IBOutlet weak var apiClients_button: NSButton!
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
//    var apiRolesSelected           = false
//    var apiClientsSelected         = false
    
//    @IBOutlet weak var sourceServerList_button: NSPopUpButton!
//    @IBOutlet weak var destServerList_button: NSPopUpButton!
//    @IBOutlet weak var siteMigrate_button: NSButton!
//    @IBOutlet weak var availableSites_button: NSPopUpButtonCell!
    
    var itemToSite      = false
//    var destination-Site = ""
    
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
//    @IBOutlet weak var smartUserGrps_label_field: NSTextField!
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
//    var dependencyParentId      = 0
//    var dependencyMigratedCount = [Int:Int]()   // [policyID:number of dependencies]
    var arrayOfSelected         = [String:[String]]()
    
    
    // source / destination array / dictionary of items
//    var sourceDataArray            = [String]()
//    var staticSource-DataArray      = [String]()
    
    var targetSelectiveObjectList = [SelectiveObject]()
    
//    var availableIDsToMigDict:[String:String] = [:]   // something like xmlName, xmlID
//    var availableObjsToMigDict:[Int:String]   = [:]   // something like xmlID, xmlName

    var selectiveListCleared                = false
    
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
    var maxLogFileCount     = 20
    var historyFile: String = ""
    var logFile:     String = ""
//    let logPath:    String? = (NSHomeDirectory() + "/Library/Logs/Replicator/")
//    var logFileW:     FileHandle? = FileHandle(forUpdatingAtPath: "")
    // legacy logging (history) path and file
    let logPathOld: String? = (NSHomeDirectory() + "/Library/Logs/jamf-migrator/")
    
    // scope preferences
    var scope_Options:           [String:[String: Bool]] = [:]
    var scope_OcpCopy      = true   // osxconfigurationprofiles copy scope
    var scope_MaCopy       = true   // macapps copy scope
    var scope_RsCopy       = true   // restrictedsoftware copy scope
    var scope_PoliciesCopy = true   // policies copy scope
    var policy_Disable     = false  // policies disable on copy
    var scope_McpCopy      = true   // mobileconfigurationprofiles copy scope
    var scope_IaCopy       = true   // iOSapps copy scope
    //    var policyMcpDisable = false  // mobileconfigurationprofiles disable on copy
    //    var policyOcpDisable = false  // osxconfigurationprofiles disable on copy
    var scope_ScgCopy      = true // static computer groups copy scope
    var scope_SigCopy      = true // static iOS device groups copy scope
    var scope_UsersCopy    = true // static user groups copy scope
    
    // command line scope copy
//    var copyScope         = true
    
    // xml prefs
    var xmlPrefOptions: [String:Bool] = [:]
    
    var sourceServerArray   = [String]()
    var destServerArray     = [String]()
    
    // credentials
    var sourceCreds = ""
    var destCreds   = ""
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
    var iconDictArray = [String:[[String:String]]]()
    var uploadedIcons = [String:Int]()

    var xmlName             = ""
    var destEPs             = [String:Int]()
    
    var currentEndpointID   = 0
    
    var whiteText:NSColor   = NSColor.systemGray
    var greenText:NSColor   = NSColor.green
    var yellowText:NSColor  = NSColor.yellow
    var redText:NSColor     = NSColor.red
//    var changeColor :Bool    = true
    
    // This order must match the drop down for selective migration, provide the node name: ../JSSResource/node_name
    var generalEndpointArray: [String] = ["api-integrations", "api-roles", "advancedusersearches", "buildings", "categories", "classes", "departments", "jamfusers", "jamfgroups", "ldapservers", "networksegments", "sites", "userextensionattributes", "users", "smartusergroups", "staticusergroups"]
    var macOSEndpointArray: [String] = ["advancedcomputersearches", "macapplications", "smartcomputergroups", "staticcomputergroups", "computers", "osxconfigurationprofiles", "directorybindings", "diskencryptionconfigurations", "dockitems", "computerextensionattributes", "distributionpoints", "packages", "patch-software-title-configurations", "policies", "computer-prestages", "printers", "restrictedsoftware", "scripts", "softwareupdateservers"]
    var iOSEndpointArray: [String] = ["advancedmobiledevicesearches", "mobiledeviceapplications", "mobiledeviceconfigurationprofiles", "smartmobiledevicegroups", "staticmobiledevicegroups", "mobiledevices",  "mobiledeviceextensionattributes", "mobile-device-prestages"]
    var AllEndpointsArray = [String]()
    
    let allObjects = ["sites", "userextensionattributes", "ldapservers", "users", "buildings", "departments", "categories", "classes", "jamfusers", "jamfgroups", "networksegments", "advancedusersearches", "smartusergroups", "staticusergroups", "distributionpoints", "directorybindings", "diskencryptionconfigurations", "dockitems", "computers", "softwareupdateservers", "computerextensionattributes", "scripts", "printers", "packages", "smartcomputergroups", "staticcomputergroups", "restrictedsoftware", "osxconfigurationprofiles", "macapplications", "patch-software-title-configurations", "advancedcomputersearches", "policies", "mobiledeviceextensionattributes", "mobiledevices", "smartmobiledevicegroups", "staticmobiledevicegroups", "advancedmobiledevicesearches", "mobiledeviceapplications", "mobiledeviceconfigurationprofiles"]
    
    let exportObjects = ["sites", "userextensionattributes", "ldapservers", "users", "buildings", "departments", "categories", "classes", "jamfusers", "jamfgroups", "networksegments", "advancedusersearches", "usergroups", "smartusergroups", "staticusergroups", "distributionpoints", "directorybindings", "diskencryptionconfigurations", "dockitems", "computers", "softwareupdateservers", "computerextensionattributes", "scripts", "printers", "packages", "computergroups", "smartcomputergroups", "staticcomputergroups", "restrictedsoftware", "osxconfigurationprofiles", "macapplications", "patch-software-title-configurations", "advancedcomputersearches", "policies", "mobiledeviceextensionattributes", "mobiledevices", "mobiledevicegroups", "smartmobiledevicegroups", "staticmobiledevicegroups", "advancedmobiledevicesearches", "mobiledeviceapplications", "mobiledeviceconfigurationprofiles"]
    
    
    var getEndpointInProgress = ""     // end point currently in the GET queue
//    var endpointInProgress    = ""     // end point currently in the POST queue
    var endpointName          = ""
//    var POSTsuccessCount      = 0
    var failedCount           = 0

//    var counters              = [String:[String:Int]]()          // summary counters of created, updated, failed, and deleted objects
    var getCounters           = [String:[String:Int]]()          // summary counters of created, updated, failed, and deleted objects
    var putCounters           = [String:[String:Int]]()
    
    // used in createEndpoints
//    var total_Created    = 0
//    var total_Updated    = 0
//    var total_Failed     = 0
//    var total_Completed  = 0
    var getArray        = [ObjectInfo]()
    var getArrayJSON    = [ObjectInfo]()
    var createArrayJson = [ObjectInfo]()
    var removeArray     = [ObjectInfo]()

    @IBOutlet weak var spinner_progressIndicator: NSProgressIndicator!
    
    // group counters
    var smartCount      = 0
    var staticCount     = 0
    //var DeviceGroupType = ""  // either smart or static
    // var groupCheckArray: [Bool] = []
    
    
    // define list of items to migrate
//    var ToMigrate.objects           = [String]()
//    var ToMigrate.total      = 0
//    var endpointsRead              = 0
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

    var readFilesQ    = OperationQueue() // for reading in data files
    var readNodesQ    = OperationQueue() // for reading in API endpoints
    var removeEPQ     = OperationQueue() //DispatchQueue(label: "com.jamf.removeEPs", qos: DispatchQoS.background)
    var removeMeterQ  = OperationQueue() //DispatchQueue(label: "com.jamf.removeEPs", qos: DispatchQoS.background)
    let theIconsQ     = OperationQueue() // que to upload/download icons
        
    var theModeQ    = DispatchQueue(label: "com.jamf.addRemove")
    
    var theSpinnerQ = DispatchQueue(label: "com.jamf.spinner")
    
    var destEPQ      = DispatchQueue(label: "com.jamf.destEPs", qos: DispatchQoS.utility)
    var getSourceEPQ = DispatchQueue(label: "com.jamf.getSourceQ", qos: DispatchQoS.utility)
    var idMapQ       = DispatchQueue(label: "com.jamf.idMap")
    var sortQ        = DispatchQueue(label: "com.jamf.sortQ", qos: DispatchQoS.default)
    var iconHoldQ    = DispatchQueue(label: "com.jamf.iconhold")
        
    var migrateOrWipe: String = ""
    var httpStatusCode: Int   = 0
    var URLisValid: Bool      = true
//    var processGroup          = DispatchGroup()
    
     func setTab_fn(selectedTab: String) {
         logFunctionCall()
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
        logFunctionCall()
        if NSEvent.modifierFlags.contains(.option) {
            markAllNone(rawStateValue: sender.state.rawValue)
        }
		  inactiveTabDisable(activeTab: "bulk")
    }
    
    func inactiveTabDisable(activeTab: String) {
	    // disable buttons on inactive tabs - start
        logFunctionCall()
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
            self.apiRoles_button.state          = NSControl.StateValue(rawValue: 0)
            self.apiClients_button.state        = NSControl.StateValue(rawValue: 0)
        }
        if activeTab == "bulk" {
            generalSectionToMigrate_button.selectItem(at: 0)
            sectionToMigrate_button.selectItem(at: 0)
            iOSsectionToMigrate_button.selectItem(at: 0)

            ToMigrate.objects.removeAll()
            Endpoints.countDict.removeAll()
            DataArray.source.removeAll()
            srcSrvTableView.reloadData()
            
            clearSourceObjectsList()
            
            targetSelectiveObjectList.removeAll()
        }
        // disable buttons on inactive tabs - end
        srcSrvTableView.isEnabled = true
	}

    func markAllNone(rawStateValue: Int) {

        logFunctionCall()
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
            self.apiRoles_button.state = NSControl.StateValue(rawValue: rawStateValue)
            self.apiClients_button.state = NSControl.StateValue(rawValue: rawStateValue)
        }
    }
    
    fileprivate func clearSourceObjectsList() {
        logFunctionCall()
        if Setting.fullGUI {
            let textPredicate = NSPredicate(format: "objectName.length > 0")
            sourceObjectList_AC.filterPredicate = textPredicate
            
            let range = 0..<(sourceObjectList_AC.arrangedObjects as AnyObject).count
            sourceObjectList_AC.remove(atArrangedObjectIndexes: IndexSet(integersIn: range))
            SourceObjects.list = sourceObjectList_AC.arrangedObjects as? [SelectiveObject] ?? [SelectiveObject]()
        }
        staticSourceObjectList.removeAll()
        ApiRoles.source.removeAll()
        ApiIntegrations.source.removeAll()
    }
    
    @IBAction func sectionToMigrate(_ sender: NSPopUpButton) {
        
        logFunctionCall()
        pref.stopMigration  = false
        goButtonEnabled(button_status: false)

        inactiveTabDisable(activeTab: "selective")
        UiVar.goSender = "selectToMigrateButton"
//        goSender = "selectToMigrateButton"

        let whichTab = sender.identifier!.rawValue
        
        if LogLevel.debug { WriteToLog.shared.message("func sectionToMigrate active tab: \(String(describing: whichTab)).") }
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
                Setting.migrateDependencies       = false
                self.migrateDependencies.state    = .off
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
            ToMigrate.objects.removeAll()
            Endpoints.countDict.removeAll()
            DataArray.source.removeAll()
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
            
            ToMigrate.objects.append(AllEndpointsArray[itemIndex-1])
            
//            print("[sectiontoMigrate] Selected: \(AllEndpointsArray[itemIndex-1])")
            if (AllEndpointsArray[itemIndex-1] == "policies" || AllEndpointsArray[itemIndex-1] == "patch-software-title-configurations") && !WipeData.state.on {
                DispatchQueue.main.async {
                    self.migrateDependencies.isHidden = false
                }
            } else {
                DispatchQueue.main.async {
                    Setting.migrateDependencies       = false
                    self.migrateDependencies.state    = .off
                    self.migrateDependencies.isHidden = true
                }
            }
            
            if LogLevel.debug { WriteToLog.shared.message("Selectively migrating: \(ToMigrate.objects) for \(sender.identifier ?? NSUserInterfaceItemIdentifier(rawValue: ""))") }
            print("[sectiontoMigrate] Selected ToMigrate.objects: \(ToMigrate.objects)")
            print("[sectionToMigrate] goSender: \(UiVar.goSender)")
            Go(sender: UiVar.goSender)
        }
    }
    
    @IBAction func Go_action(sender: NSButton) {
        logFunctionCall()
        JamfProServer.validToken["source"] = false
        JamfProServer.validToken["dest"]   = false
        JamfProServer.version["source"]    = ""
        JamfProServer.version["dest"]      = ""
        migrationComplete.isDone           = false
        if sender.title == "Go!" || sender.title == "Delete" {
            go_button.title = "Stop"
//            getCounters.removeAll()
//            putCounters.removeAll()
            Counter.shared.send.removeAll()
            Counter.shared.get.removeAll()
            Iconfiles.policyDict.removeAll()
            Iconfiles.pendingDict.removeAll()
            uploadedIcons.removeAll()
            Go(sender: "goButton")
        } else {
            WriteToLog.shared.message("Migration was manually stopped.\n")
            pref.stopMigration = true

            goButtonEnabled(button_status: true)
        }
    }
    
    func Go(sender: String) {
//        print("go (before readSettings) Scope.options: \(String(describing: Scope.options))")
        
        logFunctionCall()
        History.startTime = Date()
        Counter.shared.crud.removeAll()
        Counter.shared.summary.removeAll()
        currentEPDict.removeAll()
        
        if Setting.fullGUI {
            if WipeData.state.on && export.saveOnly {
                _ = Alert.shared.display(header: "Attention", message: "Cannot select Save Only while in delete mode.", secondButton: "")
                goButtonEnabled(button_status: true)
                return
            }
            if WipeData.state.on && sender != "selectToMigrateButton" {
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
            Scope.options          = AppInfo.settings["scope"] as! [String:[String:Bool]]
            xmlPrefOptions        = AppInfo.settings["xml"] as! [String:Bool]
            
            export.saveOnly       = (xmlPrefOptions["saveOnly"] == nil) ? false:xmlPrefOptions["saveOnly"]!
            export.saveRawXml     = (xmlPrefOptions["saveRawXml"] == nil) ? false:xmlPrefOptions["saveRawXml"]!
            export.saveTrimmedXml = (xmlPrefOptions["saveTrimmedXml"] == nil) ? false:xmlPrefOptions["saveTrimmedXml"]!
            saveRawXmlScope       = (xmlPrefOptions["saveRawXmlScope"] == nil) ? true:xmlPrefOptions["saveRawXmlScope"]!
            saveTrimmedXmlScope   = (xmlPrefOptions["saveTrimmedXmlScope"] == nil) ? true:xmlPrefOptions["saveRawXmlScope"]!
            
            smartUserGrpsSelected      = smartUserGrps_button.state == .on
            staticUserGrpsSelected     = staticUserGrps_button.state == .on
            smartComputerGrpsSelected  = smart_comp_grps_button.state.rawValue == 1
            staticComputerGrpsSelected = static_comp_grps_button.state.rawValue == 1
            smartIosGrpsSelected       = smart_ios_groups_button.state.rawValue == 1
            staticIosGrpsSelected      = static_ios_groups_button.state.rawValue == 1
            jamfUserAccountsSelected   = jamfUserAccounts_button.state.rawValue == 1
            jamfGroupAccountsSelected  = jamfGroupAccounts_button.state.rawValue == 1
//            apiRolesSelected           = apiRoles_button.state == .on
//            apiClientsSelected         = apiRoles_button.state == .on
        } else {
            if export.backupMode {
                backupDate.dateFormat = "yyyyMMdd_HHmmss"
                export.saveOnly       = true
                export.saveRawXml     = true
                export.saveTrimmedXml = false
                saveRawXmlScope       = true
                saveTrimmedXmlScope   = false
                
                smartUserGrpsSelected      = false
                staticUserGrpsSelected     = false
                smartComputerGrpsSelected  = false
                staticComputerGrpsSelected = false
                smartIosGrpsSelected       = false
                staticIosGrpsSelected      = false
                jamfUserAccountsSelected   = false
                jamfGroupAccountsSelected  = false
//                apiRolesSelected           = false
//                apiClientsSelected         = false
            }
        }
        
        if JamfProServer.importFiles == 1 && (export.saveOnly || export.saveRawXml) {
            alert_dialog(header: "Attention", message: "Cannot select Export Only or Raw Source XML (Preferneces -> Export) when using File Import.")
            goButtonEnabled(button_status: true)
            return
        }

        didRun = true

        if LogLevel.debug { WriteToLog.shared.message("Start Migrating/Removal") }
        // check for file that allow deleting data from destination server - start
        if (fm.fileExists(atPath: NSHomeDirectory() + "/Library/Application Support/Replicator/DELETE", isDirectory: &isDir)) && !export.backupMode {
            if LogLevel.debug { WriteToLog.shared.message("Removing data from destination server - \(JamfProServer.destination)") }
            WipeData.state.on = true
            
            migrateOrWipe = "----------- Starting To Wipe Data -----------\n"
        } else {
            if !export.saveOnly {
                // verify source and destination are not the same - start
                let sameSite = (JamfProServer.source == JamfProServer.destination) ? true:false
//                if sameSite && (JamfProServer.destSite == "None" || JamfProServer.destSite == "") {
                if sameSite && JamfProServer.destSite == "" {
                    alert_dialog(header: "Alert", message: "Source and destination servers cannot be the same.")
                    self.goButtonEnabled(button_status: true)
                    return
                }
                // verify source and destination are not the same - end
                if LogLevel.debug { WriteToLog.shared.message("Migrating data from \(JamfProServer.source) to \(JamfProServer.destination).") }
                migrateOrWipe = "----------- Starting Replicating -----------\n"
            } else {
                if LogLevel.debug { WriteToLog.shared.message("Exporting data from \(JamfProServer.source).") }
                if export.saveOnly  {
                    migrateOrWipe = "----------- Starting Export Only -----------\n"
                } else {
                    migrateOrWipe = "----------- Starting Export -----------\n"
                }
            }
            WipeData.state.on = false
        }
        // check for file that allow deleting data from destination server - end
        
        if LogLevel.debug { WriteToLog.shared.message("[ViewController.Go] go sender: \(sender)") }
        // determine if we got here from the Go button, selectToMigrate button, or silently
        UiVar.goSender = "\(sender)"
//        print("[Go] sender: \(sender)")

        if LogLevel.debug { WriteToLog.shared.message("[ViewController.Go] Go button pressed from: \(UiVar.goSender)") }
        
        if Setting.fullGUI {
            put_levelIndicator.fillColor = .green
            get_levelIndicator.fillColor = .green
            // which migration mode tab are we on
            if UiVar.activeTab == "Selective" {
                migrationMode = "selective"
            } else {
                migrationMode               = "bulk"
                Setting.migrateDependencies = false
            }
        } else {
            migrationMode = "bulk"
        }
        if LogLevel.debug { WriteToLog.shared.message("[ViewController.Go] Migration Mode (Go): \(migrationMode)") }
        
        goButtonEnabled(button_status: false)
        if Setting.fullGUI {
//            goButtonEnabled(button_status: false)
            clearProcessingFields()
            
            // credentials were entered check - start
            if JamfProServer.importFiles == 0 && !WipeData.state.on {
                if (JamfProServer.sourceUser == "" || JamfProServer.sourcePwd == "") && !WipeData.state.on {
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
                if Setting.fullGUI {
                    self.alert_dialog(header: "Attention:", message: "Unable to contact the source server:\n\(JamfProServer.source)")
                    self.goButtonEnabled(button_status: true)
                    return
                } else {
                    WriteToLog.shared.message("Unable to contact the source server:\n\(JamfProServer.source)")
                    NSApplication.shared.terminate(self)
                }
            }
            
            JamfProServer.url["source"] = JamfProServer.source
            
            JamfPro.shared.checkURL2(whichServer: "dest", serverURL: JamfProServer.destination)  { [self]
                (result: Bool) in
    //            print("checkURL2 returned result: \(result)")
                if !result {
                    if Setting.fullGUI {
                        self.alert_dialog(header: "Attention:", message: "Unable to contact the destination server:\n\(JamfProServer.destination)")
                        self.goButtonEnabled(button_status: true)
                        return
                    } else {
                        WriteToLog.shared.message("Unable to contact the destination server:\n\(JamfProServer.destination)")
                        NSApplication.shared.terminate(self)
                    }
                }
                // server is reachable - end
                
                JamfProServer.url["dest"] = JamfProServer.destination
                
                if Setting.fullGUI || Setting.migrate {
                    if JamfProServer.toSite {
//                        destination_Site = JamfProServer.destSite
                        itemToSite = true
                    } else {
                        itemToSite = false
                    }
                }
                
                // don't set if we're importing files or removing data
                if JamfProServer.importFiles == 0 && !WipeData.state.on {
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
                
                let clientType = (JamfProServer.sourceUseApiClient == 1) ? "API client/secret":"username/password"
                WriteToLog.shared.message("[go] Using \(clientType) to generate token for source: \(JamfProServer.source.fqdnFromUrl).")
                
                let localsource = (JamfProServer.importFiles == 1) ? true:false
                JamfPro.shared.getToken(whichServer: "source", serverUrl: JamfProServer.source, base64creds: JamfProServer.base64Creds["source"] ?? "", localSource: localsource) { [self]
                    (authResult: (Int,String)) in
                    let (authStatusCode, _) = authResult
                    if !pref.httpSuccess.contains(authStatusCode) && !WipeData.state.on {
                        if LogLevel.debug { WriteToLog.shared.message("Source server authentication failure.") }
                        
                        pref.stopMigration = true
                        goButtonEnabled(button_status: true)
                        
                        return
                    } else {
                        if Setting.fullGUI {
                            self.updateServerArray(url: JamfProServer.source, serverList: "source_server_array", theArray: self.sourceServerArray)
                            if LogLevel.debug { WriteToLog.shared.message("[ViewController.go] Updated server array with: \(JamfProServer.source.fqdnFromUrl)") }
                            // update keychain, if marked to save creds
                            if !WipeData.state.on {
                                print("[ViewController.go] JamfProServer.storeSourceCreds: \(JamfProServer.storeSourceCreds)")
                                if JamfProServer.storeSourceCreds == 1 {
                                    if LogLevel.debug { WriteToLog.shared.message("[ViewController.go] save credentials for: \(JamfProServer.source.fqdnFromUrl)") }
                                    Credentials.shared.save(service: JamfProServer.source.fqdnFromUrl, account: JamfProServer.sourceUser, credential: JamfProServer.sourcePwd, whichServer: "source")
                                    self.storedSourceUser = JamfProServer.sourceUser
                                } else {
                                    if LogLevel.debug { WriteToLog.shared.message("[ViewController.go] Not saving credentials for: \(JamfProServer.source.fqdnFromUrl)") }
                                }
                            }
                        }
                        
                        let clientType = (JamfProServer.destUseApiClient == 1) ? "API client/secret":"username/password"
                        WriteToLog.shared.message("[go] Using \(clientType) to generate token for destination: \(JamfProServer.destination.fqdnFromUrl).")
                        JamfPro.shared.getToken(whichServer: "dest", serverUrl: JamfProServer.destination, base64creds: JamfProServer.base64Creds["dest"] ?? "", localSource: localsource) { [self]
                            (authResult: (Int,String)) in
                            let (authStatusCode, _) = authResult
                            if !pref.httpSuccess.contains(authStatusCode) {
                                if LogLevel.debug { WriteToLog.shared.message("[ViewController.Go] Destination server (\(JamfProServer.destination)) authentication failure.") }
                                
                                pref.stopMigration = true
                                goButtonEnabled(button_status: true)
                                
                                return
                            } else {
                                // update keychain, if marked to save creds
                                if !export.saveOnly && Setting.fullGUI {
                                    print("[ViewController.go] JamfProServer.storeDestCreds: \(JamfProServer.storeDestCreds)")
                                    if JamfProServer.storeDestCreds == 1 {
                                        print("[ViewController.go] save credentials for: \(JamfProServer.destination.fqdnFromUrl)")
                                        Credentials.shared.save(service: JamfProServer.destination.fqdnFromUrl, account: JamfProServer.destUser, credential: JamfProServer.destPwd, whichServer: "dest")
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
                                        Setting.csa = true
                                    } else {
                                        Setting.csa = false
                                    }
    //                                print("csa: \(setting.csa)")
                                    
                                    if !export.saveOnly && Setting.fullGUI {
                                        self.updateServerArray(url: self.dest_jp_server, serverList: "dest_server_array", theArray: self.destServerArray)
                                    }
            
                                    if LogLevel.debug { WriteToLog.shared.message("call startMigrating().") }
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
        logFunctionCall()
        go_button.isEnabled = false
        // check for file that sets mode to delete data from destination server, delete if found - start
        rmDELETE()

        AppDelegate.shared.quitNow(sender: self)
    }
    
    //================================= migration functions =================================//
    func startMigrating() {
        logFunctionCall()
        _ = disableSleep(reason: "starting process")
        
        if LogLevel.debug { WriteToLog.shared.message("[ViewController.startMigrating] enter") }
        pref.stopMigration = false
        Counter.shared.createRetry.removeAll()
        Counter.shared.createRetry.removeAll()
        nodesComplete      = 0
        getNodesComplete   = 0
        ToMigrate.rawCount = 0
        
        // make sure the labels can change color when we start
        UiVar.changeColor  = true
        getEndpointInProgress = "start"
        endpointInProgress    = ""
        Summary().zeroTotals()
        
        DispatchQueue.main.async { [self] in
            if !export.backupMode {
                fileImport = (JamfProServer.importFiles == 1) ? true:false
                createDestUrlBase = "\(JamfProServer.destination)/JSSResource".urlFix
            } else {
                fileImport = false
                createDestUrlBase = "\(dest_jp_server)/JSSResource".urlFix
            }
                
            if Setting.fullGUI {
                // set all the labels to white - start
                AllEndpointsArray = macOSEndpointArray + iOSEndpointArray + generalEndpointArray
                for i in (0..<AllEndpointsArray.count) {
                    labelColor(endpoint: AllEndpointsArray[i], theColor: whiteText)
                }
                // set all the labels to white - end
            }
            if LogLevel.debug { WriteToLog.shared.message("[ViewController.startMigrating] Start Migrating/Removal") }
            if Setting.fullGUI {
                if LogLevel.debug { WriteToLog.shared.message("[ViewController.startMigrating] platform: \(deviceType()).") }
            }
            if LogLevel.debug { WriteToLog.shared.message("[ViewController.startMigrating] Migration Mode (startMigration): \(migrationMode).") }
                        
                // list the items in the order they need to be migrated
            if migrationMode == "bulk" {
                // initialize list of items to migrate then add what we want - start
                ToMigrate.objects.removeAll()
                Endpoints.countDict.removeAll()

                if Setting.fullGUI {
                    if LogLevel.debug { WriteToLog.shared.message("Types of objects to migrate: \(deviceType()).") }
                    // macOS
                    switch deviceType() {
                    case "general":
                        if sites_button.state.rawValue == 1 {
                            ToMigrate.objects += ["sites"]
                            ToMigrate.rawCount += 1
                        }
                        
                        if userEA_button.state.rawValue == 1 {
                            ToMigrate.objects += ["userextensionattributes"]
                            ToMigrate.rawCount += 1
                        }
                        
                        if ldapservers_button.state.rawValue == 1 {
                            ToMigrate.objects += ["ldapservers"]
                            ToMigrate.rawCount += 1
                        }
                        
                        if users_button.state.rawValue == 1 {
                            ToMigrate.objects += ["users"]
                            ToMigrate.rawCount += 1
                        }
                        
                        if building_button.state.rawValue == 1 {
                            ToMigrate.objects += ["buildings"]
                            ToMigrate.rawCount += 1
                        }
                        
                        if dept_button.state.rawValue == 1 {
                            ToMigrate.objects += ["departments"]
                            ToMigrate.rawCount += 1
                        }
                        
                        if categories_button.state.rawValue == 1 {
                            ToMigrate.objects += ["categories"]
                            ToMigrate.rawCount += 1
                        }
                        
                        if jamfUserAccounts_button.state.rawValue == 1 {
                            ToMigrate.objects += ["jamfusers"]
                            ToMigrate.rawCount += 1
                        }
                        
                        if jamfGroupAccounts_button.state.rawValue == 1 {
                            ToMigrate.objects += ["jamfgroups"]
                            ToMigrate.rawCount += 1
                        }
                        
                        if networks_button.state.rawValue == 1 {
                            ToMigrate.objects += ["networksegments"]
                            ToMigrate.rawCount += 1
                        }
                        
                        if advusersearch_button.state.rawValue == 1 {
                            ToMigrate.objects += ["advancedusersearches"]
                            ToMigrate.rawCount += 1
                        }
                        
                        if smartUserGrps_button.state.rawValue == 1 || staticUserGrps_button.state.rawValue == 1 {
                            ToMigrate.rawCount += 1
                            smartUserGrps_button.state.rawValue == 1 ? (migrateSmartUserGroups = true):(migrateSmartUserGroups = false)
                            staticUserGrps_button.state.rawValue == 1 ? (migrateStaticUserGroups = true):(migrateStaticUserGroups = false)
                            if !fileImport || WipeData.state.on {
                                ToMigrate.objects += ["usergroups"]
                            } else {
                                if migrateSmartUserGroups {
                                    ToMigrate.objects += ["smartusergroups"]
                                }
                                if migrateStaticUserGroups {
                                    ToMigrate.objects += ["staticusergroups"]
                                }
                            }
                        }
                        
                        if classes_button.state.rawValue == 1 {
                            ToMigrate.objects += ["classes"]
                            ToMigrate.rawCount += 1
                        }
                        
                        if apiRoles_button.state == .on {
                            ToMigrate.objects += ["api-roles"]
                            ToMigrate.rawCount += 1
                        }
                        
                        if apiClients_button.state == .on {
                            ToMigrate.objects += ["api-integrations"]
                            ToMigrate.rawCount += 1
                        }
                    case "macOS":
                        if fileshares_button.state.rawValue == 1 {
                            ToMigrate.rawCount += 1
                            ToMigrate.objects += ["distributionpoints"]
                        }
                        
                        if directory_bindings_button.state.rawValue == 1 {
                            ToMigrate.rawCount += 1
                            ToMigrate.objects += ["directorybindings"]
                        }
                        
                        if disk_encryptions_button.state.rawValue == 1 {
                            ToMigrate.rawCount += 1
                            ToMigrate.objects += ["diskencryptionconfigurations"]
                        }
                        
                        if dock_items_button.state.rawValue == 1 {
                            ToMigrate.rawCount += 1
                            ToMigrate.objects += ["dockitems"]
                        }
                        
                        if computers_button.state.rawValue == 1 {
                            ToMigrate.rawCount += 1
                            ToMigrate.objects += ["computers"]
                        }
                        
                        if sus_button.state.rawValue == 1 {
                            ToMigrate.rawCount += 1
                            ToMigrate.objects += ["softwareupdateservers"]
                        }
                        
//                        if netboot_button.state.rawValue == 1 {
//                            ToMigrate.objects += ["netbootservers"]
//                        }
                        
                        if ext_attribs_button.state.rawValue == 1 {
                            ToMigrate.rawCount += 1
                            ToMigrate.objects += ["computerextensionattributes"]
                        }
                        
                        if scripts_button.state.rawValue == 1 {
                            ToMigrate.rawCount += 1
                            ToMigrate.objects += ["scripts"]
                        }
                        
                        if printers_button.state.rawValue == 1 {
                            ToMigrate.rawCount += 1
                            ToMigrate.objects += ["printers"]
                        }
                        
                        if packages_button.state.rawValue == 1 {
                            ToMigrate.rawCount += 1
                            ToMigrate.objects += ["packages"]
                        }
                        
                        if smart_comp_grps_button.state.rawValue == 1 || static_comp_grps_button.state.rawValue == 1 {
                            ToMigrate.rawCount += 1
                            smart_comp_grps_button.state == .on ? (migrateSmartComputerGroups = true):(migrateSmartComputerGroups = false)
                            static_comp_grps_button.state == .on ? (migrateStaticComputerGroups = true):(migrateStaticComputerGroups = false)
                            if !fileImport || WipeData.state.on {
                                ToMigrate.objects += ["computergroups"]
                            } else {
                                if migrateSmartComputerGroups {
                                    ToMigrate.objects += ["smartcomputergroups"]
                                }
                                if migrateStaticComputerGroups {
                                    ToMigrate.objects += ["staticcomputergroups"]
                                }
                            }
                        }
                        
                        if restrictedsoftware_button.state.rawValue == 1 {
                            ToMigrate.rawCount += 1
                            ToMigrate.objects += ["restrictedsoftware"]
                        }
                        
                        if osxconfigurationprofiles_button.state.rawValue == 1 {
                            ToMigrate.rawCount += 1
                            ToMigrate.objects += ["osxconfigurationprofiles"]
                        }
                        
                        if macapplications_button.state.rawValue == 1 {
                            ToMigrate.rawCount += 1
                            ToMigrate.objects += ["macapplications"]
                        }
                        
                        if patch_mgmt_button.state.rawValue == 1 {
                            ToMigrate.rawCount += 1
                            ToMigrate.objects += ["patch-software-title-configurations"]
                        }
                        
                        if advcompsearch_button.state.rawValue == 1 {
                            ToMigrate.rawCount += 1
                            ToMigrate.objects += ["advancedcomputersearches"]
                        }
                        
                        if policies_button.state.rawValue == 1 {
                            ToMigrate.rawCount += 1
                            ToMigrate.objects += ["policies"]
                        }
                    case "iOS":
                        if mobiledeviceextensionattributes_button.state.rawValue == 1 {
                            ToMigrate.rawCount += 1
                            ToMigrate.objects += ["mobiledeviceextensionattributes"]
                        }
                        
                        if mobiledevices_button.state.rawValue == 1 {
                            ToMigrate.rawCount += 1
                            ToMigrate.objects += ["mobiledevices"]
                        }

                        if smart_ios_groups_button.state.rawValue == 1 || static_ios_groups_button.state.rawValue == 1 {
                            ToMigrate.rawCount += 1
                             smart_ios_groups_button.state.rawValue == 1 ? (migrateSmartMobileGroups = true):(migrateSmartMobileGroups = false)
                             static_ios_groups_button.state.rawValue == 1 ? (migrateStaticMobileGroups = true):(migrateStaticMobileGroups = false)
                             if !fileImport || WipeData.state.on {
                                 ToMigrate.objects += ["mobiledevicegroups"]
                             } else {
                                 if migrateSmartMobileGroups {
                                     ToMigrate.objects += ["smartmobiledevicegroups"]
                                 }
                                 if migrateStaticMobileGroups {
                                     ToMigrate.objects += ["staticmobiledevicegroups"]
                                 }
                             }
                         }

                        if advancedmobiledevicesearches_button.state.rawValue == 1 {
                            ToMigrate.rawCount += 1
                            ToMigrate.objects += ["advancedmobiledevicesearches"]
                        }
                        
                        if mobiledevicecApps_button.state.rawValue == 1 {
                            ToMigrate.rawCount += 1
                            ToMigrate.objects += ["mobiledeviceapplications"]
                        }
                        
                        if mobiledeviceconfigurationprofiles_button.state.rawValue == 1 {
                            ToMigrate.rawCount += 1
                            ToMigrate.objects += ["mobiledeviceconfigurationprofiles"]
                        }
                    default: break
                    }
                    ToMigrate.total = ToMigrate.objects.count
                    if !fileImport {
                        if smartUserGrps_button.state.rawValue == 1 && staticUserGrps_button.state.rawValue == 1 {
                            ToMigrate.total += 1
                        } else if smart_comp_grps_button.state.rawValue == 1 && static_comp_grps_button.state.rawValue == 1 {
                            ToMigrate.total += 1
                        } else if smart_ios_groups_button.state.rawValue == 1 && static_ios_groups_button.state.rawValue == 1 {
                            ToMigrate.total += 1
                        }
                    }
                } else {
                    if Setting.migrate {
                        // set migration order
                        for theObject in allObjects {
                            if Setting.objects.firstIndex(of: theObject) != nil || Setting.objects.contains("allobjects") {
                                ToMigrate.objects += [theObject]
                            }
                        }
                    } else {
                        // define objects to export
                        for theObject in exportObjects {
                            if Setting.objects.firstIndex(of: theObject) != nil || Setting.objects.contains("allobjects") {
                                switch theObject {
                                case "computergroups", "smartcomputergroups", "staticcomputergroups":
                                    if theObject == "computergroups" || theObject == "smartcomputergroups" {
                                        migrateSmartComputerGroups = true
                                        smartComputerGrpsSelected  = true
                                    }
                                    if theObject == "computergroups" || theObject == "staticcomputergroups" {
                                        migrateStaticComputerGroups = true
                                        staticComputerGrpsSelected  = true
                                    }
                                    if !ToMigrate.objects.contains("computergroups") {
                                        ToMigrate.objects += ["computergroups"]
                                    }
                                case "mobiledevicegroups", "smartmobiledevicegroups", "staticmobiledevicegroups":
                                    if theObject == "mobiledevicegroups" || theObject == "smartmobiledevicegroups" {
                                        migrateSmartMobileGroups = true
                                        smartIosGrpsSelected  = true
                                    }
                                    if theObject == "mobiledevicegroups" || theObject == "staticmobiledevicegroups" {
                                        migrateStaticMobileGroups = true
                                        staticIosGrpsSelected  = true
                                    }
                                    if !ToMigrate.objects.contains("mobiledevicegroups") {
                                        ToMigrate.objects += ["mobiledevicegroups"]
                                    }
                                case "usergroups", "smartusergroups", "staticusergroups":
                                    if theObject == "usergroups" || theObject == "smartusergroups" {
                                        migrateSmartUserGroups = true
                                        smartUserGrpsSelected  = true
                                    }
                                    if theObject == "usergroups" || theObject == "staticusergroups" {
                                        migrateStaticUserGroups = true
                                        staticUserGrpsSelected  = true
                                    }
                                    if !ToMigrate.objects.contains("usergroups") {
                                        ToMigrate.objects += ["usergroups"]
                                    }
                                case "jamfusers":
                                    jamfUserAccountsSelected = true
                                    ToMigrate.objects += [theObject]
                                case "jamfgroups":
                                    jamfGroupAccountsSelected = true
                                    ToMigrate.objects += [theObject]
                                default:
                                    ToMigrate.objects += [theObject]
                                }
                            }
                        }
                        ToMigrate.rawCount = ToMigrate.objects.count
                        if ToMigrate.objects.contains("smartcomputergroups") && ToMigrate.objects.contains("staticcomputergroups") {
                            ToMigrate.rawCount -= 1
                        }
                        if ToMigrate.objects.contains("smartmobiledevicegroups") && ToMigrate.objects.contains("staticmobiledevicegroups") {
                            ToMigrate.rawCount -= 1
                        }
                        if ToMigrate.objects.contains("smartusergroups") && ToMigrate.objects.contains("staticusergroups") {
                            ToMigrate.rawCount -= 1
                        }
                    }
//                    ToMigrate.objects = ["buildings", "departments", "categories", "jamfusers"]    // for testing
                    ToMigrate.total = ToMigrate.objects.count
                }
//                endpoints-Read = 0
                Endpoints.read = 0
            } else {   // if migrationMode == "bulk" - end
                ToMigrate.total = 1
                ToMigrate.rawCount = 1
            }
            
            // initialize list of items to migrate then add what we want - end
            if LogLevel.debug { WriteToLog.shared.message("[ViewController.startMigrating] objects: \(ToMigrate.objects)") }
            print("[ViewController.startMigrating] objects: \(ToMigrate.objects)")
                    
            
            if ToMigrate.objects.count == 0 {
                if LogLevel.debug { WriteToLog.shared.message("[ViewController.startMigrating] nothing selected to migrate/remove.") }
                self.goButtonEnabled(button_status: true)
                return
            } else {
                nodesMigrated = 0
                if WipeData.state.on {
                    // reverse migration order for removal and set create / delete header for summary table
                    ToMigrate.objects.reverse()
                    // set server and credentials used for wipe
                    self.sourceBase64Creds = self.destBase64Creds
                    JamfProServer.base64Creds["source"] = self.destBase64Creds
                    JamfProServer.source  = self.dest_jp_server
                    
                    JamfProServer.authCreds["source"]   = JamfProServer.authCreds["dest"]
//                    JamfProServer.authExpires["source"] = JamfProServer.authExpires["dest"]
                    JamfProServer.authType["source"]    = JamfProServer.authType["dest"]
                        
                    summaryHeader.createDelete = "Delete"
                } else {   // if WipeData.state.on - end
                    summaryHeader.createDelete = "Create"
                }
            }
            
            
            
            WriteToLog.shared.message(self.migrateOrWipe)
            
            // initialize counters
            for currentNode in ToMigrate.objects {
                if Setting.fullGUI {
                    PutLevelIndicator.shared.indicatorColor[currentNode] = .green
//                    self.put_levelIndicatorFillColor[currentNode] = .green
                }
//                print("[startMigrating] currentNode: \(currentNode)")
                switch currentNode {
                case "computergroups", "smartcomputergroups", "staticcomputergroups":
                    if self.smartComputerGrpsSelected {
                        Counter.shared.progressArray["smartcomputergroups"] = 0
                        Counter.shared.crud["smartcomputergroups"]           = ["create":0, "update":0, "fail":0, "skipped":0, "total":0]
                        Counter.shared.summary["smartcomputergroups"]       = ["create":[], "update":[], "fail":[]]
                        self.getCounters["smartcomputergroups"]        = ["get":0]
                        self.putCounters["smartcomputergroups"]        = ["put":0]
                    }
                    if self.staticComputerGrpsSelected {
                        Counter.shared.progressArray["staticcomputergroups"] = 0
                        Counter.shared.crud["staticcomputergroups"]           = ["create":0, "update":0, "fail":0, "skipped":0, "total":0]
                        Counter.shared.summary["staticcomputergroups"]        = ["create":[], "update":[], "fail":[]]
                        self.getCounters["staticcomputergroups"]        = ["get":0]
                        self.putCounters["staticcomputergroups"]        = ["put":0]
                    }
                    Counter.shared.progressArray["computergroups"] = 0 // this is the recognized end point
                case "mobiledevicegroups":
                    if self.smartIosGrpsSelected {
                        Counter.shared.progressArray["smartmobiledevicegroups"] = 0
                        Counter.shared.crud["smartmobiledevicegroups"]           = ["create":0, "update":0, "fail":0, "skipped":0, "total":0]
                        Counter.shared.summary["smartmobiledevicegroups"]        = ["create":[], "update":[], "fail":[]]
                        self.getCounters["smartmobiledevicegroups"]        = ["get":0]
                        self.putCounters["smartmobiledevicegroups"]        = ["put":0]
                    }
                    if self.staticIosGrpsSelected {
                        Counter.shared.progressArray["staticmobiledevicegroups"] = 0
                        Counter.shared.crud["staticmobiledevicegroups"]           = ["create":0, "update":0, "fail":0, "skipped":0, "total":0]
                        Counter.shared.summary["staticmobiledevicegroups"]        = ["create":[], "update":[], "fail":[]]
                        self.getCounters["staticmobiledevicegroups"]        = ["get":0]
                        self.putCounters["staticmobiledevicegroups"]        = ["put":0]
                    }
                    Counter.shared.progressArray["mobiledevicegroups"] = 0 // this is the recognized end point
                case "usergroups":
                    if self.smartUserGrpsSelected {
                        Counter.shared.progressArray["smartusergroups"] = 0
                        Counter.shared.crud["smartusergroups"]           = ["create":0, "update":0, "fail":0, "skipped":0, "total":0]
                        Counter.shared.summary["smartusergroups"]        = ["create":[], "update":[], "fail":[]]
                        self.getCounters["smartusergroups"]        = ["get":0]
                        self.putCounters["smartusergroups"]        = ["put":0]
                    }
                    if self.staticUserGrpsSelected {
                        Counter.shared.progressArray["staticusergroups"] = 0
                        Counter.shared.crud["staticusergroups"]           = ["create":0, "update":0, "fail":0, "skipped":0, "total":0]
                        Counter.shared.summary["staticusergroups"]        = ["create":[], "update":[], "fail":[]]
                        self.getCounters["staticusergroups"]        = ["get":0]
                        self.putCounters["staticusergroups"]        = ["put":0]
                    }
                    Counter.shared.progressArray["usergroups"] = 0 // this is the recognized end point
                case "accounts":
                    if self.jamfUserAccountsSelected {
                        Counter.shared.progressArray["jamfusers"] = 0
                        Counter.shared.crud["jamfusers"]           = ["create":0, "update":0, "fail":0, "skipped":0, "total":0]
                        Counter.shared.summary["jamfusers"]        = ["create":[], "update":[], "fail":[]]
                        self.getCounters["jamfusers"]        = ["get":0]
                        self.putCounters["jamfusers"]        = ["put":0]
                    }
                    if self.jamfGroupAccountsSelected {
                        Counter.shared.progressArray["jamfgroups"] = 0
                        Counter.shared.crud["jamfgroups"]           = ["create":0, "update":0, "fail":0, "skipped":0, "total":0]
                        Counter.shared.summary["jamfgroups"]        = ["create":[], "update":[], "fail":[]]
                        self.getCounters["jamfgroups"]        = ["get":0]
                        self.putCounters["jamfgroups"]        = ["put":0]
                    }
                    Counter.shared.progressArray["accounts"] = 0 // this is the recognized end point
                case "patch-software-title-configurations":
                    Counter.shared.progressArray["patch-software-title-configurations"] = 0
                    Counter.shared.crud["patch-software-title-configurations"]           = ["create":0, "update":0, "fail":0, "skipped":0, "total":0]
                    Counter.shared.summary["patch-software-title-configurations"]        = ["create":[], "update":[], "fail":[]]
                    self.getCounters["patch-software-title-configurations"]        = ["get":0]
                    self.putCounters["patch-software-title-configurations"]        = ["put":0]
                default:
                    Counter.shared.progressArray["\(currentNode)"] = 0
                    Counter.shared.crud[currentNode] = ["create":0, "update":0, "fail":0, "skipped":0, "total":0]
                    Counter.shared.summary[currentNode] = ["create":[], "update":[], "fail":[]]
                    self.getCounters[currentNode] = ["get":0]
                    self.putCounters[currentNode] = ["put":0]
                }
            }

            // get scope copy / policy disable options
            Scope.options = readSettings()["scope"] as! [String: [String: Bool]]
//            print("startMigrating Scope.options: \(String(describing: Scope.options))")
            
            if Setting.fullGUI {
                // get scope preference settings - start
                if Scope.options["osxconfigurationprofiles"]!["copy"] != nil {
                    Scope.ocpCopy = Scope.options["osxconfigurationprofiles"]!["copy"]!
                }
                if Scope.options["macapps"] != nil {
                    if Scope.options["macapps"]!["copy"] != nil {
                        Scope.maCopy = Scope.options["macapps"]!["copy"]!
                    } else {
                        Scope.maCopy = true
                    }
                } else {
                    Scope.maCopy = true
                }
                if Scope.options["restrictedsoftware"]!["copy"] != nil {
                    Scope.rsCopy = Scope.options["restrictedsoftware"]!["copy"]!
                }
                if Scope.options["policies"]!["copy"] != nil {
                    Scope.policiesCopy = Scope.options["policies"]!["copy"]!
                }
                if Scope.options["policies"]!["disable"] != nil {
                    Scope.policiesDisable = Scope.options["policies"]!["disable"]!
                }
                if Scope.options["mobiledeviceconfigurationprofiles"]!["copy"] != nil {
                    Scope.mcpCopy = Scope.options["mobiledeviceconfigurationprofiles"]!["copy"]!
                }
                if Scope.options["iosapps"] != nil {
                    if Scope.options["iosapps"]!["copy"] != nil {
                        Scope.iaCopy = Scope.options["iosapps"]!["copy"]!
                    } else {
                        Scope.iaCopy = true
                    }
                } else {
                    Scope.iaCopy = true
                }
                if Scope.options["scg"]!["copy"] != nil {
                    Scope.scgCopy = Scope.options["scg"]!["copy"]!
                }
                if Scope.options["sig"]!["copy"] != nil {
                    Scope.sigCopy = Scope.options["sig"]!["copy"]!
                }
                if Scope.options["users"]!["copy"] != nil {
                    Scope.usersCopy = Scope.options["users"]!["copy"]!
                }
                // get scope preference settings - end
            }
            
            if LogLevel.debug { WriteToLog.shared.message("[ViewController.startMigrating] migrating/removing \(ToMigrate.objects.count) sections") }
            // loop through process of migrating or removing - start
            self.readNodesQ.addOperation {
                let currentNode = ToMigrate.objects[0]

                if LogLevel.debug { WriteToLog.shared.message("[ViewController.startMigrating] Starting to process \(currentNode)") }
                                
                if (UiVar.goSender == "goButton" && self.migrationMode == "bulk") || (UiVar.goSender == "selectToMigrateButton") || (UiVar.goSender == "silent") {
                    if LogLevel.debug { WriteToLog.shared.message("[ViewController.startMigrating] getting endpoint: \(currentNode)") }
                    
                    // this will populate list for selective migration or start migration of bulk operations
                    self.readNodes(nodesToMigrate: ToMigrate.objects, nodeIndex: 0)
                    
                } else {
                    // **************************************** selective migration - start ****************************************
                    var selectedEndpoint = ""
                    switch ToMigrate.objects[0] {
                    case "jamfusers":
                        selectedEndpoint = "accounts/userid"
                    case "jamfgroups":
                        selectedEndpoint = "accounts/groupid"
                    default:
                        selectedEndpoint = ToMigrate.objects[0]
                    }
                    if LogLevel.debug { WriteToLog.shared.message("[ViewController.startMigrating] Look for existing endpoints for: \(ToMigrate.objects[0])") }
                    
                    print("[startMigrating] call ExistingObjects.shared.capi - theDestEndpoint: \(ToMigrate.objects[0])")
                    ExistingObjects.shared.capi(skipLookup: false, theDestEndpoint: "\(ToMigrate.objects[0])")  { [self]
//                    self.existingEndpoints(skipLookup: false, theDestEndpoint: "\(ToMigrate.objects[0])")  { [self]
                        (result: (String,String)) in
                        print("[startMigrating] returned from ExistingObjects.shared.capi - theDestEndpoint: \(ToMigrate.objects[0])")
                        
                        let (resultMessage, resultEndpoint) = result
                        if LogLevel.debug { WriteToLog.shared.message("[ViewController.startMigrating] Returned from existing endpoints: \(resultMessage)") }
                        
//                        print("build list of objects selected")
                        
                        // clear targetSelectiveObjectList - needed to handle switching tabs
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
                                    if LogLevel.debug { WriteToLog.shared.message("[ViewController.startMigrating] nothing selected to migrate/remove.") }
                                    self.alert_dialog(header: "Alert:", message: "Nothing was selected.")
                                    self.goButtonEnabled(button_status: true)
                                    return
                                }
                            
//                                if LogLevel.debug { WriteToLog.shared.message("[ViewController.startMigrating] Item(s) chosen from selective: \(sourceObjectList_AC.arrangedObjects as! [SelectiveObject])") }

                                advancedMigrateDict.removeAll()
                                migratedDependencies.removeAll()
                                migratedPkgDependencies.removeAll()
                                waitForDependencies  = false
                                
                                print("[startMigrating] call selectiveMigrationDelegate for selectedEndpoint: \(selectedEndpoint)")
                                selectiveMigrationDelegate(objectIndex: 0, selectedEndpoint: selectedEndpoint)
                            }
                    }
                }   //  if (UiVar.goSender == "goButton"... - else - end
            // **************************************** selective migration - end ****************************************
            }   // self.readFiles.async - end
        }   //DispatchQueue.main.async - end
    }   // func startMigrating - end
    
    func selectiveMigrationDelegate(objectIndex: Int, selectedEndpoint: String) {
        logFunctionCall()
        ObjectAndDependencies.records.removeAll()
        if migrateDependencies.state == .on {
            
//            var dependencyObjectList = [String: [SelectiveObject]]()
            
            print("[selectiveMigrationDelegate] call getDependencies for selectedEndpoint: \(selectedEndpoint)")
            getDependencies(objectIndex: objectIndex, selectedEndpoint: selectedEndpoint, selectedObjectList: targetSelectiveObjectList) { [self] (result) in
                for objectInfo in result {
                    print("objectType: \(objectInfo.objectType) - objectName: \(objectInfo.objectName) - objectId: \(objectInfo.objectId)")
//                    dependencyObjectList[objectType] = objectInfo
                }
                startSelectiveMigration(objectIndex: objectIndex, objectAndDependencies: ObjectAndDependencies.records)
                if objectIndex+1 < targetSelectiveObjectList.count {
                    selectiveMigrationDelegate(objectIndex: objectIndex+1, selectedEndpoint: selectedEndpoint)
                }
            }
        } else {
            for objectInfo in targetSelectiveObjectList {
                ObjectAndDependencies.records.append(ObjectAndDependency(objectType: selectedEndpoint, objectName: objectInfo.objectName, objectId: objectInfo.objectId))
            }
            startSelectiveMigration(objectIndex: 0, objectAndDependencies: ObjectAndDependencies.records)
        }
    }
    
    func startSelectiveMigration(objectIndex: Int, objectAndDependencies: [ObjectAndDependency]) {
//        print("[startSelectiveMigration] objectIndex: \(objectIndex), selectedEndpoint: \(selectedEndpoint)")
        
        logFunctionCall()
        var idPath             = ""  // adjust for jamf users/groups that use userid/groupid instead of id
//        var alreadyMigrated    = false
//        let theButton          = ""

//        print("[startMigrating] AvailableObjsToMig.byName: \(AvailableObjsToMig.byName)")
        // todo - consolidate these 2 vars
        let selectedEndpoint      = objectAndDependencies[objectIndex].objectType
        let primaryObjToMigrateID = Int(objectAndDependencies[objectIndex].objectId)
        let objToMigrateID        = objectAndDependencies[objectIndex].objectId
        
        dependencyParentId        = primaryObjToMigrateID!
        dependency.isRunning      = true
        Counter.shared.dependencyMigrated[dependencyParentId] = 0
        
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
            case "patch-software-title-configurations":
                rawEndpoint = "patch-software-title-configurations"
            default:
                rawEndpoint = selectedEndpoint
        }
        
        var endpointToLookup = fileImport ? "skip":"\(rawEndpoint)/\(idPath)/\(String(describing: primaryObjToMigrateID!))"
        if fileImport || WipeData.state.on {
            endpointToLookup = "skip"
        }
        
        switch selectedEndpoint {
        case "api-roles", "api-integrations":
            idPath = ""
            endpointToLookup = "skip"
        case "accounts/userid", "accounts/groupid":
            idPath = "/"
        default:
            idPath = "id/"
        }
        
        print("[startSelectiveMigration] selectedEndpoint: \(selectedEndpoint)")
        if !WipeData.state.on {
            Json.shared.getRecord(whichServer: "source", base64Creds: JamfProServer.base64Creds["source"] ?? "", theEndpoint: endpointToLookup, endpointBase: selectedEndpoint, endpointId: objToMigrateID)  { [self]
                (objectRecord: Any) in
                
                switch selectedEndpoint {
                case "patch-software-title-configurations":
                    let existingPatch = objectRecord as? PatchSoftwareTitleConfiguration
                    print("[startSelectiveMigration] patch management title name: \(existingPatch?.displayName ?? "")")
                    
                    let selectedObject = objectAndDependencies[objectIndex].objectName
                    print("[startSelectiveMigration] patch management selectedEndpoint: \(selectedEndpoint)")
                    print("[startSelectiveMigration] patch management selectedObject: \(selectedObject)")
                    print("[startSelectiveMigration] selected currentEPDict: \(currentEPDict[selectedEndpoint]?[selectedObject] ?? 0)")
                    print("[startSelectiveMigration] currentEPDict: \(currentEPDict)")
                    if !fileImport {
                        // export policy details if export.saveRawXml
                        if export.saveRawXml {
                            DispatchQueue.main.async {
                                WriteToLog.shared.message("[getEndpoints] Exporting raw JSON for patch policy details")
                                let exportFormat = (export.backupMode) ? "\(JamfProServer.source.fqdnFromUrl)_export_\(backupDate.string(from: History.startTime))":"raw"
                                ExportItem.shared.export(node: "patchPolicyDetails", object: PatchPoliciesDetails.source, format: exportFormat)
                            }
                        }
                    }
                default:
                    break
                }
                let result = objectRecord as? [String: AnyObject] ?? [:]
                print("[startSelectiveMigration] result.count: \(result.count)")
                print("[startSelectiveMigration] result: \(result)")
                if LogLevel.debug { WriteToLog.shared.message("[ViewController.startMigration] Returned from Json.getRecord") }
                
                if pref.stopMigration {
//                    print("[\(#function)] \(#line) stopMigration")
                    stopButton(self)
                    return
                }
                
                let selectedObject = objectAndDependencies[objectIndex].objectName
//                    print("[startSelectiveMigration] selectedObject: \(selectedObject)")
            // include dependencies - start
//                    print("advancedMigrateDict with policy: \(advancedMigrateDict)")
            
                self.destEPQ.async { [self] in
                    
                    // migrate the policy or selected object now the dependencies are done
                    DispatchQueue.global(qos: .utility).async { [self] in
                      
    //                    if theButton == "Stop" { return }
                        
                        var theAction = "update"

                        if !export.saveOnly { WriteToLog.shared.message("check destination for existing object: \(selectedObject)") }
                        
    //                    print("[startSelectiveMigration] selectedObject: \(selectedObject)\n currentEPDict[\(selectedEndpoint)]: \(currentEPDict[selectedEndpoint] ?? [:])")
                        var existingObjectId = 0
                        switch selectedEndpoint {
                        case "api-roles":
                            existingObjectId = Int(ApiRoles.destination.first(where: { $0.displayName.lowercased() == selectedObject.lowercased() })?.id ?? "0") ?? 0
                        case "api-integrations":
                            existingObjectId = Int(ApiIntegrations.destination.first(where: { $0.displayName.lowercased() == selectedObject.lowercased() })?.id ?? "0") ?? 0
                        case "patch-software-title-configurations":
                            existingObjectId = currentEPDict[selectedEndpoint]?[selectedObject] ?? 0
                        default:
                            existingObjectId = currentEPDict[rawEndpoint]?[selectedObject] ?? 0
                        }
                        
                        if existingObjectId == 0 && !export.saveOnly {
                            theAction = "create"
                        }
                        print("[startSelectiveMigration] existingObjectId: \(existingObjectId), theAction: \(theAction)")
                        
                        WriteToLog.shared.message("[ViewController.startSelectiveMigration] \(theAction) \(selectedObject) \(selectedEndpoint) dependency")
                        
                        if !fileImport {
                            EndpointXml.shared.endPointByIdQueue(endpoint: selectedEndpoint, endpointID: objToMigrateID, endpointCurrent: (objectIndex+1), endpointCount: objectAndDependencies.count, action: theAction, destEpId: existingObjectId, destEpName: selectedObject)
                        } else {
                            //                                   print("[ViewController.startSelectiveMigration-fileImport] \(selectedObject), all items: \(self.availableFilesToMigDict)")
                            
                            let fileToMigrate = displayNameToFilename[selectedObject]
    //                                print("[ViewController.startSelectiveMigration-fileImport] selectedObject: \(selectedObject), fileToMigrate: \(String(describing: fileToMigrate))")
    //                                print("[ViewController.startSelectiveMigration-fileImport] objectIndex+1: \(objectIndex+1), targetSelectiveObjectList.count: \(targetSelectiveObjectList.count)")
                            
                            arrayOfSelected[selectedObject] = self.availableFilesToMigDict[fileToMigrate!]!
    //                                print("[ViewController.startSelectiveMigration] selectedObject: \(selectedObject)")
    //                                print("[ViewController.startSelectiveMigration-fileImport] arrayOfSelected: \(arrayOfSelected[selectedObject] ?? [])")
                            
                            if objectIndex+1 == objectAndDependencies.count {
    //                                    print("[ViewController.startSelectiveMigration] processFiles)")
                                self.processFiles(endpoint: selectedEndpoint, fileCount: objectAndDependencies.count, itemsDict: arrayOfSelected) {
                                    (result: String) in
                                    if LogLevel.debug { WriteToLog.shared.message("[readDataFiles] Returned from processFile (\(String(describing: fileToMigrate))).") }
                                }
                            }
                        }
                        
                        print("[\(#function.short)] objectIndex+1: \(objectIndex+1) - objectAndDependencies.count: \(objectAndDependencies.count)")
                        // call next item
                        if objectIndex+1 < objectAndDependencies.count {
                            //                                        print("[ViewController.startSelectiveMigration] call next \(selectedEndpoint)")
                            startSelectiveMigration(objectIndex: objectIndex+1, objectAndDependencies: objectAndDependencies)
                        } else if objectIndex+1 == objectAndDependencies.count {
                            print("[\(#function.short)] dependency.isRunning \(dependency.isRunning)")
                            dependency.isRunning = false
                        }
                    }
                }
            }
        } else {
            // selective removal
//            print("[removeEndpoints] Counter.shared.crud[\(selectedEndpoint)]: \(Counter.shared.crud[selectedEndpoint])")
            Counter.shared.crud[selectedEndpoint] = ["create": Counter.shared.crud[selectedEndpoint]?["create"] ?? 0, "update": Counter.shared.crud[selectedEndpoint]?["update"] ?? 0, "fail": Counter.shared.crud[selectedEndpoint]?["fail"] ?? 0, "skipped": Counter.shared.crud[selectedEndpoint]?["skipped"] ?? 0, "total": Counter.shared.crud[selectedEndpoint]?["total"] ?? 0]
            
            Counter.shared.crud[selectedEndpoint]!["total"] = targetSelectiveObjectList.count

            if Counter.shared.summary[selectedEndpoint] == nil {
                Counter.shared.summary[selectedEndpoint] = ["create":[], "update":[], "fail":[]]
            }
            for i in 0..<targetSelectiveObjectList.count {
                let theObject = targetSelectiveObjectList[i]
                if LogLevel.debug { WriteToLog.shared.message("remove - endpoint: \(targetSelectiveObjectList[objectIndex].objectName)\t endpointID: \(objToMigrateID)\t endpointName: \(self.targetSelectiveObjectList[objectIndex].objectName)") }
                RemoveObjects.shared.queue(endpointType: selectedEndpoint, endPointID: "\(theObject.objectId)", endpointName: theObject.objectName, endpointCurrent: (i+1), endpointCount: targetSelectiveObjectList.count)
//                removeEndpointsQueue(endpointType: selectedEndpoint, endPointID: "\(theObject.objectId)", endpointName: theObject.objectName, endpointCurrent: (i+1), endpointCount: targetSelectiveObjectList.count)
            }
            RemoveObjects.shared.queue(endpointType: selectedEndpoint, endPointID: "-1", endpointName: "", endpointCurrent: -1, endpointCount: 0)
            print("[\(#function.short)] dependency.isRunning \(dependency.isRunning)")
            dependency.isRunning = false
        }   // if !WipeData.state.on else - end
//        }   // Json().getRecord - end
    }
    
    
    func readNodes(nodesToMigrate: [String], nodeIndex: Int) {
        
        logFunctionCall()
        if pref.stopMigration {
//            print("[\(#function)] \(#line) stopMigration")
            stopButton(self)
            return
        }
        
        if LogLevel.debug { WriteToLog.shared.message("[ViewController.readNodes] enter search for \(nodesToMigrate[nodeIndex])") }
        
        print("node to migrate: \(nodesToMigrate[nodeIndex])")
        switch nodesToMigrate[nodeIndex] {
        case "computergroups", "smartcomputergroups", "staticcomputergroups":
            Counter.shared.progressArray["smartcomputergroups"]  = 0
            Counter.shared.progressArray["staticcomputergroups"] = 0
            Counter.shared.progressArray["computergroups"]       = 0 // this is the recognized end point
        case "mobiledevicegroups", "smartmobiledevicegroups", "staticmobiledevicegroups":
            Counter.shared.progressArray["smartmobiledevicegroups"]     = 0
            Counter.shared.progressArray["staticmobiledevicegroups"]    = 0
            Counter.shared.progressArray["mobiledevicegroups"] = 0 // this is the recognized end point
        case "usergroups", "smartusergroups", "staticusergroups":
            Counter.shared.progressArray["smartusergroups"] = 0
            Counter.shared.progressArray["staticusergroups"] = 0
            Counter.shared.progressArray["usergroups"] = 0 // this is the recognized end point
        case "accounts":
            Counter.shared.progressArray["jamfusers"] = 0
            Counter.shared.progressArray["jamfgroups"] = 0
            Counter.shared.progressArray["accounts"] = 0 // this is the recognized end point
        default:
            Counter.shared.progressArray["\(nodesToMigrate[nodeIndex])"] = 0
        }
        if LogLevel.debug { WriteToLog.shared.message("[ViewController.readNodes] getting endpoint: \(nodesToMigrate[nodeIndex])") }
        
        if nodeIndex == 0 {
            // see if the source is a folder, is so allow access
            if JamfProServer.source.first == "/" {
                if JamfProServer.source.last != "/" {
                    JamfProServer.source = JamfProServer.source + "/"
                }
                
                if SecurityScopedBookmarks.shared.allowAccess(for: JamfProServer.source) {
                    WriteToLog.shared.message("[ViewController.readNodes] successfully set access permissions to \(JamfProServer.source)")
                } else {
                    WriteToLog.shared.message("[ViewController.readNodes] Bookmark Access Failed for \(JamfProServer.source)")
                }
                
                if !FileManager.default.isReadableFile(atPath: JamfProServer.source) {
                    WriteToLog.shared.message("[ViewController.readNodes] Unable to read from \(JamfProServer.source).  Reselect it using the File Import or Browse button and try again.")
                    pref.stopMigration = true
                    if Setting.fullGUI {
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
                    WriteToLog.shared.message("[ViewController.readNodes] successfully set access permissions to \(export.saveLocation)")
                } else {
                    WriteToLog.shared.message("[ViewController.readNodes] Bookmark Access Failed for \(export.saveLocation)")
                }
                
                if !FileManager.default.isWritableFile(atPath: export.saveLocation) {
                    WriteToLog.shared.message("[ViewController.readNodes] Unable to write to \(export.saveLocation), setting export location to \(NSHomeDirectory())/Downloads/Replicator/")
                    export.saveLocation = (NSHomeDirectory() + "/Downloads/Replicator/")
                    userDefaults.set("\(export.saveLocation)", forKey: "saveLocation")
                } else {
                    if LogLevel.debug { WriteToLog.shared.message("[ViewController.readNodes] \(export.saveLocation) is writable") }
                }
            }   // if export.saveRawXml - end
        }   // if nodeIndex == 0 - end
            
        print("[check] nodesToMigrate: \(nodesToMigrate), nodeIndex: \(nodeIndex)")
        if fileImport && !WipeData.state.on && !pref.stopMigration {
            
            if LogLevel.debug { WriteToLog.shared.message("[ViewController.readNodes] reading files for: \(nodesToMigrate)") }
            if LogLevel.debug { WriteToLog.shared.message("[ViewController.readNodes]         nodeIndex: \(nodeIndex)") }
//            print("call readDataFiles for \(nodesToMigrate)")   // called too often
            self.readDataFiles(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex) {
                (result: String) in
                if LogLevel.debug { WriteToLog.shared.message("[ViewController.readNodes] processFiles result: \(result)") }
                if LogLevel.debug { WriteToLog.shared.message("[ViewController.readNodes] exit") }
            }
        } else {
            
            clearSourceObjectsList()
            AvailableObjsToMig.byId.removeAll()
            
            self.getSourceEndpoints(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex)  {
                (result: [String]) in
//                print("[ViewController.readNodes] getEndpoints result: \(result)")
                if LogLevel.debug { WriteToLog.shared.message("[ViewController.readNodes] getEndpoints result for \(nodesToMigrate[nodeIndex]): \(result)") }
                if LogLevel.debug { WriteToLog.shared.message("[ViewController.readNodes] exit") }
                if Setting.fullGUI {
                    if UiVar.activeTab == "Selective" {
                        self.goButtonEnabled(button_status: true)
                    }
                }
            }
        }
    }   // func readNodes - end
    
    fileprivate func updateSelectiveList(objectName: String, objectId: String, fileContents: String) {
        logFunctionCall()
        DispatchQueue.main.async { [self] in
            sourceObjectList_AC.addObject(SelectiveObject(objectName: objectName, objectId: objectId, fileContents: fileContents))
            // sort printer list
            sourceObjectList_AC.rearrangeObjects()
            staticSourceObjectList = sourceObjectList_AC.arrangedObjects as! [SelectiveObject]
            SourceObjects.list    = sourceObjectList_AC.arrangedObjects as? [SelectiveObject] ?? [SelectiveObject]()
            
//            srcSrvTableView.reloadData()
            srcSrvTableView.scrollRowToVisible(staticSourceObjectList.count-1)
            // srcSrvTableView.scrollToEndOfDocument(nil)
        }
    }
    
    func getSourceEndpoints(nodesToMigrate: [String], nodeIndex: Int, completion: @escaping (_ result: [String]) -> Void) {
        // get objects from source server (query source server) - destination server if removing
        logFunctionCall()
        print("[getSourceEndpoints] nodesToMigrate: \(nodesToMigrate)")
        if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] enter") }
//        pendingGetCount = 0
        Counter.shared.pendingGet = 0

        if pref.stopMigration {
//            print("[\(#function)] \(#line) stopMigration")
            stopButton(self)
            completion([])
            return
        }
        
//        var duplicatePackages      = false
//        var duplicatePackagesDict  = [String:[String]]()
//        var failedPkgNameLookup    = [String]()
        
        URLCache.shared.removeAllCachedResponses()
        var endpoint       = nodesToMigrate[nodeIndex]
        var endpointParent = ""
        let node           = ""
        var endpointCount  = 0
        var groupType      = ""
        if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] Getting \(endpoint)") }
//        print("[ViewController.getSourceEndpoints] Getting \(endpoint), index \(nodeIndex)")
        
        if endpoint.contains("smart") {
            groupType = "smart"
        } else if endpoint.contains("static") {
            groupType = "static"
        }
        
        switch endpoint {
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
            case "patch-software-title-configurations":
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
               
            default:
                endpointParent = "\(endpoint)"
        }
        
        getEndpointsQ.maxConcurrentOperationCount = maxConcurrentThreads
//        let semaphore = DispatchSemaphore(value: 0)
        
        if Setting.fullGUI {
            DispatchQueue.main.async {
                self.srcSrvTableView.isEnabled = true
            }
        }
        DataArray.source.removeAll()
        AvailableObjsToMig.byName.removeAll()
        
        clearSourceObjectsList()
        
        getEndpointsQ.addOperation {
            
            ObjectDelegate.shared.getAll(whichServer: "source", endpoint: endpoint) { [self]
                result in
                
//                print("[getEndpoints] result: \(result)")
//                print("[getEndpoints] goSender: \(UiVar.goSender)")
                
                Endpoints.read += 1
                Endpoints.countDict[endpoint] = endpointCount
                switch endpoint {
                case "api-roles", "api-integrations":
//                    do {
//                        let jsonData = try? JSONSerialization.data(withJSONObject: result, options: [])
//                        ApiRoles.source = try JSONDecoder().decode([ApiRole].self, from: jsonData!)
//                    } catch {
//                        print("error getting \(endpoint) configurations: \(error)")
//                    }
                    let objectCount = (endpoint == "api-roles") ? ApiRoles.source.count : ApiIntegrations.source.count
                    print("test \(endpoint) object count: \(objectCount)")
                    if objectCount > 0 {
                        AvailableObjsToMig.byId.removeAll()
                        
                        if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] Initial count for \(endpoint) found: \(objectCount)") }
                        
                        if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] Verify empty dictionary of objects - AvailableObjsToMig.byId count: \(AvailableObjsToMig.byId.count)") }
                        
                        switch endpoint {
                        case "api-roles":
                            for theObject in ApiRoles.source /*as? [ApiRole] ?? []*/ {
                                if theObject.displayName.isEmpty {
                                    AvailableObjsToMig.byId[Int(theObject.id) ?? 0] = ""
                                } else {
                                    AvailableObjsToMig.byId[Int(theObject.id) ?? 0] = theObject.displayName
                                }
                            }
                        case "api-integrations":
                            for theObject in ApiIntegrations.source /*as? [ApiIntegration] ?? []*/ {
                                if theObject.displayName.isEmpty {
                                    AvailableObjsToMig.byId[Int(theObject.id) ?? 0] = ""
                                } else {
                                    AvailableObjsToMig.byId[Int(theObject.id) ?? 0] = theObject.displayName
                                }
                            }
                        default:
                            break
                        }
                        
                        Endpoints.read += 1
                        
                        Endpoints.countDict[endpoint] = AvailableObjsToMig.byId.count
                        if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] Found total of \(AvailableObjsToMig.byId.count) \(endpoint) to process") }
                        
                        // get existing destination objects
                        
                        let skipLookup = (migrationMode == "bulk") ? false:true
                        ExistingObjects.shared.capi(skipLookup: skipLookup, theDestEndpoint: "\(endpoint)")  { [self]
                            (result: (String,String)) in
                            if pref.stopMigration {
                                rmDELETE()
                                completion(["migration stopped", "0"])
                                return
                            }
                            
                            if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] returning existing \(endpoint) endpoints: \(AvailableObjsToMig.byId)") }
                            
                            //                                                            completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                            //                                                            return
                            // make into a func - start
                            if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] Found total of \(AvailableObjsToMig.byId.count) \(endpoint) to process") }
                            
                            var counter = 1
                            if UiVar.goSender == "goButton" || UiVar.goSender == "silent" {
                                
                                Counter.shared.crud[endpoint]!["total"] = AvailableObjsToMig.byId.count
                                
                                for (l_xmlID, l_xmlName) in AvailableObjsToMig.byId {
                                    if !WipeData.state.on  {
                                        if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] check for ID of \(l_xmlName): \(currentEPs[l_xmlName] ?? 0)") }
                                        
                                        let destinationObjectExists = ( endpoint == "api-roles") ? ApiRoles.destination.first(where: { $0.displayName == l_xmlName}) != nil : ApiIntegrations.destination.first(where: { $0.displayName == l_xmlName}) != nil
//                                        print("[getSourceEndpoints] not yet implemented - check for ID of \(l_xmlName): \(currentEPs[l_xmlName] ?? 0)")
//                                        print("[getSourceEndpoints] not yet implemented - exists \(l_xmlName): \(destinationObjectExists)")
                                        // check to see if create or update...
                                        
                                        
                                        if destinationObjectExists {
                                            if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] \(l_xmlName) already exists") }
                                            if Setting.onlyCopyMissing {
                                                updateGetStatus(endpoint: endpoint, total: AvailableObjsToMig.byId.count)
                                                CreateEndpoints.shared.queue(endpointType: endpoint, endpointName: l_xmlName, endPointXML: "", endpointCurrent: counter, endpointCount: AvailableObjsToMig.byId.count, action: "update", sourceEpId: 0, destEpId: "0", ssIconName: "", ssIconId: "0", ssIconUri: "", retry: false) {
                                                    (result: String) in
                                                    completion(["skipped endpoint - \(endpoint)", "\(AvailableObjsToMig.byId.count)"])
                                                }
                                            } else {
                                                let destinationObjectId = (endpoint == "api-roles") ? ApiRoles.destination.first(where: { $0.displayName == l_xmlName })?.id ?? "0" : ApiIntegrations.destination.first(where: { $0.displayName == l_xmlName })?.id ?? "0"
                                                EndpointXml.shared.endPointByIdQueue(endpoint: endpoint, endpointID: "\(l_xmlID)", endpointCurrent: counter, endpointCount: AvailableObjsToMig.byId.count, action: "update", destEpId: Int(destinationObjectId) ?? 0, destEpName: l_xmlName)
                                            }
                                        } else {
                                            if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] \(l_xmlName) - create") }
                                            if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] function - endpoint: \(endpoint), endpointID: \(l_xmlID), endpointCurrent: \(counter), endpointCount: \(endpointCount), action: \"create\", destEpId: 0") }
                                            if Setting.onlyCopyExisting {
                                                updateGetStatus(endpoint: endpoint, total: AvailableObjsToMig.byId.count)
                                                CreateEndpoints.shared.queue(endpointType: endpoint, endpointName: l_xmlName, endPointXML: "", endpointCurrent: counter, endpointCount: AvailableObjsToMig.byId.count, action: "create", sourceEpId: 0, destEpId: "0", ssIconName: "", ssIconId: "0", ssIconUri: "", retry: false) {
                                                    (result: String) in
                                                    completion(["skipped endpoint - \(endpoint)", "\(AvailableObjsToMig.byId.count)"])
                                                }
                                            } else {
                                                EndpointXml.shared.endPointByIdQueue(endpoint: endpoint, endpointID: "\(l_xmlID)", endpointCurrent: counter, endpointCount: AvailableObjsToMig.byId.count, action: "create", destEpId: 0, destEpName: l_xmlName)
                                            }
                                        }
                                        
                                    } else {
                                        if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] remove - endpoint: \(endpoint)\t endpointID: \(l_xmlID)\t endpointName: \(l_xmlName)") }
                                        if WipeData.state.on {
                                            RemoveObjects.shared.queue(endpointType: endpoint, endPointID: "\(l_xmlID)", endpointName: l_xmlName, endpointCurrent: counter, endpointCount: AvailableObjsToMig.byId.count)
                                        }
                                    }   // if !WipeData.state.on else - end
                                    counter+=1
                                }   // for (l_xmlID, l_xmlName) in AvailableObjsToMig.byId
                                RemoveObjects.shared.queue(endpointType: endpoint, endPointID: "-1", endpointName: "", endpointCurrent: -1, endpointCount: 0)
                            } else {
                                // populate source server under the selective tab - bulk
                                //                                                                        print("[getEndpoints] AvailableObjsToMig.byId: \(AvailableObjsToMig.byId)")
                                if !pref.stopMigration {
                                    //                                                                      print("-populate (\(endpoint)) source server under the selective tab")
                                    ListDelay.shared.milliseconds = (AvailableObjsToMig.byId.count > 1000) ? 0:listDelay(itemCount: AvailableObjsToMig.byId.count)
                                    for (l_xmlID, l_xmlName) in AvailableObjsToMig.byId {
                                        sortQ.async { [self] in
                                            //                                                                              print("[getEndpoints] adding \(l_xmlName) to array")
                                            AvailableObjsToMig.byName[l_xmlName] = "\(l_xmlID)"
                                            DataArray.source.append(l_xmlName)
                                            DataArray.source = DataArray.source.sorted{$0.localizedCaseInsensitiveCompare($1) == .orderedAscending}
                                            
                                            DataArray.staticSource = DataArray.source
                                            
                                            updateSelectiveList(objectName: l_xmlName, objectId: "\(l_xmlID)", fileContents: "")
                                            // slight delay in building the list - visual effect
                                            usleep(ListDelay.shared.milliseconds)
                                            
                                            if counter == AvailableObjsToMig.byId.count {
                                                nodesMigrated += 1
                                                //                                                                print("[\(#function)] \(#line) - finished getting \(endpoint)")
                                                goButtonEnabled(button_status: true)
                                            }
                                            counter+=1
                                        }   // sortQ.async - end
                                    }   // for (l_xmlID, l_xmlName) in AvailableObjsToMig.byId
                                }   // if !pref.stopMigration
                            }   // if UiVar.goSender else - end
                            // make into a func - end
                            
//                                if nodeIndex < nodesToMigrate.count - 1 {
//                                    readNodes(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1)
//                                }
                            if !(Setting.onlyCopyMissing || Setting.onlyCopyExisting) {
                                completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                            }
                        }
                        
                    } else {
                        // no objects were found
                        Endpoints.read += 1
                        // print("[Endpoints.read += 1] \(endpoint)")
                        
                        //                                            nodesMigrated+=1
                        updateGetStatus(endpoint: endpoint, total: 0)
                        putStatusUpdate(endpoint: endpoint, total: 0)
                        
//                            if nodeIndex < nodesToMigrate.count - 1 {
//                                self.readNodes(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1)
//                            }
                        completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                    }

                case "packages":
                    //                    var lookupCount    = 0
                    //                    var uniquePackages = [String]()
                    
                    if let endpointInfo = result as? [ExistingObject] {
                        endpointCount = endpointInfo.count
                        
                        
                        if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] Initial count for \(endpoint) found: \(endpointCount)") }
                        
                        if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] Verify empty dictionary of objects - AvailableObjsToMig.byId count: \(AvailableObjsToMig.byId.count)") }
                        
                        if endpointCount > 0 {
                            for thePackage in endpointInfo {
                                if let fileName = thePackage.fileName {
                                    AvailableObjsToMig.byId[thePackage.id] = fileName
                                }
                            }
                            
                            let skipLookup = (migrationMode == "bulk") ? false:true
                            ExistingObjects.shared.capi(skipLookup: skipLookup, theDestEndpoint: "\(endpoint)")  { [self]
                                (result: (String,String)) in
                                if pref.stopMigration {
                                    rmDELETE()
                                    completion(["migration stopped", "0"])
                                    return
                                }
                                
                                if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] returning existing packages endpoints: \(AvailableObjsToMig.byId)") }
                                
                                //                                                            completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                                //                                                            return
                                // make into a func - start
                                if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] Found total of \(AvailableObjsToMig.byId.count) \(endpoint) to process") }
                                
                                var counter = 1
                                if UiVar.goSender == "goButton" || UiVar.goSender == "silent" {
                                    
                                    Counter.shared.crud[endpoint]!["total"] = AvailableObjsToMig.byId.count
                                    
                                    for (l_xmlID, l_xmlName) in AvailableObjsToMig.byId {
                                        if !WipeData.state.on  {
                                            if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] check for ID of \(l_xmlName): \(currentEPs[l_xmlName] ?? 0)") }
                                            
                                            if currentEPDict[endpoint]?[l_xmlName] != nil {
                                                if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] \(l_xmlName) already exists") }
                                                if Setting.onlyCopyMissing {
                                                    updateGetStatus(endpoint: endpoint, total: AvailableObjsToMig.byId.count)
                                                    CreateEndpoints.shared.queue(endpointType: endpoint, endpointName: l_xmlName, endPointXML: "", endpointCurrent: counter, endpointCount: AvailableObjsToMig.byId.count, action: "update", sourceEpId: 0, destEpId: "0", ssIconName: "", ssIconId: "0", ssIconUri: "", retry: false) {
                                                        (result: String) in
                                                        completion(["skipped endpoint - \(endpoint)", "\(AvailableObjsToMig.byId.count)"])
                                                    }
                                                } else {
                                                    EndpointXml.shared.endPointByIdQueue(endpoint: endpoint, endpointID: "\(l_xmlID)", endpointCurrent: counter, endpointCount: AvailableObjsToMig.byId.count, action: "update", destEpId: currentEPDict[endpoint]![l_xmlName]!, destEpName: l_xmlName)
                                                }
                                            } else {
                                                if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] \(l_xmlName) - create") }
                                                if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] function - endpoint: \(endpoint), endpointID: \(l_xmlID), endpointCurrent: \(counter), endpointCount: \(endpointCount), action: \"create\", destEpId: 0") }
                                                if Setting.onlyCopyExisting {
                                                    updateGetStatus(endpoint: endpoint, total: AvailableObjsToMig.byId.count)
                                                    CreateEndpoints.shared.queue(endpointType: endpoint, endpointName: l_xmlName, endPointXML: "", endpointCurrent: counter, endpointCount: AvailableObjsToMig.byId.count, action: "create", sourceEpId: 0, destEpId: "0", ssIconName: "", ssIconId: "0", ssIconUri: "", retry: false) {
                                                        (result: String) in
                                                        completion(["skipped endpoint - \(endpoint)", "\(AvailableObjsToMig.byId.count)"])
                                                    }
                                                } else {
                                                    EndpointXml.shared.endPointByIdQueue(endpoint: endpoint, endpointID: "\(l_xmlID)", endpointCurrent: counter, endpointCount: AvailableObjsToMig.byId.count, action: "create", destEpId: 0, destEpName: l_xmlName)
                                                }
                                            }
                                        } else {
                                            if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] remove - endpoint: \(endpoint)\t endpointID: \(l_xmlID)\t endpointName: \(l_xmlName)") }
                                            if WipeData.state.on {
                                                RemoveObjects.shared.queue(endpointType: endpoint, endPointID: "\(l_xmlID)", endpointName: l_xmlName, endpointCurrent: counter, endpointCount: AvailableObjsToMig.byId.count)
                                            }
                                        }   // if !WipeData.state.on else - end
                                        counter+=1
                                    }   // for (l_xmlID, l_xmlName) in AvailableObjsToMig.byId
                                    RemoveObjects.shared.queue(endpointType: endpoint, endPointID: "-1", endpointName: "", endpointCurrent: -1, endpointCount: 0)
                                } else {
                                    // populate source server under the selective tab - bulk
                                    //                                                                        print("[getEndpoints] AvailableObjsToMig.byId: \(AvailableObjsToMig.byId)")
                                    if !pref.stopMigration {
                                        //                                                                      print("-populate (\(endpoint)) source server under the selective tab")
                                        ListDelay.shared.milliseconds = (AvailableObjsToMig.byId.count > 1000) ? 0:listDelay(itemCount: AvailableObjsToMig.byId.count)
                                        for (l_xmlID, l_xmlName) in AvailableObjsToMig.byId {
                                            sortQ.async { [self] in
                                                //                                                                              print("[getEndpoints] adding \(l_xmlName) to array")
                                                AvailableObjsToMig.byName[l_xmlName] = "\(l_xmlID)"
                                                DataArray.source.append(l_xmlName)
                                                DataArray.source = DataArray.source.sorted{$0.localizedCaseInsensitiveCompare($1) == .orderedAscending}
                                                
                                                DataArray.staticSource = DataArray.source
                                                
                                                updateSelectiveList(objectName: l_xmlName, objectId: "\(l_xmlID)", fileContents: "")
                                                // slight delay in building the list - visual effect
                                                usleep(ListDelay.shared.milliseconds)
                                                
                                                if counter == AvailableObjsToMig.byId.count {
                                                    nodesMigrated += 1
                                                    //                                                                print("[\(#function)] \(#line) - finished getting \(endpoint)")
                                                    goButtonEnabled(button_status: true)
                                                }
                                                counter+=1
                                            }   // sortQ.async - end
                                        }   // for (l_xmlID, l_xmlName) in AvailableObjsToMig.byId
                                    }   // if !pref.stopMigration
                                }   // if UiVar.goSender else - end
                                // make into a func - end
                                
//                                if nodeIndex < nodesToMigrate.count - 1 {
//                                    readNodes(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1)
//                                }
                                if !(Setting.onlyCopyMissing || Setting.onlyCopyExisting) {
                                    completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                                }
                            }
                        } else {
                            // no packages were found
                            Endpoints.read += 1
                            // print("[Endpoints.read += 1] \(endpoint)")
                            
                            //                                            nodesMigrated+=1
                            updateGetStatus(endpoint: endpoint, total: 0)
                            putStatusUpdate(endpoint: endpoint, total: 0)
                            
//                            if nodeIndex < nodesToMigrate.count - 1 {
//                                self.readNodes(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1)
//                            }
                            completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                        }   // if endpointCount > 0 - end
                    } else {   // end if let endpointInfo
                        updateGetStatus(endpoint: endpoint, total: 0)
                        putStatusUpdate(endpoint: endpoint, total: 0)
//                        if nodeIndex < nodesToMigrate.count - 1 {
//                            self.readNodes(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1)
//                        }
                        completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                    }
                case "patch-software-title-configurations":
                    do {
                        let jsonData = try? JSONSerialization.data(withJSONObject: result, options: [])
                        PatchTitleConfigurations.source = try JSONDecoder().decode([PatchSoftwareTitleConfiguration].self, from: jsonData!)
                        print("test count: \(PatchTitleConfigurations.source.count)")
                    } catch {
                        print("error getting patch software title configurations: \(error)")
                    }
                    //                    PatchTitleConfigurations.source = result as? [PatchSoftwareTitleConfiguration] ?? []   //try! JSONDecoder().decode(PatchSoftwareTitleConfigurations.self, from: data ?? Data())
                    
                    print("[getEndpoints] found \(PatchTitleConfigurations.source.count) patch objects on the source server")
                    AvailableObjsToMig.byId.removeAll()
                    
                    var displayNames = [String]()
                    for patchObject in PatchTitleConfigurations.source as [PatchSoftwareTitleConfiguration] {
                        var displayName = patchObject.displayName
                        if patchObject.softwareTitlePublisher.range(of: "(Deprecated Definition)") != nil {
                            displayName.append(" (Deprecated Definition)")
                        }
                        //                                        print("displayName: \(displayName)")
                        displayNames.append(displayName)
                        
                        if displayName.isEmpty {
                            AvailableObjsToMig.byId[Int(patchObject.id ?? "") ?? 0] = ""
                        } else {
                            AvailableObjsToMig.byId[Int(patchObject.id ?? "") ?? 0] = displayName
                        }
                    }
                    Endpoints.read += 1
                    
                    Endpoints.countDict["patch-software-title-configurations"] = AvailableObjsToMig.byId.count
                    
                    if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] Found total of \(AvailableObjsToMig.byId.count) \(endpoint) to process") }
                    
                    if endpoint == "patch-software-title-configurations" {
                        ExistingObjects.shared.capi(skipLookup: false, theDestEndpoint: "\(endpoint)")  { [self]
                            (result: (String,String)) in
                            print("[getEndpoints] fetch patch management dependencies from source server")
                            PatchDelegate.shared.getDependencies(whichServer: "source") { [self] result in
                                message_TextField.stringValue = ""
                                PatchDelegate.shared.getDependencies(whichServer: "dest") { [self] result in
                                    message_TextField.stringValue = ""
                                    
                                    var counter = 1
                                    if UiVar.goSender == "goButton" || !Setting.fullGUI {
                                        // export policy details if export.saveRawXml
                                        if export.saveRawXml {
                                            DispatchQueue.main.async {
                                                WriteToLog.shared.message("[getEndpoints] Exporting raw JSON for patch policy details")
                                                let exportFormat = (export.backupMode) ? "\(JamfProServer.source.fqdnFromUrl)_export_\(backupDate.string(from: History.startTime))":"raw"
                                                ExportItem.shared.export(node: "patchPolicyDetails", object: PatchPoliciesDetails.source, format: exportFormat)
                                                //                                                            ExportItem.shared.patchmanagement(node: "patchPolicyDetails", object: PatchPoliciesDetails.source, format: exportFormat)
                                            }
                                        }
                                        
//                                        print("[getEndpoints] \(#line) counters: \(Counter.shared.crud)")
                                        Counter.shared.crud[endpoint]!["total"] = AvailableObjsToMig.byId.count
                                        //                                                Counter.shared.crud["patch-software-title-configurations"]!["total"] = AvailableObjsToMig.byId.count
                                        
                                        if Setting.fullGUI {
                                            // display migrateDependencies button
                                            DispatchQueue.main.async {
                                                if !WipeData.state.on {
                                                    self.migrateDependencies.isHidden = false
                                                }
                                            }
                                        }
                                        
                                        if AvailableObjsToMig.byId.isEmpty {
                                            updateGetStatus(endpoint: endpoint, total: 0)
                                            putStatusUpdate(endpoint: endpoint, total: 0)
                                            Endpoints.read += 1
                                            completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                                            return
                                        }
                                        for (l_xmlID, l_xmlName) in AvailableObjsToMig.byId {
                                            if pref.stopMigration { break }
                                            if !WipeData.state.on  {
                                                if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] check for ID on \(l_xmlName): \(currentEPs[l_xmlName] ?? 0)") }
                                                
                                                if currentEPDict[endpoint]?[l_xmlName] != nil {
                                                    if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] \(l_xmlName) already exists") }
                                                    
                                                    if Setting.onlyCopyMissing {
                                                        updateGetStatus(endpoint: endpoint, total: AvailableObjsToMig.byId.count)
                                                        CreateEndpoints.shared.queue(endpointType: endpoint, endpointName: l_xmlName, endPointXML: "", endpointCurrent: counter, endpointCount: AvailableObjsToMig.byId.count, action: "update", sourceEpId: 0, destEpId: "0", ssIconName: "", ssIconId: "0", ssIconUri: "", retry: false) {
                                                            (result: String) in
                                                            completion(["skipped endpoint - \(endpoint)", "\(AvailableObjsToMig.byId.count)"])
                                                        }
                                                    } else {
                                                        EndpointXml.shared.endPointByIdQueue(endpoint: endpoint, endpointID: "\(l_xmlID)", endpointCurrent: counter, endpointCount: AvailableObjsToMig.byId.count, action: "update", destEpId: currentEPDict[endpoint]![l_xmlName]!, destEpName: l_xmlName)
                                                    }
                                                } else {
                                                    if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] \(l_xmlName) - create") }
                                                    if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] function - endpoint: \(endpoint), endpointID: \(l_xmlID), endpointCurrent: \(counter), endpointCount: \(endpointCount), action: \"create\", destEpId: 0") }
                                                    //                                                                    if (userDefaults.integer(forKey: "copyExisting") != 1) {
                                                    if Setting.onlyCopyExisting {
                                                        updateGetStatus(endpoint: endpoint, total: AvailableObjsToMig.byId.count)
                                                        CreateEndpoints.shared.queue(endpointType: endpoint, endpointName: l_xmlName, endPointXML: "", endpointCurrent: counter, endpointCount: AvailableObjsToMig.byId.count, action: "create", sourceEpId: 0, destEpId: "0", ssIconName: "", ssIconId: "0", ssIconUri: "", retry: false) {
                                                            (result: String) in
                                                            completion(["skipped endpoint - \(endpoint)", "\(AvailableObjsToMig.byId.count)"])
                                                        }
                                                    } else {
                                                        EndpointXml.shared.endPointByIdQueue(endpoint: endpoint, endpointID: "\(l_xmlID)", endpointCurrent: counter, endpointCount: AvailableObjsToMig.byId.count, action: "create", destEpId: 0, destEpName: l_xmlName)
                                                    }
                                                }
                                            } else {
                                                if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] remove - endpoint: \(endpoint)\t endpointID: \(l_xmlID)\t endpointName: \(l_xmlName)") }
                                                RemoveObjects.shared.queue(endpointType: endpoint, endPointID: "\(l_xmlID)", endpointName: l_xmlName, endpointCurrent: counter, endpointCount: AvailableObjsToMig.byId.count)
                                            }   // if !WipeData.state.on else - end
                                            counter+=1
                                        }   // for (l_xmlID, l_xmlName) in AvailableObjsToMig.byId
                                        if WipeData.state.on {
                                            RemoveObjects.shared.queue(endpointType: endpoint, endPointID: "-1", endpointName: "", endpointCurrent: -1, endpointCount: 0)
                                        }
                                    } else {
                                        // populate source server under the selective tab
                                        // print("populate (\(endpoint)) source server under the selective tab")
                                        AvailableObjsToMig.byName.removeAll()
                                        DataArray.source.removeAll()
                                        ListDelay.shared.milliseconds = listDelay(itemCount: AvailableObjsToMig.byId.count)
                                        for (l_xmlID, l_xmlName) in AvailableObjsToMig.byId {
                                            sortQ.async { [self] in
                                                //                                            print("adding \(l_xmlName) to array")
                                                AvailableObjsToMig.byName[l_xmlName] = "\(l_xmlID)"
                                                DataArray.source.append(l_xmlName)
                                                
                                                DataArray.source = DataArray.source.sorted{ $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
                                                
                                                DataArray.staticSource = DataArray.source
                                                updateSelectiveList(objectName: l_xmlName, objectId: "\(l_xmlID)", fileContents: "")
                                                
                                                DispatchQueue.main.async { [self] in
                                                    srcSrvTableView.reloadData()
                                                }
                                                // slight delay in building the list - visual effect
                                                usleep(ListDelay.shared.milliseconds)
                                                
                                                if counter == AvailableObjsToMig.byId.count {
                                                    nodesMigrated += 1
                                                    //                                                print("[\(#function)] \(#line) - finished getting \(endpoint)")
                                                    goButtonEnabled(button_status: true)
                                                }
                                                counter+=1
                                            }   // sortQ.async - end
                                        }   // for (l_xmlID, l_xmlName) in AvailableObjsToMig.byId
                                    }   // if UiVar.goSender else - end
                                    
                                    completion(displayNames)
                                }
                            }
                        }
                    }
                    
                case "advancedcomputersearches", "advancedmobiledevicesearches", "advancedusersearches", "buildings", "categories", "classes", "computerextensionattributes", "computers", "departments", "directorybindings", "diskencryptionconfigurations", "distributionpoints", "dockitems", "ldapservers", "macapplications", "mobiledeviceapplications", "mobiledeviceconfigurationprofiles", "mobiledeviceextensionattributes", "mobiledevices", "networksegments", "osxconfigurationprofiles", "patchpolicies", "printers", "restrictedsoftware", "scripts", "sites", "softwareupdateservers", "userextensionattributes", "users":
                    
//                    print("[getEndpoints] result: \(result.description)")
                    
                    if let endpointArray = result as? [[String: Any]], let endpointJson = endpointArray[0] as? [String: Any], let endpointInfo = endpointJson[endpointParent] as? [[String: Any]] /*endpointJSON[endpointParent] as? [Any]*/ {
                        
                        endpointCount = endpointInfo.count
                        if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] Initial count for \(endpoint) found: \(endpointCount)") }
                        
                        if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] Verify empty dictionary of objects - AvailableObjsToMig.byId count: \(AvailableObjsToMig.byId.count)") }
                        
                        if endpointCount > 0 {
                            // get existing (destination server) objects
                            ExistingObjects.shared.capi(skipLookup: false, theDestEndpoint: endpoint)  { [self]
                                (result: (String,String)) in
                                let (resultMessage, _) = result
                                //print("[ViewController.getSourceEndpoints] \(#function.short) \(endpoint) - returned from existing objects: \(resultMessage)")
                                if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] \(endpoint) - returned from existing objects: \(resultMessage)") }
                                
                                if pref.stopMigration {
                                    rmDELETE()
                                    completion(["migration stopped", "0"])
                                    return
                                }
                                
                                Endpoints.read += 1
                                // print("[Endpoints.read += 1] \(endpoint)")
                                
                                Endpoints.countDict[endpoint] = endpointCount
                                for i in (0..<endpointCount) {
                                    if i == 0 { AvailableObjsToMig.byId.removeAll() }
                                    
                                    let record = endpointInfo[i]
                                    
                                    if record["name"] != nil {
                                        AvailableObjsToMig.byId[record["id"] as! Int] = record["name"] as! String?
                                    } else {
                                        AvailableObjsToMig.byId[record["id"] as! Int] = ""
                                    }
                                    
                                }   // for i in (0..<endpointCount) end
                                if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] Found total of \(AvailableObjsToMig.byId.count) \(endpoint) to process") }
                                
                                var counter = 1
                                if UiVar.goSender == "goButton" || !Setting.fullGUI {
                                    
                                    Counter.shared.crud[endpoint]!["total"] = AvailableObjsToMig.byId.count
                                    
                                    for (l_xmlID, l_xmlName) in AvailableObjsToMig.byId {
                                        if pref.stopMigration { break }
                                        if !WipeData.state.on  {
                                            if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] check for ID on \(l_xmlName): \(currentEPs[l_xmlName] ?? 0)") }
                                            
                                            if currentEPDict[endpoint]?[l_xmlName] != nil {
                                                if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] \(l_xmlName) already exists") }
                                                
                                                if Setting.onlyCopyMissing {
                                                    updateGetStatus(endpoint: endpoint, total: AvailableObjsToMig.byId.count)
                                                    CreateEndpoints.shared.queue(endpointType: endpoint, endpointName: l_xmlName, endPointXML: "", endpointCurrent: counter, endpointCount: AvailableObjsToMig.byId.count, action: "update", sourceEpId: 0, destEpId: "0", ssIconName: "", ssIconId: "0", ssIconUri: "", retry: false) {
                                                        (result: String) in
                                                        completion(["skipped endpoint - \(endpoint)", "\(AvailableObjsToMig.byId.count)"])
                                                    }
                                                } else {
                                                    EndpointXml.shared.endPointByIdQueue(endpoint: endpoint, endpointID: "\(l_xmlID)", endpointCurrent: counter, endpointCount: AvailableObjsToMig.byId.count, action: "update", destEpId: currentEPDict[endpoint]![l_xmlName]!, destEpName: l_xmlName)
                                                }
                                            } else {
                                                if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] \(l_xmlName) - create") }
                                                if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] function - endpoint: \(endpoint), endpointID: \(l_xmlID), endpointCurrent: \(counter), endpointCount: \(endpointCount), action: \"create\", destEpId: 0") }
                                                
                                                if Setting.onlyCopyExisting {
                                                    updateGetStatus(endpoint: endpoint, total: AvailableObjsToMig.byId.count)
                                                    CreateEndpoints.shared.queue(endpointType: endpoint, endpointName: l_xmlName, endPointXML: "", endpointCurrent: counter, endpointCount: AvailableObjsToMig.byId.count, action: "create", sourceEpId: 0, destEpId: "0", ssIconName: "", ssIconId: "0", ssIconUri: "", retry: false) {
                                                        (result: String) in
                                                        completion(["skipped endpoint - \(endpoint)", "\(AvailableObjsToMig.byId.count)"])
                                                    }
                                                } else {
                                                    EndpointXml.shared.endPointByIdQueue(endpoint: endpoint, endpointID: "\(l_xmlID)", endpointCurrent: counter, endpointCount: AvailableObjsToMig.byId.count, action: "create", destEpId: 0, destEpName: l_xmlName)
                                                }
                                            }
                                        } else {
                                            if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] remove - endpoint: \(endpoint)\t endpointID: \(l_xmlID)\t endpointName: \(l_xmlName)") }
                                            RemoveObjects.shared.queue(endpointType: endpoint, endPointID: "\(l_xmlID)", endpointName: l_xmlName, endpointCurrent: counter, endpointCount: AvailableObjsToMig.byId.count)
                                        }   // if !WipeData.state.on else - end
                                        counter+=1
                                    }   // for (l_xmlID, l_xmlName) in AvailableObjsToMig.byId
                                    if WipeData.state.on {
                                        RemoveObjects.shared.queue(endpointType: endpoint, endPointID: "-1", endpointName: "", endpointCurrent: -1, endpointCount: 0)
                                    }
                                } else {
                                    // populate source server under the selective tab
                                    // print("populate (\(endpoint)) source server under the selective tab")
                                    ListDelay.shared.milliseconds = listDelay(itemCount: AvailableObjsToMig.byId.count)
                                    for (l_xmlID, l_xmlName) in AvailableObjsToMig.byId {
                                        sortQ.async { [self] in
                                            //                                                                print("adding \(l_xmlName) to array")
                                            AvailableObjsToMig.byName[l_xmlName] = "\(l_xmlID)"
                                            DataArray.source.append(l_xmlName)
                                            //                                                        if AvailableObjsToMig.byName.count == DataArray.source.count {
                                            DataArray.source = DataArray.source.sorted{$0.localizedCaseInsensitiveCompare($1) == .orderedAscending}
                                            
                                            DataArray.staticSource = DataArray.source
                                            updateSelectiveList(objectName: l_xmlName, objectId: "\(l_xmlID)", fileContents: "")
                                            
                                            
                                            DispatchQueue.main.async { [self] in
                                                srcSrvTableView.reloadData()
                                            }
                                            // slight delay in building the list - visual effect
                                            usleep(ListDelay.shared.milliseconds)
                                            
                                            if counter == AvailableObjsToMig.byId.count {
                                                nodesMigrated += 1
                                                //                                                print("[\(#function)] \(#line) - finished getting \(endpoint)")
                                                goButtonEnabled(button_status: true)
                                            }
                                            counter+=1
                                        }   // sortQ.async - end
                                    }   // for (l_xmlID, l_xmlName) in AvailableObjsToMig.byId
                                    
                                }   // if UiVar.goSender else - end
                            }
                            //                            }   // existingEndpoints - end
                        } else {
                            //                                            nodesMigrated+=1
                            updateGetStatus(endpoint: endpoint, total: 0)
                            putStatusUpdate(endpoint: endpoint, total: 0)
                            
                            Endpoints.read += 1
                        }   // if endpointCount > 0 - end
//                        if nodeIndex < nodesToMigrate.count - 1 {
//                            self.readNodes(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1)
//                        }
                        completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                    } else {   // end if let endpointInfo
                        updateGetStatus(endpoint: endpoint, total: 0)
                        putStatusUpdate(endpoint: endpoint, total: 0)
//                        if nodeIndex < nodesToMigrate.count - 1 {
//                            self.readNodes(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1)
//                        }
                        completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                    }
                    
                case "computergroups", "mobiledevicegroups", "usergroups":
                    if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] processing \(endpoint)") }
                    if let endpointArray = result as? [[String: Any]], let endpointJson = endpointArray[0] as? [String: Any], let endpointInfo = endpointJson[endpointParent] as? [[String: Any]] /*endpointJSON[endpointParent] as? [Any]*/ {
                        
                        //                        if Counter.shared.crud[endpoint] == nil {
                        //                            Counter.shared.crud[endpoint]    = ["create":0, "update":0, "fail":0, "skipped":0, "total":0]
                        //                            Counter.shared.summary[endpoint] = ["create":[], "update":[], "fail":[]]
                        //                        }
                        endpointCount = endpointInfo.count
                        if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] groups found: \(endpointCount)") }
                        
                        var smartGroupDict: [Int: String] = [:]
                        var staticGroupDict: [Int: String] = [:]
                        
                        if endpointCount > 0 {
                            //                            ExistingObjects.shared.capi(skipLookup: false, theDestEndpoint: "\(endpoint)")  { [self]
                            //                                (result: (String,String)) in
                            ExistingObjects.shared.capi(skipLookup: false, theDestEndpoint: endpoint)  { [self]
                                (result: (String,String)) in
                                let (resultMessage, _) = result
                                //print("[ViewController.getSourceEndpoints] \(#function.short) \(endpoint) - returned from existing objects: \(resultMessage)")
                                if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] \(endpoint) - returned from existing objects: \(resultMessage)") }
                                
                                if pref.stopMigration {
                                    rmDELETE()
                                    completion(["migration stopped", "0"])
                                    return
                                }

                                // find number of groups
                                smartCount = 0
                                staticCount = 0
                                var excludeCount = 0
                                
                                Endpoints.read += 1
                                // print("[Endpoints.read += 1] \(endpoint)")
                                
                                // split computergroups into smart and static - start
                                for i in (0..<endpointCount) {
                                    let record = endpointInfo[i]
                                    
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
                                
                                if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] \(smartGroupDict.count) smart groups") }
                                if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] \(staticGroupDict.count) static groups") }
                                var currentGroupDict: [Int: String] = [:]
                                
                                // verify we have some groups
                                for g in (0...1) {
                                    currentGroupDict.removeAll()
                                    var groupCount = 0
                                    var localEndpoint = endpoint
                                    switch endpoint {
                                    case "computergroups":
                                        if (smartComputerGrpsSelected || (UiVar.goSender != "goButton" && groupType == "smart")) && (g == 0) {
                                            currentGroupDict = smartGroupDict
                                            groupCount = currentGroupDict.count
                                            localEndpoint = "smartcomputergroups"
                                        }
                                        if (staticComputerGrpsSelected || (UiVar.goSender != "goButton" && groupType == "static")) && (g == 1) {
                                            currentGroupDict = staticGroupDict
                                            groupCount = currentGroupDict.count
                                            localEndpoint = "staticcomputergroups"
                                        }
                                    case "mobiledevicegroups":
                                        if ((smartIosGrpsSelected) || (UiVar.goSender != "goButton" && groupType == "smart")) && (g == 0) {
                                            currentGroupDict = smartGroupDict
                                            groupCount = currentGroupDict.count
                                            localEndpoint = "smartmobiledevicegroups"
                                        }
                                        if ((staticIosGrpsSelected) || (UiVar.goSender != "goButton" && groupType == "static")) && (g == 1) {
                                            currentGroupDict = staticGroupDict
                                            groupCount = currentGroupDict.count
                                            localEndpoint = "staticmobiledevicegroups"
                                        }
                                    case "usergroups":
                                        if ((smartUserGrpsSelected) || (UiVar.goSender != "goButton" && groupType == "smart")) && (g == 0) {
                                            currentGroupDict = smartGroupDict
                                            groupCount = currentGroupDict.count
                                            //                                                        DeviceGroupType = "smartcomputergroups"
                                            //                                                        print("usergroups smart - DeviceGroupType: \(DeviceGroupType)")
                                            localEndpoint = "smartusergroups"
                                        }
                                        if ((staticUserGrpsSelected) || (UiVar.goSender != "goButton" && groupType == "static")) && (g == 1) {
                                            currentGroupDict = staticGroupDict
                                            groupCount = currentGroupDict.count
                                            //                                                        DeviceGroupType = "staticcomputergroups"
                                            //                                                        print("usergroups static - DeviceGroupType: \(DeviceGroupType)")
                                            localEndpoint = "staticusergroups"
                                        }
                                    default: break
                                    }
                                    
                                    var counter = 1
                                    ListDelay.shared.milliseconds = listDelay(itemCount: currentGroupDict.count)
                                    
                                    Endpoints.countDict[localEndpoint] = groupCount
                                    
                                    if currentGroupDict.count == 0 && (localEndpoint == "smartcomputergroups" || localEndpoint == "staticcomputergroups" || localEndpoint == "smartmobiledevicegroups" || localEndpoint == "staticmobiledevicegroups") {
                                        updateGetStatus(endpoint: localEndpoint, total: 0)
                                        putStatusUpdate(endpoint: localEndpoint, total: 0)
                                    }
                                    
                                    Counter.shared.crud[endpoint]!["total"] = currentGroupDict.count
                                    
                                    for (l_xmlID, l_xmlName) in currentGroupDict {
                                        AvailableObjsToMig.byId[l_xmlID] = l_xmlName
                                        if UiVar.goSender == "goButton" || UiVar.goSender == "silent" {
                                            if !WipeData.state.on  {
                                                //need to call existingEndpoints here to keep proper order?
                                                if currentEPs[l_xmlName] != nil {
                                                    if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] \(l_xmlName) already exists") }
                                                    
                                                    if Setting.onlyCopyMissing {
                                                        updateGetStatus(endpoint: endpoint, total: AvailableObjsToMig.byId.count)
                                                        CreateEndpoints.shared.queue(endpointType: endpoint, endpointName: l_xmlName, endPointXML: "", endpointCurrent: counter, endpointCount: AvailableObjsToMig.byId.count, action: "update", sourceEpId: 0, destEpId: "0", ssIconName: "", ssIconId: "0", ssIconUri: "", retry: false) {
                                                            (result: String) in
                                                            completion(["skipped endpoint - \(endpoint)", "\(AvailableObjsToMig.byId.count)"])
                                                        }
                                                    } else {
                                                        EndpointXml.shared.endPointByIdQueue(endpoint: localEndpoint, endpointID: "\(l_xmlID)", endpointCurrent: counter, endpointCount: groupCount, action: "update", destEpId: currentEPs[l_xmlName]!, destEpName: l_xmlName)
                                                        //                                                                            endPointByIDQueue(endpoint: localEndpoint, endpointID: "\(l_xmlID)", endpointCurrent: counter, endpointCount: groupCount, action: "update", destEpId: currentEPs[l_xmlName]!, destEpName: l_xmlName)
                                                    }
                                                    
                                                } else {
                                                    if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] \(l_xmlName) - create") }
                                                    if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] function - endpoint: \(localEndpoint), endpointID: \(l_xmlID), endpointCurrent: \(counter), endpointCount: \(groupCount), action: \"create\", destEpId: 0") }
                                                    
                                                    if Setting.onlyCopyExisting {
                                                        updateGetStatus(endpoint: endpoint, total: AvailableObjsToMig.byId.count)
                                                        CreateEndpoints.shared.queue(endpointType: endpoint, endpointName: l_xmlName, endPointXML: "", endpointCurrent: counter, endpointCount: AvailableObjsToMig.byId.count, action: "create", sourceEpId: 0, destEpId: "0", ssIconName: "", ssIconId: "0", ssIconUri: "", retry: false) {
                                                            (result: String) in
                                                            completion(["skipped endpoint - \(endpoint)", "\(AvailableObjsToMig.byId.count)"])
                                                        }
                                                    } else {
                                                        EndpointXml.shared.endPointByIdQueue(endpoint: localEndpoint, endpointID: "\(l_xmlID)", endpointCurrent: counter, endpointCount: groupCount, action: "create", destEpId: 0, destEpName: l_xmlName)
                                                        //                                                                        endPointByIDQueue(endpoint: localEndpoint, endpointID: "\(l_xmlID)", endpointCurrent: counter, endpointCount: groupCount, action: "create", destEpId: 0, destEpName: l_xmlName)
                                                    }
                                                    
                                                }
                                            } else {
                                                RemoveObjects.shared.queue(endpointType: localEndpoint, endPointID: "\(l_xmlID)", endpointName: l_xmlName, endpointCurrent: counter, endpointCount: groupCount)
                                            }   // if !WipeData.state.on else - end
                                            counter += 1
                                        } else {
                                            // populate source server under the selective tab
                                            sortQ.async { [self] in
                                                //                                                                print("adding \(l_xmlName) to array")
                                                AvailableObjsToMig.byName[l_xmlName] = "\(l_xmlID)"
                                                DataArray.source.append(l_xmlName)
                                                
                                                DataArray.staticSource = DataArray.source
                                                updateSelectiveList(objectName: l_xmlName, objectId: "\(l_xmlID)", fileContents: "")
                                                
                                                //                                                                    DispatchQueue.main.async { [self] in
                                                //                                                                        srcSrvTableView.reloadData()
                                                //                                                                    }
                                                // slight delay in building the list - visual effect
                                                usleep(ListDelay.shared.milliseconds)
                                                
                                                if counter == DataArray.source.count {
                                                    
                                                    sortList(theArray: DataArray.source) { [self]
                                                        (result: [String]) in
                                                        DataArray.source = result
                                                        DispatchQueue.main.async { [self] in
                                                            srcSrvTableView.reloadData()
                                                        }
                                                        //                                                        print("[\(#function)] \(#line) - finished getting \(endpoint)")
                                                        goButtonEnabled(button_status: true)
                                                    }
                                                }
                                                counter += 1
                                            }   // sortQ.async - end
                                        }   // if UiVar.goSender else - end
                                    }   // for (l_xmlID, l_xmlName) - end
                                    
                                    nodesMigrated+=1
                                    if WipeData.state.on && (UiVar.goSender == "goButton" || UiVar.goSender == "silent") {
                                        RemoveObjects.shared.queue(endpointType: endpoint, endPointID: "-1", endpointName: "", endpointCurrent: -1, endpointCount: 0)
                                    }
                                    
                                }   //for g in (0...1) - end
                            }
                            //                            }   // existingEndpoints(skipLookup: false, theDestEndpoint: "\(endpoint)") - end
                        } else {    //if endpointCount > 0 - end
                            //                                            nodesMigrated+=1
                            updateGetStatus(endpoint: endpoint, total: 0)
                            putStatusUpdate(endpoint: endpoint, total: 0)
                            
                            Endpoints.read += 1
                            // print("[Endpoints.read += 1] \(endpoint)")
                            //                                            if endpoint == ToMigrate.objects.last {
                            //                                                if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] Reached last object to migrate: \(endpoint)") }
                            //                                                self.rmDELETE()
                            //                                            }
                        }   // else if endpointCount > 0 - end
//                        if nodeIndex < nodesToMigrate.count - 1 {
//                            self.readNodes(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1)
//                        }
                        completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                    } else {  // if let endpointInfo = endpointJSON["computer_groups"] - end
                        updateGetStatus(endpoint: endpoint, total: 0)
                        putStatusUpdate(endpoint: endpoint, total: 0)
//                        if nodeIndex < nodesToMigrate.count - 1 {
//                            self.readNodes(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1)
//                        }
                        completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                    }
                    
                case "policies":
                    //                                    print("[ViewController.getSourceEndpoints] processing policies")
                    if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] processing policies") }
                    if let endpointArray = result as? [[String: Any]], let endpointJson = endpointArray[0] as? [String: Any], let endpointInfo = endpointJson[endpointParent] as? [[String: Any]] /*endpointJSON[endpointParent] as? [Any]*/ {
//                        print("[getEndpoints] \(endpoint) endpointInfo: \(endpointInfo)")
                        endpointCount = endpointInfo.count
                        
                        if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] policies found: \(endpointCount)") }
                        
                        var computerPoliciesDict: [Int: String] = [:]
                        
                        if endpointCount > 0 {
                            if pref.stopMigration {
                                self.rmDELETE()
                                completion(["migration stopped", "0"])
                                return
                            }
                            if Setting.fullGUI {
                                // display migrateDependencies button
                                DispatchQueue.main.async {
                                    if !WipeData.state.on {
                                        self.migrateDependencies.isHidden = false
                                    }
                                }
                            }
                            
                            // create dictionary of existing policies
                            ExistingObjects.shared.capi(skipLookup: false, theDestEndpoint: "policies")  { [self]
                                (result: (String,String)) in
                                let (resultMessage, _) = result
                                //print("[ViewController.getSourceEndpoints] \(#function.short) \(endpoint) - returned from existing objects: \(resultMessage)")
                                if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] policies - returned from existing endpoints: \(resultMessage)") }
                                
                                // filter out policies created from jamf remote (casper remote) - start
                                for i in (0..<endpointCount) {
                                    let record = endpointInfo[i] //as! [String : AnyObject]
                                    let nameCheck = record["name"] as! String
                                    
                                    if nameCheck.range(of:"[0-9]{4}-[0-9]{2}-[0-9]{2} at [0-9]", options: .regularExpression) == nil && nameCheck != "Update Inventory" {
                                        computerPoliciesDict[record["id"] as! Int] = nameCheck
                                    }
                                }
                                // filter out policies created from casper remote - end
                                
                                AvailableObjsToMig.byId = computerPoliciesDict
                                let nonRemotePolicies = computerPoliciesDict.count
                                var counter = 1
                                
                                ListDelay.shared.milliseconds = listDelay(itemCount: computerPoliciesDict.count)
                                //                                                print("[ViewController.getSourceEndpoints] [policies] policy count: \(nonRemotePolicies)")    // appears 2
                                
                                Endpoints.read += 1
                                // print("[Endpoints.read += 1] \(endpoint)")
                                Endpoints.countDict[endpoint] = computerPoliciesDict.count
                                if computerPoliciesDict.count == 0 {
                                    Endpoints.read += 1
                                    nodesMigrated+=1    // ;print("added node: \(endpoint) - getEndpoints2")
                                    // print("[Endpoints.read += 1] \(endpoint)")
                                } else {
                                    
                                    Counter.shared.crud[endpoint]!["total"] = computerPoliciesDict.count
                                    
                                    for (l_xmlID, l_xmlName) in computerPoliciesDict {
                                        if UiVar.goSender == "goButton" || UiVar.goSender == "silent" {
                                            if !WipeData.state.on  {
                                                if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] check for ID on \(l_xmlName): \(String(describing: currentEPs[l_xmlName]))") }
                                                //                                                        if currentEPs[l_xmlName] != nil {
                                                if currentEPDict[endpoint]?[l_xmlName] != nil {
                                                    if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] \(l_xmlName) already exists") }
                                                    
                                                    if Setting.onlyCopyMissing {
                                                        updateGetStatus(endpoint: endpoint, total: AvailableObjsToMig.byId.count)
                                                        CreateEndpoints.shared.queue(endpointType: endpoint, endpointName: l_xmlName, endPointXML: "", endpointCurrent: counter, endpointCount: nonRemotePolicies, action: "update", sourceEpId: 0, destEpId: "0", ssIconName: "", ssIconId: "0", ssIconUri: "", retry: false) {
                                                            (result: String) in
                                                            completion(["skipped endpoint - \(endpoint)", "\(AvailableObjsToMig.byId.count)"])
                                                        }
                                                    } else {
                                                        EndpointXml.shared.endPointByIdQueue(endpoint: endpoint, endpointID: "\(l_xmlID)", endpointCurrent: counter, endpointCount: nonRemotePolicies, action: "update", destEpId: currentEPDict[endpoint]![l_xmlName]!, destEpName: l_xmlName)
                                                        //                                                                        endPointByIDQueue(endpoint: endpoint, endpointID: "\(l_xmlID)", endpointCurrent: counter, endpointCount: nonRemotePolicies, action: "update", destEpId: currentEPDict[endpoint]![l_xmlName]!, destEpName: l_xmlName)
                                                    }
                                                    
                                                } else {
                                                    if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] \(l_xmlName) - create") }
                                                    if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] function - endpoint: \(endpoint), endpointID: \(l_xmlID), endpointCurrent: \(counter), endpointCount: \(endpointCount), action: \"create\", destEpId: 0") }
                                                    
                                                    if Setting.onlyCopyExisting {
                                                        updateGetStatus(endpoint: endpoint, total: AvailableObjsToMig.byId.count)
                                                        CreateEndpoints.shared.queue(endpointType: endpoint, endpointName: l_xmlName, endPointXML: "", endpointCurrent: counter, endpointCount: nonRemotePolicies, action: "create", sourceEpId: 0, destEpId: "0", ssIconName: "", ssIconId: "0", ssIconUri: "", retry: false) {
                                                            (result: String) in
                                                            completion(["skipped endpoint - \(endpoint)", "\(AvailableObjsToMig.byId.count)"])
                                                        }
                                                    } else {
                                                        EndpointXml.shared.endPointByIdQueue(endpoint: endpoint, endpointID: "\(l_xmlID)", endpointCurrent: counter, endpointCount: nonRemotePolicies, action: "create", destEpId: 0, destEpName: l_xmlName)
                                                        //                                                                        endPointByIDQueue(endpoint: endpoint, endpointID: "\(l_xmlID)", endpointCurrent: counter, endpointCount: nonRemotePolicies, action: "create", destEpId: 0, destEpName: l_xmlName)
                                                    }
                                                    
                                                }
                                            } else {
                                                if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] remove - endpoint: \(endpoint)\t endpointID: \(l_xmlID)\t endpointName: \(l_xmlName)") }
                                                RemoveObjects.shared.queue(endpointType: endpoint, endPointID: "\(l_xmlID)", endpointName: l_xmlName, endpointCurrent: counter, endpointCount: nonRemotePolicies)
                                            }   // if !WipeData.state.on else - end
                                            counter += 1
                                        } else {
                                            // populate source server under the selective tab
                                            sortQ.async { [self] in
                                                AvailableObjsToMig.byName[l_xmlName+" (\(l_xmlID))"] = "\(l_xmlID)"
                                                DataArray.source.append(l_xmlName+" (\(l_xmlID))")
                                                DataArray.source = DataArray.source.sorted{$0.localizedCaseInsensitiveCompare($1) == .orderedAscending}
                                                
                                                DataArray.staticSource = DataArray.source
                                                updateSelectiveList(objectName: l_xmlName, objectId: "\(l_xmlID)", fileContents: "")
                                                
                                                //                                                                    DispatchQueue.main.async { [self] in
                                                //                                                                        srcSrvTableView.reloadData()
                                                //                                                                    }
                                                // slight delay in building the list - visual effect
                                                usleep(ListDelay.shared.milliseconds)
                                                
                                                if counter == computerPoliciesDict.count {
                                                    nodesMigrated += 1
                                                    //                                                    print("[\(#function)] \(#line) - finished getting \(endpoint)")
                                                    goButtonEnabled(button_status: true)
                                                }
                                                counter+=1
                                            }   // sortQ.async - end
                                            
                                        }   // if UiVar.goSender else - end
                                    }   // for (l_xmlID, l_xmlName) in computerPoliciesDict - end
                                }   // else for (l_xmlID, l_xmlName) - end
                                if WipeData.state.on && (UiVar.goSender == "goButton" || UiVar.goSender == "silent") {
                                    RemoveObjects.shared.queue(endpointType: endpoint, endPointID: "-1", endpointName: "", endpointCurrent: -1, endpointCount: 0)
                                }
                            }   // existingEndpoints - end
                        } else {
                            //                                            nodesMigrated+=1
                            updateGetStatus(endpoint: endpoint, total: 0)
                            putStatusUpdate(endpoint: endpoint, total: 0)
                            
                            Endpoints.read += 1
                           
//                            completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                        }   // if endpointCount > 0
//                        print("[ViewController.getSourceEndpoints] [policies] Got endpoint - \(endpoint)", "\(endpointCount)")
                        completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                    } else {   //if let endpointInfo = endpointJSON - end
                        updateGetStatus(endpoint: endpoint, total: 0)
                        putStatusUpdate(endpoint: endpoint, total: 0)
                        Endpoints.read += 1
                        completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                    }
                    
                case "jamfusers", "jamfgroups":
//                    var endpointInfo = [[String: Any]]()
                    
                    if let endpointArray = result as? [[String: Any]], let endpointJson = endpointArray[0] as? [String: Any], let usersGroups = endpointJson["accounts"] as? [String: Any], let endpointInfo = usersGroups[endpointParent] as? [[String: Any]] {
                        
//                        endpointInfo = usersGroups[endpointParent] as? [[String: Any]] ?? []
                        print("endpointInfo: \(endpointInfo)")
                        
                        endpointCount = endpointInfo.count
                        if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] Initial count for \(endpoint) found: \(endpointCount)") }
                        
                        if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] Verify empty dictionary of objects - AvailableObjsToMig.byId count: \(AvailableObjsToMig.byId.count)") }
                        
                        if endpointCount > 0 {
                            
                            ExistingObjects.shared.capi(skipLookup: false, theDestEndpoint: "ldapservers")  {
                                (result: (String,String)) in
                                if pref.stopMigration {
                                    self.rmDELETE()
                                    completion(["migration stopped", "0"])
                                    return
                                }
                                let (resultMessage, _) = result
                                //print("[ViewController.getSourceEndpoints] \(#function.short) ldapservers - returned from existing objects: \(resultMessage)")
                                if LogLevel.debug { WriteToLog.shared.message("[getEndpoints-LDAP] Returned from existing ldapservers: \(resultMessage)") }
                                
                                ExistingObjects.shared.capi(skipLookup: false, theDestEndpoint: endpoint)  { [self]
                                    (result: (String,String)) in
                                    let (resultMessage, _) = result
                                    //print("[ViewController.getSourceEndpoints] \(#function.short) \(node) - returned from existing objects: \(resultMessage)")
                                    if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] Returned from existing \(node): \(resultMessage)") }
                                    
                                    Endpoints.read += 1
                                    // print("[Endpoints.read += 1] \(endpoint)")
                                    Endpoints.countDict[endpoint] = endpointCount
                                    
                                    Counter.shared.crud[endpoint]!["total"] = endpointCount
                                    
                                    for i in (0..<endpointCount) {
                                        if i == 0 { AvailableObjsToMig.byId.removeAll() }
                                        
                                        let record = endpointInfo[i] as! [String : AnyObject]
                                        if !(endpoint == "jamfusers" && record["name"] as! String? == dest_user) {
                                            AvailableObjsToMig.byId[record["id"] as! Int] = record["name"] as! String?
                                        }
                                        
                                        if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] Current number of \(endpoint) to process: \(AvailableObjsToMig.byId.count)") }
                                    }   // for i in (0..<endpointCount) end
                                    if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] Found total of \(AvailableObjsToMig.byId.count) \(endpoint) to process") }
                                    
                                    var counter = 1
                                    if UiVar.goSender == "goButton" || UiVar.goSender == "silent" {
                                        if AvailableObjsToMig.byId.count == 0 && endpoint == "jamfusers"{
                                            updateGetStatus(endpoint: endpoint, total: 0)
                                            putStatusUpdate(endpoint: endpoint, total: 0)
                                        }
                                        for (l_xmlID, l_xmlName) in AvailableObjsToMig.byId {
                                            if !WipeData.state.on  {
                                                if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] check for ID on \(l_xmlName): \(String(describing: currentEPs[l_xmlName]))") }
                                                
                                                if currentEPs[l_xmlName] != nil {
                                                    if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] \(l_xmlName) already exists") }
                                                    
                                                    EndpointXml.shared.endPointByIdQueue(endpoint: endpoint, endpointID: "\(l_xmlID)", endpointCurrent: counter, endpointCount: AvailableObjsToMig.byId.count, action: "update", destEpId: currentEPs[l_xmlName]!, destEpName: l_xmlName)
                                                    //                                                                    endPointByIDQueue(endpoint: endpoint, endpointID: "\(l_xmlID)", endpointCurrent: counter, endpointCount: AvailableObjsToMig.byId.count, action: "update", destEpId: currentEPs[l_xmlName]!, destEpName: l_xmlName)
                                                } else {
                                                    if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] \(l_xmlName) - create") }
                                                    if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] function - endpoint: \(endpoint), endpointID: \(l_xmlID), endpointCurrent: \(counter), endpointCount: \(endpointCount), action: \"create\", destEpId: 0") }
                                                    EndpointXml.shared.endPointByIdQueue(endpoint: endpoint, endpointID: "\(l_xmlID)", endpointCurrent: counter, endpointCount: AvailableObjsToMig.byId.count, action: "create", destEpId: 0, destEpName: l_xmlName)
                                                    //                                                                    endPointByIDQueue(endpoint: endpoint, endpointID: "\(l_xmlID)", endpointCurrent: counter, endpointCount: AvailableObjsToMig.byId.count, action: "create", destEpId: 0, destEpName: l_xmlName)
                                                }
                                            } else {
                                                if !(endpoint == "jamfusers" && "\(l_xmlName)".lowercased() == dest_user.lowercased()) {
                                                    if LogLevel.debug { WriteToLog.shared.message("[ViewController.getSourceEndpoints] remove - endpoint: \(endpoint)\t endpointID: \(l_xmlID)\t endpointName: \(l_xmlName)") }
                                                    RemoveObjects.shared.queue(endpointType: endpoint, endPointID: "\(l_xmlID)", endpointName: l_xmlName, endpointCurrent: counter, endpointCount: AvailableObjsToMig.byId.count)
                                                }
                                                
                                            }   // if !WipeData.state.on else - end
                                            counter+=1
                                        }   // for (l_xmlID, l_xmlName) in AvailableObjsToMig.byId
                                        if WipeData.state.on {
                                            RemoveObjects.shared.queue(endpointType: endpoint, endPointID: "-1", endpointName: "", endpointCurrent: -1, endpointCount: 0)
                                        }
                                    } else {
                                        // populate source server under the selective tab
                                        ListDelay.shared.milliseconds = listDelay(itemCount: AvailableObjsToMig.byId.count)
                                        for (l_xmlID, l_xmlName) in AvailableObjsToMig.byId {
                                            sortQ.async { [self] in
                                                //                                                                    print("adding \(l_xmlName) to array")
                                                AvailableObjsToMig.byName[l_xmlName] = "\(l_xmlID)"
                                                DataArray.source.append(l_xmlName)
                                                
                                                DataArray.source = DataArray.source.sorted{$0.localizedCaseInsensitiveCompare($1) == .orderedAscending}
                                                
                                                DataArray.staticSource = DataArray.source
                                                
                                                updateSelectiveList(objectName: l_xmlName, objectId: "\(l_xmlID)", fileContents: "")
                                                
                                                //                                                                    DispatchQueue.main.async { [self] in
                                                //                                                                        srcSrvTableView.reloadData()
                                                //                                                                    }
                                                // slight delay in building the list - visual effect
                                                usleep(ListDelay.shared.milliseconds)
                                                
                                                if counter == AvailableObjsToMig.byId.count {
                                                    nodesMigrated += 1
                                                    //                                                    print("[\(#function)] \(#line) - finished getting \(endpoint)")
                                                    goButtonEnabled(button_status: true)
                                                }
                                                counter+=1
                                            }   // sortQ.async - end
                                        }   // for (l_xmlID, l_xmlName) in AvailableObjsToMig.byId
                                    }   // if UiVar.goSender else - end
                                    
//                                    if nodeIndex < nodesToMigrate.count - 1 {
//                                        self.readNodes(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1)
//                                    }
                                    completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                                    
                                }   // existingEndpoints - end
                            }
                            
                        } else {
                            updateGetStatus(endpoint: endpoint, total: 0)
                            putStatusUpdate(endpoint: endpoint, total: 0)
                            
                            Endpoints.read += 1
                            // print("[Endpoints.read += 1] \(endpoint)")
                            //                                            if endpoint == ToMigrate.objects.last {
                            //                                                self.rmDELETE()
                            ////                                                completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                            //                                            }
//                            if nodeIndex < nodesToMigrate.count - 1 {
//                                self.readNodes(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1)
//                            }
                            completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                        }   // if endpointCount > 0 - end
                    } else {   // end if let buildings, departments...
                        updateGetStatus(endpoint: endpoint, total: 0)
                        putStatusUpdate(endpoint: endpoint, total: 0)
//                        if nodeIndex < nodesToMigrate.count - 1 {
//                            self.readNodes(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1)
//                        }
                        completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                    }
                    
                default:
                    print("")
                }
            }
        }
        
    }   // func getEndpoints - end
    
    func readDataFiles(nodesToMigrate: [String], nodeIndex: Int, completion: @escaping (_ result: String) -> Void) {
        
        logFunctionCall()
        if LogLevel.debug { WriteToLog.shared.message("[readDataFiles] enter") }
        
        if JamfProServer.source.last != "/" {
            JamfProServer.source = JamfProServer.source + "/"
        }
        importFilesUrl = URL(string: "file://\(JamfProServer.source.replacingOccurrences(of: " ", with: "%20"))")
        
        if LogLevel.debug { WriteToLog.shared.message("[readDataFiles] JamfProServer.source: \(JamfProServer.source)") }
        
        var local_general       = ""
        let endpoint            = nodesToMigrate[nodeIndex]
        print("[readDataFiles] endpoint: \(endpoint)")
        
        switch endpoint {
        case "computergroups", "smartcomputergroups", "staticcomputergroups":
            Counter.shared.progressArray["smartcomputergroups"]  = 0
            Counter.shared.progressArray["staticcomputergroups"] = 0
            Counter.shared.progressArray["computergroups"]       = 0 // this is the recognized end point
        case "mobiledevicegroups", "smartmobiledevicegroups", "staticmobiledevicegroups":
            Counter.shared.progressArray["smartmobiledevicegroups"]  = 0
            Counter.shared.progressArray["staticmobiledevicegroups"] = 0
            Counter.shared.progressArray["mobiledevicegroups"]       = 0 // this is the recognized end point
        case "usergroups", "smartusergroups", "staticusergroups":
            Counter.shared.progressArray["smartusergroups"]  = 0
            Counter.shared.progressArray["staticusergroups"] = 0
            Counter.shared.progressArray["usergroups"]       = 0 // this is the recognized end point
        case "accounts", "jamfusers", "jamfgroups":
            Counter.shared.progressArray["jamfusers"]  = 0
            Counter.shared.progressArray["jamfgroups"] = 0
            Counter.shared.progressArray["accounts"]   = 0 // this is the recognized end point
        default:
            Counter.shared.progressArray["\(nodesToMigrate[nodeIndex])"] = 0
        }

        if LogLevel.debug { WriteToLog.shared.message("[readDataFiles]       Data files root: \(JamfProServer.source)") }
        if LogLevel.debug { WriteToLog.shared.message("[readDataFiles] Working with endpoint: \(endpoint)") }

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

            WriteToLog.shared.message("[readDataFiles] scanning: \(directoryPath) for files.")
            do {
                let allFiles = FileManager.default.enumerator(atPath: "\(directoryPath)")

                if let allFilePaths = allFiles?.allObjects {
                    let allFilePathsArray = allFilePaths as! [String]
                    var xmlFilePaths      = [String]()
                    
//                    print("[ViewController.files] looking for files in \(local_folder)")
                    switch local_folder {
                    case "buildings", "patch-software-title-configurations", "api-integrations", "api-roles":
                        xmlFilePaths = allFilePathsArray.filter{$0.contains(".json")} // filter for only files with json extension
                        if local_folder == "patch-software-title-configurations" {
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
                                    WriteToLog.shared.message("[readDataFiles] patch-policies-policy-details.json - issue converting to json")
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
//                    print("[ViewController.files] found \(dataFilesCount) files in \(local_folder)")
                    var counter = 1
                    
                    if dataFilesCount < 1 {
//                        if setting.fullGUI {
//                            DispatchQueue.main.async {
//                                self.alert_dialog(header: "Attention:", message: "No files found.  If the folder exists outside the Downloads directory, reselect it with the Browse button and try again.")
//                            }
//                        } else {
                            WriteToLog.shared.message("[readDataFiles] No files found.  If the import folder exists outside the Downloads directory and files are expected, reselect the import folder with with either the File Imprort or the Browse button and try again.")
//                            DispatchQueue.main.async {
//                                NSApplication.shared.terminate(self)
//                            }
//                        }
                        completion("no files found for: \(endpoint)")
                    } else {
                        if LogLevel.debug { WriteToLog.shared.message("[readDataFiles] Found \(dataFilesCount) files for endpoint: \(endpoint)") }
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
                                case "api-roles", "api-integrations":
                                    let data = fileContents.data(using: .utf8)!
                                    do {
                                        if let jsonData = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as? [String:Any]
                                        {
                                            name     = "\(jsonData["displayName"] ?? "")"
                                            id       = "\(jsonData["id"] ?? "")"
                                        } else {
                                            WriteToLog.shared.message("[readDataFiles] \(endpoint) - issue with string format, not json")
                                        }
                                    } catch let error as NSError {
                                        print(error)
                                    }
                                case "buildings":
                                    let data = fileContents.data(using: .utf8)!
                                    do {
                                        if let jsonData = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as? [String:Any]
                                        {
                                            name     = "\(jsonData["name"] ?? "")"
                                            id       = "\(jsonData["id"] ?? "")"
                                        } else {
                                            WriteToLog.shared.message("[readDataFiles] buildings - issue with string format, not json")
                                        }
                                    } catch let error as NSError {
                                        print(error)
                                    }
                                case "patch-software-title-configurations":
                                    let data = fileContents.data(using: .utf8) ?? Data()
                                    do {
                                        let patchObject = try JSONDecoder().decode(PatchSoftwareTitleConfiguration.self, from: data)
//                                        if let jsonData = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as? [String:Any]
//                                        {
//                                                fileJSON = jsonData
                                            name = patchObject.displayName //"\(jsonData["name"] ?? "")"
                                            id   = patchObject.id ?? "" //"\(jsonData["id"] ?? "")"
//                                        } else {
//                                            WriteToLog.shared.message("[readDataFiles] buildings - issue with string format, not json")
//                                        }
                                    } catch let error as NSError {
                                        WriteToLog.shared.message("[readDataFiles] \(endpoint) - issue converting to json")
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

                                if !["buildings", "patch-software-title-configurations", "api-roles", "api-integrations"].contains(endpoint) {
                                    id   = tagValue2(xmlString:local_general, startTag:"<id>", endTag:"</id>")
                                    name = tagValue2(xmlString:local_general, startTag:"<name>", endTag:"</name>")
                                }
                                
                                displayNameToFilename[name]       = dataFile
                                availableFilesToMigDict[dataFile] = [id, name, fileContents]
                                targetSelectiveObjectList.append(SelectiveObject(objectName: name, objectId: id, fileContents: fileContents))
                                
                                if LogLevel.debug { WriteToLog.shared.message("[readDataFiles] read \(local_folder): file name : object name - \(dataFile)  :  \(name), id: \(id)") }
                                // populate selective list, when appropriate
                                if UiVar.goSender == "selectToMigrateButton" {
//                                  print("fileImport - goSender: \(UiVar.goSender)")
//                                        print("adding \(name) to array")
                                          
                                    AvailableObjsToMig.byName[name] = id
                                    DataArray.source.append(name)
                                    DataArray.source = DataArray.source.sorted{$0.localizedCaseInsensitiveCompare($1) == .orderedAscending}

                                    DataArray.staticSource = DataArray.source
                                    
                                    print("[readDataFiles] add \(name) (id: \(id)) to sourceObjectList_AC")
                                    updateSelectiveList(objectName: name, objectId: id, fileContents: fileContents)
                                    
                                    // slight delay in building the list - visual effect
                                    usleep(ListDelay.shared.milliseconds)

                                    if counter == dataFilesCount {
                                        nodesMigrated += 1
                                        DispatchQueue.main.async { [self] in
                                            spinner_progressIndicator.stopAnimation(self)
                                        }
//                                        print("[\(#function)] \(#line) - finished reading \(endpoint)")
                                        goButtonEnabled(button_status: true)
                                    }
                                    counter+=1
                                }
                                
                            } catch {
                                //                    print("unable to read \(dataFile)")
                                if LogLevel.debug { WriteToLog.shared.message("[readDataFiles] unable to read \(dataFile)") }
                            }
//                                getStatusUpdate(endpoint: local_folder, current: i, total: dataFilesCount)
                        }   // for i in 1...dataFilesCount - end
                        
                        let fileCount = availableFilesToMigDict.count
                    
                        if LogLevel.debug { WriteToLog.shared.message("[readDataFiles] Node: \(local_folder) has \(fileCount) files.") }
                    }
                } else {   // if let allFilePaths - end
                    WriteToLog.shared.message("[readDataFiles] No files found.  If the import folder exists outside the Downloads directory and files are expected, reselect the import folder with with either the File Imprort or the Browse button and try again.")
                    completion("no files found for: \(endpoint)")
                }
            } //catch {
                //if LogLevel.debug { WriteToLog.shared.message("[readDataFiles] Node: \(local_folder): unable to get files.") }
            //}

//            var fileCount = self.availableFilesToMigDict.count
            var fileCount = targetSelectiveObjectList.count
         
            if LogLevel.debug { WriteToLog.shared.message("[readDataFiles] Node: \(local_folder) has \(fileCount) files.") }
             
            if fileCount > 0 {
            //                    print("[readDataFiles] call processFiles for \(endpoint), nodeIndex \(nodeIndex) of \(nodesToMigrate)")
             if UiVar.goSender == "goButton" || UiVar.goSender == "silent" {
                 self.processFiles(endpoint: endpoint, fileCount: fileCount, itemsDict: self.availableFilesToMigDict) { [self]
                     (result: String) in
                     if LogLevel.debug { WriteToLog.shared.message("[readDataFiles] Returned from processFiles.") }
            //                        print("[readDataFiles] returned from processFiles for \(endpoint), nodeIndex \(nodeIndex) of \(nodesToMigrate)")
                     self.availableFilesToMigDict.removeAll()
                     targetSelectiveObjectList.removeAll()
                     
                     if nodeIndex < nodesToMigrate.count - 1 {
                         self.readDataFiles(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1) {
                             (result: String) in
                             if LogLevel.debug { WriteToLog.shared.message("[ViewController.readDataFiles] processFiles result: \(result)") }
                         }
                     }
                     completion("fetched xml for: \(endpoint)")
                 }
             }
            } else {   // if fileCount - end
             WriteToLog.shared.message("[readDataFiles] \(endpoint) fileCount = 0.")
             
            //                 nodesMigrated+=1    // ;print("added node: \(endpoint) - readDataFiles2")
             updateGetStatus(endpoint: endpoint, total: fileCount)
             putStatusUpdate(endpoint: endpoint, total: fileCount)
             
             if nodeIndex < nodesToMigrate.count - 1 {
                 self.readDataFiles(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1) {
                     (result: String) in
                     if LogLevel.debug { WriteToLog.shared.message("[ViewController.readDataFiles] no files found for: \(local_folder)") }
                 }
             }
             completion("fetched xml for: \(endpoint)")
            }
            fileCount = 0

        }   // self.theOpQ - end
    }   // func readDataFiles - end
    
    func processFiles(endpoint: String, fileCount: Int, itemsDict: [String:[String]] = [:], completion: @escaping (_ result: String) -> Void) {
        logFunctionCall()
        
        let skipLookup = (UiVar.activeTab == "Selective") ? true:false
        ExistingObjects.shared.capi(skipLookup: skipLookup, theDestEndpoint: "\(endpoint)") { [self]
            (result: (String,String)) in
            let (resultMessage, _) = result
            //print("[ViewController.processFiles] \(#function.short) \(endpoint) - returned from existing objects: \(resultMessage)")
            if LogLevel.debug { WriteToLog.shared.message("[processFiles] Returned from existing \(endpoint): \(resultMessage)") }
            
            readFilesQ.maxConcurrentOperationCount = 1

            var l_index = 1
            for theObject in targetSelectiveObjectList {
//                print("[processFiles] object name: \(theObject.objectName.xmlDecode)")
                readFilesQ.addOperation { [self] in
                    let l_id   = theObject.objectId         // id of object
                    let l_name = theObject.objectName.xmlDecode    // name of object, remove xml encoding
                    let l_xml  = theObject.fileContents
                    
//                    print("[processFiles] l_id: \(l_id), l_name: \(theObject.objectName.xmlDecode), l_xml: \(l_xml)")
                    updateGetStatus(endpoint: endpoint, total: targetSelectiveObjectList.count, index: l_index)
                    
//                    if l_id != nil && l_name != "" && l_xml != "" {
                    if l_id != "" && l_name != "" && l_xml != "" {
                        if !WipeData.state.on  {
                            if LogLevel.debug { WriteToLog.shared.message("[processFiles] check for ID on \(String(describing: l_name)): \(currentEPs[l_name] ?? 0)") }
                            if currentEPs["\(l_name)"] != nil {
                                if LogLevel.debug { WriteToLog.shared.message("[processFiles] \(endpoint):\(String(describing: l_name)) already exists") }
                                
                                print("[processFiles] update endpoint: \(endpoint)")
                                switch endpoint {
                                case "buildings":
                                    let data = l_xml.data(using: .utf8)!
                                    var jsonData = [String:Any]()
                                    var action = "update"
                                    do {
                                        if let _ = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as? [String: Any] {
                                            jsonData = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as! [String: Any]
                                            WriteToLog.shared.message("[ViewController.processFiles] JSON file for \(l_name) successfully parsed.")
                                        } else {
                                            WriteToLog.shared.message("[ViewController.processFiles] JSON file \(theObject.fileContents) failed to parse.")
                                            action = "skip"
                                        }
                                    } catch let error as NSError {
                                        WriteToLog.shared.message("[ViewController.processFiles] file \(theObject.fileContents) failed to parse. Error: \(error.localizedDescription)")
                                        action = "skip"
                                    }
                                    Cleanup.shared.Json(endpoint: endpoint, JSON: jsonData, endpointID: l_id, endpointCurrent: l_index, endpointCount: fileCount, action: action, destEpId: "\(currentEPs[l_name] ?? 0)", destEpName: l_name) {
//                                    cleanupJSON(endpoint: endpoint, JSON: jsonData, endpointID: l_id, endpointCurrent: l_index, endpointCount: fileCount, action: action, destEpId: currentEPs[l_name]!, destEpName: l_name) {
                                        (cleanJSON: String) in
                                        if LogLevel.debug { WriteToLog.shared.message("[processFiles] [\(endpoint)]: Returned from cleanupJSON") }
                                        if cleanJSON == "last" {
                                            completion("processed last file")
                                        }
                                    }
                                case "patch-software-title-configurations":
                                    PatchDelegate.shared.getDependencies(whichServer: "dest") { result in
                                        self.message_TextField.stringValue = ""
                                        let data = l_xml.data(using: .utf8)!
                                        var jsonData = [String:Any]()
                                        var action = "update"
                                        do {
                                            if let _ = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as? [String: Any] {
                                                jsonData = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as! [String: Any]
                                                WriteToLog.shared.message("[ViewController.processFiles] JSON file for \(l_name) successfully parsed.")
                                            } else {
                                                WriteToLog.shared.message("[ViewController.processFiles] JSON file \(theObject.fileContents) failed to parse.")
                                                action = "skip"
                                            }
                                        } catch let error as NSError {
                                            WriteToLog.shared.message("[ViewController.processFiles] file \(theObject.fileContents) failed to parse. Error: \(error.description)")
                                            //                                        print(error)
                                            action = "skip"
                                        }
                                        
                                        Cleanup.shared.Json(endpoint: endpoint, JSON: jsonData, endpointID: l_id, endpointCurrent: l_index, endpointCount: fileCount, action: action, destEpId: "\(currentEPs[l_name] ?? 0)", destEpName: l_name) {
                                            (cleanJSON: String) in
                                            if LogLevel.debug { WriteToLog.shared.message("[processFiles] [\(endpoint)]: Returned from cleanupJSON") }
                                            if cleanJSON == "last" {
                                                completion("processed last file")
                                            }
                                        }
                                    }
                                default:
                                    Cleanup.shared.Xml(endpoint: endpoint, Xml: l_xml, endpointID: l_id, endpointCurrent: l_index, endpointCount: fileCount, action: "update", destEpId: "\(currentEPs[l_name] ?? 0)", destEpName: l_name) {
                                        (result: String) in
                                        if LogLevel.debug { WriteToLog.shared.message("[processFiles] [\(endpoint)]: Returned from cleanupXml") }
                                        if result == "last" {
                                            completion("processed last file")
                                        }
                                    }
                                }
                            } else {
                                print("[processFiles] create endpoint: \(endpoint)")
                                if LogLevel.debug { WriteToLog.shared.message("[processFiles] \(endpoint):\(String(describing: l_name)) - create") }
                                
                                switch endpoint {
                                case "buildings":
                                    let data = l_xml.data(using: .utf8)!
                                    var jsonData = [String:Any]()
                                    var action = "create"
                                    do {
                                        if let _ = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as? [String:Any] {
                                            jsonData = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as! [String:Any]
                                            WriteToLog.shared.message("[ViewController.processFiles] JSON file for \(l_name) successfully parsed.")
                                        } else {
                                            WriteToLog.shared.message("[ViewController.processFiles] JSON file \(theObject.fileContents) failed to parse.")
                                            action = "skip"
                                        }
                                    } catch let error as NSError {
                                        WriteToLog.shared.message("[ViewController.processFiles] file \(theObject.fileContents) failed to parse.")
                                        print(error)
                                        action = "skip"
                                    }
                                    
                                    Cleanup.shared.Json(endpoint: endpoint, JSON: jsonData, endpointID: l_id, endpointCurrent: l_index, endpointCount: fileCount, action: action, destEpId: "0", destEpName: l_name) {
                                        (cleanJSON: String) in
                                        if LogLevel.debug { WriteToLog.shared.message("[processFiles] [\(endpoint)]: Returned from cleanupJSON") }
                                        if cleanJSON == "last" {
                                            completion("processed last file")
                                        }
                                    }
                                case "patch-software-title-configurations":
                                    PatchDelegate.shared.getDependencies(whichServer: "dest") { result in
                                        self.message_TextField.stringValue = ""
                                        let data = l_xml.data(using: .utf8)!
                                        var jsonData = [String:Any]()
                                        var action = "create"
                                        do {
                                            if let _ = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as? [String:Any] {
                                                jsonData = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as! [String:Any]
                                                WriteToLog.shared.message("[ViewController.processFiles] JSON file for \(l_name) successfully parsed.")
                                            } else {
                                                WriteToLog.shared.message("[ViewController.processFiles] JSON file \(theObject.fileContents) failed to parse.")
                                                action = "skip"
                                            }
                                        } catch let error as NSError {
                                            WriteToLog.shared.message("[ViewController.processFiles] file \(theObject.fileContents) failed to parse.")
                                            print(error)
                                            action = "skip"
                                        }
                                        
                                        Cleanup.shared.Json(endpoint: endpoint, JSON: jsonData, endpointID: l_id, endpointCurrent: l_index, endpointCount: fileCount, action: action, destEpId: "0", destEpName: l_name) {
                                            (cleanJSON: String) in
                                            if LogLevel.debug { WriteToLog.shared.message("[processFiles] [\(endpoint)]: Returned from cleanupJSON") }
                                            if cleanJSON == "last" {
                                                completion("processed last file")
                                            }
                                        }
                                    }
                                default:
                                    Cleanup.shared.Xml(endpoint: endpoint, Xml: l_xml, endpointID: l_id, endpointCurrent: l_index, endpointCount: fileCount, action: "create", destEpId: "0", destEpName: l_name) {
                                        (result: String) in
                                        if LogLevel.debug { WriteToLog.shared.message("[processFiles] [\(endpoint)]: Returned from cleanupXml") }
                                        if result == "last" {
                                            completion("processed last file")
                                        }
                                    }
                                }
                            }
                        }   // if !WipeData.state.on - end
                    } else {
                        let theName = "name: \(l_name)  id: \(l_id)"
                        if endpoint != "buildings" {
                            Cleanup.shared.Xml(endpoint: endpoint, Xml: l_xml, endpointID: l_id, endpointCurrent: l_index, endpointCount: fileCount, action: "create", destEpId: "\(currentEPs[l_name] ?? 0)", destEpName: theName) {
                                (result: String) in
                                if LogLevel.debug { WriteToLog.shared.message("[processFiles] [\(endpoint)]: Returned from cleanupXml") }
                                if result == "last" {
                                    completion("processed last file")
                                }
                            }
                        } else {
                            Cleanup.shared.Json(endpoint: endpoint, JSON: ["name":theName], endpointID: l_id, endpointCurrent: l_index, endpointCount: fileCount, action: "skip", destEpId: "0", destEpName: l_name) {
                                (cleanJSON: String) in
                                if LogLevel.debug { WriteToLog.shared.message("[processFiles] [\(endpoint)]: Returned from cleanupJSON") }
                                if cleanJSON == "last" {
                                    completion("processed last file")
                                }
                            }
                        }
                        if LogLevel.debug { WriteToLog.shared.message("[processFiles] [\(endpoint)]: trouble with \(theObject.fileContents)") }
                    }
                    l_index+=1
                    usleep(25000)  // slow the file read process
                }   // readFilesQ.sync - end
                usleep(25000)  // slow the file read process
            }   // for (_, objectInfo) - end
        }
    }
    
    func updatePendingCounter(caller: String, change: Int) {
        logFunctionCall()
        DispatchQueue.global().async {
//            self.lockQueue.async {
//                print("[updatePendingCounter] called from: \(caller), change: \(change)")
                Counter.shared.pendingSend += change
//            }
        }
    }
    
    func getDependencies(objectIndex: Int, selectedEndpoint: String, selectedObjectList: [SelectiveObject], completion: @escaping (_ returnedDependencies: [ObjectAndDependency]) -> Void) {
        logFunctionCall()
        WriteToLog.shared.message("[getDependencies] enter")
        
        let primaryObjId    = Int(selectedObjectList[objectIndex].objectId)
        let objToMigrateId  = selectedObjectList[objectIndex].objectId
        let primaryObjName  = selectedObjectList[objectIndex].objectName
        
        var idPath                = ""  // adjust for jamf users/groups that use userid/groupid instead of id
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
            case "patch-software-title-configurations":
                rawEndpoint = "patch-software-title-configurations"
            default:
                rawEndpoint = selectedEndpoint
        }
                    
        let endpointToLookup = fileImport ? "skip":"\(rawEndpoint)/\(idPath)\(String(describing: primaryObjId!))"
        
        print("[getDependencies] endpointToLookup: \(endpointToLookup)")
        Json.shared.getRecord(whichServer: "source", base64Creds: JamfProServer.base64Creds["source"] ?? "", theEndpoint: endpointToLookup, endpointBase: selectedEndpoint, endpointId: objToMigrateId)  { [self]
            (objectRecord: Any) in
            
            var json = [String: AnyObject]()
            switch selectedEndpoint {
            case "patch-software-title-configurations":
                do {
                    let jsonData = try JSONEncoder().encode(objectRecord as! PatchSoftwareTitleConfiguration)
                    if let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: AnyObject] {
                        json = jsonObject
                    }
                } catch {
                    
                }
            default:
                json = objectRecord as? [String: AnyObject] ?? [:]
            }
            
            print("[getDependencies] json: \(json)")
            
            //        }
            if json.count == 0 {
                ObjectAndDependencies.records.append(ObjectAndDependency(objectType: selectedEndpoint, objectName: primaryObjName, objectId: objToMigrateId))
                completion(ObjectAndDependencies.records)
                return
            }
            
            var objectDict           = [String:Any]()
            var fullDependencyDict   = [String: [String:String]]()    // full list of dependencies of a single policy
            //        var allDependencyDict  = [String: [String:String]]()    // all dependencies of all selected policies
            var dependencyArray      = [String:String]()
//            var waitForPackageLookup = false
            
//            if setting.migrateDependencies {
            var dependencyNode = ""
            
            print("look up dependencies for \(selectedEndpoint)")
        
            switch selectedEndpoint {
            case "policies":
                objectDict      = json["policy"] as! [String:Any]
                let general     = objectDict["general"] as! [String:Any]
                let bindings    = objectDict["account_maintenance"] as! [String:Any]
                let scope       = objectDict["scope"] as! [String:Any]
                let scripts     = objectDict["scripts"] as! [[String:Any]]
        
                let exclusions  = scope["exclusions"] as! [String:Any]
                let limitations = scope["limitations"] as! [String:Any]
                
                for the_dependency in Dependencies.orderedArray {
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
                        if (Scope.policiesCopy && dependencyNode == "computer_groups") || (dependencyNode != "computer_groups") {
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
                        let packages = objectDict["package_configuration"] as! [String:Any]
                        if let _ = packages[dependencyNode] {
                            let packages_dep = packages[dependencyNode] as! [AnyObject]
//                            if packages_dep.count > 0 { waitForPackageLookup = true }
                            var completedPackageLookups = 0
                            for theObject in packages_dep {
                                //                             let local_name = (theObject as! [String:Any])["name"]
                                //                             print("lookup package filename for display name \(String(describing: local_name!))")
                                let local_id   = (theObject as! [String:Any])["id"]
                                
                                // todo - update to use jpapi packages?
                                PackagesDelegate.shared.getFilename(whichServer: "source", theServer: JamfProServer.source, base64Creds: JamfProServer.base64Creds["source"] ?? "", theEndpoint: "packages", theEndpointID: local_id as! Int, skip: WipeData.state.on, currentTry: 1) {
                                    (result: (Int,String)) in
                                    let (_,packageFilename) = result
                                    if packageFilename != "" {
                                        dependencyArray["\(packageFilename)"] = "\(local_id!)"
                                    } else {
                                        WriteToLog.shared.message("[getDependencies] package filename lookup failed for package ID \(String(describing: local_id))")
                                    }
                                    completedPackageLookups += 1
                                    if completedPackageLookups == packages_dep.count {
//                                        waitForPackageLookup = false
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
            case "patch-software-title-configurations":
                if let packages = json["packages"] as? [[String: Any]] {
                    var completedPackageLookups = 0
                    for thePackage in packages {
                        if let local_id = thePackage["packageId"] as? String, let fileName = Packages.source.filter({ $0.id == local_id }).first?.fileName {
                            
                                if fileName != "" {
                                dependencyArray["\(fileName)"] = local_id
                            } else {
                                WriteToLog.shared.message("[getDependencies] package filename lookup failed for package ID \(String(describing: local_id))")
                            }
                        }
                        completedPackageLookups += 1
                        if completedPackageLookups == packages.count {
                            fullDependencyDict["packages"] = dependencyArray.count == 0 ? nil:dependencyArray
                        }
                    }
                }
                if let siteId = json["siteId"] as? String, siteId != "-1", let siteName = json["siteName"] as? String {
                    fullDependencyDict["sites"] = [siteName: siteId]
                }
            default:
                if LogLevel.debug { WriteToLog.shared.message("[getDependencies] not implemented for \(selectedEndpoint).") }
                //                print("return empty fullDependencyDict")
                completion([])
            }
                
            if LogLevel.debug { WriteToLog.shared.message("[getDependencies] dependencies: \(fullDependencyDict)") }
            WriteToLog.shared.message("[getDependencies] complete")
            var tmpCount = 1
//            DispatchQueue.global(qos: .utility).async { [self] in
//                while waitForPackageLookup && tmpCount <= 60 {
//                    //                print("trying to resolve package filename(s), attempt \(tmpCount)")
//                    sleep(1)
//                    tmpCount += 1
//                }
                
            print("[getDependencies] fullDependencyDict: \(fullDependencyDict)")
            Dependencies.current.removeAll()
            for (theObject, _) in fullDependencyDict {
                Dependencies.current.append(theObject)
            }
                // put dependencies in order, then add parent
                var lookupCount = 0
                if allObjects.count == 0 {
                    ObjectAndDependencies.records.append(ObjectAndDependency(objectType: selectedEndpoint, objectName: primaryObjName, objectId: objToMigrateId))
                    completion(ObjectAndDependencies.records)
                    return
                }
                for theObject in allObjects {
                    if let dependencies = fullDependencyDict[theObject], dependencies.count > 0 {
                        print("found \(dependencies.count) dependencies for \(theObject)")
                        var skipLookup: Bool = false
                        if theObject == selectedEndpoint {
                            skipLookup = true
                            lookupCount += 1
                        }
                        ExistingObjects.shared.capi(skipLookup: skipLookup, theDestEndpoint: theObject) { [self]
                            (result: (String,String)) in
                            ExistingEndpoints.shared.waiting = false
                            let (_, theObjectType) = result
                            print("[getDependencies] theObjectType: \(theObjectType)")
//                            for (name, id) in dependencies {
                            for (name, id) in fullDependencyDict[theObjectType] ?? [:] {
                                print("     name: \(name) - id: \(id)")
                                ObjectAndDependencies.records.append(ObjectAndDependency(objectType: theObjectType, objectName: name, objectId: id))
                            }
                            lookupCount += 1
                            print("\(#line) theObjectType: \(theObjectType) - lookupCount: \(lookupCount) - allObjects: \(allObjects.count)")
                            if lookupCount == allObjects.count {
                                ExistingObjects.shared.capi(skipLookup: skipLookup, theDestEndpoint: selectedEndpoint) {
                                    (result: (String,String)) in
                                    let (_, theObjectType) = result
                                    let parentObject = (theObjectType == "patch-software-title-configurations") ? "patch-software-title-configurations":theObjectType
                                    print("last theObjectType: \(theObjectType)")
                                    ObjectAndDependencies.records.append(ObjectAndDependency(objectType: parentObject, objectName: primaryObjName, objectId: objToMigrateId))
                                    completion(ObjectAndDependencies.records)
                                }
                            }
                        }
                    } else {
                        lookupCount += 1
                        print("\(#line) theObject: \(theObject) - lookupCount: \(lookupCount) - allObjects: \(allObjects.count)")
                        if lookupCount == allObjects.count {
                            ExistingObjects.shared.capi(skipLookup: false, theDestEndpoint: selectedEndpoint) {
                                (result: (String,String)) in
                                let (_, theObjectType) = result
                                let parentObject = (theObjectType == "patch-software-title-configurations") ? "patch-software-title-configurations":theObjectType
                                ObjectAndDependencies.records.append(ObjectAndDependency(objectType: parentObject, objectName: primaryObjName, objectId: objToMigrateId))
                                completion(ObjectAndDependencies.records)
                            }
                        }
                    }
                }
//            }
        }
    }
    
    @IBAction func migrateDependencies_fn(_ sender: Any) {
        logFunctionCall()
        Setting.migrateDependencies = migrateDependencies.state == .on ? true:false
    }
    
    //==================================== Utility functions ====================================
    func alert_dialog(header: String, message: String) {
        logFunctionCall()
        NSApplication.shared.activate(ignoringOtherApps: true)
        let dialog: NSAlert = NSAlert()
        dialog.messageText = header
        dialog.informativeText = message
        dialog.alertStyle = NSAlert.Style.warning
        dialog.addButton(withTitle: "OK")
        dialog.runModal()
        //return true
    }   // func alert_dialog - end
    
    func clearProcessingFields() {
        logFunctionCall()
        DispatchQueue.main.async { [self] in
            get_name_field.stringValue    = ""
            put_name_field.stringValue    = ""

            getSummary_label.stringValue  = ""
            get_levelIndicator.floatValue = 0.0
            get_levelIndicator.isEnabled  = false

            putSummary_label.stringValue  = ""
            put_levelIndicator.floatValue = 0.0
            put_levelIndicator.isEnabled  = false
        }
    }
    
    func clearSelectiveList() {
        logFunctionCall()
        DispatchQueue.main.async { [self] in
            if !selectiveListCleared && srcSrvTableView.isEnabled {
                
                generalSectionToMigrate_button.selectItem(at: 0)
                sectionToMigrate_button.selectItem(at: 0)
                iOSsectionToMigrate_button.selectItem(at: 0)
                selectiveFilter_TextField.stringValue = ""

                ToMigrate.objects.removeAll()
                Endpoints.countDict.removeAll()
                DataArray.source.removeAll()
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
        logFunctionCall()
        if (whichserver == "source" && !WipeData.state.on) || (whichserver == "dest" && WipeData.state.on) || (srcSrvTableView.isEnabled == false) {
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

        logFunctionCall()
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
    
//    func disable(theXML: String) -> String {
//        let regexDisable    = try? NSRegularExpression(pattern: "<enabled>true</enabled>", options:.caseInsensitive)
//        let newXML          = (regexDisable?.stringByReplacingMatches(in: theXML, options: [], range: NSRange(0..<theXML.utf16.count), withTemplate: "<enabled>false</enabled>"))!
//  
//        return newXML
//    }
    
    func runComplete() {
//        print("[runComplete] enter")
//        DispatchQueue.main.async { [self] in
        logFunctionCall()
        migrationComplete.isDone = true
        print("[runComplete] Queue.shared.operation.operationCount: \(Queue.shared.operation.operationCount)")
        if theIconsQ.operationCount == 0 && Queue.shared.operation.operationCount == 0 {
                nodesComplete = 0
                AllEndpointsArray.removeAll()
                AvailableObjsToMig.byId.removeAll()
                
                Iconfiles.policyDict.removeAll()
                Iconfiles.pendingDict.removeAll()
                
                if Setting.fullGUI {
                    DispatchQueue.main.async { [self] in
                        let (h,m,s, _) = timeDiff(forWhat: "runTime")
                        WriteToLog.shared.message("[Migration Complete] runtime: \(Utilities.shared.dd(value: h)):\(Utilities.shared.dd(value: m)):\(Utilities.shared.dd(value: s)) (h:m:s)")
                        spinner_progressIndicator.stopAnimation(self)
                        resetAllCheckboxes()
                    }
                }

                if WipeData.state.on {
                    rmDELETE()
                }
//                print("[\(#function)] \(#line) - finished")
                goButtonEnabled(button_status: true)
                
                if Setting.fullGUI {
                    DispatchQueue.main.async { [self] in
                        spinner_progressIndicator.stopAnimation(self)
                        go_button.title = "Go!"
                        _ = enableSleep()
                    }
                } else {
                    // silent run complete
                    Headless.shared.runComplete(backupDate: backupDate, nodesMigrated: nodesMigrated, objectsToMigrate: ToMigrate.objects, counters: Counter.shared.crud)
                    
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
//                                    WriteToLog.shared.message("[Backup Complete] Backup created: \(export.saveLocation)\(JamfProServer.source.fqdnFromUrl)_export_\(backupDate.string(from: History.startTime)).zip")
//                                    
//                                    let (h,m,s, _) = timeDiff(forWhat: "runTime")
//                                    WriteToLog.shared.message("[Backup Complete] runtime: \(Utilities.shared.dd(value: h)):\(Utilities.shared.dd(value: m)):\(Utilities.shared.dd(value: s)) (h:m:s)")
//                                } catch let error as NSError {
//                                    if LogLevel.debug { WriteToLog.shared.message("Unable to delete backup folder! Something went wrong: \(error)") }
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
//                            let sortedObjects = ToMigrate.objects.sorted()
//                            // find longest length of objects migrated
//                            var column1Padding = ""
//                            for theObject in ToMigrate.objects {
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
//                                if Counter.shared.crud[theObject] != nil {
//                                    let counts = Counter.shared.crud[theObject]!
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
//                            WriteToLog.shared.message(summary)
//                            let (h,m,s, _) = timeDiff(forWhat: "runTime")
//                            WriteToLog.shared.message("[Migration Complete] runtime: \(Utilities.shared.dd(value: h)):\(Utilities.shared.dd(value: m)):\(Utilities.shared.dd(value: s)) (h:m:s)")
//                            
//                            logCleanup()
//                            NSApplication.shared.terminate(self)
//                        }
//                    }
                }
        } else {
            DispatchQueue.main.async { [self] in
                print("[runComplete] waiting for queues to clear")
                sleep(2)
                runComplete()
            }
        }
//        }
    }
    
    func goButtonEnabled(button_status: Bool) {
        logFunctionCall()
        if Setting.fullGUI {
            DispatchQueue.main.async { [self] in
                if button_status {
                    spinner_progressIndicator.stopAnimation(self)
                } else {
                    spinner_progressIndicator.startAnimation(self)
                }
                if button_status {
                    if WipeData.state.on {
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
        logFunctionCall()
        if itemCount > 1000 { return 0 }
        
        let delayFactor = (itemCount < 10) ? 10:itemCount
        
        let factor = (50000000/delayFactor/delayFactor)
        if factor > 50000 {
            return 50000
        } else {
            return UInt32(factor)
        }
    }
    
    func updateGetStatus(endpoint: String, total: Int, index: Int = -1) {
        logFunctionCall()
        if WipeData.state.on { return }
        print("[updateGetStatus] endpoint: \(endpoint), total: \(total), index: \(index)")
        var adjEndpoint = ""
        switch endpoint {
        case "accounts/userid":
            adjEndpoint = "jamfusers"
        case "accounts/groupid":
            adjEndpoint = "jamfgroups"
        default:
            adjEndpoint = endpoint
        }
        
//        if index == -1 {
//            if getCounters[adjEndpoint] == nil {
//                getCounters[adjEndpoint] = ["get":1]
//            } else {
//                getCounters[adjEndpoint]!["get"]! += 1
//            }
//        } else {
//            getCounters[adjEndpoint] = ["get":index]
//        }
        
        if index == -1 {
            if Counter.shared.get[adjEndpoint] == nil {
                Counter.shared.get[adjEndpoint] = ["get":1]
            } else {
                Counter.shared.get[adjEndpoint]!["get"]! += 1
            }
        } else {
            Counter.shared.get[adjEndpoint] = ["get":index]
        }
        
        //        let totalCount = (fileImport && UiVar.activeTab == "Selective") ? targetSelectiveObjectList.count:total
        let totalCount = (UiVar.activeTab == "Selective") ? targetSelectiveObjectList.count:total
        
        print("[getStatusUpdate] \(adjEndpoint): retrieved \(Counter.shared.get[adjEndpoint]!["get"]!) of \(totalCount)")
        if Counter.shared.get[adjEndpoint]!["get"]! == totalCount || total == 0 {
            var getNext = true
            switch endpoint {
            case "smartcomputergroups":
                if smartComputerGrpsSelected && staticComputerGrpsSelected && total > 0 {
                    getNext = false
                }
            case "smartmobiledevicegroups":
                if smartIosGrpsSelected && staticIosGrpsSelected && total > 0 {
                    getNext = false
                }
            case "smartusergroups":
                if smartUserGrpsSelected && staticUserGrpsSelected && total > 0 {
                    getNext = false
                }
            default:
                break
            }
            if getNext {
                getNodesComplete += 1
            }
            
            print("[getStatusUpdate] \(adjEndpoint) nodesComplete: \(getNodesComplete) - get ToMigrate.total: \(ToMigrate.total), ToMigrate.rawCount: \(ToMigrate.rawCount)")
            if getNodesComplete == ToMigrate.rawCount && export.saveOnly {
                runComplete()
            } else {
                if getNodesComplete < ToMigrate.rawCount && getNext {
                    print("[getStatusUpdate] nextNode: \(ToMigrate.objects[nodesComplete])")
                    readNodes(nodesToMigrate: ToMigrate.objects, nodeIndex: getNodesComplete)
                }
            }
        }
        
        if Setting.fullGUI && totalCount > 0 {
            DispatchQueue.main.async { [self] in
                print("[getStatusUpdate] adjEndpoint: \(adjEndpoint)")
                //                print("[getStatusUpdate] count: \(String(describing: Counter.shared.get[adjEndpoint]?["get"]))")
                if let currentCount = Counter.shared.get[adjEndpoint]?["get"], currentCount > 0 {
                    //                if Counter.shared.get[adjEndpoint]!["get"]! > 0 {
                    if (!Setting.migrateDependencies && adjEndpoint != "patchpolicies") || ["patch-software-title-configurations", "policies"].contains(adjEndpoint) {
                        get_name_field.stringValue    = adjEndpoint.readable
                        get_levelIndicator.floatValue = Float(currentCount)/Float(totalCount)
                        getSummary_label.stringValue  = "\(currentCount) of \(totalCount)"
                    }
                }
            }
        }
    }
    
    func putStatusUpdate(endpoint: String, total: Int) {
        logFunctionCall()
        var adjEndpoint = ""
        
        switch endpoint {
        case "accounts/userid":
            adjEndpoint = "jamfusers"
        case "accounts/groupid":
            adjEndpoint = "jamfgroups"
        case "patchpolicies":
            adjEndpoint = "patch-software-title-configurations"
        default:
            adjEndpoint = endpoint
        }
        print("[putStatusUpdate] adjEndpoint: \(adjEndpoint)")
        
        
        let totalCount = (UiVar.activeTab == "Selective") ? targetSelectiveObjectList.count:total
        
        if Counter.shared.send[adjEndpoint] == nil {
            Counter.shared.send[adjEndpoint] = ["put": /*newPutTotal*/ 1]
        } else {
            Counter.shared.send[adjEndpoint]!["put"]! /*= newPutTotal*/ += 1
        }
        var newPutTotal = Counter.shared.send[adjEndpoint]!["put"]!
//        if putCounters[adjEndpoint] == nil {
//            putCounters[adjEndpoint] = ["put": /*newPutTotal*/ 1]
//        } else {
//            putCounters[adjEndpoint]!["put"]! /*= newPutTotal*/ += 1
//        }
        
//        print("[putStatusUpdate.counter]  create: \(Counter.shared.summary[adjEndpoint]?["create"]?.count ?? 0)")
//        print("[putStatusUpdate.counter]  update: \(Counter.shared.summary[adjEndpoint]?["update"]?.count ?? 0)")
//        print("[putStatusUpdate.counter]    fail: \(Counter.shared.summary[adjEndpoint]?["fail"]?.count ?? 0)")
//        print("[putStatusUpdate.counter] skipped: \(Counter.shared.summary[adjEndpoint]?["skipped"]?.count ?? 0)")
        
//        print("[putStatusUpdate] \(adjEndpoint) put count: \(putCounters[adjEndpoint]!["put"]!)")
        print("[putStatusUpdate] \(adjEndpoint) put count: \(Counter.shared.send[adjEndpoint]!["put"]!)")
        print("[putStatusUpdate] newPutTotal: \(newPutTotal), totalCount: \(totalCount)")
        print("[putStatusUpdate] ToMigrate.objects: \(ToMigrate.objects.description)")
        
        if newPutTotal == totalCount || total == 0 {
            var getNext = true
            switch endpoint {
                case "smartcomputergroups":
                    if smartComputerGrpsSelected && staticComputerGrpsSelected && total > 0 {
                        getNext = false
                    }
                case "mobiledevicegroups":
                    if smartIosGrpsSelected && staticIosGrpsSelected && total > 0 {
                        getNext = false
                    }
                case "usergroups":
                    if smartUserGrpsSelected && staticUserGrpsSelected && total > 0 {
                        getNext = false
                    }
                default:
                    break
            }
//            getNext = !(smartComputerGrpsSelected && staticComputerGrpsSelected && endpoint == "smartcomputergroups") ||
//            !(smartIosGrpsSelected && staticIosGrpsSelected && endpoint == "mobiledevicegroups") ||
//            !(smartUserGrpsSelected && staticUserGrpsSelected && endpoint == "usergroups")
            if getNext {
                nodesComplete += 1
            }
            WriteToLog.shared.message("[putStatusUpdate] \(adjEndpoint): \(nodesComplete) of \(ToMigrate.total) object types complete")
            print("[putStatusUpdate] \(adjEndpoint) nodesComplete: \(nodesComplete) - put ToMigrate.total: \(ToMigrate.total), ToMigrate.rawCount: \(ToMigrate.rawCount)")
            if nodesComplete == ToMigrate.rawCount {
                if !Setting.fullGUI {
                    nodesMigrated = nodesComplete
                }
                print("[putStatusUpdate] runComplete")
                runComplete()
            } else {
                print("[putStatusUpdate] getNext: \(getNext), WipeData.state.on: \(WipeData.state.on)")
                if nodesComplete < ToMigrate.rawCount && getNext && WipeData.state.on {
                    print("[putStatusUpdate] nextNode: \(ToMigrate.objects[nodesComplete])")
                    readNodes(nodesToMigrate: ToMigrate.objects, nodeIndex: nodesComplete)
                }
            }
        }
        
        DispatchQueue.main.async { [self] in
            if Setting.fullGUI && totalCount > 0 {
                if Counter.shared.crud[adjEndpoint]?["fail"] == 0 {
                    PutLevelIndicator.shared.indicatorColor[adjEndpoint] = .green
//                    put_levelIndicatorFillColor[adjEndpoint] = .green
                    DispatchQueue.main.async { [self] in
                        put_levelIndicator.fillColor = .green
                    }
                } else if ((Counter.shared.crud[adjEndpoint]?["fail"] ?? 0)! > 0 && (Counter.shared.crud[adjEndpoint]?["fail"] ?? 0)! < totalCount) {
                    PutLevelIndicator.shared.indicatorColor[adjEndpoint]/*put_levelIndicatorFillColor[adjEndpoint]*/ = .yellow
                    put_levelIndicator.fillColor = .yellow
                } else {
                    PutLevelIndicator.shared.indicatorColor[adjEndpoint]/* put_levelIndicatorFillColor[adjEndpoint]*/ = .red
                    put_levelIndicator.fillColor = .red
                }
                print("[putStatusUpdate] \(adjEndpoint) \(newPutTotal) of \(totalCount)\n")
//                if let currentPutCount = putCounters[adjEndpoint]?["put"], currentPutCount > 0 {
                if let currentPutCount = Counter.shared.send[adjEndpoint]?["put"], currentPutCount > 0 {
                    if (!Setting.migrateDependencies && adjEndpoint != "patchpolicies") || ["patch-software-title-configurations", "policies"].contains(adjEndpoint) {
                        put_name_field.stringValue    = adjEndpoint.readable
                        put_levelIndicator.floatValue = Float(newPutTotal)/Float(totalCount)
                        putSummary_label.stringValue  = "\(newPutTotal) of \(totalCount)"
                    }
                }
            }
        }
    }
    
    func icons(endpointType: String, action: String, ssInfo: [String: String], f_createDestUrl: String, responseData: String, sourcePolicyId: String) {

        logFunctionCall()
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
            if Setting.csa {
                // cloud connector
                createDestUrl = "\(createDestUrlBase)/v1/icon"
                createDestUrl = createDestUrl.replacingOccurrences(of: "/JSSResource", with: "/api")
            } else {
                createDestUrl = "\(createDestUrlBase)/fileuploads/\(iconNode)/id/\(tagValue(xmlString: responseData, xmlTag: "id"))"
            }
            createDestUrl = createDestUrl.urlFix
            
            // Get or skip icon from Jamf Pro
            if LogLevel.debug { WriteToLog.shared.message("[ViewController.icons] before icon download.") }

            if Iconfiles.pendingDict["\(ssIconId)"] ?? "" != "pending" {
                if Iconfiles.pendingDict["\(ssIconId)"] ?? "" != "ready" {
                    Iconfiles.pendingDict["\(ssIconId)"] = "pending"
                    WriteToLog.shared.message("[ViewController.icons] marking icon for \(iconNode) id \(sourcePolicyId) as pending")
                } else {
                    action = "SKIP"
                }
                
                // download the icon - action = "GET"
                iconMigrate(action: action, ssIconUri: ssIconUri, ssIconId: ssIconId, ssIconName: ssIconName, _iconToUpload: "", createDestUrl: "") {
                    (result: Int) in
//                    print("action: \(action)")
//                    print("Icon url: \(ssIconUri)")
                    if LogLevel.debug { WriteToLog.shared.message("[ViewController.icons] after icon download.") }
                    
                    if result > 199 && result < 300 {
                        if LogLevel.debug { WriteToLog.shared.message("[ViewController.icons] retuned from icon id \(ssIconId) GET with result: \(result)") }
//                        print("\ncreateDestUrl: \(createDestUrl)")

                        if LogLevel.debug { WriteToLog.shared.message("[ViewController.icons] retrieved icon from \(ssIconUri)") }
                        if export.saveRawXml || export.saveTrimmedXml {
                            var saveFormat = export.saveRawXml ? "raw":"trimmed"
                            if export.backupMode {
                                saveFormat = "\(JamfProServer.source.fqdnFromUrl)_export_\(backupDate.string(from: History.startTime))"
                            }
                            if LogLevel.debug { WriteToLog.shared.message("[ViewController.icons] saving icon: \(ssIconName) for \(iconNode).") }
                            DispatchQueue.main.async {
                                XmlDelegate().save(node: iconNodeSave, xml: "\(NSHomeDirectory())/Library/Caches/icons/\(ssIconId)/\(ssIconName)", rawName: ssIconName, id: ssIconId, format: "\(saveFormat)")
                            }
                        }   // if export.saveRawXml - end
                        // upload icon if not in save only mode
                        if !export.saveOnly {
                            
                            // see if the icon has been downloaded
//                            if iconfiles.policyDict["\(ssIconId)"]?["policyId"] == nil || iconfiles.policyDict["\(ssIconId)"]?["policyId"] == "" {
                            let downloadedIcon = Iconfiles.policyDict["\(ssIconId)"]?["policyId"]
                            if downloadedIcon?.fixOptional == nil || downloadedIcon?.fixOptional == "" {
//                                print("[ViewController.icons] iconfiles.policyDict value for icon id \(ssIconId.fixOptional): \(String(describing: iconfiles.policyDict["\(ssIconId)"]?["policyId"]))")
                                Iconfiles.policyDict["\(ssIconId)"] = ["policyId":"", "destinationIconId":""]
                                if LogLevel.debug { WriteToLog.shared.message("[ViewController.icons] upload icon (id=\(ssIconId)) to: \(createDestUrl)") }
//                                        print("createDestUrl: \(createDestUrl)")
                                if LogLevel.debug { WriteToLog.shared.message("[ViewController.icons] POST icon (id=\(ssIconId)) to: \(createDestUrl)") }
                                
                                self.iconMigrate(action: "POST", ssIconUri: "", ssIconId: ssIconId, ssIconName: ssIconName, _iconToUpload: "\(iconToUpload)", createDestUrl: createDestUrl) {
                                        (iconMigrateResult: Int) in

                                        if LogLevel.debug { WriteToLog.shared.message("[ViewController.icons] result of icon POST: \(iconMigrateResult).") }
                                        // verify icon uploaded successfully
                                        if iconMigrateResult != 0 {
                                            // associate self service icon to new policy id
                                            if LogLevel.debug { WriteToLog.shared.message("[ViewController.icons] source icon (id=\(ssIconId)) successfully uploaded and has id=\(iconMigrateResult).") }

//                                            iconfiles.policyDict["\(ssIconId)"] = ["policyId":"\(iconMigrateResult)", "destinationIconId":""]
                                            Iconfiles.policyDict["\(ssIconId)"]?["policyId"]          = "\(iconMigrateResult)"
                                            Iconfiles.policyDict["\(ssIconId)"]?["destinationIconId"] = ""
                                            
                                            
                                            if LogLevel.debug { WriteToLog.shared.message("[ViewController.icons] future usage of source icon id \(ssIconId) should reference new policy id \(iconMigrateResult) for the icon id") }
//                                            print("iconfiles.policyDict[\(ssIconId)]: \(String(describing: iconfiles.policyDict["\(ssIconId)"]!))")
                                            
                                            usleep(100)

                                            // removed cached icon
                                            if fm.fileExists(atPath: "\(NSHomeDirectory())/Library/Caches/icons/\(ssIconId)/") {
                                                do {
                                                    if LogLevel.debug { WriteToLog.shared.message("[ViewController.icons] removing cached icon: \(NSHomeDirectory())/Library/Caches/icons/\(ssIconId)/") }
                                                    try FileManager.default.removeItem(at: URL(fileURLWithPath: "\(NSHomeDirectory())/Library/Caches/icons/\(ssIconId)/"))
                                                }
                                                catch let error as NSError {
                                                    if LogLevel.debug { WriteToLog.shared.message("[ViewController.icons] unable to delete \(NSHomeDirectory())/Library/Caches/icons/\(ssIconId)/.  Error \(error).") }
                                                }
                                            }
                                            
                                            if Setting.csa {
                                                switch endpointType {
                                                case "policies":
                                                    iconXml = "<?xml version='1.0' encoding='UTF-8' standalone='yes'?><policy><self_service>\(ssXml)<self_service_icon><id>\(iconMigrateResult)</id></self_service_icon></self_service></policy>"
                                                case "mobiledeviceapplications":
//                                                    let newAppIcon = iconfiles.policyDict["\(ssIconId)"]?["policyId"] ?? "0"
                                                    iconXml = "<?xml version='1.0' encoding='UTF-8' standalone='yes'?><mobile_device_application><general><icon><id>\(iconMigrateResult)</id><name>\(ssIconName)</name><uri>\(ssIconUri)</uri></icon></general></mobile_device_application>"
                                                default:
                                                    break
                                                }
                                                
                                                let policyUrl = "\(createDestUrlBase)/\(endpointType)/id/\(tagValue(xmlString: responseData, xmlTag: "id"))"
                                                self.iconMigrate(action: "PUT", ssIconUri: "", ssIconId: ssIconId, ssIconName: "", _iconToUpload: iconXml, createDestUrl: policyUrl) {
                                                    (result: Int) in
                                                
                                                    if result > 199 && result < 300 {
                                                        if LogLevel.debug { WriteToLog.shared.message("[ViewController.icons] successfully updated policy (id: \(tagValue(xmlString: responseData, xmlTag: "id"))) with icon id \(iconMigrateResult)") }
//                                                        print("successfully used new icon id \(newSelfServiceIconId)")
                                                    }
                                                }
                                                
                                            }
                                        } else {
                                            // icon failed to upload
                                            if LogLevel.debug { WriteToLog.shared.message("[ViewController.icons] source icon (id=\(ssIconId)) failed to upload") }
                                            Iconfiles.policyDict["\(ssIconId)"] = ["policyId":"", "destinationIconId":""]
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
                                let policyUrl   = "\(createDestUrlBase)/\(endpointType)/id/\(thePolicyID)"
//                                print("\n[ViewController.icons] iconfiles.policyDict value for icon id \(ssIconId.fixOptional): \(String(describing: iconfiles.policyDict["\(ssIconId)"]?["policyId"]))")
//                                print("[ViewController.icons] policyUrl: \(policyUrl)")
                                
                                if Iconfiles.policyDict["\(ssIconId.fixOptional)"]!["destinationIconId"]! == "" {
                                    if LogLevel.debug { WriteToLog.shared.message("[ViewController.icons] getting downloaded icon id from destination server, policy id: \(String(describing: Iconfiles.policyDict["\(ssIconId.fixOptional)"]!["policyId"]!))") }
                                    var policyIconDict = Iconfiles.policyDict

                                    Json.shared.getRecord(whichServer: "dest", base64Creds: JamfProServer.base64Creds["dest"] ?? "", theEndpoint: "\(endpointType)/id/\(thePolicyID)/subset/SelfService")  {
                                        (objectRecord: Any) in
                                        let result = objectRecord as? [String: AnyObject] ?? [:]
//                                        print("[icons] result of Json().getRecord: \(result)")
                                        if LogLevel.debug { WriteToLog.shared.message("[ViewController.icons] Returned from Json.getRecord.  Retreived Self Service info.") }
                                        
//                                        if !setting.csa {
                                            if result.count > 0 {
                                                let theKey = (endpointType == "policies") ? "policy":"mobile_device_application"
                                                let selfServiceInfoDict = result[theKey]?["self_service"] as! [String:Any]
//                                                print("[icons] selfServiceInfoDict: \(selfServiceInfoDict)")
                                                let selfServiceIconDict = selfServiceInfoDict["self_service_icon"] as! [String:Any]
                                                newSelfServiceIconId = selfServiceIconDict["id"] as? Int ?? 0
                                                
                                                if newSelfServiceIconId != 0 {
                                                    policyIconDict["\(ssIconId)"]!["destinationIconId"] = "\(newSelfServiceIconId)"
                                                    Iconfiles.policyDict = policyIconDict
            //                                        iconfiles.policyDict["\(ssIconId)"]!["destinationIconId"] = "\(newSelfServiceIconId)"
                                                    if LogLevel.debug { WriteToLog.shared.message("[ViewController.icons] Returned from Json.getRecord: \(result)") }
                                                                                            
                                                    iconXml = "<?xml version='1.0' encoding='UTF-8' standalone='yes'?><policy><self_service>\(ssXml)<self_service_icon><id>\(newSelfServiceIconId)</id></self_service_icon></self_service></policy>"
                                                } else {
                                                    WriteToLog.shared.message("[ViewController.icons] Unable to locate icon on destination server for: policies/id/\(thePolicyID)")
                                                    iconXml = "<?xml version='1.0' encoding='UTF-8' standalone='yes'?><policy><self_service>\(ssXml)<self_service_icon></self_service_icon></self_service></policy>"
                                                }
                                            } else {
                                                iconXml = "<?xml version='1.0' encoding='UTF-8' standalone='yes'?><policy><self_service>\(ssXml)<self_service_icon></self_service_icon></self_service></policy>"
                                            }
                                        
                                            self.iconMigrate(action: "PUT", ssIconUri: "", ssIconId: ssIconId, ssIconName: "", _iconToUpload: iconXml, createDestUrl: policyUrl) {
                                            (result: Int) in
                                                if LogLevel.debug { WriteToLog.shared.message("[ViewController.icons] after updating policy with icon id.") }
                                            
                                                if result > 199 && result < 300 {
                                                    WriteToLog.shared.message("[ViewController.icons] successfully used new icon id \(newSelfServiceIconId)")
                                                }
                                            }
//                                        }
                                        
                                    }
                                } else {
                                    WriteToLog.shared.message("[ViewController.icons] using new icon id from destination server")
                                    newSelfServiceIconId = Int(Iconfiles.policyDict["\(ssIconId)"]!["destinationIconId"]!) ?? 0
                                    
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
                                            if LogLevel.debug { WriteToLog.shared.message("[CreateEndpoints.icon] after updating policy with icon id.") }
                                        
                                            if result > 199 && result < 300 {
                                                WriteToLog.shared.message("[ViewController.icons] successfully used new icon id \(newSelfServiceIconId)")
                                            }
                                        }
                                }
                            }
                        }  // if !export.saveOnly - end
                    } else {
                        if LogLevel.debug { WriteToLog.shared.message("[CreateEndpoints.icon] failed to retrieved icon from \(ssIconUri).") }
                    }
                }   // iconMigrate - end
                
            } else {
                // hold processing already used icon until it's been uploaded to the new server
                if !export.saveOnly {
                    if LogLevel.debug { WriteToLog.shared.message("[CreateEndpoints.icon] sending policy id \(sourcePolicyId) to icon queue while icon id \(ssIconId) is processed") }
                    iconMigrationHold(ssIconId: "\(ssIconId)", newIconDict: ["endpointType": endpointType, "action": action, "ssIconId": "\(ssIconId)", "ssIconName": ssIconName, "ssIconUri": ssIconUri, "f_createDestUrl": f_createDestUrl, "responseData": responseData, "sourcePolicyId": sourcePolicyId])
                }
            }//                }   // if !(iconfiles.policyDict["\(ssIconId)"]?["policyId"] - end
        }   // if (ssIconName != "") && (ssIconUri != "") - end
    }   // func icons - end
    
    func iconMigrate(action: String, ssIconUri: String, ssIconId: String, ssIconName: String, _iconToUpload: String, createDestUrl: String, completion: @escaping (Int) -> Void) {
        
        logFunctionCall()
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
                Iconfiles.policyDict["\(ssIconId)"] = ["policyId":"", "destinationIconId":""]
//                print("icon id \(ssIconId) is marked for download/cache")
                WriteToLog.shared.message("[iconMigrate.\(action)] fetching icon: \(ssIconUri)")
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
                            do {if LogLevel.debug { WriteToLog.shared.message("[iconMigrate.\(action)] creating \(savedURL.path) folder to cache icon") }
                                try fm.createDirectory(atPath: savedURL.path, withIntermediateDirectories: true, attributes: nil)
//                                usleep(1000)
                            } catch {
                                if LogLevel.debug { WriteToLog.shared.message("[iconMigrate.\(action)] problem creating \(savedURL.path) folder: Error \(error)") }
                                moveIcon = false
                            }
                        }
                    } catch {
                        if LogLevel.debug { WriteToLog.shared.message("[iconMigrate.\(action)] failed to set cache location: Error \(error)") }
                    }
                    
                    guard let fileURL = urlOrNil else { return }
                    do {
                        if moveIcon {
                            if LogLevel.debug { WriteToLog.shared.message("[iconMigrate.\(action)] saving icon to \(savedURL.appendingPathComponent("\(ssIconName)"))") }
                            if !FileManager.default.fileExists(atPath: savedURL.appendingPathComponent("\(ssIconName)").path) {
                                try FileManager.default.moveItem(at: fileURL, to: savedURL.appendingPathComponent("\(ssIconName)"))
                            }
                            
                            // Mark the icon as cached
                            if LogLevel.debug { WriteToLog.shared.message("[iconMigrate.\(action)] icon id \(ssIconId) is downloaded/cached to \(savedURL.appendingPathComponent("\(ssIconName)"))") }
//                            usleep(100)
                        }
                    } catch {
                        WriteToLog.shared.message("[iconMigrate.\(action)] Problem moving icon: Error \(error)")
                    }
                    let curlResponse = responseOrNil as! HTTPURLResponse
                    curlResult = curlResponse.statusCode
                    if LogLevel.debug { WriteToLog.shared.message("[iconMigrate.\(action)] result of Swift icon GET: \(curlResult).") }
                    completion(curlResult)
                }
                downloadTask.resume()
                // swift file download - end
            
        case "POST":
            if uploadedIcons[ssIconId.fixOptional] == nil || Setting.csa {
                // upload icon to fileuploads endpoint / icon server
                WriteToLog.shared.message("[iconMigrate.\(action)] sending icon: \(ssIconName)")
               
                var fileURL: URL!
                
                fileURL = URL(fileURLWithPath: iconToUpload)

                let boundary = "----WebKitFormBoundary\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"

                var httpResponse:HTTPURLResponse?
                var statusCode = 0
                
                theIconsQ.maxConcurrentOperationCount = 2
                let semaphore = DispatchSemaphore(value: 0)
                
                    self.theIconsQ.addOperation {

                        WriteToLog.shared.message("[iconMigrate.\(action)] uploading icon: \(iconToUpload)")

                        let startTime = Date()
                        var postData  = Data()
                        var newId     = 0
                        
    //                    WriteToLog.shared.message("[iconMigrate.\(action)] fileURL: \(String(describing: fileURL!))")
                        let fileType = NSURL(fileURLWithPath: "\(String(describing: fileURL!))").pathExtension
                    
                        WriteToLog.shared.message("[iconMigrate.\(action)] uploading \(ssIconName)")
                        
                        let serverURL = URL(string: createDestUrl)!
                        WriteToLog.shared.message("[iconMigrate.\(action)] uploading to: \(createDestUrl)")
                        
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
                                WriteToLog.shared.message("[iconMigrate.\(action)] loaded \(ssIconName) to data.")
                            }
                            let dataLen = postData.count
                            request.addValue("\(dataLen)", forHTTPHeaderField: "Content-Length")
                            
                        } catch {
                            WriteToLog.shared.message("[iconMigrate.\(action)] unable to get file: \(iconToUpload)")
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
                                WriteToLog.shared.message("[iconMigrate.\(action)] \(ssIconName) - Response from server - Status code: \(statusCode)")
                                WriteToLog.shared.message("[iconMigrate.\(action)] Response data string: \(String(data: data!, encoding: .utf8)!)")
                            } else {
                                WriteToLog.shared.message("[iconMigrate.\(action)] \(ssIconName) - No response from the server.")
                                
                                completion(statusCode)
                            }

                            switch statusCode {
                            case 200, 201:
                                WriteToLog.shared.message("[iconMigrate.\(action)] file successfully uploaded.")
                                if let dataResponse = String(data: data!, encoding: .utf8) {
    //                                print("[ViewController.iconMigrate] dataResponse: \(dataResponse)")
                                    if Setting.csa {
                                        let jsonResponse = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String:Any]
                                        if let _ = jsonResponse?["id"] as? Int {
                                            newId = jsonResponse?["id"] as? Int ?? 0
                                        }
                                        
                                        uploadedIcons[ssIconId.fixOptional] = newId
                                        
                                    } else {
                                        newId = Int(tagValue2(xmlString: dataResponse, startTag: "<id>", endTag: "</id>")) ?? 0
                                    }
                                }
                                Iconfiles.pendingDict["\(ssIconId.fixOptional)"] = "ready"
                            case 401:
                                WriteToLog.shared.message("[iconMigrate.\(action)] **** Authentication failed.")
                            case 404:
                                WriteToLog.shared.message("[iconMigrate.\(action)] **** server / file not found.")
                            default:
                                WriteToLog.shared.message("[iconMigrate.\(action)] **** unknown error occured.")
                                WriteToLog.shared.message("[iconMigrate.\(action)] **** Error took place while uploading a file.")
                            }

                            let endTime = Date()
                            let components = Calendar.current.dateComponents([.second], from: startTime, to: endTime)

                            let timeDifference = Int(components.second!)
                            let (h,r) = timeDifference.quotientAndRemainder(dividingBy: 3600)
                            let (m,s) = r.quotientAndRemainder(dividingBy: 60)

                            WriteToLog.shared.message("[iconMigrate.\(action)] upload time: \(Utilities.shared.dd(value: h)):\(Utilities.shared.dd(value: m)):\(Utilities.shared.dd(value: s)) (h:m:s)")
                            
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
            
            WriteToLog.shared.message("[iconMigrate.\(action)] setting icon for \(createDestUrl)")
            
            theIconsQ.maxConcurrentOperationCount = 2
            let semaphore    = DispatchSemaphore(value: 0)
            let encodedXML   = iconToUpload.data(using: String.Encoding.utf8)
                
            self.theIconsQ.addOperation {
            
                let encodedURL = URL(string: createDestUrl)
                let request = NSMutableURLRequest(url: encodedURL! as URL)

                request.httpMethod = action
               
                let configuration = URLSessionConfiguration.default

                configuration.httpAdditionalHeaders = ["Authorization" : "\(JamfProServer.authType["dest"] ?? "Bearer") \(JamfProServer.authCreds["dest"] ?? "")", "Content-Type" : "text/xml", "Accept" : "text/xml", "User-Agent" : AppInfo.userAgentHeader]
                
                var headers = [String: String]()
                for (header, value) in configuration.httpAdditionalHeaders ?? [:] {
                    headers[header as! String] = (header as! String == "Authorization") ? "Bearer ************" : value as? String
                }
                print("[apiCall] \(#function.description) method: \(request.httpMethod)")
                print("[apiCall] \(#function.description) headers: \(headers)")
                print("[apiCall] \(#function.description) endpoint: \(encodedURL?.absoluteString ?? "")")
                print("[apiCall]")
                
                request.httpBody = encodedXML!
                let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
                let task = session.dataTask(with: request as URLRequest, completionHandler: { [self]
                    (data, response, error) -> Void in
                    session.finishTasksAndInvalidate()
                    if let httpResponse = response as? HTTPURLResponse {
                        
                            if httpResponse.statusCode > 199 && httpResponse.statusCode <= 299 {
                                WriteToLog.shared.message("[iconMigrate.\(action)] icon updated on \(createDestUrl)")
//                                WriteToLog.shared.message("[iconMigrate.\(action)] posted xml: \(iconToUpload)")
                            } else {
                                WriteToLog.shared.message("[iconMigrate.\(action)] **** error code: \(httpResponse.statusCode) failed to update icon on \(createDestUrl)")
                                if LogLevel.debug { WriteToLog.shared.message("[iconMigrate.\(action)] posted xml: \(iconToUpload)") }
//                                print("[iconMigrate.\(action)] iconToUpload: \(iconToUpload)")
                                
                            }
                        completion(httpResponse.statusCode)
                    } else {   // if let httpResponse = response - end
                        WriteToLog.shared.message("[iconMigrate.\(action)] no response from server")
                        completion(0)
                    }
                    
                    if LogLevel.debug { WriteToLog.shared.message("[iconMigrate.\(action)] POST or PUT Operation: \(action)") }
                    
                    iconNotification()
                    
                    semaphore.signal()
                })
                task.resume()
                semaphore.wait()

            }   // theUploadQ.addOperation - end
            // end upload procdess
                    
                        
        default:
            WriteToLog.shared.message("[iconMigrate.\(action)] skipping icon: \(ssIconName).")
            completion(200)
        }
     
    }
    
    func iconNotification() {
        logFunctionCall()
        DispatchQueue.main.async { [self] in
            if Setting.fullGUI {
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
        logFunctionCall()
        if iconDictArray["\(ssIconId)"] == nil {
            iconDictArray["\(ssIconId)"] = [newIconDict]
            if LogLevel.debug { WriteToLog.shared.message("[ViewController.iconMigration] first entry for iconDictArray[\(ssIconId)]: \(newIconDict)") }
        } else {
            iconDictArray["\(ssIconId)"]?.append(contentsOf: [newIconDict])
            if LogLevel.debug { WriteToLog.shared.message("[ViewController.iconMigration] updated iconDictArray[\(ssIconId)]: \(String(describing: iconDictArray["\(ssIconId)"]))") }
        }
        iconHoldQ.async {
            while Iconfiles.pendingDict.count > 0 {
                if pref.stopMigration {
                    break
                }
                sleep(1)
                for (iconId, state) in Iconfiles.pendingDict {
                    if (state == "ready") {
                        if let _ = self.iconDictArray["\(iconId)"] {
                            for iconDict in self.iconDictArray["\(iconId)"]! {
                                if let endpointType = iconDict["endpointType"], let action = iconDict["action"], let ssIconName = iconDict["ssIconName"], let ssIconUri = iconDict["ssIconUri"], let f_createDestUrl = iconDict["f_createDestUrl"], let responseData = iconDict["responseData"], let sourcePolicyId = iconDict["sourcePolicyId"] {
                                
//                                    let ssIconUriArray = ssIconUri.split(separator: "/")
//                                    let ssIconId = String("\(ssIconUriArray.last)")
                                    let ssIconId = getIconId(iconUri: ssIconUri, endpoint: endpointType)
                                    
                                    let ssInfo: [String: String] = ["ssIconName": ssIconName, "ssIconId": ssIconId, "ssIconUri": ssIconUri, "ssXml": ""]
                                    self.icons(endpointType: endpointType, action: action, ssInfo: ssInfo, f_createDestUrl: f_createDestUrl, responseData: responseData, sourcePolicyId: sourcePolicyId)
                                }
                            }
                            self.iconDictArray.removeValue(forKey: iconId)
                        }
                    } else {
//                        print("waiting for icon id \(iconId) to become ready (uploaded to destination server)")
                        if LogLevel.debug { WriteToLog.shared.message("[ViewController.iconMigration] waiting for icon id \(iconId) to become ready (uploaded to destination server)") }
                    }
                }   // for (pending, state) - end
            }   // while - end
        }   // DispatchQueue.main.async - end
    }
    
    // func labelColor - start
    func labelColor(endpoint: String, theColor: NSColor) {
//        logFunctionCall()
        if Setting.fullGUI {
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
//                        self.smartUserGrps_label_field.textColor = theColor
                        self.staticUserGrps_label_field.textColor = theColor
                    case "jamfusers", "accounts/userid":
                        self.jamfUserAccounts_field.textColor = theColor
                    case "jamfgroups", "accounts/groupid":
                        self.jamfGroupAccounts_field.textColor = theColor
//                    case "smartusergroups":
//                        self.smartUserGrps_label_field.textColor = theColor
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
//                case "patch-software-title-configurations":
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
    func moveHistoryToLog(source: String, destination: String) {
        logFunctionCall()
        var allClear = true

        do {
            let historyFiles = try fm.contentsOfDirectory(atPath: source)
            
            for historyFile in historyFiles {
                if LogLevel.debug { WriteToLog.shared.message("Moving: " + source + historyFile + " to " + destination) }
                do {
                    try fm.moveItem(atPath: source + historyFile, toPath: destination + historyFile.replacingOccurrences(of: ".txt", with: ".log"))
                }
                catch let error as NSError {
                    WriteToLog.shared.message("Ooops! Something went wrong moving the history file: \(error)")
                    allClear = false
                }
            }
        } catch {
            if LogLevel.debug { WriteToLog.shared.message("no history to display") }
        }
        if allClear {
            do {
                try fm.removeItem(atPath: source)
            } catch {
                if LogLevel.debug { WriteToLog.shared.message("Unable to remove \(source)") }
            }
        }
    }
    // move history to logs - end
    
    
    func rmDELETE() {
        logFunctionCall()
        var isDir: ObjCBool = false
        if (fm.fileExists(atPath: NSHomeDirectory() + "/Library/Application Support/Replicator/DELETE", isDirectory: &isDir)) {
            do {
                try fm.removeItem(atPath: NSHomeDirectory() + "/Library/Application Support/Replicator/DELETE")
//                wipeData.on = false
                WipeData.state.on = false
            }
            catch let error as NSError {
                if LogLevel.debug { WriteToLog.shared.message("Unable to delete file! Something went wrong: \(error)") }
            }
        }
    }
  
    func rmXmlData(theXML: String, theTag: String, keepTags: Bool) -> String {
        logFunctionCall()
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
//            if LogLevel.debug { WriteToLog.shared.message("Removing blank lines.") }
            newXML_trimmed = newXML.replacingOccurrences(of: "\n\n", with: "")
            newXML_trimmed = newXML.replacingOccurrences(of: "\r\r", with: "\r")
        }
        return newXML_trimmed
    }
    
    func stopButton(_ sender: Any) {
        logFunctionCall()
        getArray.removeAll()
        createArray.removeAll()
        ToMigrate.objects.removeAll()
        getEndpointsQ.cancelAllOperations()
        endpointsIdQ.cancelAllOperations()
        Queue.shared.operation.cancelAllOperations()
        theIconsQ.cancelAllOperations()
        readFilesQ.cancelAllOperations()
        
        XmlDelegate().getRecordQ.cancelAllOperations()
        
        if Setting.fullGUI {
            WriteToLog.shared.message("Migration was manually stopped.\n")
            pref.stopMigration = true

            goButtonEnabled(button_status: true)
        } else {
            WriteToLog.shared.message("Migration was stopped due to an issue.\n")
        }
    }
    
    func setLevelIndicatorFillColor(fn: String, endpointType: String, fillColor: NSColor, indicator: String = "put") {
//        print("set levelIndicator from \(fn), endpointType: \(endpointType), color: \(fillColor)")
        logFunctionCall()
        if Setting.fullGUI {
            DispatchQueue.main.async { [self] in
                if indicator == "put" {
                    if put_levelIndicator.fillColor == .green || PutLevelIndicator.shared.indicatorColor[endpointType] == .systemRed {
                        PutLevelIndicator.shared.indicatorColor[endpointType] = fillColor
                        put_levelIndicator.fillColor = PutLevelIndicator.shared.indicatorColor[endpointType]
                    }
                } else {
                    GetLevelIndicator.shared.indicatorColor[endpointType] = fillColor
                    get_levelIndicator.fillColor = GetLevelIndicator.shared.indicatorColor[endpointType]
                }
            }
        }
    }
    
    func myExitValue(cmd: String, args: String...) -> String {
        logFunctionCall()
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
        logFunctionCall()
        DispatchQueue.main.async {
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
            self.apiRoles_button.state = NSControl.StateValue(rawValue: 0)
            self.apiClients_button.state = NSControl.StateValue(rawValue: 0)
            // macOS tab
            self.advcompsearch_button.state = NSControl.StateValue(rawValue: 0)
            self.macapplications_button.state = NSControl.StateValue(rawValue: 0)
            self.computers_button.state = NSControl.StateValue(rawValue: 0)
            self.directory_bindings_button.state = NSControl.StateValue(rawValue: 0)
            self.disk_encryptions_button.state = NSControl.StateValue(rawValue: 0)
            self.dock_items_button.state = NSControl.StateValue(rawValue: 0)
//            self.netboot_button.state = NSControl.StateValue(rawValue: 0)
            self.osxconfigurationprofiles_button.state = NSControl.StateValue(rawValue: 0)
            self.patch_policies_button.state = NSControl.StateValue(rawValue: 0)
            self.sus_button.state = NSControl.StateValue(rawValue: 0)
            self.fileshares_button.state = NSControl.StateValue(rawValue: 0)
            self.ext_attribs_button.state = NSControl.StateValue(rawValue: 0)
            self.smart_comp_grps_button.state = NSControl.StateValue(rawValue: 0)
            self.static_comp_grps_button.state = NSControl.StateValue(rawValue: 0)
            self.scripts_button.state = NSControl.StateValue(rawValue: 0)
            self.packages_button.state = NSControl.StateValue(rawValue: 0)
            self.patch_mgmt_button.state = NSControl.StateValue(rawValue: 0)
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
        }
    }
    
    func setConcurrentThreads() {
        logFunctionCall()
        maxConcurrentThreads = (userDefaults.integer(forKey: "concurrentThreads") < 1) ? 2:userDefaults.integer(forKey: "concurrentThreads")
//        print("[ViewController] ConcurrentThreads: \(concurrent)")
        maxConcurrentThreads = (maxConcurrentThreads > 5) ? 2:maxConcurrentThreads
        userDefaults.set(maxConcurrentThreads, forKey: "concurrentThreads")
    }
    
    // add notification - run fn in SourceDestVC
    func updateServerArray(url: String, serverList: String, theArray: [String]) {
        logFunctionCall()
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
        logFunctionCall()
        let options = CGWindowListOption(arrayLiteral: CGWindowListOption.excludeDesktopElements, CGWindowListOption.optionOnScreenOnly)
        let windowListInfo = CGWindowListCopyWindowInfo(options, CGWindowID(0))
        let infoList = windowListInfo as NSArray? as? [[String: AnyObject]]
        for item in infoList! {
            if let _ = item["kCGWindowOwnerName"], let _ = item["kCGWindowName"] {
                if "\(item["kCGWindowOwnerName"]!)" == "Replicator" && "\(item["kCGWindowName"]!)" == windowName {
                    return true
                }
            }
        }
        return false
    }
    
    func zipIt(args: String..., completion: @escaping (_ result: String) -> Void) {

        logFunctionCall()
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
        logFunctionCall()
        UiVar.activeTab = didSelect!.label
        userDefaults.set("\(didSelect!.label)", forKey: "activeTab")
    }
    
    // selective migration functions - start
    func numberOfRows(in tableView: NSTableView) -> Int {
        logFunctionCall()
        var numberOfRows:Int = 0;
        if (tableView == srcSrvTableView)
        {
            numberOfRows = DataArray.source.count
        }
        print("[numberOfRows] \(numberOfRows)")
        return numberOfRows
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
    //        print("tableView: \(tableView)\t\ttableColumn: \(tableColumn)\t\trow: \(row)")
        logFunctionCall()
        var newString:String = ""
        if (tableView == srcSrvTableView) && row < DataArray.source.count
        {
            if row < DataArray.source.count {
                newString = DataArray.source[row]
            } else {
                newString = DataArray.source.last ?? ""
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
        logFunctionCall()
        print("[\(#function.description)] loaded")
        // display app version
        appVersion_TextField.stringValue = "v\(AppInfo.version)"
        
//        let def_plist = Bundle.main.path(forResource: "settings", ofType: "plist")!
        var isDir: ObjCBool = true
        
        // Create Application Support folder for the app if missing - start
        let app_support_path = NSHomeDirectory() + "/Library/Application Support/Replicator"
        if !(fm.fileExists(atPath: app_support_path, isDirectory: &isDir)) {
//            let manager = FileManager.default
            do {
                try fm.createDirectory(atPath: app_support_path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                if LogLevel.debug { WriteToLog.shared.message("Problem creating '/Library/Application Support/Replicator' folder:  \(error)") }
            }
        }
        // Create Application Support folder for the app if missing - end
        
        // read stored values from plist, if it exists
        initVars()
        
    }   //viewDidAppear - end

    @objc func setColorScheme_VC(_ notification: Notification) {
        
        logFunctionCall()
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
        logFunctionCall()
        super.viewDidLoad()
        print("[\(#function.description)] loaded")
                
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

        if LogLevel.debug { WriteToLog.shared.message("----- Debug Mode -----") }
        
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
        logFunctionCall()
        _ = readSettings()
        saveSettings(settings: AppInfo.settings)
        WriteToLog.shared.logCleanup()
    }
    
    func initVars() {
        logFunctionCall()
        print("[\(#function.description)]")
        
        // needed for protocols
        PatchDelegate.shared.messageDelegate       = self
        CreateEndpoints.shared.updateUiDelegate    = self
        EndpointXml.shared.updateUiDelegate        = self
        EndpointXml.shared.getStatusDelegate       = self
        ExistingObjects.shared.updateUiDelegate    = self
        RemoveObjects.shared.updateUiDelegate      = self
        PatchManagementApi.shared.updateUiDelegate = self
        
        if Setting.fullGUI {
            Setting.onlyCopyMissing  = (userDefaults.integer(forKey: "copyMissing")  == 1) ? true:false
            Setting.onlyCopyExisting = (userDefaults.integer(forKey: "copyExisting") == 1) ? true:false

            if !FileManager.default.fileExists(atPath: AppInfo.plistPath) {
                do {
                    if !FileManager.default.fileExists(atPath: AppInfo.appSupportPath) {
                        try FileManager.default.createDirectory(at: URL(string: AppInfo.appSupportPath)!, withIntermediateDirectories: true)
                    }
                    try FileManager.default.copyItem(atPath: Bundle.main.path(forResource: "settings", ofType: "plist")!, toPath: AppInfo.plistPath)
                    WriteToLog.shared.message("[ViewController] Created default setting from  \(Bundle.main.path(forResource: "settings", ofType: "plist")!)")
                } catch {
                    WriteToLog.shared.message("[ViewController] Unable to find/create \(AppInfo.plistPath)")
                    WriteToLog.shared.message("[ViewController] Try to manually copy the file from path_to/Replicator.app/Contents/Resources/settings.plist to \(AppInfo.plistPath)")
                    NSApplication.shared.terminate(self)
                }
            }
            
            
            // read environment settings from plist - start
            _ = readSettings()

            // read scope settings - start
            if AppInfo.settings["scope"] != nil {
                Scope.options = AppInfo.settings["scope"] as! [String:[String: Bool]]

                if Scope.options["mobiledeviceconfigurationprofiles"]!["copy"] != nil {
                    Scope.mcpCopy = Scope.options["mobiledeviceconfigurationprofiles"]!["copy"]!
                }
                if Scope.options["macapps"] != nil {
                    if Scope.options["macapps"]!["copy"] != nil {
                        Scope.maCopy = Scope.options["macapps"]!["copy"]!
                    } else {
                        Scope.maCopy = true
                    }
                } else {
                    Scope.maCopy = true
                }
                if Scope.options["policies"]!["copy"] != nil {
                    Scope.policiesCopy = Scope.options["policies"]!["copy"]!
                }
                if Scope.options["policies"]!["disable"] != nil {
                    Scope.policiesDisable = Scope.options["policies"]!["disable"]!
                }
                if Scope.options["osxconfigurationprofiles"]!["copy"] != nil {
                    Scope.ocpCopy = Scope.options["osxconfigurationprofiles"]!["copy"]!
                }
                if Scope.options["restrictedsoftware"]!["copy"] != nil {
                    Scope.rsCopy = Scope.options["restrictedsoftware"]!["copy"]!
                }
                if Scope.options["iosapps"] != nil {
                    if Scope.options["iosapps"]!["copy"] != nil {
                        Scope.iaCopy = Scope.options["iosapps"]!["copy"]!
                    } else {
                        Scope.iaCopy = true
                    }
                } else {
                    Scope.iaCopy = true
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
            
            if Scope.options["scg"] != nil && Scope.options["sig"] != nil && Scope.options["users"] != nil  {

                if (Scope.options["scg"]!["copy"] != nil) {
                    Scope.scgCopy = Scope.options["scg"]!["copy"]!
                } else {
                    Scope.scgCopy                  = true
                    Scope.options["scg"]!["copy"] = Scope.scgCopy
                }

                if (Scope.options["sig"]!["copy"] != nil) {
                    Scope.sigCopy = Scope.options["sig"]!["copy"]!
                } else {
                    Scope.sigCopy                  = true
                    Scope.options["sig"]!["copy"] = Scope.sigCopy
                }

                if (Scope.options["sig"]!["users"] != nil) {
                    Scope.usersCopy = Scope.options["sig"]!["users"]!
                } else {
                    Scope.usersCopy                 = true
                    Scope.options["sig"]!["users"] = Scope.usersCopy
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
            
            Scope.ocpCopy          = Setting.copyScope   // osxconfigurationprofiles copy scope
            Scope.maCopy           = Setting.copyScope   // macapps copy scope
            Scope.rsCopy           = Setting.copyScope   // restrictedsoftware copy scope
            Scope.policiesCopy     = Setting.copyScope   // policies copy scope
//            Scope.policiesDisable = setting.copyScope  // policies disable on copy
            Scope.mcpCopy          = Setting.copyScope   // mobileconfigurationprofiles copy scope
            Scope.iaCopy           = Setting.copyScope   // iOSapps copy scope
            Scope.scgCopy          = Setting.copyScope   // static computer groups copy scope
            Scope.sigCopy          = Setting.copyScope   // static iOS device groups copy scope
            Scope.usersCopy        = Setting.copyScope   // static user groups copy scope
            
        }
        
        let appVersion = AppInfo.version
        let appBuild   = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
        WriteToLog.shared.message("Running \(AppInfo.name) v\(appVersion) build: \(appBuild )")
        
        if !Setting.fullGUI {
            WriteToLog.shared.message("Running silently")
            Go(sender: "silent")
        }
    }
    
    @objc func resetListFields(_ notification: Notification) {
        logFunctionCall()
        if (JamfProServer.whichServer == "source" && !WipeData.state.on) || (JamfProServer.whichServer == "dest" && !export.saveOnly) || (srcSrvTableView.isEnabled == false) {
            srcSrvTableView.isEnabled = true
            selectiveListCleared      = false
            clearSelectiveList()
            clearSourceObjectsList()
            clearProcessingFields()
            
            ApiRoles.source.removeAll()
            ApiRoles.destination.removeAll()
            ApiIntegrations.source.removeAll()
            ApiIntegrations.destination.removeAll()
        }
        JamfProServer.version[JamfProServer.whichServer]    = ""
        JamfProServer.validToken[JamfProServer.whichServer] = false
    }
    // Log Folder - start
    @objc func showLogFolder(_ notification: Notification) {
        logFunctionCall()
        isDir = true
        if (fm.fileExists(atPath: History.logPath, isDirectory: &isDir)) {
//            NSWorkspace.shared.openFile(logPath!)
            NSWorkspace.shared.open(URL(fileURLWithPath: History.logPath))
        } else {
            alert_dialog(header: "Alert", message: "There are currently no log files to display.")
        }
    }
    // Log Folder - end
    // Summary Window - start
    @objc func showSummaryWindow(_ notification: Notification) {
        logFunctionCall()
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let summaryWindowController = storyboard.instantiateController(withIdentifier: "Summary Window Controller") as! NSWindowController
        if let summaryWindow = summaryWindowController.window {
            let summaryViewController = summaryWindow.contentViewController as! SummaryViewController
            
            URLCache.shared.removeAllCachedResponses()
            summaryViewController.summary_WebView.loadHTMLString(summaryXml(theSummary: Counter.shared.crud, theSummaryDetail: Counter.shared.summary), baseURL: nil)
            
            let application = NSApplication.shared
            application.runModal(for: summaryWindow)
            summaryWindow.close()
        }
    }
    // Summary Window - end
    
    @objc func deleteMode(_ notification: Notification) {
        logFunctionCall()
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
        
        if (fm.fileExists(atPath: NSHomeDirectory() + "/Library/Application Support/Replicator/DELETE", isDirectory: &isDir)) {
            if LogLevel.debug { WriteToLog.shared.message("Disabling delete mode") }
            do {
                try fm.removeItem(atPath: NSHomeDirectory() + "/Library/Application Support/Replicator/DELETE")
                DataArray.source.removeAll()
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
                WipeData.state.on = false
            } catch let error as NSError {
                if LogLevel.debug { WriteToLog.shared.message("Unable to delete file! Something went wrong: \(error)") }
            }
        } else {
            if LogLevel.debug { WriteToLog.shared.message("Enabling delete mode to removing data from destination server - \(JamfProServer.destination)") }
            fm.createFile(atPath: NSHomeDirectory() + "/Library/Application Support/Replicator/DELETE", contents: nil)
            
            NotificationCenter.default.post(name: .deleteMode_sdvc, object: self)

            DispatchQueue.main.async { [self] in
                WipeData.state.on = true
                selectiveTabelHeader_textview.stringValue = "Select object(s) to remove from the destination"
                Setting.migrateDependencies        = false
                migrateDependencies.state     = .off
                migrateDependencies.isHidden  = true
                if srcSrvTableView.isEnabled {
                    DataArray.source.removeAll()
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
                        if !(fm.fileExists(atPath: NSHomeDirectory() + "/Library/Application Support/Replicator/DELETE", isDirectory: &isDir)) {
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
        logFunctionCall()
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
                    endpointSummary.append("<td style='text-align:right; width: 35%;'>\(String(describing: key).readable)</td>")
                    endpointSummary.append("<td style='text-align:right; width: 20%;'><a class='button' href='#\(createIndex)'>\(values["create"] ?? 0)</a></td>")
                    endpointSummary.append("<td style='text-align:right; width: 20%;'><a class='button' href='#\(updateIndex)'>\(values["update"] ?? 0)</a></td>")
                    endpointSummary.append("<td style='text-align:right; width: 20%;'><a class='button' href='#\(failIndex)'>\(values["fail"] ?? 0)</a></td>")
                    endpointSummary.append("</tr>")
                    cellDetails.append(popUpHtml(id: createIndex, column: "\(String(describing: key).readable) \(summaryHeader.createDelete.lowercased())d", values: createHtml))
                    cellDetails.append(popUpHtml(id: updateIndex, column: "\(String(describing: key).readable) updated", values: updateHtml))
                    cellDetails.append(popUpHtml(id: failIndex, column: "\(String(describing: key).readable) failed", values: failHtml))
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
        logFunctionCall()
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
        logFunctionCall()
        let newArray = theArray.sorted{$0.localizedCaseInsensitiveCompare($1) == .orderedAscending}
        completion(newArray)
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        logFunctionCall()
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
            var context = ""
            let nameArray = self.components(separatedBy: "://")
            if nameArray.count > 1 {
                fqdn = nameArray[1]
            } else {
                fqdn =  self
            }

            if fqdn.contains("/") {
                let fqdnArray = fqdn.components(separatedBy: "/")
                fqdn = fqdnArray[0]
                if fqdnArray.count > 1 {
                    if !fqdnArray[1].isEmpty {
                        context = "_\(fqdnArray[1])"
                    }
                }
            }

            if fqdn.contains(":") {
                let fqdnArray = fqdn.components(separatedBy: ":")
                fqdn = fqdnArray[0]
            }
            while fqdn.last == "/" {
                fqdn = "\(fqdn.dropLast(1))"
            }
            fqdn = fqdn + context

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
    var prettyPrint: String {
        get {
            var formattedXml: String = ""
            if let xmlDoc = try? XMLDocument(xmlString: self, options: .nodePrettyPrint) {
//                if let _ = try? XMLElement.init(xmlString:"\(xml)") {
                    let data = xmlDoc.xmlData(options:.nodePrettyPrint)
                    formattedXml = String(data: data, encoding: .utf8)!
//                }
            }
            return formattedXml
        }
    }
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
    var readable: String {
        switch self {
            // general
            case "api-integrations": return "API clients"
            case "api-roles": return "API roles"
            case "advancedusersearches": return "advanced user searches"
            case "jamfgroups": return "jamf groups"
            case "jamfusers": return "jamf users"
            case "ldapservers": return "LDAP servers"
            case "networksegments": return "network segments"
            case "smartusergroups": return "smart user groups"
            case "staticusergroups": return "static user groups"
            case "userextensionattributes": return "user extension attributes"
            // macOS
            case "advancedcomputersearches": return "advanced computer searches"
            case "computerextensionattributes": return "computer extension attributes"
            case "directorybindings": return "directory bindings"
            case "diskencryptionconfigurations": return "disk encryption configurations"
            case "distributionpoints": return "distribution points"
            case "macapplications": return "mac applications"
            case "osxconfigurationprofiles": return "mac configuration profiles"
            case "patch-software-title-configurations": return "patch software title configurations"
            case "patchpolicies": return "patch policies"
            case "restrictedsoftware": return "restricted software"
            case "smartcomputergroups": return "smart computer groups"
            case "staticcomputergroups": return "static computer groups"
            case "softwareupdateservers": return "software update servers"
            // iOS
            case "advancedmobiledevicesearches": return "advanced mobile device searches"
            case "mobiledeviceapplications": return "mobile device applications"
            case "mobiledeviceconfigurationprofiles": return "mobile device configuration profiles"
            case "mobiledeviceextensionattributes": return "mobile device extension attributes"
            case "mobiledevices": return "mobile devices"
            case "smartmobiledevicegroups": return "smart mobile device groups"
            case "staticmobiledevicegroups": return "static mobile device groups"
                
            default:  return self
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
