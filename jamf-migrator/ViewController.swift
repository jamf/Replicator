//
//  ViewController.swift
//  jamf-migrator
//
//  Created by ladmin on 12/9/16.
//  Copyright © 2016 jamf. All rights reserved.
//

import Cocoa
import Foundation

class ViewController: NSViewController, URLSessionDelegate, NSTableViewDelegate, NSTableViewDataSource {
    
    // Main Window
    @IBOutlet var migrator_window: NSView!
    @IBOutlet weak var modeTab_TabView: NSTabView!
    
    @IBOutlet weak var objectsToSelect: NSScrollView!
    
    // Help Window
    @IBAction func showHelpWindow(_ sender: AnyObject) {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let helpWindowController = storyboard.instantiateController(withIdentifier: "Help View Controller") as! NSWindowController
        
        if let helpWindow = helpWindowController.window {
            //            let helpViewController = helpWindow.contentViewController as! HelpViewController
            
            let application = NSApplication.shared()
            application.runModal(for: helpWindow)
            
            helpWindow.close()
        }
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
    @IBOutlet weak var ext_attribs_button: NSButton!
    @IBOutlet weak var scripts_button: NSButton!
    @IBOutlet weak var smart_comp_grps_button: NSButton!
    @IBOutlet weak var static_comp_grps_button: NSButton!
    @IBOutlet weak var packages_button: NSButton!
    @IBOutlet weak var printers_button: NSButton!
    @IBOutlet weak var policies_button: NSButton!
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
    //    var platform = ""  // either macOS or iOS
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
    @IBOutlet weak var extension_attributes_label_field: NSTextField!
    @IBOutlet weak var scripts_label_field: NSTextField!
    @IBOutlet weak var smart_groups_label_field: NSTextField!
    @IBOutlet weak var static_groups_label_field: NSTextField!
    @IBOutlet weak var packages_label_field: NSTextField!
    @IBOutlet weak var printers_label_field: NSTextField!
    @IBOutlet weak var policies_label_field: NSTextField!
    @IBOutlet weak var jamfUserAccounts_field: NSTextField!
    @IBOutlet weak var jamfGroupAccounts_field: NSTextField!
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
    
    // plist and history variables
    let plistPath:String? = (NSHomeDirectory() + "/Library/Application Support/jamf-migrator/settings.plist")
    var format = PropertyListSerialization.PropertyListFormat.xml //format of the property list
    var plistData:[String:AnyObject] = [:]  //our server/username data
    var maxHistory: Int = 20
    var historyFile: String = ""
    let historyPath:String? = (NSHomeDirectory() + "/Library/Application Support/jamf-migrator/history/")
    var historyFileW: FileHandle?  = FileHandle(forUpdatingAtPath: "")
    
    var sourceServerArray = [String]()
    var destServerArray = [String]()
    
    // credentials
    var sourceCreds = ""
    var destCreds = ""
    var jamfAdminId = 1
    
    // settings variables
    let safeCharSet = CharacterSet.alphanumerics
    var source_jp_server: String = ""
    var source_user: String = ""
    var source_pass: String = ""
    var dest_jp_server: String = ""
    var dest_user: String = ""
    var dest_pass: String = ""
    var sourceBase64Creds: String = ""
    var destBase64Creds: String = ""
    
    var sourceURL = ""
    var destURL = ""
    
    var endpointDefDict = ["computergroups":"computer_groups","computerconfigurations":"computer_configurations", "directorybindings":"directory_bindings", "dockitems":"dock_items", "mobiledevicegroups":"mobile_device_groups", "packages":"packages", "printers":"printers", "scripts":"scripts", "usergroups":"user_groups", "userextensionattributes":"user_extension_attributes", "advancedusersearches":"advanced_user_searches"]
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
    var macOSEndpointArray: [String] = ["advancedcomputersearches", "computergroups", "computers", "osxconfigurationprofiles", "computerconfigurations", "directorybindings", "dockitems", "computerextensionattributes", "distributionpoints", "netbootservers", "packages", "policies", "printers", "scripts", "softwareupdateservers"]
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

    
    @IBOutlet weak var mySpinner_ImageView: NSImageView!
    var theImage:[NSImage] = [NSImage(named: "0.png")!, NSImage(named: "1.png")!, NSImage(named: "2.png")!, NSImage(named: "3.png")!, NSImage(named: "4.png")!, NSImage(named: "5.png")!, NSImage(named: "6.png")!, NSImage(named: "7.png")!, NSImage(named: "8.png")!, NSImage(named: "9.png")!, NSImage(named: "10.png")!, NSImage(named: "11.png")!]
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
    var destEPQ = DispatchQueue(label: "com.jamf.destEPs")
    var idMapQ = DispatchQueue(label: "com.jamf.idMap")
    
    var migrateOrWipe: String = ""
    var httpStatusCode: Int = 0
    var URLisValid: Bool = true
    var processGroup = DispatchGroup()
    
    @IBAction func showHistoryFolder(_ sender: Any) {
        isDir = true
        if (self.fm.fileExists(atPath: NSHomeDirectory() + "/Library/Application Support/jamf-migrator/history", isDirectory: &isDir)) {
            NSWorkspace.shared().openFile(NSHomeDirectory() + "/Library/Application Support/jamf-migrator/history")
        } else {
            alert_dialog(header: "Alert", message: "There are currently no history files to display.")
        }
    }
    
    @IBAction func toggleAllNone(_ sender: NSButton) {
        //        platform = deviceType()
        if deviceType() == "macOS" {
            self.allNone_button.state = (
                self.advcompsearch_button.state == 1
                    && self.computers_button.state == 1
                    && self.configurations_button.state == 1
                    && self.directory_bindings_button.state == 1
                    && self.dock_items_button.state == 1
                    && self.fileshares_button.state == 1
                    && self.sus_button.state == 1
                    && self.netboot_button.state == 1
                    && self.osxconfigurationprofiles_button.state == 1
                    && self.smart_comp_grps_button.state == 1
                    && self.static_comp_grps_button.state == 1
                    && self.ext_attribs_button.state == 1
                    && self.scripts_button.state == 1
                    && self.packages_button.state == 1
                    && self.printers_button.state == 1
                    && self.policies_button.state == 1) ? 1 : 0;
        } else if deviceType() == "iOS" {
            self.allNone_iOS_button.state = (
                self.mobiledeviceconfigurationprofiles_button.state == 1
                    && self.mobiledevices_button.state == 1
                    && self.smart_ios_groups_button.state == 1
                    && self.static_ios_groups_button.state == 1
                    && self.mobiledeviceextensionattributes_button.state == 1
                    && self.advancedmobiledevicesearches_button.state == 1) ? 1 : 0;
        } else {
            // general
            self.allNone_general_button.state = (
                self.building_button.state == 1
                    && self.categories_button.state == 1
                    && self.dept_button.state == 1
                    && self.advusersearch_button.state == 1
                    && self.userEA_button.state == 1
                    && self.ldapservers_button.state == 1
                    && self.sites_button.state == 1
                    && self.networks_button.state == 1
                    && self.jamfUserAccounts_button.state == 1
                    && self.jamfGroupAccounts_button.state == 1
                    && self.smartUserGrps_button.state == 1
                    && self.staticUserGrps_button.state == 1
                    && self.users_button.state == 1) ? 1 : 0;
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
            self.smart_comp_grps_button.state = self.allNone_button.state
            self.static_comp_grps_button.state = self.allNone_button.state
            self.ext_attribs_button.state = self.allNone_button.state
            self.scripts_button.state = self.allNone_button.state
            self.packages_button.state = self.allNone_button.state
            self.printers_button.state = self.allNone_button.state
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
        
        let whichTab = sender.identifier!
        if debug { writeToHistory(stringOfText: "[- debug -] func sectionToMigrate active tab: \(whichTab).\n") }
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
            if self.debug { self.writeToHistory(stringOfText: "[- debug -] Selectively migrating: \(objectsToMigrate) for \(sender.identifier ?? "")\n") }
            Go(sender: self)
        }
    }
    
    @IBAction func Go(sender: AnyObject) {
        if self.debug { self.writeToHistory(stringOfText: "[- debug -] Start Migrating/Removal\n") }
        // check for file that allow deleting data from destination server - start
        //       var isDir: ObjCBool = false
        if (fm.fileExists(atPath: NSHomeDirectory() + "/Library/Application Support/jamf-migrator/DELETE", isDirectory: &isDir)) {
            if self.debug { self.writeToHistory(stringOfText: "[- debug -] Removing data from destination server - \(dest_jp_server_field.stringValue)\n") }
            wipe_data = true
            
            migrateOrWipe = "----------- Starting To Wipe Data -----------\n"
        } else {
            if self.debug { self.writeToHistory(stringOfText: "[- debug -] Migrating data from \(source_jp_server_field.stringValue) to \(dest_jp_server_field.stringValue).\n") }
            // verify source and destination are not the same - start
            if source_jp_server_field.stringValue == dest_jp_server_field.stringValue {
                alert_dialog(header: "Alert", message: "Source and destination servers cannot be the same.")
                //self.go_button.isEnabled = true
                self.goButtonEnabled(button_status: true)
                return
            }
            // verify source and destination are not the same - end
            wipe_data = false
            
            migrateOrWipe = "----------- Starting Migration -----------\n"
        }
        // check for file that allow deleting data from destination server - end
        
        
        if debug { writeToHistory(stringOfText: "[- debug -] go sender tag: \(sender.tag)\n") }
        // determine if we got here from the Go button or selectToMigrate button
        if sender.tag != nil {
            self.goSender = "goButton"
        } else {
            self.goSender = "selectToMigrateButton"
        }
        if debug { writeToHistory(stringOfText: "[- debug -] Go button pressed from: \(goSender)\n") }
        
        // which migration mode tab are we on - start
        if activeTab() != "selective" {
            migrationMode = "bulk"
        } else {
            migrationMode = "selective"
        }
        if debug { writeToHistory(stringOfText: "[- debug -] Migration Mode (Go): \(migrationMode)\n") }
        
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
        self.source_user = source_user_field.stringValue.addingPercentEncoding(withAllowedCharacters: safeCharSet)!
        self.source_pass = source_pwd_field.stringValue.addingPercentEncoding(withAllowedCharacters: safeCharSet)!
        
        self.dest_jp_server = dest_jp_server_field.stringValue
        self.dest_user = dest_user_field.stringValue.addingPercentEncoding(withAllowedCharacters: safeCharSet)!
        self.dest_pass = dest_pwd_field.stringValue.addingPercentEncoding(withAllowedCharacters: safeCharSet)!
        // set credentials / servers - end
        
        // server is reachable - start
        checkURL2(serverURL: self.source_jp_server)  {
            (result: Bool) in
            print("checkURL2 returned result: \(result)")
            if !result {
                self.alert_dialog(header: "Attention:", message: "Unable to contact the source server: \(self.source_jp_server)")
                self.goButtonEnabled(button_status: true)
                return
            }
        }
        checkURL2(serverURL: self.dest_jp_server)  {
            (result: Bool) in
            print("checkURL2 returned result: \(result)")
            if !result {
                self.alert_dialog(header: "Attention:", message: "Unable to contact the destination server: \(self.dest_jp_server)")
                self.goButtonEnabled(button_status: true)
                return
            }
            // server is reachable - end
            
            self.sourceCreds = "\(self.source_user):\(self.source_pass)"
            let sourceUtf8Creds = self.sourceCreds.data(using: String.Encoding.utf8)
            self.sourceBase64Creds = (sourceUtf8Creds?.base64EncodedString())!
            
            self.destCreds = "\(self.dest_user):\(self.dest_pass)"
            let destUtf8Creds = self.destCreds.data(using: String.Encoding.utf8)
            self.destBase64Creds = (destUtf8Creds?.base64EncodedString())!
            // set credentials - end
            
            // check authentication - start
            self.authCheck(f_sourceURL: self.source_jp_server, f_credentials: self.sourceBase64Creds)  {
                (result: Bool) in
                if !result && !self.wipe_data {
                    NSLog("Source server authentication failure.")
                    return
                } else {
                    self.updateServerArray(url: self.source_jp_server, serverList: "source_server_array", theArray: self.sourceServerArray)
                    self.authCheck(f_sourceURL: self.dest_jp_server, f_credentials: self.destBase64Creds)  {
                        (result: Bool) in
                        if !result {
                            NSLog("Destination server authentication failure.")
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
                                    let destinationURL = URL(string: self.dest_jp_server_field.stringValue)
                                    let task_destinationURL = URLSession.shared.dataTask(with: destinationURL!) { _, response, _ in
                                        if (response as? HTTPURLResponse) != nil || (response as? HTTPURLResponse) == nil {
                                            //print("Destination server response: \(response)")
                                            NSLog("Destination server response: \(String(describing: response))")
                                            if(!self.theOpQ.isSuspended) {
                                                //====================================    Start Migrating/Removing    ====================================//
                                                self.startMigrating()
                                            }
                                        } else {
                                            DispatchQueue.main.async {
                                                //print("Destination server response: \(response)")
                                                NSLog("Destination server response: \(String(describing: response))")
                                                self.alert_dialog(header: "Attention", message: "The destination server URL could not be validated.")
                                            }
                                            
                                            NSLog("Failed to connect to destination server.")
                                            //self.go_button.isEnabled = true
                                            self.goButtonEnabled(button_status: true)
                                            return
                                        }
                                    }   // let task for destinationURL - end
                                    
                                    task_destinationURL.resume()
                                    // verify source destination URL - end
                                    
                                } else {
                                    DispatchQueue.main.async {
                                        self.alert_dialog(header: "Attention", message: "The source server URL could not be validated.")
                                    }
                                    NSLog("Failed to connect source server.")
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
        NSApplication.shared().terminate(self)
    }
    
    //================================= migration functions =================================//
    
    func authCheck(f_sourceURL: String, f_credentials: String, completion: @escaping (Bool) -> Void) {
        var validCredentials:Bool = false
        if self.debug { self.writeToHistory(stringOfText: "[- debug -] --- checking authentication to: \(f_sourceURL)\n") }
        
        if !(f_sourceURL == self.source_jp_server && wipe_data) {
            authQ.sync {
                var myURL = "\(f_sourceURL)/JSSResource/accounts"
                myURL = myURL.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
                if self.debug { self.writeToHistory(stringOfText: "[- debug -] checking: \(myURL)\n") }
                
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
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] \(myURL) auth check httpResponse: \(httpResponse.statusCode)\n") }
                        
                        if httpResponse.statusCode >= 199 && httpResponse.statusCode <= 299 {
                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] \(myURL) auth httpResponse, between 199 and 299: \(httpResponse.statusCode)\n") }
                            validCredentials = true
                            completion(validCredentials)
                        } else {
                            if self.debug { self.writeToHistory(stringOfText: "\n\n[- debug -] ---------- status code ----------\n") }
                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] \(httpResponse.statusCode)\n") }
                            self.httpStatusCode = httpResponse.statusCode
                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] ---------- status code ----------\n") }
                            if self.debug { self.writeToHistory(stringOfText: "\n\n[- debug -] ---------- response ----------\n") }
                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] \(httpResponse)\n") }
                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] ---------- response ----------\n\n") }
                            self.theOpQ.cancelAllOperations()
                            switch self.httpStatusCode {
                            case 401:
                                self.alert_dialog(header: "Authentication Failure", message: "Please verify username and password for:\n\(f_sourceURL)")
                            case 503:
                                self.alert_dialog(header: "Service Unavailable", message: "Take a deep breath and try again later, error: \(self.httpStatusCode):\n\(f_sourceURL)")
                            default:
                                self.alert_dialog(header: "Error", message: "An unknown error (\(self.httpStatusCode)) occured trying to query the server:\n\(f_sourceURL)")
                            }
                            //                        401 - wrong username and/or password
                            //                        409 - unable to create object; data missing or xml error
                            //self.go_button.isEnabled = true
                            self.goButtonEnabled(button_status: true)
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
        
        // set all the labels to white - start
        AllEndpointsArray = macOSEndpointArray + iOSEndpointArray + generalEndpointArray
        DispatchQueue.main.async {
            for i in (0..<self.AllEndpointsArray.count) {
                self.labelColor(endpoint: self.AllEndpointsArray[i], theColor: self.whiteText)
            }
        }
        // set all the labels to white - end
        
        if self.debug { self.writeToHistory(stringOfText: "[- debug -] Start Migrating/Removal\n") }
        if self.debug { self.writeToHistory(stringOfText: "[- debug -] platform: \(deviceType()).\n") }
        if self.debug { self.writeToHistory(stringOfText: "[- debug -] Migration Mode (startMigration): \(migrationMode).\n") }
        // list the items in the order they need to be migrated
        if migrationMode == "bulk" {
            // initialize list of items to migrate then add what we want - start
            objectsToMigrate.removeAll()
            // macOS
            switch deviceType() {
            case "macOS":
                if fileshares_button.state == 1 {
                    objectsToMigrate += ["distributionpoints"]
                }
                
                if directory_bindings_button.state == 1 {
                    objectsToMigrate += ["directorybindings"]
                }
                
                if dock_items_button.state == 1 {
                    objectsToMigrate += ["dockitems"]
                }
                
                if computers_button.state == 1 {
                    objectsToMigrate += ["computers"]
                }
                
                if sus_button.state == 1 {
                    objectsToMigrate += ["softwareupdateservers"]
                }
                
                if netboot_button.state == 1 {
                    objectsToMigrate += ["netbootservers"]
                }
                
                if ext_attribs_button.state == 1 {
                    objectsToMigrate += ["computerextensionattributes"]
                }
                
                if advcompsearch_button.state == 1 {
                    objectsToMigrate += ["advancedcomputersearches"]
                }
                
                if scripts_button.state == 1 {
                    objectsToMigrate += ["scripts"]
                }
                
                if smart_comp_grps_button.state == 1 || static_comp_grps_button.state == 1 {
                    objectsToMigrate += ["computergroups"]
                }
                
                if osxconfigurationprofiles_button.state == 1 {
                    objectsToMigrate += ["osxconfigurationprofiles"]
                }
                
                if packages_button.state == 1 {
                    objectsToMigrate += ["packages"]
                }
                
                if printers_button.state == 1 {
                    objectsToMigrate += ["printers"]
                }
                
                if configurations_button.state == 1 {
                    objectsToMigrate += ["computerconfigurations"]
                }
                
                if policies_button.state == 1 {
                    objectsToMigrate += ["policies"]
                }
            case "iOS":
                if mobiledeviceextensionattributes_button.state == 1 {
                    objectsToMigrate += ["mobiledeviceextensionattributes"]
                }
                
                if mobiledevices_button.state == 1 {
                    objectsToMigrate += ["mobiledevices"]
                }
                
                if smart_ios_groups_button.state == 1 || static_ios_groups_button.state == 1 {
                    objectsToMigrate += ["mobiledevicegroups"]
                }
                
                if advancedmobiledevicesearches_button.state == 1 {
                    objectsToMigrate += ["advancedmobiledevicesearches"]
                }
                
                if mobiledevicecApps_button.state == 1 {
                    //                    objectsToMigrate += ["mobiledeviceapplications"]
                }
                
                if mobiledeviceconfigurationprofiles_button.state == 1 {
                    objectsToMigrate += ["mobiledeviceconfigurationprofiles"]
                }
            case "general":
                if sites_button.state == 1 {
                    objectsToMigrate += ["sites"]
                }
                
                if userEA_button.state == 1 {
                    objectsToMigrate += ["userextensionattributes"]
                }
                
                if users_button.state == 1 {
                    objectsToMigrate += ["users"]
                }
                
                if building_button.state == 1 {
                    objectsToMigrate += ["buildings"]
                }
                
                if dept_button.state == 1 {
                    objectsToMigrate += ["departments"]
                }
                
                if categories_button.state == 1 {
                    objectsToMigrate += ["categories"]
                }
                
                if ldapservers_button.state == 1 {
                    objectsToMigrate += ["ldapservers"]
                }
                
                if jamfUserAccounts_button.state == 1 {
                    objectsToMigrate += ["jamfusers"]
                }
                
                if jamfGroupAccounts_button.state == 1 {
                    objectsToMigrate += ["jamfgroups"]
                }
                
                if networks_button.state == 1 {
                    objectsToMigrate += ["networksegments"]
                }
                
                if advusersearch_button.state == 1 {
                    objectsToMigrate += ["advancedusersearches"]
                }
                
                if smartUserGrps_button.state == 1 || staticUserGrps_button.state == 1 {
                    objectsToMigrate += ["usergroups"]
                }
            default: break
            }
            print("objectsToMigrate: \(objectsToMigrate)")
            
            // initialize list of items to migrate then add what we want - end
            if self.debug { self.writeToHistory(stringOfText: "[- debug -] objects: \(objectsToMigrate).\n") }
            
        }   // if migrationMode == "bulk" - end
        
        if objectsToMigrate.count == 0 {
            if self.debug { self.writeToHistory(stringOfText: "[- debug -] nothing selected to migrate/remove.\n") }
            self.goButtonEnabled(button_status: true)
            return
        }
        
        if wipe_data {
            if objectsToMigrate.count > 0 {
                // set server and credentials used for wipe
                sourceBase64Creds = destBase64Creds
                self.source_jp_server = dest_jp_server
                // move sites to the end of the array
                var siteIndex = objectsToMigrate.index(of: "users")
                if siteIndex != nil {
                    let siteTmp = objectsToMigrate.remove(at: siteIndex!)
                    objectsToMigrate.insert(siteTmp, at: objectsToMigrate.count)
                }
                siteIndex = objectsToMigrate.index(of: "sites")
                if siteIndex != nil {
                    let siteTmp = objectsToMigrate.remove(at: siteIndex!)
                    objectsToMigrate.insert(siteTmp, at: objectsToMigrate.count)
                }
                
            } else {
                //go_button.isEnabled = true
                self.goButtonEnabled(button_status: true)
                return
            }// end if objectsToMigrate - end
        }   // if wipe_data - end
        
        writeToHistory(stringOfText: migrateOrWipe)
        //go_button.isEnabled = false
        self.goButtonEnabled(button_status: false)
        
        if self.debug { self.writeToHistory(stringOfText: "[- debug -] migrating/removing \(objectsToMigrate.count) sections\n") }
        // loop through process of migrating or removing - start
        for i in (0..<objectsToMigrate.count) {
            if self.debug { self.writeToHistory(stringOfText: "[- debug -] Starting to process \(objectsToMigrate[i])\n") }
            if (goSender == "goButton" && migrationMode == "bulk") || (goSender == "selectToMigrateButton") {
                if self.debug { self.writeToHistory(stringOfText: "[- debug -] getting endpoint: \(objectsToMigrate[i])\n") }
                self.getEndpoints(endpoint: objectsToMigrate[i])  {
                    (result: String) in
                    if self.debug { self.writeToHistory(stringOfText: "[- debug -] getEndpoints result: \(result)\n") }
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
                self.existingEndpoints(destEndpoint: "\(objectsToMigrate[0])")  {
                    (result: String) in
                    if self.debug { self.writeToHistory(stringOfText: "[- debug -] Returned from existing endpoints: \(result)\n") }
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
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] nothing selected to migrate/remove.\n") }
                        self.alert_dialog(header: "Alert:", message: "Nothing was selected.")
                        self.goButtonEnabled(button_status: true)
                        return
                    }
                    
                    if self.debug { self.writeToHistory(stringOfText: "[- debug -] Item(s) chosen from selective: \(self.targetDataArray)\n") }
                    for j in (0..<self.targetDataArray.count) {
                        objToMigrateID = self.availableIDsToMigDict[self.targetDataArray[j]]!
                        if !self.wipe_data  {
                            if let selectedObject = self.availableObjsToMigDict[objToMigrateID] {
                                if self.debug { self.writeToHistory(stringOfText: "[- debug -] check for existing object: \(selectedObject)\n") }
                                if nil != self.currentEPs[self.availableObjsToMigDict[objToMigrateID]!] {
                                    if self.debug { self.writeToHistory(stringOfText: "[- debug -] \(selectedObject) already exists\n") }
                                    //self.currentEndpointID = self.currentEPs[xmlName]!
                                    self.endPointByID(endpoint: selectedEndpoint, endpointID: objToMigrateID, endpointCurrent: (j+1), endpointCount: self.targetDataArray.count, action: "update", destEpId: self.currentEPs[self.availableObjsToMigDict[objToMigrateID]!]!)
                                } else {
                                    self.endPointByID(endpoint: selectedEndpoint, endpointID: objToMigrateID, endpointCurrent: (j+1), endpointCount: self.targetDataArray.count, action: "create", destEpId: 0)
                                }
                            }
                        } else {
                            // selective removal
                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] remove - endpoint: \(self.targetDataArray[j])\t endpointID: \(objToMigrateID)\t endpointName: \(self.targetDataArray[j])\n") }
                            self.RemoveEndpoints(endpointType: selectedEndpoint, endPointID: objToMigrateID, endpointName: self.targetDataArray[j], endpointCurrent: (j+1), endpointCount: self.targetDataArray.count)
                            
                        }   // if !self.wipe_data else - end
                    }   // for j in  - end
                }
            }   //for i in - else - end
            // **************************************** selective migration - end ****************************************
        }   // loop through process of migrating or removing - end
        
    }   // func startMigrating - end
    
    
    func getEndpoints(endpoint: String, completion: @escaping (_ result: String) -> Void) {
        URLCache.shared.removeAllCachedResponses()
        if self.debug { self.writeToHistory(stringOfText: "[- debug -] Getting \(endpoint)\n") }
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
        
        theOpQ.maxConcurrentOperationCount = 2
        let semaphore = DispatchSemaphore(value: 0)
        
        theOpQ.addOperation {
            (endpoint == "jamfusers" || endpoint == "jamfgroups") ? (node = "accounts"):(node = endpoint)
            var myURL = "\(self.source_jp_server)/JSSResource/\(node)"
            myURL = myURL.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
            
            let encodedURL = NSURL(string: myURL)
            let request = NSMutableURLRequest(url: encodedURL! as URL)
            request.httpMethod = "GET"
            let configuration = URLSessionConfiguration.default
            configuration.httpAdditionalHeaders = ["Authorization" : "Basic \(self.sourceBase64Creds)", "Content-Type" : "application/json", "Accept" : "application/json"]
            let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
            let task = session.dataTask(with: request as URLRequest, completionHandler: {
                (data, response, error) -> Void in
                if let httpResponse = response as? HTTPURLResponse {
                    print("httpResponse: \(httpResponse.statusCode)")
                    
                    do {
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] Getting all endpoints from: \(myURL)\n") }
                        let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                        if let endpointJSON = json as? [String: Any] {
                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] endpointJSON: \(endpointJSON))") }
                            
                            switch endpoint {
                            case "advancedcomputersearches", "buildings", "categories", "computers", "computerextensionattributes", "departments", "distributionpoints", "directorybindings", "dockitems", "ldapservers", "netbootservers", "networksegments", "osxconfigurationprofiles", "packages", "printers", "scripts", "sites", "softwareupdateservers", "users", "mobiledeviceconfigurationprofiles", "mobiledeviceapplications", "advancedmobiledevicesearches", "mobiledeviceextensionattributes", "mobiledevices", "userextensionattributes", "advancedusersearches":
                                if let endpointInfo = endpointJSON[endpointParent] as? [Any] {
                                    let endpointCount: Int = endpointInfo.count
                                    if self.debug { self.writeToHistory(stringOfText: "[- debug -] Initial count for \(endpoint) found: \(endpointCount)\n") }
                                    
                                    if self.debug { self.writeToHistory(stringOfText: "[- debug -] Verify empty dictionary of objects - availableObjsToMigDict count: \(self.availableObjsToMigDict.count)\n") }
                                    
                                    if endpointCount > 0 {
                                        
                                        self.existingEndpoints(destEndpoint: "\(endpoint)")  {
                                            (result: String) in
                                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] Returned from existing \(endpoint): \(result)\n") }
                                            
                                            for i in (0..<endpointCount) {
                                                if i == 0 { self.availableObjsToMigDict.removeAll() }
                                                
                                                let record = endpointInfo[i] as! [String : AnyObject]
                                                
                                                if endpoint != "mobiledeviceapplications" {
                                                    self.availableObjsToMigDict[record["id"] as! Int] = record["name"] as! String?
                                                } else {
                                                    self.availableObjsToMigDict[record["id"] as! Int] = record["bundle_id"] as! String?
                                                }
                                                
                                                if self.debug { self.writeToHistory(stringOfText: "[- debug -] Current number of \(endpoint) to process: \(self.availableObjsToMigDict.count)\n") }
                                            }   // for i in (0..<endpointCount) end
                                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] Found total of \(self.availableObjsToMigDict.count) \(endpoint) to process\n") }
                                            
                                            var counter = 1
                                            if self.goSender == "goButton" {
                                                for (l_xmlID, l_xmlName) in self.availableObjsToMigDict {
                                                    if !self.wipe_data  {
                                                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] check for ID on \(l_xmlName): \(self.currentEPs[l_xmlName] ?? 0)\n") }
                                                        if self.currentEPs[l_xmlName] != nil {
                                                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] \(l_xmlName) already exists\n") }
                                                            //self.currentEndpointID = self.currentEPs[l_xmlName]!
                                                            self.endPointByID(endpoint: endpoint, endpointID: l_xmlID, endpointCurrent: counter, endpointCount: self.availableObjsToMigDict.count, action: "update", destEpId: self.currentEPs[l_xmlName]!)
                                                        } else {
                                                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] \(l_xmlName) - create\n") }
                                                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] function - endpoint: \(endpoint), endpointID: \(l_xmlID), endpointCurrent: \(counter), endpointCount: \(endpointCount), action: \"create\", destEpId: 0\n") }
                                                            self.endPointByID(endpoint: endpoint, endpointID: l_xmlID, endpointCurrent: counter, endpointCount: self.availableObjsToMigDict.count, action: "create", destEpId: 0)
                                                        }
                                                    } else {
                                                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] remove - endpoint: \(endpoint)\t endpointID: \(l_xmlID)\t endpointName: \(l_xmlName)\n") }
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
                                if self.debug { self.writeToHistory(stringOfText: "[- debug -] processing device groups\n") }
                                if let endpointInfo = endpointJSON[self.endpointDefDict["\(endpoint)"]!] as? [Any] {
                                    
                                    let endpointCount: Int = endpointInfo.count
                                    if self.debug { self.writeToHistory(stringOfText: "[- debug -] groups found: \(endpointCount)\n") }
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
                                                if self.smart_comp_grps_button.state == 0 {
                                                    excludeCount += smartGroupDict.count
                                                }
                                                if self.static_comp_grps_button.state == 0 {
                                                    excludeCount += staticGroupDict.count
                                                }
                                            case "mobiledevicegroups":
                                                if self.smart_ios_groups_button.state == 0 {
                                                    excludeCount += smartGroupDict.count
                                                }
                                                if self.static_ios_groups_button.state == 0 {
                                                    excludeCount += staticGroupDict.count
                                                }
                                            case "usergroups":
                                                if self.smartUserGrps_button.state == 0 {
                                                    excludeCount += smartGroupDict.count
                                                }
                                                if self.staticUserGrps_button.state == 0 {
                                                    excludeCount += staticGroupDict.count
                                                }
                                                
                                            default: break
                                            }
                                            
                                            
                                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] \(smartGroupDict.count) smart groups\n") }
                                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] \(staticGroupDict.count) static groups\n") }
                                            var currentGroupDict: [Int: String] = [:]
                                            // verify we have some groups
                                            for g in (0...1) {
                                                currentGroupDict.removeAll()
                                                var groupCount = 0
                                                var localEndpoint = endpoint
                                                switch endpoint {
                                                case "computergroups":
                                                    if (self.smart_comp_grps_button.state == 1) && (g == 0) {
                                                        currentGroupDict = smartGroupDict
                                                        groupCount = currentGroupDict.count
                                                        self.DeviceGroupType = "smartcomputergroups"
                                                        print("computergroups smart - DeviceGroupType: \(self.DeviceGroupType)")
                                                        localEndpoint = "smartcomputergroups"
                                                    }
                                                    if (self.static_comp_grps_button.state == 1) && (g == 1) {
                                                        currentGroupDict = staticGroupDict
                                                        groupCount = currentGroupDict.count
                                                        self.DeviceGroupType = "staticcomputergroups"
                                                        print("computergroups static - DeviceGroupType: \(self.DeviceGroupType)")
                                                        localEndpoint = "staticcomputergroups"
                                                    }
                                                case "mobiledevicegroups":
                                                    if (self.smart_ios_groups_button.state == 1) && (g == 0) {
                                                        currentGroupDict = smartGroupDict
                                                        groupCount = currentGroupDict.count
                                                        self.DeviceGroupType = "smartcomputergroups"
                                                        print("devicegroups smart - DeviceGroupType: \(self.DeviceGroupType)")
                                                        localEndpoint = "smartiosgroups"
                                                    }
                                                    if (self.static_ios_groups_button.state == 1) && (g == 1) {
                                                        currentGroupDict = staticGroupDict
                                                        groupCount = currentGroupDict.count
                                                        self.DeviceGroupType = "staticcomputergroups"
                                                        print("devicegroups static - DeviceGroupType: \(self.DeviceGroupType)")
                                                        localEndpoint = "staticiosgroups"
                                                    }
                                                case "usergroups":
                                                    if (self.smartUserGrps_button.state == 1) && (g == 0) {
                                                        currentGroupDict = smartGroupDict
                                                        groupCount = currentGroupDict.count
                                                        self.DeviceGroupType = "smartcomputergroups"
                                                        print("usergroups smart - DeviceGroupType: \(self.DeviceGroupType)")
                                                        localEndpoint = "smartusergroups"
                                                    }
                                                    if (self.staticUserGrps_button.state == 1) && (g == 1) {
                                                        currentGroupDict = staticGroupDict
                                                        groupCount = currentGroupDict.count
                                                        self.DeviceGroupType = "staticcomputergroups"
                                                        print("usergroups static - DeviceGroupType: \(self.DeviceGroupType)")
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
                                                                if self.debug { self.writeToHistory(stringOfText: "[- debug -] \(l_xmlName) already exists\n") }
                                                                self.endPointByID(endpoint: localEndpoint, endpointID: l_xmlID, endpointCurrent: counter, endpointCount: groupCount, action: "update", destEpId: self.currentEPs[l_xmlName]!)
                                                            } else {
                                                                if self.debug { self.writeToHistory(stringOfText: "[- debug -] \(l_xmlName) - create\n") }
                                                                if self.debug { self.writeToHistory(stringOfText: "[- debug -] function - endpoint: \(localEndpoint), endpointID: \(l_xmlID), endpointCurrent: \(counter), endpointCount: \(groupCount), action: \"create\", destEpId: 0\n") }
                                                                self.endPointByID(endpoint: localEndpoint, endpointID: l_xmlID, endpointCurrent: counter, endpointCount: groupCount, action: "create", destEpId: 0)
                                                            }
                                                            
//                                                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] \(l_xmlName) - create\n") }
//                                                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] function - endpoint: \(endpoint), endpointID: \(l_xmlID), endpointCurrent: \(counter), endpointCount: \(endpointCount), action: \"create\", destEpId: 0\n") }
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
                                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] Reached last object to migrate: \(endpoint)\n") }
                                            self.rmDELETE()
                                            self.goButtonEnabled(button_status: true)
                                            completion("Got endpoint - \(endpoint)")
                                        }
                                    }   // if endpointCount - end
                                }   // if let endpointInfo = endpointJSON["computer_groups"] - end
                                
                            case "policies":
                                if self.debug { self.writeToHistory(stringOfText: "[- debug -] processing \(endpoint)\n") }
                                if let endpointInfo = endpointJSON[endpoint] as? [Any] {
                                    let endpointCount: Int = endpointInfo.count
                                    if self.debug { self.writeToHistory(stringOfText: "[- debug -] \(endpoint) found: \(endpointCount)\n") }
                                    
                                    var computerPoliciesDict: [Int: String] = [:]
                                    if endpointCount > 0 {
                                        
                                        // create dictionary of existing policies
                                        self.existingEndpoints(destEndpoint: "policies")  {
                                            (result: String) in
                                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] Returned from existing endpoints: \(result)\n") }
                                            
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
                                                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] check for ID on \(l_xmlName): \(String(describing: self.currentEPs[l_xmlName]))\n") }
                                                        if self.currentEPs[l_xmlName] != nil {
                                                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] \(l_xmlName) already exists\n") }
                                                            //self.currentEndpointID = self.currentEPs[l_xmlName]!
                                                            self.endPointByID(endpoint: endpoint, endpointID: l_xmlID, endpointCurrent: counter, endpointCount: nonRemotePolicies, action: "update", destEpId: self.currentEPs[l_xmlName]!)
                                                        } else {
                                                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] \(l_xmlName) - create\n") }
                                                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] function - endpoint: \(endpoint), endpointID: \(l_xmlID), endpointCurrent: \(counter), endpointCount: \(endpointCount), action: \"create\", destEpId: 0\n") }
                                                            self.endPointByID(endpoint: endpoint, endpointID: l_xmlID, endpointCurrent: counter, endpointCount: nonRemotePolicies, action: "create", destEpId: 0)
                                                        }
                                                        //self.endPointByID(endpoint: endpoint, endpointID: l_xmlID, endpointCurrent: counter, endpointCount: nonRemotePolicies, action: "create", destEpId: 0)
                                                    } else {
                                                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] remove - endpoint: \(endpoint)\t endpointID: \(l_xmlID)\t endpointName: \(l_xmlName)\n") }
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
                                    if self.debug { self.writeToHistory(stringOfText: "[- debug -] Initial count for \(node) found: \(endpointCount)\n") }
                                    
                                    if self.debug { self.writeToHistory(stringOfText: "[- debug -] Verify empty dictionary of objects - availableObjsToMigDict count: \(self.availableObjsToMigDict.count)\n") }
                                    
                                    if endpointCount > 0 {
                                        
                                        //                                        self.existingEndpoints(destEndpoint: "accounts")  {
                                        //                                            (result: String) in
                                        //                                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] Returned from existing \(node): \(result)\n") }
                                        
                                        for i in (0..<endpointCount) {
                                            if i == 0 { self.availableObjsToMigDict.removeAll() }
                                            
                                            let record = endpointInfo[i] as! [String : AnyObject]
                                            if !(endpoint == "jamfusers" && record["name"] as! String? == self.dest_user) {
                                                self.availableObjsToMigDict[record["id"] as! Int] = record["name"] as! String?
                                            }
                                            
                                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] Current number of \(endpoint) to process: \(self.availableObjsToMigDict.count)\n") }
                                        }   // for i in (0..<endpointCount) end
                                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] Found total of \(self.availableObjsToMigDict.count) \(endpoint) to process\n") }
                                        
                                        var counter = 1
                                        if self.goSender == "goButton" {
                                            for (l_xmlID, l_xmlName) in self.availableObjsToMigDict {
                                                if !self.wipe_data  {
                                                    if self.debug { self.writeToHistory(stringOfText: "[- debug -] check for ID on \(l_xmlName): \(String(describing: self.currentEPs[l_xmlName]))\n") }
                                                    
                                                    if self.currentEPs[l_xmlName] != nil {
                                                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] \(l_xmlName) already exists\n") }
                                                        //self.currentEndpointID = self.currentEPs[l_xmlName]!
                                                        self.endPointByID(endpoint: endpoint, endpointID: l_xmlID, endpointCurrent: counter, endpointCount: self.availableObjsToMigDict.count, action: "update", destEpId: self.currentEPs[l_xmlName]!)
                                                    } else {
                                                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] \(l_xmlName) - create\n") }
                                                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] function - endpoint: \(endpoint), endpointID: \(l_xmlID), endpointCurrent: \(counter), endpointCount: \(endpointCount), action: \"create\", destEpId: 0\n") }
                                                        self.endPointByID(endpoint: endpoint, endpointID: l_xmlID, endpointCurrent: counter, endpointCount: self.availableObjsToMigDict.count, action: "create", destEpId: 0)
                                                    }
                                                } else {
                                                    if !(endpoint == "jamfusers" && "\(l_xmlName)".lowercased() == self.dest_user.lowercased()) {
                                                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] remove - endpoint: \(endpoint)\t endpointID: \(l_xmlID)\t endpointName: \(l_xmlName)\n") }
                                                        self.RemoveEndpoints(endpointType: endpoint, endPointID: l_xmlID, endpointName: l_xmlName, endpointCurrent: counter, endpointCount: self.availableObjsToMigDict.count)                                                        }
                                                    
                                                    
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
                                        //                                        }   // self.existingEndpoints - end
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
                                    if self.debug { self.writeToHistory(stringOfText: "[- debug -] Initial count for \(endpoint) found: \(endpointCount)\n") }
                                    
                                    if self.debug { self.writeToHistory(stringOfText: "[- debug -] Verify empty dictionary of objects - availableObjsToMigDict count: \(self.availableObjsToMigDict.count)\n") }
                                    
                                    if endpointCount > 0 {
                                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] Create Id Mappings - start.\n") }
                                        
                                        self.nameIdDict(server: self.source_jp_server, endPoint: "computerconfigurations", id: "sourceId") {
                                            (result: [String:Dictionary<String,Int>]) in
                                            self.idDict.removeAll()
                                            
                                            self.nameIdDict(server: self.source_jp_server, endPoint: "packages", id: "sourceId") {
                                                (result: [String:Dictionary<String,Int>]) in
                                            
                                                self.nameIdDict(server: self.dest_jp_server, endPoint: "packages", id: "destId") {
                                                    (result: [String:Dictionary<String,Int>]) in
                                                    self.packages_id_map = result
                                                    if self.debug { self.writeToHistory(stringOfText: "[- debug -] packages id map:\n\(self.packages_id_map)\n") }
                                                    self.idDict.removeAll()
                                                    
                                                    self.nameIdDict(server: self.source_jp_server, endPoint: "scripts", id: "sourceId") {
                                                        (result: [String:Dictionary<String,Int>]) in
                                                        
                                                        self.nameIdDict(server: self.dest_jp_server, endPoint: "scripts", id: "destId") {
                                                            (result: [String:Dictionary<String,Int>]) in
                                                            self.scripts_id_map = result
                                                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] scripts id map:\n\(self.scripts_id_map)\n") }
                                                            self.idDict.removeAll()
                                                            
                                                            self.nameIdDict(server: self.source_jp_server, endPoint: "printers", id: "sourceId") {
                                                                (result: [String:Dictionary<String,Int>]) in
                                                                
                                                                self.nameIdDict(server: self.dest_jp_server, endPoint: "printers", id: "destId") {
                                                                    (result: [String:Dictionary<String,Int>]) in
                                                                    self.printers_id_map = result
                                                                    if self.debug { self.writeToHistory(stringOfText: "[- debug -] printers id map:\n\(self.printers_id_map)\n")}
                                                                    self.idDict.removeAll()
                                                                    
                                                                    self.nameIdDict(server: self.source_jp_server, endPoint: "directorybindings", id: "sourceId") {
                                                                        (result: [String:Dictionary<String,Int>]) in
                                                                        
                                                                        self.nameIdDict(server: self.dest_jp_server, endPoint: "directorybindings", id: "destId") {
                                                                            (result: [String:Dictionary<String,Int>]) in
                                                                            self.bindings_id_map = result
                                                                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] bindings id map:\n\(self.bindings_id_map)\n")}
                                                                            self.idDict.removeAll()

                                                                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] Create Id Mappings - end.\n") }
                                                                            
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
                                                                                        self.writeToHistory(stringOfText: "Smart config '\(self.configObjectsDict[key]?["parent"] ?? "name not found")' is missing its parent and cannot be migrated.\n")
                                                                                        self.writeToHistory(stringOfText: "Smart config '\(key)' (child of '\(self.configObjectsDict[key]?["parent"] ?? "name not found")') will be migrated and changed from smart to standard.\n")
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
                                                                                if self.debug { self.writeToHistory(stringOfText: "[- debug -] Returned from existing \(endpoint): \(result)\n") }
                                                                                
                                                                                var tmp_availableObjsToMigDict = [Int:String]()
                                                                                
                                                                                for i in (0..<endpointCount) {
//                                                                                    if i == 0 { self.availableObjsToMigDict.removeAll() }
                                                                                    
                                                                                    let record = endpointInfo[i] as! [String : AnyObject]
                                                                                    
                                                                                    tmp_availableObjsToMigDict[record["id"] as! Int] = record["name"] as! String?
                                                                                    
                                                                                }   // for i in (0..<endpointCount) end
                                                                                
                                                                                self.availableObjsToMigDict.removeAll()
                                                                                for orderedId in orderedConfArray {
                                                                                    
                                                                                    self.availableObjsToMigDict[Int(orderedId)!] = tmp_availableObjsToMigDict[Int(orderedId)!]
                                                                                    
                                                                                    if self.debug { self.writeToHistory(stringOfText: "[- debug -] Current number of \(endpoint) to process: \(self.availableObjsToMigDict.count)\n") }
                                                                                }   // for i in (0..<endpointCount) end
                                                                                
                                                                                
                                                                                if self.debug { self.writeToHistory(stringOfText: "[- debug -] Found total of \(self.availableObjsToMigDict.count) \(endpoint) to process\n") }
                                                                                
                                                                                var counter = 1
                                                                                if self.goSender == "goButton" {
//                                                                                  for (l_xmlID, l_xmlName) in self.availableObjsToMigDict {
                                                                                    for orderedId in orderedConfArray {
                                                                                        let l_xmlID = Int(orderedId)
                                                                                        let l_xmlName = tmp_availableObjsToMigDict[l_xmlID!]
                                                                                        if !self.wipe_data  {
                                                                                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] check for ID on \(String(describing: l_xmlName)): \(self.currentEPs[l_xmlName!] ?? 0)\n") }
                                                                                            if self.currentEPs[l_xmlName!] != nil {
                                                                                                if self.debug { self.writeToHistory(stringOfText: "[- debug -] \(String(describing: l_xmlName)) already exists\n") }
                                                                                                //self.currentEndpointID = self.currentEPs[l_xmlName]!
                                                                                                self.endPointByID(endpoint: endpoint, endpointID: l_xmlID!, endpointCurrent: counter, endpointCount: self.availableObjsToMigDict.count, action: "update", destEpId: self.currentEPs[l_xmlName!]!)
                                                                                            } else {
                                                                                                if self.debug { self.writeToHistory(stringOfText: "[- debug -] \(String(describing: l_xmlName)) - create\n") }
                                                                                                if self.debug { self.writeToHistory(stringOfText: "[- debug -] function - endpoint: \(endpoint), endpointID: \(String(describing: l_xmlID)), endpointCurrent: \(counter), endpointCount: \(endpointCount), action: \"create\", destEpId: 0\n") }
                                                                                                self.endPointByID(endpoint: endpoint, endpointID: l_xmlID!, endpointCurrent: counter, endpointCount: self.availableObjsToMigDict.count, action: "create", destEpId: 0)
                                                                                            }
                                                                                        } else {
                                                                                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] remove - endpoint: \(endpoint)\t endpointID: \(String(describing: l_xmlID))\t endpointName: \(String(describing: l_xmlName))\n") }
                                                                                            self.RemoveEndpoints(endpointType: endpoint, endPointID: l_xmlID!, endpointName: l_xmlName!, endpointCurrent: counter, endpointCount: self.availableObjsToMigDict.count)
                                                                                        }   // if !self.wipe_data else - end
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
    
    func endPointByID(endpoint: String, endpointID: Int, endpointCurrent: Int, endpointCount: Int, action: String, destEpId: Int) {
        URLCache.shared.removeAllCachedResponses()
        if self.debug { self.writeToHistory(stringOfText: "[- debug -] endpoint passed to endPointByID: \(endpoint)\n") }
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
            theOpQ.addOperation {
                var myURL = "\(self.source_jp_server)/JSSResource/\(localEndPointType)/id/\(endpointID)"
                myURL = myURL.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
                myURL = myURL.replacingOccurrences(of: "/JSSResource/jamfusers/id", with: "/JSSResource/accounts/userid")
                myURL = myURL.replacingOccurrences(of: "/JSSResource/jamfgroups/id", with: "/JSSResource/accounts/groupid")
                myURL = myURL.replacingOccurrences(of: "id/id/", with: "id/")
                if self.debug { self.writeToHistory(stringOfText: "[- debug -] fetching XML from: \(myURL)\n") }
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
                        
                        switch endpoint {
                        case "buildings", "departments", "sites", "categories", "directorybindings", "distributionpoints", "dockitems", "netbootservers", "softwareupdateservers", "computerextensionattributes", "computerconfigurations", "scripts", "printers", "osxconfigurationprofiles", "mobiledeviceconfigurationprofiles", "mobiledeviceapplications", "advancedmobiledevicesearches", "mobiledeviceextensionattributes", "mobiledevicegroups", "smartiosgroups", "staticiosgroups", "mobiledevices", "smartusergroups", "staticusergroups", "userextensionattributes", "advancedusersearches":
                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] processing \(endpoint) - verbose\n") }
                            //print("\nXML: \(PostXML)")
                            
                            // clean up PostXML, remove unwanted/conflicting data
                            switch endpoint {
                            case "advancedusersearches":
                                for xmlTag in ["users"] {
                                    PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag)
                                }
                                
                            case "advancedmobiledevicesearches", "mobiledevicegroups", "smartiosgroups", "staticiosgroups":
                                for xmlTag in ["mobile_devices"] {
                                    PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag)
                                }
                                
                            case "mobiledeviceconfigurationprofiles":
                                for xmlTag in ["scope"] {
                                    PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag)
                                }
                                
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
                                for xmlTag in ["initial_entry_date_epoch", "initial_entry_date_utc", "last_enrollment_epoch", "last_enrollment_utc", "applications", "certificates", "configuration_profiles", "provisioning_profiles", "mobile_device_groups", "extension_attributes"] {
                                    PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag)
                                }
                                
                            case "smartusergroups", "staticusergroups":
                                for xmlTag in ["full_name", "phone_number", "email_address"] {
                                    PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag)
                                }
                                
                            case "computerconfigurations":
                                if self.debug { self.writeToHistory(stringOfText: "[- debug -] cleaning up computerconfigurations - verbose\n") }
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
                            self.CreateEndpoints(endpointType: endpoint, endPointXML: PostXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, destEpId: destEpId)
                            
                        case "directorybindings", "ldapservers":
                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] processing ldapservers - verbose\n") }
                            // remove password from XML, since it doesn't work on the new server
                            let regexComp = try! NSRegularExpression(pattern: "<password_sha256 since=\"9.23\">(.*?)</password_sha256>", options:.caseInsensitive)
                            PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "")
                            //print("\nXML: \(PostXML)")
                            
                            if self.getEndpointInProgress != endpoint {
                                self.endpointInProgress = endpoint
                                self.getStatusInit(endpoint: endpoint, count: endpointCount)
                            }
                            self.get_completed_field.stringValue = "\(endpointCurrent)"
                            
                            self.CreateEndpoints(endpointType: endpoint, endPointXML: PostXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, destEpId: destEpId)
                            
                        case "advancedcomputersearches":
                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] processing advancedcomputersearches - verbose\n") }
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
                            
                            self.CreateEndpoints(endpointType: endpoint, endPointXML: PostXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, destEpId: destEpId)
                            
                            
                        case "computers":
                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] processing computers - verbose\n") }
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
                            
                            self.CreateEndpoints(endpointType: endpoint, endPointXML: PostXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, destEpId: destEpId)
                            
                        case "networksegments":
                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] processing network segments - verbose\n") }
                            // remove items not transfered; distribution points, netboot server, SUS from XML
                            let regexDistro1 = try! NSRegularExpression(pattern: "<distribution_server>(.*?)</distribution_server>", options:.caseInsensitive)
                            let regexDistro2 = try! NSRegularExpression(pattern: "<distribution_point>(.*?)</distribution_point>", options:.caseInsensitive)
                            let regexDistro3 = try! NSRegularExpression(pattern: "<url>(.*?)</url>", options:.caseInsensitive)
                            let regexNetBoot = try! NSRegularExpression(pattern: "<netboot_server>(.*?)</netboot_server>", options:.caseInsensitive)
                            let regexSUS = try! NSRegularExpression(pattern: "<swu_server>(.*?)</swu_server>", options:.caseInsensitive)
                            PostXML = regexDistro1.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<distribution_server/>")
                            // if not migrating file shares remove then from network segments xml - start
                            if self.fileshares_button.state == 0 {
                                PostXML = regexDistro2.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<distribution_point/>")
                                PostXML = regexDistro3.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<url/>")
                            }
                            // if not migrating file shares remove then from network segments xml - end
                            // if not migrating netboot server remove then from network segments xml - start
                            if self.netboot_button.state == 0 {
                                PostXML = regexNetBoot.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<netboot_server/>")
                            }
                            // if not migrating netboot server remove then from network segments xml - end
                            // if not migrating software update server remove then from network segments xml - start
                            if self.sus_button.state == 0 {
                                PostXML = regexSUS.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<swu_server/>")
                            }
                            // if not migrating software update server remove then from network segments xml - end
                            
                            //print("\nXML: \(PostXML)")
                            
                            if self.getEndpointInProgress != endpoint {
                                self.endpointInProgress = endpoint
                                self.getStatusInit(endpoint: endpoint, count: endpointCount)
                            }
                            self.get_completed_field.stringValue = "\(endpointCurrent)"
                            
                            self.CreateEndpoints(endpointType: endpoint, endPointXML: PostXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, destEpId: destEpId)
                        case "computergroups", "smartcomputergroups", "staticcomputergroups":
                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] processing \(endpoint) - verbose\n") }
                            // remove computers that are a member of a smart group
                            if PostXML.range(of:"<is_smart>true</is_smart>") != nil {
                                let regexComp = try! NSRegularExpression(pattern: "<computers>(.*?)</computers>", options:.caseInsensitive)
                                PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "")
                            }
                            //                        if endpoint == "smartcomputergroups" {
                            //                            let regexComp = try! NSRegularExpression(pattern: "<computers>(.*?)</computers>", options:.caseInsensitive)
                            //                            PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "")
                            //                        }
                            //print("\n\(endpoint) XML: \(PostXML)\n")
                            
                            if self.getEndpointInProgress != endpoint {
                                self.endpointInProgress = endpoint
                                self.getStatusInit(endpoint: endpoint, count: endpointCount)
                            }
                            self.get_completed_field.stringValue = "\(endpointCurrent)"
                            
                            self.CreateEndpoints(endpointType: endpoint, endPointXML: PostXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, destEpId: destEpId)
                            
                        case "packages":
                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] processing packages - verbose\n") }
                            // remove 'No category assigned' from XML
                            let regexComp = try! NSRegularExpression(pattern: "<category>No category assigned</category>", options:.caseInsensitive)
                            PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<category/>")
                            //print("\nXML: \(PostXML)")
                            
                            if self.getEndpointInProgress != endpoint {
                                self.endpointInProgress = endpoint
                                self.getStatusInit(endpoint: endpoint, count: endpointCount)
                            }
                            self.get_completed_field.stringValue = "\(endpointCurrent)"
                            
                            self.CreateEndpoints(endpointType: endpoint, endPointXML: PostXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, destEpId: destEpId)
                            
                        case "policies":
                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] processing policies - verbose\n") }
                            // remove individual objects that are scoped to the policy from XML
                            for xmlTag in ["self_service_icon", "computers", "allow_users_to_defer", "allow_deferral_until_utc"] {
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
                            
                            self.CreateEndpoints(endpointType: endpoint, endPointXML: PostXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, destEpId: destEpId)
                            
                        case "users":
                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] processing users - verbose\n") }
                            
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
                            
                            self.CreateEndpoints(endpointType: endpoint, endPointXML: PostXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, destEpId: destEpId)
                            
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
                            
                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] processing ldapservers\(endpoint) - verbose\n") }
                            // remove password from XML, since it doesn't work on the new server
                            let regexComp = try! NSRegularExpression(pattern: "<password_sha256 since=\"9.32\">(.*?)</password_sha256>", options:.caseInsensitive)
                            PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "")
                            //print("\nXML: \(PostXML)")
                            if action == "create" {
                                // newly created accounts are disabled
                                let regexComp1 = try! NSRegularExpression(pattern: "<enabled>Enabled</enabled>", options:.caseInsensitive)
                                PostXML = regexComp1.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<enabled>Disabled</enabled>")
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
                            
                            self.CreateEndpoints(endpointType: accountType, endPointXML: PostXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, destEpId: destEpId)
                            
                        default:
                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] Unknown endpoint: \(endpoint)\n") }
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
    
    func CreateEndpoints(endpointType: String, endPointXML: String, endpointCurrent: Int, endpointCount: Int, action: String, destEpId: Int) {
        // this is where we create the new endpoint
        if self.debug { self.writeToHistory(stringOfText: "[- debug -] Creating new: \(endpointType)\n") }
        var DestURL = ""
        let destinationEpId = destEpId
        //if self.debug { self.writeToHistory(stringOfText: "[- debug -] ----- Posting #\(endpointCurrent): \(endpointType) -----\n") }
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
        //        if endpointType == "smartcomputergroups" || endpointType == "staticcomputergroups" {
        //            localEndPointType = "computergroups"
        //        }
        
        theCreateQ.addOperation {
            
            DestURL = "\(self.dest_jp_server_field.stringValue)/JSSResource/" + localEndPointType + "/id/\(destinationEpId)"
            if self.debug { self.writeToHistory(stringOfText: "[- debug -] Original Dest. URL: \(DestURL)\n") }
            DestURL = DestURL.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
            DestURL = DestURL.replacingOccurrences(of: "/JSSResource/jamfusers/id", with: "/JSSResource/accounts/userid")
            DestURL = DestURL.replacingOccurrences(of: "/JSSResource/jamfgroups/id", with: "/JSSResource/accounts/groupid")
            
            if self.debug { self.writeToHistory(stringOfText: "[- debug -] Action: \(action)\t URL: \(DestURL)\t Object \(endpointCurrent) of \(endpointCount)\n") }
            if self.debug { self.writeToHistory(stringOfText: "[- debug -] Object XML: \(endPointXML)\n") }
            
            if endpointCurrent == 1 {
                self.postCount = 1
                // initial counters
                self.counters[endpointType] = ["create":0, "update":0, "fail":0]
            } else {
                self.postCount += 1
                //print("destURL: \(DestURL)\n")
            }
            let encodedURL = NSURL(string: DestURL)
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
                    //print(httpResponse.statusCode)
                    //print(httpResponse)
                    //print("POST XML-\(endpointCurrent): endpointType: \(endpointType)  endpointNumber: \(endpointCurrent)")
                    DispatchQueue.main.async {
                        //self.migrationStatus(endpoint: endpointType, count: endpointCount)
                        self.migrationStatus(endpoint: endpointType, count: endpointCount)
                        //self.object_name_field.stringValue = endpointType
                        
                        self.objects_completed_field.stringValue = "\(self.postCount)"
                        //                        if endpointCount == endpointCurrent && self.changeColor {
                        //                            self.labelColor(endpoint: endpointType, theColor: self.greenText)
                        //                        }
                        //if self.objectsToMigrate.last == endpointType && endpointCount == endpointCurrent {
                        if self.objectsToMigrate.last == localEndPointType && endpointCount == endpointCurrent {
                            //self.go_button.isEnabled = true
                            self.rmDELETE()
                            self.goButtonEnabled(button_status: true)
                            print("Done")
                        }
                    }
                    // look to see if we are processing the next endpointType - start
                    if self.endpointInProgress != endpointType {
                        self.writeToHistory(stringOfText: "Migrating \(endpointType)\n")
                        self.endpointInProgress = endpointType
                        //                        self.changeColor = true
                        self.POSTsuccessCount = 0
                        //                        self.progressCountArray["\(endpointType)"] = 0
                    }   // look to see if we are processing the next localEndPointType - end
                    if httpResponse.statusCode >= 199 && httpResponse.statusCode <= 299 {
                        self.writeToHistory(stringOfText: "\t\(self.getName(endpoint: endpointType, objectXML: endPointXML))\n")
                        
                        self.POSTsuccessCount += 1
                        self.progressCountArray["\(endpointType)"] = self.progressCountArray["\(endpointType)"]!+1
                        if endpointCount == endpointCurrent && self.progressCountArray["\(endpointType)"] == endpointCount {
                            //                            if endpointCount == endpointCurrent && self.changeColor {
                            self.labelColor(endpoint: endpointType, theColor: self.greenText)
                        }
                        //                        print("\n\n---------- Success ----------")
                        //                        print("\(endPointXML)")
                        //                        print("---------- Success ----------")
                        
                        // update global counters
                        self.counters[endpointType]?["\(action)"] = (self.counters[endpointType]?["\(action)"])!+1
                    } else {
                        // create failed
                        self.labelColor(endpoint: endpointType, theColor: self.yellowText)
                        //                        self.changeColor = false
                        self.writeToHistory(stringOfText: "\n\n**** \(self.getName(endpoint: endpointType, objectXML: endPointXML)) - Failed\n")
                        // Write xml for degugging - start
                        
                        self.writeToHistory(stringOfText: "\(endPointXML)\n")
                        self.writeToHistory(stringOfText: "HTTP status code: \(httpResponse.statusCode)\n")
                        
                        // Write xml for degugging - end
                        
                        if self.progressCountArray["\(endpointType)"] == 0 && endpointCount == endpointCurrent {
                            self.labelColor(endpoint: endpointType, theColor: self.redText)
                        }
                        if self.debug { self.writeToHistory(stringOfText: "\n\n[- debug -] ---------- xml of failed upload ----------\n") }
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] \(endPointXML)\n") }
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] ---------- status code ----------\n") }
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] \(httpResponse.statusCode)\n") }
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] ---------- response ----------\n") }
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] \(httpResponse)\n") }
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] ---------- response ----------\n\n") }
                        //                        401 - wrong username and/or password
                        //                        409 - unable to create object; already exists or data missing or xml error
                        
                        // update global counters
                        self.counters[endpointType]?["fail"] = (self.counters[endpointType]?["fail"])!+1
                    }
                }
                if self.debug { self.writeToHistory(stringOfText: "[- debug -] POST or PUT Operation: \(request.httpMethod)\n") }
                
                if self.debug { self.writeToHistory(stringOfText: "[- debug -] endpoint: \(localEndPointType)-\(endpointCurrent)\t Total: \(endpointCount)\t Succeeded: \(self.POSTsuccessCount)\t No Failures: \(self.changeColor)\t SuccessArray \(String(describing: self.progressCountArray["\(localEndPointType)"]))!\n") }
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
        theOpQ.maxConcurrentOperationCount = 3
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
            
            theOpQ.addOperation {
                var DestURL = "\(self.dest_jp_server_field.stringValue)/JSSResource/" + localEndPointType + "/id/\(endPointID)"
                DestURL = DestURL.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
                DestURL = DestURL.replacingOccurrences(of: "/JSSResource/jamfusers/id", with: "/JSSResource/accounts/userid")
                DestURL = DestURL.replacingOccurrences(of: "/JSSResource/jamfgroups/id", with: "/JSSResource/accounts/groupid")
                DestURL = DestURL.replacingOccurrences(of: "id/id/", with: "id/")
                
                if self.debug { self.writeToHistory(stringOfText: "[- debug -] removing \(endpointType) with ID \(endPointID)  -  Object \(endpointCurrent) of \(endpointCount)\n") }
                if self.debug { self.writeToHistory(stringOfText: "\n[- debug -] removal URL: \(DestURL)\n") }
                
                let encodedURL = NSURL(string: DestURL)
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
                                self.writeToHistory(stringOfText: "Removing \(endpointType)\n")
                            }   // look to see if we are processing the next endpointType - end
                            //                            self.object_name_field.stringValue = endpointType
                            //                            self.objects_completed_field.stringValue = "\(endpointCurrent)"
                            
                        }
                        if httpResponse.statusCode >= 199 && httpResponse.statusCode <= 299 {
                            self.writeToHistory(stringOfText: "\t\(endpointName)\n")
                            self.POSTsuccessCount += 1
                            if endpointCount == endpointCurrent && self.changeColor {
                                self.labelColor(endpoint: endpointType, theColor: self.greenText)
                            }
                            
                        } else {
                            self.labelColor(endpoint: endpointType, theColor: self.yellowText)
                            self.changeColor = false
                            self.writeToHistory(stringOfText: "**** Failed to remove: \(endpointName)\n")
                            if self.POSTsuccessCount == 0 && endpointCount == endpointCurrent {
                                self.labelColor(endpoint: endpointType, theColor: self.redText)
                            }
                            if self.debug { self.writeToHistory(stringOfText: "\n\n[- debug -] ---------- endpoint info ----------\n") }
                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] Type: \(endpointType)\t Name: \(endpointName)\t ID: \(endPointID)\n") }
                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] ---------- status code ----------\n") }
                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] \(httpResponse.statusCode)\n") }
                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] ---------- response ----------\n") }
                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] \(httpResponse)\n") }
                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] ---------- response ----------\n\n") }
                        }
                        
                    }
                    if self.activeTab() != "selective" {
                        if self.objectsToMigrate.last == localEndPointType && endpointCount == endpointCurrent {
                            // check for file that allows deleting data from destination server, delete if found - start
                            self.rmDELETE()
                            // check for file that allows deleting data from destination server, delete if found - end
                            //self.go_button.isEnabled = true
                            self.goButtonEnabled(button_status: true)
                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] Done\n") }
                        }
                        semaphore.signal()
                        if error != nil {
                        }
                    } else {
                        if self.debug { self.writeToHistory(stringOfText: "\n[- debug -] endpointCount: \(endpointCount)\t endpointCurrent: \(endpointCurrent)\n") }
                        
                        if endpointCount == endpointCurrent {
                            // check for file that allows deleting data from destination server, delete if found - start
                            self.rmDELETE()
                            // check for file that allows deleting data from destination server, delete if found - end
                            //self.go_button.isEnabled = true
                            self.goButtonEnabled(button_status: true)
                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] Done\n") }
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
        var destXmlName = ""
        var existingEndpointNode = ""
        (destEndpoint == "jamfusers" || destEndpoint == "jamfgroups") ? (existingEndpointNode = "accounts"):(existingEndpointNode = destEndpoint)
        print("\nGetting existing endpoints: \(existingEndpointNode)\n")
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
        
        //theOpQ.maxConcurrentOperationCount = 1
        let semaphore = DispatchSemaphore(value: 1)
        destEPQ.async {
            //        theOpQ.addOperation {
            //print("Entered destEPQ")
            var destURL = "\(self.dest_jp_server)/JSSResource/\(existingEndpointNode)"
            destURL = destURL.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
            print("existing endpoints URL: \(destURL)")
            
            let destEncodedURL = NSURL(string: destURL)
            let destRequest = NSMutableURLRequest(url: destEncodedURL! as URL)
            destRequest.httpMethod = "GET"
            let destConf = URLSessionConfiguration.default
            destConf.httpAdditionalHeaders = ["Authorization" : "Basic \(self.destBase64Creds)", "Content-Type" : "application/json", "Accept" : "application/json"]
            let destSession = Foundation.URLSession(configuration: destConf, delegate: self, delegateQueue: OperationQueue.main)
            let task = destSession.dataTask(with: destRequest as URLRequest, completionHandler: {
                (data, response, error) -> Void in
                if let httpResponse = response as? HTTPURLResponse {
                    print("httpResponse: \(String(describing: response))")
                    do {
                        let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                        if let destEndpointJSON = json as? [String: Any] {
                            if self.debug { self.writeToHistory(stringOfText: "\n[- debug -] -------- Getting all \(destEndpoint) --------\n") }
                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] existing destEndpointJSON: \(destEndpointJSON))\n") }
                            switch destEndpoint {
                                
                            // need to revisit as name isn't the best indicatory on whether or not a computer exists
                            case "-computers":
                                if self.debug { self.writeToHistory(stringOfText: "[- debug -] getting current computers\n") }
                                if let destEndpointInfo = destEndpointJSON["computers"] as? [Any] {
                                    let destEndpointCount: Int = destEndpointInfo.count
                                    if self.debug { self.writeToHistory(stringOfText: "[- debug -] esisting \(destEndpoint) found: \(destEndpointCount)\n") }
                                    if self.debug { self.writeToHistory(stringOfText: "[- debug -] destEndpointInfo: \(destEndpointInfo)\n") }
                                    
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
                                if destEndpoint == "jamfusers" || destEndpoint == "jamfgroups" {
                                    let accountsDict = destEndpointJSON as Dictionary<String, Any>
                                    let usersGroups = accountsDict["accounts"] as! Dictionary<String, Any>
                                    print("users: \(String(describing: usersGroups["users"]))")
                                    print("groups: \(String(describing: usersGroups["groups"]))")
                                    destEndpoint == "jamfusers" ? (destEndpointDict = usersGroups["users"] as Any):(destEndpointDict = usersGroups["groups"] as Any)
                                } else {
                                    destEndpointDict = destEndpointJSON["\(endpointParent)"]
                                }
                                if self.debug { self.writeToHistory(stringOfText: "[- debug -] getting current \(existingEndpointNode) on destination server\n") }
                                if let destEndpointInfo = destEndpointDict as? [Any] {
                                    let destEndpointCount: Int = destEndpointInfo.count
                                    if self.debug { self.writeToHistory(stringOfText: "[- debug -] existing \(existingEndpointNode) found: \(destEndpointCount) on destination server\n") }
                                    
                                    if destEndpointCount > 0 {
                                        for i in (0..<destEndpointCount) {
                                            let destRecord = destEndpointInfo[i] as! [String : AnyObject]
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
                                                if self.debug { self.writeToHistory(stringOfText: "[- debug -] adding \(destXmlName) (id: \(destXmlID))  to currentEP array.\n") }
                                                self.currentEPs[destXmlName] = destXmlID
                                            } else {
                                                if self.debug { self.writeToHistory(stringOfText: "[- debug -] skipping computer id: \(destXmlID), could not determine its name.\n") }
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
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] returning existing \(existingEndpointNode) endpoints: \(self.currentEPs)\n") }
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
        URLCache.shared.removeAllCachedResponses()
        var serverUrl = "\(server)/JSSResource/\(endPoint)"
        serverUrl = serverUrl.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
        
        var serverCreds = ""
        let serverConf = URLSessionConfiguration.default
        if id == "sourceId" {
            serverCreds = self.sourceBase64Creds
        } else {
            serverCreds = self.destBase64Creds
        }
        
        let semaphore = DispatchSemaphore(value: 1)
        idMapQ.async {
        
            let serverEncodedURL = NSURL(string: serverUrl)
            let serverRequest = NSMutableURLRequest(url: serverEncodedURL! as URL)
            
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
                                    let recordId = record["id"] as? Int
                                    if endPoint == "computerconfigurations" {
                                        self.configInfo(server: "\(server)", endPoint: "computerconfigurations", recordId: recordId!) {
                                            (result: Dictionary<String,Dictionary<String,String>>) in
                                            //                                            print("ordered config IDs: \(result)")
                                        }
                                        
                                    } else {
                                        let recordName = record["name"] as! String
                                        if self.idDict[recordName]?.count == nil {
                                            self.idDict[recordName] = ["sourceId":0, "destId":0]
                                        }
                                        self.idDict[recordName]?[id] = recordId
                                    }

                                }   // for i in (0..<endpointCount) end
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
////            if self.debug { self.writeToHistory(stringOfText: "[- debug -] Current number of \(endpoint) to process: \(self.availableObjsToMigDict.count)\n") }
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
        if self.debug { self.writeToHistory(stringOfText: "[- debug -] Active tab: \(activeTab)\n") }
        return activeTab
    }
    
    func alert_dialog(header: String, message: String) {
        let dialog: NSAlert = NSAlert()
        dialog.messageText = header
        dialog.informativeText = message
        dialog.alertStyle = NSAlertStyle.warning
        dialog.addButton(withTitle: "OK")
        dialog.runModal()
        //return true
    }   // func alert_dialog - end
    
    
    func checkURL2(serverURL: String, completion: @escaping (Bool) -> Void) {
        print("enter checkURL2")
        var available:Bool = false
        if self.debug { self.writeToHistory(stringOfText: "[- debug -] --- checking availability of server: \(serverURL)\n") }
        
        authQ.sync {
            //    var myURL = "\(serverURL)"
            //    if self.debug { self.writeToHistory(stringOfText: "[- debug -] checking: \(myURL)\n") }
            if self.debug { self.writeToHistory(stringOfText: "[- debug -] checking: \(serverURL)\n") }
            
            //                    let encodedURL = NSURL(string: myURL)
            //                    let request = NSMutableURLRequest(url: encodedURL! as URL)
            //                    request.httpMethod = "HEAD"
            guard let encodedURL = URL(string: serverURL) else {
                if self.debug { self.writeToHistory(stringOfText: "[- debug -] --- Cannot cast to URL: \(serverURL)\n") }
                completion(false)
                return
            }
            let configuration = URLSessionConfiguration.default
            var request = URLRequest(url: encodedURL.appendingPathComponent("/JSSResource/accounts"))
            request.httpMethod = "HEAD"
            
            let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
            let task = session.dataTask(with: request as URLRequest, completionHandler: {
                (data, response, error) -> Void in
                if let httpResponse = response as? HTTPURLResponse {
                    if self.debug { self.writeToHistory(stringOfText: "[- debug -] Server check: \(serverURL), httpResponse: \(httpResponse.statusCode)\n") }
                    
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
        var platform = ""
        if macOS_tabViewItem.tabState.rawValue == 0 {
            platform = "macOS"
        } else if iOS_tabViewItem.tabState.rawValue == 0 {
            platform = "iOS"
        } else if general_tabViewItem.tabState.rawValue == 0 {
            platform = "general"
        } else {
            if sectionToMigrate_button.indexOfSelectedItem > 0 {
                platform = "macOS"
            } else if iOSsectionToMigrate_button.indexOfSelectedItem > 0 {
                platform = "iOS"
            } else {
                platform = "general"
            }
        }
        
        return platform
    }
    // which platform mode tab are we on - end
    
    func goButtonEnabled(button_status: Bool) {
        DispatchQueue.main.async {
            self.theSpinnerQ.async {
                var theImageNo = 0
                while !button_status {
                    DispatchQueue.main.async {
                        self.mySpinner_ImageView.image = self.theImage[theImageNo]
                        theImageNo += 1
                        if theImageNo > 11 {
                            theImageNo = 0
                        }
                    }
                    usleep(100000)  // sleep 0.1 seconds
                }
            }
            self.mySpinner_ImageView.isHidden = button_status
            self.stop_button.isHidden = button_status
            self.go_button.isEnabled = button_status
        }
        
        print("button_status: \(button_status)")
        if button_status {
            // display summary of created, updated, and failed objects
            if counters.count > 0 {
                print("\(counters)")
            }
        } else {
            // clear previous results
            counters.removeAll()
        }
    }
    
    @IBAction func stopButton(_ sender: Any) {
        self.writeToHistory(stringOfText: "Migration was manually stopped.\n\n")
        theOpQ.cancelAllOperations()
        theCreateQ.cancelAllOperations()
        goButtonEnabled(button_status: true)
        
    }
    
    func getCurrentTime() -> String {
        let date = NSDate()
        let date_formatter = DateFormatter()
        date_formatter.dateFormat = "YYYYMMdd_HHmmss"
        let stringDate = date_formatter.string(from: date as Date)
        
        return stringDate
    }
    
    func getName(endpoint: String, objectXML: String) -> String {
        var theName: String = ""
        var dropChars: Int = 0
        if let nameTemp = objectXML.range(of: "<name>") {
            let firstPart = String(objectXML.characters.prefix(through: nameTemp.upperBound).dropLast())
            dropChars = firstPart.characters.count
        }
        if let nameTmp = objectXML.range(of: "</name>") {
            let nameTmp2 = String(objectXML.characters.prefix(through: nameTmp.lowerBound))
            theName = String(nameTmp2.characters.dropFirst(dropChars).dropLast())
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
    
    func historyCleanup() {
        var historyArray: [String] = []
        var historyCount: Int = 0
        do {
            let historyFiles = try fm.contentsOfDirectory(atPath: historyPath!)
            
            for historyFile in historyFiles {
                let filePath: String = historyPath! + historyFile
                historyArray.append(filePath)
            }
            //            print(String(historyArray.count) + " files found:\n")
            historyArray.sort()
            historyCount = historyArray.count
            // remove old history files
            if historyCount-1 >= maxHistory {
                for i in (0..<historyCount-maxHistory) {
                    //print(i)
                    NSLog("Deleting: " + historyArray[i])
                    
                    do {
                        try fm.removeItem(atPath: historyArray[i])
                    }
                    catch let error as NSError {
                        print("Ooops! Something went wrong: \(error)")
                    }
                }
            }
        } catch {
            print("no history")
        }
    }   // func historyCleanup - end
    
    func migrationStatus(endpoint: String, count: Int) {
        object_name_field.stringValue = endpoint
        objects_found_field.stringValue = "\(count)"
    }
    
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
    
    func rmXmlData(theXML: String, theTag: String) -> String {
        
        let f_regexComp = try! NSRegularExpression(pattern: "<\(theTag)>(.|\n)*?</\(theTag)>", options:.caseInsensitive)
        let newXML = f_regexComp.stringByReplacingMatches(in: theXML, options: [], range: NSRange(0..<theXML.utf16.count), withTemplate: "")
        
        return newXML
    }
    
    func rmDELETE() {
        var isDir: ObjCBool = false
        if (self.fm.fileExists(atPath: NSHomeDirectory() + "/Library/Application Support/jamf-migrator/DELETE", isDirectory: &isDir)) {
            do {
                try self.fm.removeItem(atPath: NSHomeDirectory() + "/Library/Application Support/jamf-migrator/DELETE")
            }
            catch let error as NSError {
                NSLog("Unable to delete file! Something went wrong: \(error)")
            }
        }
    }
    
    func saveSettings() {
        plistData["source_jp_server"] = source_jp_server_field.stringValue as AnyObject?
        plistData["source_user"] = source_user_field.stringValue as AnyObject?
        plistData["dest_jp_server"] = dest_jp_server_field.stringValue as AnyObject?
        plistData["dest_user"] = dest_user_field.stringValue as AnyObject?
        plistData["maxHistory"] = maxHistory as AnyObject?
        (plistData as NSDictionary).write(toFile: plistPath!, atomically: false)
    }
    
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
        plistData[serverList] = local_serverArray as AnyObject?
        (plistData as NSDictionary).write(toFile: plistPath!, atomically: false)
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
//        print("sender: \(sender.tag)")
        switch sender.tag {
        case 0:
            self.source_jp_server_field.stringValue = sourceServerList_button.titleOfSelectedItem!
        case 1:
            self.dest_jp_server_field.stringValue = destServerList_button.titleOfSelectedItem!
        default: break
        }
    }
    
    func writeToHistory(stringOfText: String) {
        self.historyFileW?.seekToEndOfFile()
        let historyText = (stringOfText as NSString).data(using: String.Encoding.utf8.rawValue)
        self.historyFileW?.write(historyText!)
    }
    
    func mySpinner(spin: Bool) {
        theSpinnerQ.async {
            var theImageNo = 0
            while spin {
                DispatchQueue.main.async {
                    self.mySpinner_ImageView.image = self.theImage[theImageNo]
                    theImageNo += 1
                    if theImageNo > 11 {
                        theImageNo = 0
                    }
                }
                usleep(100000)  // sleep 0.1 seconds
            }
        }
    }
    
    override func viewDidAppear() {
        
        // v1 colors
        //        self.view.layer?.backgroundColor = CGColor(red: 0x11/255.0, green: 0x1E/255.0, blue: 0x3A/255.0, alpha: 1.0)
        // v2 colors
        self.view.layer?.backgroundColor = CGColor(red: 0x5C/255.0, green: 0x78/255.0, blue: 0x94/255.0, alpha: 1.0)
        //[NSColor colorWithCalibratedRed:0x5C/255.0 green:0x78/255.0 blue:0x94/255.0 alpha:0xFF/255.0]/* 5C7894FF */
        let def_plist = Bundle.main.path(forResource: "settings", ofType: "plist")!
        var isDir: ObjCBool = true
        
        // Create Application Support folder for the app if missing - start
        let app_support_path = NSHomeDirectory() + "/Library/Application Support/jamf-migrator"
        if !(fm.fileExists(atPath: app_support_path, isDirectory: &isDir)) {
            let manager = FileManager.default
            do {
                try manager.createDirectory(atPath: app_support_path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                NSLog("Problem creating '/Library/Application Support/jamf-migrator' folder:  \(error)")
            }
        }
        // Create Application Support folder for the app if missing - end
        
        // Create preference file if missing - start
        isDir = true
        if !(fm.fileExists(atPath: NSHomeDirectory() + "/Library/Application Support/jamf-migrator/settings.plist", isDirectory: &isDir)) {
            do {
                try fm.copyItem(atPath: def_plist, toPath: NSHomeDirectory() + "/Library/Application Support/jamf-migrator/settings.plist")
                //migrator.makeKeyAndOrderFront(self)
            }
            catch let error as NSError {
                NSLog("File copy failed! Something went wrong: \(error)")
            }
        }
        // Create preference file if missing - end
        
        // check for file that allows deleting data from destination server, delete if found - start
        self.rmDELETE()
        // check for file that allows deleting data from destination server, delete if found - end
        
        // read environment settings - start
        let plistXML = FileManager.default.contents(atPath: plistPath!)!
        do{
            plistData = try PropertyListSerialization.propertyList(from: plistXML,
                                                                   options: .mutableContainersAndLeaves,
                                                                   format: &format)
                as! [String:AnyObject]
        }
        catch{
            NSLog("Error reading plist: \(error), format: \(format)")
        }
        if plistData["source_jp_server"] != nil {
            source_jp_server = plistData["source_jp_server"] as! String
            source_jp_server_field.stringValue = source_jp_server
        }
        if plistData["source_user"] != nil {
            source_user = plistData["source_user"] as! String
            source_user_field.stringValue = source_user
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
        // read environment settings - end
        
        source_jp_server_field.becomeFirstResponder()
        
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
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        // Sellect all items to be migrated
        // macOS tab
        allNone_button.state = 1
        advcompsearch_button.state = 1
        computers_button.state = 1
        configurations_button.state = 1
        directory_bindings_button.state = 1
        dock_items_button.state = 1
        netboot_button.state = 1
        osxconfigurationprofiles_button.state = 1
        sus_button.state = 1
        fileshares_button.state = 1
        ext_attribs_button.state = 1
        smart_comp_grps_button.state = 1
        static_comp_grps_button.state = 1
        scripts_button.state = 1
        packages_button.state = 1
        printers_button.state = 1
        policies_button.state = 1
        // iOS tab
        allNone_iOS_button.state = 1
        advancedmobiledevicesearches_button.state = 1
        mobiledevicecApps_button.state = 0
        mobiledevices_button.state = 1
        smart_ios_groups_button.state = 1
        static_ios_groups_button.state = 1
        mobiledeviceconfigurationprofiles_button.state = 1
        mobiledeviceextensionattributes_button.state = 1
        // general tab
        allNone_general_button.state = 1
        advusersearch_button.state = 1
        building_button.state = 1
        categories_button.state = 1
        dept_button.state = 1
        userEA_button.state = 1
        sites_button.state = 1
        ldapservers_button.state = 1
        networks_button.state = 1
        users_button.state = 1
        jamfUserAccounts_button.state = 1
        jamfGroupAccounts_button.state = 1
        smartUserGrps_button.state = 1
        staticUserGrps_button.state = 1
        
        source_jp_server_field.becomeFirstResponder()
        go_button.isEnabled = true
        
        NSLog(srcSrvTableView.registeredDraggedTypes.description)
        // for selective migration - end
        
        // read commandline args
        var numberOfArgs = 0
        
        numberOfArgs = CommandLine.arguments.count - 2  // subtract 2 since we start counting at 0, another 1 for the app itself
        if numberOfArgs >= 0 {
            for i in stride(from: 1, through: numberOfArgs+1, by: 1) {
                //print("i: \(i)\t argument: \(CommandLine.arguments[i])")
                switch CommandLine.arguments[i]{
                case "-s":
                    // Add code to save xml to file
                    print("not yet implemented")
                case "-debug":
                    debug = true
                default:
                    print("unknown switch or no argument(s) passed: \(CommandLine.arguments[i])")
                }
            }
        }
        
        historyFile = getCurrentTime() + "_migration.txt"
        isDir = false
        if !(fm.fileExists(atPath: historyPath! + historyFile, isDirectory: &isDir)) {
            _ = try? fm.createDirectory(atPath: historyPath!, withIntermediateDirectories: true, attributes: nil )
        }
        fm.createFile(atPath: historyPath! + historyFile, contents: nil, attributes: nil)
        historyFileW = FileHandle(forUpdatingAtPath: (historyPath! + historyFile))
        sleep(1)
        if debug { writeToHistory(stringOfText: "----- Debug Mode -----\n") }
        
        theModeQ.async {
            var isDir: ObjCBool = false
            var isRed = false
            
            while true {
                if (self.fm.fileExists(atPath: NSHomeDirectory() + "/Library/Application Support/jamf-migrator/DELETE", isDirectory: &isDir)) {
                    DispatchQueue.main.async {
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
                        self.migrateOrRemove_label_field.stringValue = "Migrate"
                        self.migrateOrRemove_label_field.textColor = self.whiteText
                        isRed = false
                    }
                }
                sleep(1)
            }
        }
        
        NSApplication.shared().activate(ignoringOtherApps: true)
    }   //override func viewDidLoad() - end
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    override func viewDidDisappear() {
        // Insert code here to tear down your application
        saveSettings()
        historyCleanup()
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(  URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
    
}

