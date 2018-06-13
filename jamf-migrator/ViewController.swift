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
    
    @IBOutlet weak var objectsToSelect: NSScrollView!
    
        // Help Window
    @IBAction func showHelpWindow(_ sender: AnyObject) {
        let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
        let helpWindowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "Help View Controller")) as! NSWindowController
        helpWindowController.showWindow(self)
        
//        if let helpWindow = helpWindowController.window {
//            //            let helpViewController = helpWindow.contentViewController as! HelpViewController
//            
//            let application = NSApplication.shared()
//            application.runModal(for: helpWindow)
//            
//            helpWindow.close()
//        }
    }
    
    // Show Preferences Window
    @IBAction func showPrefsWindow(_ sender: AnyObject) {
        let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
        let prefsWindowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "Prefs View Controller")) as! NSWindowController
        prefsWindowController.showWindow(self)
    }

        
    // keychain access
    let Creds = Credentials()
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
    @IBOutlet weak var computers_button: NSButton!
    @IBOutlet weak var configurations_button: NSButton!
    @IBOutlet weak var directory_bindings_button: NSButton!
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
    @IBOutlet weak var computers_label_field: NSTextField!
    @IBOutlet weak var configurations_label_field: NSTextField!
    @IBOutlet weak var directory_bindings_field: NSTextField!
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
    @IBOutlet weak var migrateOrRemove_label_field: NSTextField!
    //    @IBOutlet weak var migrateOrRemove_iOS_label_field: NSTextField!
    
    // Source and destination fields
    @IBOutlet weak var source_jp_server_field: NSTextField!
    @IBOutlet weak var source_user_field: NSTextField!
    @IBOutlet weak var source_pwd_field: NSSecureTextField!
    @IBOutlet weak var dest_jp_server_field: NSTextField!
    @IBOutlet weak var dest_user_field: NSTextField!
    @IBOutlet weak var dest_pwd_field: NSSecureTextField!
    
    // GET and POST fields
    @IBOutlet weak var object_name_field: NSTextField!  // object being migrated
    @IBOutlet weak var objects_completed_field: NSTextField!
    @IBOutlet weak var objects_found_field: NSTextField!
    
    @IBOutlet weak var get_name_field: NSTextField!
    @IBOutlet weak var get_completed_field: NSTextField!
    @IBOutlet weak var get_found_field: NSTextField!
    
    // selective migration items - start
    // source / destination tables
    @IBOutlet weak var srcSrvTableView: NSTableView!
    
    // source / destination array / dictionary of items
    var sourceDataArray:[String] = []
    var targetDataArray:[String] = []
    var availableIDsToMigDict:[String:Int] = [:]   // something like xmlName, xmlID
    var availableObjsToMigDict:[Int:String] = [:]   // something like xmlID, xmlName
    
    // destination TextFieldCells
    @IBOutlet weak var destTextCell_TextFieldCell: NSTextFieldCell!
    @IBOutlet weak var dest_TableColumn: NSTableColumn!
    // selective migration items - end
    
    var isDir: ObjCBool = false
    
    // command line switches
    var debug = false
    
    // plist and log variables
    var didRun = false  // used to determine if the Go! button was selected, if not delete the empty log file only.
    let plistPath:String? = (NSHomeDirectory() + "/Library/Application Support/jamf-migrator/settings.plist")
    var format = PropertyListSerialization.PropertyListFormat.xml //format of the property list
    var plistData:[String:Any] = [:]   //our server/username data

    var maxHistory: Int = 20
    var historyFile: String = ""
    var logFile: String = ""
    let historyPath:String? = (NSHomeDirectory() + "/Library/Application Support/jamf-migrator/history/")
    let logPath:String? = (NSHomeDirectory() + "/Library/Logs/jamf-migrator/")
    var historyFileW: FileHandle?  = FileHandle(forUpdatingAtPath: "")
    var logFileW: FileHandle?  = FileHandle(forUpdatingAtPath: "")
    
    // scope preferences
    var scopeOptions:           Dictionary<String,Dictionary<String,Bool>> = [:]
    var scopeMcpCopy:           Bool = true   // mobileconfigurationprofiles copy scope
    //    var policyMcpDisable:       Bool = false  // mobileconfigurationprofiles disable on copy
    var scopePoliciesCopy:      Bool = true   // policies copy scope
    var policyPoliciesDisable:  Bool = false  // policies disable on copy
    var scopeOcpCopy:           Bool = true   // osxconfigurationprofiles copy scope
    //    var policyOcpDisable:       Bool = false  // osxconfigurationprofiles disable on copy
    var scopeRsCopy:            Bool = true   // restrictedsoftware copy scope
    var scopeScgCopy:           Bool = true // static computer groups copy scope
    var scopeSigCopy:           Bool = true // static iOS device groups copy scope
    var scopeUsersCopy:         Bool = true // static user groups copy scope
    
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
    
    var endpointDefDict = ["computergroups":"computer_groups","computerconfigurations":"computer_configurations", "directorybindings":"directory_bindings", "dockitems":"dock_items", "mobiledevicegroups":"mobile_device_groups", "packages":"packages", "patches":"patch_management_software_titles", "patchpolicies":"patch_policies", "printers":"printers", "scripts":"scripts", "usergroups":"user_groups", "userextensionattributes":"user_extension_attributes", "advancedusersearches":"advanced_user_searches", "restrictedsoftware":"restricted_software"]
    var xmlName = ""
    var destEPs = [String:Int]()
    var currentEPs = [String:Int]()
    var currentEndpointID = 0
    var progressCountArray = [String:Int]() // track if post/put was successful
    
    var whiteText:NSColor = NSColor.white
    var greenText:NSColor = NSColor.green
    var yellowText:NSColor = NSColor.yellow
    var redText:NSColor = NSColor.red
    var changeColor:Bool = true
    
    // This order must match the drop down for selective migration
    var macOSEndpointArray: [String] = ["advancedcomputersearches", "computergroups", "computers", "osxconfigurationprofiles", "computerconfigurations", "directorybindings", "dockitems", "computerextensionattributes", "distributionpoints", "netbootservers", "packages", "policies", "printers", "restrictedsoftware", "scripts", "softwareupdateservers"]
    var iOSEndpointArray: [String] = ["advancedmobiledevicesearches", "mobiledeviceconfigurationprofiles", "mobiledevicegroups",  "mobiledeviceextensionattributes", "mobiledevices"]
    var generalEndpointArray: [String] = ["advancedusersearches", "buildings", "categories", "departments", "userextensionattributes", "jamfusers", "jamfgroups", "ldapservers", "networksegments", "sites", "users", "usergroups"]
    var AllEndpointsArray = [String]()
    
    
    var getEndpointInProgress: String = ""     // end point currently in the GET queue
    var endpointInProgress: String = ""     // end point currently in the POST queue
    var endpointName: String = ""
    var POSTsuccessCount: Int = 0
    var failedCount: Int = 0
    var postCount: Int = 1
    var counters = Dictionary<String, Dictionary<String,Int>>()     // summary counters of created, updated, and failed objects
    var tmp_counter = Dictionary<String, Dictionary<String,Int>>() // used to hold value of counter and avoid simultaneous access when updating
    var summaryDict = Dictionary<String, Dictionary<String,[String]>>()     // summary arrays of created, updated, and failed objects

    
    @IBOutlet weak var mySpinner_ImageView: NSImageView!
    var theImage:[NSImage] = [NSImage(named: NSImage.Name(rawValue: "0.png"))!, NSImage(named: NSImage.Name(rawValue: "1.png"))!, NSImage(named: NSImage.Name(rawValue: "2.png"))!]
    var showSpinner = false
    
    // group counters
    var smartCount = 0
    var staticCount = 0
    var DeviceGroupType = ""  // either smart or static
    //var groupCheckArray: [Bool] = []
    
    
    // define list of items to migrate
    var objectsToMigrate: [String] = []
    
    // dictionaries to map id of object on source server to id of same object on destination server
