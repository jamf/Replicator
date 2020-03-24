//
//  ViewController.swift
//  jamf-migrator
//
//  Created by lnh on 12/9/16.
//  Copyright © 2016 jamf. All rights reserved.
//

import AppKit
import Cocoa
import Foundation

class ViewController: NSViewController, URLSessionDelegate, NSTableViewDelegate, NSTableViewDataSource {
    
    // Main Window
    @IBOutlet var migrator_window: NSView!
    @IBOutlet weak var modeTab_TabView: NSTabView!
    
    @IBOutlet weak var sitesSpinner_ProgressIndicator: NSProgressIndicator!
    
    
    // Import file variables
    @IBOutlet weak var importFiles_button: NSButton!
    var exportedFilesUrl                          = URL(string: "")
    var availableFilesToMigDict:[String:[String]] = [:]   // something like xmlID, xmlName
    
    @IBOutlet weak var objectsToSelect: NSScrollView!
    
    let userDefaults = UserDefaults.standard
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
        }
        
//        if let helpWindow = helpWindowController.window {
////            let helpViewController = helpWindow.contentViewController as! HelpViewController
//
//            let application = NSApplication.shared
//            application.runModal(for: helpWindow)
//
//            helpWindow.close()
//        }
    }
    
    // Show Preferences Window
    var prefWindowController2: PrefsWindowController?
    @IBAction func showPrefsWindow(_ sender: Any) {
        PrefsWindowController().show()
//        let myPrefs = PrefsWindowController().window
//        myPrefs?.makeKeyAndOrderFront(self)
//        PrefsWindowController().window?.orderFrontRegardless()
//        PrefsWindowController().window?.makeKeyAndOrderFront(self)
//        
//        self.view.window?.orderFront(self)
//        self.view.window?.makeKeyAndOrderFront(self)
    }

        
    // keychain access
//    let Creds            = Credentials()
    let Creds2           = Credentials2()
    var validCreds       = true     // used to deterine if keychain has valid credentials
    var storedSourceUser = ""       // source user account stored in the keychain
    var storedDestUser   = ""       // destination user account stored in the keychain
    @IBOutlet weak var storeCredentials_button: NSButton!
    var storeCredentials = 0
    @IBAction func storeCredentials(_ sender: Any) {
        storeCredentials = storeCredentials_button.state.rawValue
    }
        
    // Buttons
    // macOS tab
    @IBOutlet weak var allNone_button: NSButton!
    @IBOutlet weak var advcompsearch_button: NSButton!
    @IBOutlet weak var macapplications_button: NSButton!
    @IBOutlet weak var computers_button: NSButton!
    @IBOutlet weak var configurations_button: NSButton!
    @IBOutlet weak var directory_bindings_button: NSButton!
    @IBOutlet weak var disk_encryptions_button: NSButton!
    @IBOutlet weak var dock_items_button: NSButton!
    @IBOutlet weak var fileshares_button: NSButton!
    @IBOutlet weak var sus_button: NSButton!
    @IBOutlet weak var netboot_button: NSButton!
    @IBOutlet weak var osxconfigurationprofiles_button: NSButton!
//    @IBOutlet weak var patch_mgmt_button: NSButton!
    @IBOutlet weak var patch_policies_button: NSButton!
    @IBOutlet weak var ext_attribs_button: NSButton!
    @IBOutlet weak var scripts_button: NSButton!
    @IBOutlet weak var smart_comp_grps_button: NSButton!
    @IBOutlet weak var static_comp_grps_button: NSButton!
    @IBOutlet weak var packages_button: NSButton!
    @IBOutlet weak var printers_button: NSButton!
    @IBOutlet weak var policies_button: NSButton!
    @IBOutlet weak var restrictedsoftware_button: NSButton!
    // iOS tab
    @IBOutlet weak var allNone_iOS_button: NSButton!
    @IBOutlet weak var mobiledevices_button: NSButton!
    @IBOutlet weak var mobiledeviceconfigurationprofiles_button: NSButton!
    @IBOutlet weak var mobiledeviceextensionattributes_button: NSButton!
    @IBOutlet weak var mobiledevicecApps_button: NSButton!
    @IBOutlet weak var smart_ios_groups_button: NSButton!
    @IBOutlet weak var static_ios_groups_button: NSButton!
    @IBOutlet weak var advancedmobiledevicesearches_button: NSButton!
    // general tab
    @IBOutlet weak var allNone_general_button: NSButton!
    @IBOutlet weak var advusersearch_button: NSButton!
    @IBOutlet weak var building_button: NSButton!
    @IBOutlet weak var categories_button: NSButton!
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
    
    @IBOutlet weak var sourceServerList_button: NSPopUpButton!
    @IBOutlet weak var destServerList_button: NSPopUpButton!
    @IBOutlet weak var siteMigrate: NSButton!
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
    @IBOutlet weak var configurations_label_field: NSTextField!
    @IBOutlet weak var directory_bindings_field: NSTextField!
    @IBOutlet weak var disk_encryptions_field: NSTextField!
    @IBOutlet weak var dock_items_field: NSTextField!
    @IBOutlet weak var file_shares_label_field: NSTextField!
    @IBOutlet weak var sus_label_field: NSTextField!
    @IBOutlet weak var netboot_label_field: NSTextField!
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
    // iOS button labels
    @IBOutlet weak var smart_ios_groups_label_field: NSTextField!
    @IBOutlet weak var static_ios_groups_label_field: NSTextField!
    @IBOutlet weak var mobiledeviceconfigurationprofile_label_field: NSTextField!
    @IBOutlet weak var mobiledeviceextensionattributes_label_field: NSTextField!
    @IBOutlet weak var mobiledevices_label_field: NSTextField!
    @IBOutlet weak var mobiledeviceApps_label_field: NSTextField!
    @IBOutlet weak var advancedmobiledevicesearches_label_field: NSTextField!
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
    
    // Source and destination fields
    @IBOutlet weak var source_jp_server_field: NSTextField!
    @IBOutlet weak var source_user_field: NSTextField!
    @IBOutlet weak var source_pwd_field: NSSecureTextField!
    @IBOutlet weak var dest_jp_server_field: NSTextField!
    @IBOutlet weak var dest_user_field: NSTextField!
    @IBOutlet weak var dest_pwd_field: NSSecureTextField!
    
    // Source and destination buttons
    @IBOutlet weak var sourceServerPopup_button: NSPopUpButton!
    @IBOutlet weak var destServerPopup_button: NSPopUpButton!
    
    // GET and POST/PUT (DELETE) fields
    @IBOutlet weak var object_name_field: NSTextField!  // object being migrated
    @IBOutlet weak var objects_completed_field: NSTextField!
    @IBOutlet weak var objects_found_field: NSTextField!
    
    @IBOutlet weak var get_name_field: NSTextField!
    @IBOutlet weak var get_completed_field: NSTextField!
    @IBOutlet weak var get_found_field: NSTextField!
    
    // selective migration items - start
    // source / destination tables
    @IBOutlet weak var srcSrvTableView: NSTableView!
    @IBOutlet weak var migrateDependencies: NSButton!
    
    // source / destination array / dictionary of items
    var sourceDataArray:[String]            = []
    var targetDataArray:[String]            = []
    var availableIDsToMigDict:[String:Int]  = [:]   // something like xmlName, xmlID
    var availableObjsToMigDict:[Int:String] = [:]   // something like xmlID, xmlName
    var availableIdsToDelArray:[Int]        = []   // array of objects' to delete IDs
    var selectiveListCleared                = false
    var delayInt: UInt32                    = 50000
    
    // destination TextFieldCells
    @IBOutlet weak var destTextCell_TextFieldCell: NSTextFieldCell!
    @IBOutlet weak var dest_TableColumn: NSTableColumn!
    // selective migration items - end
    
    // smartgroup vars
    var migrateSmartComputerGroups  = false
    var migrateStaticComputerGroups = false
    var migrateSmartMobileGroups    = false
    var migrateStaticMobileGroups   = false
    var migrateSmartUserGroups      = false
    var migrateStaticUserGroups     = false
    
    var isDir: ObjCBool = false
    
    // command line switches
//    var debug           = false
    var hideGui             = false
    var saveOnly            = false
    var saveRawXml          = false
    var saveTrimmedXml      = false
    var saveRawXmlScope     = true
    var saveTrimmedXmlScope = true
    
    // plist and log variables
    var didRun            = false  // used to determine if the Go! button was selected, if not delete the empty log file only.
    let plistPath:String? = (NSHomeDirectory() + "/Library/Application Support/jamf-migrator/settings.plist")
    var format = PropertyListSerialization.PropertyListFormat.xml //format of the property list
    var plistData:[String:Any] = [:]   //our server/username data

    var maxHistory:     Int = 20
    var historyFile: String = ""
    var logFile:     String = ""
    let logPath:    String? = (NSHomeDirectory() + "/Library/Logs/jamf-migrator/")
    var logFileW:     FileHandle? = FileHandle(forUpdatingAtPath: "")
    // legacy logging (history) path and file
    let historyPath:String? = (NSHomeDirectory() + "/Library/Application Support/jamf-migrator/history/")
    var historyFileW: FileHandle? = FileHandle(forUpdatingAtPath: "")
    
    // scope preferences
    var scopeOptions:           Dictionary<String,Dictionary<String,Bool>> = [:]
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
    
    // xml prefs
    var xmlPrefOptions: Dictionary<String,Bool> = [:]
    
    // site copy / move pref
    var sitePref = ""
    
    var sourceServerArray   = [String]()
    var destServerArray     = [String]()
    
    // credentials
    var sourceCreds = ""
    var destCreds   = ""
    var jamfAdminId = 1
    
    // settings variables
    let safeCharSet                 = CharacterSet.alphanumerics
    var source_jp_server: String    = ""
    var source_user: String         = ""
    var source_pass: String         = ""
    var dest_jp_server: String      = ""
    var dest_user: String           = ""
    var dest_pass: String           = ""
    var sourceBase64Creds: String   = ""
    var destBase64Creds: String     = ""
    
    var sourceURL = ""
//    var destURL = ""
    var createDestUrlBase = ""
    
    // import file vars
    var fileImport      = false
    var dataFilesRoot   = ""
    
    var endpointDefDict = ["computergroups":"computer_groups", "computerconfigurations":"computer_configurations", "directorybindings":"directory_bindings", "diskencryptionconfigurations":"disk_encryption_configurations", "dockitems":"dock_items","macapplications":"mac_applications", "mobiledeviceapplications":"mobile_device_application", "mobiledevicegroups":"mobile_device_groups", "packages":"packages", "patches":"patch_management_software_titles", "patchpolicies":"patch_policies", "printers":"printers", "scripts":"scripts", "usergroups":"user_groups", "userextensionattributes":"user_extension_attributes", "advancedusersearches":"advanced_user_searches", "restrictedsoftware":"restricted_software"]
    let ordered_dependency_array = ["sites", "buildings", "categories", "computergroups", "dockitems", "departments", "directorybindings", "distributionpoints", "ibeacons", "packages", "printers", "scripts", "softwareupdateservers", "networksegments"]
    var xmlName             = ""
    var destEPs             = [String:Int]()
    var currentEPs          = [String:Int]()
    var currentLDAPServers  = [String:Int]()
    
    var currentEPDict       = [String:[String:Int]]()
    
    var currentEndpointID   = 0
    var progressCountArray  = [String:Int]() // track if post/put was successful
    
    var whiteText:NSColor   = NSColor.white
    var greenText:NSColor   = NSColor.green
    var yellowText:NSColor  = NSColor.yellow
    var redText:NSColor     = NSColor.red
    var changeColor:Bool    = true
    
    // This order must match the drop down for selective migration, provide the node name: ../JSSResource/node_name
    var macOSEndpointArray: [String] = ["advancedcomputersearches", "macapplications", "smartcomputergroups", "staticcomputergroups", "computers", "osxconfigurationprofiles", "computerconfigurations", "directorybindings", "diskencryptionconfigurations", "dockitems", "computerextensionattributes", "distributionpoints", "netbootservers", "packages", "policies", "printers", "restrictedsoftware", "scripts", "softwareupdateservers"]
    var iOSEndpointArray: [String] = ["advancedmobiledevicesearches", "mobiledeviceapplications", "mobiledeviceconfigurationprofiles", "smartmobiledevicegroups", "staticmobiledevicegroups", "mobiledevices",  "mobiledeviceextensionattributes"]
    var generalEndpointArray: [String] = ["advancedusersearches", "buildings", "categories", "departments", "jamfusers", "jamfgroups", "ldapservers", "networksegments", "sites", "userextensionattributes", "users", "smartusergroups", "staticusergroups"]
    var AllEndpointsArray = [String]()
    
    
    var getEndpointInProgress = ""     // end point currently in the GET queue
    var endpointInProgress    = ""     // end point currently in the POST queue
    var endpointName          = ""
    var POSTsuccessCount      = 0
    var failedCount           = 0
    var postCount             = 1       // is this needed?
    var counters    = Dictionary<String, Dictionary<String,Int>>()             // summary counters of created, updated, failed, and deleted objects
    var getCounters = [String:[String:Int]]()
//    var tmp_counter = Dictionary<String, Dictionary<String,Int>>()          // used to hold value of counter and avoid simultaneous access when updating
    var summaryDict = Dictionary<String, Dictionary<String,[String]>>()     // summary arrays of created, updated, and failed objects

    @IBOutlet weak var mySpinner_ImageView: NSImageView!
    var theImage:[NSImage] = [NSImage(named: "0.png")!,
                              NSImage(named: "1.png")!,
                              NSImage(named: "2.png")!]
    var showSpinner = false
    
    // group counters
    var smartCount      = 0
    var staticCount     = 0
    //var DeviceGroupType = ""  // either smart or static
    // var groupCheckArray: [Bool] = []
    
    
    // define list of items to migrate
    var objectsToMigrate: [String] = []
    var nodesMigrated              = 0
    var objectNode                 = "" // link dependency type to object endpoint. ex. (dependency) category to (endpoint) categories

    // dictionaries to map id of object on source server to id of same object on destination server
//    var computerconfigs_id_map = [String:Dictionary<String,Int>]()
    var bindings_id_map   = [String:Dictionary<String,Int>]()
    var packages_id_map   = [String:Dictionary<String,Int>]()
    var printers_id_map   = [String:Dictionary<String,Int>]()
    var scripts_id_map    = [String:Dictionary<String,Int>]()
    var configObjectsDict = [String:Dictionary<String,String>]()
    var orphanIds         = [String]()
    var idDict            = [String:Dictionary<String,Int>]()
    
//    var wipeData.on: Bool = false
    
    let fm         = FileManager()
    var theOpQ     = OperationQueue() // create operation queue for API calls
    var theCreateQ = OperationQueue() // create operation queue for API POST/PUT calls
    var readFilesQ = OperationQueue() // for reading in data files