//    var computerconfigs_id_map = [String:Dictionary<String,Int>]()
    var bindings_id_map = [String:Dictionary<String,Int>]()
    var packages_id_map = [String:Dictionary<String,Int>]()
    var printers_id_map = [String:Dictionary<String,Int>]()
    var scripts_id_map = [String:Dictionary<String,Int>]()
    var configObjectsDict = [String:Dictionary<String,String>]()
    var orphanIds = [String]()
    var idDict = [String:Dictionary<String,Int>]()
    
    var wipe_data: Bool = false
    
    let fm = FileManager()
    var theOpQ = OperationQueue() // create operation queue for API calls
    var theCreateQ = OperationQueue() // create operation queue for API POST/PUT calls
    
    var authQ = DispatchQueue(label: "com.jamf.auth")
    var theModeQ = DispatchQueue(label: "com.jamf.addRemove")
    var theSpinnerQ = DispatchQueue(label: "com.jamf.spinner")
    var destEPQ = DispatchQueue(label: "com.jamf.destEPs", qos: DispatchQoS.background)
    var idMapQ = DispatchQueue(label: "com.jamf.idMap")
    var writeLogQ = DispatchQueue(label: "com.jamf.writeLogQ", qos: DispatchQoS.background)
    
    var migrateOrWipe: String = ""
    var httpStatusCode: Int = 0
    var URLisValid: Bool = true
    var processGroup = DispatchGroup()
    
    @IBAction func showLogFolder(_ sender: Any) {
        isDir = true
        if (self.fm.fileExists(atPath: logPath!, isDirectory: &isDir)) {
            NSWorkspace.shared.openFile(logPath!)
        } else {
            alert_dialog(header: "Alert", message: "There are currently no log files to display.")
        }
    }
    
    @IBAction func toggleAllNone(_ sender: NSButton) {
        //        platform = deviceType()
        if deviceType() == "macOS" {
            self.allNone_button.state = NSControl.StateValue(rawValue: (
                self.advcompsearch_button.state.rawValue == 1
                    && self.computers_button.state.rawValue == 1
                    && self.configurations_button.state.rawValue == 1
                    && self.directory_bindings_button.state.rawValue == 1
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
            self.packages_button.state = self.allNone_button.state
            self.printers_button.state = self.allNone_button.state
            self.restrictedsoftware_button.state = self.allNone_button.state
            self.policies_button.state = self.allNone_button.state
        } else if deviceType() == "iOS" {
            self.advancedmobiledevicesearches_button.state = self.allNone_iOS_button.state
            self.mobiledevices_button.state = self.allNone_iOS_button.state
            self.smart_ios_groups_button.state = self.allNone_iOS_button.state
            self.static_ios_groups_button.state = self.allNone_iOS_button.state
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
        
        let whichTab = sender.identifier!.rawValue
        
        if debug { writeToLog(stringOfText: "func sectionToMigrate active tab: \(String(describing: whichTab)).\n") }
        var itemIndex = 0
        switch whichTab {
        case "macOS":
            itemIndex = sectionToMigrate_button.indexOfSelectedItem
        case "iOS":
            itemIndex = iOSsectionToMigrate_button.indexOfSelectedItem
        default:
            itemIndex = generalSectionToMigrate_button.indexOfSelectedItem
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
            if self.debug { self.writeToLog(stringOfText: "Selectively migrating: \(objectsToMigrate) for \(sender.identifier ?? NSUserInterfaceItemIdentifier(rawValue: ""))\n") }
            Go(sender: self)
        }
    }
    
    @IBAction func Go(sender: AnyObject) {
        print("go (before readSettings) scopeOptions: \(String(describing: scopeOptions))\n")
        plistData = readSettings()
        scopeOptions = plistData["scope"] as! Dictionary<String,Dictionary<String,Bool>>
        print("go (after readSettings) scopeOptions:  \(String(describing: scopeOptions))\n")
        didRun = true
        if self.debug { self.writeToLog(stringOfText: "Start Migrating/Removal\n") }
        // check for file that allow deleting data from destination server - start
        //       var isDir: ObjCBool = false
        if (fm.fileExists(atPath: NSHomeDirectory() + "/Library/Application Support/jamf-migrator/DELETE", isDirectory: &isDir)) {
            if self.debug { self.writeToLog(stringOfText: "Removing data from destination server - \(dest_jp_server_field.stringValue)\n") }
            wipe_data = true
            
            migrateOrWipe = "----------- Starting To Wipe Data -----------\n"
        } else {
            // verify source and destination are not the same - start
            if source_jp_server_field.stringValue == dest_jp_server_field.stringValue {
                alert_dialog(header: "Alert", message: "Source and destination servers cannot be the same.")
                //self.go_button.isEnabled = true
                self.goButtonEnabled(button_status: true)
                return
            }
            // verify source and destination are not the same - end
            if self.debug { self.writeToLog(stringOfText: "Migrating data from \(source_jp_server_field.stringValue) to \(dest_jp_server_field.stringValue).\n") }
            wipe_data = false
            
            migrateOrWipe = "----------- Starting Migration -----------\n"
        }
        // check for file that allow deleting data from destination server - end
        
        
        if debug { writeToLog(stringOfText: "go sender tag: \(sender.tag)\n") }
        // determine if we got here from the Go button or selectToMigrate button
        if sender.tag != nil {
            self.goSender = "goButton"
        } else {
            self.goSender = "selectToMigrateButton"
        }
        if debug { writeToLog(stringOfText: "Go button pressed from: \(goSender)\n") }
        
        // which migration mode tab are we on - start
        if activeTab() != "selective" {
            migrationMode = "bulk"
        } else {
            migrationMode = "selective"
        }
        if debug { writeToLog(stringOfText: "Migration Mode (Go): \(migrationMode)\n") }
        
        //self.go_button.isEnabled = false
        goButtonEnabled(button_status: false)
        clearProcessingFields()
        currentEPs.removeAll()
        
        // credentials were entered check - start
        if (source_user_field.stringValue == "" || source_pwd_field.stringValue == "") && !wipe_data {
            alert_dialog(header: "Alert", message: "Must provide both a username and password for the source server.")
            //self.go_button.isEnabled = true
            goButtonEnabled(button_status: true)
            return
        }
        if dest_user_field.stringValue == "" || dest_pwd_field.stringValue == "" {
            alert_dialog(header: "Alert", message: "Must provide both a username and password for the destination server.")
            //self.go_button.isEnabled = true
            goButtonEnabled(button_status: true)
            return
        }
        // credentials check - end
        
        // set credentials / servers - start
        self.source_jp_server = source_jp_server_field.stringValue
        self.source_user = source_user_field.stringValue
        self.source_pass = source_pwd_field.stringValue
        
        self.dest_jp_server = dest_jp_server_field.stringValue
        self.dest_user = dest_user_field.stringValue
        self.dest_pass = dest_pwd_field.stringValue
        // set credentials / servers - end
        
        // server is reachable - start
        checkURL2(serverURL: self.source_jp_server)  {
            (result: Bool) in
//            print("checkURL2 returned result: \(result)")
            if !result {
                self.alert_dialog(header: "Attention:", message: "Unable to contact the source server:\n\(self.source_jp_server)")
                self.goButtonEnabled(button_status: true)
                return
            }
        }
        checkURL2(serverURL: self.dest_jp_server)  {
            (result: Bool) in
//            print("checkURL2 returned result: \(result)")
            if !result {
                self.alert_dialog(header: "Attention:", message: "Unable to contact the destination server:\n\(self.dest_jp_server)")
                self.goButtonEnabled(button_status: true)
                return
            }
            // server is reachable - end
            
            self.sourceCreds = "\(self.source_user):\(self.source_pass)"
            self.sourceBase64Creds = self.sourceCreds.data(using: .utf8)?.base64EncodedString() ?? ""
            
            self.destCreds = "\(self.dest_user):\(self.dest_pass)"
            self.destBase64Creds = self.destCreds.data(using: .utf8)?.base64EncodedString() ?? ""

            // set credentials - end
            
            
            // check authentication - start
            self.authCheck(f_sourceURL: self.source_jp_server, f_credentials: self.sourceBase64Creds)  {
                (result: Bool) in
                if !result && !self.wipe_data {
                    if self.debug { self.writeToLog(stringOfText: "Source server authentication failure.") }
                    return
                } else {
                    self.updateServerArray(url: self.source_jp_server, serverList: "source_server_array", theArray: self.sourceServerArray)
                    self.authCheck(f_sourceURL: self.dest_jp_server, f_credentials: self.destBase64Creds)  {
                        (result: Bool) in
                        if !result {
                            if self.debug { self.writeToLog(stringOfText: "Destination server authentication failure.") }
                            return
                        } else {
                            self.updateServerArray(url: self.dest_jp_server, serverList: "dest_server_array", theArray: self.destServerArray)
                            // verify source server URL - start
                            let sourceURL = URL(string: self.source_jp_server_field.stringValue)
                            let task_sourceURL = URLSession.shared.dataTask(with: sourceURL!) { _, response, _ in
                                if (response as? HTTPURLResponse) != nil || (response as? HTTPURLResponse) == nil {
                                    //print(HTTPURLResponse.statusCode)
                                    //===== change to go to function to check dest. server, which forwards to migrate if all is well
                                    // verify destination server URL - start
                                    DispatchQueue.main.async {
                                        let destinationURL = URL(string: self.dest_jp_server_field.stringValue)
                                        let task_destinationURL = URLSession.shared.dataTask(with: destinationURL!) { _, response, _ in
                                            if (response as? HTTPURLResponse) != nil || (response as? HTTPURLResponse) == nil {
                                                // print("Destination server response: \(response)")
                                                if(!self.theOpQ.isSuspended) {
                                                    //====================================    Start Migrating/Removing    ====================================//
                                                    self.startMigrating()
                                                }
                                            } else {
//                                                DispatchQueue.main.async {
                                                    //print("Destination server response: \(response)")
                                                    self.alert_dialog(header: "Attention", message: "The destination server URL could not be validated.")
//                                                }
                                                
                                                if self.debug { self.writeToLog(stringOfText: "Failed to connect to destination server.") }
                                                //self.go_button.isEnabled = true
                                                self.goButtonEnabled(button_status: true)
                                                return
                                            }
                                        }   // let task for destinationURL - end
                                    
                                        task_destinationURL.resume()
                                    }
                                    // verify source destination URL - end
                                    
                                } else {
                                    DispatchQueue.main.async {
                                        self.alert_dialog(header: "Attention", message: "The source server URL could not be validated.")
                                    }
                                    if self.debug { self.writeToLog(stringOfText: "Failed to connect source server.") }
                                    //self.go_button.isEnabled = true
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
        //self.go_button.isEnabled = true
        self.goButtonEnabled(button_status: true)
        NSApplication.shared.terminate(self)
    }
    
    //================================= migration functions =================================//
    
    func authCheck(f_sourceURL: String, f_credentials: String, completion: @escaping (Bool) -> Void) {
        var validCredentials:Bool = false
        if self.debug { self.writeToLog(stringOfText: "--- checking authentication to: \(f_sourceURL)\n") }
        
        if !(f_sourceURL == self.source_jp_server && wipe_data) {
            var myURL = "\(f_sourceURL)/JSSResource/buildings"
            myURL = myURL.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
            authQ.sync {
                if self.debug { self.writeToLog(stringOfText: "checking: \(myURL)\n") }
                
                let encodedURL = NSURL(string: myURL)
                let request = NSMutableURLRequest(url: encodedURL! as URL)
                //let request = NSMutableURLRequest(url: encodedURL as! URL, cachePolicy: NSURLRequest.CachePolicy(rawValue: 1)!, timeoutInterval: 10)
                request.httpMethod = "GET"
                let configuration = URLSessionConfiguration.default
                configuration.httpAdditionalHeaders = ["Authorization" : "Basic \(f_credentials)", "Content-Type" : "application/json", "Accept" : "application/json"]
                let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
                let task = session.dataTask(with: request as URLRequest, completionHandler: {
                    (data, response, error) -> Void in
                    if let httpResponse = response as? HTTPURLResponse {
                        if self.debug { self.writeToLog(stringOfText: "\(myURL) auth check httpResponse: \(httpResponse.statusCode)\n") }
                        
                        if httpResponse.statusCode >= 199 && httpResponse.statusCode <= 299 {
                            if self.debug { self.writeToLog(stringOfText: "\(myURL) auth httpResponse, between 199 and 299: \(httpResponse.statusCode)\n") }
                            
                            if (!self.validCreds) || (self.source_user_field.stringValue != self.storedSourceUser) || (self.dest_user_field.stringValue != self.storedDestUser) {
                                // save credentials to login keychain - start
                                let regexKey = try! NSRegularExpression(pattern: "http(.*?)://", options:.caseInsensitive)
                                if f_sourceURL == self.source_jp_server && !self.wipe_data {
                                    if self.storeCredentials_button.state.rawValue == 1 {
                                        let credKey = regexKey.stringByReplacingMatches(in: f_sourceURL, options: [], range: NSRange(0..<f_sourceURL.utf16.count), withTemplate: "")
                                        self.Creds.save("migrator - "+credKey, account: self.source_user_field.stringValue, data: self.source_pwd_field.stringValue)
                                        self.storedSourceUser = self.source_user_field.stringValue
                                    }
                                } else {
                                    if self.storeCredentials_button.state.rawValue == 1 {
                                        let credKey = regexKey.stringByReplacingMatches(in: f_sourceURL, options: [], range: NSRange(0..<f_sourceURL.utf16.count), withTemplate: "")
                                        self.Creds.save("migrator - "+credKey, account: self.dest_user_field.stringValue, data: self.dest_pwd_field.stringValue)
                                        self.storedDestUser = self.dest_user_field.stringValue
                                    }
                                }
                                // save credentials to login keychain - end
                            }

                            validCredentials = true
                            completion(validCredentials)
                        } else {
                            if self.debug { self.writeToLog(stringOfText: "\n\n[- debug -] ---------- status code ----------\n") }
                            if self.debug { self.writeToLog(stringOfText: "\(httpResponse.statusCode)\n") }
                            self.httpStatusCode = httpResponse.statusCode
                            if self.debug { self.writeToLog(stringOfText: "---------- status code ----------\n") }
                            if self.debug { self.writeToLog(stringOfText: "\n\n[- debug -] ---------- response ----------\n") }
                            if self.debug { self.writeToLog(stringOfText: "\(httpResponse)\n") }
                            if self.debug { self.writeToLog(stringOfText: "---------- response ----------\n\n") }
                            self.theOpQ.cancelAllOperations()
                            switch self.httpStatusCode {
                            case 401:
                                self.alert_dialog(header: "Authentication Failure", message: "Please verify username and password for:\n\(f_sourceURL)")
                            case 503:
                                self.alert_dialog(header: "Service Unavailable", message: "Verify you can manually log into the API:\n\(f_sourceURL)/api \nError: \(self.httpStatusCode)")
                            default:
                                self.alert_dialog(header: "Error", message: "An unknown error (\(self.httpStatusCode)) occured trying to query the server:\n\(f_sourceURL)")
                            }
                            //                        401 - wrong username and/or password
                            //                        409 - unable to create object; data missing or xml error
                            //self.go_button.isEnabled = true
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
        // make sure the labels can change color when we start
        changeColor = true
        DispatchQueue.main.async {
            self.createDestUrlBase = "\(self.dest_jp_server_field.stringValue)/JSSResource"
//        }
        
        
        
        // set all the labels to white - start
            self.AllEndpointsArray = self.macOSEndpointArray + self.iOSEndpointArray + self.generalEndpointArray
//            DispatchQueue.main.async {
                for i in (0..<self.AllEndpointsArray.count) {
                    self.labelColor(endpoint: self.AllEndpointsArray[i], theColor: self.whiteText)
                }
//            }
            // set all the labels to white - end
            
            if self.debug { self.writeToLog(stringOfText: "Start Migrating/Removal\n") }
            if self.debug { self.writeToLog(stringOfText: "platform: \(self.deviceType()).\n") }
            if self.debug { self.writeToLog(stringOfText: "Migration Mode (startMigration): \(self.migrationMode).\n") }
            
                // list the items in the order they need to be migrated
                if self.migrationMode == "bulk" {
                    // initialize list of items to migrate then add what we want - start
                    self.objectsToMigrate.removeAll()
                    if self.debug { self.writeToLog(stringOfText: "Types of objects to migrate: \(self.deviceType()).\n") }
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
                            
                            if self.smart_comp_grps_button.state.rawValue == 1 || self.static_comp_grps_button.state.rawValue == 1 {
                                self.objectsToMigrate += ["computergroups"]
                            }
                            
                            if self.restrictedsoftware_button.state.rawValue == 1 {
                                self.objectsToMigrate += ["restrictedsoftware"]
                            }
                            
                            if self.osxconfigurationprofiles_button.state.rawValue == 1 {
                                self.objectsToMigrate += ["osxconfigurationprofiles"]
                            }
                            
                            if self.packages_button.state.rawValue == 1 {
                                self.objectsToMigrate += ["packages"]
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
                            }
                            
                            if self.advancedmobiledevicesearches_button.state.rawValue == 1 {
                                self.objectsToMigrate += ["advancedmobiledevicesearches"]
                            }
                            
                            if self.mobiledevicecApps_button.state.rawValue == 1 {
                                //                    self.objectsToMigrate += ["mobiledeviceapplications"]
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
                            }
                        default: break
                        }
                        print(self.getCurrentTime()+" objectsToMigrate: \(self.objectsToMigrate)")
                        
                    }
                    
                    // initialize list of items to migrate then add what we want - end
                    if self.debug { self.writeToLog(stringOfText: "objects: \(self.objectsToMigrate).\n") }
                    
//                }   // if migrationMode == "bulk" - end
            
            if self.objectsToMigrate.count == 0 {
                if self.debug { self.writeToLog(stringOfText: "nothing selected to migrate/remove.\n") }
                self.goButtonEnabled(button_status: true)
                return
            }
            
            if self.wipe_data {
                self.objectsToMigrate.reverse()
                if self.objectsToMigrate.count > 0 {
                    // set server and credentials used for wipe
                    self.sourceBase64Creds = self.destBase64Creds
                    self.source_jp_server = self.dest_jp_server
                    // move users and sites to the end of the array
    //              trying reverse() for removal order
    //                var siteIndex = objectsToMigrate.index(of: "users")
    //                if siteIndex != nil {
    //                    let siteTmp = objectsToMigrate.remove(at: siteIndex!)
    //                    objectsToMigrate.insert(siteTmp, at: objectsToMigrate.count)
    //                }
    //                siteIndex = objectsToMigrate.index(of: "sites")
    //                if siteIndex != nil {
    //                    let siteTmp = objectsToMigrate.remove(at: siteIndex!)
    //                    objectsToMigrate.insert(siteTmp, at: objectsToMigrate.count)
    //                }
                    
                } else {
                    //go_button.isEnabled = true
                    self.goButtonEnabled(button_status: true)
                    return
                }// end if objectsToMigrate - end
            }   // if wipe_data - end
            
            self.writeToLog(stringOfText: self.migrateOrWipe)
            //go_button.isEnabled = false
            self.goButtonEnabled(button_status: false)
            
//            // initialize counters - changed 20180603 (disabled) setting in func CreateEndpoints
//            // need to add code to handle computergroups, mobiledevicegroups, and usergroups
//            for currentNode in self.objectsToMigrate {
//                self.counters[currentNode] = ["create":0, "update":0, "fail":0]
//                self.summaryDict[currentNode] = ["create":[], "update":[], "fail":[]]
//            }
            
            // get scope copy / policy disable options
            self.scopeOptions = self.readSettings()["scope"] as! Dictionary<String, Dictionary<String, Bool>>
            print("startMigrating scopeOptions: \(String(describing: self.scopeOptions))")
            
            // get preference settings - start
            if self.scopeOptions["mobiledeviceconfigurationprofiles"]!["copy"] != nil {
                self.scopeMcpCopy = self.scopeOptions["mobiledeviceconfigurationprofiles"]!["copy"]!
            }
            if self.scopeOptions["policies"]!["copy"] != nil {
                self.scopePoliciesCopy = self.scopeOptions["policies"]!["copy"]!
            }
            if self.scopeOptions["policies"]!["disable"] != nil {
                self.policyPoliciesDisable = self.scopeOptions["policies"]!["disable"]!
            }
            if self.scopeOptions["osxconfigurationprofiles"]!["copy"] != nil {
                self.scopeOcpCopy = self.scopeOptions["osxconfigurationprofiles"]!["copy"]!
            }
            if self.scopeOptions["restrictedsoftware"]!["copy"] != nil {
                self.scopeRsCopy = self.scopeOptions["restrictedsoftware"]!["copy"]!
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
            // get preference settings - start
            
            if self.debug { self.writeToLog(stringOfText: "migrating/removing \(self.objectsToMigrate.count) sections\n") }
            // loop through process of migrating or removing - start
            for currentNode in self.objectsToMigrate {
                
                if self.debug { self.writeToLog(stringOfText: "Starting to process \(currentNode)\n") }
                if (self.goSender == "goButton" && self.migrationMode == "bulk") || (self.goSender == "selectToMigrateButton") {
                    if self.debug { self.writeToLog(stringOfText: "getting endpoint: \(currentNode)\n") }
                    self.getEndpoints(endpoint: currentNode)  {
                        (result: String) in
                        if self.debug { self.writeToLog(stringOfText: "getEndpoints result: \(result)\n") }
                    }
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
                    self.existingEndpoints(destEndpoint: "\(self.objectsToMigrate[0])")  {
                        (result: String) in
                        if self.debug { self.writeToLog(stringOfText: "Returned from existing endpoints: \(result)\n") }
                        var objToMigrateID = 0
                        // clear targetDataArray - needed to handle switching tabs
                        self.targetDataArray.removeAll()
                        // create targetDataArray
                        for k in (0..<self.sourceDataArray.count) {
                            if self.srcSrvTableView.isRowSelected(k) {
                                // prevent the removal of the account we're using
                                if !(selectedEndpoint == "jamfusers" && self.sourceDataArray[k].lowercased() == self.dest_user.lowercased()) {
                                    self.targetDataArray.append(self.sourceDataArray[k])
                                }
                            }
                        }
                        
                        if self.targetDataArray.count == 0 {
                            if self.debug { self.writeToLog(stringOfText: "nothing selected to migrate/remove.\n") }
                            self.alert_dialog(header: "Alert:", message: "Nothing was selected.")
                            self.goButtonEnabled(button_status: true)
                            return
                        }
                        
                        if self.debug { self.writeToLog(stringOfText: "Item(s) chosen from selective: \(self.targetDataArray)\n") }
                        for j in (0..<self.targetDataArray.count) {
                            objToMigrateID = self.availableIDsToMigDict[self.targetDataArray[j]]!
                            if !self.wipe_data  {
                                if let selectedObject = self.availableObjsToMigDict[objToMigrateID] {
                                    if self.debug { self.writeToLog(stringOfText: "check for existing object: \(selectedObject)\n") }
                                    if nil != self.currentEPs[self.availableObjsToMigDict[objToMigrateID]!] {
                                        if self.debug { self.writeToLog(stringOfText: "\(selectedObject) already exists\n") }
                                        //self.currentEndpointID = self.currentEPs[xmlName]!
                                        self.endPointByID(endpoint: selectedEndpoint, endpointID: objToMigrateID, endpointCurrent: (j+1), endpointCount: self.targetDataArray.count, action: "update", destEpId: self.currentEPs[self.availableObjsToMigDict[objToMigrateID]!]!, destEpName: selectedObject)
                                    } else {
                                        self.endPointByID(endpoint: selectedEndpoint, endpointID: objToMigrateID, endpointCurrent: (j+1), endpointCount: self.targetDataArray.count, action: "create", destEpId: 0, destEpName: selectedObject)
                                    }
                                }
                            } else {
                                // selective removal
                                if self.debug { self.writeToLog(stringOfText: "remove - endpoint: \(self.targetDataArray[j])\t endpointID: \(objToMigrateID)\t endpointName: \(self.targetDataArray[j])\n") }
                                self.RemoveEndpoints(endpointType: selectedEndpoint, endPointID: objToMigrateID, endpointName: self.targetDataArray[j], endpointCurrent: (j+1), endpointCount: self.targetDataArray.count)
                                
                            }   // if !self.wipe_data else - end
                        }   // for j in  - end
                    }
                }   //for i in - else - end
                // **************************************** selective migration - end ****************************************
            }   // loop through process of migrating or removing - end
        }   //DispatchQueue.man.async - end

    }   // func startMigrating - end
    
    
    func getEndpoints(endpoint: String, completion: @escaping (_ result: String) -> Void) {
        URLCache.shared.removeAllCachedResponses()
        if self.debug { self.writeToLog(stringOfText: "[getEndpoints] Getting \(endpoint)\n") }
        var endpointParent = ""
        var node = ""
        switch endpoint {
        // macOS items
        case "advancedcomputersearches":
            endpointParent = "advanced_computer_searches"
        case "computerconfigurations":
            endpointParent = "computer_configurations"
        case "computerextensionattributes":
            endpointParent = "computer_extension_attributes"
        case "directorybindings":
            endpointParent = "directory_bindings"
        case "dockitems":
            endpointParent = "dock_items"
        case "computergroups":
            endpointParent = "computer_groups"
        case "distributionpoints":
            endpointParent = "distribution_points"
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
        case "mobiledevicegroups":
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
        case "usergroups":
            endpointParent = "user_groups"
        case "jamfusers":
            endpointParent = "users"
        case "jamfgroups":
            endpointParent = "groups"
        default:
            endpointParent = "\(endpoint)"
        }
        
        // initialize post/put success count switch endpoint {
        switch endpoint {
        case "computergroups":
            progressCountArray["smartcomputergroups"] = 0
            progressCountArray["staticcomputergroups"] = 0
            progressCountArray["computergroups"] = 0 // this is the recognized end point
        case "mobiledevicegroups":
            progressCountArray["smartiosgroups"] = 0
            progressCountArray["staticiosgroups"] = 0
            progressCountArray["mobiledevicegroups"] = 0 // this is the recognized end point
        case "usergroups":
            progressCountArray["smartusergroups"] = 0
            progressCountArray["staticusergroups"] = 0
            progressCountArray["usergroups"] = 0 // this is the recognized end point
        case "accounts":
            progressCountArray["jamfusers"] = 0
            progressCountArray["jamfgroups"] = 0
            progressCountArray["accounts"] = 0 // this is the recognized end point
        default:
            progressCountArray["\(endpoint)"] = 0
        }
        
        (endpoint == "jamfusers" || endpoint == "jamfgroups") ? (node = "accounts"):(node = endpoint)
        var myURL = "\(self.source_jp_server)/JSSResource/\(node)"
        myURL = myURL.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
        
        theOpQ.maxConcurrentOperationCount = 1
        let semaphore = DispatchSemaphore(value: 0)
        
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
                        if self.debug { self.writeToLog(stringOfText: "[getEndpoints] Getting all endpoints from: \(myURL)\n") }
                        let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                        if let endpointJSON = json as? [String: Any] {
                            if self.debug { self.writeToLog(stringOfText: "[getEndpoints] endpointJSON: \(endpointJSON))") }
                            
                            switch endpoint {
                            case "advancedcomputersearches", "buildings", "categories", "computers", "computerextensionattributes", "departments", "distributionpoints", "directorybindings", "dockitems", "ldapservers", "netbootservers", "networksegments", "osxconfigurationprofiles", "packages", "patchpolicies", "printers", "scripts", "sites", "softwareupdateservers", "users", "mobiledeviceconfigurationprofiles", "mobiledeviceapplications", "advancedmobiledevicesearches", "mobiledeviceextensionattributes", "mobiledevices", "userextensionattributes", "advancedusersearches", "restrictedsoftware":
                                if let endpointInfo = endpointJSON[endpointParent] as? [Any] {
                                    let endpointCount: Int = endpointInfo.count
                                    if self.debug { self.writeToLog(stringOfText: "[getEndpoints] Initial count for \(endpoint) found: \(endpointCount)\n") }
                                    
                                    if self.debug { self.writeToLog(stringOfText: "[getEndpoints] Verify empty dictionary of objects - availableObjsToMigDict count: \(self.availableObjsToMigDict.count)\n") }
                                    
                                    if endpointCount > 0 {
                                        
                                        self.existingEndpoints(destEndpoint: "\(endpoint)")  {
                                            (result: String) in
                                            if self.debug { self.writeToLog(stringOfText: "[getEndpoints] Returned from existing \(endpoint): \(result)\n") }
                                            
                                            for i in (0..<endpointCount) {
                                                if i == 0 { self.availableObjsToMigDict.removeAll() }
                                                
                                                let record = endpointInfo[i] as! [String : AnyObject]
                                                
                                                if endpoint != "mobiledeviceapplications" {
                                                    if record["name"] != nil {
                                                        self.availableObjsToMigDict[record["id"] as! Int] = record["name"] as! String?
                                                    } else {
                                                        self.availableObjsToMigDict[record["id"] as! Int] = ""
                                                    }
                                                } else {
                                                        self.availableObjsToMigDict[record["id"] as! Int] = record["bundle_id"] as! String?
                                                }
                                                
                                                if self.debug { self.writeToLog(stringOfText: "[getEndpoints] Current number of \(endpoint) to process: \(self.availableObjsToMigDict.count)\n") }
                                            }   // for i in (0..<endpointCount) end
                                            if self.debug { self.writeToLog(stringOfText: "[getEndpoints] Found total of \(self.availableObjsToMigDict.count) \(endpoint) to process\n") }
                                            
                                            var counter = 1
                                            if self.goSender == "goButton" {
                                                for (l_xmlID, l_xmlName) in self.availableObjsToMigDict {
                                                    if !self.wipe_data  {
                                                        if self.debug { self.writeToLog(stringOfText: "[getEndpoints] check for ID on \(l_xmlName): \(self.currentEPs[l_xmlName] ?? 0)\n") }
                                                        if self.currentEPs[l_xmlName] != nil {
                                                            if self.debug { self.writeToLog(stringOfText: "[getEndpoints] \(l_xmlName) already exists\n") }
                                                            //self.currentEndpointID = self.currentEPs[l_xmlName]!
                                                            self.endPointByID(endpoint: endpoint, endpointID: l_xmlID, endpointCurrent: counter, endpointCount: self.availableObjsToMigDict.count, action: "update", destEpId: self.currentEPs[l_xmlName]!, destEpName: l_xmlName)
                                                        } else {
                                                            if self.debug { self.writeToLog(stringOfText: "[getEndpoints] \(l_xmlName) - create\n") }
                                                            if self.debug { self.writeToLog(stringOfText: "[getEndpoints] function - endpoint: \(endpoint), endpointID: \(l_xmlID), endpointCurrent: \(counter), endpointCount: \(endpointCount), action: \"create\", destEpId: 0\n") }
                                                            self.endPointByID(endpoint: endpoint, endpointID: l_xmlID, endpointCurrent: counter, endpointCount: self.availableObjsToMigDict.count, action: "create", destEpId: 0, destEpName: l_xmlName)
                                                        }
                                                    } else {
                                                        if self.debug { self.writeToLog(stringOfText: "[getEndpoints] remove - endpoint: \(endpoint)\t endpointID: \(l_xmlID)\t endpointName: \(l_xmlName)\n") }
                                                        self.RemoveEndpoints(endpointType: endpoint, endPointID: l_xmlID, endpointName: l_xmlName, endpointCurrent: counter, endpointCount: self.availableObjsToMigDict.count)
                                                    }   // if !self.wipe_data else - end
                                                    counter+=1
                                                }   // for (l_xmlID, l_xmlName) in availableObjsToMigDict
                                            } else {
                                                // populate source server under the selective tab
                                                for (l_xmlID, l_xmlName) in self.availableObjsToMigDict {
                                                    DispatchQueue.main.async {
                                                        //print("adding \(l_xmlName) to array")
                                                        self.availableIDsToMigDict[l_xmlName] = l_xmlID
                                                        self.sourceDataArray.append(l_xmlName)
                                                        
                                                        self.srcSrvTableView.reloadData()
                                                        
                                                    }   // DispatchQueue.main.async - end
                                                    counter+=1
                                                }   // for (l_xmlID, l_xmlName) in availableObjsToMigDict
                                                DispatchQueue.main.async {
                                                    //self.sourceDataArray.sort()
                                                    self.sourceDataArray = self.sourceDataArray.sorted{$0.localizedCompare($1) == .orderedAscending}
                                                    
                                                    self.srcSrvTableView.reloadData()
                                                }
                                            }   // if self.goSender else - end
                                        }   // self.existingEndpoints - end
                                    } else {
                                        if endpoint == self.objectsToMigrate.last {
                                            self.rmDELETE()
                                            self.goButtonEnabled(button_status: true)
                                            completion("Got endpoint - \(endpoint)")
                                        }
                                    }// if endpointCount - end
                                }   // end if let buildings, departments...
                                
                            case "computergroups", "mobiledevicegroups", "usergroups":
                                if self.debug { self.writeToLog(stringOfText: "[getEndpoints] processing device groups\n") }
                                if let endpointInfo = endpointJSON[self.endpointDefDict["\(endpoint)"]!] as? [Any] {
                                    
                                    let endpointCount: Int = endpointInfo.count
                                    if self.debug { self.writeToLog(stringOfText: "[getEndpoints] groups found: \(endpointCount)\n") }
                                    //self.migrationStatus(endpoint: "computer groups", count: endpointCount)
                                    
                                    var smartGroupDict: [Int: String] = [:]
                                    var staticGroupDict: [Int: String] = [:]
                                    if endpointCount > 0 {
                                        self.existingEndpoints(destEndpoint: "\(endpoint)")  {
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
                                                    if record["name"] as! String? != "All Managed Clients" && record["name"] as! String? != "All Managed Servers" {
                                                        smartGroupDict[record["id"] as! Int] = record["name"] as! String?
                                                    }
                                                } else {
                                                    //self.staticCount += 1
                                                    staticGroupDict[record["id"] as! Int] = record["name"] as! String?
                                                }
                                            }
                                            // split devicegroups into smart and static - end
                                            switch endpoint {
                                            case "computergroups":
                                                if self.smart_comp_grps_button.state.rawValue == 0 {
                                                    excludeCount += smartGroupDict.count
                                                }
                                                if self.static_comp_grps_button.state.rawValue == 0 {
                                                    excludeCount += staticGroupDict.count
                                                }
                                            case "mobiledevicegroups":
                                                if self.smart_ios_groups_button.state.rawValue == 0 {
                                                    excludeCount += smartGroupDict.count
                                                }
                                                if self.static_ios_groups_button.state.rawValue == 0 {
                                                    excludeCount += staticGroupDict.count
                                                }
                                            case "usergroups":
                                                if self.smartUserGrps_button.state.rawValue == 0 {
                                                    excludeCount += smartGroupDict.count
                                                }
                                                if self.staticUserGrps_button.state.rawValue == 0 {
                                                    excludeCount += staticGroupDict.count
                                                }
                                                
                                            default: break
                                            }
                                            
                                            
                                            if self.debug { self.writeToLog(stringOfText: "[getEndpoints] \(smartGroupDict.count) smart groups\n") }
                                            if self.debug { self.writeToLog(stringOfText: "[getEndpoints] \(staticGroupDict.count) static groups\n") }
                                            var currentGroupDict: [Int: String] = [:]
                                            // verify we have some groups
                                            for g in (0...1) {
                                                currentGroupDict.removeAll()
                                                var groupCount = 0
                                                var localEndpoint = endpoint
                                                switch endpoint {
                                                case "computergroups":
                                                    if (self.smart_comp_grps_button.state.rawValue == 1) && (g == 0) {
                                                        currentGroupDict = smartGroupDict
                                                        groupCount = currentGroupDict.count
                                                        self.DeviceGroupType = "smartcomputergroups"
                                                        print("computergroups smart - DeviceGroupType: \(self.DeviceGroupType)")
                                                        localEndpoint = "smartcomputergroups"
                                                    }
                                                    if (self.static_comp_grps_button.state.rawValue == 1) && (g == 1) {
                                                        currentGroupDict = staticGroupDict
                                                        groupCount = currentGroupDict.count
                                                        self.DeviceGroupType = "staticcomputergroups"
                                                        print("computergroups static - DeviceGroupType: \(self.DeviceGroupType)")
                                                        localEndpoint = "staticcomputergroups"
                                                    }
                                                case "mobiledevicegroups":
                                                    if (self.smart_ios_groups_button.state.rawValue == 1) && (g == 0) {
                                                        currentGroupDict = smartGroupDict
                                                        groupCount = currentGroupDict.count
                                                        self.DeviceGroupType = "smartcomputergroups"
                                                        print("devicegroups smart - DeviceGroupType: \(self.DeviceGroupType)")
                                                        localEndpoint = "smartiosgroups"
                                                    }
                                                    if (self.static_ios_groups_button.state.rawValue == 1) && (g == 1) {
                                                        currentGroupDict = staticGroupDict
                                                        groupCount = currentGroupDict.count
                                                        self.DeviceGroupType = "staticcomputergroups"
                                                        print("devicegroups static - DeviceGroupType: \(self.DeviceGroupType)")
                                                        localEndpoint = "staticiosgroups"
                                                    }
                                                case "usergroups":
                                                    if (self.smartUserGrps_button.state.rawValue == 1) && (g == 0) {
                                                        currentGroupDict = smartGroupDict
                                                        groupCount = currentGroupDict.count
                                                        self.DeviceGroupType = "smartcomputergroups"
//                                                        print("usergroups smart - DeviceGroupType: \(self.DeviceGroupType)")
                                                        localEndpoint = "smartusergroups"
                                                    }
                                                    if (self.staticUserGrps_button.state.rawValue == 1) && (g == 1) {
                                                        currentGroupDict = staticGroupDict
                                                        groupCount = currentGroupDict.count
                                                        self.DeviceGroupType = "staticcomputergroups"
//                                                        print("usergroups static - DeviceGroupType: \(self.DeviceGroupType)")
                                                        localEndpoint = "staticusergroups"
                                                    }
                                                default: break
                                                }
                                                var counter = 1
                                                for (l_xmlID, l_xmlName) in currentGroupDict {
                                                    self.availableObjsToMigDict[l_xmlID] = l_xmlName
                                                    if self.goSender == "goButton" {
                                                        if !self.wipe_data  {
                                                            
                                                            //need to call existingEndpoints here to keep proper order?
                                                            if self.currentEPs[l_xmlName] != nil {
                                                                if self.debug { self.writeToLog(stringOfText: "[getEndpoints] \(l_xmlName) already exists\n") }
                                                                self.endPointByID(endpoint: localEndpoint, endpointID: l_xmlID, endpointCurrent: counter, endpointCount: groupCount, action: "update", destEpId: self.currentEPs[l_xmlName]!, destEpName: l_xmlName)
                                                            } else {
                                                                if self.debug { self.writeToLog(stringOfText: "[getEndpoints] \(l_xmlName) - create\n") }
                                                                if self.debug { self.writeToLog(stringOfText: "[getEndpoints] function - endpoint: \(localEndpoint), endpointID: \(l_xmlID), endpointCurrent: \(counter), endpointCount: \(groupCount), action: \"create\", destEpId: 0\n") }
                                                                self.endPointByID(endpoint: localEndpoint, endpointID: l_xmlID, endpointCurrent: counter, endpointCount: groupCount, action: "create", destEpId: 0, destEpName: l_xmlName)
                                                            }
                                                            
//                                                            if self.debug { self.writeToLog(stringOfText: "[getEndpoints] \(l_xmlName) - create\n") }
//                                                            if self.debug { self.writeToLog(stringOfText: "[getEndpoints] function - endpoint: \(endpoint), endpointID: \(l_xmlID), endpointCurrent: \(counter), endpointCount: \(endpointCount), action: \"create\", destEpId: 0\n") }
//                                                            self.endPointByID(endpoint: localEndpoint, endpointID: l_xmlID, endpointCurrent: counter, endpointCount: groupCount, action: "create", destEpId: 0)
                                                        } else {
                                                            
                                                            self.RemoveEndpoints(endpointType: localEndpoint, endPointID: l_xmlID, endpointName: l_xmlName, endpointCurrent: counter, endpointCount: groupCount)
                                                        }   // if !self.wipe_data else - end
                                                    } else {
                                                        // populate source server under the selective tab
                                                        DispatchQueue.main.async {
                                                            //print("adding \(l_xmlName) to array")
                                                            self.availableIDsToMigDict[l_xmlName] = l_xmlID
                                                            self.sourceDataArray.append(l_xmlName)
                                                            
                                                            self.sourceDataArray = self.sourceDataArray.sorted{$0.localizedCompare($1) == .orderedAscending}
                                                            self.srcSrvTableView.reloadData()
                                                            
                                                        }   // DispatchQueue.main.async - end
                                                    }   // if self.goSender else - end
                                                    
                                                    counter += 1
                                                }   // for (l_xmlID, l_xmlName) - end
                                            }   //for g in (0...1) - end
                                        }
                                    } else {
                                        if endpoint == self.objectsToMigrate.last {
                                            if self.debug { self.writeToLog(stringOfText: "[getEndpoints] Reached last object to migrate: \(endpoint)\n") }
                                            self.rmDELETE()
                                            self.goButtonEnabled(button_status: true)
                                            completion("Got endpoint - \(endpoint)")
                                        }
                                    }   // if endpointCount - end
                                }   // if let endpointInfo = endpointJSON["computer_groups"] - end
                                
                            case "policies":
                                if self.debug { self.writeToLog(stringOfText: "[getEndpoints] processing \(endpoint)\n") }
                                if let endpointInfo = endpointJSON[endpoint] as? [Any] {
                                    let endpointCount: Int = endpointInfo.count
                                    if self.debug { self.writeToLog(stringOfText: "[getEndpoints] \(endpoint) found: \(endpointCount)\n") }
                                    
                                    var computerPoliciesDict: [Int: String] = [:]
                                    if endpointCount > 0 {
                                        
                                        // create dictionary of existing policies
                                        self.existingEndpoints(destEndpoint: "policies")  {
                                            (result: String) in
                                            if self.debug { self.writeToLog(stringOfText: "[getEndpoints] Returned from existing endpoints: \(result)\n") }
                                            
                                            for _ in (0..<endpointCount) {
                                                //var nonRemotePolicies = 0
                                                // filter out policies created from casper remote - start
                                                for i in (0..<endpointCount) {
                                                    let record = endpointInfo[i] as! [String : AnyObject]
                                                    let nameCheck = record["name"] as! String
                                                    if nameCheck.range(of:"[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] at", options: .regularExpression) == nil && nameCheck != "Update Inventory" {
                                                        computerPoliciesDict[record["id"] as! Int] = nameCheck
                                                    }
                                                }
                                            }
                                            self.availableObjsToMigDict = computerPoliciesDict
                                            let nonRemotePolicies = computerPoliciesDict.count
                                            var counter = 1
                                            for (l_xmlID, l_xmlName) in computerPoliciesDict {
                                                if self.goSender == "goButton" {
                                                    if !self.wipe_data  {
                                                        if self.debug { self.writeToLog(stringOfText: "[getEndpoints] check for ID on \(l_xmlName): \(String(describing: self.currentEPs[l_xmlName]))\n") }
                                                        if self.currentEPs[l_xmlName] != nil {
                                                            if self.debug { self.writeToLog(stringOfText: "[getEndpoints] \(l_xmlName) already exists\n") }
                                                            //self.currentEndpointID = self.currentEPs[l_xmlName]!
                                                            self.endPointByID(endpoint: endpoint, endpointID: l_xmlID, endpointCurrent: counter, endpointCount: nonRemotePolicies, action: "update", destEpId: self.currentEPs[l_xmlName]!, destEpName: l_xmlName)
                                                        } else {
                                                            if self.debug { self.writeToLog(stringOfText: "[getEndpoints] \(l_xmlName) - create\n") }
                                                            if self.debug { self.writeToLog(stringOfText: "[getEndpoints] function - endpoint: \(endpoint), endpointID: \(l_xmlID), endpointCurrent: \(counter), endpointCount: \(endpointCount), action: \"create\", destEpId: 0\n") }
                                                            self.endPointByID(endpoint: endpoint, endpointID: l_xmlID, endpointCurrent: counter, endpointCount: nonRemotePolicies, action: "create", destEpId: 0, destEpName: l_xmlName)
                                                        }
                                                        //self.endPointByID(endpoint: endpoint, endpointID: l_xmlID, endpointCurrent: counter, endpointCount: nonRemotePolicies, action: "create", destEpId: 0)
                                                    } else {
                                                        if self.debug { self.writeToLog(stringOfText: "[getEndpoints] remove - endpoint: \(endpoint)\t endpointID: \(l_xmlID)\t endpointName: \(l_xmlName)\n") }
                                                        self.RemoveEndpoints(endpointType: endpoint, endPointID: l_xmlID, endpointName: l_xmlName, endpointCurrent: counter, endpointCount: nonRemotePolicies)
                                                    }   // if !self.wipe_data else - end
                                                } else {
                                                    // populate source server under the selective tab
                                                    DispatchQueue.main.async {
                                                        //print("adding \(l_xmlName) to array")
                                                        self.availableIDsToMigDict[l_xmlName+" (\(l_xmlID))"] = l_xmlID
                                                        self.sourceDataArray.append(l_xmlName+" (\(l_xmlID))")
                                                        self.sourceDataArray = self.sourceDataArray.sorted{$0.localizedCompare($1) == .orderedAscending}
                                                        self.srcSrvTableView.reloadData()
                                                    }   // DispatchQueue.main.async - end
                                                }   // if self.goSender else - end
                                                counter += 1
                                            }   // for (l_xmlID, l_xmlName) in computerPoliciesDict - end
                                        }   // self.existingEndpoints - end
                                    } else {
                                        if endpoint == self.objectsToMigrate.last {
                                            self.rmDELETE()
                                            self.goButtonEnabled(button_status: true)
                                            completion("Got endpoint - \(endpoint)")
                                        }
                                    }   // if endpointCount > 0
                                }   //if let endpointInfo = endpointJSON - end
                                
                            case "jamfusers", "jamfgroups":
                                let accountsDict = endpointJSON as Dictionary<String, Any>
                                let usersGroups = accountsDict["accounts"] as! Dictionary<String, Any>
                                
                                if let endpointInfo = usersGroups[endpointParent] as? [Any] {
                                    let endpointCount: Int = endpointInfo.count
                                    if self.debug { self.writeToLog(stringOfText: "[getEndpoints] Initial count for \(node) found: \(endpointCount)\n") }
                                    
                                    if self.debug { self.writeToLog(stringOfText: "[getEndpoints] Verify empty dictionary of objects - availableObjsToMigDict count: \(self.availableObjsToMigDict.count)\n") }
                                    
                                    if endpointCount > 0 {
                                        
//                                        self.existingEndpoints(destEndpoint: "accounts")  {
                                        self.existingEndpoints(destEndpoint: endpoint)  {
                                            (result: String) in
                                            if self.debug { self.writeToLog(stringOfText: "[getEndpoints] Returned from existing \(node): \(result)\n") }
                                        
                                            for i in (0..<endpointCount) {
                                                if i == 0 { self.availableObjsToMigDict.removeAll() }
                                                
                                                let record = endpointInfo[i] as! [String : AnyObject]
                                                if !(endpoint == "jamfusers" && record["name"] as! String? == self.dest_user) {
                                                    self.availableObjsToMigDict[record["id"] as! Int] = record["name"] as! String?
                                                }
                                                
                                                if self.debug { self.writeToLog(stringOfText: "[getEndpoints] Current number of \(endpoint) to process: \(self.availableObjsToMigDict.count)\n") }
                                            }   // for i in (0..<endpointCount) end
                                            if self.debug { self.writeToLog(stringOfText: "[getEndpoints] Found total of \(self.availableObjsToMigDict.count) \(endpoint) to process\n") }
                                            
                                            var counter = 1
                                            if self.goSender == "goButton" {
                                                for (l_xmlID, l_xmlName) in self.availableObjsToMigDict {
                                                    if !self.wipe_data  {
                                                        if self.debug { self.writeToLog(stringOfText: "[getEndpoints] check for ID on \(l_xmlName): \(String(describing: self.currentEPs[l_xmlName]))\n") }
                                                        
                                                        if self.currentEPs[l_xmlName] != nil {
                                                            if self.debug { self.writeToLog(stringOfText: "[getEndpoints] \(l_xmlName) already exists\n") }
                                                            //self.currentEndpointID = self.currentEPs[l_xmlName]!
                                                            self.endPointByID(endpoint: endpoint, endpointID: l_xmlID, endpointCurrent: counter, endpointCount: self.availableObjsToMigDict.count, action: "update", destEpId: self.currentEPs[l_xmlName]!, destEpName: l_xmlName)
                                                        } else {
                                                            if self.debug { self.writeToLog(stringOfText: "[getEndpoints] \(l_xmlName) - create\n") }
                                                            if self.debug { self.writeToLog(stringOfText: "[getEndpoints] function - endpoint: \(endpoint), endpointID: \(l_xmlID), endpointCurrent: \(counter), endpointCount: \(endpointCount), action: \"create\", destEpId: 0\n") }
                                                            self.endPointByID(endpoint: endpoint, endpointID: l_xmlID, endpointCurrent: counter, endpointCount: self.availableObjsToMigDict.count, action: "create", destEpId: 0, destEpName: l_xmlName)
                                                        }
                                                    } else {
                                                        if !(endpoint == "jamfusers" && "\(l_xmlName)".lowercased() == self.dest_user.lowercased()) {
                                                            if self.debug { self.writeToLog(stringOfText: "[getEndpoints] remove - endpoint: \(endpoint)\t endpointID: \(l_xmlID)\t endpointName: \(l_xmlName)\n") }
                                                            self.RemoveEndpoints(endpointType: endpoint, endPointID: l_xmlID, endpointName: l_xmlName, endpointCurrent: counter, endpointCount: self.availableObjsToMigDict.count)
                                                        }
                                                        
                                                    }   // if !self.wipe_data else - end
                                                    counter+=1
                                                }   // for (l_xmlID, l_xmlName) in availableObjsToMigDict
                                            } else {
                                                // populate source server under the selective tab
                                                for (l_xmlID, l_xmlName) in self.availableObjsToMigDict {
                                                    DispatchQueue.main.async {
                                                        //print("adding \(l_xmlName) to array")
                                                        self.availableIDsToMigDict[l_xmlName] = l_xmlID
                                                        self.sourceDataArray.append(l_xmlName)
                                                        
                                                        self.srcSrvTableView.reloadData()
                                                        
                                                    }   // DispatchQueue.main.async - end
                                                    counter+=1
                                                }   // for (l_xmlID, l_xmlName) in availableObjsToMigDict
                                                DispatchQueue.main.async {
                                                    //self.sourceDataArray.sort()
                                                    self.sourceDataArray = self.sourceDataArray.sorted{$0.localizedCompare($1) == .orderedAscending}
                                                    
                                                    self.srcSrvTableView.reloadData()
                                                }
                                            }   // if self.goSender else - end
                                        }   // self.existingEndpoints - end
                                    } else {
                                        if endpoint == self.objectsToMigrate.last {
                                            self.rmDELETE()
                                            self.goButtonEnabled(button_status: true)
                                            completion("Got endpoint - \(endpoint)")
                                        }
                                    }// if endpointCount - end
                                }   // end if let buildings, departments...
                              
                            case "computerconfigurations":
                                if let endpointInfo = endpointJSON[self.endpointDefDict[endpoint]!] as? [Any] {
                                    let endpointCount: Int = endpointInfo.count
                                    if self.debug { self.writeToLog(stringOfText: "[getEndpoints] Initial count for \(endpoint) found: \(endpointCount)\n") }
                                    
                                    if self.debug { self.writeToLog(stringOfText: "[getEndpoints] Verify empty dictionary of objects - availableObjsToMigDict count: \(self.availableObjsToMigDict.count)\n") }
                                    
                                    if endpointCount > 0 {
                                        if self.debug { self.writeToLog(stringOfText: "[getEndpoints] Create Id Mappings - start.\n") }
                                        
                                        self.nameIdDict(server: self.source_jp_server, endPoint: "computerconfigurations", id: "sourceId") {
                                            (result: [String:Dictionary<String,Int>]) in
                                            self.idDict.removeAll()
                                            
                                            self.nameIdDict(server: self.source_jp_server, endPoint: "packages", id: "sourceId") {
                                                (result: [String:Dictionary<String,Int>]) in
                                            
                                                self.nameIdDict(server: self.dest_jp_server, endPoint: "packages", id: "destId") {
                                                    (result: [String:Dictionary<String,Int>]) in
                                                    self.packages_id_map = result
                                                    if self.debug { self.writeToLog(stringOfText: "[getEndpoints] packages id map:\n\(self.packages_id_map)\n") }
                                                    self.idDict.removeAll()
                                                    
                                                    self.nameIdDict(server: self.source_jp_server, endPoint: "scripts", id: "sourceId") {
                                                        (result: [String:Dictionary<String,Int>]) in
                                                        
                                                        self.nameIdDict(server: self.dest_jp_server, endPoint: "scripts", id: "destId") {
                                                            (result: [String:Dictionary<String,Int>]) in
                                                            self.scripts_id_map = result
                                                            if self.debug { self.writeToLog(stringOfText: "[getEndpoints] scripts id map:\n\(self.scripts_id_map)\n") }
                                                            self.idDict.removeAll()
                                                            
                                                            self.nameIdDict(server: self.source_jp_server, endPoint: "printers", id: "sourceId") {
                                                                (result: [String:Dictionary<String,Int>]) in
                                                                
                                                                self.nameIdDict(server: self.dest_jp_server, endPoint: "printers", id: "destId") {
                                                                    (result: [String:Dictionary<String,Int>]) in
                                                                    self.printers_id_map = result
                                                                    if self.debug { self.writeToLog(stringOfText: "[getEndpoints] printers id map:\n\(self.printers_id_map)\n")}
                                                                    self.idDict.removeAll()
                                                                    
                                                                    self.nameIdDict(server: self.source_jp_server, endPoint: "directorybindings", id: "sourceId") {
                                                                        (result: [String:Dictionary<String,Int>]) in
                                                                        
                                                                        self.nameIdDict(server: self.dest_jp_server, endPoint: "directorybindings", id: "destId") {
                                                                            (result: [String:Dictionary<String,Int>]) in
                                                                            self.bindings_id_map = result
                                                                            if self.debug { self.writeToLog(stringOfText: "[getEndpoints] bindings id map:\n\(self.bindings_id_map)\n")}
                                                                            self.idDict.removeAll()

                                                                            if self.debug { self.writeToLog(stringOfText: "[getEndpoints] Create Id Mappings - end.\n") }
                                                                            
                                                                            var orderedConfArray = [String]()
                                                                            var movedParentArray = [String]()
                                                                            self.orphanIds.removeAll()
                                                                            //                                        var remainingConfigsArray = [String]()
                                                                            
                                                                            while self.configObjectsDict.count != movedParentArray.count {
                                                                                for (key, _) in self.configObjectsDict {
                                                                                    if ((self.configObjectsDict[key]?["type"] == "Standard") && (movedParentArray.index(of: key) == nil)) || ((movedParentArray.index(of: key) == nil) && (movedParentArray.index(of: (self.configObjectsDict[key]?["parent"])!) != nil)) {
                                                                                        orderedConfArray.append((self.configObjectsDict[key]?["id"])!)
                                                                                        movedParentArray.append(key)
                                                                                        // look for configs missing their parent
                                                                                    } else if (((self.configObjectsDict[key]?["type"])! == "Smart") && (self.configObjectsDict[(self.configObjectsDict[key]?["parent"])!]?.count == nil)) && (movedParentArray.index(of: key) == nil) {
                                                                                        self.writeToLog(stringOfText: "[getEndpoints] Smart config '\(self.configObjectsDict[key]?["parent"] ?? "name not found")' is missing its parent and cannot be migrated.\n")
                                                                                        self.writeToLog(stringOfText: "[getEndpoints] Smart config '\(key)' (child of '\(self.configObjectsDict[key]?["parent"] ?? "name not found")') will be migrated and changed from smart to standard.\n")
                                                                                        orderedConfArray.append((self.configObjectsDict[key]?["id"])!)
                                                                                        movedParentArray.append(key)
                                                                                        self.orphanIds.append((self.configObjectsDict[key]?["id"])!)
                                                                                    }
                                                                                }
                                                                            }
                                                                            if self.wipe_data {
                                                                                orderedConfArray.reverse()
                                                                            }
//                                                                            print("parent array: \(orderedConfArray)")
                                                                            
                                                                            self.existingEndpoints(destEndpoint: "\(endpoint)")  {
                                                                                (result: String) in
                                                                                if self.debug { self.writeToLog(stringOfText: "[getEndpoints] Returned from existing \(endpoint): \(result)\n") }
                                                                                
                                                                                var tmp_availableObjsToMigDict = [Int:String]()
                                                                                
                                                                                for i in (0..<endpointCount) {
//                                                                                    if i == 0 { self.availableObjsToMigDict.removeAll() }
                                                                                    
                                                                                    let record = endpointInfo[i] as! [String : AnyObject]
                                                                                    
                                                                                    tmp_availableObjsToMigDict[record["id"] as! Int] = record["name"] as! String?
                                                                                    
                                                                                }   // for i in (0..<endpointCount) end
                                                                                
                                                                                self.availableObjsToMigDict.removeAll()
                                                                                for orderedId in orderedConfArray {
                                                                                    
                                                                                    self.availableObjsToMigDict[Int(orderedId)!] = tmp_availableObjsToMigDict[Int(orderedId)!]
                                                                                    
                                                                                    if self.debug { self.writeToLog(stringOfText: "[getEndpoints] Current number of \(endpoint) to process: \(self.availableObjsToMigDict.count)\n") }
                                                                                }   // for i in (0..<endpointCount) end
                                                                                
                                                                                
                                                                                if self.debug { self.writeToLog(stringOfText: "[getEndpoints] Found total of \(self.availableObjsToMigDict.count) \(endpoint) to process\n") }
                                                                                
                                                                                var counter = 1
                                                                                if self.goSender == "goButton" {
//                                                                                  for (l_xmlID, l_xmlName) in self.availableObjsToMigDict {
                                                                                    for orderedId in orderedConfArray {
                                                                                        let l_xmlID = Int(orderedId)
                                                                                        let l_xmlName = tmp_availableObjsToMigDict[l_xmlID!]
                                                                                        if (l_xmlID != nil) && (l_xmlName != nil) {
                                                                                            if !self.wipe_data  {
                                                                                                if self.debug { self.writeToLog(stringOfText: "[getEndpoints] check for ID on \(String(describing: l_xmlName)): \(self.currentEPs[l_xmlName!] ?? 0)\n") }
                                                                                                if self.currentEPs[l_xmlName!] != nil {
                                                                                                    if self.debug { self.writeToLog(stringOfText: "[getEndpoints] \(String(describing: l_xmlName)) already exists\n") }
                                                                                                    //self.currentEndpointID = self.currentEPs[l_xmlName]!
                                                                                                    self.endPointByID(endpoint: endpoint, endpointID: l_xmlID!, endpointCurrent: counter, endpointCount: self.availableObjsToMigDict.count, action: "update", destEpId: self.currentEPs[l_xmlName!]!, destEpName: l_xmlName!)
                                                                                                } else {
                                                                                                    if self.debug { self.writeToLog(stringOfText: "[getEndpoints] \(String(describing: l_xmlName)) - create\n") }
                                                                                                    if self.debug { self.writeToLog(stringOfText: "[getEndpoints] function - endpoint: \(endpoint), endpointID: \(String(describing: l_xmlID)), endpointCurrent: \(counter), endpointCount: \(endpointCount), action: \"create\", destEpId: 0\n") }
                                                                                                    self.endPointByID(endpoint: endpoint, endpointID: l_xmlID!, endpointCurrent: counter, endpointCount: self.availableObjsToMigDict.count, action: "create", destEpId: 0, destEpName: l_xmlName!)
                                                                                                }
                                                                                            } else {
                                                                                                if self.debug { self.writeToLog(stringOfText: "[getEndpoints] remove - endpoint: \(endpoint)\t endpointID: \(String(describing: l_xmlID))\t endpointName: \(String(describing: l_xmlName))\n") }
                                                                                                self.RemoveEndpoints(endpointType: endpoint, endPointID: l_xmlID!, endpointName: l_xmlName!, endpointCurrent: counter, endpointCount: self.availableObjsToMigDict.count)
                                                                                            }   // if !self.wipe_data else - end
                                                                                        }
                                                                                            counter+=1
                                                                                    }   // for (l_xmlID, l_xmlName) in availableObjsToMigDict
                                                                                } else {
                                                                                    // populate source server under the selective tab
                                                                                    // for (l_xmlID, l_xmlName) in self.availableObjsToMigDict {
                                                                                    for orderedId in orderedConfArray {
                                                                                        let l_xmlID = Int(orderedId)
                                                                                        let l_xmlName = tmp_availableObjsToMigDict[l_xmlID!]
                                                                                        DispatchQueue.main.async {
                                                                                            //print("adding \(l_xmlName) to array")
                                                                                            self.availableIDsToMigDict[l_xmlName!] = l_xmlID
                                                                                            self.sourceDataArray.append(l_xmlName!)
                                                                                            
                                                                                            self.srcSrvTableView.reloadData()
                                                                                            
                                                                                        }   // DispatchQueue.main.async - end
                                                                                        counter+=1
                                                                                    }   // for (l_xmlID, l_xmlName) in availableObjsToMigDict
                                                                                    DispatchQueue.main.async {
                                                                                        //self.sourceDataArray.sort()
                                                                                        self.sourceDataArray = self.sourceDataArray.sorted{$0.localizedCompare($1) == .orderedAscending}
                                                                                        
                                                                                        self.srcSrvTableView.reloadData()
                                                                                    }
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
                                        if endpoint == self.objectsToMigrate.last {
                                            self.rmDELETE()
                                            self.goButtonEnabled(button_status: true)
                                            completion("Got endpoint - \(endpoint)")
                                        }
                                    }   // if endpointCount > 0 - end
                            }   // end if computerconfigurations
                                
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
            semaphore.wait()
            if self.goSender == "selectToMigrateButton" {
                self.goButtonEnabled(button_status: true)
            }
            
        }   // theOpQ - end
        completion("Got endpoint - \(endpoint)")
    }
    func endPointByID(endpoint: String, endpointID: Int, endpointCurrent: Int, endpointCount: Int, action: String, destEpId: Int, destEpName: String) {
//    func endPointByID(endpoint: String, endpointID: Int, endpointCurrent: Int, endpointCount: Int, action: String, destEpId: Int) {
        URLCache.shared.removeAllCachedResponses()
        if self.debug { self.writeToLog(stringOfText: "[endPointByID] endpoint passed to endPointByID: \(endpoint)\n") }
        theOpQ.maxConcurrentOperationCount = 1
        let semaphore = DispatchSemaphore(value: 0)
        //
        //        endpoint == "jamfusers" ? (subnode == "userid"):(subnode == "groupid")
        
        var localEndPointType = ""
        switch endpoint {
        case "smartcomputergroups", "staticcomputergroups":
            localEndPointType = "computergroups"
        case "smartiosgroups", "staticiosgroups":
            localEndPointType = "mobiledevicegroups"
        case "smartusergroups", "staticusergroups":
            localEndPointType = "usergroups"
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
                if self.debug { self.writeToLog(stringOfText: "[endPointByID] fetching XML from: \(myURL)\n") }
                let encodedURL = NSURL(string: myURL)
                let request = NSMutableURLRequest(url: encodedURL! as URL)
                request.httpMethod = "GET"
                let configuration = URLSessionConfiguration.default
                configuration.httpAdditionalHeaders = ["Authorization" : "Basic \(self.sourceBase64Creds)", "Content-Type" : "text/xml", "Accept" : "text/xml"]
                let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
                let task = session.dataTask(with: request as URLRequest, completionHandler: {
                    (data, response, error) -> Void in
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        //                    print("EA data:")
                        //                    print(NSString(data: data!, encoding: String.Encoding.utf8.rawValue)!)
                        var PostXML = String(data: data!, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
                        // strip out <id> tag from XML
                        //                    let regexID = try! NSRegularExpression(pattern: "<id>+[0-9]+</id>", options:.caseInsensitive)
                        //                    PostXML = regexID.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "")
                        
                        //PostXML = PostXML.replacingOccurrences(of: "(?:\\r|\\n)+", with: "", options: .regularExpression)

                        if endpoint != "computerconfigurations" {
                            for xmlTag in ["id"] {
                                PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag)
                            }
                        } else {
                            let regexComp = try! NSRegularExpression(pattern: "<general><id>(.*?)</id>", options:.caseInsensitive)
                            PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<general>")
                        }
                        
                        // check scope options for mobiledeviceconfigurationprofiles, osxconfigurationprofiles, and restrictedsoftware - start
                        switch endpoint {
                            case "mobiledeviceconfigurationprofiles":
                                if !self.scopeMcpCopy {
                                    PostXML = self.rmXmlData(theXML: PostXML, theTag: "scope")
                                }
                            case "policies":
                                if !self.scopePoliciesCopy {
                                    PostXML = self.rmXmlData(theXML: PostXML, theTag: "scope")
                                }
                                if self.policyPoliciesDisable {
                                    PostXML = self.disable(theXML: PostXML)
                                }
                            case "osxconfigurationprofiles":
                                if !self.scopeOcpCopy {
                                    PostXML = self.rmXmlData(theXML: PostXML, theTag: "scope")
                                }
                           case "restrictedsoftware":
                                if !self.scopeRsCopy {
                                    PostXML = self.rmXmlData(theXML: PostXML, theTag: "scope")
                                }
//                            case "staticcomputergroups":  // handled below in computers case
//                            case "staticiosgroups":   // handled below in mobiledevicegroups case
//                                if !self.scopeSigCopy {
//                                    PostXML = self.rmXmlData(theXML: PostXML, theTag: "scope")
//                            }
                            case "staticusergroups":
                                if !self.scopeUsersCopy {
                                    PostXML = self.rmXmlData(theXML: PostXML, theTag: "users")
                            }
                            default:
                                break
                        }
                        // check scope options for mobiledeviceconfigurationprofiles, osxconfigurationprofiles, and restrictedsoftware - end
                        
                        
                        switch endpoint {
                        case "buildings", "departments", "sites", "categories", "distributionpoints", "dockitems", "netbootservers", "softwareupdateservers", "computerextensionattributes", "computerconfigurations", "scripts", "printers", "osxconfigurationprofiles", "patchpolicies", "mobiledeviceconfigurationprofiles", "mobiledeviceapplications", "advancedmobiledevicesearches", "mobiledeviceextensionattributes", "mobiledevicegroups", "smartiosgroups", "staticiosgroups", "mobiledevices", "smartusergroups", "staticusergroups", "userextensionattributes", "advancedusersearches", "restrictedsoftware":
                            if self.debug { self.writeToLog(stringOfText: "[endPointByID] processing \(endpoint) - verbose\n") }
                            //print("\nXML: \(PostXML)")
                            
                            // clean up PostXML, remove unwanted/conflicting data
                            switch endpoint {
                            case "advancedusersearches":
                                for xmlTag in ["users"] {
                                    PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag)
                                }
                                
                            case "advancedmobiledevicesearches", "mobiledevicegroups", "smartiosgroups", "staticiosgroups":
//                                 !self.scopeSigCopy
                                if (PostXML.range(of:"<is_smart>true</is_smart>") != nil || !self.scopeSigCopy) {
                                    PostXML = self.rmXmlData(theXML: PostXML, theTag: "mobile_devices")
                                }
//                                for xmlTag in ["mobile_devices"] {
//                                    PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag)
//                                }
                                
//                            case "mobiledeviceconfigurationprofiles":
//                                for xmlTag in ["scope"] {
//                                    PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag)
//                                }
                                
                            case "mobiledeviceapplications":
                                for xmlTag in ["scope"] {
                                    PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag)
                                }
                                
                                // update server reference of icons to new server
                                //                            let trimmedDestUrlArray = self.dest_jp_server.components(separatedBy: ":")
                                //                            let trimmedDestUrl = trimmedDestUrlArray[1]
                                let regexComp = try! NSRegularExpression(pattern: "\(self.source_jp_server)", options:.caseInsensitive)
                                PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "\(self.dest_jp_server)")
                                
                            case "mobiledevices":
                                for xmlTag in ["initial_entry_date_epoch", "initial_entry_date_utc", "last_enrollment_epoch", "last_enrollment_utc", "1applications", "certificates", "configuration_profiles", "provisioning_profiles", "mobile_device_groups", "extension_attributes"] {
                                    PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag)
                                }
                                
                            case "smartusergroups", "staticusergroups":
                                for xmlTag in ["full_name", "phone_number", "email_address"] {
                                    PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag)
                                }
                                
                            case "computerconfigurations":
                                if self.debug { self.writeToLog(stringOfText: "[endPointByID] cleaning up computerconfigurations - verbose\n") }
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
                                if self.orphanIds.index(of: "\(endpointID)") != nil {
                                    let regexComp = try! NSRegularExpression(pattern: "<type>Smart<type>", options:.caseInsensitive)
                                    PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<type>Standard<type>")
                                    let regexComp2 = try! NSRegularExpression(pattern: "<parent>(.*?)</parent>", options:.caseInsensitive)
                                    PostXML = regexComp2.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "")
                                }
                                for xmlTag in ["script_contents", "script_contents_encoded", "ppd_contents"] {
                                    PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag)
                                }
                                
                            default: break
                            }
                            
                            //                        DispatchQueue.main.async {
                            if self.getEndpointInProgress != endpoint {
                                self.endpointInProgress = endpoint
                                self.getStatusInit(endpoint: endpoint, count: endpointCount)
                                
                            }
                            self.get_completed_field.stringValue = "\(endpointCurrent)"
                            
                            //                        }
                            if self.tagValue(xmlString: PostXML, xmlTag: "description") != "Extension Attribute provided by JAMF Nation patch service" {
                                self.CreateEndpoints(endpointType: endpoint, endPointXML: PostXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, destEpId: destEpId, ssIconName: "", ssIconUri: "")
                            } else {
                                // Currently patch EAs are not migrated - handle those here
                                if self.counters[endpoint]?["fail"] != endpointCount-1 {
                                    self.labelColor(endpoint: endpoint, theColor: self.yellowText)
                                } else {
                                    // every EA failed, and a patch EA was the last on the list
                                    self.labelColor(endpoint: endpoint, theColor: self.redText)
                                }
                                // update global counters
                                let patchEaName = self.getName(endpoint: endpoint, objectXML: PostXML)
//                                if self.counters[endpoint]?["fail"] == nil {
//                                    self.counters[endpoint]?["fail"] = 0
//                                }
                                let localTmp = (self.counters[endpoint]?["fail"])!
                                self.counters[endpoint]?["fail"] = localTmp + 1
                                if var summaryArray = self.summaryDict[endpoint]?["fail"] {
                                    summaryArray.append(patchEaName)
                                    self.summaryDict[endpoint]?["fail"] = summaryArray
                                }
                                self.writeToLog(stringOfText: "[endPointByID] Patch EAs are not migrated, skipping \(patchEaName)\n")
                                self.postCount += 1
                                if self.objectsToMigrate.last == endpoint && endpointCount == endpointCurrent {
                                    //self.go_button.isEnabled = true
                                    self.rmDELETE()
                                    self.goButtonEnabled(button_status: true)
                                    print("Done")
                                }
                            }
                            
                        case "directorybindings", "ldapservers":
                            if self.debug { self.writeToLog(stringOfText: "[endPointByID] processing ldapservers - verbose\n") }
                            // remove password from XML, since it doesn't work on the new server
                            let regexComp = try! NSRegularExpression(pattern: "<password_sha256 since=\"9.23\">(.*?)</password_sha256>", options:.caseInsensitive)
                            PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "")
                            //print("\nXML: \(PostXML)")
                            
                            if self.getEndpointInProgress != endpoint {
                                self.endpointInProgress = endpoint
                                self.getStatusInit(endpoint: endpoint, count: endpointCount)
                            }
                            self.get_completed_field.stringValue = "\(endpointCurrent)"
                            
                            self.CreateEndpoints(endpointType: endpoint, endPointXML: PostXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, destEpId: destEpId, ssIconName: "", ssIconUri: "")
                            
                        case "advancedcomputersearches":
                            if self.debug { self.writeToLog(stringOfText: "[endPointByID] processing advancedcomputersearches - verbose\n") }
                            // clean up some data from XML
                            for xmlTag in ["computers"] {
                                PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag)
                            }
                            
                            //print("\nXML: \(PostXML)")
                            
                            if self.getEndpointInProgress != endpoint {
                                self.endpointInProgress = endpoint
                                self.getStatusInit(endpoint: endpoint, count: endpointCount)
                            }
                            self.get_completed_field.stringValue = "\(endpointCurrent)"
                            
                            self.CreateEndpoints(endpointType: endpoint, endPointXML: PostXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, destEpId: destEpId, ssIconName: "", ssIconUri: "")
                            
                            
                        case "computers":
                            if self.debug { self.writeToLog(stringOfText: "[endPointByID] processing computers - verbose\n") }
                            // clean up some data from XML
                            for xmlTag in ["package", "mapped_printers", "plugins", "running_services", "licensed_software", "computer_group_memberships", "managed", "management_username"] {
                                PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag)
                            }
                            
                            let regexComp = try! NSRegularExpression(pattern: "<management_password_sha256 since=\"9.23\">(.*?)</management_password_sha256>", options:.caseInsensitive)
                            PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "")
                            PostXML = PostXML.replacingOccurrences(of: "<xprotect_version/>", with: "")
                            //print("\nXML: \(PostXML)")
                            
                            if self.getEndpointInProgress != endpoint {
                                self.endpointInProgress = endpoint
                                self.getStatusInit(endpoint: endpoint, count: endpointCount)
                            }
                            self.get_completed_field.stringValue = "\(endpointCurrent)"
                            
                            self.CreateEndpoints(endpointType: endpoint, endPointXML: PostXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, destEpId: destEpId, ssIconName: "", ssIconUri: "")
                            
                        case "networksegments":
                            if self.debug { self.writeToLog(stringOfText: "[endPointByID] processing network segments - verbose\n") }
                            // remove items not transfered; distribution points, netboot server, SUS from XML
                            let regexDistro1 = try! NSRegularExpression(pattern: "<distribution_server>(.*?)</distribution_server>", options:.caseInsensitive)
                            let regexDistro2 = try! NSRegularExpression(pattern: "<distribution_point>(.*?)</distribution_point>", options:.caseInsensitive)
                            let regexDistro3 = try! NSRegularExpression(pattern: "<url>(.*?)</url>", options:.caseInsensitive)
                            let regexNetBoot = try! NSRegularExpression(pattern: "<netboot_server>(.*?)</netboot_server>", options:.caseInsensitive)
                            let regexSUS = try! NSRegularExpression(pattern: "<swu_server>(.*?)</swu_server>", options:.caseInsensitive)
                            PostXML = regexDistro1.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<distribution_server/>")
                            // if not migrating file shares remove then from network segments xml - start
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
                            
                            //print("\nXML: \(PostXML)")
                            
                            if self.getEndpointInProgress != endpoint {
                                self.endpointInProgress = endpoint
                                self.getStatusInit(endpoint: endpoint, count: endpointCount)
                            }
                            self.get_completed_field.stringValue = "\(endpointCurrent)"
                            
                            self.CreateEndpoints(endpointType: endpoint, endPointXML: PostXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, destEpId: destEpId, ssIconName: "", ssIconUri: "")
                            
                        case "computergroups", "smartcomputergroups", "staticcomputergroups":
                            if self.debug { self.writeToLog(stringOfText: "[endPointByID] processing \(endpoint) - verbose\n") }
                            // remove computers that are a member of a smart group
                            if (PostXML.range(of:"<is_smart>true</is_smart>") != nil || !self.scopeScgCopy) {
                                PostXML = self.rmXmlData(theXML: PostXML, theTag: "computers")
                            }
//                            if PostXML.range(of:"<is_smart>true</is_smart>") != nil {
//                                let regexComp = try! NSRegularExpression(pattern: "<computers>(.*?)</computers>", options:.caseInsensitive)
//                                PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "")
//                            }
                            //print("\n\(endpoint) XML: \(PostXML)\n")
                            
                            if self.getEndpointInProgress != endpoint {
                                self.endpointInProgress = endpoint
                                self.getStatusInit(endpoint: endpoint, count: endpointCount)
                            }
                            self.get_completed_field.stringValue = "\(endpointCurrent)"
                            
                            self.CreateEndpoints(endpointType: endpoint, endPointXML: PostXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, destEpId: destEpId, ssIconName: "", ssIconUri: "")
                            
                        case "packages":
                            if self.debug { self.writeToLog(stringOfText: "[endPointByID] processing packages - verbose\n") }
                            // remove 'No category assigned' from XML
                            let regexComp = try! NSRegularExpression(pattern: "<category>No category assigned</category>", options:.caseInsensitive)
                            PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<category/>")
                            //print("\nXML: \(PostXML)")
                            
                            if self.getEndpointInProgress != endpoint {
                                self.endpointInProgress = endpoint
                                self.getStatusInit(endpoint: endpoint, count: endpointCount)
                            }
                            self.get_completed_field.stringValue = "\(endpointCurrent)"
                            
                            self.CreateEndpoints(endpointType: endpoint, endPointXML: PostXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, destEpId: destEpId, ssIconName: "", ssIconUri: "")
                            
                        case "policies":
                            var iconName = ""
                            var iconUri = ""
                            if self.debug { self.writeToLog(stringOfText: "[endPointByID] processing policies - verbose\n") }
                            // check for a self service icon
                            if PostXML.range(of: "</self_service_icon>") != nil {
                                let selfServiceIconXml = self.tagValue(xmlString: PostXML, xmlTag: "self_service_icon")
                                iconName = self.tagValue(xmlString: selfServiceIconXml, xmlTag: "filename")
                                iconUri = self.tagValue(xmlString: selfServiceIconXml, xmlTag: "uri").replacingOccurrences(of: "//iconservlet", with: "/iconservlet")
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
                            
                            // remove individual objects that are scoped to the policy from XML
                            for xmlTag in ["self_service_icon", "computers"] {
                                PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag)
                            }
                            
                            
                            let regexComp = try! NSRegularExpression(pattern: "<management_password_sha256 since=\"9.23\">(.*?)</management_password_sha256>", options:.caseInsensitive)
                            PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "")
                            //print("\nXML: \(PostXML)")
                            
                            if self.getEndpointInProgress != endpoint {
                                self.endpointInProgress = endpoint
                                self.getStatusInit(endpoint: endpoint, count: endpointCount)
                            }
                            self.get_completed_field.stringValue = "\(endpointCurrent)"
                            
                            // create the policy
                            self.CreateEndpoints(endpointType: endpoint, endPointXML: PostXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, destEpId: destEpId, ssIconName: iconName, ssIconUri: iconUri)
                            
                            // create the self service icon if present
//                            self.uploadSelfServiceIcon(iconName: iconName, iconUri: iconUri, )
                            
                        case "users":
                            if self.debug { self.writeToLog(stringOfText: "[endPointByID] processing users - verbose\n") }
                            
                            let regexComp = try! NSRegularExpression(pattern: "<self_service_icon>(.*?)</self_service_icon>", options:.caseInsensitive)
                            PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<self_service_icon/>")
                            // remove photo reference from XML
                            for xmlTag in ["enable_custom_photo_url", "custom_photo_url", "links"] {
                                PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag)
                            }
                            //print("\nXML: \(PostXML)")
                            
                            if self.getEndpointInProgress != endpoint {
                                self.endpointInProgress = endpoint
                                self.getStatusInit(endpoint: endpoint, count: endpointCount)
                            }
                            self.get_completed_field.stringValue = "\(endpointCurrent)"
                            
                            self.CreateEndpoints(endpointType: endpoint, endPointXML: PostXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, destEpId: destEpId, ssIconName: "", ssIconUri: "")
                            
                        case "jamfusers", "jamfgroups", "accounts/userid", "accounts/groupid":
                            var accountType = ""
                            switch endpoint {
                            case "accounts/userid":
                                accountType = "jamfusers"
                            case "accounts/groupid":
                                accountType = "jamfgroups"
                            default:
                                accountType = endpoint
                            }
                            
                            if self.debug { self.writeToLog(stringOfText: "[endPointByID] processing jamf users/groups - verbose\n") }
                            // remove password from XML, since it doesn't work on the new server
                            let regexComp = try! NSRegularExpression(pattern: "<password_sha256 since=\"9.32\">(.*?)</password_sha256>", options:.caseInsensitive)
                            PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "")
                            //print("\nXML: \(PostXML)")
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
                            
                            if self.getEndpointInProgress != endpoint {
                                self.endpointInProgress = endpoint
                                self.getStatusInit(endpoint: endpoint, count: endpointCount)
                            }
                            self.get_completed_field.stringValue = "\(endpointCurrent)"
                            
                            self.CreateEndpoints(endpointType: accountType, endPointXML: PostXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, destEpId: destEpId, ssIconName: "", ssIconUri: "")
                            
                        default:
                            if self.debug { self.writeToLog(stringOfText: "[endPointByID] Unknown endpoint: \(endpoint)\n") }
                        }   // switch - end
                        
                        if httpResponse.statusCode >= 199 && httpResponse.statusCode <= 299 {
                            //print("\(httpResponse.statusCode)\t\t\(httpResponse.allHeaderFields)")
                        } else {
                            //print("\(httpResponse.statusCode)\t\t\(httpResponse.allHeaderFields)")
                        }   // if httpResponse/else - end
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
    
    func CreateEndpoints(endpointType: String, endPointXML: String, endpointCurrent: Int, endpointCount: Int, action: String, destEpId: Int, ssIconName: String, ssIconUri: String) {
        // this is where we create the new endpoint
        if self.debug { self.writeToLog(stringOfText: "Creating new: \(endpointType)\n") }
//        var createDestUrl = createDestUrlBase
        let destinationEpId = destEpId
        //if self.debug { self.writeToLog(stringOfText: "----- Posting #\(endpointCurrent): \(endpointType) -----\n") }
        theCreateQ.maxConcurrentOperationCount = 1
        let semaphore = DispatchSemaphore(value: 0)
        let encodedXML = endPointXML.data(using: String.Encoding.utf8)
        var localEndPointType = ""
        
        switch endpointType {
        case "smartcomputergroups", "staticcomputergroups":
            localEndPointType = "computergroups"
        case "smartiosgroups", "staticiosgroups":
            localEndPointType = "mobiledevicegroups"
        case "smartusergroups", "staticusergroups":
            localEndPointType = "usergroups"
        default:
            localEndPointType = endpointType
        }
        var responseData = ""
        //        if endpointType == "smartcomputergroups" || endpointType == "staticcomputergroups" {
        //            localEndPointType = "computergroups"
        //        }
        
        var createDestUrl = "\(createDestUrlBase)/" + localEndPointType + "/id/\(destinationEpId)"
        if self.debug { self.writeToLog(stringOfText: "Original Dest. URL: \(createDestUrl)\n") }
        createDestUrl = createDestUrl.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
        createDestUrl = createDestUrl.replacingOccurrences(of: "/JSSResource/jamfusers/id", with: "/JSSResource/accounts/userid")
        createDestUrl = createDestUrl.replacingOccurrences(of: "/JSSResource/jamfgroups/id", with: "/JSSResource/accounts/groupid")
        
        theCreateQ.addOperation {
//            DispatchQueue.main.async {
//                self.createDestUrl = "\(self.dest_jp_server_field.stringValue)/JSSResource/" + localEndPointType + "/id/\(destinationEpId)"

//            }
            
            if self.debug { self.writeToLog(stringOfText: "Action: \(action)\t URL: \(createDestUrl)\t Object \(endpointCurrent) of \(endpointCount)\n") }
            if self.debug { self.writeToLog(stringOfText: "Object XML: \(endPointXML)\n") }
            
            if endpointCurrent == 1 {
                self.postCount = 1
                // initial counters
                // changed 20180603 (re-enabled)
                self.counters[endpointType] = ["create":0, "update":0, "fail":0]
                self.summaryDict[endpointType] = ["create":[], "update":[], "fail":[]]
            } else {
                self.postCount += 1
                print("createDestUrl: \(createDestUrl)\n")
            }
            let encodedURL = NSURL(string: createDestUrl)
            let request = NSMutableURLRequest(url: encodedURL! as URL)
            if action == "create" {
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
//                        if self.debug { self.writeToLog(stringOfText: "\n\n[- debug -] full response from create:\n\(responseData)") }
//                        print("create data response: \(responseData)")
                    } else {
                        if self.debug { self.writeToLog(stringOfText: "\n\n[- debug -] No data was returned from post/put.\n") }
                    }
                    
                    DispatchQueue.main.async {
                        self.migrationStatus(endpoint: endpointType, count: endpointCount)
                        
                        self.objects_completed_field.stringValue = "\(self.postCount)"

                        if self.objectsToMigrate.last == localEndPointType && endpointCount == endpointCurrent {
                            //self.go_button.isEnabled = true
                            self.rmDELETE()
                            self.goButtonEnabled(button_status: true)
                            print("Done")
                        }
                    }   // DispatchQueue.main.async - end
                    // look to see if we are processing the next endpointType - start
                    if self.endpointInProgress != endpointType {
                        self.writeToLog(stringOfText: "Migrating \(endpointType)\n")
                        self.endpointInProgress = endpointType
                        //                        self.changeColor = true
                        self.POSTsuccessCount = 0
                        //                        self.progressCountArray["\(endpointType)"] = 0
                    }   // look to see if we are processing the next localEndPointType - end
                    
                    DispatchQueue.main.async {
                    
                    if httpResponse.statusCode >= 199 && httpResponse.statusCode <= 299 {
                        self.writeToLog(stringOfText: "[\(localEndPointType)] succeeded: \(self.getName(endpoint: endpointType, objectXML: endPointXML))\n")
                        
                        self.POSTsuccessCount += 1
                        self.progressCountArray["\(endpointType)"] = self.progressCountArray["\(endpointType)"]!+1
                        if endpointCount == endpointCurrent && self.progressCountArray["\(endpointType)"] == endpointCount {
                            self.labelColor(endpoint: endpointType, theColor: self.greenText)
                        }
                        
                        // update global counters
//                        if self.counters[endpointType]?["\(action)"] == nil {
//                            self.counters[endpointType]?["\(action)"] = 0
//                        }
                        let localTmp = (self.counters[endpointType]?["\(action)"])!
//                        print("localTmp: \(localTmp)")
                        self.counters[endpointType]?["\(action)"] = localTmp + 1
                        
                        if var summaryArray = self.summaryDict[endpointType]?["\(action)"] {
                            summaryArray.append(self.getName(endpoint: endpointType, objectXML: endPointXML))
                            self.summaryDict[endpointType]?["\(action)"] = summaryArray
                        }
                        if (endpointType == "policies") && (action == "create") {
                            if (ssIconName != "") && (ssIconUri != "") {
//                                print("new policy id: \(self.tagValue(xmlString: responseData, xmlTag: "id"))")
//                                print("iconName: "+ssIconName+"\tURL: \(ssIconUri)")
//                                DispatchQueue.main.async {
                                    createDestUrl = "\(self.createDestUrlBase)/fileuploads/policies/id/\(self.tagValue(xmlString: responseData, xmlTag: "id"))"
//                                }
                                createDestUrl = createDestUrl.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
//                                self.selfServiceIconGet(newPolicyId: "\(self.tagValue(xmlString: responseData, xmlTag: "id"))", ssIconName: ssIconName, ssIconUri: ssIconUri)
                                let curlResult = self.myExitValue(cmd: "/bin/bash", args: "-c", "/usr/bin/curl -sk \(ssIconUri) -o \"/tmp/\(ssIconName)\"")
                                if self.debug { self.writeToLog(stringOfText: "result of icon GET: \(curlResult).") }
//                                print("result of icon GET: "+curlResult)
                                let curlResult2 = self.myExitValue(cmd: "/bin/bash", args: "-c", "/usr/bin/curl -sk -H \"Authorization:Basic \(self.destBase64Creds)\" \(createDestUrl) -F \"name=@/tmp/\(ssIconName)\"  -X POST")
                                if self.debug { self.writeToLog(stringOfText: "result of icon POST: \(curlResult2).") }
//                                print("result of icon POST: "+curlResult2)
                                if self.myExitValue(cmd: "/bin/bash", args: "-c", "/bin/rm \"/tmp/\(ssIconName)\"") != "0" {
                                    if self.debug { self.writeToLog(stringOfText: "unable to delete /tmp/\(ssIconName).") }
                                }
                            }
                        }
                        
                    } else {
                        // create failed
                        self.labelColor(endpoint: endpointType, theColor: self.yellowText)
                        //                        self.changeColor = false
                        self.writeToLog(stringOfText: "\n\n**** [\(localEndPointType)] \(self.getName(endpoint: endpointType, objectXML: endPointXML)) - Failed\n")
                                                
                        // Write xml for degugging - start
                        if self.debug { self.writeToLog(stringOfText: "\(endPointXML)\n")}
                        self.writeToLog(stringOfText: "HTTP status code: \(httpResponse.statusCode)\n")
                        let errorMsg = self.tagValue2(xmlString: responseData, startTag: "<p>Error: ", endTag: "</p>")
                        if errorMsg != "" {
                            self.writeToLog(stringOfText: "Create/update error: \(errorMsg)\n\n")
                        } else {
                            if self.debug { self.writeToLog(stringOfText: "Error parsing conflict.") }
                        }
                        // Write xml for degugging - end
                        
                        if self.progressCountArray["\(endpointType)"] == 0 && endpointCount == endpointCurrent {
                            self.labelColor(endpoint: endpointType, theColor: self.redText)
                        }
                        if self.debug { self.writeToLog(stringOfText: "\n\n[- debug -] ---------- xml of failed upload ----------\n") }
                        if self.debug { self.writeToLog(stringOfText: "\(endPointXML)\n") }
                        if self.debug { self.writeToLog(stringOfText: "---------- status code ----------\n") }
                        if self.debug { self.writeToLog(stringOfText: "\(httpResponse.statusCode)\n") }
                        if self.debug { self.writeToLog(stringOfText: "---------- response ----------\n") }
                        if self.debug { self.writeToLog(stringOfText: "\(httpResponse)\n") }
                        if self.debug { self.writeToLog(stringOfText: "---------- response ----------\n\n") }
                        //                        401 - wrong username and/or password
                        //                        409 - unable to create object; already exists or data missing or xml error
                        
                        // update global counters
//                        if self.counters[endpointType]?["fail"] == nil {
//                            self.counters[endpointType]?["fail"] = 0
//                        }
                        let localTmp = (self.counters[endpointType]?["fail"])!
                        self.counters[endpointType]?["fail"] = localTmp + 1
                        if var summaryArray = self.summaryDict[endpointType]?["fail"] {
                            summaryArray.append(self.getName(endpoint: endpointType, objectXML: endPointXML))
                            self.summaryDict[endpointType]?["fail"] = summaryArray
                        }
                    }
                    }
                }   // if let httpResponse = response - end
                
                if self.debug { self.writeToLog(stringOfText: "POST or PUT Operation: \(request.httpMethod)\n") }
                
                if self.debug { self.writeToLog(stringOfText: "endpoint: \(localEndPointType)-\(endpointCurrent)\t Total: \(endpointCount)\t Succeeded: \(self.POSTsuccessCount)\t No Failures: \(self.changeColor)\t SuccessArray \(String(describing: self.progressCountArray["\(localEndPointType)"]))!\n") }
                semaphore.signal()
                if error != nil {
                }
            })
            task.resume()
            semaphore.wait()
            
        }   // theCreateQ.addOperation - end
    }
    
    func RemoveEndpoints(endpointType: String, endPointID: Int, endpointName: String, endpointCurrent: Int, endpointCount: Int) {
        // this is where we delete the endpoint
        var removeDestUrl = ""
        theOpQ.maxConcurrentOperationCount = 1
        let semaphore = DispatchSemaphore(value: 0)
        var localEndPointType = ""
        switch endpointType {
        case "smartcomputergroups", "staticcomputergroups":
            localEndPointType = "computergroups"
        case "smartiosgroups", "staticiosgroups":
            localEndPointType = "mobiledevicegroups"
        case "smartusergroups", "staticusergroups":
            localEndPointType = "usergroups"
        default:
            localEndPointType = endpointType
        }

        if endpointName != "All Managed Clients" && endpointName != "All Managed Servers" && endpointName != "All Managed iPads" && endpointName != "All Managed iPhones" && endpointName != "All Managed iPod touches" {
            
            removeDestUrl = "\(self.dest_jp_server_field.stringValue)/JSSResource/" + localEndPointType + "/id/\(endPointID)"
            if self.debug { self.writeToLog(stringOfText: "\n[- debug -] raw removal URL: \(removeDestUrl)\n") }
            removeDestUrl = removeDestUrl.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
            removeDestUrl = removeDestUrl.replacingOccurrences(of: "/JSSResource/jamfusers/id", with: "/JSSResource/accounts/userid")
            removeDestUrl = removeDestUrl.replacingOccurrences(of: "/JSSResource/jamfgroups/id", with: "/JSSResource/accounts/groupid")
            removeDestUrl = removeDestUrl.replacingOccurrences(of: "id/id/", with: "id/")
            
            theOpQ.addOperation {

                if self.debug { self.writeToLog(stringOfText: "removing \(endpointType) with ID \(endPointID)  -  Object \(endpointCurrent) of \(endpointCount)\n") }
                if self.debug { self.writeToLog(stringOfText: "\n[- debug -] removal URL: \(removeDestUrl)\n") }
                
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
                        
                        DispatchQueue.main.async {
                            self.migrationStatus(endpoint: endpointType, count: endpointCount)
                            self.objects_completed_field.stringValue = "\(endpointCurrent)"
                            
                            // look to see if we are processing the next endpointType - start
                            if self.endpointInProgress != endpointType {
                                self.endpointInProgress = endpointType
                                self.changeColor = true
                                self.POSTsuccessCount = 0
                                self.writeToLog(stringOfText: "Removing \(endpointType)\n")
                            }   // look to see if we are processing the next endpointType - end
                            //                            self.object_name_field.stringValue = endpointType
                            //                            self.objects_completed_field.stringValue = "\(endpointCurrent)"
                            
                        }
                        if httpResponse.statusCode >= 199 && httpResponse.statusCode <= 299 {
                            self.writeToLog(stringOfText: "\t\(endpointName)\n")
                            self.POSTsuccessCount += 1
                            if endpointCount == endpointCurrent && self.changeColor {
                                self.labelColor(endpoint: endpointType, theColor: self.greenText)
                            }
                            
                        } else {
                            self.labelColor(endpoint: endpointType, theColor: self.yellowText)
                            self.changeColor = false
                            self.writeToLog(stringOfText: "**** Failed to remove: \(endpointName)\n")
                            if self.POSTsuccessCount == 0 && endpointCount == endpointCurrent {
                                self.labelColor(endpoint: endpointType, theColor: self.redText)
                            }
                            if self.debug { self.writeToLog(stringOfText: "\n\n[- debug -] ---------- endpoint info ----------\n") }
                            if self.debug { self.writeToLog(stringOfText: "Type: \(endpointType)\t Name: \(endpointName)\t ID: \(endPointID)\n") }
                            if self.debug { self.writeToLog(stringOfText: "---------- status code ----------\n") }
                            if self.debug { self.writeToLog(stringOfText: "\(httpResponse.statusCode)\n") }
                            if self.debug { self.writeToLog(stringOfText: "---------- response ----------\n") }
                            if self.debug { self.writeToLog(stringOfText: "\(httpResponse)\n") }
                            if self.debug { self.writeToLog(stringOfText: "---------- response ----------\n\n") }
                        }
                        
                    }
                    if self.activeTab() != "selective" {
                        if self.objectsToMigrate.last == localEndPointType && endpointCount == endpointCurrent {
                            // check for file that allows deleting data from destination server, delete if found - start
                            self.rmDELETE()
                            // check for file that allows deleting data from destination server, delete if found - end
                            //self.go_button.isEnabled = true
                            self.goButtonEnabled(button_status: true)
                            if self.debug { self.writeToLog(stringOfText: "Done\n") }
                        }
                        semaphore.signal()
                        if error != nil {
                        }
                    } else {
                        if self.debug { self.writeToLog(stringOfText: "\n[- debug -] endpointCount: \(endpointCount)\t endpointCurrent: \(endpointCurrent)\n") }
                        
                        if endpointCount == endpointCurrent {
                            // check for file that allows deleting data from destination server, delete if found - start
                            self.rmDELETE()
                            // check for file that allows deleting data from destination server, delete if found - end
                            //self.go_button.isEnabled = true
                            self.goButtonEnabled(button_status: true)
                            if self.debug { self.writeToLog(stringOfText: "Done\n") }
                        }
                        semaphore.signal()
                    }
                })  // let task = session.dataTask - end
                task.resume()
                semaphore.wait()
            }   // theOpQ.addOperation - end
        }
    }
    
    func existingEndpoints(destEndpoint: String, completion: @escaping (_ result: String) -> Void) {
        URLCache.shared.removeAllCachedResponses()
        currentEPs.removeAll()
        var existingDestUrl = ""
        var destXmlName = ""
        var existingEndpointNode = ""
        (destEndpoint == "jamfusers" || destEndpoint == "jamfgroups") ? (existingEndpointNode = "accounts"):(existingEndpointNode = destEndpoint)
//        print("\nGetting existing endpoints: \(existingEndpointNode)\n")
        var destEndpointDict:(Any)? = nil
        var endpointParent = ""
        switch destEndpoint {
        // macOS items
        case "advancedcomputersearches":
            endpointParent = "advanced_computer_searches"
        case "computerextensionattributes":
            endpointParent = "computer_extension_attributes"
        case "computergroups":
            endpointParent = "computer_groups"
        case "computerconfigurations":
            endpointParent = "computer_configurations"
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
        
        existingDestUrl = "\(self.dest_jp_server)/JSSResource/\(existingEndpointNode)"
        existingDestUrl = existingDestUrl.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
//      print("existing endpoints URL: \(existingDestUrl)")
        
//        theOpQ.maxConcurrentOperationCount = 1
        let semaphore = DispatchSemaphore(value: 1)
        destEPQ.async {
//        theOpQ.addOperation {
            //print("Entered destEPQ")
            
            let destEncodedURL = NSURL(string: existingDestUrl)
            let destRequest = NSMutableURLRequest(url: destEncodedURL! as URL)
            destRequest.httpMethod = "GET"
            let destConf = URLSessionConfiguration.default
            destConf.httpAdditionalHeaders = ["Authorization" : "Basic \(self.destBase64Creds)", "Content-Type" : "application/json", "Accept" : "application/json"]
            let destSession = Foundation.URLSession(configuration: destConf, delegate: self, delegateQueue: OperationQueue.main)
            let task = destSession.dataTask(with: destRequest as URLRequest, completionHandler: {
                (data, response, error) -> Void in
                if let httpResponse = response as? HTTPURLResponse {
//                    print("httpResponse: \(String(describing: response))")
                    do {
                        let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                        if let destEndpointJSON = json as? [String: Any] {
                            if self.debug { self.writeToLog(stringOfText: " --------------- Getting all \(destEndpoint) ---------------\n") }
                            if self.debug { self.writeToLog(stringOfText: "[existingEndpoints] existing destEndpointJSON: \(destEndpointJSON))\n") }
                            switch destEndpoint {
                                
                            // need to revisit as name isn't the best indicatory on whether or not a computer exists
                            case "-computers":
                                if self.debug { self.writeToLog(stringOfText: "[existingEndpoints] getting current computers\n") }
                                if let destEndpointInfo = destEndpointJSON["computers"] as? [Any] {
                                    let destEndpointCount: Int = destEndpointInfo.count
                                    if self.debug { self.writeToLog(stringOfText: "[existingEndpoints] existing \(destEndpoint) found: \(destEndpointCount)\n") }
                                    if self.debug { self.writeToLog(stringOfText: "[existingEndpoints] destEndpointInfo: \(destEndpointInfo)\n") }
                                    
                                    if destEndpointCount > 0 {
                                        for i in (0..<destEndpointCount) {
                                            let destRecord = destEndpointInfo[i] as! [String : AnyObject]
                                            let destXmlID: Int = (destRecord["id"] as! Int)
                                            //                                            print("computer ID: \(destXmlID)")
                                            if let destEpGeneral = destEndpointJSON["computers/id/\(destXmlID)/subset/General"] as? [Any] {
                                                print("destEpGeneral: \(destEpGeneral)")
                                                let destRecordGeneral = destEpGeneral[0] as! [String : AnyObject]
                                                print("destRecordGeneral: \(destRecordGeneral)")
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
                                    destEndpointDict = destEndpointJSON["\(endpointParent)"]
                                }
                                if self.debug { self.writeToLog(stringOfText: "[existingEndpoints] getting current \(existingEndpointNode) on destination server\n") }
                                if let destEndpointInfo = destEndpointDict as? [Any] {
                                    let destEndpointCount: Int = destEndpointInfo.count
                                    if self.debug { self.writeToLog(stringOfText: "[existingEndpoints] existing \(existingEndpointNode) found: \(destEndpointCount) on destination server\n") }
                                    
                                    if destEndpointCount > 0 {
                                        for i in (0..<destEndpointCount) {
                                            
                                            let destRecord = destEndpointInfo[i] as! [String : AnyObject]
                                            if self.debug { self.writeToLog(stringOfText: "[existingEndpoints] Processing: \(destRecord).\n") }
                                            let destXmlID: Int = (destRecord["id"] as! Int)
                                                if destEndpoint != "mobiledeviceapplications" {
                                                    if destRecord["name"] != nil {
                                                        destXmlName = destRecord["name"] as! String
                                                    } else {
                                                        destXmlName = ""
                                                    }
                                                } else {
                                                    destXmlName = destRecord["bundle_id"] as! String
                                                }
                                                if destXmlName != "" {
                                                    if "\(destXmlID)" != "" {
                                                        if self.debug { self.writeToLog(stringOfText: "[existingEndpoints] adding \(destXmlName) (id: \(destXmlID)) to currentEP array.\n") }
                                                        self.currentEPs[destXmlName] = destXmlID
                                                        if self.debug { self.writeToLog(stringOfText: "[existingEndpoints]    Array has \(self.currentEPs.count) entries.\n") }
                                                    } else {
                                                        if self.debug { self.writeToLog(stringOfText: "[existingEndpoints] skipping object: \(destXmlName), could not determine its id.\n") }
                                                    }
                                                } else {
                                                    if self.debug { self.writeToLog(stringOfText: "[existingEndpoints] skipping id: \(destXmlID), could not determine its name.\n") }
                                                }
                                            
                                        }   // for i in (0..<destEndpointCount) - end
                                    } else {   // if destEndpointCount > 0 - end
                                        self.currentEPs.removeAll()
                                    }
                                }   // if let destEndpointInfo - end
                            }   // switch - end
                        } else {
                            self.currentEPs.removeAll()
                            completion("error parsing JSON")
                        }   // if let destEndpointJSON - end
                        
                    }   // end do/catch
                    
                    if httpResponse.statusCode >= 199 && httpResponse.statusCode <= 299 {
                        //print(httpResponse.statusCode)
                        if self.debug { self.writeToLog(stringOfText: "[existingEndpoints] returning existing \(existingEndpointNode) endpoints: \(self.currentEPs)\n") }
//                        print("returning existing endpoints: \(self.currentEPs)")
                        completion("\nCurrent endpoints - \(self.currentEPs)")
                    } else {
                        // something went wrong
                        completion("\ndestination count error")
                        
                    }   // if httpResponse/else - end
                    
                }   // if let httpResponse - end
                semaphore.signal()
                if error != nil {
                }
            })  // let task = destSession - end
            //print("GET")
            task.resume()
            //semaphore.wait()
        }   // destEPQ - end
    }
    
    
    func nameIdDict(server: String, endPoint: String, id: String, completion: @escaping (_ result: [String:Dictionary<String,Int>]) -> Void) {
        // matches the id to name of objects in a configuration (imaging)
        if self.debug { self.writeToLog(stringOfText: "[nameIdDict] start matching \(endPoint) (by name) that exist on both servers\n") }
        URLCache.shared.removeAllCachedResponses()
        var serverUrl   = "\(server)/JSSResource/\(endPoint)"
        serverUrl       = serverUrl.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
        var recordName  = ""
        
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
                            let endpointCount: Int = endpointInfo.count
                            
                            if endpointCount > 0 {
                                for i in (0..<endpointCount) {
                                    let record = endpointInfo[i] as! [String : AnyObject]
                                    let recordId = (record["id"] != nil) ? record["id"] as? Int:0
                                    
                                    if endPoint == "computerconfigurations" {
                                        self.configInfo(server: "\(server)", endPoint: "computerconfigurations", recordId: recordId!) {
                                            (result: Dictionary<String,Dictionary<String,String>>) in
                                            //                                            print("ordered config IDs: \(result)")
                                        }
                                        
                                    } else {
                                        recordName = record["name"] as! String
                                        if self.idDict[recordName]?.count == nil || recordId == 0 {
                                            self.idDict[recordName] = ["sourceId":0, "destId":0]
                                            self.writeToLog(stringOfText: "[nameIdDict] \(String(describing: recordName)): new object.\n")
                                        }
                                        self.idDict[recordName]?[id] = recordId
                                        if self.debug {
                                            self.writeToLog(stringOfText: "[nameIdDict] \(String(describing: recordName)): existing object.\n")
                                            self.writeToLog(stringOfText: "[nameIdDict] \(String(describing: self.idDict[recordName]!)) ID matching dictionary :\n")
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
                        print("status code: \(httpResponse.statusCode)")
                        completion([:])
                        
                    }   // if httpResponse/else - end
                }   // if let httpResponse - end
                semaphore.signal()
                if error != nil {
                }
            })  // let task = destSession - end
            task.resume()
            //semaphore.wait()
        }   // idMapQ - end
    }   // func nameIdDict - end
    
    func configInfo(server: String, endPoint: String, recordId: Int, completion: @escaping (_ result: Dictionary<String,Dictionary<String,String>>) -> Void) {
        URLCache.shared.removeAllCachedResponses()
        
        var serverUrl = "\(server)/JSSResource/\(endPoint)/id/\(recordId)"
        serverUrl = serverUrl.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")

        let semaphore = DispatchSemaphore(value: 0)
        idMapQ.async {
            
            let serverEncodedURL = NSURL(string: serverUrl)
            let serverRequest = NSMutableURLRequest(url: serverEncodedURL! as URL)
            
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
                        //                        print(httpResponse.statusCode)
                        //                            print("\nconfig \(recordId): \(self.configObjectsDict)\n")
                        completion(self.configObjectsDict)
                    } else {
                        // something went wrong
                        print("status code: \(httpResponse.statusCode)")
                        completion([:])
                        
                    }   // if httpResponse/else - end
                }   // if let httpResponse - end
                semaphore.signal()
                if error != nil {
                }
            })  // let task = destSession - end
            //print("GET")
            task.resume()
            //semaphore.wait()
        }   // theOpQ - end
    }
    
//    func sortedEndpointArray(allEndpoints: [Any], arrayCount: Int, completion: @escaping (_ result: [Int:String]) -> Void) {
//        for i in (0..<arrayCount) {
//            if i == 0 { self.availableObjsToMigDict.removeAll() }
//            
//            let record = allEndpoints[i] as! [String : AnyObject]
//            
//            self.availableObjsToMigDict[record["id"] as! Int] = record["name"] as! String?
//            
////            if self.debug { self.writeToLog(stringOfText: "Current number of \(endpoint) to process: \(self.availableObjsToMigDict.count)\n") }
//        }   // for i in (0..<endpointCount) end
//    
//    }
    
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
        if self.debug { self.writeToLog(stringOfText: "Active tab: \(activeTab)\n") }
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
    
    func checkURL2(serverURL: String, completion: @escaping (Bool) -> Void) {
//        print("enter checkURL2")
        var available:Bool = false
        if self.debug { self.writeToLog(stringOfText: "--- checking availability of server: \(serverURL)\n") }
        
        authQ.sync {
            //    var myURL = "\(serverURL)"
            //    if self.debug { self.writeToLog(stringOfText: "checking: \(myURL)\n") }
            if self.debug { self.writeToLog(stringOfText: "checking: \(serverURL)\n") }

            guard let encodedURL = URL(string: serverURL) else {
                if self.debug { self.writeToLog(stringOfText: "--- Cannot cast to URL: \(serverURL)\n") }
                completion(false)
                return
            }
            let configuration = URLSessionConfiguration.default
//            var request = URLRequest(url: encodedURL.appendingPathComponent("/JSSResource/accounts"))
//            request.httpMethod = "HEAD"
            var request = URLRequest(url: encodedURL.appendingPathComponent("/healthCheck.html"))
            request.httpMethod = "GET"

            
            let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
            let task = session.dataTask(with: request as URLRequest, completionHandler: {
                (data, response, error) -> Void in
                if let httpResponse = response as? HTTPURLResponse {
                    if self.debug { self.writeToLog(stringOfText: "Server check: \(serverURL), httpResponse: \(httpResponse.statusCode)\n") }
                    
                    //                    print("response: \(response)")
                    if let responseData = String(data: data!, encoding: .utf8) {
                        if self.debug { self.writeToLog(stringOfText: "checkURL2 data: \(responseData)") }
                    } else {
                        if self.debug { self.writeToLog(stringOfText: "checkURL2 data: none") }
                    }
                    available = true
                    
                } // if let httpResponse - end
                // server is not reachable - availability is still false
                completion(available)
            })  // let task = session - end
            task.resume()
        }   // authQ - end
    }   // func checkURL2 - end
    
    func clearProcessingFields() {
        DispatchQueue.main.async {
            self.get_name_field.stringValue = ""
            self.get_completed_field.stringValue = ""
            self.get_found_field.stringValue = ""
            self.object_name_field.stringValue = ""
            self.objects_completed_field.stringValue = ""
            self.objects_found_field.stringValue = ""
        }
    }
    
    // which platform mode tab are we on - start
    func deviceType() -> String {
//        var platform = ""
//        DispatchQueue.main.async {
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
//            }
        }
        
        print("platform: \(platform)")
        return platform
    }
    // which platform mode tab are we on - end
    
    func disable(theXML: String) -> String {
        let regexDisable = try? NSRegularExpression(pattern: "<enabled>true</enabled>", options:.caseInsensitive)
        let newXML = (regexDisable?.stringByReplacingMatches(in: theXML, options: [], range: NSRange(0..<theXML.utf16.count), withTemplate: "<enabled>false</enabled>"))!
  
        return newXML
    }
    
    func goButtonEnabled(button_status: Bool) {
        DispatchQueue.main.async {
            self.theSpinnerQ.async {
                var theImageNo = 0
                while !button_status {
                    DispatchQueue.main.async {
                        self.mySpinner_ImageView.image = self.theImage[theImageNo]
                        theImageNo += 1
                        if theImageNo > 2 {
//                            if theImageNo > 11 {
                            theImageNo = 0
                        }
                    }
                    usleep(300000)  // sleep 0.3 seconds
//                    usleep(100000)  // sleep 0.1 seconds
                }
            }
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
            }
        } else {
            // clear previous results
            counters.removeAll()
        }
    }
    
    @IBAction func stopButton(_ sender: Any) {
        self.writeToLog(stringOfText: "Migration was manually stopped.\n\n")
        theOpQ.cancelAllOperations()
        theCreateQ.cancelAllOperations()
        goButtonEnabled(button_status: true)
    }
    
    func getCurrentTime() -> String {
        let date = NSDate()
        let date_formatter = DateFormatter()
        // the following produced the wrong year with run on Dec. 31 - string showed the next year rather then present year
//        date_formatter.dateFormat = "YYYYMMdd_HHmmss"
//        let stringDate = date_formatter.string(from: date as Date)
        date_formatter.dateFormat = "HH:mm:ss"
        let myDateArray = "\(date)".components(separatedBy: " ")
        let stringDate = myDateArray[0].replacingOccurrences(of: "-", with: "") + "_" + date_formatter.string(from: date as Date)
        
//        print("stringDate: " + stringDate)
        return stringDate
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
    
    func getStatusInit(endpoint: String, count: Int) {
        self.get_name_field.stringValue = endpoint
        self.get_found_field.stringValue = "\(count)"
        self.get_completed_field.stringValue = "0"
    }
    
    func getStatusUpdate(endpoint: String, count: Int) {
        //self.get_name_field.stringValue = endpoint
        //self.get_found_field.stringValue = "\(count)"
        self.get_completed_field.stringValue = "\(count)"
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
                        if self.debug { self.writeToLog(stringOfText: "Deleting log file: " + logArray[i]) }
                        
                        do {
                            try fm.removeItem(atPath: logArray[i])
                        }
                        catch let error as NSError {
                            if self.debug { self.writeToLog(stringOfText: "Error deleting log file:\n" + logArray[i] + "\n\(error)") }
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
                if self.debug { self.writeToLog(stringOfText: "Error deleting log file:\n" + logPath! + logFile + "\n\(error)") }
            }
        }

    }
    // func logCleanup - end
    
    // func labelColor - start
    func labelColor(endpoint: String, theColor: NSColor) {
        switch endpoint {
        // macOS tab
        case "advancedcomputersearches":
            advcompsearch_label_field.textColor = theColor
        case "computers":
            computers_label_field.textColor = theColor
        case "computerconfigurations":
            configurations_label_field.textColor = theColor
        case "directorybindings":
            directory_bindings_field.textColor = theColor
        case "distributionpoints":
            file_shares_label_field.textColor = theColor
        case "dockitems":
            dock_items_field.textColor = theColor
        case "softwareupdateservers":
            sus_label_field.textColor = theColor
        case "netbootservers":
            netboot_label_field.textColor = theColor
        case "osxconfigurationprofiles":
            osxconfigurationprofiles_label_field.textColor = theColor
        case "patchpolicies":
            patch_policies_field.textColor = theColor
        case "computerextensionattributes":
            extension_attributes_label_field.textColor = theColor
        case "scripts":
            scripts_label_field.textColor = theColor
        case "computergroups":
            smart_groups_label_field.textColor = theColor
            static_groups_label_field.textColor = theColor
        case "smartcomputergroups":
            smart_groups_label_field.textColor = theColor
        case "staticcomputergroups":
            static_groups_label_field.textColor = theColor
        case "packages":
            packages_label_field.textColor = theColor
        case "printers":
            printers_label_field.textColor = theColor
        case "policies":
            policies_label_field.textColor = theColor
        case "restrictedsoftware":
            restrictedsoftware_label_field.textColor = theColor
        // iOS tab
        case "advancedmobiledevicesearches":
            advancedmobiledevicesearches_label_field.textColor = theColor
        case "mobiledeviceapplications":
            mobiledeviceApps_label_field.textColor = theColor
        case "mobiledeviceconfigurationprofiles":
            mobiledeviceconfigurationprofile_label_field.textColor = theColor
        case "mobiledeviceextensionattributes":
            mobiledeviceextensionattributes_label_field.textColor = theColor
        case "mobiledevices":
            mobiledevices_label_field.textColor = theColor
        case "mobiledevicegroups":
            smart_ios_groups_label_field.textColor = theColor
            static_ios_groups_label_field.textColor = theColor
        case "smartiosgroups":
            smart_ios_groups_label_field.textColor = theColor
        case "staticiosgroups":
            static_ios_groups_label_field.textColor = theColor
        // general tab
        case "advancedusersearches":
            advusersearch_label_field.textColor = theColor
        case "buildings":
            building_label_field.textColor = theColor
        case "categories":
            categories_label_field.textColor = theColor
        case "departments":
            departments_label_field.textColor = theColor
        case "userextensionattributes":
            userEA_label_field.textColor = theColor
        case "ldapservers":
            ldapservers_label_field.textColor = theColor
        case "sites":
            sites_label_field.textColor = theColor
        case "networksegments":
            network_segments_label_field.textColor = theColor
        case "users":
            users_label_field.textColor = theColor
        case "usergroups":
            smartUserGrps_label_field.textColor = theColor
            staticUserGrps_label_field.textColor = theColor
        case "jamfusers", "accounts/userid":
            jamfUserAccounts_field.textColor = theColor
        case "jamfgroups", "accounts/groupid":
            jamfGroupAccounts_field.textColor = theColor
        case "smartusergroups":
            smartUserGrps_label_field.textColor = theColor
        case "staticusergroups":
            staticUserGrps_label_field.textColor = theColor
        default:
            print("function labelColor: unknown label - \(endpoint)")
        }
    }
    // func labelColor - end
    
    func migrationStatus(endpoint: String, count: Int) {
        object_name_field.stringValue = endpoint
        objects_found_field.stringValue = "\(count)"
    }
    
    // move history to log - start
    func moveHistoryToLog (source: String, destination: String) {
        var allClear = true

        do {
            let historyFiles = try fm.contentsOfDirectory(atPath: source)
            
            for historyFile in historyFiles {
                if self.debug { self.writeToLog(stringOfText: "Moving: " + source + historyFile + " to " + destination) }
                do {
                    try fm.moveItem(atPath: source + historyFile, toPath: destination + historyFile.replacingOccurrences(of: ".txt", with: ".log"))
                }
                catch let error as NSError {
                    self.writeToLog(stringOfText: "Ooops! Something went wrong moving the history file: \(error)\n")
                    allClear = false
                }
            }
        } catch {
            if self.debug { self.writeToLog(stringOfText: "no history to display\n") }
        }
        if allClear {
            do {
                try fm.removeItem(atPath: source)
            } catch {
                if self.debug { self.writeToLog(stringOfText: "Unable to remove \(source)\n") }
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
//                        if theImageNo > 11 {
                        theImageNo = 0
                    }
                }
                usleep(300000)  // sleep 0.3 seconds
//                usleep(100000)  // sleep 0.1 seconds
            }
        }
    }
    
    func rmDELETE() {
        var isDir: ObjCBool = false
        if (self.fm.fileExists(atPath: NSHomeDirectory() + "/Library/Application Support/jamf-migrator/DELETE", isDirectory: &isDir)) {
            do {
                try self.fm.removeItem(atPath: NSHomeDirectory() + "/Library/Application Support/jamf-migrator/DELETE")
                // re-enable source server, username, and password fields (to finish later)
//                source_jp_server_field.isEnabled = true
//                sourceServerList_button.isEnabled = true
            }
            catch let error as NSError {
                if self.debug { self.writeToLog(stringOfText: "Unable to delete file! Something went wrong: \(error)\n") }
            }
        }
    }
    
    func rmXmlData(theXML: String, theTag: String) -> String {
        let f_regexComp = try! NSRegularExpression(pattern: "<\(theTag)>(.|\n)*?</\(theTag)>", options:.caseInsensitive)
        let newXML = f_regexComp.stringByReplacingMatches(in: theXML, options: [], range: NSRange(0..<theXML.utf16.count), withTemplate: "")
        
        return newXML
    }
    
    func readSettings() -> [String:Any] {
        // read environment settings - start
//        var plistData = [String:Any]()
//        let plistXML = FileManager.default.contents(atPath: plistPath!)!
        do {
//            plistData = try PropertyListSerialization.propertyList(from: plistXML,
//                                                                   options: .mutableContainersAndLeaves,
//                                                                   format: &format)
//                as! [String:Any]
            try plistData = (NSDictionary(contentsOf: URL(fileURLWithPath: plistPath!)) as? [String : Any])!
        }
        catch{
            if self.debug { self.writeToLog(stringOfText: "Error reading plist: \(error), format: \(format)") }
        }

//        print("readSettings - plistData: \(String(describing: plistData["scope"]))\n")
        return(plistData)
        // read environment settings - end
    }
    
    func saveSettings() {
        plistData["source_jp_server"] = source_jp_server_field.stringValue as Any?
//        plistData["source_user"] = source_user_field.stringValue as AnyObject?
        plistData["source_user"] = storedSourceUser as Any?
        plistData["dest_jp_server"] = dest_jp_server_field.stringValue as Any?
        plistData["dest_user"] = dest_user_field.stringValue as Any?
        plistData["maxHistory"] = maxHistory as Any?
        plistData["storeCredentials"] = storeCredentials_button.state as Any?
        NSDictionary(dictionary: plistData).write(toFile: plistPath!, atomically: true)
        print("saveSettings scopeOptions: \(String(describing: plistData["scope"]))\n")
//        (plistData as NSDictionary).write(toFile: plistPath!, atomically: false)
    }
    func savePrefs(prefs: [String:Any]) {
//        DispatchQueue.main.async {
            self.plistData["scope"] = prefs
            self.scopeOptions = prefs["scope"] as! Dictionary<String,Dictionary<String,Bool>>
            NSDictionary(dictionary: prefs).write(toFile: self.plistPath!, atomically: true)
//            self.plistData = self.readSettings()
            print("savePrefs scopeOptions: \(String(describing: self.plistData["scope"]))\n")
//        }
    }
    
    // functions used to get existing self service icons to new server - start
    func myExitValue(cmd: String, args: String...) -> String {
        var status  = ""
        let pipe    = Pipe()
        let task    = Process()
        
        task.launchPath     = cmd
        task.arguments      = args
        task.standardOutput = pipe
        let outputHandle    = pipe.fileHandleForReading
        
        outputHandle.readabilityHandler = { pipe in
            if let testResult = String(data: pipe.availableData, encoding: String.Encoding.utf8) {
                status = testResult.replacingOccurrences(of: "\n", with: "")
            } else {
                status = "unknown"
            }
        }
        
        task.launch()
        task.waitUntilExit()
        
        return(status)
    }
    
    
    
//    func selfServiceIconGet(newPolicyId: String, ssIconName: String, ssIconUri: String) {
//        theCreateQ.maxConcurrentOperationCount = 1
//        let semaphore = DispatchSemaphore(value: 0)
//
////        var responseData = ""
//
//        theCreateQ.addOperation {
//            if self.debug { self.writeToLog(stringOfText: "Getting icon \(ssIconName) from \(ssIconUri)\n") }
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
//                            self.writeToLog(stringOfText: "icon get succeeded: \(ssIconName)\n")
//                            self.selfServiceIconPost(newPolicyId: newPolicyId, ssIconName: ssIconName, ssIcon: data!)
//                            
//                        } else {
//                            self.writeToLog(stringOfText: "icon get failed: \(ssIconName)\n")
//                        }
////                        responseData = String(data: data!, encoding: .unicode)!
//                        //                        if self.debug { self.writeToLog(stringOfText: "\n\n[- debug -] full response from create:\n\(responseData)") }
////                        print("create data response: \(responseData)")
//                    } else {
//                        if self.debug { self.writeToLog(stringOfText: "\n\n[- debug -] No data was returned from icon GET.\n") }
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
            if self.debug { self.writeToLog(stringOfText: "invalid input for tagValue function or tag not found.\n") }
            if self.debug { self.writeToLog(stringOfText: "\ttag: \(xmlTag)\n") }
            if self.debug { self.writeToLog(stringOfText: "\txml: \(xmlString)\n") }
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
            if self.debug { self.writeToLog(stringOfText: "[tagValue2] Start, \(startTag), and end, \(endTag), not found.\n") }
        }
        return rawValue
    }
    //  extract the value between (different) tags - end
    
    func updateServerArray(url: String, serverList: String, theArray: [String]) {
        var local_serverArray = theArray
        let positionInList = local_serverArray.index(of: url)
        if positionInList == nil {
                local_serverArray.insert(url, at: 0)
        } else if positionInList! > 0 {
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
                self.sourceServerList_button.addItems(withTitles: [theServer])
            }
            self.sourceServerArray = local_serverArray
        case "dest_server_array":
            self.destServerList_button.removeAllItems()
            for theServer in local_serverArray {
                self.destServerList_button.addItems(withTitles: [theServer])
            }
            self.destServerArray = local_serverArray
        default: break
        }
        
    }
    
    @IBAction func setServerUrl_button(_ sender: NSPopUpButton) {
        switch sender.tag {
        case 0:
            self.source_jp_server_field.stringValue = sourceServerList_button.titleOfSelectedItem!
        case 1:
            self.dest_jp_server_field.stringValue = destServerList_button.titleOfSelectedItem!
        default: break
        }
    }
    
    func writeToLog(stringOfText: String) {
        writeLogQ.async {
            let logString = "\(self.getCurrentTime()) [- debug -] \(stringOfText)"
            self.logFileW = FileHandle(forUpdatingAtPath: (self.logPath! + self.logFile))
            
            self.logFileW?.seekToEndOfFile()
            let historyText = (logString as NSString).data(using: String.Encoding.utf8.rawValue)
            self.logFileW?.write(historyText!)
            self.logFileW?.closeFile()
        }
    }
    
    //// selective migration functions - start
    func numberOfRows(in aTableView: NSTableView) -> Int
    {
        var numberOfRows:Int = 0;
        if (aTableView == srcSrvTableView)
        {
            numberOfRows = sourceDataArray.count
        }
        
        return numberOfRows
    }
    //
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any?
    {
        //        print("tableView: \(tableView)\t\ttableColumn: \(tableColumn)\t\trow: \(row)")
        var newString:String = ""
        if (tableView == srcSrvTableView)
        {
            newString = sourceDataArray[row]
        }
        
        return newString;
    }
    //// selective migration functions - end
    
    override func viewDidAppear() {

        
        // set tab order
        source_jp_server_field.nextKeyView  = source_user_field
        source_user_field.nextKeyView       = source_pwd_field
        source_pwd_field.nextKeyView        = dest_jp_server_field
        dest_jp_server_field.nextKeyView    = dest_user_field
        dest_user_field.nextKeyView         = dest_pwd_field
        
        // v1 colors
        //        self.view.layer?.backgroundColor = CGColor(red: 0x11/255.0, green: 0x1E/255.0, blue: 0x3A/255.0, alpha: 1.0)
        // v2 colors
        self.view.layer?.backgroundColor = CGColor(red: 0x5C/255.0, green: 0x78/255.0, blue: 0x94/255.0, alpha: 1.0)
        //[NSColor colorWithCalibratedRed:0x5C/255.0 green:0x78/255.0 blue:0x94/255.0 alpha:0xFF/255.0]/* 5C7894FF */
        
//        [NSColor colorWithCalibratedRed:0xE8/255.0 green:0xEE/255.0 blue:0xEE/255.0 alpha:0xFF/255.0]/* E8EEEEFF */
        let bkgndAlpha:CGFloat = 0.95
        get_name_field.backgroundColor         = NSColor(calibratedRed: 0xE8/255.0, green: 0xE8/255.0, blue: 0xE8/255.0, alpha: bkgndAlpha)
        object_name_field.backgroundColor     = NSColor(calibratedRed: 0xE8/255.0, green: 0xE8/255.0, blue: 0xE8/255.0, alpha: bkgndAlpha)
        get_completed_field.backgroundColor   = NSColor(calibratedRed: 0xE8/255.0, green: 0xE8/255.0, blue: 0xE8/255.0, alpha: bkgndAlpha)
        get_found_field.backgroundColor       = NSColor(calibratedRed: 0xE8/255.0, green: 0xE8/255.0, blue: 0xE8/255.0, alpha: bkgndAlpha)
        objects_completed_field.backgroundColor   = NSColor(calibratedRed: 0xE8/255.0, green: 0xE8/255.0, blue: 0xE8/255.0, alpha: bkgndAlpha)
        objects_found_field.backgroundColor   = NSColor(calibratedRed: 0xE8/255.0, green: 0xE8/255.0, blue: 0xE8/255.0, alpha: bkgndAlpha)
        
        let def_plist = Bundle.main.path(forResource: "settings", ofType: "plist")!
        var isDir: ObjCBool = true
        
        // Create Application Support folder for the app if missing - start
        let app_support_path = NSHomeDirectory() + "/Library/Application Support/jamf-migrator"
        if !(fm.fileExists(atPath: app_support_path, isDirectory: &isDir)) {
            let manager = FileManager.default
            do {
                try manager.createDirectory(atPath: app_support_path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                if self.debug { self.writeToLog(stringOfText: "Problem creating '/Library/Application Support/jamf-migrator' folder:  \(error)") }
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
                if self.debug { self.writeToLog(stringOfText: "Failed creating default settings.plist! Something went wrong: \(error)") }
                alert_dialog(header: "Error:", message: "Failed creating default settings.plist")
                exit(0)
            }
        }
        // Create preference file if missing - end
        
        // check for file that allows deleting data from destination server, delete if found - start
        self.rmDELETE()
        // check for file that allows deleting data from destination server, delete if found - end
        
//        // read environment settings - start
        plistData = readSettings()
//        let plistXML = FileManager.default.contents(atPath: plistPath!)!
//        do{
//            plistData = try PropertyListSerialization.propertyList(from: plistXML,
//                                                                   options: .mutableContainersAndLeaves,
//                                                                   format: &format)
//                as! [String:AnyObject]
//        }
//        catch{
//            if self.debug { self.writeToLog(stringOfText: "Error reading plist: \(error), format: \(format)") }
//        }
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
        if plistData["scope"] != nil {
            scopeOptions = plistData["scope"] as! Dictionary<String,Dictionary<String,Bool>>
            if scopeOptions["mobiledeviceconfigurationprofiles"]!["copy"] != nil {
                scopeMcpCopy = scopeOptions["mobiledeviceconfigurationprofiles"]!["copy"]!
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
            if scopeOptions["scg"] != nil {
                if scopeOptions["scg"]!["copy"] != nil {
                    scopeScgCopy = scopeOptions["scg"]!["copy"]!
                }
                if scopeOptions["sig"]!["copy"] != nil {
                    scopeSigCopy = scopeOptions["sig"]!["copy"]!
                }
                if scopeOptions["users"]!["copy"] != nil {
                    scopeUsersCopy = scopeOptions["users"]!["copy"]!
                }
            } else {
                plistData["scope"] = ["mobiledeviceconfigurationprofiles":["copy":true],
                                      "policies":["copy":true,"disable":false],
                                      "osxconfigurationprofiles":["copy":true],
                                      "restrictedsoftware":["copy":true],
                                      "scg":["copy":true],
                                      "sig":["copy":true],
                                      "users":["copy":true]] as Any
                saveSettings()
            }
            
        } else {
            // initilize new settings
            plistData["scope"] = ["mobiledeviceconfigurationprofiles":["copy":true],
                                  "policies":["copy":true,"disable":false],
                                  "osxconfigurationprofiles":["copy":true],
                                  "restrictedsoftware":["copy":true],
                                  "scg":["copy":true],
                                  "sig":["copy":true],
                                  "users":["copy":true]] as Any
            saveSettings()
        }
        // read environment settings - end

        // check for stored passwords - start
        let regexKey = try! NSRegularExpression(pattern: "http(.*?)://", options:.caseInsensitive)
        if (source_jp_server != "") && (source_user != "") {
            let credKey = regexKey.stringByReplacingMatches(in: source_jp_server, options: [], range: NSRange(0..<source_jp_server.utf16.count), withTemplate: "")
            let storedSourcePassword = Creds.retrieve("migrator - "+credKey, account: source_user)
            if storedSourcePassword != nil {
                source_pwd_field.stringValue = storedSourcePassword!
                self.storedSourceUser = source_user
            } else {
                source_pwd_field.stringValue = ""
                source_pwd_field.becomeFirstResponder()
            }
        }
        if (dest_jp_server != "") && (dest_user != "") {
            let credKey = regexKey.stringByReplacingMatches(in: dest_jp_server, options: [], range: NSRange(0..<dest_jp_server.utf16.count), withTemplate: "")
            let storedDestPassword = Creds.retrieve("migrator - "+credKey, account: dest_user)
            if storedDestPassword != nil {
                dest_pwd_field.stringValue = storedDestPassword!
                self.storedDestUser = dest_user
            } else {
                dest_pwd_field.stringValue = ""
                if source_pwd_field.stringValue != "" {
                    dest_pwd_field.becomeFirstResponder()
                }
            }
        }
        if (source_pwd_field.stringValue == "") || (dest_pwd_field.stringValue == "") {
            self.validCreds = false
        }
        // check for stored passwords - start

        
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        // Sellect all items to be migrated
        // macOS tab
        allNone_button.state = NSControl.StateValue(rawValue: 1)
        advcompsearch_button.state = NSControl.StateValue(rawValue: 1)
        computers_button.state = NSControl.StateValue(rawValue: 1)
        configurations_button.state = NSControl.StateValue(rawValue: 1)
        directory_bindings_button.state = NSControl.StateValue(rawValue: 1)
        dock_items_button.state = NSControl.StateValue(rawValue: 1)
        netboot_button.state = NSControl.StateValue(rawValue: 1)
        osxconfigurationprofiles_button.state = NSControl.StateValue(rawValue: 1)
//        patch_mgmt_button.state = 1
        patch_policies_button.state = NSControl.StateValue(rawValue: 1)
        sus_button.state = NSControl.StateValue(rawValue: 1)
        fileshares_button.state = NSControl.StateValue(rawValue: 1)
        ext_attribs_button.state = NSControl.StateValue(rawValue: 1)
        smart_comp_grps_button.state = NSControl.StateValue(rawValue: 1)
        static_comp_grps_button.state = NSControl.StateValue(rawValue: 1)
        scripts_button.state = NSControl.StateValue(rawValue: 1)
        packages_button.state = NSControl.StateValue(rawValue: 1)
        policies_button.state = NSControl.StateValue(rawValue: 1)
        printers_button.state = NSControl.StateValue(rawValue: 1)
        restrictedsoftware_button.state = NSControl.StateValue(rawValue: 1)
        // iOS tab
        allNone_iOS_button.state = NSControl.StateValue(rawValue: 1)
        advancedmobiledevicesearches_button.state = NSControl.StateValue(rawValue: 1)
        mobiledevicecApps_button.state = NSControl.StateValue(rawValue: 0)
        mobiledevices_button.state = NSControl.StateValue(rawValue: 1)
        smart_ios_groups_button.state = NSControl.StateValue(rawValue: 1)
        static_ios_groups_button.state = NSControl.StateValue(rawValue: 1)
        mobiledeviceconfigurationprofiles_button.state = NSControl.StateValue(rawValue: 1)
        mobiledeviceextensionattributes_button.state = NSControl.StateValue(rawValue: 1)
        // general tab
        allNone_general_button.state = NSControl.StateValue(rawValue: 1)
        advusersearch_button.state = NSControl.StateValue(rawValue: 1)
        building_button.state = NSControl.StateValue(rawValue: 1)
        categories_button.state = NSControl.StateValue(rawValue: 1)
        dept_button.state = NSControl.StateValue(rawValue: 1)
        userEA_button.state = NSControl.StateValue(rawValue: 1)
        sites_button.state = NSControl.StateValue(rawValue: 1)
        ldapservers_button.state = NSControl.StateValue(rawValue: 1)
        networks_button.state = NSControl.StateValue(rawValue: 1)
        users_button.state = NSControl.StateValue(rawValue: 1)
        jamfUserAccounts_button.state = NSControl.StateValue(rawValue: 1)
        jamfGroupAccounts_button.state = NSControl.StateValue(rawValue: 1)
        smartUserGrps_button.state = NSControl.StateValue(rawValue: 1)
        staticUserGrps_button.state = NSControl.StateValue(rawValue: 1)
        
        source_jp_server_field.becomeFirstResponder()
        go_button.isEnabled = true
        
        // for selective migration - end
        
        // read commandline args
        var numberOfArgs = 0
        
        debug = true
        
        numberOfArgs = CommandLine.arguments.count - 2  // subtract 2 since we start counting at 0, another 1 for the app itself
        if numberOfArgs >= 0 {
//            print("all arguments: \(CommandLine.arguments)")
            for i in stride(from: 1, through: numberOfArgs+1, by: 1) {
                //print("i: \(i)\t argument: \(CommandLine.arguments[i])")
                switch CommandLine.arguments[i]{
                case "-saveXML":
                    // Add code to save xml to file
                    print("not yet implemented")
                case "-debug":
                    debug = true
                case "-NSDocumentRevisionsDebugMode","YES":
                    continue
                default:
                    print("unknown switch passed: \(CommandLine.arguments[i])")
                }
            }
        }
        
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

        isDir = false
        if !(fm.fileExists(atPath: logPath! + logFile, isDirectory: &isDir)) {
            fm.createFile(atPath: logPath! + logFile, contents: nil, attributes: nil)
        }

        sleep(1)
        if debug { writeToLog(stringOfText: "----- Debug Mode -----\n") }
        
        theModeQ.async {
            var isDir: ObjCBool = false
            var isRed = false
            
            while true {
                if (self.fm.fileExists(atPath: NSHomeDirectory() + "/Library/Application Support/jamf-migrator/DELETE", isDirectory: &isDir)) {
                    
                    DispatchQueue.main.async {
                        // disaable source server, username and password fields (to finish)
                        if self.source_jp_server_field.isEnabled {
                            self.source_jp_server_field.textColor   = NSColor.white
                            self.source_jp_server_field.isEnabled   = false
                            self.sourceServerList_button.isEnabled  = false
                            self.source_user_field.isEnabled        = false
                            self.source_pwd_field.isEnabled         = false
                        }

                        if isRed == false {
                            self.migrateOrRemove_label_field.stringValue = "--- Removing ---"
                            self.migrateOrRemove_label_field.textColor = self.redText
                            isRed = true
                        } else {
                            self.migrateOrRemove_label_field.textColor = self.yellowText
                            isRed = false
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        if !self.source_jp_server_field.isEnabled {
                            self.source_jp_server_field.textColor   = NSColor.black
                            self.source_jp_server_field.isEnabled   = true
                            self.sourceServerList_button.isEnabled  = true
                            self.source_user_field.isEnabled        = true
                            self.source_pwd_field.isEnabled         = true
                        }

                        self.migrateOrRemove_label_field.stringValue = "Migrate"
                        self.migrateOrRemove_label_field.textColor = self.whiteText
                        isRed = false
                    }
                }
                sleep(1)
            }
        }
        
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
        let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
        let summaryWindowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "Summary Window Controller")) as! NSWindowController
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
                cellDetails.append(popUpHtml(id: createIndex, column: "\(String(describing: key)) Created", values: createHtml))
                cellDetails.append(popUpHtml(id: updateIndex, column: "\(String(describing: key)) Updated", values: updateHtml))
                cellDetails.append(popUpHtml(id: failIndex, column: "\(String(describing: key)) Failed", values: failHtml))
            }
            summaryResult.append("<table style='table-layout:fixed; border-collapse: collapse; margin-left: auto; margin-right: auto; width: 95%;'>" +
            "<tr>" +
                "<th style='text-align:right; width: 35%;'>Endpoint</th>" +
                "<th style='text-align:right; width: 20%;'>Created</th>" +
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