//    var readFilesQ = DispatchQueue(label: "com.jamf.readFilesQ", qos: DispatchQoS.background)   // for reading in data files
    var readNodesQ = DispatchQueue(label: "com.jamf.readNodesQ")   // for reading in API endpoints
    let theIconsQ  = OperationQueue() // que to upload/download icons
    
    var authQ       = DispatchQueue(label: "com.jamf.auth")
    var theModeQ    = DispatchQueue(label: "com.jamf.addRemove")
    var theSpinnerQ = DispatchQueue(label: "com.jamf.spinner")
    var destEPQ     = DispatchQueue(label: "com.jamf.destEPs", qos: DispatchQoS.background)
    var idMapQ      = DispatchQueue(label: "com.jamf.idMap")
    var sortQ       = DispatchQueue(label: "com.jamf.sortQ", qos: DispatchQoS.default)
    
    var concurrentThreads = 3
    
    var migrateOrWipe: String = ""
    var httpStatusCode: Int = 0
    var URLisValid: Bool = true
    var processGroup = DispatchGroup()
    
    @IBAction func deleteMode_fn(_ sender: Any) {
        var isDir: ObjCBool = false
        // turn off all selected items - start
        print("[deleteMode_fn] endpoint: NA")
        resetAllCheckboxes()
        // turn off all selected items - end
        
        if (fm.fileExists(atPath: NSHomeDirectory() + "/Library/Application Support/jamf-migrator/DELETE", isDirectory: &isDir)) {
            if LogLevel.debug { WriteToLog().message(stringOfText: "Disabling delete mode\n") }
            do {
                try self.fm.removeItem(atPath: NSHomeDirectory() + "/Library/Application Support/jamf-migrator/DELETE")
                self.sourceDataArray.removeAll()
                self.srcSrvTableView.stringValue = ""
                self.srcSrvTableView.reloadData()
                self.selectiveListCleared = true
                _ = serverOrFiles()
            }
            catch let error as NSError {
                if LogLevel.debug { WriteToLog().message(stringOfText: "Unable to delete file! Something went wrong: \(error)\n") }
            }
            wipeData.on = false
        } else {
            if LogLevel.debug { WriteToLog().message(stringOfText: "Enabling delete mode to removing data from destination server - \(dest_jp_server_field.stringValue)\n") }
            do {
                try self.fm.createFile(atPath: NSHomeDirectory() + "/Library/Application Support/jamf-migrator/DELETE", contents: nil)
            }
            catch let error as NSError {
                if LogLevel.debug { WriteToLog().message(stringOfText: "Unable to create delete file! Something went wrong: \(error)\n") }
            }
            DispatchQueue.main.async {
                wipeData.on = true
                self.migrateDependencies.state = NSControl.StateValue(rawValue: 0)
                self.migrateDependencies.isHidden = true
            }
        }
    }
    
    var tabImage:[NSImage] = [NSImage(named: "general.png")!,
                              NSImage(named: "general_active.png")!,
                              NSImage(named: "macos.png")!,
                              NSImage(named: "macos_active.png")!,
                              NSImage(named: "ios.png")!,
                              NSImage(named: "ios_active.png")!,
                              NSImage(named: "selective.png")!,
                              NSImage(named: "selective_active.png")!]
    
    @IBOutlet weak var generalTab_NSButton: NSButton!
    @IBOutlet weak var macosTab_NSButton: NSButton!
    @IBOutlet weak var iosTab_NSButton: NSButton!
    @IBOutlet weak var selectiveTab_NSButton: NSButton!
    
    @IBAction func selectTab_fn(_ sender: NSButton) {
        let whichTab = (sender.identifier?.rawValue)!
        switch whichTab {
        case "generalTab":
            setTab_fn(selectedTab: "General")
        case "macosTab":
            setTab_fn(selectedTab: "macOS")
        case "iosTab":
            setTab_fn(selectedTab: "iOS")
        default:
            setTab_fn(selectedTab: "Selective")
        }
    }
    
    func setTab_fn(selectedTab: String) {
        DispatchQueue.main.async {
            switch selectedTab {
            case "General":
                self.activeTab_TabView.selectTabViewItem(at: 0)
                self.generalTab_NSButton.image = self.tabImage[1]
                self.macosTab_NSButton.image = self.tabImage[2]
                self.iosTab_NSButton.image = self.tabImage[4]
                self.selectiveTab_NSButton.image = self.tabImage[6]
            case "macOS":
                self.activeTab_TabView.selectTabViewItem(at: 1)
                self.generalTab_NSButton.image = self.tabImage[0]
                self.macosTab_NSButton.image = self.tabImage[3]
                self.iosTab_NSButton.image = self.tabImage[4]
                self.selectiveTab_NSButton.image = self.tabImage[6]
            case "iOS":
                self.activeTab_TabView.selectTabViewItem(at: 2)
                self.generalTab_NSButton.image = self.tabImage[0]
                self.macosTab_NSButton.image = self.tabImage[2]
                self.iosTab_NSButton.image = self.tabImage[5]
                self.selectiveTab_NSButton.image = self.tabImage[6]
            default:
                self.activeTab_TabView.selectTabViewItem(at: 3)
                self.generalTab_NSButton.image = self.tabImage[0]
                self.macosTab_NSButton.image = self.tabImage[2]
                self.iosTab_NSButton.image = self.tabImage[4]
                self.selectiveTab_NSButton.image = self.tabImage[7]
            }   // swtich - end
        }   // DispatchQueue - end
    }   // func setTab_fn - end
    
    @IBAction func showLogFolder(_ sender: Any) {
//        activeTab_TabView.selectTabViewItem(at: 0)
        
        isDir = true
        if (self.fm.fileExists(atPath: logPath!, isDirectory: &isDir)) {
            NSWorkspace.shared.openFile(logPath!)
        } else {
            alert_dialog(header: "Alert", message: "There are currently no log files to display.")
        }
    }
    
    @IBAction func fileImport(_ sender: Any) {
        if importFiles_button.state.rawValue == 1 {
            DispatchQueue.main.async {
                let openPanel = NSOpenPanel()
            
                openPanel.canChooseDirectories = true
                openPanel.canChooseFiles       = false
            
                openPanel.begin { (result) in
                    if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                        self.exportedFilesUrl = openPanel.url
                        self.dataFilesRoot = (self.exportedFilesUrl?.absoluteString.replacingOccurrences(of: "file://", with: ""))!
                        self.dataFilesRoot = self.dataFilesRoot.replacingOccurrences(of: "%20", with: " ")
        //                print("encoded dataFilesRoot: \(String(describing: dataFilesRoot))")
                        self.source_jp_server_field.stringValue = self.dataFilesRoot
                        self.source_user_field.isHidden = true
                        self.source_pwd_field.isHidden = true
//                        self.source_user_field.stringValue = ""
//                        self.source_user_field.isEnabled = false
//                        self.source_pwd_field.stringValue = ""
//                        self.source_pwd_field.isEnabled = false
                        self.fileImport = true
                    } else {
                        self.source_jp_server_field.stringValue = ""
                        self.source_user_field.isHidden = false
                        self.source_pwd_field.isHidden = false
                        self.fileImport = false
                        self.importFiles_button.state = NSControl.StateValue(rawValue: 0)
                    }
                } // openPanel.begin - end
                // if importFiles_button.state - end
            }
        } else {
            DispatchQueue.main.async {
                self.source_jp_server_field.stringValue = ""
                self.source_user_field.isHidden = false
                self.source_pwd_field.isHidden = false
                self.fileImport = false
                self.importFiles_button.state = NSControl.StateValue(rawValue: 0)
            }
        }
    }   // @IBAction func fileImport - end
    
    
    @IBAction func toggleAllNone(_ sender: NSButton) {
        //        platform = deviceType()
        if deviceType() == "macOS" {
            self.allNone_button.state = NSControl.StateValue(rawValue: (
                self.advcompsearch_button.state.rawValue == 1
                    && self.computers_button.state.rawValue == 1
                    && self.configurations_button.state.rawValue == 1
                    && self.directory_bindings_button.state.rawValue == 1
                    && self.disk_encryptions_button.state.rawValue == 1
                    && self.dock_items_button.state.rawValue == 1
                    && self.fileshares_button.state.rawValue == 1
                    && self.sus_button.state.rawValue == 1
                    && self.netboot_button.state.rawValue == 1
                    && self.osxconfigurationprofiles_button.state.rawValue == 1
                    //                    && self.patch_mgmt_button.state == 1
                    && self.patch_policies_button.state.rawValue == 1
                    && self.smart_comp_grps_button.state.rawValue == 1
                    && self.static_comp_grps_button.state.rawValue == 1
                    && self.ext_attribs_button.state.rawValue == 1
                    && self.scripts_button.state.rawValue == 1
                    && self.macapplications_button.state.rawValue == 1
                    && self.packages_button.state.rawValue == 1
                    && self.printers_button.state.rawValue == 1
                    && self.restrictedsoftware_button.state.rawValue == 1
                    && self.policies_button.state.rawValue == 1) ? 1 : 0);
        } else if deviceType() == "iOS" {
            self.allNone_iOS_button.state = NSControl.StateValue(rawValue: (
                self.mobiledeviceconfigurationprofiles_button.state.rawValue == 1
                    && self.mobiledevices_button.state.rawValue == 1
                    && self.smart_ios_groups_button.state.rawValue == 1
                    && self.static_ios_groups_button.state.rawValue == 1
                    && self.mobiledevicecApps_button.state.rawValue == 1
                    && self.mobiledeviceextensionattributes_button.state.rawValue == 1
                    && self.advancedmobiledevicesearches_button.state.rawValue == 1) ? 1 : 0);
        } else {
            // general
            self.allNone_general_button.state = NSControl.StateValue(rawValue: (
                self.building_button.state.rawValue == 1
                    && self.categories_button.state.rawValue == 1
                    && self.dept_button.state.rawValue == 1
                    && self.advusersearch_button.state.rawValue == 1
                    && self.userEA_button.state.rawValue == 1
                    && self.ldapservers_button.state.rawValue == 1
                    && self.sites_button.state.rawValue == 1
                    && self.networks_button.state.rawValue == 1
                    && self.jamfUserAccounts_button.state.rawValue == 1
                    && self.jamfGroupAccounts_button.state.rawValue == 1
                    && self.smartUserGrps_button.state.rawValue == 1
                    && self.staticUserGrps_button.state.rawValue == 1
                    && self.users_button.state.rawValue == 1) ? 1 : 0);
        }
    }
    
    @IBAction func allNone(_ sender: Any) {
        if deviceType() == "macOS" {
            self.advcompsearch_button.state = self.allNone_button.state
            self.computers_button.state = self.allNone_button.state
            self.configurations_button.state = self.allNone_button.state
            self.directory_bindings_button.state = self.allNone_button.state
            self.disk_encryptions_button.state = self.allNone_button.state
            self.dock_items_button.state = self.allNone_button.state
            self.fileshares_button.state = self.allNone_button.state
            self.sus_button.state = self.allNone_button.state
            self.netboot_button.state = self.allNone_button.state
            self.osxconfigurationprofiles_button.state = self.allNone_button.state
//            self.patch_mgmt_button.state = self.allNone_button.state
            self.patch_policies_button.state = self.allNone_button.state
            self.smart_comp_grps_button.state = self.allNone_button.state
            self.static_comp_grps_button.state = self.allNone_button.state
            self.ext_attribs_button.state = self.allNone_button.state
            self.scripts_button.state = self.allNone_button.state
            self.macapplications_button.state = self.allNone_button.state
            self.packages_button.state = self.allNone_button.state
            self.printers_button.state = self.allNone_button.state
            self.restrictedsoftware_button.state = self.allNone_button.state
            self.policies_button.state = self.allNone_button.state
        } else if deviceType() == "iOS" {
            self.advancedmobiledevicesearches_button.state = self.allNone_iOS_button.state
            self.mobiledevices_button.state = self.allNone_iOS_button.state
            self.smart_ios_groups_button.state = self.allNone_iOS_button.state
            self.static_ios_groups_button.state = self.allNone_iOS_button.state
            self.mobiledevicecApps_button.state = self.allNone_iOS_button.state
            self.mobiledeviceextensionattributes_button.state = self.allNone_iOS_button.state
            self.mobiledeviceconfigurationprofiles_button.state = self.allNone_iOS_button.state
        } else {
            self.building_button.state = self.allNone_general_button.state
            self.categories_button.state = self.allNone_general_button.state
            self.dept_button.state = self.allNone_general_button.state
            self.advusersearch_button.state = self.allNone_general_button.state
            self.userEA_button.state = self.allNone_general_button.state
            self.ldapservers_button.state = self.allNone_general_button.state
            self.sites_button.state = self.allNone_general_button.state
            self.networks_button.state = self.allNone_general_button.state
            self.jamfUserAccounts_button.state = self.allNone_general_button.state
            self.jamfGroupAccounts_button.state = self.allNone_general_button.state
            self.smartUserGrps_button.state = self.allNone_general_button.state
            self.staticUserGrps_button.state = self.allNone_general_button.state
            self.users_button.state = self.allNone_general_button.state
        }
    }
    
    @IBAction func sectionToMigrate(_ sender: NSPopUpButton) {
        if fileImport {
            alert_dialog(header: "Attention:", message: "Selective migration while importing files is not yet available.")
            return
        }
        
        let whichTab = sender.identifier!.rawValue
        
        if LogLevel.debug { WriteToLog().message(stringOfText: "func sectionToMigrate active tab: \(String(describing: whichTab)).\n") }
        var itemIndex = 0
        switch whichTab {
        case "macOS":
            itemIndex = sectionToMigrate_button.indexOfSelectedItem
        case "iOS":
            itemIndex = iOSsectionToMigrate_button.indexOfSelectedItem
        default:
            itemIndex = generalSectionToMigrate_button.indexOfSelectedItem
        }
        
        if whichTab != "macOS" {
            DispatchQueue.main.async {
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
            objectsToMigrate.removeAll()
            sourceDataArray.removeAll()
            srcSrvTableView.reloadData()
            targetDataArray.removeAll()
            //            desSrvTableView.reloadData()
            
            if whichTab == "macOS" {
                AllEndpointsArray = macOSEndpointArray
            } else if whichTab == "iOS" {
                AllEndpointsArray = iOSEndpointArray
            } else {
                AllEndpointsArray = generalEndpointArray
            }
            
            objectsToMigrate.append(AllEndpointsArray[itemIndex-1])
            
//            print("wipeData.on: \(wipeData.on)")
            if AllEndpointsArray[itemIndex-1] == "policies" && !wipeData.on {
                DispatchQueue.main.async {
                    self.migrateDependencies.isHidden = false
                }
            } else {
                DispatchQueue.main.async {
                    self.migrateDependencies.isHidden = true
                }
            }
            
            if LogLevel.debug { WriteToLog().message(stringOfText: "Selectively migrating: \(objectsToMigrate) for \(sender.identifier ?? NSUserInterfaceItemIdentifier(rawValue: ""))\n") }
            Go(sender: self)
        }
    }
    
    @IBAction func Go(sender: AnyObject) {
//        print("go (before readSettings) scopeOptions: \(String(describing: scopeOptions))\n")
        plistData           = readSettings()
        scopeOptions        = plistData["scope"] as! Dictionary<String,Dictionary<String,Bool>>
        xmlPrefOptions      = plistData["xml"] as! Dictionary<String,Bool>
        saveOnly            = xmlPrefOptions["saveOnly"]!
        saveRawXml          = xmlPrefOptions["saveRawXml"]!
        saveTrimmedXml      = xmlPrefOptions["saveTrimmedXml"]!
        saveRawXmlScope     = (xmlPrefOptions["saveRawXmlScope"] == nil) ? true:xmlPrefOptions["saveRawXmlScope"]!
        saveTrimmedXmlScope = (xmlPrefOptions["saveTrimmedXmlScope"] == nil) ? true:xmlPrefOptions["saveRawXmlScope"]!
        
        if fileImport && (saveOnly || saveRawXml) {
            alert_dialog(header: "Attention", message: "Cannot select Save Only or Raw Source XML (Preferneces -> Export) when using File Import.")
            return
        }

        didRun = true

        if LogLevel.debug { WriteToLog().message(stringOfText: "Start Migrating/Removal\n") }
        // check for file that allow deleting data from destination server - start
        //       var isDir: ObjCBool = false
        if (fm.fileExists(atPath: NSHomeDirectory() + "/Library/Application Support/jamf-migrator/DELETE", isDirectory: &isDir)) {
            if LogLevel.debug { WriteToLog().message(stringOfText: "Removing data from destination server - \(dest_jp_server_field.stringValue)\n") }
            wipeData.on = true
            
            migrateOrWipe = "----------- Starting To Wipe Data -----------\n"
        } else {
            // verify source and destination are not the same - start
            if (source_jp_server_field.stringValue == dest_jp_server_field.stringValue) && siteMigrate.state.rawValue == 0 {
                alert_dialog(header: "Alert", message: "Source and destination servers cannot be the same.")
                self.goButtonEnabled(button_status: true)
                return
            }
            // verify source and destination are not the same - end
            if LogLevel.debug { WriteToLog().message(stringOfText: "Migrating data from \(source_jp_server_field.stringValue) to \(dest_jp_server_field.stringValue).\n") }
            wipeData.on = false
            
            migrateOrWipe = "----------- Starting Migration -----------\n"
        }
        // check for file that allow deleting data from destination server - end
        
        
        if LogLevel.debug { WriteToLog().message(stringOfText: "go sender tag: \(String(describing: sender.tag))\n") }
        // determine if we got here from the Go button or selectToMigrate button
        if sender.tag != nil {
            self.goSender = "goButton"
        } else {
            self.goSender = "selectToMigrateButton"
        }
        if LogLevel.debug { WriteToLog().message(stringOfText: "Go button pressed from: \(goSender)\n") }
        
        // which migration mode tab are we on - start
        if activeTab() != "selective" {
            migrationMode = "bulk"
        } else {
            migrationMode = "selective"
        }
        if LogLevel.debug { WriteToLog().message(stringOfText: "Migration Mode (Go): \(migrationMode)\n") }
        
        //self.go_button.isEnabled = false
        nodesMigrated = -1
        goButtonEnabled(button_status: false)
        clearProcessingFields()
        currentEPs.removeAll()
        
        // credentials were entered check - start
        // don't check if we're importing files
        if !fileImport {
            if (source_user_field.stringValue == "" || source_pwd_field.stringValue == "") && !wipeData.on {
                alert_dialog(header: "Alert", message: "Must provide both a username and password for the source server.")
                //self.go_button.isEnabled = true
                goButtonEnabled(button_status: true)
                return
            }
        }
        if !saveOnly {
            if dest_user_field.stringValue == "" || dest_pwd_field.stringValue == "" {
                alert_dialog(header: "Alert", message: "Must provide both a username and password for the destination server.")
                //self.go_button.isEnabled = true
                goButtonEnabled(button_status: true)
                return
            }
        }
        // credentials check - end
        
        // set credentials / servers - start
        // don't set user / pass if we're importing files
        self.source_jp_server = source_jp_server_field.stringValue
        if !fileImport && !wipeData.on {
            self.source_user = source_user_field.stringValue
            self.source_pass = source_pwd_field.stringValue
        }

        self.dest_jp_server = dest_jp_server_field.stringValue
        self.dest_user = dest_user_field.stringValue
        self.dest_pass = dest_pwd_field.stringValue
        // set credentials / servers - end
        
        // server is reachable - start
        // don't check if we're importing files
        if !fileImport {
            if !wipeData.on {
                checkURL2(whichServer: "source", serverURL: self.source_jp_server)  {
                    (result: Bool) in
        //            print("checkURL2 returned result: \(result)")
                    if !result {
                        self.alert_dialog(header: "Attention:", message: "Unable to contact the source server:\n\(self.source_jp_server)")
                        self.goButtonEnabled(button_status: true)
                        return
                    }
                }
            }
        }
        
        // set site, if option selected - start
        if siteMigrate.state.rawValue == 1 {
            destinationSite = availableSites_button.selectedItem!.title
            itemToSite = true
        } else {
            itemToSite = false
        }
        // set site, if option selected - end
        
        checkURL2(whichServer: "dest", serverURL: self.dest_jp_server)  {
            (result: Bool) in
//            print("checkURL2 returned result: \(result)")
            if !result {
                self.alert_dialog(header: "Attention:", message: "Unable to contact the destination server:\n\(self.dest_jp_server)")
                self.goButtonEnabled(button_status: true)
                return
            }
            // server is reachable - end
            // don't set if we're importing files
            if !self.fileImport {
                self.sourceCreds = "\(self.source_user):\(self.source_pass)"
            } else {
                self.sourceCreds = ":"
            }
            self.sourceBase64Creds = self.sourceCreds.data(using: .utf8)?.base64EncodedString() ?? ""
            
            self.destCreds = "\(self.dest_user):\(self.dest_pass)"
            self.destBase64Creds = self.destCreds.data(using: .utf8)?.base64EncodedString() ?? ""
            // set credentials - end
            
            var sourceURL      = URL(string: "")
            var destinationURL = URL(string: "")
            
            // check authentication - start
            self.authCheck(whichServer: "source", f_sourceURL: self.source_jp_server, f_credentials: self.sourceBase64Creds)  {
                (result: Bool) in
                if !result && !wipeData.on {
                    if LogLevel.debug { WriteToLog().message(stringOfText: "Source server authentication failure.") }
                    return
                } else {
//                    if !self.fileImport {
                    if !wipeData.on {
                        self.updateServerArray(url: self.source_jp_server, serverList: "source_server_array", theArray: self.sourceServerArray)
                    }
                    self.authCheck(whichServer: "dest", f_sourceURL: self.dest_jp_server, f_credentials: self.destBase64Creds)  {
                        (result: Bool) in
                        if !result {
                            if LogLevel.debug { WriteToLog().message(stringOfText: "Destination server authentication failure.") }
                            return
                        } else {
                            if !self.saveOnly {
                                self.updateServerArray(url: self.dest_jp_server, serverList: "dest_server_array", theArray: self.destServerArray)
                            }
                            // verify source server URL - start
                            if !self.fileImport && !wipeData.on {
                                sourceURL = URL(string: self.source_jp_server_field.stringValue)
                            } else {
                                sourceURL = URL(string: "https://www.jamf.com")
                            }
                            URLCache.shared.removeAllCachedResponses()
                            let task_sourceURL = URLSession.shared.dataTask(with: sourceURL!) { _, response, _ in
                                if (response as? HTTPURLResponse) != nil || (response as? HTTPURLResponse) == nil || self.fileImport {
                                    //print(HTTPURLResponse.statusCode)
                                    //===== change to go to function to check dest. server, which forwards to migrate if all is well
                                    // verify destination server URL - start
                                    DispatchQueue.main.async {
                                        if !self.saveOnly {
                                            destinationURL = URL(string: self.dest_jp_server_field.stringValue)
                                        } else {
                                            destinationURL = URL(string: "https://www.jamf.com")
                                        }
                                        URLCache.shared.removeAllCachedResponses()
                                        let task_destinationURL = URLSession.shared.dataTask(with: destinationURL!) { _, response, _ in
                                            if (response as? HTTPURLResponse) != nil || (response as? HTTPURLResponse) == nil || self.saveOnly {
                                                // print("Destination server response: \(response)")
                                                if(!self.theOpQ.isSuspended) {
                                                    //====================================    Start Migrating/Removing    ====================================//
                                                    self.startMigrating()
                                                }
                                            } else {
//                                                DispatchQueue.main.async {
                                                    //print("Destination server response: \(response)")
                                                self.alert_dialog(header: "Attention:", message: "The destination server URL could not be validated.")
//                                                }
                                                
                                                if LogLevel.debug { WriteToLog().message(stringOfText: "Failed to connect to destination server.") }
                                                self.goButtonEnabled(button_status: true)
                                                return
                                            }
                                        }   // let task for destinationURL - end
                                    
                                        task_destinationURL.resume()
                                    }
                                    // verify source destination URL - end
                                    
                                } else {
                                    DispatchQueue.main.async {
                                        self.alert_dialog(header: "Attention:", message: "The source server URL could not be validated.")
                                    }
                                    if LogLevel.debug { WriteToLog().message(stringOfText: "Failed to connect source server.") }
                                    self.goButtonEnabled(button_status: true)
                                    return
                                }
                            }   // let task for soureURL - end
                            task_sourceURL.resume()
                            // verify source server URL - end
                        }
                    }
                }   // else check dest URL auth - end
            }
            // check authentication - end
        }   // checkURL2 (destination server) - end
    }   // checkURL2 (source server) - end
    
    
    @IBAction func QuitNow(sender: AnyObject) {
        // check for file that sets mode to delete data from destination server, delete if found - start
        rmDELETE()
        // check for file that allows deleting data from destination server, delete if found - end
        self.goButtonEnabled(button_status: true)
        
        let tabLabel = (activeTab_TabView.selectedTabViewItem?.label)!        
        userDefaults.set(tabLabel, forKey: "activeTab")

        WriteToLog().logFileW?.closeFile()
        NSApplication.shared.terminate(self)
    }
    
    //================================= migration functions =================================//
    
    func authCheck(whichServer: String, f_sourceURL: String, f_credentials: String, completion: @escaping (Bool) -> Void) {
        URLCache.shared.removeAllCachedResponses()
        var validCredentials:Bool = false
        if LogLevel.debug { WriteToLog().message(stringOfText: "--- checking authentication to \(whichServer) server: \(f_sourceURL)\n") }
        
        if (whichServer == "source" && (!wipeData.on && !fileImport)) || (whichServer == "dest" && !saveOnly) {
            var myURL = "\(f_sourceURL)/JSSResource/buildings"
            myURL = myURL.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
            authQ.sync {
                if LogLevel.debug { WriteToLog().message(stringOfText: "checking: \(myURL)\n") }
                
                let encodedURL = NSURL(string: myURL)
                let request = NSMutableURLRequest(url: encodedURL! as URL)
                //let request = NSMutableURLRequest(url: encodedURL as! URL, cachePolicy: NSURLRequest.CachePolicy(rawValue: 1)!, timeoutInterval: 10)
                request.httpMethod = "GET"
                let configuration = URLSessionConfiguration.default
                configuration.httpAdditionalHeaders = ["Authorization" : "Basic \(f_credentials)", "Accept" : "application/json"]
                let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
                let task = session.dataTask(with: request as URLRequest, completionHandler: {
                    (data, response, error) -> Void in
                    if let httpResponse = response as? HTTPURLResponse {
                        if LogLevel.debug { WriteToLog().message(stringOfText: "\(myURL) auth check httpResponse: \(httpResponse.statusCode)\n") }
                        
                        if httpResponse.statusCode >= 199 && httpResponse.statusCode <= 299 {
                            if LogLevel.debug { WriteToLog().message(stringOfText: "[\(whichServer) server] \(myURL) auth httpResponse, between 199 and 299: \(httpResponse.statusCode)\n") }
                            
                            if (!self.validCreds) || (self.source_user_field.stringValue != self.storedSourceUser) || (self.dest_user_field.stringValue != self.storedDestUser) {
                                // save credentials to login keychain - start
                                let regexKey = try! NSRegularExpression(pattern: "http(.*?)://", options:.caseInsensitive)
                                if f_sourceURL == self.source_jp_server && !wipeData.on {
                                    if self.storeCredentials_button.state.rawValue == 1 {
                                        let credKey = regexKey.stringByReplacingMatches(in: f_sourceURL, options: [], range: NSRange(0..<f_sourceURL.utf16.count), withTemplate: "")
                                        self.Creds2.save(service: "migrator - "+credKey, account: self.source_user_field.stringValue, data: self.source_pwd_field.stringValue)
//                                        self.Creds.save("migrator - "+credKey, account: self.source_user_field.stringValue, data: self.source_pwd_field.stringValue)
                                        self.storedSourceUser = self.source_user_field.stringValue
                                    }
                                } else {
                                    if self.storeCredentials_button.state.rawValue == 1 {
                                        let credKey = regexKey.stringByReplacingMatches(in: f_sourceURL, options: [], range: NSRange(0..<f_sourceURL.utf16.count), withTemplate: "")
                                        self.Creds2.save(service: "migrator - "+credKey, account: self.dest_user_field.stringValue, data: self.dest_pwd_field.stringValue)
//                                        self.Creds.save("migrator - "+credKey, account: self.dest_user_field.stringValue, data: self.dest_pwd_field.stringValue)
                                        self.storedDestUser = self.dest_user_field.stringValue
                                    }
                                }
                                // save credentials to login keychain - end
                            }

                            validCredentials = true
                            
                            if whichServer == "dest" {

                                if LogLevel.debug { WriteToLog().message(stringOfText: "[\(whichServer) server] Query Jamf Pro API for token.\n") }
                                
                                UapiCall().getToken(serverUrl: f_sourceURL, base64creds: f_credentials) {
                                    (returnedToken: String) in
                                    if returnedToken == "" {
                                        if LogLevel.debug { WriteToLog().message(stringOfText: "[\(whichServer) server] Unable to get token.\n") }
//                                        completion(false)
                                        completion(validCredentials)
                                        return
                                    }
//                                    print("token received.")
                                    if LogLevel.debug { WriteToLog().message(stringOfText: "[\(whichServer) server] Token received.  Query Jamf Pro API for version.\n") }
                                    UapiCall().get(serverUrl: f_sourceURL, path: "preview/jamf-pro-information", token: returnedToken, action: "GET") {
                                        (json: [String:Any] ) in
//                                        print("json \(json)")
                                        if let fullVersion = json["jamfProVersion"] {
                                            let versionArray = "\(fullVersion)".split(separator: ".")
                                            if versionArray.count >= 2 {
                                                jamfProVersion.major = Int("\(versionArray[0])") ?? 0
                                                jamfProVersion.minor = Int("\(versionArray[1])") ?? 0
                                            }
                                        } else {
                                            if LogLevel.debug { WriteToLog().message(stringOfText: "[\(whichServer) server] Unable to get server version for Jamf Pro API.\n") }
                                        }
                                        completion(validCredentials)
                                    }
                                    
                                }
                            } else {
                                completion(validCredentials)
                            }
                            
                        } else {
                            if LogLevel.debug { WriteToLog().message(stringOfText: "\n\n") }
                            if LogLevel.debug { WriteToLog().message(stringOfText: "---------- status code ----------\n") }
                            if LogLevel.debug { WriteToLog().message(stringOfText: "\(httpResponse.statusCode)\n") }
                            self.httpStatusCode = httpResponse.statusCode
                            if LogLevel.debug { WriteToLog().message(stringOfText: "---------- status code ----------\n") }
                            if LogLevel.debug { WriteToLog().message(stringOfText: "\n\n---------- response ----------\n") }
                            if LogLevel.debug { WriteToLog().message(stringOfText: "\(httpResponse)\n") }
                            if LogLevel.debug { WriteToLog().message(stringOfText: "---------- response ----------\n\n") }
                            self.theOpQ.cancelAllOperations()
                            switch self.httpStatusCode {
                            case 401:
                                self.alert_dialog(header: "Authentication Failure", message: "Please verify username and password for:\n\(f_sourceURL)")
                            case 503:
                                self.alert_dialog(header: "Service Unavailable", message: "Verify you can manually log into the API:\n\(f_sourceURL)/api. \nError: \(self.httpStatusCode)")
                            default:
                                self.alert_dialog(header: "Error", message: "An unknown error (\(self.httpStatusCode)) occured trying to query the server:\n\(f_sourceURL)")
                            }
                            //                        401 - wrong username and/or password
                            //                        409 - unable to create object; data missing or xml error
                            self.goButtonEnabled(button_status: true)
                            self.validCreds = false
                            completion(validCredentials)
                        }   // if httpResponse/else - end
                    }   // if let httpResponse - end
                    // server not reachable
                    //                    if error != nil {
                    //                    }
                })  // let task = session - end
                task.resume()
            }   // authQ - end
        } else {
            completion(true)
        }
        
    }   // func authCheck - end
    
    func startMigrating() {
        
        if LogLevel.debug { WriteToLog().message(stringOfText: "[startMigrating] enter\n") }
        
        // make sure the labels can change color when we start
                  changeColor = true
        getEndpointInProgress = "start"
        endpointInProgress    = ""
        var idPath            = ""  // adjust for jamf users/groups that use userid/groupid instead of id
        
        DispatchQueue.main.async {
            self.importFiles_button.state.rawValue == 0 ? (self.fileImport = false):(self.fileImport = true)
            self.createDestUrlBase = "\(self.dest_jp_server_field.stringValue)/JSSResource"
//        }
        
        
        
        // set all the labels to white - start
            self.AllEndpointsArray = self.macOSEndpointArray + self.iOSEndpointArray + self.generalEndpointArray
            for i in (0..<self.AllEndpointsArray.count) {
                self.labelColor(endpoint: self.AllEndpointsArray[i], theColor: self.whiteText)
            }
            // set all the labels to white - end
            if LogLevel.debug { WriteToLog().message(stringOfText: "Start Migrating/Removal\n") }
            if LogLevel.debug { WriteToLog().message(stringOfText: "platform: \(self.deviceType()).\n") }
            if LogLevel.debug { WriteToLog().message(stringOfText: "Migration Mode (startMigration): \(self.migrationMode).\n") }
            
                // list the items in the order they need to be migrated
            if self.migrationMode == "bulk" {
                // initialize list of items to migrate then add what we want - start
                self.objectsToMigrate.removeAll()
                if LogLevel.debug { WriteToLog().message(stringOfText: "Types of objects to migrate: \(self.deviceType()).\n") }
//                    DispatchQueue.main.async {
                    // macOS
                    switch self.deviceType() {
                    case "macOS":
                        if self.fileshares_button.state.rawValue == 1 {
                            self.objectsToMigrate += ["distributionpoints"]
                        }
                        
                        if self.directory_bindings_button.state.rawValue == 1 {
                            self.objectsToMigrate += ["directorybindings"]
                        }
                        
                        if self.disk_encryptions_button.state.rawValue == 1 {
                            self.objectsToMigrate += ["diskencryptionconfigurations"]
                        }
                        
                        if self.dock_items_button.state.rawValue == 1 {
                            self.objectsToMigrate += ["dockitems"]
                        }
                        
                        if self.computers_button.state.rawValue == 1 {
                            self.objectsToMigrate += ["computers"]
                        }
                        
                        if self.sus_button.state.rawValue == 1 {
                            self.objectsToMigrate += ["softwareupdateservers"]
                        }
                        
                        if self.netboot_button.state.rawValue == 1 {
                            self.objectsToMigrate += ["netbootservers"]
                        }
                        
                        if self.ext_attribs_button.state.rawValue == 1 {
                            self.objectsToMigrate += ["computerextensionattributes"]
                        }
                        
                        if self.scripts_button.state.rawValue == 1 {
                            self.objectsToMigrate += ["scripts"]
                        }
                        
                        if self.printers_button.state.rawValue == 1 {
                            self.objectsToMigrate += ["printers"]
                        }
                        
                        if self.packages_button.state.rawValue == 1 {
                            self.objectsToMigrate += ["packages"]
                        }
                        
                        if self.smart_comp_grps_button.state.rawValue == 1 || self.static_comp_grps_button.state.rawValue == 1 {
                            self.objectsToMigrate += ["computergroups"]
                            self.smart_comp_grps_button.state.rawValue == 1 ? (self.migrateSmartComputerGroups = true):(self.migrateSmartComputerGroups = false)
                            self.static_comp_grps_button.state.rawValue == 1 ? (self.migrateStaticComputerGroups = true):(self.migrateStaticComputerGroups = false)
                        }
                        
                        if self.restrictedsoftware_button.state.rawValue == 1 {
                            self.objectsToMigrate += ["restrictedsoftware"]
                        }
                        
                        if self.osxconfigurationprofiles_button.state.rawValue == 1 {
                            self.objectsToMigrate += ["osxconfigurationprofiles"]
                        }
                        
                        if self.macapplications_button.state.rawValue == 1 {
                            self.objectsToMigrate += ["macapplications"]
                        }
                        
                        if self.patch_policies_button.state.rawValue == 1 {
                            //                    self.objectsToMigrate += ["patches"]
                            self.objectsToMigrate += ["patchpolicies"]
                        }
                        
                        if self.advcompsearch_button.state.rawValue == 1 {
                            self.objectsToMigrate += ["advancedcomputersearches"]
                        }
                        
                        if self.configurations_button.state.rawValue == 1 {
                            self.objectsToMigrate += ["computerconfigurations"]
                        }
                        
                        if self.policies_button.state.rawValue == 1 {
                            self.objectsToMigrate += ["policies"]
                        }
                    case "iOS":
                        if self.mobiledeviceextensionattributes_button.state.rawValue == 1 {
                            self.objectsToMigrate += ["mobiledeviceextensionattributes"]
                        }
                        
                        if self.mobiledevices_button.state.rawValue == 1 {
                            self.objectsToMigrate += ["mobiledevices"]
                        }
                        
                        if self.smart_ios_groups_button.state.rawValue == 1 || self.static_ios_groups_button.state.rawValue == 1 {
                            self.objectsToMigrate += ["mobiledevicegroups"]
                            self.smart_ios_groups_button.state.rawValue == 1 ? (self.migrateSmartMobileGroups = true):(self.migrateSmartMobileGroups = false)
                            self.static_ios_groups_button.state.rawValue == 1 ? (self.migrateStaticMobileGroups = true):(self.migrateStaticMobileGroups = false)
                        }
                        
                        if self.advancedmobiledevicesearches_button.state.rawValue == 1 {
                            self.objectsToMigrate += ["advancedmobiledevicesearches"]
                        }
                        
                        if self.mobiledevicecApps_button.state.rawValue == 1 {
                            self.objectsToMigrate += ["mobiledeviceapplications"]
                        }
                        
                        if self.mobiledeviceconfigurationprofiles_button.state.rawValue == 1 {
                            self.objectsToMigrate += ["mobiledeviceconfigurationprofiles"]
                        }
                    case "general":
                        if self.sites_button.state.rawValue == 1 {
                            self.objectsToMigrate += ["sites"]
                        }
                        
                        if self.userEA_button.state.rawValue == 1 {
                            self.objectsToMigrate += ["userextensionattributes"]
                        }
                        
                        if self.ldapservers_button.state.rawValue == 1 {
                            self.objectsToMigrate += ["ldapservers"]
                        }
                        
                        if self.users_button.state.rawValue == 1 {
                            self.objectsToMigrate += ["users"]
                        }
                        
                        if self.building_button.state.rawValue == 1 {
                            self.objectsToMigrate += ["buildings"]
                        }
                        
                        if self.dept_button.state.rawValue == 1 {
                            self.objectsToMigrate += ["departments"]
                        }
                        
                        if self.categories_button.state.rawValue == 1 {
                            self.objectsToMigrate += ["categories"]
                        }
                        
                        if self.jamfUserAccounts_button.state.rawValue == 1 {
                            self.objectsToMigrate += ["jamfusers"]
                        }
                        
                        if self.jamfGroupAccounts_button.state.rawValue == 1 {
                            self.objectsToMigrate += ["jamfgroups"]
                        }
                        
                        if self.networks_button.state.rawValue == 1 {
                            self.objectsToMigrate += ["networksegments"]
                        }
                        
                        if self.advusersearch_button.state.rawValue == 1 {
                            self.objectsToMigrate += ["advancedusersearches"]
                        }
                        
                        if self.smartUserGrps_button.state.rawValue == 1 || self.staticUserGrps_button.state.rawValue == 1 {
                            self.objectsToMigrate += ["usergroups"]
                            self.smartUserGrps_button.state.rawValue == 1 ? (self.migrateSmartUserGroups = true):(self.migrateSmartUserGroups = false)
                            self.staticUserGrps_button.state.rawValue == 1 ? (self.migrateStaticUserGroups = true):(self.migrateStaticUserGroups = false)
                        }
                    default: break
                    }
//                        print(self.getCurrentTime()+" objectsToMigrate: \(self.objectsToMigrate)")
                
            }   // if migrationMode == "bulk" - end
            
            // initialize list of items to migrate then add what we want - end
            if LogLevel.debug { WriteToLog().message(stringOfText: "objects: \(self.objectsToMigrate).\n") }
                    
            
            if self.objectsToMigrate.count == 0 {
                if LogLevel.debug { WriteToLog().message(stringOfText: "nothing selected to migrate/remove.\n") }
                self.goButtonEnabled(button_status: true)
                return
            } else {
                self.nodesMigrated = 0
            }
            
            // reverse migration order for removal and set create / delete header for summary table
            if wipeData.on {
                self.objectsToMigrate.reverse()
                if self.objectsToMigrate.count > 0 {
                    // set server and credentials used for wipe
                    self.sourceBase64Creds = self.destBase64Creds
                    self.source_jp_server = self.dest_jp_server
                } else {
                    self.goButtonEnabled(button_status: true)
                    return
                }// end if objectsToMigrate - end
                summaryHeader.createDelete = "Delete"
            } else {   // if wipeData.on - end
                summaryHeader.createDelete = "Create"
            }
            
            
            WriteToLog().message(stringOfText: self.migrateOrWipe)
            
            // initialize created/updated/failed counters
           // need to add code to handle computergroups, mobiledevicegroups, and usergroups (done?)
            for currentNode in self.objectsToMigrate {
                switch currentNode {
                case "computergroups":
                    if self.smart_comp_grps_button.state.rawValue == 1 {
                        self.progressCountArray["smartcomputergroups"] = 0
                        self.counters["smartcomputergroups"]           = ["create":0, "update":0, "fail":0, "total":0]
                        self.summaryDict["staticcomputergroups"]       = ["create":[], "update":[], "fail":[]]
                        self.getCounters["smartcomputergroups"]        = ["get":0]
                    }
                    if self.static_comp_grps_button.state.rawValue == 1 {
                        self.progressCountArray["staticcomputergroups"] = 0
                        self.counters["staticcomputergroups"]           = ["create":0, "update":0, "fail":0, "total":0]
                        self.summaryDict["staticcomputergroups"]        = ["create":[], "update":[], "fail":[]]
                        self.getCounters["staticcomputergroups"]        = ["get":0]
                    }
                    self.progressCountArray["computergroups"] = 0 // this is the recognized end point
                case "mobiledevicegroups":
                    if self.smart_ios_groups_button.state.rawValue == 1 {
                        self.progressCountArray["smartmobiledevicegroups"] = 0
                        self.counters["smartmobiledevicegroups"]           = ["create":0, "update":0, "fail":0, "total":0]
                        self.summaryDict["smartmobiledevicegroups"]        = ["create":[], "update":[], "fail":[]]
                        self.getCounters["smartmobiledevicegroups"]        = ["get":0]
                    }
                    if self.static_ios_groups_button.state.rawValue == 1 {
                        self.progressCountArray["staticmobiledevicegroups"] = 0
                        self.counters["staticmobiledevicegroups"]           = ["create":0, "update":0, "fail":0, "total":0]
                        self.summaryDict["staticmobiledevicegroups"]        = ["create":[], "update":[], "fail":[]]
                        self.getCounters["staticmobiledevicegroups"]        = ["get":0]
                    }
                    self.progressCountArray["mobiledevicegroups"] = 0 // this is the recognized end point
                case "usergroups":
                    if self.smartUserGrps_button.state.rawValue == 1 {
                        self.progressCountArray["smartusergroups"] = 0
                        self.counters["smartusergroups"]           = ["create":0, "update":0, "fail":0, "total":0]
                        self.summaryDict["smartusergroups"]        = ["create":[], "update":[], "fail":[]]
                        self.getCounters["smartusergroups"]        = ["get":0]
                    }
                    if self.staticUserGrps_button.state.rawValue == 1 {
                        self.progressCountArray["staticusergroups"] = 0
                        self.counters["staticusergroups"]           = ["create":0, "update":0, "fail":0, "total":0]
                        self.summaryDict["staticusergroups"]        = ["create":[], "update":[], "fail":[]]
                        self.getCounters["staticusergroups"]        = ["get":0]
                    }
                    self.progressCountArray["usergroups"] = 0 // this is the recognized end point
                case "accounts":
                    if self.jamfUserAccounts_button.state.rawValue == 1 {
                        self.progressCountArray["jamfusers"] = 0
                        self.counters["jamfusers"]           = ["create":0, "update":0, "fail":0, "total":0]
                        self.summaryDict["jamfusers"]        = ["create":[], "update":[], "fail":[]]
                        self.getCounters["jamfusers"]        = ["get":0]
                    }
                    if self.jamfGroupAccounts_button.state.rawValue == 1 {
                        self.progressCountArray["jamfgroups"] = 0
                        self.counters["jamfgroups"]           = ["create":0, "update":0, "fail":0, "total":0]
                        self.summaryDict["jamfgroups"]        = ["create":[], "update":[], "fail":[]]
                        self.getCounters["jamfgroups"]        = ["get":0]
                    }
                    self.progressCountArray["accounts"] = 0 // this is the recognized end point
                default:
                    self.progressCountArray["\(currentNode)"] = 0
                    self.counters[currentNode] = ["create":0, "update":0, "fail":0, "total":0]
                    self.summaryDict[currentNode] = ["create":[], "update":[], "fail":[]]
                    self.getCounters[currentNode] = ["get":0]
                }
            }

            // get scope copy / policy disable options
            self.scopeOptions = self.readSettings()["scope"] as! Dictionary<String, Dictionary<String, Bool>>
//            print("startMigrating scopeOptions: \(String(describing: self.scopeOptions))")
            
            // get preference settings - start
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
            // get preference settings - end
            
            if LogLevel.debug { WriteToLog().message(stringOfText: "migrating/removing \(self.objectsToMigrate.count) sections\n") }
//            var arrayIndex = 0
            // loop through process of migrating or removing - start
            self.readNodesQ.sync {
                let currentNode = self.objectsToMigrate[0]

                if LogLevel.debug { WriteToLog().message(stringOfText: "Starting to process \(currentNode)\n") }
                if (self.goSender == "goButton" && self.migrationMode == "bulk") || (self.goSender == "selectToMigrateButton") {
                    if LogLevel.debug { WriteToLog().message(stringOfText: "getting endpoint: \(currentNode)\n") }
                    
                    self.readNodes(nodesToMigrate: self.objectsToMigrate, nodeIndex: 0)
                    
                } else {
                    // **************************************** selective migration - start ****************************************
                    if self.fileImport {
                        self.alert_dialog(header: "Attention:", message: "Selective migration is not yet available when importing files.")
                        self.goButtonEnabled(button_status: true)
                        return
                    }
                    var selectedEndpoint = ""
                    switch self.objectsToMigrate[0] {
                    case "jamfusers":
                        selectedEndpoint = "accounts/userid"
                    case "jamfgroups":
                        selectedEndpoint = "accounts/groupid"
                    default:
                        selectedEndpoint = self.objectsToMigrate[0]
                    }
                    self.existingEndpoints(theDestEndpoint: "\(self.objectsToMigrate[0])")  {
                        (result: String) in
                        if LogLevel.debug { WriteToLog().message(stringOfText: "Returned from existing endpoints: \(result)\n") }
                        var objToMigrateID = 0
                        // clear targetDataArray - needed to handle switching tabs
                        self.targetDataArray.removeAll()
                        
                        DispatchQueue.main.async {
                            // create targetDataArray, list of objects to migrate/remove - start
                            for k in (0..<self.sourceDataArray.count) {
                                if self.srcSrvTableView.isRowSelected(k) {
                                    // prevent the removal of the account we're using
                                    if !(selectedEndpoint == "jamfusers" && self.sourceDataArray[k].lowercased() == self.dest_user.lowercased()) {
                                        self.targetDataArray.append(self.sourceDataArray[k])
                                    }
                                }   // if self.srcSrvTableView.isRowSelected(k) - end
                            }   // for k in - end
                            // create targetDataArray, list of objects to migrate/remove - end
                        
                            if self.targetDataArray.count == 0 {
                                if LogLevel.debug { WriteToLog().message(stringOfText: "nothing selected to migrate/remove.\n") }
                                self.alert_dialog(header: "Alert:", message: "Nothing was selected.")
                                self.goButtonEnabled(button_status: true)
                                return
                            }
                            
                            // Used if we remove items from the list as they are removed from the server
                            if wipeData.on {
                                self.availableIdsToDelArray.removeAll()
                                for k in (0..<self.sourceDataArray.count) {
                                    self.availableIdsToDelArray.append(self.availableIDsToMigDict[self.sourceDataArray[k]]!)
                                }
//                                        print("availableIdsToDelArray: \(self.availableIdsToDelArray)")
                            }
                        
                            if LogLevel.debug { WriteToLog().message(stringOfText: "Item(s) chosen from selective: \(self.targetDataArray)\n") }
                            var advancedMigrateDict = [String:[String:String]]()    // dictionary of dependencies for the object we're migrating - category:dictionary of dependencies
                            
                            for j in (0..<self.targetDataArray.count) {
                                let primaryObjToMigrateID = self.availableIDsToMigDict[self.targetDataArray[j]]!
                                // why use the above?
//                                let objToMigrateID        = self.availableIDsToMigDict[self.targetDataArray[j]]!
                                
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
                                    default:
                                        rawEndpoint = selectedEndpoint
                                }
                                
                                Json().getRecord(theServer: self.source_jp_server, base64Creds: self.sourceBase64Creds, theEndpoint: "\(rawEndpoint)/\(idPath)\(primaryObjToMigrateID)")  {
                                    (result: [String:AnyObject]) in
                                    if LogLevel.debug { WriteToLog().message(stringOfText: "Returned from Json.getRecord: \(result)\n") }
                                    if selectedEndpoint == "policies" && self.migrateDependencies.state.rawValue == 1 {
                                        advancedMigrateDict = self.getDependencies(object: "policy", json: result)
//                                        print("[ViewController] advancedMigrateDict: \(advancedMigrateDict)")
                                    } else {
                                        advancedMigrateDict = [:]
                                    }
//                                    switch selectedEndpoint {
//                                    case "policies":
//                                        advancedMigrateDict = self.getDependencies(object: "policy", json: result)
//                                        print("[ViewController] advancedMigrateDict: \(advancedMigrateDict)")
//                                    default:
//                                        advancedMigrateDict = [:]
//                                    }
                                    let objToMigrateID = self.availableIDsToMigDict[self.targetDataArray[j]]!

                                    if !wipeData.on  {
                                        if let selectedObject = self.availableObjsToMigDict[objToMigrateID] {
                                            if selectedEndpoint == "policies" && self.migrateDependencies.state.rawValue == 1 {
                                                // migrate dependencies - start
                                                let full_ordered_dependency_array = self.ordered_dependency_array + ["policies"]
                                                advancedMigrateDict["policies"] = [String:String]()
                                                advancedMigrateDict["policies"]![selectedObject] = "\(objToMigrateID)"  //[name of policy:id of policy]
//                                                print("advancedMigrateDict: \(advancedMigrateDict)")


                                                dependency.wait = false
                                                var objectIndex = 0
                                                self.destEPQ.async {
                                                while true {
//                                                for object in full_ordered_dependency_array {
                                                    if !dependency.wait {
//                                                        print("check item \(objectIndex+1) of \(full_ordered_dependency_array.count)")
                                                        if objectIndex >= full_ordered_dependency_array.count { break }
//                                                        print("[ViewController.startMigrating] set dependency.wait = true")
                                                        dependency.wait = true

                                                        let object = full_ordered_dependency_array[objectIndex]
                                                        objectIndex+=1
//                                                        print("object: \(object)")
    //                                                    print("advancedMigrateDict[\(object)]: \(String(describing: advancedMigrateDict[object]!))")

                                                        let dependencyCount = advancedMigrateDict[object]!.count
                                                        if dependencyCount > 0 {
                                                            var dependencyCounter = 0
                                                            
//                                                            print("advancedMigrateDict[\(object)]: \(String(describing: advancedMigrateDict[object]!))")
                                                            
                                                            for (name, id) in advancedMigrateDict[object]! {
//                                                                print("object name: \(String(describing: name))")
                                                                dependencyCounter += 1
                                                                if LogLevel.debug && !self.saveOnly { WriteToLog().message(stringOfText: "check for existing object: \(name)\n") }
    //                                                            print("self.saveOnly: \(self.saveOnly)")
    //                                                            print("object: \(object) - name: \(name)")
//                                                                print("create or update \(object): \(name)")
                                                                if nil != self.currentEPDict[object]![name] && !self.saveOnly {
                                                                    if LogLevel.debug { WriteToLog().message(stringOfText: "\(object): \(name) already exists\n") }
                                                                    //self.currentEndpointID = self.currentEPs[xmlName]!
                                                                    self.endPointByID(endpoint: object, endpointID: Int(id)!, endpointCurrent: dependencyCounter, endpointCount: dependencyCount, action: "update", destEpId: Int(self.currentEPDict[object]![name]!), destEpName: selectedObject)
                                                                } else {
                                                                    self.endPointByID(endpoint: object, endpointID: Int(id)!, endpointCurrent: dependencyCounter, endpointCount: dependencyCount, action: "create", destEpId: 0, destEpName: selectedObject)
                                                                }
                                                            }   // for (name, id) in advancedMigrateDict[object]! - end
                                                                
                                                        } else {   // if dependencyCount - end
                                                            // object had no dependencies
                                                            dependency.wait = false
                                                        }
                                                    } else {  // for object in full_ordered_dependency_array - end
                                                        sleep(1)
                                                    }
                                                }   // while true - end
                                                }
                                                
                                                
                                                // migrate dependencies - end
                                                
                                            } else {
                                            
                                                if LogLevel.debug && !self.saveOnly { WriteToLog().message(stringOfText: "check for existing object: \(selectedObject)\n") }
                                                if nil != self.currentEPs[self.availableObjsToMigDict[objToMigrateID]!] && !self.saveOnly {
                                                    if LogLevel.debug { WriteToLog().message(stringOfText: "\(selectedObject) already exists\n") }
                                                    //self.currentEndpointID = self.currentEPs[xmlName]!
                                                    self.endPointByID(endpoint: selectedEndpoint, endpointID: objToMigrateID, endpointCurrent: (j+1), endpointCount: self.targetDataArray.count, action: "update", destEpId: self.currentEPs[self.availableObjsToMigDict[objToMigrateID]!]!, destEpName: selectedObject)
                                                } else {
                                                    self.endPointByID(endpoint: selectedEndpoint, endpointID: objToMigrateID, endpointCurrent: (j+1), endpointCount: self.targetDataArray.count, action: "create", destEpId: 0, destEpName: selectedObject)
                                                }
                                            }
                                        }
                                    } else {
                                        // selective removal
                                        if LogLevel.debug { WriteToLog().message(stringOfText: "remove - endpoint: \(self.targetDataArray[j])\t endpointID: \(objToMigrateID)\t endpointName: \(self.targetDataArray[j])\n") }
                                        
                                        self.RemoveEndpoints(endpointType: selectedEndpoint, endPointID: objToMigrateID, endpointName: self.targetDataArray[j], endpointCurrent: (j+1), endpointCount: self.targetDataArray.count)
                                        
                                    }   // if !wipeData.on else - end
                                    
                                }   // Json().getRecord - end
                                
                            }   // for j in  - end
                            
                        }   // DispatchQueue.main.async - end
                    }
                }   //for i in - else - end
            // **************************************** selective migration - end ****************************************
            }   // self.readFiles.async - end
        }   //DispatchQueue.main.async - end
    }   // func startMigrating - end
    
    
    func readNodes(nodesToMigrate: [String], nodeIndex: Int) {
        
        if LogLevel.debug { WriteToLog().message(stringOfText: "[readNodes] enter\n") }
        
//        print("nodesToMigrate: \(nodesToMigrate[nodeIndex])")
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
        if LogLevel.debug { WriteToLog().message(stringOfText: "getting endpoint: \(nodesToMigrate[nodeIndex])\n") }
        if self.fileImport {
            self.readDataFiles(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex) {
                (result: String) in
                if LogLevel.debug { WriteToLog().message(stringOfText: "processFiles result: \(result)\n") }
            }
        } else {
            self.getEndpoints(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex)  {
                (result: [String]) in
                if LogLevel.debug { WriteToLog().message(stringOfText: "getEndpoints result: \(result)\n") }
            }
        }
        
        if LogLevel.debug { WriteToLog().message(stringOfText: "[readNodes] exit\n") }
    }
    
    
    func getEndpoints(nodesToMigrate: [String], nodeIndex: Int, completion: @escaping (_ result: [String]) -> Void) {
        
        if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] enter\n") }
        
        URLCache.shared.removeAllCachedResponses()
        var endpoint       = nodesToMigrate[nodeIndex]
        var endpointParent = ""
        var node           = ""
        var endpointCount  = 0
        var groupType      = ""
        if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] Getting \(endpoint)\n") }
        
        
        if endpoint.contains("smart") {
            groupType = "smart"
        } else if endpoint.contains("static") {
            groupType = "static"
        }
        
        switch endpoint {
        // macOS items
        case "advancedcomputersearches":
            endpointParent = "advanced_computer_searches"
        case "computerconfigurations":
            endpointParent = "computer_configurations"
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
        case "netbootservers":
            endpointParent = "netboot_servers"
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
                
        (endpoint == "jamfusers" || endpoint == "jamfgroups") ? (node = "accounts"):(node = endpoint)
        var myURL = "\(self.source_jp_server)/JSSResource/\(node)"
        myURL = myURL.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
        
        concurrentThreads = (concurrentThreads > 5) ? 3:concurrentThreads
        theOpQ.maxConcurrentOperationCount = concurrentThreads
        let semaphore = DispatchSemaphore(value: 0)
        
        DispatchQueue.main.async {
            self.srcSrvTableView.isEnabled = true
        }
        self.sourceDataArray.removeAll()
        self.availableIDsToMigDict.removeAll()
        
        theOpQ.addOperation {
            
            let encodedURL = NSURL(string: myURL)
            let request = NSMutableURLRequest(url: encodedURL! as URL)
            request.httpMethod = "GET"
            let configuration = URLSessionConfiguration.default
            configuration.httpAdditionalHeaders = ["Authorization" : "Basic \(self.sourceBase64Creds)", "Content-Type" : "application/json", "Accept" : "application/json"]
            let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
            let task = session.dataTask(with: request as URLRequest, completionHandler: {
                (data, response, error) -> Void in
                if let httpResponse = response as? HTTPURLResponse {
//                    print("httpResponse: \(httpResponse.statusCode)")
                    
                    do {
                        if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] Getting all endpoints from: \(myURL)\n") }
                        let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                        if let endpointJSON = json as? [String: Any] {
                            if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] endpointJSON: \(endpointJSON))\n") }
                            
                            switch endpoint {
                            case "advancedcomputersearches", "macapplications", "buildings", "categories", "computers", "computerextensionattributes", "departments", "distributionpoints", "directorybindings", "diskencryptionconfigurations", "dockitems", "ldapservers", "netbootservers", "networksegments", "osxconfigurationprofiles", "packages", "patchpolicies", "printers", "scripts", "sites", "softwareupdateservers", "users", "mobiledeviceconfigurationprofiles", "mobiledeviceapplications", "advancedmobiledevicesearches", "mobiledeviceextensionattributes", "mobiledevices", "userextensionattributes", "advancedusersearches", "restrictedsoftware":
                                if let endpointInfo = endpointJSON[endpointParent] as? [Any] {
                                    endpointCount = endpointInfo.count
                                    if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] Initial count for \(endpoint) found: \(endpointCount)\n") }
                                    
                                    if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] Verify empty dictionary of objects - availableObjsToMigDict count: \(self.availableObjsToMigDict.count)\n") }
                                    
                                    if endpointCount > 0 {
                                        
                                        self.existingEndpoints(theDestEndpoint: "\(endpoint)")  {
                                            (result: String) in
                                            if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] Returned from existing \(endpoint): \(result)\n") }
                                            
                                            for i in (0..<endpointCount) {
                                                if i == 0 { self.availableObjsToMigDict.removeAll() }
                                                
                                                let record = endpointInfo[i] as! [String : AnyObject]
                                                
//                                                if endpoint != "mobiledeviceapplications" {
                                                    if record["name"] != nil {
                                                        self.availableObjsToMigDict[record["id"] as! Int] = record["name"] as! String?
                                                    } else {
                                                        self.availableObjsToMigDict[record["id"] as! Int] = ""
                                                    }
//                                                } else {
//                                                        self.availableObjsToMigDict[record["id"] as! Int] = record["bundle_id"] as! String?
//                                                }
                                            
                                                if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] Current number of \(endpoint) to process: \(self.availableObjsToMigDict.count)\n") }
                                            }   // for i in (0..<endpointCount) end
                                            if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] Found total of \(self.availableObjsToMigDict.count) \(endpoint) to process\n") }
                                            
                                            var counter = 1
                                            if self.goSender == "goButton" {
                                                for (l_xmlID, l_xmlName) in self.availableObjsToMigDict {
                                                    if !wipeData.on  {
                                                        if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] check for ID on \(l_xmlName): \(self.currentEPs[l_xmlName] ?? 0)\n") }
//                                                        if self.currentEPs[l_xmlName] != nil {
                                                        if self.currentEPDict[endpoint]?[l_xmlName] != nil {
                                                            if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] \(l_xmlName) already exists\n") }
//                                                            self.endPointByID(endpoint: endpoint, endpointID: l_xmlID, endpointCurrent: counter, endpointCount: self.availableObjsToMigDict.count, action: "update", destEpId: self.currentEPs[l_xmlName]!, destEpName: l_xmlName)
                                                            self.endPointByID(endpoint: endpoint, endpointID: l_xmlID, endpointCurrent: counter, endpointCount: self.availableObjsToMigDict.count, action: "update", destEpId: self.currentEPDict[endpoint]![l_xmlName]!, destEpName: l_xmlName)
                                                        } else {
                                                            if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] \(l_xmlName) - create\n") }
                                                            if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] function - endpoint: \(endpoint), endpointID: \(l_xmlID), endpointCurrent: \(counter), endpointCount: \(endpointCount), action: \"create\", destEpId: 0\n") }
                                                            self.endPointByID(endpoint: endpoint, endpointID: l_xmlID, endpointCurrent: counter, endpointCount: self.availableObjsToMigDict.count, action: "create", destEpId: 0, destEpName: l_xmlName)
                                                        }
                                                    } else {
                                                        if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] remove - endpoint: \(endpoint)\t endpointID: \(l_xmlID)\t endpointName: \(l_xmlName)\n") }
                                                        self.RemoveEndpoints(endpointType: endpoint, endPointID: l_xmlID, endpointName: l_xmlName, endpointCurrent: counter, endpointCount: self.availableObjsToMigDict.count)
                                                    }   // if !wipeData.on else - end
                                                    counter+=1
                                                }   // for (l_xmlID, l_xmlName) in availableObjsToMigDict
                                            } else {
                                                // populate source server under the selective tab
                                                self.delayInt = self.listDelay(itemCount: self.availableObjsToMigDict.count)
                                                for (l_xmlID, l_xmlName) in self.availableObjsToMigDict {
                                                    self.sortQ.async {
                                                        //print("adding \(l_xmlName) to array")
                                                        self.availableIDsToMigDict[l_xmlName] = l_xmlID
                                                        self.sourceDataArray.append(l_xmlName)
//                                                        if self.availableIDsToMigDict.count == self.sourceDataArray.count {
                                                            self.sourceDataArray = self.sourceDataArray.sorted{$0.localizedCaseInsensitiveCompare($1) == .orderedAscending}
                                                            DispatchQueue.main.async {
                                                                self.srcSrvTableView.reloadData()
                                                            }
                                                        // slight delay in building the list - visual effect
                                                        usleep(self.delayInt)
//                                                            self.goButtonEnabled(button_status: true)
//                                                        }   //if self.availableIDsToMigDict.count - end
//                                                        DispatchQueue.main.async {
//                                                            self.srcSrvTableView.reloadData()
//                                                        }
                                                        if counter == self.availableObjsToMigDict.count {
                                                            self.goButtonEnabled(button_status: true)
                                                        }
                                                        counter+=1
                                                    }   // self.sortQ.async - end
                                                }   // for (l_xmlID, l_xmlName) in availableObjsToMigDict
                                                
                                            }   // if self.goSender else - end
                                        }   // self.existingEndpoints - end
                                    } else {
                                        self.nodesMigrated+=1    // ;print("added node: \(endpoint) - getEndpoints1")
                                        if endpoint == self.objectsToMigrate.last {
                                            self.rmDELETE()
                                            self.resetAllCheckboxes()
//                                            self.goButtonEnabled(button_status: true)
//                                            completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                                        }
                                    }// if endpointCount > 0 - end
                                    if nodeIndex < nodesToMigrate.count - 1 {
                                        self.readNodes(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1)
                                    }
                                    completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                                } else {   // end if let buildings, departments...
                                    if nodeIndex < nodesToMigrate.count - 1 {
                                        self.readNodes(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1)
                                    }
                                    completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                                }
                                
                            case "computergroups", "mobiledevicegroups", "usergroups":
                                if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] processing device groups\n") }
                                if let endpointInfo = endpointJSON[self.endpointDefDict["\(endpoint)"]!] as? [Any] {
                                    
                                    endpointCount = endpointInfo.count
                                    if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] groups found: \(endpointCount)\n") }
                                    
                                    var smartGroupDict: [Int: String] = [:]
                                    var staticGroupDict: [Int: String] = [:]
                                                                        
                                    if endpointCount > 0 {
                                        self.existingEndpoints(theDestEndpoint: "\(endpoint)")  {
                                            (result: String) in
                                            // find number of groups
                                            self.smartCount = 0
                                            self.staticCount = 0
                                            var excludeCount = 0
                                            // split computergroups into smart and static - start
                                            for i in (0..<endpointCount) {
                                                let record = endpointInfo[i] as! [String : AnyObject]
                                                
                                                let smart: Bool = (record["is_smart"] as! Bool)
                                                if smart {
                                                    //self.smartCount += 1
                                                    if record["name"] as! String? != "All Managed Clients" && record["name"] as! String? != "All Managed Servers" && record["name"] as! String? != "All Managed iPads" && record["name"] as! String? != "All Managed iPhones" && record["name"] as! String? != "All Managed iPod touches" {
                                                        smartGroupDict[record["id"] as! Int] = record["name"] as! String?
                                                    }
                                                } else {
                                                    //self.staticCount += 1
                                                    staticGroupDict[record["id"] as! Int] = record["name"] as! String?
                                                }
                                            }
                                            
                                            if (smartGroupDict.count == 0 || staticGroupDict.count == 0) && !(smartGroupDict.count == 0 && staticGroupDict.count == 0) {
                                                self.nodesMigrated+=1
                                            }
                                            
                                            // split devicegroups into smart and static - end
                                            switch endpoint {
                                            case "computergroups":
                                                if (self.smart_comp_grps_button.state.rawValue == 0 && groupType == "") || groupType == "static" {
                                                    excludeCount += smartGroupDict.count
                                                }
                                                if (self.static_comp_grps_button.state.rawValue == 0 && groupType == "") || groupType == "smart" {
                                                    excludeCount += staticGroupDict.count
                                                }
                                                if self.smart_comp_grps_button.state.rawValue == 1 && self.static_comp_grps_button.state.rawValue == 1 && groupType == "" {
                                                    self.nodesMigrated-=1
                                                }
                                            case "mobiledevicegroups":
                                                if (self.smart_ios_groups_button.state.rawValue == 0 && groupType == "") || groupType == "static" {
                                                    excludeCount += smartGroupDict.count
                                                }
                                                if (self.static_ios_groups_button.state.rawValue == 0 && groupType == "") || groupType == "smart" {
                                                    excludeCount += staticGroupDict.count
                                                }
                                                if self.smart_ios_groups_button.state.rawValue == 1 && self.static_ios_groups_button.state.rawValue == 1 {
                                                    self.nodesMigrated-=1
                                                }
                                            case "usergroups":
                                                if (self.smartUserGrps_button.state.rawValue == 0 && groupType == "") || groupType == "static" {
                                                    excludeCount += smartGroupDict.count
                                                }
                                                if (self.staticUserGrps_button.state.rawValue == 0 && groupType == "") || groupType == "smart" {
                                                    excludeCount += staticGroupDict.count
                                                }
                                                if self.smartUserGrps_button.state.rawValue == 1 && self.staticUserGrps_button.state.rawValue == 1 && groupType == "" {
                                                    self.nodesMigrated-=1
                                                }
                                                
                                            default: break
                                            }
                                            
                                            
                                            if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] \(smartGroupDict.count) smart groups\n") }
                                            if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] \(staticGroupDict.count) static groups\n") }
                                            var currentGroupDict: [Int: String] = [:]
                                            // verify we have some groups
                                            for g in (0...1) {
                                                currentGroupDict.removeAll()
                                                var groupCount = 0
                                                var localEndpoint = endpoint
                                                switch endpoint {
                                                case "computergroups":
                                                    if ((self.smart_comp_grps_button.state.rawValue == 1) || (self.goSender != "goButton" && groupType == "smart")) && (g == 0) {
                                                        currentGroupDict = smartGroupDict
                                                        groupCount = currentGroupDict.count
//                                                        self.DeviceGroupType = "smartcomputergroups"
//                                                        print("computergroups smart - DeviceGroupType: \(self.DeviceGroupType)")
                                                        localEndpoint = "smartcomputergroups"
                                                    }
                                                    if ((self.static_comp_grps_button.state.rawValue == 1) || (self.goSender != "goButton" && groupType == "static")) && (g == 1) {
                                                        currentGroupDict = staticGroupDict
                                                        groupCount = currentGroupDict.count
//                                                        self.DeviceGroupType = "staticcomputergroups"
//                                                        print("computergroups static - DeviceGroupType: \(self.DeviceGroupType)")
                                                        localEndpoint = "staticcomputergroups"
                                                    }
                                                case "mobiledevicegroups":
                                                    if ((self.smart_ios_groups_button.state.rawValue == 1) || (self.goSender != "goButton" && groupType == "smart")) && (g == 0) {
                                                        currentGroupDict = smartGroupDict
                                                        groupCount = currentGroupDict.count
//                                                        self.DeviceGroupType = "smartcomputergroups"
//                                                        print("devicegroups smart - DeviceGroupType: \(self.DeviceGroupType)")
                                                        localEndpoint = "smartmobiledevicegroups"
                                                    }
                                                    if ((self.static_ios_groups_button.state.rawValue == 1) || (self.goSender != "goButton" && groupType == "static")) && (g == 1) {
                                                        currentGroupDict = staticGroupDict
                                                        groupCount = currentGroupDict.count
//                                                        self.DeviceGroupType = "staticcomputergroups"
//                                                        print("devicegroups static - DeviceGroupType: \(self.DeviceGroupType)")
                                                        localEndpoint = "staticmobiledevicegroups"
                                                    }
                                                case "usergroups":
                                                    if ((self.smartUserGrps_button.state.rawValue == 1) || (self.goSender != "goButton" && groupType == "smart")) && (g == 0) {
                                                        currentGroupDict = smartGroupDict
                                                        groupCount = currentGroupDict.count
//                                                        self.DeviceGroupType = "smartcomputergroups"
//                                                        print("usergroups smart - DeviceGroupType: \(self.DeviceGroupType)")
                                                        localEndpoint = "smartusergroups"
                                                    }
                                                    if ((self.staticUserGrps_button.state.rawValue == 1) || (self.goSender != "goButton" && groupType == "static")) && (g == 1) {
                                                        currentGroupDict = staticGroupDict
                                                        groupCount = currentGroupDict.count
//                                                        self.DeviceGroupType = "staticcomputergroups"
//                                                        print("usergroups static - DeviceGroupType: \(self.DeviceGroupType)")
                                                        localEndpoint = "staticusergroups"
                                                    }
                                                default: break
                                                }
                                                var counter = 1
                                                self.delayInt = self.listDelay(itemCount: currentGroupDict.count)
                                                for (l_xmlID, l_xmlName) in currentGroupDict {
                                                    self.availableObjsToMigDict[l_xmlID] = l_xmlName
                                                    if self.goSender == "goButton" {
                                                        if !wipeData.on  {
                                                            
                                                            //need to call existingEndpoints here to keep proper order?
                                                            if self.currentEPs[l_xmlName] != nil {
                                                                if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] \(l_xmlName) already exists\n") }
                                                                self.endPointByID(endpoint: localEndpoint, endpointID: l_xmlID, endpointCurrent: counter, endpointCount: groupCount, action: "update", destEpId: self.currentEPs[l_xmlName]!, destEpName: l_xmlName)
                                                            } else {
                                                                if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] \(l_xmlName) - create\n") }
                                                                if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] function - endpoint: \(localEndpoint), endpointID: \(l_xmlID), endpointCurrent: \(counter), endpointCount: \(groupCount), action: \"create\", destEpId: 0\n") }
                                                                self.endPointByID(endpoint: localEndpoint, endpointID: l_xmlID, endpointCurrent: counter, endpointCount: groupCount, action: "create", destEpId: 0, destEpName: l_xmlName)
                                                            }
                                                            
                                                        } else {
                                                            
                                                            self.RemoveEndpoints(endpointType: localEndpoint, endPointID: l_xmlID, endpointName: l_xmlName, endpointCurrent: counter, endpointCount: groupCount)
                                                        }   // if !wipeData.on else - end
                                                        counter += 1
                                                    } else {
                                                        // populate source server under the selective tab
                                                        self.sortQ.async {
//                                                            print("adding \(l_xmlName) to array")
                                                            self.availableIDsToMigDict[l_xmlName] = l_xmlID
                                                            self.sourceDataArray.append(l_xmlName)
                                                            self.sourceDataArray = self.sourceDataArray.sorted{$0.localizedCaseInsensitiveCompare($1) == .orderedAscending}

                                                            DispatchQueue.main.async {
                                                                self.srcSrvTableView.reloadData()
                                                            }
                                                            // slight delay in building the list - visual effect
                                                            usleep(self.delayInt)
                                                            
                                                            if counter == self.sourceDataArray.count {
                                                                self.goButtonEnabled(button_status: true)
                                                            }

                                                            counter += 1
                                                        }   // self.sortQ.async - end
                                                    }   // if self.goSender else - end
                                                    
                                                }   // for (l_xmlID, l_xmlName) - end
                                                
                                                self.nodesMigrated+=1
                                                
                                            }   //for g in (0...1) - end
                                        }   // self.existingEndpoints(theDestEndpoint: "\(endpoint)") - end
                                    } else {    //if endpointCount > 0 - end
                                        self.nodesMigrated+=1    // ;print("added node: \(endpoint) - getEndpoints2")
                                        if endpoint == self.objectsToMigrate.last {
                                            if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] Reached last object to migrate: \(endpoint)\n") }
                                            self.rmDELETE()
                                            self.resetAllCheckboxes()
//                                            self.goButtonEnabled(button_status: true)
                                            completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                                        }
                                    }   // else if endpointCount > 0 - end
                                    if nodeIndex < nodesToMigrate.count - 1 {
                                        self.readNodes(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1)
                                    }
                                    
                                    // commented out lnh 200123
//                                    if endpoint == self.objectsToMigrate.last {
//                                        if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] Reached last object to migrate: \(endpoint)\n") }
//                                        self.rmDELETE()
//                                        print("[getEndpoints] endpoint: \(endpoint)")
//                                        self.resetAllCheckboxes()
//                                    }
                                    
                                    completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                                } else {  // if let endpointInfo = endpointJSON["computer_groups"] - end
                                    if nodeIndex < nodesToMigrate.count - 1 {
                                        self.readNodes(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1)
                                    }
                                    completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                                }
                                
                            case "policies":
                                if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] processing \(endpoint)\n") }
                                if let endpointInfo = endpointJSON[endpoint] as? [Any] {
                                    endpointCount = endpointInfo.count
                                    
                                    if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] \(endpoint) found: \(endpointCount)\n") }
                                    
                                    var computerPoliciesDict: [Int: String] = [:]

                                    if endpointCount > 0 {
                                        // display migrateDependencies button
                                        DispatchQueue.main.async {
                                            self.migrateDependencies.isHidden = false
                                        }
                                        
                                        // create dictionary of existing policies
                                        self.existingEndpoints(theDestEndpoint: "policies")  {
                                            (result: String) in
                                            if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] Returned from existing endpoints: \(result)\n") }
                                            
                                            // filter out policies created from casper remote - start
                                            for i in (0..<endpointCount) {
                                                let record = endpointInfo[i] as! [String : AnyObject]
                                                let nameCheck = record["name"] as! String
                                                if nameCheck.range(of:"[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] at", options: .regularExpression) == nil && nameCheck != "Update Inventory" {
                                                    computerPoliciesDict[record["id"] as! Int] = nameCheck
                                                }
                                            }
                                            // filter out policies created from casper remote - end
                                            
                                            self.availableObjsToMigDict = computerPoliciesDict
                                            let nonRemotePolicies = computerPoliciesDict.count
                                            var counter = 1
                                            
                                            self.delayInt = self.listDelay(itemCount: computerPoliciesDict.count)
                                            for (l_xmlID, l_xmlName) in computerPoliciesDict {
                                                if self.goSender == "goButton" {
                                                    if !wipeData.on  {
                                                        if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] check for ID on \(l_xmlName): \(String(describing: self.currentEPs[l_xmlName]))\n") }
//                                                        if self.currentEPs[l_xmlName] != nil {
                                                        if self.currentEPDict[endpoint]?[l_xmlName] != nil {
                                                            if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] \(l_xmlName) already exists\n") }
//                                                            self.endPointByID(endpoint: endpoint, endpointID: l_xmlID, endpointCurrent: counter, endpointCount: nonRemotePolicies, action: "update", destEpId: self.currentEPs[l_xmlName]!, destEpName: l_xmlName)
                                                            self.endPointByID(endpoint: endpoint, endpointID: l_xmlID, endpointCurrent: counter, endpointCount: nonRemotePolicies, action: "update", destEpId: self.currentEPDict[endpoint]![l_xmlName]!, destEpName: l_xmlName)
                                                        } else {
                                                            if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] \(l_xmlName) - create\n") }
                                                            if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] function - endpoint: \(endpoint), endpointID: \(l_xmlID), endpointCurrent: \(counter), endpointCount: \(endpointCount), action: \"create\", destEpId: 0\n") }
                                                            self.endPointByID(endpoint: endpoint, endpointID: l_xmlID, endpointCurrent: counter, endpointCount: nonRemotePolicies, action: "create", destEpId: 0, destEpName: l_xmlName)
                                                        }
                                                    } else {
                                                        if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] remove - endpoint: \(endpoint)\t endpointID: \(l_xmlID)\t endpointName: \(l_xmlName)\n") }
                                                        self.RemoveEndpoints(endpointType: endpoint, endPointID: l_xmlID, endpointName: l_xmlName, endpointCurrent: counter, endpointCount: nonRemotePolicies)
                                                    }   // if !wipeData.on else - end
                                                    counter += 1
                                                } else {
                                                    // populate source server under the selective tab
//                                                        print("adding \(l_xmlName) to array")
//                                                    if self.sourceDataArray.count == computerPoliciesDict.count {
//                                                        if self.availableIDsToMigDict.count == computerPoliciesDict.count {
                                                        self.sortQ.async {
                                                            self.availableIDsToMigDict[l_xmlName+" (\(l_xmlID))"] = l_xmlID
                                                            self.sourceDataArray.append(l_xmlName+" (\(l_xmlID))")
                                                            self.sourceDataArray = self.sourceDataArray.sorted{$0.localizedCaseInsensitiveCompare($1) == .orderedAscending}
                                                            DispatchQueue.main.async {
                                                                self.srcSrvTableView.reloadData()
                                                            }
                                                            // slight delay in building the list - visual effect
                                                            usleep(self.delayInt)

                                                            if counter == computerPoliciesDict.count {
                                                                self.goButtonEnabled(button_status: true)
                                                            }
                                                            counter+=1
                                                        }   // self.sortQ.async - end
                                                    
                                                }   // if self.goSender else - end
                                            }   // for (l_xmlID, l_xmlName) in computerPoliciesDict - end
                                        }   // self.existingEndpoints - end
                                    } else {
                                        self.nodesMigrated+=1
                                        if endpoint == self.objectsToMigrate.last {
                                            if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] Reached last object to migrate: \(endpoint)\n") }
                                            self.rmDELETE()
                                            self.resetAllCheckboxes()
//                                            print("rmDelete 1")
//                                            self.goButtonEnabled(button_status: true)
                                            completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                                        }
                                    }   // if endpointCount > 0
                                    if nodeIndex < nodesToMigrate.count - 1 {
                                        self.readNodes(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1)
                                    }
//                                    self.nodesMigrated+=1
//                                    if endpoint == self.objectsToMigrate.last {
//                                        if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] Reached last object to migrate: \(endpoint)\n") }
//                                        self.rmDELETE()
//                                        print("rmDelete 2")
//                                    }
                                    completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                                } else {   //if let endpointInfo = endpointJSON - end
                                    if nodeIndex < nodesToMigrate.count - 1 {
                                        self.readNodes(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1)
                                    }
                                    completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                                }
                                
                            case "jamfusers", "jamfgroups":
                                let accountsDict = endpointJSON as Dictionary<String, Any>
                                let usersGroups = accountsDict["accounts"] as! Dictionary<String, Any>
                                
                                if let endpointInfo = usersGroups[endpointParent] as? [Any] {
                                    endpointCount = endpointInfo.count
                                    if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] Initial count for \(node) found: \(endpointCount)\n") }
                                    
                                    if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] Verify empty dictionary of objects - availableObjsToMigDict count: \(self.availableObjsToMigDict.count)\n") }
                                    
                                    if endpointCount > 0 {
                                        
//                                        self.existingEndpoints(theDestEndpoint: "accounts")  {
                                        self.existingEndpoints(theDestEndpoint: "ldapservers")  {
                                            (result: String) in
                                            if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints-LDAP] Returned from existing ldapservers: \(result)\n") }
                                            
                                            self.existingEndpoints(theDestEndpoint: endpoint)  {
                                                (result: String) in
                                                if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] Returned from existing \(node): \(result)\n") }
                                            
                                                for i in (0..<endpointCount) {
                                                    if i == 0 { self.availableObjsToMigDict.removeAll() }
                                                    
                                                    let record = endpointInfo[i] as! [String : AnyObject]
                                                    if !(endpoint == "jamfusers" && record["name"] as! String? == self.dest_user) {
                                                        self.availableObjsToMigDict[record["id"] as! Int] = record["name"] as! String?
                                                    }
                                                    
                                                    if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] Current number of \(endpoint) to process: \(self.availableObjsToMigDict.count)\n") }
                                                }   // for i in (0..<endpointCount) end
                                                if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] Found total of \(self.availableObjsToMigDict.count) \(endpoint) to process\n") }
                                                
                                                var counter = 1
                                                if self.goSender == "goButton" {
                                                    for (l_xmlID, l_xmlName) in self.availableObjsToMigDict {
                                                        if !wipeData.on  {
                                                            if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] check for ID on \(l_xmlName): \(String(describing: self.currentEPs[l_xmlName]))\n") }
                                                            
                                                            if self.currentEPs[l_xmlName] != nil {
                                                                if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] \(l_xmlName) already exists\n") }
                                                                //self.currentEndpointID = self.currentEPs[l_xmlName]!
                                                                self.endPointByID(endpoint: endpoint, endpointID: l_xmlID, endpointCurrent: counter, endpointCount: self.availableObjsToMigDict.count, action: "update", destEpId: self.currentEPs[l_xmlName]!, destEpName: l_xmlName)
                                                            } else {
                                                                if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] \(l_xmlName) - create\n") }
                                                                if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] function - endpoint: \(endpoint), endpointID: \(l_xmlID), endpointCurrent: \(counter), endpointCount: \(endpointCount), action: \"create\", destEpId: 0\n") }
                                                                self.endPointByID(endpoint: endpoint, endpointID: l_xmlID, endpointCurrent: counter, endpointCount: self.availableObjsToMigDict.count, action: "create", destEpId: 0, destEpName: l_xmlName)
                                                            }
                                                        } else {
                                                            if !(endpoint == "jamfusers" && "\(l_xmlName)".lowercased() == self.dest_user.lowercased()) {
                                                                if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] remove - endpoint: \(endpoint)\t endpointID: \(l_xmlID)\t endpointName: \(l_xmlName)\n") }
                                                                self.RemoveEndpoints(endpointType: endpoint, endPointID: l_xmlID, endpointName: l_xmlName, endpointCurrent: counter, endpointCount: self.availableObjsToMigDict.count)
                                                            }
                                                            
                                                        }   // if !wipeData.on else - end
                                                        counter+=1
                                                    }   // for (l_xmlID, l_xmlName) in availableObjsToMigDict
                                                } else {
                                                    // populate source server under the selective tab
                                                    self.delayInt = self.listDelay(itemCount: self.availableObjsToMigDict.count)
                                                    for (l_xmlID, l_xmlName) in self.availableObjsToMigDict {
                                                        self.sortQ.async {
                                                            //print("adding \(l_xmlName) to array")
                                                            self.availableIDsToMigDict[l_xmlName] = l_xmlID
                                                            self.sourceDataArray.append(l_xmlName)

                                                            self.sourceDataArray = self.sourceDataArray.sorted{$0.localizedCaseInsensitiveCompare($1) == .orderedAscending}
                                                            DispatchQueue.main.async {
                                                                self.srcSrvTableView.reloadData()
                                                            }
                                                            // slight delay in building the list - visual effect
                                                            usleep(self.delayInt)
                                                            
                                                            if counter == self.availableObjsToMigDict.count {
                                                                self.goButtonEnabled(button_status: true)
                                                            }
                                                            counter+=1
                                                        }   // self.sortQ.async - end
                                                    }   // for (l_xmlID, l_xmlName) in availableObjsToMigDict
                                                }   // if self.goSender else - end
                                            }   // self.existingEndpoints - end

                                            
                                        }
                                        
                                    } else {
                                        self.nodesMigrated+=1    // ;print("added node: \(endpoint) - getEndpoints4")
                                        if endpoint == self.objectsToMigrate.last {
                                            self.rmDELETE()
                                            self.resetAllCheckboxes()
//                                            self.goButtonEnabled(button_status: true)
                                            completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                                        }
                                    }   // if endpointCount > 0 - end
                                    if nodeIndex < nodesToMigrate.count - 1 {
                                        self.readNodes(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1)
                                    }
                                    completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                                } else {   // end if let buildings, departments...
                                    if nodeIndex < nodesToMigrate.count - 1 {
                                        self.readNodes(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1)
                                    }
                                    completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                                }
                              
                            case "computerconfigurations":
                                if let endpointInfo = endpointJSON[self.endpointDefDict[endpoint]!] as? [Any] {
                                    endpointCount = endpointInfo.count
                                    if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] Initial count for \(endpoint) found: \(endpointCount)\n") }
                                    
                                    if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] Verify empty dictionary of objects - availableObjsToMigDict count: \(self.availableObjsToMigDict.count)\n") }
                                    
                                    if endpointCount > 0 {
                                        if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] Create Id Mappings - start.\n") }
                                        
                                        self.nameIdDict(server: self.source_jp_server, endPoint: "computerconfigurations", id: "sourceId") {
                                            (result: [String:Dictionary<String,Int>]) in
                                            self.idDict.removeAll()
                                            
                                            self.nameIdDict(server: self.source_jp_server, endPoint: "packages", id: "sourceId") {
                                                (result: [String:Dictionary<String,Int>]) in
                                            
                                                self.nameIdDict(server: self.dest_jp_server, endPoint: "packages", id: "destId") {
                                                    (result: [String:Dictionary<String,Int>]) in
                                                    self.packages_id_map = result
                                                    if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] packages id map:\n\(self.packages_id_map)\n") }
                                                    self.idDict.removeAll()
                                                    
                                                    self.nameIdDict(server: self.source_jp_server, endPoint: "scripts", id: "sourceId") {
                                                        (result: [String:Dictionary<String,Int>]) in
                                                        
                                                        self.nameIdDict(server: self.dest_jp_server, endPoint: "scripts", id: "destId") {
                                                            (result: [String:Dictionary<String,Int>]) in
                                                            self.scripts_id_map = result
                                                            if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] scripts id map:\n\(self.scripts_id_map)\n") }
                                                            self.idDict.removeAll()
                                                            
                                                            self.nameIdDict(server: self.source_jp_server, endPoint: "printers", id: "sourceId") {
                                                                (result: [String:Dictionary<String,Int>]) in
                                                                
                                                                self.nameIdDict(server: self.dest_jp_server, endPoint: "printers", id: "destId") {
                                                                    (result: [String:Dictionary<String,Int>]) in
                                                                    self.printers_id_map = result
                                                                    if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] printers id map:\n\(self.printers_id_map)\n")}
                                                                    self.idDict.removeAll()
                                                                    
                                                                    self.nameIdDict(server: self.source_jp_server, endPoint: "directorybindings", id: "sourceId") {
                                                                        (result: [String:Dictionary<String,Int>]) in
                                                                        
                                                                        self.nameIdDict(server: self.dest_jp_server, endPoint: "directorybindings", id: "destId") {
                                                                            (result: [String:Dictionary<String,Int>]) in
                                                                            self.bindings_id_map = result
                                                                            if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] bindings id map:\n\(self.bindings_id_map)\n")}
                                                                            self.idDict.removeAll()

                                                                            if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] Create Id Mappings - end.\n") }
                                                                            
                                                                            var orderedConfArray = [String]()
                                                                            var movedParentArray = [String]()
                                                                            self.orphanIds.removeAll()
                                                                            //                                        var remainingConfigsArray = [String]()
                                                                            
                                                                            while self.configObjectsDict.count != movedParentArray.count {
                                                                                for (key, _) in self.configObjectsDict {
                                                                                    if ((self.configObjectsDict[key]?["type"] == "Standard") && (movedParentArray.firstIndex(of: key) == nil)) || ((movedParentArray.firstIndex(of: key) == nil) && (movedParentArray.firstIndex(of: (self.configObjectsDict[key]?["parent"])!) != nil)) {
                                                                                        orderedConfArray.append((self.configObjectsDict[key]?["id"])!)
                                                                                        movedParentArray.append(key)
                                                                                        // look for configs missing their parent
                                                                                    } else if (((self.configObjectsDict[key]?["type"])! == "Smart") && (self.configObjectsDict[(self.configObjectsDict[key]?["parent"])!]?.count == nil)) && (movedParentArray.firstIndex(of: key) == nil) {
                                                                                        WriteToLog().message(stringOfText: "[getEndpoints] Smart config '\(self.configObjectsDict[key]?["parent"] ?? "name not found")' is missing its parent and cannot be migrated.\n")
                                                                                        WriteToLog().message(stringOfText: "[getEndpoints] Smart config '\(key)' (child of '\(self.configObjectsDict[key]?["parent"] ?? "name not found")') will be migrated and changed from smart to standard.\n")
                                                                                        orderedConfArray.append((self.configObjectsDict[key]?["id"])!)
                                                                                        movedParentArray.append(key)
                                                                                        self.orphanIds.append((self.configObjectsDict[key]?["id"])!)
                                                                                    }
                                                                                }
                                                                            }
                                                                            if wipeData.on {
                                                                                orderedConfArray.reverse()
                                                                            }
//                                                                            print("parent array: \(orderedConfArray)")
                                                                            
                                                                            self.existingEndpoints(theDestEndpoint: "\(endpoint)")  {
                                                                                (result: String) in
                                                                                if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] Returned from existing \(endpoint): \(result)\n") }
                                                                                
                                                                                var tmp_availableObjsToMigDict = [Int:String]()
                                                                                
                                                                                for i in (0..<endpointCount) {
//                                                                                    if i == 0 { self.availableObjsToMigDict.removeAll() }
                                                                                    
                                                                                    let record = endpointInfo[i] as! [String : AnyObject]
                                                                                    
                                                                                    tmp_availableObjsToMigDict[record["id"] as! Int] = record["name"] as! String?
                                                                                    
                                                                                }   // for i in (0..<endpointCount) end
                                                                                
                                                                                self.availableObjsToMigDict.removeAll()
                                                                                for orderedId in orderedConfArray {
                                                                                    
                                                                                    self.availableObjsToMigDict[Int(orderedId)!] = tmp_availableObjsToMigDict[Int(orderedId)!]
                                                                                    
                                                                                    if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] Current number of \(endpoint) to process: \(self.availableObjsToMigDict.count)\n") }
                                                                                }   // for i in (0..<endpointCount) end
                                                                                
                                                                                
                                                                                if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] Found total of \(self.availableObjsToMigDict.count) \(endpoint) to process\n") }
                                                                                
                                                                                var counter = 1
                                                                                if self.goSender == "goButton" {
//                                                                                  for (l_xmlID, l_xmlName) in self.availableObjsToMigDict {
                                                                                    for orderedId in orderedConfArray {
                                                                                        let l_xmlID = Int(orderedId)
                                                                                        let l_xmlName = tmp_availableObjsToMigDict[l_xmlID!]
                                                                                        if (l_xmlID != nil) && (l_xmlName != nil) {
                                                                                            if !wipeData.on  {
                                                                                                if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] check for ID on \(String(describing: l_xmlName)): \(self.currentEPs[l_xmlName!] ?? 0)\n") }
                                                                                                if self.currentEPs[l_xmlName!] != nil {
                                                                                                    if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] \(String(describing: l_xmlName)) already exists\n") }
                                                                                                    //self.currentEndpointID = self.currentEPs[l_xmlName]!
                                                                                                    self.endPointByID(endpoint: endpoint, endpointID: l_xmlID!, endpointCurrent: counter, endpointCount: self.availableObjsToMigDict.count, action: "update", destEpId: self.currentEPs[l_xmlName!]!, destEpName: l_xmlName!)
                                                                                                } else {
                                                                                                    if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] \(String(describing: l_xmlName)) - create\n") }
                                                                                                    if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] function - endpoint: \(endpoint), endpointID: \(String(describing: l_xmlID)), endpointCurrent: \(counter), endpointCount: \(endpointCount), action: \"create\", destEpId: 0\n") }
                                                                                                    self.endPointByID(endpoint: endpoint, endpointID: l_xmlID!, endpointCurrent: counter, endpointCount: self.availableObjsToMigDict.count, action: "create", destEpId: 0, destEpName: l_xmlName!)
                                                                                                }
                                                                                            } else {
                                                                                                if LogLevel.debug { WriteToLog().message(stringOfText: "[getEndpoints] remove - endpoint: \(endpoint)\t endpointID: \(String(describing: l_xmlID))\t endpointName: \(String(describing: l_xmlName))\n") }
                                                                                                self.RemoveEndpoints(endpointType: endpoint, endPointID: l_xmlID!, endpointName: l_xmlName!, endpointCurrent: counter, endpointCount: self.availableObjsToMigDict.count)
                                                                                            }   // if !wipeData.on else - end
                                                                                        }
                                                                                            counter+=1
                                                                                    }   // for (l_xmlID, l_xmlName) in availableObjsToMigDict
                                                                                } else {
                                                                                    // populate source server under the selective tab
                                                                                    // for (l_xmlID, l_xmlName) in self.availableObjsToMigDict {
                                                                                    self.delayInt = self.listDelay(itemCount: orderedConfArray.count)
                                                                                    for orderedId in orderedConfArray {
                                                                                        let l_xmlID = Int(orderedId)
                                                                                        let l_xmlName = tmp_availableObjsToMigDict[l_xmlID!]
                                                                                        self.sortQ.async {
                                                                                            //print("adding \(l_xmlName) to array")
                                                                                            self.availableIDsToMigDict[l_xmlName!] = l_xmlID
                                                                                            self.sourceDataArray.append(l_xmlName!)
                                                                                            self.sourceDataArray = self.sourceDataArray.sorted{$0.localizedCaseInsensitiveCompare($1) == .orderedAscending}
                                                                                            DispatchQueue.main.async {
                                                                                                self.srcSrvTableView.reloadData()
                                                                                            }
                                                                                            // slight delay in building the list - visual effect
                                                                                            usleep(self.delayInt)

                                                                                            if counter == orderedConfArray.count {
                                                                                                self.goButtonEnabled(button_status: true)
                                                                                            }
                                                                                            counter+=1
                                                                                        }   // DispatchQueue.main.async - end
                                                                                    }   // for (l_xmlID, l_xmlName) in availableObjsToMigDict
                                                                                }   // if self.goSender else - end
                                                                            }   // self.existingEndpoints - end
                                            
                                                                        }   // self.nameIdDict(server: self.dest_jp_server - bindings end
                                                                    }   // self.nameIdDict(server: self.source_jp_server - bindings end
                                                                }   // self.nameIdDict(server: self.dest_jp_server - printers end
                                                            }   // self.nameIdDict(server: self.source_jp_server - printers end
                                                        }   // self.nameIdDict(server: self.dest_jp_server - scripts end
                                                    }   // self.nameIdDict(server: self.source_jp_server - scripts end
                                                }   // self.nameIdDict(server: self.dest_jp_server - packages end
                                            }   // self.nameIdDict(server: self.source_jp_server - packages end
                                        }   // self.nameIdDict(server: self.source_jp_server - computerconfigurations end
                            
                                    } else {
                                        self.nodesMigrated+=1    // ;print("added node: \(endpoint) - getEndpoints5")
                                        if endpoint == self.objectsToMigrate.last {
                                            self.rmDELETE()
                                            self.resetAllCheckboxes()
//                                            self.goButtonEnabled(button_status: true)
                                            completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                                        }
                                    }   // if endpointCount > 0 - end
                                    if nodeIndex < nodesToMigrate.count - 1 {
                                        self.readNodes(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1)
                                    }
                                    completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
                                } else {  // end if computerconfigurations
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
                    
                }   // if let httpResponse as? HTTPURLResponse - end
                semaphore.signal()
                if error != nil {
                }
            })  // let task = session - end
            task.resume()
        }   // theOpQ - end
//        completion(["Got endpoint - \(endpoint)", "\(endpointCount)"])
    }
    
    func readDataFiles(nodesToMigrate: [String], nodeIndex: Int, completion: @escaping (_ result: String) -> Void) {
        
        if LogLevel.debug { WriteToLog().message(stringOfText: "[readDataFiles] enter\n") }
        
        var local_endpointArray = [String]()
        var local_general       = ""
        let endpoint            = nodesToMigrate[nodeIndex]
        if LogLevel.debug { WriteToLog().message(stringOfText: "[readDataFiles] Working with endpoint: \(endpoint)\n") }

        
        switch nodesToMigrate[nodeIndex] {
        case "computergroups":
            self.progressCountArray["smartcomputergroups"] = 0
            self.progressCountArray["staticcomputergroups"] = 0
            self.progressCountArray["computergroups"] = 0 // this is the recognized end point
        case "mobiledevicegroups":
            self.progressCountArray["smartmobiledevicegroups"] = 0
            self.progressCountArray["staticmobiledevicegroups"] = 0
            self.progressCountArray["mobiledevicegroups"] = 0 // this is the recognized end point
        case "usergroups":
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
        
            switch endpoint {
            case "computergroups":
                if migrateSmartComputerGroups {
                    local_endpointArray.append("smartcomputergroups")
                }
                if migrateStaticComputerGroups {
                    local_endpointArray.append("staticcomputergroups")
                }
                if migrateSmartComputerGroups && migrateStaticComputerGroups {
                    self.nodesMigrated-=1
                }
            case "mobiledevicegroups":
                if migrateSmartMobileGroups {
                    local_endpointArray.append("smartmobiledevicegroups")
                }
                if migrateStaticMobileGroups {
                    local_endpointArray.append("staticmobiledevicegroups")
                }
                if migrateSmartMobileGroups && migrateStaticMobileGroups {
                    self.nodesMigrated-=1
                }
            case "usergroups":
                if migrateSmartUserGroups {
                    local_endpointArray.append("smartusergroups")
                }
                if migrateStaticUserGroups {
                    local_endpointArray.append("staticusergroups")
                }
                if migrateSmartUserGroups && migrateStaticUserGroups {
                    self.nodesMigrated-=1
                }
            default:
                local_endpointArray = [endpoint]
            }
        
        self.availableFilesToMigDict.removeAll()
        theOpQ.maxConcurrentOperationCount = 1
//        let semaphore = DispatchSemaphore(value: 0)
        self.theOpQ.addOperation {
            for local_folder in local_endpointArray {
                do {
                    let allFiles = FileManager.default.enumerator(atPath: self.dataFilesRoot + "/" + local_folder)
                    if let allFilePaths = allFiles?.allObjects {
                        let allFilePathsArray = allFilePaths as! [String]
                        let xmlFilePaths = allFilePathsArray.filter{$0.contains(".xml")} // filter for only files with xml extension
                        let dataFilesCount = xmlFilePaths.count
                    
//                        print("dataFilesCount: \(dataFilesCount)")
                    
                        if dataFilesCount < 1 {
                            self.alert_dialog(header: "Attention:", message: "No files found.")
                            completion("no files found for: \(endpoint)")
                        }
                        for i in 1...dataFilesCount {
                            let dataFile = xmlFilePaths[i-1]
    //                        let dataFile = dataFiles[i-1]
                            let fileUrl = self.exportedFilesUrl?.appendingPathComponent("\(local_folder)/\(dataFile)", isDirectory: false)
                            do {
                                let fileContents = try String(contentsOf: fileUrl!)
                                switch endpoint {
                                case "advancedcomputersearches", "advancedmobiledevicesearches", "categories", "computerextensionattributes", "computergroups", "distributionpoints", "dockitems", "jamfgroups", "jamfusers", "ldapservers", "mobiledeviceextensionattributes", "mobiledevicegroups", "netbootservers", "networksegments", "packages", "printers", "scripts", "softwareupdateservers", "usergroups", "users":
                                    local_general = fileContents
                                    for xmlTag in ["site", "criterion", "computers", "mobile_devices", "image", "path", "contents", "privilege_set", "privileges", "members", "groups", "script_contents", "script_contents_encoded"] {
                                        local_general = self.rmXmlData(theXML: local_general, theTag: xmlTag)
                                    }
                                case "buildings", "departments", "sites", "directorybindings":
                                    local_general = fileContents
                                default:
                                    local_general = self.tagValue2(xmlString:fileContents, startTag:"<general>", endTag:"</general>")
                                    for xmlTag in ["site", "category", "payloads"] {
                                        local_general = self.rmXmlData(theXML: local_general, theTag: xmlTag)
                                    }
                                }
                                
                                let id   = self.tagValue2(xmlString:local_general, startTag:"<id>", endTag:"</id>")
                                let name = self.tagValue2(xmlString:local_general, startTag:"<name>", endTag:"</name>")
                                
                                self.availableFilesToMigDict[dataFile] = [id, name, fileContents]
                                if LogLevel.debug { WriteToLog().message(stringOfText: "[readDataFiles] read \(local_folder): file name : object name - \(dataFile) \t: \(name)\n") }
                            } catch {
                                //                    print("unable to read \(dataFile)")
                                if LogLevel.debug { WriteToLog().message(stringOfText: "[readDataFiles] unable to read \(dataFile)\n") }
                            }
                            self.getStatusUpdate(endpoint: local_folder, current: i, total: dataFilesCount)
                        }   // for i in 1...dataFilesCount - end
                    }   // if let allFilePaths - end
                } catch {
                    if LogLevel.debug { WriteToLog().message(stringOfText: "[readDataFiles] Node: \(local_folder): unable to get files.\n") }
                }
            
                var fileCount = self.availableFilesToMigDict.count
            
                //        print("node: \(local_folder) has \(fileCount) files.")
                if LogLevel.debug { WriteToLog().message(stringOfText: "[readDataFiles] Node: \(local_folder) has \(fileCount) files.\n") }
            
                if fileCount > 0 {
                    self.processFiles(endpoint: endpoint, fileCount: fileCount, itemsDict: self.availableFilesToMigDict) {
                        (result: String) in
                        if LogLevel.debug { WriteToLog().message(stringOfText: "[readDataFiles] Returned from processFiles.\n") }
                        self.availableFilesToMigDict.removeAll()
                        if nodeIndex < nodesToMigrate.count - 1 {
                            self.readNodes(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1)
                        }
                        completion("fetched xml for: \(endpoint)")
                    }
                } else {   // if fileCount - end
                    self.nodesMigrated+=1    // ;print("added node: \(endpoint) - readDataFiles2")
                    if nodeIndex < nodesToMigrate.count - 1 {
                        self.readNodes(nodesToMigrate: nodesToMigrate, nodeIndex: nodeIndex+1)
                    }
                    completion("fetched xml for: \(endpoint)")
                }
                fileCount = 0
            }
        }   // self.theOpQ - end
    }
    
    func processFiles(endpoint: String, fileCount: Int, itemsDict: Dictionary<String,[String]>, completion: @escaping (_ result: String) -> Void) {
        
        if LogLevel.debug { WriteToLog().message(stringOfText: "[processFiles] enter\n") }
        
        self.existingEndpoints(theDestEndpoint: "\(endpoint)") {
            (result: String) in
            if LogLevel.debug { WriteToLog().message(stringOfText: "[processFiles] Returned from existing \(endpoint): \(result)\n") }
            
            self.readFilesQ.maxConcurrentOperationCount = 1
            
            var l_index = 1
            for (_, objectInfo) in itemsDict {
//                self.readFilesQ.sync {
                self.readFilesQ.addOperation {
                    let l_id   = Int(objectInfo[0])   // id of object
                    let l_name = objectInfo[1]        // name of object
                    let l_xml  = objectInfo[2]        // xml of object

                    if l_id != nil && l_name != "" && l_xml != "" {
                        if !wipeData.on  {
                            if LogLevel.debug { WriteToLog().message(stringOfText: "[processFiles] check for ID on \(String(describing: l_name)): \(self.currentEPs[l_name] ?? 0)\n") }
                            if self.currentEPs[l_name] != nil {
                                if LogLevel.debug { WriteToLog().message(stringOfText: "[processFiles] \(endpoint):\(String(describing: l_name)) already exists\n") }
                                self.cleanupXml(endpoint: endpoint, Xml: l_xml, endpointID: l_id!, endpointCurrent: l_index, endpointCount: fileCount, action: "update", destEpId: self.currentEPs[l_name]!, destEpName: l_name) {
                                    (result: String) in
                                    if LogLevel.debug { WriteToLog().message(stringOfText: "[processFiles] [\(endpoint)]: Returned from cleanupXml\n") }
                                    if result == "last" {
                                        completion("processed last file")
                                    }
                                }
                            } else {
                                if LogLevel.debug { WriteToLog().message(stringOfText: "[processFiles] \(endpoint):\(String(describing: l_name)) - create\n") }
                                self.cleanupXml(endpoint: endpoint, Xml: l_xml, endpointID: l_id!, endpointCurrent: l_index, endpointCount: fileCount, action: "create", destEpId: 0, destEpName: l_name) {
                                    (result: String) in
                                    if LogLevel.debug { WriteToLog().message(stringOfText: "[processFiles] [\(endpoint)]: Returned from cleanupXml\n") }
                                    if result == "last" {
                                        completion("processed last file")
                                    }
                                }
                            }
                        }   // if !wipeData.on - end
                    } else {
                        print("trouble with \(objectInfo)")
                    }
                    l_index+=1
                    usleep(50000)  // slow the file read process
                }   // readFilesQ.sync - end
            }   // for (_, objectInfo) - end
        }
    }
    
    // get full record in XML format
    func endPointByID(endpoint: String, endpointID: Int, endpointCurrent: Int, endpointCount: Int, action: String, destEpId: Int, destEpName: String) {
        
        if LogLevel.debug { WriteToLog().message(stringOfText: "[endPointByID] enter\n") }
        
        saveRawXml      = xmlPrefOptions["saveRawXml"]!
        saveRawXmlScope = xmlPrefOptions["saveRawXmlScope"]!

        URLCache.shared.removeAllCachedResponses()
        if LogLevel.debug { WriteToLog().message(stringOfText: "[endPointByID] endpoint passed to endPointByID: \(endpoint)\n") }
        
        concurrentThreads = (concurrentThreads > 5) ? 3:concurrentThreads
        theOpQ.maxConcurrentOperationCount = concurrentThreads
        let semaphore = DispatchSemaphore(value: 0)
        
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
        default:
            localEndPointType = endpoint
        }

        if !( endpoint == "jamfuser" && endpointID == jamfAdminId) {
            var myURL = "\(self.source_jp_server)/JSSResource/\(localEndPointType)/id/\(endpointID)"
            myURL = myURL.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
            myURL = myURL.replacingOccurrences(of: "/JSSResource/jamfusers/id", with: "/JSSResource/accounts/userid")
            myURL = myURL.replacingOccurrences(of: "/JSSResource/jamfgroups/id", with: "/JSSResource/accounts/groupid")
            myURL = myURL.replacingOccurrences(of: "id/id/", with: "id/")
            
            theOpQ.addOperation {
                if LogLevel.debug { WriteToLog().message(stringOfText: "[endPointByID] fetching XML from: \(myURL)\n") }
                let encodedURL = NSURL(string: myURL)
                let request = NSMutableURLRequest(url: encodedURL! as URL)
                request.httpMethod = "GET"
                let configuration = URLSessionConfiguration.default
                configuration.httpAdditionalHeaders = ["Authorization" : "Basic \(self.sourceBase64Creds)", "Content-Type" : "text/xml", "Accept" : "text/xml"]
                let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
                let task = session.dataTask(with: request as URLRequest, completionHandler: {
                    (data, response, error) -> Void in
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        if LogLevel.debug { WriteToLog().message(stringOfText: "[endPointByID] HTTP response code of GET for \(destEpName): \(httpResponse.statusCode)\n") }
                        let PostXML = String(data: data!, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
                        
                        // save source XML - start
                        if self.saveRawXml {
                            if LogLevel.debug { WriteToLog().message(stringOfText: "[endPointByID] Saving raw XML for \(destEpName) with id: \(endpointID).\n") }
                            DispatchQueue.main.async {
                                // added option to remove scope
//                                print("[endPointByID] export.rawXmlScope: \(export.rawXmlScope)")
                                let exportRawXml = (export.rawXmlScope) ? PostXML:self.rmXmlData(theXML: PostXML, theTag: "scope")
                                Xml().save(node: endpoint, xml: exportRawXml, name: destEpName, id: endpointID, format: "raw")
                            }
                        }
                        // save source XML - end
                        
                        if LogLevel.debug { WriteToLog().message(stringOfText: "[endPointByID] Starting to clean-up the XML.\n") }
                        self.cleanupXml(endpoint: endpoint, Xml: PostXML, endpointID: endpointID, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, destEpId: destEpId, destEpName: destEpName) {
                            (result: String) in
                            if LogLevel.debug { WriteToLog().message(stringOfText: "[endPointByID] Returned from cleanupXml\n") }
                        }
                    }   // if let httpResponse - end
                    semaphore.signal()
                    if error != nil {
                    }
                })  // let task = session - end
                //print("GET")
                task.resume()
                semaphore.wait()
            }   // theOpQ - end
        }
    }
    
    func cleanupXml(endpoint: String, Xml: String, endpointID: Int, endpointCurrent: Int, endpointCount: Int, action: String, destEpId: Int, destEpName: String, completion: @escaping (_ result: String) -> Void) {
        
        if LogLevel.debug { WriteToLog().message(stringOfText: "[cleanUpXml] enter\n") }
        
        if !fileImport {
            completion("")
        }
        var PostXML       = Xml
        var knownEndpoint = true

        var iconName        = ""
        var iconId_string   = ""
        var iconId          = 0
        var iconUri         = ""
        
//        var localEndPointType = ""    // disabled lnh 191223
        var theEndpoint       = endpoint
        
        switch endpoint {
        //      adjust the lookup endpoint
//        case "smartcomputergroups", "staticcomputergroups":
//            localEndPointType = "computergroups"
//        case "smartmobiledevicegroups", "staticmobiledevicegroups":
//            localEndPointType = "mobiledevicegroups"
//        case "smartusergroups", "staticusergroups":
//            localEndPointType = "usergroups"
        //      adjust the where the data is sent
        case "accounts/userid":
            theEndpoint = "jamfusers"
        case "accounts/groupid":
            theEndpoint = "jamfgroups"
        default:
            theEndpoint = endpoint
//            localEndPointType = endpoint
        }
        
        // strip out <id> tag from XML
        if endpoint != "computerconfigurations" {
            for xmlTag in ["id"] {
                PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag)
            }
        } else {
            // parent computerconfigurations reference child configurations by id not name
            let regexComp = try! NSRegularExpression(pattern: "<general><id>(.*?)</id>", options:.caseInsensitive)
            PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<general>")
        }
        
        // check scope options for mobiledeviceconfigurationprofiles, osxconfigurationprofiles, and restrictedsoftware - start
        switch endpoint {
        case "osxconfigurationprofiles":
            if !self.scopeOcpCopy {
                PostXML = self.rmXmlData(theXML: PostXML, theTag: "scope")
            }
        case "policies":
            if !self.scopePoliciesCopy {
                PostXML = self.rmXmlData(theXML: PostXML, theTag: "scope")
            }
            if self.policyPoliciesDisable {
                PostXML = self.disable(theXML: PostXML)
            }
        case "macapplications":
            if !self.scopeMaCopy {
                PostXML = self.rmXmlData(theXML: PostXML, theTag: "scope")
            }
        case "restrictedsoftware":
            if !self.scopeRsCopy {
                PostXML = self.rmXmlData(theXML: PostXML, theTag: "scope")
            }
        case "mobiledeviceconfigurationprofiles":
            if !self.scopeMcpCopy {
                PostXML = self.rmXmlData(theXML: PostXML, theTag: "scope")
            }
        case "mobiledeviceapplications":
            if !self.scopeIaCopy {
                PostXML = self.rmXmlData(theXML: PostXML, theTag: "scope")
            }
        case "usergroups", "staticusergroups":
            if !self.scopeUsersCopy {
                PostXML = self.rmXmlData(theXML: PostXML, theTag: "users")
            }

        default:
            break
        }
        // check scope options for mobiledeviceconfigurationprofiles, osxconfigurationprofiles, and restrictedsoftware - end
        
        switch endpoint {
        case "buildings", "departments", "diskencryptionconfigurations", "sites", "categories", "distributionpoints", "dockitems", "netbootservers", "softwareupdateservers", "computerconfigurations", "scripts", "printers", "osxconfigurationprofiles", "patchpolicies", "mobiledeviceconfigurationprofiles", "advancedmobiledevicesearches", "mobiledeviceextensionattributes", "mobiledevicegroups", "smartmobiledevicegroups", "staticmobiledevicegroups", "mobiledevices", "usergroups", "smartusergroups", "staticusergroups", "userextensionattributes", "advancedusersearches", "restrictedsoftware":
            if LogLevel.debug { WriteToLog().message(stringOfText: "[cleanupXml] processing \(endpoint) - verbose\n") }
            //print("\nXML: \(PostXML)")
            
            // clean up PostXML, remove unwanted/conflicting data
            switch endpoint {
            case "advancedusersearches":
                for xmlTag in ["users"] {
                    PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag)
                }
                
            case "advancedmobiledevicesearches", "mobiledevicegroups", "smartmobiledevicegroups", "staticmobiledevicegroups":
                //                                 !self.scopeSigCopy
                if (PostXML.range(of:"<is_smart>true</is_smart>") != nil || !self.scopeSigCopy) {
                    PostXML = self.rmXmlData(theXML: PostXML, theTag: "mobile_devices")
                }
                
                if itemToSite && destinationSite != "" && endpoint != "advancedmobiledevicesearches" {
//                if siteMigrate.state.rawValue == 1 && destinationSite != "" && endpoint != "advancedmobiledevicesearches" {
                    PostXML = setSite(xmlString: PostXML, site: destinationSite, endpoint: endpoint)
                }
                
            case "mobiledevices":
                for xmlTag in ["initial_entry_date_epoch", "initial_entry_date_utc", "last_enrollment_epoch", "last_enrollment_utc", "1applications", "certificates", "configuration_profiles", "provisioning_profiles", "mobile_device_groups", "extension_attributes"] {
                    PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag)
                }
                
            case "osxconfigurationprofiles", "mobiledeviceconfigurationprofiles":
                // migrating to another site
                if itemToSite && destinationSite != "" {
//                if siteMigrate.state.rawValue == 1 && destinationSite != "" {
                    PostXML = setSite(xmlString: PostXML, site: destinationSite, endpoint: endpoint)
                }
                
                if endpoint == "osxconfigurationprofiles" {
                    // correct issue when an & is in the name of a macOS configuration profiles - real issue is in the encoded payload
                    PostXML = PostXML.replacingOccurrences(of: "&amp;amp;", with: "%26;")
                    //print("\nXML: \(PostXML)")
                }
                
            case "usergroups", "smartusergroups", "staticusergroups":
                for xmlTag in ["full_name", "phone_number", "email_address"] {
                    PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag)
                }
                
            case "computerconfigurations":
                if LogLevel.debug { WriteToLog().message(stringOfText: "[endPointByID] cleaning up computerconfigurations - verbose\n") }
                // remove password from XML, since it doesn't work on the new server
                let regexComp = try! NSRegularExpression(pattern: "<password_sha256 since=(.*?)</password_sha256>", options:.caseInsensitive)
                PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "")
                
                for (item,itemIds) in self.packages_id_map {
                    let sourceId = itemIds["sourceId"]
                    let destId = itemIds["destId"]
                    let regexComp = try! NSRegularExpression(pattern: "<package><id>\(sourceId ?? 0)</id><name>\(item)</name>", options:.caseInsensitive)
                    PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<package><id>\(destId ?? 0)</id><name>\(item)</name>")
                }
                for (item,itemIds) in self.scripts_id_map {
                    let sourceId = itemIds["sourceId"]
                    let destId = itemIds["destId"]
                    let regexComp = try! NSRegularExpression(pattern: "<script><id>\(sourceId ?? 0)</id><name>\(item)</name>", options:.caseInsensitive)
                    PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<script><id>\(destId ?? 0)</id><name>\(item)</name>")
                }
                for (item,itemIds) in self.printers_id_map {
                    let sourceId = itemIds["sourceId"]
                    let destId = itemIds["destId"]
                    let regexComp = try! NSRegularExpression(pattern: "<printer><id>\(sourceId ?? 0)</id><name>\(item)</name>", options:.caseInsensitive)
                    PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<printer><id>\(destId ?? 0)</id><name>\(item)</name>")
                }
                for (item,itemIds) in self.bindings_id_map {
                    let sourceId = itemIds["sourceId"]
                    let destId = itemIds["destId"]
                    let regexComp = try! NSRegularExpression(pattern: "<directory_bindings><id>\(sourceId ?? 0)</id><name>\(item)</name>", options:.caseInsensitive)
                    PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<directory_bindings><id>\(destId ?? 0)</id><name>\(item)</name>")
                }
                if self.orphanIds.firstIndex(of: "\(endpointID)") != nil {
                    let regexComp = try! NSRegularExpression(pattern: "<type>Smart<type>", options:.caseInsensitive)
                    PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<type>Standard<type>")
                    let regexComp2 = try! NSRegularExpression(pattern: "<parent>(.*?)</parent>", options:.caseInsensitive)
                    PostXML = regexComp2.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "")
                }
                for xmlTag in ["script_contents", "script_contents_encoded", "ppd_contents"] {
                    PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag)
                }
                
            case "scripts":
                for xmlTag in ["script_contents_encoded"] {
                    PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag)
                }
                // fix to remove parameter labels that have been deleted from existing scripts
                PostXML = self.parameterFix(theXML: PostXML)
                
            default: break
            }
            
        case "computerextensionattributes":
            if self.tagValue(xmlString: PostXML, xmlTag: "description") == "Extension Attribute provided by JAMF Nation patch service" {
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
                WriteToLog().message(stringOfText: "[endPointByID] Patch EAs are not migrated, skipping \(patchEaName)\n")
                self.postCount += 1
                if self.objectsToMigrate.last == endpoint && endpointCount == endpointCurrent {
                    //self.go_button.isEnabled = true
                    self.rmDELETE()
                    self.resetAllCheckboxes()
                    self.goButtonEnabled(button_status: true)
                    print("Done - cleanupXml")
                }
            }
            
        case "directorybindings", "ldapservers":
            if LogLevel.debug { WriteToLog().message(stringOfText: "[endPointByID] processing ldapservers - verbose\n") }
            // remove password from XML, since it doesn't work on the new server
            let regexComp = try! NSRegularExpression(pattern: "<password_sha256 since=\"9.23\">(.*?)</password_sha256>", options:.caseInsensitive)
            PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "")
            //print("\nXML: \(PostXML)")
            
        case "advancedcomputersearches":
            if LogLevel.debug { WriteToLog().message(stringOfText: "[endPointByID] processing advancedcomputersearches - verbose\n") }
            // clean up some data from XML
            for xmlTag in ["computers"] {
                PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag)
            }
            
        case "computers":
            if LogLevel.debug { WriteToLog().message(stringOfText: "[endPointByID] processing computers - verbose\n") }
            // clean up some data from XML
            for xmlTag in ["package", "mapped_printers", "plugins", "running_services", "licensed_software", "computer_group_memberships", "managed", "management_username"] {
                PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag)
            }
            
            // change serial number 'Not Available' to blank so machines will migrate
            PostXML = PostXML.replacingOccurrences(of: "<serial_number>Not Available</serial_number>", with: "<serial_number></serial_number>")
            
            let regexComp = try! NSRegularExpression(pattern: "<management_password_sha256 since=\"9.23\">(.*?)</management_password_sha256>", options:.caseInsensitive)
            PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "")
            PostXML = PostXML.replacingOccurrences(of: "<xprotect_version/>", with: "")
            //print("\nXML: \(PostXML)")
            
        case "networksegments":
            if LogLevel.debug { WriteToLog().message(stringOfText: "[endPointByID] processing network segments - verbose\n") }
            // remove items not transfered; distribution points, netboot server, SUS from XML
            let regexDistro1 = try! NSRegularExpression(pattern: "<distribution_server>(.*?)</distribution_server>", options:.caseInsensitive)
            let regexDistro2 = try! NSRegularExpression(pattern: "<distribution_point>(.*?)</distribution_point>", options:.caseInsensitive)
            let regexDistro3 = try! NSRegularExpression(pattern: "<url>(.*?)</url>", options:.caseInsensitive)
            let regexNetBoot = try! NSRegularExpression(pattern: "<netboot_server>(.*?)</netboot_server>", options:.caseInsensitive)
            let regexSUS = try! NSRegularExpression(pattern: "<swu_server>(.*?)</swu_server>", options:.caseInsensitive)
            PostXML = regexDistro1.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<distribution_server/>")
            // if not migrating file shares remove then from network segments xml - start
            DispatchQueue.main.async {
                if self.fileshares_button.state.rawValue == 0 {
                    PostXML = regexDistro2.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<distribution_point/>")
                    PostXML = regexDistro3.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<url/>")
                }
                // if not migrating file shares remove then from network segments xml - end
                // if not migrating netboot server remove then from network segments xml - start
                if self.netboot_button.state.rawValue == 0 {
                    PostXML = regexNetBoot.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<netboot_server/>")
                }
                // if not migrating netboot server remove then from network segments xml - end
                // if not migrating software update server remove then from network segments xml - start
                if self.sus_button.state.rawValue == 0 {
                    PostXML = regexSUS.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<swu_server/>")
                }
                // if not migrating software update server remove then from network segments xml - end
            }
            
            //print("\nXML: \(PostXML)")
            
        case "computergroups", "smartcomputergroups", "staticcomputergroups":
            if LogLevel.debug { WriteToLog().message(stringOfText: "[endPointByID] processing \(endpoint) - verbose\n") }
            // remove computers that are a member of a smart group
            if (PostXML.range(of:"<is_smart>true</is_smart>") != nil || !self.scopeScgCopy) {
                // groups containing thousands of computers could not be cleared by only using the computers tag
                PostXML = self.rmXmlData(theXML: PostXML, theTag: "computer")
                PostXML = self.rmBlankLines(theXML: PostXML)
                PostXML = self.rmXmlData(theXML: PostXML, theTag: "computers")
            }
            //            print("\n\(endpoint) XML: \(PostXML)\n")
            
            // migrating to another site
//            DispatchQueue.main.async {
            if itemToSite && destinationSite != "" {
//                if siteMigrate.state.rawValue == 1 && destinationSite != "" {
                    PostXML = setSite(xmlString: PostXML, site: destinationSite, endpoint: endpoint)
                }
//            }
            
        case "packages":
            if LogLevel.debug { WriteToLog().message(stringOfText: "[endPointByID] processing packages - verbose\n") }
            // remove 'No category assigned' from XML
            let regexComp = try! NSRegularExpression(pattern: "<category>No category assigned</category>", options:.caseInsensitive)
            PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<category/>")
            //print("\nXML: \(PostXML)")
            
        case "policies", "macapplications", "mobiledeviceapplications":
            if LogLevel.debug { WriteToLog().message(stringOfText: "[endPointByID] processing \(endpoint) - verbose\n") }
            // check for a self service icon and grab name and id if present - start
            if PostXML.range(of: "</self_service_icon>") != nil {
                let selfServiceIconXml = self.tagValue(xmlString: PostXML, xmlTag: "self_service_icon")
                iconUri = self.tagValue(xmlString: selfServiceIconXml, xmlTag: "uri").replacingOccurrences(of: "//iconservlet", with: "/iconservlet")
                iconName = self.tagValue(xmlString: selfServiceIconXml, xmlTag: "filename")
                if let index = iconUri.firstIndex(of: "=") {
                    iconId_string = iconUri.suffix(from: index).replacingOccurrences(of: "=", with: "")
                    if endpoint != "policies" {
                        if let index = iconId_string.firstIndex(of: "&") {
                            iconId = Int(iconId_string.prefix(upTo: index))!
                        }
                    } else {
                        iconId = Int(iconId_string)!
                    }
                }
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
            
            // Self Service description fix, migrating from 9 to 10.2+
            //                            if self.tagValue(xmlString: PostXML, xmlTag: "use_for_self_service") == "true" {
            //                                if self.tagValue(xmlString: PostXML, xmlTag: "self_service_display_name") == "" {
            //                                    let SsText = "<use_for_self_service>true</use_for_self_service>"
            //                                    let SsDesc = "<self_service_display_name>\(destEpName)</self_service_display_name>"
            //                                    let regexSsDesc = try! NSRegularExpression(pattern: SsText, options:.caseInsensitive)
            //                                    PostXML = regexSsDesc.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: SsText+"\n"+SsDesc)
            //                                }
            //                            }
            
            // fix names that start with spaces - convert space to hex: &#xA0;
            let regexPolicyName = try! NSRegularExpression(pattern: "<name> ", options:.caseInsensitive)
            PostXML = regexPolicyName.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<name>&#xA0;")
            
            // remove individual objects that are scoped to the policy from XML
            for xmlTag in ["self_service_icon"] {
                PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag)
            }
            
            // update references to the Jamf server
            let regexServer = try! NSRegularExpression(pattern: self.urlToFqdn(serverUrl: self.source_jp_server), options:.caseInsensitive)
            PostXML = regexServer.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: self.urlToFqdn(serverUrl: self.dest_jp_server))
            
            // set the password used in the accounts payload to jamfchangeme - start
            let regexAccounts = try! NSRegularExpression(pattern: "<password_sha256 since=\"9.23\">(.*?)</password_sha256>", options:.caseInsensitive)
            PostXML = regexAccounts.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<password>jamfchangeme</password>")
            // set the password used in the accounts payload to jamfchangeme - end
            
            let regexComp = try! NSRegularExpression(pattern: "<management_password_sha256 since=\"9.23\">(.*?)</management_password_sha256>", options:.caseInsensitive)
            PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "")
            //print("\nXML: \(PostXML)")
            
            // migrating to another site
//            DispatchQueue.main.async {
            if itemToSite && destinationSite != "" && endpoint == "policies" {
//                if siteMigrate.state.rawValue == 1 && destinationSite != "" && endpoint == "policies" {
                    PostXML = setSite(xmlString: PostXML, site: destinationSite, endpoint: endpoint)
                }
//            }
            
        case "users":
            if LogLevel.debug { WriteToLog().message(stringOfText: "[endPointByID] processing users - verbose\n") }
            
            let regexComp = try! NSRegularExpression(pattern: "<self_service_icon>(.*?)</self_service_icon>", options:.caseInsensitive)
            PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<self_service_icon/>")
            // remove photo reference from XML
            for xmlTag in ["enable_custom_photo_url", "custom_photo_url", "links"] {
                PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag)
            }
            //print("\nXML: \(PostXML)")
            
        case "jamfusers", "jamfgroups", "accounts/userid", "accounts/groupid":
            if LogLevel.debug { WriteToLog().message(stringOfText: "[endPointByID] processing jamf users/groups (\(endpoint)) - verbose\n") }
            // remove password from XML, since it doesn't work on the new server
            let regexComp = try! NSRegularExpression(pattern: "<password_sha256 since=\"9.32\">(.*?)</password_sha256>", options:.caseInsensitive)
            PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "")
            //print("\nXML: \(PostXML)")
            // check for LDAP account/group, make adjustment for v10.17+ which needs id rather than name - start
            //   && jamfProVersion.major >= 10 && jamfProVersion.minor >= 17
            if tagValue(xmlString: PostXML, xmlTag: "ldap_server") != "" {
                let ldapServerInfo = tagValue(xmlString: PostXML, xmlTag: "ldap_server")
                let ldapServerName = tagValue(xmlString: ldapServerInfo, xmlTag: "name")
                    let regexLDAP = try! NSRegularExpression(pattern: "<ldap_server>(.*?)</ldap_server>", options:.caseInsensitive)
                let ldapId = currentLDAPServers[ldapServerName] ?? -1
                PostXML = regexLDAP.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<ldap_server><id>\(ldapId)</id></ldap_server>")
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
                    PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag)
                }
            }
            
        default:
            if LogLevel.debug { WriteToLog().message(stringOfText: "[endPointByID] Unknown endpoint: \(endpoint)\n") }
            knownEndpoint = false
        }   // switch - end
        if self.getCounters[endpoint] == nil {
            self.getCounters[endpoint] = ["get":1]
        } else {
            self.getCounters[endpoint]!["get"]! += 1
        }
//        self.getCounters[endpoint]!["get"]! += 1
        self.getStatusUpdate(endpoint: endpoint, current: self.getCounters[endpoint]!["get"]!, total: endpointCount)
//        self.getStatusUpdate(endpoint: endpoint, current: endpointCurrent, total: endpointCount)
        
        if knownEndpoint {
//            print("\n[cleanupXml] knownEndpoint-PostXML: \(PostXML)")
            self.CreateEndpoints(endpointType: theEndpoint, endPointXML: PostXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, sourceEpId: endpointID, destEpId: destEpId, ssIconName: iconName, ssIconId: iconId, ssIconUri: iconUri, retry: false) {
                (result: String) in
                if LogLevel.debug { WriteToLog().message(stringOfText: "[endPointByID] \(result)\n") }
                if endpointCurrent == endpointCount {
                    completion("last")
                } else {
                    completion("")
                }
            }
        } else {
            if endpointCurrent == endpointCount {
                if LogLevel.debug { WriteToLog().message(stringOfText: "[cleanupXml] Last item in \(theEndpoint) was unkown.\n") }
                self.nodesMigrated+=1
                completion("last")
                // ;print("added node: \(localEndPointType) - createEndpoints")
                //                    print("nodes complete: \(self.nodesMigrated)")
            } else {
                completion("")
            }
        }
    }
    
    func CreateEndpoints(endpointType: String, endPointXML: String, endpointCurrent: Int, endpointCount: Int, action: String, sourceEpId: Int, destEpId: Int, ssIconName: String, ssIconId: Int, ssIconUri: String, retry: Bool, completion: @escaping (_ result: String) -> Void) {
        
        if LogLevel.debug { WriteToLog().message(stringOfText: "[CreateEndpoints] enter\n") }
        
        if counters[endpointType] == nil {
            self.counters[endpointType] = ["create":0, "update":0, "fail":0, "total":0]
            self.summaryDict[endpointType] = ["create":[], "update":[], "fail":[]]
        }
        
        var destinationEpId = destEpId
        var apiAction       = action
        
        // counterts for completed endpoints
        var totalCreated   = 0
        var totalUpdated   = 0
        var totalFailed    = 0
        var totalCompleted = 0
        
        if counters[endpointType] == nil {
            counters[endpointType] = ["total":endpointCount]
        } else {
            counters[endpointType]!["total"] = endpointCount
        }
        
        // if working a site migrations within a single server force create when copying an item
        if self.itemToSite && sitePref == "Copy" {
            destinationEpId = 0
            apiAction       = "create"
        }
        
        // this is where we create the new endpoint
        if !self.saveOnly {
            if LogLevel.debug { WriteToLog().message(stringOfText: "[CreateEndpoints] Creating new: \(endpointType)\n") }
        } else {
            if LogLevel.debug { WriteToLog().message(stringOfText: "[CreateEndpoints] Save only selected, skipping \(apiAction) for: \(endpointType)\n") }
        }
//        var createDestUrl = createDestUrlBase
        //if LogLevel.debug { WriteToLog().message(stringOfText: "[CreateEndpoints] ----- Posting #\(endpointCurrent): \(endpointType) -----\n") }
        
        concurrentThreads = (concurrentThreads > 5) ? 3:concurrentThreads
        theCreateQ.maxConcurrentOperationCount = concurrentThreads
        let semaphore = DispatchSemaphore(value: 0)
        let encodedXML = endPointXML.data(using: String.Encoding.utf8)
        var localEndPointType = ""
        var whichError        = ""
//        var curlResult        = ""
        
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
        
        if self.itemToSite {
            
        }
        
        var createDestUrl = "\(createDestUrlBase)/" + localEndPointType + "/id/\(destinationEpId)"
        
        if LogLevel.debug { WriteToLog().message(stringOfText: "[CreateEndpoints] Original Dest. URL: \(createDestUrl)\n") }
        createDestUrl = createDestUrl.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
        createDestUrl = createDestUrl.replacingOccurrences(of: "/JSSResource/jamfusers/id", with: "/JSSResource/accounts/userid")
        createDestUrl = createDestUrl.replacingOccurrences(of: "/JSSResource/jamfgroups/id", with: "/JSSResource/accounts/groupid")
        
        theCreateQ.addOperation {
            
            // save trimmed XML - start
            if self.saveTrimmedXml {
                let endpointName = self.getName(endpoint: endpointType, objectXML: endPointXML)
                if LogLevel.debug { WriteToLog().message(stringOfText: "[CreateEndpoints] Saving trimmed XML for \(endpointName) with id: \(sourceEpId).\n") }
                DispatchQueue.main.async {
                    let exportTrimmedXml = (export.trimmedXmlScope) ? endPointXML:self.rmXmlData(theXML: endPointXML, theTag: "scope")
                    Xml().save(node: endpointType, xml: exportTrimmedXml, name: endpointName, id: sourceEpId, format: "trimmed")
                }
                
            }
            // save trimmed XML - end
            
            //******************                // add option to save icons to folder if using the export option
            if self.saveOnly {
                if self.objectsToMigrate.last == localEndPointType && endpointCount == endpointCurrent {
                    //self.go_button.isEnabled = true
                    self.rmDELETE()
                    self.resetAllCheckboxes()
                    self.goButtonEnabled(button_status: true)
//                    print("Done - CreateEndpoints")
                }
                if ((endpointType == "policies") || (endpointType == "mobiledeviceapplications")) && (action == "create") {
                    self.icons(endpointType: endpointType, action: action, ssIconName: ssIconName, ssIconId: ssIconId, ssIconUri: ssIconUri, f_createDestUrl: createDestUrl, responseData: responseData)
                }
                return
            }
            
            if LogLevel.debug { WriteToLog().message(stringOfText: "[CreateEndpoints] Action: \(apiAction)\t URL: \(createDestUrl)\t Object \(endpointCurrent) of \(endpointCount)\n") }
            if LogLevel.debug { WriteToLog().message(stringOfText: "[CreateEndpoints] Object XML: \(endPointXML)\n") }
//            print("[CreateEndpoints] [\(localEndPointType)] process start: \(self.getName(endpoint: endpointType, objectXML: endPointXML))")
            
            if endpointCurrent == 1 {
                if !retry {
                    self.postCount = 1
                }
            } else {
                if !retry {
                    self.postCount += 1
                }
            }
            let encodedURL = NSURL(string: createDestUrl)
            let request = NSMutableURLRequest(url: encodedURL! as URL)
            if apiAction == "create" {
                request.httpMethod = "POST"
            } else {
                request.httpMethod = "PUT"
            }
            let configuration = URLSessionConfiguration.default
            configuration.httpAdditionalHeaders = ["Authorization" : "Basic \(self.destBase64Creds)", "Content-Type" : "text/xml", "Accept" : "text/xml"]
            request.httpBody = encodedXML!
            let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
            let task = session.dataTask(with: request as URLRequest, completionHandler: {
                (data, response, error) -> Void in
                if let httpResponse = response as? HTTPURLResponse {
                    
                    if let _ = String(data: data!, encoding: .utf8) {
                        responseData = String(data: data!, encoding: .utf8)!
//                        if LogLevel.debug { WriteToLog().message(stringOfText: "[CreateEndpoints] \n\nfull response from create:\n\(responseData)") }
//                        print("create data response: \(responseData)")
                    } else {
                        if LogLevel.debug { WriteToLog().message(stringOfText: "\n\n[CreateEndpoints] No data was returned from post/put.\n") }
                    }
                    
                    // look to see if we are processing the next endpointType - start
                    if self.endpointInProgress != endpointType || self.endpointInProgress == "" {
                        WriteToLog().message(stringOfText: "[CreateEndpoints] Migrating \(endpointType)\n")
                        self.endpointInProgress = endpointType
                        self.POSTsuccessCount = 0
                    }   // look to see if we are processing the next localEndPointType - end
                    
                    DispatchQueue.main.async {
                    
                        // ? remove creation of counters dict defined earlier ?
                        if self.counters[endpointType] == nil {
                            self.counters[endpointType] = ["create":0, "update":0, "fail":0, "total":0]
                            self.summaryDict[endpointType] = ["create":[], "update":[], "fail":[]]
                        }
                        
                        
                        if httpResponse.statusCode > 199 && httpResponse.statusCode <= 299 {
                            WriteToLog().message(stringOfText: "    [CreateEndpoints] [\(localEndPointType)] succeeded: \(self.getName(endpoint: endpointType, objectXML: endPointXML))\n")
                            
                            self.POSTsuccessCount += 1
                            
//                            print("endpointType: \(endpointType)")
//                            print("progressCountArray: \(String(describing: self.progressCountArray["\(endpointType)"]))")
                            
                            if let _ = self.progressCountArray["\(endpointType)"] {
                                self.progressCountArray["\(endpointType)"] = self.progressCountArray["\(endpointType)"]!+1
//                                if endpointCount == endpointCurrent && self.progressCountArray["\(endpointType)"] == endpointCount {
//                                    self.labelColor(endpoint: endpointType, theColor: self.greenText)
//                                }
                                
                            }
                            
                            let localTmp = (self.counters[endpointType]?["\(apiAction)"])!
    //                        print("localTmp: \(localTmp)")
                            self.counters[endpointType]?["\(apiAction)"] = localTmp + 1
                            
                            if var summaryArray = self.summaryDict[endpointType]?["\(apiAction)"] {
                                summaryArray.append(self.getName(endpoint: endpointType, objectXML: endPointXML))
                                self.summaryDict[endpointType]?["\(apiAction)"] = summaryArray
                            }
                            
                            // currently there is no way to upload mac app store icons
                            // removed check for those -  || (endpointType == "macapplications")
                            if ((endpointType == "policies") || (endpointType == "mobiledeviceapplications")) && (action == "create") {
                                self.icons(endpointType: endpointType, action: action, ssIconName: ssIconName, ssIconId: ssIconId, ssIconUri: ssIconUri, f_createDestUrl: createDestUrl, responseData: responseData)
                            }
                            
                        } else {
                            // create failed

                            self.labelColor(endpoint: endpointType, theColor: self.yellowText)
                        
                            // Write xml for degugging - start
                            let errorMsg = self.tagValue2(xmlString: responseData, startTag: "<p>Error: ", endTag: "</p>")
                            var localErrorMsg = ""

                            errorMsg != "" ? (localErrorMsg = "\(action.capitalized) error: \(errorMsg)"):(localErrorMsg = "\(action.capitalized) error: unknown")
                            
                            // Write xml for degugging - end
                            
                            if errorMsg.lowercased().range(of:"no match found for category") != nil || errorMsg.lowercased().range(of:"problem with category") != nil {
                                whichError = "category"
                            } else {
                                whichError = errorMsg
                            }
                            
                            // retry computers with dublicate serial or MAC - start
                            switch whichError {
                            case "Duplicate serial number", "Duplicate MAC address":
                                if !retry {
                                    WriteToLog().message(stringOfText: "    [CreateEndpoints] [\(localEndPointType)] \(self.getName(endpoint: endpointType, objectXML: endPointXML)) - Conflict (\(httpResponse.statusCode)).  \(localErrorMsg).  Will retry without serial and MAC address.\n")
                                    var tmp_endPointXML = endPointXML
                                    for xmlTag in ["alt_mac_address", "mac_address", "serial_number"] {
                                        tmp_endPointXML = self.rmXmlData(theXML: tmp_endPointXML, theTag: xmlTag)
                                    }
                                    self.CreateEndpoints(endpointType: endpointType, endPointXML: tmp_endPointXML, endpointCurrent: (endpointCurrent), endpointCount: endpointCount, action: action, sourceEpId: sourceEpId, destEpId: destEpId, ssIconName: ssIconName, ssIconId: ssIconId, ssIconUri: ssIconUri, retry: true) {
                                        (result: String) in
                                        //                                    if LogLevel.debug { WriteToLog().message(stringOfText: "[endPointByID] \(result)\n") }
                                    }
                                } else {
                                    WriteToLog().message(stringOfText: "    [CreateEndpoints] [\(localEndPointType)] \(self.getName(endpoint: endpointType, objectXML: endPointXML)) - Conflict (\(httpResponse.statusCode)).  \(localErrorMsg).  Will retry without serial and MAC address failed.\n")
                                }
                            case "category":
                                WriteToLog().message(stringOfText: "    [CreateEndpoints] [\(localEndPointType)] \(self.getName(endpoint: endpointType, objectXML: endPointXML)) - Conflict (\(httpResponse.statusCode)).  \(localErrorMsg).  Will retry without the category.\n")
                                var tmp_endPointXML = endPointXML
                                for xmlTag in ["category"] {
                                    tmp_endPointXML = self.rmXmlData(theXML: tmp_endPointXML, theTag: xmlTag)
                                }
                                self.CreateEndpoints(endpointType: endpointType, endPointXML: tmp_endPointXML, endpointCurrent: (endpointCurrent), endpointCount: endpointCount, action: action, sourceEpId: sourceEpId, destEpId: destEpId, ssIconName: ssIconName, ssIconId: ssIconId, ssIconUri: ssIconUri, retry: true) {
                                    (result: String) in
                                }
                            //    self.postCount -= 1
                           //     return
                            case "Problem with department in location":
                                WriteToLog().message(stringOfText: "    [CreateEndpoints] [\(localEndPointType)] \(self.getName(endpoint: endpointType, objectXML: endPointXML)) - Conflict (\(httpResponse.statusCode)).  \(localErrorMsg).  Will retry without the department.\n")
                                var tmp_endPointXML = endPointXML
                                for xmlTag in ["department"] {
                                    tmp_endPointXML = self.rmXmlData(theXML: tmp_endPointXML, theTag: xmlTag)
                                }
                                self.CreateEndpoints(endpointType: endpointType, endPointXML: tmp_endPointXML, endpointCurrent: (endpointCurrent), endpointCount: endpointCount, action: action, sourceEpId: sourceEpId, destEpId: destEpId, ssIconName: ssIconName, ssIconId: ssIconId, ssIconUri: ssIconUri, retry: true) {
                                    (result: String) in
                                }
                            //    self.postCount -= 1
                            //    return
                            case "Problem with building in location":
                                WriteToLog().message(stringOfText: "    [CreateEndpoints] [\(localEndPointType)] \(self.getName(endpoint: endpointType, objectXML: endPointXML)) - Conflict (\(httpResponse.statusCode)).  \(localErrorMsg).  Will retry without the building.\n")
                                var tmp_endPointXML = endPointXML
                                for xmlTag in ["building"] {
                                    tmp_endPointXML = self.rmXmlData(theXML: tmp_endPointXML, theTag: xmlTag)
                                }
                                self.CreateEndpoints(endpointType: endpointType, endPointXML: tmp_endPointXML, endpointCurrent: (endpointCurrent), endpointCount: endpointCount, action: action, sourceEpId: sourceEpId, destEpId: destEpId, ssIconName: ssIconName, ssIconId: ssIconId, ssIconUri: ssIconUri, retry: true) {
                                    (result: String) in
                                    //                                    if LogLevel.debug { WriteToLog().message(stringOfText: "[endPointByID] \(result)\n") }
                                }
                              //  self.postCount -= 1
                             //   return
                            default:
                                WriteToLog().message(stringOfText: "[CreateEndpoints] [\(localEndPointType)] \(self.getName(endpoint: endpointType, objectXML: endPointXML)) - Failed (\(httpResponse.statusCode)).  \(localErrorMsg).\n")
                                
                                if LogLevel.debug { WriteToLog().message(stringOfText: "\n\n") }
                                if LogLevel.debug { WriteToLog().message(stringOfText: "[CreateEndpoints]  ---------- xml of failed upload ----------\n") }
                                if LogLevel.debug { WriteToLog().message(stringOfText: "[CreateEndpoints] \(endPointXML)\n") }
                                if LogLevel.debug { WriteToLog().message(stringOfText: "[CreateEndpoints] ---------- status code ----------\n") }
                                if LogLevel.debug { WriteToLog().message(stringOfText: "[CreateEndpoints] \(httpResponse.statusCode)\n") }
                                if LogLevel.debug { WriteToLog().message(stringOfText: "[CreateEndpoints] ---------- response data ----------\n") }
                                if LogLevel.debug { WriteToLog().message(stringOfText: "[CreateEndpoints] \n\(responseData)\n") }
                                if LogLevel.debug { WriteToLog().message(stringOfText: "[CreateEndpoints] ---------- response data ----------\n\n") }
                                // 400 - likely the format of the xml is incorrect or wrong endpoint
                                // 401 - wrong username and/or password
                                // 409 - unable to create object; already exists or data missing or xml error
                                
                                // update global counters
                                let localTmp = (self.counters[endpointType]?["fail"])!
                                self.counters[endpointType]?["fail"] = localTmp + 1
                                if var summaryArray = self.summaryDict[endpointType]?["fail"] {
                                    summaryArray.append(self.getName(endpoint: endpointType, objectXML: endPointXML))
                                    self.summaryDict[endpointType]?["fail"] = summaryArray
                                }
                            }
                        }   // create failed - end
                        
                        totalCreated   = self.counters[endpointType]!["create"]!
                        totalUpdated   = self.counters[endpointType]!["update"]!
                        totalFailed    = self.counters[endpointType]!["fail"]!
                        totalCompleted = totalCreated + totalUpdated + totalFailed
                        
                        // update counter
                        //                        DispatchQueue.main.async {
                        self.object_name_field.stringValue = "\(endpointType)"
                        let currentCompleted = Int(self.objects_completed_field!.stringValue) ?? 0
                        //                            if endpointCurrent > currentCompleted || (endpointCurrent < 4 && endpointCurrent > 0) {
//                        if totalCompleted > currentCompleted {
                        if totalCompleted > 0 {
                            self.objects_completed_field.stringValue = "\(totalCompleted)"
                        }
                        self.objects_found_field.stringValue = "\(String(describing: self.counters[endpointType]!["total"]!))"
//                            self.objects_found_field.stringValue     = "\(endpointCount)"
//                        }   // DispatchQueue.main.async - end
                        
                        // move to the next dependency
//                        print("[CreateEndpoints] [\(localEndPointType)] process complete: \(self.getName(endpoint: endpointType, objectXML: endPointXML))")
//                        print("[CreateEndpoints] [\(localEndPointType)] dependency \(endpointCurrent): completed \(totalCompleted) of \(endpointCount)")
                        if totalCompleted == endpointCount {
                            if totalFailed == 0 {   // removed  && self.changeColor from if condition
                                self.labelColor(endpoint: endpointType, theColor: self.greenText)
                            } else if totalFailed == endpointCount {
                                self.labelColor(endpoint: endpointType, theColor: self.redText)
                            }
//                            print("[CreateEndpoints] set dependency.wait = false")
                            dependency.wait = false
                        }
                    }
                    completion("create func: \(endpointCurrent) of \(endpointCount) complete.")
                }   // if let httpResponse = response - end
                
                if LogLevel.debug { WriteToLog().message(stringOfText: "[CreateEndpoints] POST or PUT Operation: \(request.httpMethod)\n") }
                
                if endpointCurrent > 0 {
                    if LogLevel.debug { WriteToLog().message(stringOfText: "[CreateEndpoints] endpoint: \(localEndPointType)-\(endpointCurrent)\t Total: \(endpointCount)\t Succeeded: \(self.POSTsuccessCount)\t No Failures: \(self.changeColor)\t SuccessArray \(String(describing: self.progressCountArray["\(localEndPointType)"]!))\n") }
                }
                semaphore.signal()
                if error != nil {
                }
//                print("create func: \(endpointCurrent) of \(endpointCount) complete.  \(self.nodesMigrated) nodes migrated.")
                if endpointCurrent == endpointCount {
//                if totalCompleted == endpointCount {
                    if LogLevel.debug { WriteToLog().message(stringOfText: "[CreateEndpoints] Last item in \(localEndPointType) complete.\n") }
                    self.nodesMigrated+=1    // ;print("added node: \(localEndPointType) - createEndpoints")
//                    print("nodes complete: \(self.nodesMigrated)")
                }
            })
            task.resume()
            semaphore.wait()
            
        }   // theCreateQ.addOperation - end
//        completion("create func: \(endpointCurrent) of \(endpointCount) complete.")
    }   // func createEndpoints - end
    
    func RemoveEndpoints(endpointType: String, endPointID: Int, endpointName: String, endpointCurrent: Int, endpointCount: Int) {
        if LogLevel.debug { WriteToLog().message(stringOfText: "[RemoveEndpoints] enter\n") }
        // this is where we delete the endpoint
        var removeDestUrl = ""
        
        if counters[endpointType] == nil {
            self.counters[endpointType] = ["create":0, "update":0, "fail":0, "total":0]
            self.summaryDict[endpointType] = ["create":[], "update":[], "fail":[]]
        }
        
        // whether the operation was successful or not, either delete or fail
        var methodResult = "create"
//        var methodResult = "delete"
        
        // counters for completed objects
        var totalDeleted   = 0
        var totalFailed    = 0
        var totalCompleted = 0
        
        concurrentThreads = (concurrentThreads > 5) ? 3:concurrentThreads
        theOpQ.maxConcurrentOperationCount = concurrentThreads
        let semaphore = DispatchSemaphore(value: 0)
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
            
            removeDestUrl = "\(self.dest_jp_server_field.stringValue)/JSSResource/" + localEndPointType + "/id/\(endPointID)"
            if LogLevel.debug { WriteToLog().message(stringOfText: "\n[RemoveEndpoints] [CreateEndpoints] raw removal URL: \(removeDestUrl)\n") }
            removeDestUrl = removeDestUrl.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
            removeDestUrl = removeDestUrl.replacingOccurrences(of: "/JSSResource/jamfusers/id", with: "/JSSResource/accounts/userid")
            removeDestUrl = removeDestUrl.replacingOccurrences(of: "/JSSResource/jamfgroups/id", with: "/JSSResource/accounts/groupid")
            removeDestUrl = removeDestUrl.replacingOccurrences(of: "id/id/", with: "id/")
            
            if saveRawXml {
                endPointByID(endpoint: endpointType, endpointID: endPointID, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: "", destEpId: 0, destEpName: endpointName)
            }
            if saveOnly {
                if endpointCurrent == endpointCount {
                    if LogLevel.debug { WriteToLog().message(stringOfText: "[removeEndpoints] Last item in \(localEndPointType) complete.\n") }
                    nodesMigrated+=1    // ;print("added node: \(localEndPointType) - removeEndpoints")
                    //            print("remove nodes complete: \(nodesMigrated)")
                }
                return
            }
            
            theOpQ.addOperation {
                
                DispatchQueue.main.async {
                    // look to see if we are processing the next endpointType - start
                    if self.endpointInProgress != endpointType || self.endpointInProgress == "" {
                        self.endpointInProgress = endpointType
                        self.changeColor = true
                        self.POSTsuccessCount = 0
                        WriteToLog().message(stringOfText: "[RemoveEndpoints] Removing \(endpointType)\n")
                    }   // look to see if we are processing the next endpointType - end
                }

                if LogLevel.debug { WriteToLog().message(stringOfText: "[RemoveEndpoints] removing \(endpointType) with ID \(endPointID)  -  Object \(endpointCurrent) of \(endpointCount)\n") }
                if LogLevel.debug { WriteToLog().message(stringOfText: "\n[RemoveEndpoints] removal URL: \(removeDestUrl)\n") }
                
                let encodedURL = NSURL(string: removeDestUrl)
                let request = NSMutableURLRequest(url: encodedURL! as URL)
                request.httpMethod = "DELETE"
                let configuration = URLSessionConfiguration.default
                configuration.httpAdditionalHeaders = ["Authorization" : "Basic \(self.destBase64Creds)", "Content-Type" : "text/xml", "Accept" : "text/xml"]
                //request.httpBody = encodedXML!
                let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
                let task = session.dataTask(with: request as URLRequest, completionHandler: {
                    (data, response, error) -> Void in
                    if let httpResponse = response as? HTTPURLResponse {
                        //print(httpResponse.statusCode)
                        //print(httpResponse)
                        if httpResponse.statusCode >= 199 && httpResponse.statusCode <= 299 {
                            // remove items from the list as they are removed from the server
                            if self.activeTab() == "selective" {
                                let lineNumber = self.availableIdsToDelArray.firstIndex(of: endPointID)!
                                
                                DispatchQueue.main.async {
                                    self.srcSrvTableView.beginUpdates()
                                    self.srcSrvTableView.removeRows(at: IndexSet(integer: lineNumber), withAnimation: .effectFade)
                                    self.srcSrvTableView.endUpdates()
                                    self.availableIdsToDelArray.remove(at: lineNumber)
                                    self.sourceDataArray.remove(at: lineNumber)
                                    self.srcSrvTableView.isEnabled = false
                                }
                            }
                            
                            WriteToLog().message(stringOfText: "    [RemoveEndpoints] [\(endpointType)] \(endpointName)\n")
                            self.POSTsuccessCount += 1
//                            if endpointCount == endpointCurrent && self.changeColor {
//                                self.labelColor(endpoint: endpointType, theColor: self.greenText)
//                            }
                        } else {
                            methodResult = "fail"
                            self.labelColor(endpoint: endpointType, theColor: self.yellowText)
                            self.changeColor = false
                            WriteToLog().message(stringOfText: "    [RemoveEndpoints] [\(endpointType)] **** Failed to remove: \(endpointName)\n")
                            if httpResponse.statusCode == 400 {
                                WriteToLog().message(stringOfText: "    [RemoveEndpoints] [\(endpointType)] **** Verify other items are not dependent on \(endpointName)\n")
                                WriteToLog().message(stringOfText: "    [RemoveEndpoints] [\(endpointType)] **** For example, \(endpointName) is not used in a policy\n")
                            }
                            
                            if LogLevel.debug { WriteToLog().message(stringOfText: "\n\n") }
                            if LogLevel.debug { WriteToLog().message(stringOfText: "[RemoveEndpoints] ---------- endpoint info ----------\n") }
                            if LogLevel.debug { WriteToLog().message(stringOfText: "[RemoveEndpoints] Type: \(endpointType)\t Name: \(endpointName)\t ID: \(endPointID)\n") }
                            if LogLevel.debug { WriteToLog().message(stringOfText: "[RemoveEndpoints] ---------- status code ----------\n") }
                            if LogLevel.debug { WriteToLog().message(stringOfText: "[RemoveEndpoints] \(httpResponse.statusCode)\n") }
                            if LogLevel.debug { WriteToLog().message(stringOfText: "[RemoveEndpoints] ---------- response ----------\n") }
                            if LogLevel.debug { WriteToLog().message(stringOfText: "[RemoveEndpoints] \(httpResponse)\n") }
                            if LogLevel.debug { WriteToLog().message(stringOfText: "[RemoveEndpoints] ---------- response ----------\n\n") }
                        }
                        

                        // update global counters
                        let localTmp = (self.counters[endpointType]?[methodResult])!
                        self.counters[endpointType]?[methodResult] = localTmp + 1
                        if var summaryArray = self.summaryDict[endpointType]?[methodResult] {
                            summaryArray.append(endpointName)
                            self.summaryDict[endpointType]?[methodResult] = summaryArray
                        }
                        
                        totalDeleted   = self.counters[endpointType]!["create"]!
                        totalFailed    = self.counters[endpointType]!["fail"]!
                        totalCompleted = totalDeleted + totalFailed

                        DispatchQueue.main.async {
                            self.object_name_field.stringValue       = "\(endpointType)"
                            let currentCompleted = Int(self.objects_completed_field!.stringValue) ?? 0
//                            if endpointCurrent > currentCompleted || (endpointCurrent < 4 && endpointCurrent > 0) {
                            if totalCompleted > 0 {
                                self.objects_completed_field.stringValue = "\(totalCompleted)"
                            }
                            self.objects_found_field.stringValue     = "\(endpointCount)"
                            
                            if totalDeleted == endpointCount && self.changeColor {
                                self.labelColor(endpoint: endpointType, theColor: self.greenText)
                            } else if totalFailed == endpointCount {
                                self.labelColor(endpoint: endpointType, theColor: self.redText)
                            }
                            
                        }
                        
                    }
                    if self.activeTab() != "selective" {
//                        print("localEndPointType: \(localEndPointType) \t count: \(endpointCount)")
                        if self.objectsToMigrate.last == localEndPointType && (endpointCount == endpointCurrent || endpointCount == 0) {
                            // check for file that allows deleting data from destination server, delete if found - start
                            self.rmDELETE()
                            print("[removeEndpoints] endpoint: \(endpointType)")
                            self.resetAllCheckboxes()
                            // check for file that allows deleting data from destination server, delete if found - end
                            //self.go_button.isEnabled = true
                            self.goButtonEnabled(button_status: true)
                            if LogLevel.debug { WriteToLog().message(stringOfText: "Done\n") }
                        }
                        semaphore.signal()
                        if error != nil {
                        }
                    } else {
                        if LogLevel.debug { WriteToLog().message(stringOfText: "\n[RemoveEndpoints] endpointCount: \(endpointCount)\t endpointCurrent: \(endpointCurrent)\n") }
                        
                        if endpointCount == endpointCurrent {
                            // check for file that allows deleting data from destination server, delete if found - start
                            self.rmDELETE()
                            print("[removeEndpoints] endpoint: \(endpointType)")
                            self.resetAllCheckboxes()
                            // check for file that allows deleting data from destination server, delete if found - end
                            //self.go_button.isEnabled = true
                            self.goButtonEnabled(button_status: true)
                            if LogLevel.debug { WriteToLog().message(stringOfText: "Done\n") }
                        }
                        semaphore.signal()
                    }
                })  // let task = session.dataTask - end
                task.resume()
                semaphore.wait()
            }   // theOpQ.addOperation - end
        }
        if endpointCurrent == endpointCount {
            if LogLevel.debug { WriteToLog().message(stringOfText: "[removeEndpoints] Last item in \(localEndPointType) complete.\n") }
            nodesMigrated+=1    // ;print("added node: \(localEndPointType) - removeEndpoints")
            //            print("remove nodes complete: \(nodesMigrated)")
        }
    }   // func removeEndpoints - end
    
    func existingEndpoints(theDestEndpoint: String, completion: @escaping (_ result: String) -> Void) {
        
        if LogLevel.debug { WriteToLog().message(stringOfText: "[existingEndpoints] enter\n") }
        
        if !saveOnly {
            URLCache.shared.removeAllCachedResponses()
            currentEPs.removeAll()
            currentEPDict.removeAll()
            
            var destEndpoint         = theDestEndpoint
            var existingDestUrl      = ""
            var destXmlName          = ""
            var destXmlID:Int?
            var existingEndpointNode = ""
            var een                  = ""

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
            default:
                existingEndpointNode = destEndpoint
            }
            
    //        print("\nGetting existing endpoints: \(existingEndpointNode)\n")
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
            case "computerconfigurations":
                endpointParent = "computer_configurations"
            case "diskencryptionconfigurations":
                endpointParent = "disk_encryption_configurations"
            case "distributionpoints":
                endpointParent = "distribution_points"
            case "directorybindings":
                endpointParent = "directory_bindings"
            case "dockitems":
                endpointParent = "dock_items"
            case "netbootservers":
                endpointParent = "netboot_servers"
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
            
            var endpointDependendyArray = ordered_dependency_array
            var completed               = 0
            var waiting                 = false
            
            switch endpointParent {
            case "policies":
                endpointDependendyArray.append(existingEndpointNode)
            default:
                endpointDependendyArray = ["\(existingEndpointNode)"]
            }
            
            let semaphore = DispatchSemaphore(value: 1)
            destEPQ.async {
                while (completed < endpointDependendyArray.count) {
//                    print("[\(endpointParent)] completed \(completed) of \(endpointDependendyArray.count)")
                    usleep(10)
                    if !waiting {
                        URLCache.shared.removeAllCachedResponses()
                        waiting = true
                        existingEndpointNode = endpointDependendyArray[completed]
                        existingDestUrl = "\(self.dest_jp_server)/JSSResource/\(existingEndpointNode)"
                        existingDestUrl = existingDestUrl.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
//                        print("existing endpoints URL: \(existingDestUrl)")
                        let destEncodedURL = NSURL(string: existingDestUrl)
                        let destRequest = NSMutableURLRequest(url: destEncodedURL! as URL)
                        
                        destRequest.httpMethod = "GET"
                        let destConf = URLSessionConfiguration.default
                        destConf.httpAdditionalHeaders = ["Authorization" : "Basic \(self.destBase64Creds)", "Content-Type" : "application/json", "Accept" : "application/json"]
                        let destSession = Foundation.URLSession(configuration: destConf, delegate: self, delegateQueue: OperationQueue.main)
                        let task = destSession.dataTask(with: destRequest as URLRequest, completionHandler: {
                            (data, response, error) -> Void in
                            if let httpResponse = response as? HTTPURLResponse {
//                                print("httpResponse: \(String(describing: response))!")
                                do {
                                    let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                                    if let destEndpointJSON = json as? [String: Any] {
//                                        print("destEndpointJSON: \(destEndpointJSON)")
                                        if LogLevel.debug { WriteToLog().message(stringOfText: "[existingEndpoints]  --------------- Getting all \(destEndpoint) ---------------\n") }
                                        if LogLevel.debug { WriteToLog().message(stringOfText: "[existingEndpoints] existing destEndpointJSON: \(destEndpointJSON))\n") }
                                        switch destEndpoint {
                                            
                                        // need to revisit as name isn't the best indicatory on whether or not a computer exists
                                        case "-computers":
                                            if LogLevel.debug { WriteToLog().message(stringOfText: "[existingEndpoints] getting current computers\n") }
                                            if let destEndpointInfo = destEndpointJSON["computers"] as? [Any] {
                                                let destEndpointCount: Int = destEndpointInfo.count
                                                if LogLevel.debug { WriteToLog().message(stringOfText: "[existingEndpoints] existing \(destEndpoint) found: \(destEndpointCount)\n") }
                                                if LogLevel.debug { WriteToLog().message(stringOfText: "[existingEndpoints] destEndpointInfo: \(destEndpointInfo)\n") }
                                                
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
                                            
                                        default:
                                            if destEndpoint == "jamfusers" || destEndpoint == "jamfgroups" { // || destEndpoint == "jamfusers" || destEndpoint == "jamfgroups"
                                                let accountsDict = destEndpointJSON as Dictionary<String, Any>
                                                let usersGroups = accountsDict["accounts"] as! Dictionary<String, Any>
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
                                                
//
                                            }
                                            if LogLevel.debug { WriteToLog().message(stringOfText: "[existingEndpoints] getting current \(existingEndpointNode) on destination server\n") }
                                            if let destEndpointInfo = destEndpointDict as? [Any] {
                                                let destEndpointCount: Int = destEndpointInfo.count
                                                if LogLevel.debug { WriteToLog().message(stringOfText: "[existingEndpoints] existing \(existingEndpointNode) found: \(destEndpointCount) on destination server\n") }
                                                
                                                if destEndpointCount > 0 {
                                                    for i in (0..<destEndpointCount) {
                                                        
                                                        let destRecord = destEndpointInfo[i] as! [String : AnyObject]
                                                        if LogLevel.debug { WriteToLog().message(stringOfText: "[existingEndpoints] Processing: \(destRecord).\n") }
                                                        destXmlID = (destRecord["id"] as! Int)
        //                                                    if destEndpoint != "mobiledeviceapplications" {
                                                                if destRecord["name"] != nil {
                                                                    destXmlName = destRecord["name"] as! String
                                                                } else {
                                                                    destXmlName = ""
                                                                }
        //                                                    } else {
        //                                                        destXmlName = destRecord["bundle_id"] as! String
        //                                                    }
                                                            if destXmlName != "" {
                                                                if "\(String(describing: destXmlID))" != "" {
                                                                    if LogLevel.debug { WriteToLog().message(stringOfText: "[existingEndpoints] adding \(destXmlName) (id: \(String(describing: destXmlID!))) to currentEP array.\n") }
                                                                    
                                                                    // filter out policies created from casper remote - start
                                                                        if destXmlName.range(of:"[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] at", options: .regularExpression) == nil && destXmlName != "Update Inventory" {
                                                                            self.currentEPs[destXmlName] = destXmlID
                                                                        }
                                                                    // filter out policies created from casper remote - end
                                                                    
                                                                    if LogLevel.debug { WriteToLog().message(stringOfText: "[existingEndpoints]    Array has \(self.currentEPs.count) entries.\n") }
                                                                } else {
                                                                    if LogLevel.debug { WriteToLog().message(stringOfText: "[existingEndpoints] skipping object: \(destXmlName), could not determine its id.\n") }
                                                                }
                                                            } else {
                                                                if LogLevel.debug { WriteToLog().message(stringOfText: "[existingEndpoints] skipping id: \(String(describing: destXmlID)), could not determine its name.\n") }
                                                            }
                                                        
                                                    }   // for i in (0..<destEndpointCount) - end
                                                } else {   // if destEndpointCount > 0 - end
                                                    self.currentEPs.removeAll()
                                                }
                                                
//                                                print("\n[existingEndpoints] endpointParent: \(endpointParent)\n")
                                                switch endpointParent {
                                                case "policies":
                                                    self.currentEPDict[existingEndpointNode] = self.currentEPs
//                                                    print("[existingEndpoints] currentEPDict[\(existingEndpointNode)]: \(self.currentEPDict[existingEndpointNode]!)")
                                                default:
                                                    self.currentEPDict[destEndpoint] = self.currentEPs
//                                                    print("[existingEndpoints] currentEPDict[\(destEndpoint)]: \(self.currentEPDict[destEndpoint]!)")
                                                }
//                                                self.currentEPDict[existingEndpointNode] = self.currentEPs
                                                self.currentEPs.removeAll()
                                            }   // if let destEndpointInfo - end
                                        }   // switch - end
                                    } else {
                                        self.currentEPs.removeAll()
                                        completion("error parsing JSON")
                                    }   // if let destEndpointJSON - end
                                    
                                }   // end do/catch
                                
                                completed += 1
                                waiting = (completed < endpointDependendyArray.count) ? false:true
//                                print("completed: \(completed) of \(endpointDependendyArray.count) (\(existingEndpointNode))")
                                
                                if httpResponse.statusCode > 199 && httpResponse.statusCode <= 299 {
//                                    print(httpResponse.statusCode)
                                    if LogLevel.debug { WriteToLog().message(stringOfText: "[existingEndpoints] returning existing \(existingEndpointNode) endpoints: \(self.currentEPs)\n") }
        //                            print("returning existing endpoints: \(self.currentEPs)")
                                    if completed == endpointDependendyArray.count {
                                        if endpointParent == "ldap_servers" {
                                            self.currentLDAPServers = self.currentEPDict[destEndpoint]!
//                                            print("[existingEndpoints-LDAP] currentLDAPServers: \(String(describing: self.currentLDAPServers))")
                                        }
//                                        print("[existingEndpoints] currentEPDict[]: \(String(describing: self.currentEPDict))")
                                        self.currentEPs = self.currentEPDict[destEndpoint]!
                                        completion("\n[existingEndpoints] Current endpoints - \(self.currentEPs)")
                                    }
                                } else {
                                    // something went wrong
                                    if completed == endpointDependendyArray.count {
                                        print("currentEPDict[] - error: \(String(describing: self.currentEPDict))")
                                        self.currentEPs = self.currentEPDict[destEndpoint]!
                                        completion("\ndestination count error")
                                    }
                                    
                                }   // if httpResponse/else - end
                                
                            }   // if let httpResponse - end
                            semaphore.signal()
                            if error != nil {
                            }
                        })  // let task = destSession - end
                        //print("GET")
                        task.resume()
                    }   //for currentDependency in endpointDependendyArray - end
                }
//                print("[\(endpointParent)] completed \(completed) of \(endpointDependendyArray.count)")
            }   // destEPQ - end
        } else {
            self.currentEPs["_"] = 0
            completion(" Current endpoints - saveOnly, not needed.")
        }
    }

    func getDependencies(object: String, json: [String:AnyObject]) -> Dictionary<String, [String:String]> {
        if LogLevel.debug { WriteToLog().message(stringOfText: "[getDependencies] enter\n") }
        var objectDict         = [String:Any]()
        var fullDependencyDict = Dictionary<String, [String:String]>()
        var dependencyArray    = [String:String]()
        var dependencyNode     = ""
        
        switch object {
        case "policy":
            objectDict      = json[object] as! [String:Any]
            let general     = objectDict["general"] as! [String:Any]
            let bindings    = objectDict["account_maintenance"] as! [String:Any]
            let scope       = objectDict["scope"] as! [String:Any]
            let scripts     = objectDict["scripts"] as! [[String:Any]]
            let packages    = objectDict["package_configuration"] as! [String:Any]
            let exclusions  = scope["exclusions"] as! [String:Any]
            let limitations = scope["limitations"] as! [String:Any]
            
            for the_dependency in ordered_dependency_array {

                switch the_dependency {
                case "cagtegories":
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
                    if let _ = scope[dependencyNode] {
                        let scope_dep = scope[dependencyNode] as! [AnyObject]
                        for theObject in scope_dep {
                            let local_name = (theObject as! [String:Any])["name"]
                            let local_id   = (theObject as! [String:Any])["id"]
                            dependencyArray["\(local_name!)"] = "\(local_id!)"
                        }
                    }
                    
                    if let _ = exclusions[dependencyNode] {
                        let scope_excl_dep = exclusions[dependencyNode] as! [AnyObject]
                        for theObject in scope_excl_dep {
                            let local_name = (theObject as! [String:Any])["name"]
                            let local_id   = (theObject as! [String:Any])["id"]
                            dependencyArray["\(local_name!)"] = "\(local_id!)"
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
                     for theObject in packages_dep {
                         let local_name = (theObject as! [String:Any])["name"]
                         let local_id   = (theObject as! [String:Any])["id"]
                         dependencyArray["\(local_name!)"] = "\(local_id!)"
                     }
                 }

                 case "printers":
                 let jsonPrinterArray = objectDict[dependencyNode] as! [Any]
                 for i in 0..<jsonPrinterArray.count {
                    if "\(jsonPrinterArray[i])" != "" {
                        let scope_item = jsonPrinterArray[i] as! Dictionary<String,Any>

                        let local_name = scope_item["name"]
                        let local_id   = scope_item["id"]
//                        for theObject in scope_item {
//                            let local_name = (theObject as! [String:Any])["name"]
//                            let local_id   = (theObject as! [String:Any])["id"]
                            dependencyArray["\(local_name!)"] = "\(local_id!)"
//                        }
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
                
                fullDependencyDict[the_dependency] = dependencyArray
//              print("fullDependencyDict[\(the_dependency)]: \(fullDependencyDict[the_dependency]!)")
            }

        default:
            if LogLevel.debug { WriteToLog().message(stringOfText: "[getDependencies] not implemented for \(object).\n") }
            print("[getDependencies] not implemented for \(object)")
        }
        if LogLevel.debug { WriteToLog().message(stringOfText: "[getDependencies] exit\n") }
        return fullDependencyDict
    }
    
    func nameIdDict(server: String, endPoint: String, id: String, completion: @escaping (_ result: [String:Dictionary<String,Int>]) -> Void) {
        // matches the id to name of objects in a configuration (imaging)
        if LogLevel.debug { WriteToLog().message(stringOfText: "[nameIdDict] start matching \(endPoint) (by name) that exist on both servers\n") }
        URLCache.shared.removeAllCachedResponses()
        var serverUrl     = "\(server)/JSSResource/\(endPoint)"
        serverUrl         = serverUrl.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
        var recordName    = ""
        var endpointCount = 0
        
        var serverCreds = ""
        let serverConf = URLSessionConfiguration.default
        if id == "sourceId" {
            serverCreds = self.sourceBase64Creds
        } else {
            serverCreds = self.destBase64Creds
        }
        
        let serverEncodedURL = NSURL(string: serverUrl)
        let serverRequest = NSMutableURLRequest(url: serverEncodedURL! as URL)
        
        let semaphore = DispatchSemaphore(value: 1)
        idMapQ.async {
            
            serverRequest.httpMethod = "GET"
            serverConf.httpAdditionalHeaders = ["Authorization" : "Basic \(serverCreds)", "Content-Type" : "application/json", "Accept" : "application/json"]
            let serverSession = Foundation.URLSession(configuration: serverConf, delegate: self, delegateQueue: OperationQueue.main)
            let task = serverSession.dataTask(with: serverRequest as URLRequest, completionHandler: {
                (data, response, error) -> Void in
                if let httpResponse = response as? HTTPURLResponse {
                    let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                    if let endpointJSON = json as? [String: Any] {
                        
                        if let endpointInfo = endpointJSON[self.endpointDefDict[endPoint]!] as? [Any] {
                            endpointCount = endpointInfo.count
                            
                            if endpointCount > 0 {
                                for i in (0..<endpointCount) {
                                    let record = endpointInfo[i] as! [String : AnyObject]
                                    let recordId = (record["id"] != nil) ? record["id"] as? Int:0
//                                    print("[nameIdDict] record: \(record ) \t recordId: \(recordId!)")
                                    
                                    if endPoint == "computerconfigurations" {
                                        self.configInfo(server: "\(server)", endPoint: "computerconfigurations", recordId: recordId!) {
                                            (result: Dictionary<String,Dictionary<String,String>>) in
                                            //                                            print("ordered config IDs: \(result)")
                                        }
                                        
                                    } else {
                                        recordName = record["name"] as! String
                                        if self.idDict[recordName]?.count == nil || recordId == 0 {
                                            self.idDict[recordName] = ["sourceId":0, "destId":0]
                                            WriteToLog().message(stringOfText: "[nameIdDict] \(String(describing: recordName)): new object.\n")
                                        }
                                        self.idDict[recordName]?[id] = recordId
                                        if LogLevel.debug {
                                            WriteToLog().message(stringOfText: "[nameIdDict] \(String(describing: recordName)): existing object.\n")
                                            WriteToLog().message(stringOfText: "[nameIdDict] \(String(describing: self.idDict[recordName]!)) ID matching dictionary :\n")
                                    }

                                }   // for i in (0..<endpointCount) end
                                }
                                
                            }   //if endpointCount > 0 - end
                        }   // if let endpointInfo = endpointJSON - end
                    }   // if let serverEndpointJSON - end
                    
                    if httpResponse.statusCode >= 199 && httpResponse.statusCode <= 299 {
                        completion(self.idDict)
                    } else {
                        // something went wrong
//                        print("[nameIdDict] status code: \(httpResponse.statusCode)")
                        completion([:])
                        
                    }   // if httpResponse/else - end
                }   // if let httpResponse - end
                semaphore.signal()
                if error != nil {
                }
            })  // let task = destSession - end
            task.resume()
        }   // idMapQ - end
    }   // func nameIdDict - end
    
    func configInfo(server: String, endPoint: String, recordId: Int, completion: @escaping (_ result: Dictionary<String,Dictionary<String,String>>) -> Void) {
        URLCache.shared.removeAllCachedResponses()
        
        var serverUrl = "\(server)/JSSResource/\(endPoint)/id/\(recordId)"
        serverUrl = serverUrl.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
        
        let serverEncodedURL = NSURL(string: serverUrl)
        let serverRequest = NSMutableURLRequest(url: serverEncodedURL! as URL)

        let semaphore = DispatchSemaphore(value: 0)
        idMapQ.async {
            
            serverRequest.httpMethod = "GET"
            let serverConf = URLSessionConfiguration.default
            serverConf.httpAdditionalHeaders = ["Authorization" : "Basic \(self.sourceBase64Creds)", "Content-Type" : "application/json", "Accept" : "application/json"]
            let serverSession = Foundation.URLSession(configuration: serverConf, delegate: self, delegateQueue: OperationQueue.main)
            let task = serverSession.dataTask(with: serverRequest as URLRequest, completionHandler: {
                (data, response, error) -> Void in
                if let httpResponse = response as? HTTPURLResponse {
                    let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                    if let endpointJSON = json as? [String: Any] {
                        
                        let endpointInfo = endpointJSON["computer_configuration"] as! [String:Any]
                        let record = endpointInfo["general"] as! [String:Any]
                        let configName = record["name"] as? String
                        self.configObjectsDict[configName!] = [:]
                        self.configObjectsDict[configName!]?["id"] = "\(recordId)"
                        self.configObjectsDict[configName!]?["type"] = record["type"] as? String
                        if self.configObjectsDict[configName!]?["type"] == "Smart" {
                            self.configObjectsDict[configName!]?["parent"] = record["parent"] as? String
                        } else {
                            self.configObjectsDict[configName!]?["parent"] = ""
                        }
                    }   // if let endpointInfo = endpointJSON - end
                    
                    if httpResponse.statusCode >= 199 && httpResponse.statusCode <= 299 {
//                      print(httpResponse.statusCode)
//                        print("\nconfig \(recordId): \(self.configObjectsDict)\n")
                        completion(self.configObjectsDict)
                    } else {
                        // something went wrong
//                        print("[configInfo] status code: \(httpResponse.statusCode)")
                        completion([:])
                        
                    }   // if httpResponse/else - end
                }   // if let httpResponse - end
                semaphore.signal()
                if error != nil {
                }
            })  // let task = destSession - end
            task.resume()
        }   // theOpQ - end
    }
    
    @IBAction func migrateToSite(_ sender: Any) {
        if siteMigrate.state.rawValue == 1 {
            itemToSite = true
            availableSites_button.removeAllItems()

            DispatchQueue.main.async {
                self.siteMigrate.isEnabled = false
                self.sitesSpinner_ProgressIndicator.startAnimation(self)
            }
            
            Sites().fetch(server: "\(dest_jp_server_field.stringValue)", creds: "\(dest_user_field.stringValue):\(dest_pwd_field.stringValue)") {
                (result: [String]) in
                let destSitesArray = result
                if destSitesArray.count == 0 {self.destinationLabel_TextField.stringValue = "Site Name"
                    // no sites found - allow migration from a site to none
                    self.availableSites_button.addItems(withTitles: ["None"])
                    self.availableSites_button.isEnabled = true
//                    self.alert_dialog(header: "Attention", message: "No sites were found or the server cound not be queried.")
//                    self.siteMigrate.state = NSControl.StateValue(rawValue: 0) // or convertToNSControlStateValue(0)
//                    self.itemToSite = false
//                    return
                }
                    self.destinationLabel_TextField.stringValue = "Site Name"
                    self.availableSites_button.addItems(withTitles: ["None"])
                    for theSite in destSitesArray {
                        self.availableSites_button.addItems(withTitles: [theSite])
                    }
                    self.availableSites_button.isEnabled = true
                    
                    DispatchQueue.main.async {
                        self.sitesSpinner_ProgressIndicator.stopAnimation(self)
                        self.siteMigrate.isEnabled = true
                    }
            }
            
        } else {
            destinationLabel_TextField.stringValue = "Destination"
            self.availableSites_button.isEnabled = false
            destinationSite = ""
            itemToSite = false
            DispatchQueue.main.async {
                self.sitesSpinner_ProgressIndicator.stopAnimation(self)
                self.siteMigrate.isEnabled = true
            }
        }
        
    }

    //==================================== Utility functions ====================================
    
    func activeTab() -> String {
        var activeTab = ""
        if macOS_tabViewItem.tabState.rawValue == 0 {
            activeTab =  "macOS"
        } else if iOS_tabViewItem.tabState.rawValue == 0 {
            activeTab = "iOS"
        } else if selective_tabViewItem.tabState.rawValue == 0 {
            activeTab = "selective"
        }
        if LogLevel.debug { WriteToLog().message(stringOfText: "Active tab: \(activeTab)\n") }
        return activeTab
    }
    
    func alert_dialog(header: String, message: String) {
        let dialog: NSAlert = NSAlert()
        dialog.messageText = header
        dialog.informativeText = message
        dialog.alertStyle = NSAlert.Style.warning
        dialog.addButton(withTitle: "OK")
        dialog.runModal()
        //return true
    }   // func alert_dialog - end
    
    func checkURL2(whichServer: String, serverURL: String, completion: @escaping (Bool) -> Void) {
//        print("enter checkURL2")
        if (whichServer == "dest" && saveOnly) {
            completion(true)
        } else {
            var available:Bool = false
            if LogLevel.debug { WriteToLog().message(stringOfText: "[checkURL2] --- checking availability of server: \(serverURL)\n") }
        
            authQ.sync {
                if LogLevel.debug { WriteToLog().message(stringOfText: "[checkURL2] checking: \(serverURL)\n") }

                guard let encodedURL = URL(string: serverURL) else {
                    if LogLevel.debug { WriteToLog().message(stringOfText: "[checkURL2] --- Cannot cast to URL: \(serverURL)\n") }
                    completion(false)
                    return
                }
                let configuration = URLSessionConfiguration.default

                if LogLevel.debug { WriteToLog().message(stringOfText: "[checkURL2] --- checking healthCheck page.\n") }
                var request = URLRequest(url: encodedURL.appendingPathComponent("/healthCheck.html"))
                request.httpMethod = "GET"

                let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
                let task = session.dataTask(with: request as URLRequest, completionHandler: {
                    (data, response, error) -> Void in
                    if let httpResponse = response as? HTTPURLResponse {
                        if LogLevel.debug { WriteToLog().message(stringOfText: "[checkURL2] Server check: \(serverURL), httpResponse: \(httpResponse.statusCode)\n") }
                        
                        //                    print("response: \(response)")
                        if let responseData = String(data: data!, encoding: .utf8) {
                            if LogLevel.debug { WriteToLog().message(stringOfText: "[checkURL2] checkURL2 data: \(responseData)") }
                        } else {
                            if LogLevel.debug { WriteToLog().message(stringOfText: "[checkURL2] checkURL2 data: none") }
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
    
    func clearProcessingFields() {
        DispatchQueue.main.async {
            self.get_name_field.stringValue             = ""
            self.get_completed_field.stringValue        = ""
            self.get_found_field.stringValue            = ""
            self.object_name_field.stringValue          = ""
            self.objects_completed_field.stringValue    = ""
            self.objects_found_field.stringValue        = ""
        }
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
    
    func disable(theXML: String) -> String {
        let regexDisable    = try? NSRegularExpression(pattern: "<enabled>true</enabled>", options:.caseInsensitive)
        let newXML          = (regexDisable?.stringByReplacingMatches(in: theXML, options: [], range: NSRange(0..<theXML.utf16.count), withTemplate: "<enabled>false</enabled>"))!
  
        return newXML
    }
    
    func fetchPassword(whichServer: String, url: String, theUser: String) {
        let regexKey        = try! NSRegularExpression(pattern: "http(.*?)://", options:.caseInsensitive)
        let credKey         = regexKey.stringByReplacingMatches(in: url, options: [], range: NSRange(0..<url.utf16.count), withTemplate: "")
        let credentailArray  = Creds2.retrieve(service: "migrator - "+credKey)
        
        if credentailArray.count == 2 {
            if whichServer == "source" {
                if (url != "") {
                    source_user_field.stringValue = credentailArray[0]
                    source_pwd_field.stringValue = credentailArray[1]
                    self.storedSourceUser = credentailArray[0]
                }
            } else {
                if (url != "") {
                    dest_user_field.stringValue = credentailArray[0]
                    dest_pwd_field.stringValue = credentailArray[1]
                    self.storedDestUser = credentailArray[0]
                } else {
                    dest_pwd_field.stringValue = ""
                    if source_pwd_field.stringValue != "" {
                        dest_pwd_field.becomeFirstResponder()
                    }
                }
            }   // if whichServer - end
        } else {
            // credentials not found - blank out username / password fields
            if whichServer == "source" {
                source_user_field.stringValue = ""
                source_pwd_field.stringValue = ""
                self.storedSourceUser = ""
                source_user_field.becomeFirstResponder()
            } else {
                dest_user_field.stringValue = ""
                dest_pwd_field.stringValue = ""
                self.storedSourceUser = ""
                dest_user_field.becomeFirstResponder()
            }
        }
    }
    
    func goButtonEnabled(button_status: Bool) {
        var local_button_status = button_status
        DispatchQueue.main.async {
            self.theSpinnerQ.async {
                var theImageNo = 0
                if !local_button_status {
                    repeat {
                        DispatchQueue.main.async {
                            self.mySpinner_ImageView.image = self.theImage[theImageNo]
                            theImageNo += 1
                            if theImageNo > 2 {
                                theImageNo = 0
                            }
                            if self.theCreateQ.operationCount == 0 && self.theOpQ.operationCount == 0 && self.nodesMigrated >= self.objectsToMigrate.count && self.objectsToMigrate.count != 0  {
                                self.goButtonEnabled(button_status: true)
                                local_button_status = true
//                                print("go button enabled")
                            }
                        }
                        usleep(300000)  // sleep 0.3 seconds
                    } while !local_button_status  // while !button_status - end
                }   // self.theSpinnerQ.async - end
            }   // DispatchQueue.main.async  -end
            self.mySpinner_ImageView.isHidden = button_status
            self.stop_button.isHidden = button_status
            self.go_button.isEnabled = button_status
        }
        
//        print("button_status: \(button_status)")
        if button_status {
            // display summary of created, updated, and failed objects
            if counters.count > 0 {
//                print("summary:\n\(counters)")
//                print("summary dict:\n\(summaryDict)")
                // clear objects in selective field
                DispatchQueue.main.async {
                    if wipeData.on && self.srcSrvTableView.isEnabled == true {
    //                        self.sourceDataArray.removeAll()
                            self.srcSrvTableView.stringValue = ""
                            self.srcSrvTableView.reloadData()
                    }
                }
            }
        } else {
            // clear previous results
            counters.removeAll()
        }
    }
    
    @IBAction func stopButton(_ sender: Any) {
        WriteToLog().message(stringOfText: "Migration was manually stopped.\n\n")
        readFilesQ.cancelAllOperations()
        theOpQ.cancelAllOperations()
        theCreateQ.cancelAllOperations()
        goButtonEnabled(button_status: true)
    }
    
    func getCurrentTime() -> String {
        let current = Date()
        let localCalendar = Calendar.current
        let dateObjects: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
        let dateTime = localCalendar.dateComponents(dateObjects, from: current)
        let currentMonth  = leadingZero(value: dateTime.month!)
        let currentDay    = leadingZero(value: dateTime.day!)
        let currentHour   = leadingZero(value: dateTime.hour!)
        let currentMinute = leadingZero(value: dateTime.minute!)
        let currentSecond = leadingZero(value: dateTime.second!)
        let stringDate = "\(dateTime.year!)\(currentMonth)\(currentDay)_\(currentHour)\(currentMinute)\(currentSecond)"
        return stringDate
    }
    
    // add leading zero to single digit integers
    func leadingZero(value: Int) -> String {
        var formattedValue = ""
        if value < 10 {
            formattedValue = "0\(value)"
        } else {
            formattedValue = "\(value)"
        }
        return formattedValue
    }
    
    // scale the delay when listing items with selective migrations based on the number of items
    func listDelay(itemCount: Int) -> UInt32 {
        let delayFactor = (itemCount < 10) ? 10:itemCount
        
        let factor = (5000000/delayFactor)
        if factor > 50000 {
            return 50000
        } else {
            return UInt32(factor)
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
    
    func getStatusUpdate(endpoint: String, current: Int, total: Int) {
        DispatchQueue.main.async {
            self.get_name_field.stringValue = endpoint
            if current > 0 {
                self.get_completed_field.stringValue = "\(current)"
            }
            self.get_found_field.stringValue = "\(total)"
        }
    }
    
    func icons(endpointType: String, action: String, ssIconName: String, ssIconId: Int, ssIconUri: String, f_createDestUrl: String, responseData: String) {
        var curlResult    = ""
        var curlResult2   = ""
        var createDestUrl = f_createDestUrl
        var iconToUpload  = ""
        var action        = "GET"
        
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
            //                                print("new policy id: \(self.tagValue(xmlString: responseData, xmlTag: "id"))")
            //                                    print("iconName: "+ssIconName+"\tURL: \(ssIconUri)")
            createDestUrl = "\(self.createDestUrlBase)/fileuploads/\(iconNode)/id/\(self.tagValue(xmlString: responseData, xmlTag: "id"))"
            createDestUrl = createDestUrl.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
            
            if fileImport {
                action       = "SKIP"
                iconToUpload = NSHomeDirectory() + "/Documents/Jamf Migrator/raw/\(iconNodeSave)/\(ssIconId)/\(ssIconName)"
            }
            
            // Get or skip icon from Jamf Pro
            if LogLevel.debug { WriteToLog().message(stringOfText: "[CreateEndpoints] before icon download.\n") }
            iconMigrate(action: action, ssIconUri: ssIconUri, ssIconName: ssIconName, iconToUpload: "", createDestUrl: "") {
                (result: Int) in
                if LogLevel.debug { WriteToLog().message(stringOfText: "[CreateEndpoints] after icon download.\n") }
                if result > 199 && result < 300 {
                    iconToUpload = "\(NSHomeDirectory())/Library/Caches/\(ssIconName)"
                    if LogLevel.debug { WriteToLog().message(stringOfText: "[CreateEndpoints] retrieved icon from \(ssIconUri)\n") }
                    if self.saveRawXml {
                        if LogLevel.debug { WriteToLog().message(stringOfText: "[icons] Saving icon id: \(ssIconName) for \(iconNode).\n") }
                        DispatchQueue.main.async {
                            Xml().save(node: iconNodeSave, xml: "\(NSHomeDirectory())/Library/Caches/\(ssIconName)", name: ssIconName, id: ssIconId, format: "raw")
                        }
                    }   // if self.saveRawXml - end
                    // upload icon if not in save only mode
                    if !self.saveOnly {
                        
//                        self.iconMigrate(action: "POST", ssIconUri: "", ssIconName: ssIconName, iconToUpload: iconToUpload, createDestUrl: createDestUrl) {
//                            (result: Int) in
//                            if LogLevel.debug { WriteToLog().message(stringOfText: "[icons] Uploaded icon: \(ssIconName).\n") }
//
//                            if self.fm.fileExists(atPath: "\(NSHomeDirectory())/Library/Caches/\(ssIconName)") {
//                                do {
//                                    try FileManager.default.removeItem(at: URL(fileURLWithPath: "\(NSHomeDirectory())/Library/Caches/\(ssIconName)"))
//                                }
//                                catch let error as NSError {
//                                    if LogLevel.debug { WriteToLog().message(stringOfText: "[CreateEndpoints] unable to delete \(NSHomeDirectory())/Library/Caches/\(ssIconName).  Error \(error).\n") }
//                                }
//                            }
//                        }
                        
                        curlResult2 = self.myExitValue(cmd: "/bin/bash", args: "-c", "/usr/bin/curl -sk -H \"Authorization:Basic \(self.destBase64Creds)\" \(createDestUrl) -F \"name=@\(iconToUpload)\" -X POST")
                        if LogLevel.debug { WriteToLog().message(stringOfText: "[CreateEndpoints] result of icon POST: \(curlResult2).\n") }
                        if self.fm.fileExists(atPath: "\(NSHomeDirectory())/Library/Caches/\(ssIconName)") {
                            do {
                                try FileManager.default.removeItem(at: URL(fileURLWithPath: "\(NSHomeDirectory())/Library/Caches/\(ssIconName)"))
                            }
                            catch let error as NSError {
                                if LogLevel.debug { WriteToLog().message(stringOfText: "[CreateEndpoints] unable to delete \(NSHomeDirectory())/Library/Caches/\(ssIconName).  Error \(error).\n") }
                            }
                        }
                        
                        //                                    print("result of icon POST: "+curlResult2)
                    } else {
                        if self.fm.fileExists(atPath: "\(NSHomeDirectory())/Library/Caches/\(ssIconName)") {
                            do {
                                try FileManager.default.removeItem(at: URL(string: "\(NSHomeDirectory())/Library/Caches/\(ssIconName)")!)
                            }
                            catch let error as NSError {
                                if LogLevel.debug { WriteToLog().message(stringOfText: "[CreateEndpoints] unable to delete \(NSHomeDirectory())/Library/Caches/\(ssIconName).  Error \(error).\n") }
                            }
//                            if self.myExitValue(cmd: "/bin/bash", args: "-c", "/bin/rm \"\(NSHomeDirectory())/Library/Caches/\(ssIconName)\"") != "0" {
//                                if LogLevel.debug { WriteToLog().message(stringOfText: "[CreateEndpoints] unable to delete \(NSHomeDirectory())/Library/Caches/\(ssIconName).\n") }
//                            }
                        }
                    }  // if !saveOnly - end
                } else {
                    if LogLevel.debug { WriteToLog().message(stringOfText: "[CreateEndpoints] failed to retrieved icon from \(ssIconUri).\n") }
                }
            }
        }   // if (ssIconName != "") && (ssIconUri != "") - end
    }   // func icons - end
    
    func iconMigrate(action: String, ssIconUri: String, ssIconName: String, iconToUpload: String, createDestUrl: String, completion: @escaping (Int) -> Void) {

        var curlResult = 0
        
        switch action {
        case "GET":
            print("[iconMigrate] GET")

            // https://developer.apple.com/documentation/foundation/url_loading_system/downloading_files_from_websites
            let url = URL(string: "\(ssIconUri)")!
            
            let downloadTask = URLSession.shared.downloadTask(with: url) {
                urlOrNil, responseOrNil, errorOrNil in
                // check for and handle errors:
                // * errorOrNil should be nil
                // * responseOrNil should be an HTTPURLResponse with statusCode in 200..<299
                
                guard let fileURL = urlOrNil else { return }
                do {
                    let documentsURL = try
                        FileManager.default.url(for: .libraryDirectory,
                                                in: .userDomainMask,
                                                appropriateFor: nil,
                                                create: false)
                    let savedURL = documentsURL.appendingPathComponent("Caches/\(ssIconName)")
                    try FileManager.default.moveItem(at: fileURL, to: savedURL)
                } catch {
                    print ("file error: \(error)")
                }
                let curlResponse = responseOrNil as! HTTPURLResponse
                curlResult = curlResponse.statusCode
                if LogLevel.debug { WriteToLog().message(stringOfText: "[CreateEndpoints] result of Swift icon GET: \(curlResult).\n") }
                completion(curlResult)
            }
            downloadTask.resume()
            // swift file download - end
            
        case "POST":
            print("[iconMigrate] POST")

            var statusCode = 0
            let nameArray  = ssIconName.split(separator: ".")
            let uuid = NSUUID().uuidString
            let boundary = String(repeating: "-", count: 19) + uuid.replacingOccurrences(of: "-", with: "")
            let startBoundary = "\r\n-\(boundary)\r\nContent-Type: image/png\r\nContent-Disposition: form-data; filename=\(ssIconName); name=\(nameArray[0])\r\n\r\n"
//            let startBoundary = "\r\n-\(boundary)\r\n\r\n"

                    var httpResponse:HTTPURLResponse?
                    
                    theIconsQ.maxConcurrentOperationCount = 1
                    let semaphore = DispatchSemaphore(value: 0)
                    
//                        print("uploading package: \(package) with id: \(newPackageId)")
                        
                        self.theIconsQ.addOperation {
                            
                            var postData = Data()
                            
                            let fileURL = URL(fileURLWithPath: "\(iconToUpload)")
                            print("fileURL: \(fileURL)")

                            // Create URL to the destination server - this must be a trusted server
                            let serverURL = URL(string: "\(createDestUrl)")!
                            print("serverURL: \(serverURL)")
                            
                            let sessionConfig = URLSessionConfiguration.default
                            let session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: OperationQueue.main)
                            
                            var request = URLRequest(url:serverURL)
                            
                            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

                            request.addValue("Basic \(self.destBase64Creds)", forHTTPHeaderField: "Authorization")
                            
                            // prep the data for uploading
                            if let startData = startBoundary.data(using: .utf8) {
                                postData.append(startData)
                            }
                            do {
                                let fileData = try Data(contentsOf:fileURL, options:[])
                                postData.append(fileData)
                                print("loaded file to data.")
                            } catch {
                                print("unable to get file")
                            }
                            let endBoundary = "\r\n-\(boundary)"
                            if let endData = endBoundary.data(using: .utf8) {
                                    postData.append(endData)
                            }

                            request.httpBody   = postData
                            request.httpMethod = "POST"
                            
                            // start upload process
                            URLCache.shared.removeAllCachedResponses()
                            // let task = session.dataTask(with: request) { (data, response, error) in
                            let task = session.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
                                // Success
                //                if let httpResponse = response as? HTTPURLResponse {
                                if let _ = (response as? HTTPURLResponse)?.statusCode {
                                    httpResponse = response as? HTTPURLResponse
                                    statusCode = httpResponse!.statusCode
                                    print("Response from server - Status code: \(statusCode)")
            //                        print("Response (package) data string: \(String(data: data!, encoding: .utf8)!)")
                                } else {
                                    print("No response from the server.")
                                    completion(statusCode)
                                }

                                switch (response as? HTTPURLResponse)?.statusCode {
                                case 200, 201:
                                    print("\t file successfully uploaded.")
                                case 401:
                                    print("\t Authentication failed.")
                                case 404:
                                    print("\t server / file not found.")
                                default:
                                    print("\t unknown error occured.\n")
                                    print("\t Error took place while uploading a file. Error description: %@", error?.localizedDescription ?? "unknown")
                                }

                                completion(httpResponse?.statusCode ?? 0)
                                // upload checksum - end
                                
                                semaphore.signal()
                            })   // let task = session - end
                            task.resume()
                            semaphore.wait()
                        }   // theUploadQ.addOperation - end
                            // end upload procdess
            
            
        default:
            print("[iconMigrate] skip")
            completion(200)
        }
     
    }
    
    // func logCleanup - start
    func logCleanup() {
        if didRun {
            var logArray: [String] = []
            var logCount: Int = 0
            do {
                let logFiles = try fm.contentsOfDirectory(atPath: logPath!)
                
                for logFile in logFiles {
                    let filePath: String = logPath! + logFile
                    logArray.append(filePath)
                }
                logArray.sort()
                logCount = logArray.count
                // remove old history files
                if logCount-1 >= maxHistory {
                    for i in (0..<logCount-maxHistory) {
                        if LogLevel.debug { WriteToLog().message(stringOfText: "Deleting log file: " + logArray[i] + "\n") }
                        
                        do {
                            try fm.removeItem(atPath: logArray[i])
                        }
                        catch let error as NSError {
                            if LogLevel.debug { WriteToLog().message(stringOfText: "Error deleting log file:\n    " + logArray[i] + "\n    \(error)\n") }
                        }
                    }
                }
            } catch {
                print("no history")
            }
        } else {
            // delete empty log file
            do {
                try fm.removeItem(atPath: logPath! + logFile)
            }
            catch let error as NSError {
                if LogLevel.debug { WriteToLog().message(stringOfText: "Error deleting log file:    \n" + logPath! + logFile + "\n    \(error)\n") }
            }
        }

    }
    // func logCleanup - end
    
    // func labelColor - start
    func labelColor(endpoint: String, theColor: NSColor) {
        DispatchQueue.main.async {
            switch endpoint {
            // macOS tab
            case "advancedcomputersearches":
                self.advcompsearch_label_field.textColor = theColor
            case "computers":
                self.computers_label_field.textColor = theColor
            case "computerconfigurations":
                self.configurations_label_field.textColor = theColor
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
            case "netbootservers":
                self.netboot_label_field.textColor = theColor
            case "osxconfigurationprofiles":
                self.osxconfigurationprofiles_label_field.textColor = theColor
            case "patchpolicies":
                self.patch_policies_field.textColor = theColor
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
            default:
                print("function labelColor: unknown label - \(endpoint)")
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
                if LogLevel.debug { WriteToLog().message(stringOfText: "Moving: " + source + historyFile + " to " + destination) }
                do {
                    try fm.moveItem(atPath: source + historyFile, toPath: destination + historyFile.replacingOccurrences(of: ".txt", with: ".log"))
                }
                catch let error as NSError {
                    WriteToLog().message(stringOfText: "Ooops! Something went wrong moving the history file: \(error)\n")
                    allClear = false
                }
            }
        } catch {
            if LogLevel.debug { WriteToLog().message(stringOfText: "no history to display\n") }
        }
        if allClear {
            do {
                try fm.removeItem(atPath: source)
            } catch {
                if LogLevel.debug { WriteToLog().message(stringOfText: "Unable to remove \(source)\n") }
            }
        }
    }
    // move history to logs - end
    
    func mySpinner(spin: Bool) {
        theSpinnerQ.async {
            var theImageNo = 0
            while spin {
                DispatchQueue.main.async {
                    self.mySpinner_ImageView.image = self.theImage[theImageNo]
                    theImageNo += 1
                    if theImageNo > 2 {
                        theImageNo = 0
                    }
                }
                usleep(300000)  // sleep 0.3 seconds
            }
        }
    }
    
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
        if (self.fm.fileExists(atPath: NSHomeDirectory() + "/Library/Application Support/jamf-migrator/DELETE", isDirectory: &isDir)) {
            do {
                try self.fm.removeItem(atPath: NSHomeDirectory() + "/Library/Application Support/jamf-migrator/DELETE")
                _ = serverOrFiles()
                // re-enable source server, username, and password fields (to finish later)
//                source_jp_server_field.isEnabled = true
//                sourceServerList_button.isEnabled = true
            }
            catch let error as NSError {
                if LogLevel.debug { WriteToLog().message(stringOfText: "Unable to delete file! Something went wrong: \(error)\n") }
            }
        }
    }
    
    func rmBlankLines(theXML: String) -> String {
        if LogLevel.debug { WriteToLog().message(stringOfText: "Removing blank lines.\n") }
        let f_regexComp = try! NSRegularExpression(pattern: "\n\n", options:.caseInsensitive)
        let newXML = f_regexComp.stringByReplacingMatches(in: theXML, options: [], range: NSRange(0..<theXML.utf16.count), withTemplate: "")
//        let newXML_trimmed = newXML.replacingOccurrences(of: "\n\n", with: "")
        return newXML
    }
    
    func rmXmlData(theXML: String, theTag: String) -> String {
//        let f_regexCompNl = try! NSRegularExpression(pattern: "<\(theTag)>(.|\n)*?</\(theTag)>\n", options:.caseInsensitive)
//        var newXML = f_regexCompNl.stringByReplacingMatches(in: theXML, options: [], range: NSRange(0..<theXML.utf16.count), withTemplate: "")
//
        var newXML_trimmed = ""
        let f_regexComp = try! NSRegularExpression(pattern: "<\(theTag)>(.|\n|\r)*?</\(theTag)>", options:.caseInsensitive)
        var newXML = f_regexComp.stringByReplacingMatches(in: theXML, options: [], range: NSRange(0..<theXML.utf16.count), withTemplate: "")

        // prevent removing blank lines from scripts
        if (theTag == "script_contents_encoded") || (theTag == "id") {
            newXML_trimmed = newXML
        } else {
            if LogLevel.debug { WriteToLog().message(stringOfText: "Removing blank lines.\n") }
            newXML_trimmed = newXML.replacingOccurrences(of: "\n\n", with: "\n")
            newXML_trimmed = newXML.replacingOccurrences(of: "\r\r", with: "\r")
        }
        return newXML_trimmed
    }
    
    func readSettings() -> [String:Any] {
        // read environment settings - start
        plistData = (NSDictionary(contentsOf: URL(fileURLWithPath: plistPath!)) as? [String : Any])!
        if plistData.count == 0 {
            if LogLevel.debug { WriteToLog().message(stringOfText: "Error reading plist\n") }
        }
//        print("readSettings - plistData: \(String(describing: plistData["xml"]))\n")
        return(plistData)
        // read environment settings - end
    }
    
    func saveSettings() {
        plistData                       = readSettings()
        plistData["source_jp_server"]   = source_jp_server_field.stringValue as Any?
        plistData["source_user"]        = storedSourceUser as Any?
        plistData["dest_jp_server"]     = dest_jp_server_field.stringValue as Any?
        plistData["dest_user"]          = dest_user_field.stringValue as Any?
        plistData["maxHistory"]         = maxHistory as Any?
        plistData["storeCredentials"]   = storeCredentials_button.state as Any?
        NSDictionary(dictionary: plistData).write(toFile: plistPath!, atomically: true)
    }
    
    func savePrefs(prefs: [String:Any]) {
        plistData           = readSettings()
        plistData["scope"]  = prefs["scope"]
        plistData["xml"]    = prefs["xml"]
        scopeOptions        = prefs["scope"] as! Dictionary<String,Dictionary<String,Bool>>
        xmlPrefOptions      = prefs["xml"] as! Dictionary<String,Bool>
        saveOnly            = xmlPrefOptions["saveOnly"]!
        saveRawXml          = xmlPrefOptions["saveRawXml"]!
        saveTrimmedXml      = xmlPrefOptions["saveTrimmedXml"]!
        saveRawXmlScope     = xmlPrefOptions["saveRawXmlScope"]!
        saveTrimmedXmlScope = xmlPrefOptions["saveTrimmedXmlScope"]!
        NSDictionary(dictionary: plistData).write(toFile: self.plistPath!, atomically: true)
//      print("savePrefs xml: \(String(describing: self.plistData["xml"]))\n")
    }
    
    func setSite(xmlString:String, site:String, endpoint:String) -> String {
        var rawValue = ""
        var startTag = ""
        let siteEncoded = Xml().encodeSpecialChars(textString: site)
        
        // get copy / move preference - start
        switch endpoint {
        case "computergroups", "smartcomputergroups", "staticcomputergroups", "mobiledevicegroups", "smartmobiledevicegroups", "staticmobiledevicegroups":
            sitePref = userDefaults.string(forKey: "siteGroupsAction") ?? "Copy"
            
        case "policies":
            sitePref = userDefaults.string(forKey: "sitePoliciesAction") ?? "Copy"
            
        case "osxconfigurationprofiles", "mobiledeviceconfigurationprofiles":
            sitePref = userDefaults.string(forKey: "siteProfilesAction") ?? "Copy"
            
        default:
            sitePref = "Copy"
        }
        
        if LogLevel.debug { WriteToLog().message(stringOfText: "[siteSet] site operation for \(endpoint): \(sitePref)\n") }
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
        let siteInfo = tagValue2(xmlString: xmlString, startTag: "<site>", endTag: "</site>")
        let currentSiteName = tagValue2(xmlString: siteInfo, startTag: "<name>", endTag: "</name>")
        rawValue = xmlString.replacingOccurrences(of: "<site><name>\(currentSiteName)</name></site>", with: "<site><name>\(siteEncoded)</name></site>")
        if LogLevel.debug { WriteToLog().message(stringOfText: "[siteSet] changing site from \(currentSiteName) to \(siteEncoded)\n") }
        
        // do not redeploy profile to existing scope
        if endpoint == "osxconfigurationprofiles" || endpoint == "mobiledeviceconfigurationprofiles" {
            let regexComp = try! NSRegularExpression(pattern: "<redeploy_on_update>(.*?)</redeploy_on_update>", options:.caseInsensitive)
            rawValue = regexComp.stringByReplacingMatches(in: rawValue, options: [], range: NSRange(0..<rawValue.utf16.count), withTemplate: "<redeploy_on_update>Newly Assigned</redeploy_on_update>")
        }
        
        if sitePref == "Copy" {
            // update item Name - ...<name>currentName - site</name>
            rawValue = rawValue.replacingOccurrences(of: "<\(startTag)><name>\(itemName)</name>", with: "<\(startTag)><name>\(itemName) - \(siteEncoded)</name>")
//            print("[setSite]  rawValue: \(rawValue)\n")
            
            // generate a new uuid for configuration profiles - start
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
            let rawValueArray = rawValue.split(separator: "\n")
            rawValue = ""
            var currentLine = 0
            let numberOfLines = rawValueArray.count
            while true {
                rawValue.append("\(rawValueArray[currentLine])\n")
                if currentLine+1 < numberOfLines {
                    currentLine+=1
                } else {
                    break
                }
                if rawValueArray[currentLine].contains("<scope>") {
                    while !rawValueArray[currentLine].contains("</scope>") {
                        if rawValueArray[currentLine].contains("<computer_group>") || rawValueArray[currentLine].contains("<mobile_device_group>") {
                            rawValue.append("\(rawValueArray[currentLine])\n")
                            if currentLine+1 < numberOfLines {
                                currentLine+=1
                            } else {
                                break
                            }
                            let siteGroupName = rawValueArray[currentLine].replacingOccurrences(of: "</name>", with: " - \(siteEncoded)</name>")
                            
                            //                print("siteGroupName: \(siteGroupName)")
                            
                            rawValue.append("\(siteGroupName)\n")
                            if currentLine+1 < numberOfLines {
                                currentLine+=1
                            } else {
                                break
                            }
                        } else {  // if rawValueArray[currentLine].contains("<computer_group>") - end
                            rawValue.append("\(rawValueArray[currentLine])\n")
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
            statusArray = string.components(separatedBy: "\n")
            status = statusArray[0]
        }
        
        task.waitUntilExit()
        
        return(status)
    }
    
    func resetAllCheckboxes() {
        DispatchQueue.main.async {
        // Sellect all items to be migrated
            // macOS tab
            self.allNone_button.state = NSControl.StateValue(rawValue: 0)
            self.advcompsearch_button.state = NSControl.StateValue(rawValue: 0)
            self.macapplications_button.state = NSControl.StateValue(rawValue: 0)
            self.computers_button.state = NSControl.StateValue(rawValue: 0)
            self.configurations_button.state = NSControl.StateValue(rawValue: 0)
            self.directory_bindings_button.state = NSControl.StateValue(rawValue: 0)
            self.disk_encryptions_button.state = NSControl.StateValue(rawValue: 0)
            self.dock_items_button.state = NSControl.StateValue(rawValue: 0)
            self.netboot_button.state = NSControl.StateValue(rawValue: 0)
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
            // iOS tab
            self.allNone_iOS_button.state = NSControl.StateValue(rawValue: 0)
            self.advancedmobiledevicesearches_button.state = NSControl.StateValue(rawValue: 0)
            self.mobiledevicecApps_button.state = NSControl.StateValue(rawValue: 0)
            self.mobiledevices_button.state = NSControl.StateValue(rawValue: 0)
            self.smart_ios_groups_button.state = NSControl.StateValue(rawValue: 0)
            self.static_ios_groups_button.state = NSControl.StateValue(rawValue: 0)
            self.mobiledeviceconfigurationprofiles_button.state = NSControl.StateValue(rawValue: 0)
            self.mobiledeviceextensionattributes_button.state = NSControl.StateValue(rawValue: 0)
            // general tab
            self.allNone_general_button.state = NSControl.StateValue(rawValue: 0)
            self.advusersearch_button.state = NSControl.StateValue(rawValue: 0)
            self.building_button.state = NSControl.StateValue(rawValue: 0)
            self.categories_button.state = NSControl.StateValue(rawValue: 0)
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
    
// functions used to get existing self service icons to new server - start
    // using curl to deal with self service icons
//    func selfServiceIconGet(newPolicyId: String, ssIconName: String, ssIconUri: String) {
//        theCreateQ.maxConcurrentOperationCount = 1
//        let semaphore = DispatchSemaphore(value: 0)
//
////        var responseData = ""
//
//        theCreateQ.addOperation {
//            if LogLevel.debug { WriteToLog().message(stringOfText: "Getting icon \(ssIconName) from \(ssIconUri)\n") }
//
//            let encodedURL = NSURL(string: ssIconUri)
//            let request = NSMutableURLRequest(url: encodedURL! as URL)
//            request.httpMethod = "GET"
//
//            let configuration = URLSessionConfiguration.default
////            configuration.httpAdditionalHeaders = ["Authorization" : "Basic \(self.destBase64Creds)", "Content-Type" : "text/xml", "Accept" : "text/xml"]
////            request.httpBody = encodedXML!
//            let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
//            let task = session.dataTask(with: request as URLRequest, completionHandler: {
//                (data, response, error) -> Void in
//                if let httpResponse = response as? HTTPURLResponse {
//                    
//                    if let _ = String(data: data!, encoding: .unicode) {
//                        if httpResponse.statusCode >= 199 && httpResponse.statusCode <= 299 {
//                            WriteToLog().message(stringOfText: "icon get succeeded: \(ssIconName)\n")
//                            self.selfServiceIconPost(newPolicyId: newPolicyId, ssIconName: ssIconName, ssIcon: data!)
//                            
//                        } else {
//                            WriteToLog().message(stringOfText: "icon get failed: \(ssIconName)\n")
//                        }
////                        responseData = String(data: data!, encoding: .unicode)!
//                        //                        if LogLevel.debug { WriteToLog().message(stringOfText: "\n\nfull response from create:\n\(responseData)") }
////                        print("create data response: \(responseData)")
//                    } else {
//                        if LogLevel.debug { WriteToLog().message(stringOfText: "\n\nNo data was returned from icon GET.\n") }
//                    }
//                }
//                
//                semaphore.signal()
//                if error != nil {
//                }
//            })
//            task.resume()
//            semaphore.wait()
//            
//        }   // theCreateQ.addOperation - end
//    }
//    func selfServiceIconPost(newPolicyId: String, ssIconName: String, ssIcon: Data) {
//    
//    }
    // functions used to get existing self service icons to new server - end
    
    // extract the value between xml tags - start
    func tagValue(xmlString:String, xmlTag:String) -> String {
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
    func tagValue2(xmlString:String, startTag:String, endTag:String) -> String {
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
    
    func updateServerArray(url: String, serverList: String, theArray: [String]) {
//        if !(fileImport && serverList == "source_server_array") {
            var local_serverArray = theArray
            let positionInList = local_serverArray.firstIndex(of: url)
            if positionInList == nil && url != "" {
                    local_serverArray.insert(url, at: 0)
            } else if positionInList! > 0 && url != "" {
                local_serverArray.remove(at: positionInList!)
                local_serverArray.insert(url, at: 0)
            }
            while local_serverArray.count > 10 {
                local_serverArray.removeLast()
            }
            plistData[serverList] = local_serverArray as Any?
            NSDictionary(dictionary: plistData).write(toFile: plistPath!, atomically: true)
            switch serverList {
            case "source_server_array":
                self.sourceServerList_button.removeAllItems()
                for theServer in local_serverArray {
                    if theServer != "" {
                        self.sourceServerList_button.addItems(withTitles: [theServer])
                    }
                    self.sourceServerList_button.addItems(withTitles: [theServer])
                }
                self.sourceServerArray = local_serverArray
            case "dest_server_array":
                self.destServerList_button.removeAllItems()
                for theServer in local_serverArray {
                    if theServer != "" {
                        self.destServerList_button.addItems(withTitles: [theServer])
                    }
                }
                self.destServerArray = local_serverArray
            default: break
            }
    }
    
    func urlToFqdn(serverUrl: String) -> String {
        if serverUrl != "" {
            var fqdn = serverUrl.replacingOccurrences(of: "http://", with: "")
            fqdn = serverUrl.replacingOccurrences(of: "https://", with: "")
            let fqdnArray = fqdn.split(separator: "/")
            fqdn = "\(fqdnArray[0])"
            return fqdn
        } else {
            return ""
        }
    }
    
    @IBAction func setServerUrl_button(_ sender: NSPopUpButton) {
        switch sender.tag {
        case 0:
            self.source_jp_server_field.stringValue = sourceServerList_button.titleOfSelectedItem!
            fetchPassword(whichServer: "source", url: self.source_jp_server_field.stringValue, theUser: self.source_user_field.stringValue)
        case 1:
            self.dest_jp_server_field.stringValue = destServerList_button.titleOfSelectedItem!
            fetchPassword(whichServer: "destination", url: self.dest_jp_server_field.stringValue, theUser: self.dest_user_field.stringValue)
            // reset list of available sites
            if siteMigrate.state.rawValue == 1 {
                siteMigrate.state = NSControl.StateValue(rawValue: 0)
                availableSites_button.isEnabled = false
                availableSites_button.removeAllItems()
                destinationLabel_TextField.stringValue = "Destination"
                destinationSite = ""
                itemToSite = false
            }
        default: break
        }
        // see if we're migrating from files or a server
        _ = serverOrFiles()
    }
    
    func windowIsVisible(windowName: String) -> Bool {
        let options = CGWindowListOption(arrayLiteral: CGWindowListOption.excludeDesktopElements, CGWindowListOption.optionOnScreenOnly)
        let windowListInfo = CGWindowListCopyWindowInfo(options, CGWindowID(0))
        let infoList = windowListInfo as NSArray? as? [[String: AnyObject]]
        for item in infoList! {
            if let _ = item["kCGWindowOwnerName"], let _ = item["kCGWindowName"] {
//                if "\(item["kCGWindowOwnerName"]!)" == "jamf-migrator" {
//                    print("\(item["kCGWindowOwnerName"]!) \t \(item["kCGWindowName"]!)")
//                }
                if "\(item["kCGWindowOwnerName"]!)" == "jamf-migrator" && "\(item["kCGWindowName"]!)" == windowName {
//                    print("[viewController] item: \(item)")
                    print("[viewController] \(item["kCGWindowOwnerName"]!) -> \(item["kCGWindowName"]!) is visible")
                    return true
                }
            }
        }
        return false
    }
    
    func serverOrFiles() -> String {
        // see if we last migrated from files or a server
//        print("entered serverOrFiles.")
        var sourceType = ""
        DispatchQueue.main.async {
            if self.source_jp_server_field.stringValue != "" {
//                print("prefix: \(self.source_jp_server_field.stringValue.prefix(4).lowercased())")
                if self.source_jp_server_field.stringValue.prefix(4).lowercased() == "http" {
//                    print("source: server.")
                    self.importFiles_button.state = NSControl.StateValue(rawValue: 0)
                    self.source_user_field.isHidden = false
                    self.source_pwd_field.isHidden = false
                    self.fileImport = false
                    sourceType = "server"
                } else {
//                    print("source: files.")
                    self.importFiles_button.state = NSControl.StateValue(rawValue: 1)
                    self.dataFilesRoot = self.source_jp_server_field.stringValue
                    self.exportedFilesUrl = URL(string: "file://\(self.dataFilesRoot.replacingOccurrences(of: " ", with: "%20"))")
                    self.source_user_field.isHidden = true
                    self.source_pwd_field.isHidden = true
                    self.fileImport = true
                    sourceType = "files"
                }
            }
        }
        return(sourceType)
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
//    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        //        print("tableView: \(tableView)\t\ttableColumn: \(tableColumn)\t\trow: \(row)")
        var newString:String = ""
        if (tableView == srcSrvTableView)
        {
            newString = sourceDataArray[row]
        }
        
        //            // [NSColor colorWithCalibratedRed:0x6F/255.0 green:0x8E/255.0 blue:0x9D/255.0 alpha:0xFF/255.0]/* 6F8E9DFF */
        //            //[NSColor colorWithCalibratedRed:0x8C/255.0 green:0xB5/255.0 blue:0xC8/255.0 alpha:0xFF/255.0]/* 8CB5C8FF */
//        rowView.backgroundColor = (row % 2 == 0)
//            ? NSColor(calibratedRed: 0x6F/255.0, green: 0x8E/255.0, blue: 0x9D/255.0, alpha: 0xFF/255.0)
//            : NSColor(calibratedRed: 0x8C/255.0, green: 0xB5/255.0, blue: 0xC8/255.0, alpha: 0xFF/255.0)
        
        return newString;
    }
    // selective migration functions - end
    
    override func viewDidAppear() {
        // set tab order
        // Use interface builder, right click a field and drag nextKeyView to the next
        source_jp_server_field.nextKeyView  = source_user_field
        source_user_field.nextKeyView       = source_pwd_field
        source_pwd_field.nextKeyView        = dest_jp_server_field
        dest_jp_server_field.nextKeyView    = dest_user_field
        dest_user_field.nextKeyView         = dest_pwd_field
        
        // v1 colors
        //        self.view.layer?.backgroundColor = CGColor(red: 0x11/255.0, green: 0x1E/255.0, blue: 0x3A/255.0, alpha: 1.0)
        // v2 colors
        self.view.layer?.backgroundColor = CGColor(red: 0x5C/255.0, green: 0x78/255.0, blue: 0x94/255.0, alpha: 1.0)
        
        // OS version info
        let os = ProcessInfo().operatingSystemVersion
        if os.minorVersion < 14 {
            sourceServerPopup_button.isTransparent = false
            destServerPopup_button.isTransparent   = false
        }
        if !isDarkMode || os.minorVersion < 14 {
            // light mode settings
            let bkgndAlpha:CGFloat = 0.95
            get_name_field.backgroundColor            = NSColor(calibratedRed: 0xE8/255.0, green: 0xE8/255.0, blue: 0xE8/255.0, alpha: bkgndAlpha)
            object_name_field.backgroundColor         = NSColor(calibratedRed: 0xE8/255.0, green: 0xE8/255.0, blue: 0xE8/255.0, alpha: bkgndAlpha)
            get_completed_field.backgroundColor       = NSColor(calibratedRed: 0xE8/255.0, green: 0xE8/255.0, blue: 0xE8/255.0, alpha: bkgndAlpha)
            get_found_field.backgroundColor           = NSColor(calibratedRed: 0xE8/255.0, green: 0xE8/255.0, blue: 0xE8/255.0, alpha: bkgndAlpha)
            objects_completed_field.backgroundColor   = NSColor(calibratedRed: 0xE8/255.0, green: 0xE8/255.0, blue: 0xE8/255.0, alpha: bkgndAlpha)
            objects_found_field.backgroundColor       = NSColor(calibratedRed: 0xE8/255.0, green: 0xE8/255.0, blue: 0xE8/255.0, alpha: bkgndAlpha)
        } else {
            // dark mode settings
            //            [NSColor colorWithCalibratedRed:0x85/255.0 green:0x9C/255.0 blue:0xB0/255.0 alpha:0xFF/255.0]/* 859CB0FF */
//            srcSrvTableView.backgroundColor = NSColor(calibratedRed: 0x85/255.0, green: 0x9c/255.0, blue: 0xb0/255.0, alpha: 1.0)
            srcSrvTableView.usesAlternatingRowBackgroundColors = false
//            srcSrvTableView.gridColor = .black
            quit_button.image = NSImage(named: "quit_dark.png")!
            go_button.image = NSImage(named: "go_dark.png")!
        }
        
        let def_plist = Bundle.main.path(forResource: "settings", ofType: "plist")!
        var isDir: ObjCBool = true
        
        // Create Application Support folder for the app if missing - start
        let app_support_path = NSHomeDirectory() + "/Library/Application Support/jamf-migrator"
        if !(fm.fileExists(atPath: app_support_path, isDirectory: &isDir)) {
//            let manager = FileManager.default
            do {
                try fm.createDirectory(atPath: app_support_path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                if LogLevel.debug { WriteToLog().message(stringOfText: "Problem creating '/Library/Application Support/jamf-migrator' folder:  \(error)") }
            }
        }
        // Create Application Support folder for the app if missing - end
        
        // Create preference file if missing - start
        isDir = true
        if !(fm.fileExists(atPath: NSHomeDirectory() + "/Library/Application Support/jamf-migrator/settings.plist", isDirectory: &isDir)) {
            do {
                try fm.copyItem(atPath: def_plist, toPath: NSHomeDirectory() + "/Library/Application Support/jamf-migrator/settings.plist")
            }
            catch let error as NSError {
                if LogLevel.debug { WriteToLog().message(stringOfText: "Failed creating default settings.plist! Something went wrong: \(error)") }
                alert_dialog(header: "Error:", message: "Failed creating default settings.plist")
                exit(0)
            }
        }
        // Create preference file if missing - end
        
        // check for file that allows deleting data from destination server, delete if found - start
        self.rmDELETE()
        // check for file that allows deleting data from destination server, delete if found - end
        
        // read environment settings - start
        plistData = readSettings()
        
        if userDefaults.object(forKey: "activeTab") as? String != nil {
            let setActiveTab = userDefaults.object(forKey: "activeTab") as? String
            setTab_fn(selectedTab: setActiveTab!)
        } else {
            userDefaults.set("General", forKey: "activeTab")
            setTab_fn(selectedTab: "generalTab")
        }

        if plistData["source_jp_server"] != nil {
            source_jp_server = plistData["source_jp_server"] as! String
            source_jp_server_field.stringValue = source_jp_server
        }
        if plistData["source_user"] != nil {
            source_user = plistData["source_user"] as! String
            source_user_field.stringValue = source_user
            storedSourceUser = source_user
        }
        if plistData["dest_jp_server"] != nil {
            dest_jp_server = plistData["dest_jp_server"] as! String
            dest_jp_server_field.stringValue = dest_jp_server
        }
        if plistData["dest_user"] != nil {
            dest_user = plistData["dest_user"] as! String
            dest_user_field.stringValue = dest_user
        }
        if plistData["maxHistory"] != nil {
            maxHistory = plistData["maxHistory"] as! Int
        }
        if plistData["source_server_array"] != nil {
            sourceServerArray = plistData["source_server_array"] as! [String]
            for theServer in sourceServerArray {
                self.sourceServerList_button.addItems(withTitles: [theServer])
            }
        }
        if plistData["dest_server_array"] != nil {
            destServerArray = plistData["dest_server_array"] as! [String]
            for theServer in destServerArray {
                self.destServerList_button.addItems(withTitles: [theServer])
            }
        }
        if plistData["storeCredentials"] != nil {
            storeCredentials = plistData["storeCredentials"] as! Int
            storeCredentials_button.state = NSControl.StateValue(rawValue: storeCredentials)
        }
        // settings introduced with v2.8.0
        // read scope settings - start
        if plistData["scope"] != nil {
            scopeOptions = plistData["scope"] as! Dictionary<String,Dictionary<String,Bool>>

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
            plistData          = readSettings()
            plistData["scope"] = ["osxconfigurationprofiles":["copy":true],
                                  "macapps":["copy":true],
                                  "policies":["copy":true,"disable":false],
                                  "restrictedsoftware":["copy":true],
                                  "mobiledeviceconfigurationprofiles":["copy":true],
                                  "iosapps":["copy":true],
                                  "scg":["copy":true],
                                  "sig":["copy":true],
                                  "users":["copy":true]] as Any
            
            NSDictionary(dictionary: plistData).write(toFile: plistPath!, atomically: true)
        }
        // read scope settings - end
        
        if scopeOptions["scg"] != nil && scopeOptions["sig"] != nil && scopeOptions["users"] != nil  {
            scopeScgCopy = (scopeOptions["scg"]!["copy"] != nil) ? scopeOptions["scg"]!["copy"]!:true
            scopeSigCopy = (scopeOptions["sig"]!["copy"] != nil) ? scopeOptions["sig"]!["copy"]!:true
            scopeUsersCopy = (scopeOptions["sig"]!["users"] != nil) ? scopeOptions["users"]!["copy"]!:true
        } else {
            // reset/initialize scope preferences
            plistData          = readSettings()
            plistData["scope"] = ["osxconfigurationprofiles":["copy":true],
                                  "macapps":["copy":true],
                                  "policies":["copy":true,"disable":false],
                                  "restrictedsoftware":["copy":true],
                                  "mobiledeviceconfigurationprofiles":["copy":true],
                                  "iosapps":["copy":true],
                                  "scg":["copy":true],
                                  "sig":["copy":true],
                                  "users":["copy":true]] as Any
            
            NSDictionary(dictionary: plistData).write(toFile: plistPath!, atomically: true)
        }
        
        // read xml settings - start
        if plistData["xml"] != nil {
            xmlPrefOptions       = plistData["xml"] as! Dictionary<String,Bool>
            saveRawXml           = (xmlPrefOptions["saveRawXml"] != nil) ? xmlPrefOptions["saveRawXml"]!:false
            saveTrimmedXml       = (xmlPrefOptions["saveTrimmedXml"] != nil) ? xmlPrefOptions["saveTrimmedXml"]!:false
            saveOnly             = (xmlPrefOptions["saveOnly"] != nil) ? xmlPrefOptions["saveOnly"]!:false
//            saveRawXmlScope      = (xmlPrefOptions["saveRawXmlScope"] != nil) ? xmlPrefOptions["saveRawXmlScope"]!:true
//            saveTrimmedXmlScope  = (xmlPrefOptions["saveTrimmedXmlScope"] != nil) ? xmlPrefOptions["saveTrimmedXmlScope"]!:true
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
            plistData        = readSettings()
            plistData["xml"] = ["saveRawXml":false,
                                "saveTrimmedXml":false,
                                "saveOnly":false,
                                "saveRawXmlScope":true,
                                "saveTrimmedXmlScope":true] as Any
            
            NSDictionary(dictionary: plistData).write(toFile: plistPath!, atomically: true)
        }
        // read xml settings - end
        // read environment settings - end
        
        // see if we last migrated from files or a server
        _ = serverOrFiles()

        // check for stored passwords - start
        if (dest_jp_server != "") {
            fetchPassword(whichServer: "destination", url: dest_jp_server, theUser: dest_user)
        }
        if (source_jp_server != "") {
            fetchPassword(whichServer: "source", url: source_jp_server, theUser: source_user)
        }
        if (source_pwd_field.stringValue == "") || (dest_pwd_field.stringValue == "") {
            self.validCreds = false
        }
        // check for stored passwords - end
        

        
        let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        let appBuild   = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
        WriteToLog().message(stringOfText: "jamf-migrator Version: \(appVersion) Build: \(appBuild )\n")
        
        if hideGui {
            
        }
        
    }   //viewDidAppear - end
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // read command line arguments - start
        var numberOfArgs = 0
        
//        debug = true
        
        // read commandline args
        numberOfArgs = CommandLine.arguments.count - 2  // subtract 2 since we start counting at 0, another 1 for the app itself
//        print("all arguments: \(CommandLine.arguments)")
        if CommandLine.arguments.contains("-debug") {
            numberOfArgs -= 1
            LogLevel.debug = true
        }
        if numberOfArgs >= 0 {
            for i in stride(from: 1, through: numberOfArgs+1, by: 2) {
//                print("i: \(i)\t argument: \(CommandLine.arguments[i]) \t value: \(CommandLine.arguments[i+1])")
                switch CommandLine.arguments[i]{
                case "-saveRawXml":
                    saveRawXml = true
                case "-saveTrimmedXml":
                    saveTrimmedXml = true
                case "-saveOnly":
                    saveOnly = true
                case "-sourceServer":
                    source_jp_server = "\(CommandLine.arguments[i+1])"
                case "-destServer":
                    dest_jp_server = "\(CommandLine.arguments[i+1])"
                case "-hidden":
                    hideGui = true
                case "-NSDocumentRevisionsDebugMode","YES":
                    continue
                default:
                    print("unknown switch passed: \(CommandLine.arguments[i])")
                }
            }
        }
        // read command line arguments - end

        // Do any additional setup after loading the view.
        // read maxConcurrentOperationCount setting
        concurrentThreads = (userDefaults.integer(forKey: "concurrentThreads") == 0) ? 3:userDefaults.integer(forKey: "concurrentThreads")
        concurrentThreads = (concurrentThreads > 5) ? 3:concurrentThreads
        
        // Set all checkboxes off
        resetAllCheckboxes()
//        // macOS tab
//        allNone_button.state = NSControl.StateValue(rawValue: 0)
//        advcompsearch_button.state = NSControl.StateValue(rawValue: 0)
//        macapplications_button.state = NSControl.StateValue(rawValue: 0)
//        computers_button.state = NSControl.StateValue(rawValue: 0)
//        configurations_button.state = NSControl.StateValue(rawValue: 0)
//        directory_bindings_button.state = NSControl.StateValue(rawValue: 0)
//        disk_encryptions_button.state = NSControl.StateValue(rawValue: 0)
//        dock_items_button.state = NSControl.StateValue(rawValue: 0)
//        netboot_button.state = NSControl.StateValue(rawValue: 0)
//        osxconfigurationprofiles_button.state = NSControl.StateValue(rawValue: 0)
////        patch_mgmt_button.state = 1
//        patch_policies_button.state = NSControl.StateValue(rawValue: 0)
//        sus_button.state = NSControl.StateValue(rawValue: 0)
//        fileshares_button.state = NSControl.StateValue(rawValue: 0)
//        ext_attribs_button.state = NSControl.StateValue(rawValue: 0)
//        smart_comp_grps_button.state = NSControl.StateValue(rawValue: 0)
//        static_comp_grps_button.state = NSControl.StateValue(rawValue: 0)
//        scripts_button.state = NSControl.StateValue(rawValue: 0)
//        packages_button.state = NSControl.StateValue(rawValue: 0)
//        policies_button.state = NSControl.StateValue(rawValue: 0)
//        printers_button.state = NSControl.StateValue(rawValue: 0)
//        restrictedsoftware_button.state = NSControl.StateValue(rawValue: 0)
//        // iOS tab
//        allNone_iOS_button.state = NSControl.StateValue(rawValue: 0)
//        advancedmobiledevicesearches_button.state = NSControl.StateValue(rawValue: 0)
//        mobiledevicecApps_button.state = NSControl.StateValue(rawValue: 0)
//        mobiledevices_button.state = NSControl.StateValue(rawValue: 0)
//        smart_ios_groups_button.state = NSControl.StateValue(rawValue: 0)
//        static_ios_groups_button.state = NSControl.StateValue(rawValue: 0)
//        mobiledeviceconfigurationprofiles_button.state = NSControl.StateValue(rawValue: 0)
//        mobiledeviceextensionattributes_button.state = NSControl.StateValue(rawValue: 0)
//        // general tab
//        allNone_general_button.state = NSControl.StateValue(rawValue: 0)
//        advusersearch_button.state = NSControl.StateValue(rawValue: 0)
//        building_button.state = NSControl.StateValue(rawValue: 0)
//        categories_button.state = NSControl.StateValue(rawValue: 0)
//        dept_button.state = NSControl.StateValue(rawValue: 0)
//        userEA_button.state = NSControl.StateValue(rawValue: 0)
//        sites_button.state = NSControl.StateValue(rawValue: 0)
//        ldapservers_button.state = NSControl.StateValue(rawValue: 0)
//        networks_button.state = NSControl.StateValue(rawValue: 0)
//        users_button.state = NSControl.StateValue(rawValue: 0)
//        jamfUserAccounts_button.state = NSControl.StateValue(rawValue: 0)
//        jamfGroupAccounts_button.state = NSControl.StateValue(rawValue: 0)
//        smartUserGrps_button.state = NSControl.StateValue(rawValue: 0)
//        staticUserGrps_button.state = NSControl.StateValue(rawValue: 0)
        
        source_jp_server_field.becomeFirstResponder()
        go_button.isEnabled = true
        
        // for selective migration - end
        
        // create log directory if missing - start
        if !fm.fileExists(atPath: logPath!) {
            do {
                try fm.createDirectory(atPath: logPath!, withIntermediateDirectories: true, attributes: nil )
                } catch {
                alert_dialog(header: "Error:", message: "Unable to create log directory:\n\(String(describing: logPath))\nTry creating it manually.")
                exit(0)
            }
        }
        // create log directory if missing - end
        
        if fm.fileExists(atPath: historyPath!) {
            // move legacy history files to log directory and delete history dir
            moveHistoryToLog (source: historyPath!, destination: logPath!)
        }

        
        logFile = getCurrentTime().replacingOccurrences(of: ":", with: "") + "_migration.log"
        History.logFile = getCurrentTime().replacingOccurrences(of: ":", with: "") + "_migration.log"

        isDir = false
        if !(fm.fileExists(atPath: logPath! + logFile, isDirectory: &isDir)) {
            fm.createFile(atPath: logPath! + logFile, contents: nil, attributes: nil)
        }

        sleep(1)
        if LogLevel.debug { WriteToLog().message(stringOfText: "----- Debug Mode -----\n") }
//            DispatchQueue.main.async {
//                WriteToLog().message(stringOfText: "----- Debug Mode -----\n")
//            }
//        }
        
        
        theModeQ.async {
            var isDir: ObjCBool = false
            var isRed = false
            
            while true {
                if (self.fm.fileExists(atPath: NSHomeDirectory() + "/Library/Application Support/jamf-migrator/DELETE", isDirectory: &isDir)) {
                    // clear selective list of items when changing from migration to delete mode
                    DispatchQueue.main.async {
                        if !self.selectiveListCleared && self.srcSrvTableView.isEnabled == true {
                            self.sourceDataArray.removeAll()
                            self.srcSrvTableView.stringValue = ""
                            self.srcSrvTableView.reloadData()
                            self.selectiveListCleared = true
                        } else {
                            self.selectiveListCleared = true
                            self.srcSrvTableView.isEnabled = true
                        }
                    }
                    
                    DispatchQueue.main.async {
                        // disable source server, username and password fields (to finish)
                        if self.source_jp_server_field.isEnabled {
                            self.source_jp_server_field.textColor   = NSColor.white
                            self.source_jp_server_field.isEnabled   = false
                            self.sourceServerList_button.isEnabled  = false
                            self.source_user_field.isEnabled        = false
                            self.source_pwd_field.isEnabled         = false
                        }

                        if isRed == false {
                            // Set the text for the operation
                            self.migrateOrRemove_TextField.stringValue = "--- Removing ---"
                            self.migrateOrRemove_TextField.textColor = self.redText
                            // Set the text for destination method
                            self.destinationMethod_TextField.stringValue = "DELETE"
                            self.destinationMethod_TextField.textColor = self.yellowText
                            isRed = true
                        } else {
                            self.migrateOrRemove_TextField.textColor = self.yellowText
                            self.destinationMethod_TextField.textColor = self.redText
                            isRed = false
                        }
                        // Set the text for destination method
                        self.destinationMethod_TextField.stringValue = "DELETE"
                        if self.fileImport {
                            self.fileImport = false
                            self.importFiles_button.state = NSControl.StateValue(rawValue: 0)
//                            self.importFiles_button.isEnabled = false
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        if !self.source_jp_server_field.isEnabled {
                            if !self.isDarkMode {
                                self.source_jp_server_field.textColor   = NSColor.black
                            } else {
                                self.source_jp_server_field.textColor   = NSColor.white
                            }
                            self.source_jp_server_field.isEnabled   = true
                            self.sourceServerList_button.isEnabled  = true
                            self.source_user_field.isEnabled        = true
                            self.source_pwd_field.isEnabled         = true
                            self.selectiveListCleared               = false
                        }

                        self.migrateOrRemove_TextField.stringValue = "Migrate"
                        self.migrateOrRemove_TextField.textColor = self.whiteText
                        self.destinationMethod_TextField.stringValue = "POST/PUT"
                        self.destinationMethod_TextField.textColor = self.whiteText
                        isRed = false
                    }
                }
                usleep(500000)  // 0.5 seconds
            }   // while true - end
        }
        // bring app to foreground
        NSApplication.shared.activate(ignoringOtherApps: true)
    }   //override func viewDidLoad() - end
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    override func viewDidDisappear() {
        // Insert code here to tear down your application
        saveSettings()
        logCleanup()
    }
    
    // Summary Window - start
    @IBAction func showSummaryWindow(_ sender: AnyObject) {
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
    func summaryXml(theSummary: Dictionary<String, Dictionary<String,Int>>, theSummaryDetail: Dictionary<String, Dictionary<String,[String]>>) -> String {
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
                "max-height: 190px;" +
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
            for (key,values) in theSummary {
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
                endpointSummary.append("</tr>\n")
                cellDetails.append(popUpHtml(id: createIndex, column: "\(String(describing: key)) \(summaryHeader.createDelete)d", values: createHtml))
                cellDetails.append(popUpHtml(id: updateIndex, column: "\(String(describing: key)) Updated", values: updateHtml))
                cellDetails.append(popUpHtml(id: failIndex, column: "\(String(describing: key)) Failed", values: failHtml))
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
            "</div>" +
            "</div>" +
        "</div>"
        return popUpBlock
    }
    // code for pop up window - end
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(  URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
    
}

