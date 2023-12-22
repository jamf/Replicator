//
//  SourceDestVC.swift
//  jamf-migrator
//
//  Created by lnh on 12/9/16.
//  Copyright © 2016 jamf. All rights reserved.
//

import AppKit
import Cocoa
import Foundation

class SourceDestVC: NSViewController, URLSessionDelegate, NSTableViewDelegate, NSTableViewDataSource, NSTextFieldDelegate {
    
//    let userDefaults = UserDefaults.standard
    var importFilesUrl   = URL(string: "")
//    var exportedFilesUrl = URL(string: "")
//    var jamfpro: JamfPro?
    
//    var availableFilesToMigDict = [String:[String]]()   // something like xmlID, xmlName
    var displayNameToFilename   = [String: String]()
        
    // determine if we're using dark mode
    var isDarkMode: Bool {
        let mode = userDefaults.string(forKey: "AppleInterfaceStyle")
        return mode == "Dark"
    }
    
    // keychain access
    let Creds2           = Credentials()
//    var validCreds       = true     // used to deterine if keychain has valid credentials
    var storedSourceUser = ""       // source user account stored in the keychain
    var storedSourcePwd  = ""       // source user account password stored in the keychain
    var storedDestUser   = ""       // destination user account stored in the keychain
    var storedDestPwd    = ""       // destination user account password stored in the keychain
    
    @IBOutlet weak var hideCreds_button: NSButton!
    @IBAction func hideCreds_action(_ sender: Any) {
        hideCreds_button.image = (hideCreds_button.state.rawValue == 0) ? NSImage(named: NSImage.rightFacingTriangleTemplateName):NSImage(named: NSImage.touchBarGoDownTemplateName)
        userDefaults.set("\(hideCreds_button.state.rawValue)", forKey: "hideCreds")
        setWindowSize(setting: hideCreds_button.state.rawValue)
    }
    
    @IBOutlet weak var sourceUsername_TextField: NSTextField!
    @IBOutlet weak var destUsername_TextField: NSTextField!
    @IBOutlet weak var sourcePassword_TextField: NSTextField!
    @IBOutlet weak var destPassword_TextField: NSTextField!
    
    @IBOutlet weak var sourceUseApiClient_button: NSButton!
    @IBOutlet weak var destUseApiClient_button: NSButton!
    @IBAction func useApiClient_action(_ sender: NSButton) {
        switch sender.identifier?.rawValue {
        case "sourceApiClient":
            setLabels(whichServer: "source")
            JamfProServer.sourceUseApiClient = sourceUseApiClient_button.state.rawValue
            userDefaults.set(JamfProServer.sourceUseApiClient, forKey: "sourceApiClient")
            fetchPassword(whichServer: "source", url: source_jp_server_field.stringValue)
        case "destApiClient":
            setLabels(whichServer: "dest")
            JamfProServer.destUseApiClient = destUseApiClient_button.state.rawValue
            userDefaults.set(JamfProServer.destUseApiClient, forKey: "destApiClient")
            fetchPassword(whichServer: "dest", url: dest_jp_server_field.stringValue)
        default:
            break
            
        }
    }
    
    func setWindowSize(setting: Int) {
//        print("setWindowSize - setting: \(setting)")
        var hiddenState = true
        if setting == 0 {
            preferredContentSize = CGSize(width: 848, height: 67)
            hideCreds_button.toolTip = "show username/password fields"
            showHideUserCreds(x: true)
        } else {
            preferredContentSize = CGSize(width: 848, height: 188)
            hideCreds_button.toolTip = "hide username/password fields"
            hiddenState = false
            if fileImport_button.state.rawValue == 0 {
                showHideUserCreds(x: false)
            } else {
                showHideUserCreds(x: true)
            }
        }
        
//        sourceUsername_TextField.isHidden      = hiddenState
//        sourceUser_TextField.isHidden          = hiddenState
//        sourcePassword_TextField.isHidden      = hiddenState
//        source_pwd_field.isHidden              = hiddenState
//        sourceStoreCredentials_button.isHidden = hiddenState
//        sourceUseApiClient_button.isHidden     = hiddenState
        
        destUsername_TextField.isHidden        = hiddenState
        destinationUser_TextField.isHidden     = hiddenState
        destPassword_TextField.isHidden        = hiddenState
        dest_pwd_field.isHidden                = hiddenState
        destStoreCredentials_button.isHidden   = hiddenState
        destUseApiClient_button.isHidden       = hiddenState
    }
    func setLabels(whichServer: String) {
        switch whichServer {
        case "source":
            JamfProServer.sourceUseApiClient = sourceUseApiClient_button.state.rawValue
            if JamfProServer.sourceUseApiClient == 0 {
                sourceUsername_TextField.stringValue = "Username"
                sourcePassword_TextField.stringValue = "Password"
            } else {
                sourceUsername_TextField.stringValue = "Client ID"
                sourcePassword_TextField.stringValue = "Client Secret"
            }
        case "dest":
            JamfProServer.destUseApiClient = destUseApiClient_button.state.rawValue
            if JamfProServer.destUseApiClient == 0 {
                destUsername_TextField.stringValue = "Username"
                destPassword_TextField.stringValue = "Password"
            } else {
                destUsername_TextField.stringValue = "Client ID"
                destPassword_TextField.stringValue = "Client Secret"
            }
        default:
            break
            
        }
    }
    
    @IBOutlet weak var setDestSite_button: NSPopUpButton!
    @IBOutlet weak var sitesSpinner_ProgressIndicator: NSProgressIndicator!
    
    // Import file variables
    @IBOutlet weak var fileImport_button: NSButton!
    @IBOutlet weak var browseFiles_button: NSButton!
    
    @IBOutlet weak var sourceStoreCredentials_button: NSButton!
    @IBOutlet weak var destStoreCredentials_button: NSButton!

    @IBAction func storeCredentials_action(_ sender: NSButton) {
        JamfProServer.storeSourceCreds = sourceStoreCredentials_button.state.rawValue
        JamfProServer.storeDestCreds   = destStoreCredentials_button.state.rawValue
        
        userDefaults.set(JamfProServer.storeSourceCreds, forKey: "storeSourceCreds")
        userDefaults.set(JamfProServer.storeDestCreds, forKey: "storeDestCreds")
    }
     
    @IBOutlet weak var siteMigrate_button: NSButton!
    @IBOutlet weak var availableSites_button: NSPopUpButtonCell!
    @IBOutlet weak var stickySessions_label: NSTextField!
    
    var itemToSite      = false
    var destinationSite = ""
    
    @IBOutlet weak var destinationLabel_TextField: NSTextField!
    
    // Source and destination fields
    @IBOutlet weak var source_jp_server_field: NSTextField!
    @IBOutlet weak var sourceUser_TextField: NSTextField!
    @IBOutlet weak var source_pwd_field: NSSecureTextField!
    @IBOutlet weak var dest_jp_server_field: NSTextField!
    @IBOutlet weak var destinationUser_TextField: NSTextField!
    @IBOutlet weak var dest_pwd_field: NSSecureTextField!
    
    // Source and destination buttons
    @IBOutlet weak var sourceServerList_button: NSPopUpButton!
    @IBOutlet weak var destServerList_button: NSPopUpButton!
    @IBOutlet weak var sourceServerPopup_button: NSPopUpButton!
    @IBOutlet weak var destServerPopup_button: NSPopUpButton!
    @IBOutlet weak var disableExportOnly_button: NSButton!
    
    var isDir: ObjCBool        = false
    var format                 = PropertyListSerialization.PropertyListFormat.xml //format of the property list
    
    var saveRawXmlScope     = true
    var saveTrimmedXmlScope = true
    
    var hideGui             = false
    
//  Log / backup vars
    let backupDate          = DateFormatter()
    var maxLogFileCount     = 20
    var historyFile: String = ""
    var logFile:     String = ""
    let logPath:    String? = (NSHomeDirectory() + "/Library/Logs/jamf-migrator/")
    var logFileW:     FileHandle? = FileHandle(forUpdatingAtPath: "")
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
    var accountsDict = [String:String]()
    
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
    var iconDictArray = [String:[[String:String]]]()
    var uploadedIcons = [String:Int]()
    
    // import file vars
    var fileImport      = false
    var dataFilesRoot   = ""
    
    var endpointDefDict = ["computergroups":"computer_groups", "directorybindings":"directory_bindings", "diskencryptionconfigurations":"disk_encryption_configurations", "dockitems":"dock_items","macapplications":"mac_applications", "mobiledeviceapplications":"mobile_device_application", "mobiledevicegroups":"mobile_device_groups", "packages":"packages", "patches":"patch_management_software_titles", "patchpolicies":"patch_policies", "printers":"printers", "scripts":"scripts", "usergroups":"user_groups", "userextensionattributes":"user_extension_attributes", "advancedusersearches":"advanced_user_searches", "restrictedsoftware":"restricted_software"]
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
    var generalEndpointArray: [String] = ["advancedusersearches", "buildings", "categories", "departments", "jamfusers", "jamfgroups", "ldapservers", "networksegments", "sites", "userextensionattributes", "users", "smartusergroups", "staticusergroups"]
    var macOSEndpointArray: [String] = ["advancedcomputersearches", "macapplications", "smartcomputergroups", "staticcomputergroups", "computers", "osxconfigurationprofiles", "directorybindings", "diskencryptionconfigurations", "dockitems", "computerextensionattributes", "distributionpoints", "packages", "policies", "computer-prestages", "printers", "restrictedsoftware", "scripts", "softwareupdateservers"]
    var iOSEndpointArray: [String] = ["advancedmobiledevicesearches", "mobiledeviceapplications", "mobiledeviceconfigurationprofiles", "smartmobiledevicegroups", "staticmobiledevicegroups", "mobiledevices",  "mobiledeviceextensionattributes", "mobile-device-prestages"]
    var AllEndpointsArray = [String]()
    
    
    var getEndpointInProgress = ""     // end point currently in the GET queue
    var endpointInProgress    = ""     // end point currently in the POST queue
    var endpointName          = ""
    var POSTsuccessCount      = 0
    var failedCount           = 0
    var postCount             = 1
    var counters    = Dictionary<String, Dictionary<String,Int>>()          // summary counters of created, updated, failed, and deleted objects
    var getCounters = [String:[String:Int]]()                               // summary counters of created, updated, failed, and deleted objects
    var putCounters = [String:[String:Int]]()
//    var tmp_counter = Dictionary<String, Dictionary<String,Int>>()        // used to hold value of counter and avoid simultaneous access when updating
    var summaryDict = [String: [String:[String]]]()     // summary arrays of created, updated, and failed objects
    
    // used in createEndpoints
    var totalCreated   = 0
    var totalUpdated   = 0
    var totalFailed    = 0
    var totalCompleted = 0

//    @IBOutlet weak var mySpinner_ImageView: NSImageView!
//    var theImage:[NSImage] = [NSImage(named: "0.png")!,
//                              NSImage(named: "1.png")!,
//                              NSImage(named: "2.png")!]
//    var showSpinner = false
    
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
    
    
    let fm            = FileManager()
    var theOpQ        = OperationQueue() // create operation queue for API calls
    var getEndpointsQ = OperationQueue() // create operation queue for API calls
    var theCreateQ    = OperationQueue() // create operation queue for API POST/PUT calls
    var readFilesQ    = OperationQueue() // for reading in data files
    var readNodesQ    = OperationQueue()   // for reading in API endpoints
    let theIconsQ     = OperationQueue() // que to upload/download icons
    
    let theSortQ      = OperationQueue()
    
    var authQ       = DispatchQueue(label: "com.jamf.auth")
    var theModeQ    = DispatchQueue(label: "com.jamf.addRemove")
    var theSpinnerQ = DispatchQueue(label: "com.jamf.spinner")
    var destEPQ     = DispatchQueue(label: "com.jamf.destEPs", qos: DispatchQoS.background)
    var idMapQ      = DispatchQueue(label: "com.jamf.idMap")
    var sortQ       = DispatchQueue(label: "com.jamf.sortQ", qos: DispatchQoS.default)
//    var iconHoldQ   = DispatchQueue(label: "com.jamf.iconhold")
    
    var concurrentThreads = 2
    
    var migrateOrWipe: String = ""
    var httpStatusCode: Int = 0
    var URLisValid: Bool = true
    
    @objc func deleteMode_sdvc(_ sender: Any) {
        if (self.fm.fileExists(atPath: NSHomeDirectory() + "/Library/Application Support/jamf-migrator/DELETE", isDirectory: &isDir))  {
            DispatchQueue.main.async { [self] in
                // disable source server, username and password fields (to finish)
                if source_jp_server_field.isEnabled {
//                    source_jp_server_field.textColor   = NSColor.white
                    fileImport_button.isEnabled      = false
                    browseFiles_button.isEnabled      = false
                    source_jp_server_field.isEnabled  = false
                    sourceServerList_button.isEnabled = false
                    sourceUser_TextField.isEnabled       = false
                    source_pwd_field.isEnabled        = false
                }
            }
        } else {
            DispatchQueue.main.async { [self] in
                // enable source server, username and password fields (to finish)
                if !source_jp_server_field.isEnabled {
                    fileImport_button.isEnabled       = true
                    browseFiles_button.isEnabled       = true
                    source_jp_server_field.isEnabled   = true
                    sourceServerList_button.isEnabled  = true
                    sourceUser_TextField.isEnabled        = true
                    source_pwd_field.isEnabled         = true
                    JamfProServer.validToken["source"] = false
                    JamfProServer.source               = source_jp_server_field.stringValue
                    JamfProServer.sourceUser           = sourceUser_TextField.stringValue
                    JamfProServer.sourcePwd            = source_pwd_field.stringValue
                }
            }
        }
     }
    
    @IBAction func fileImport_action(_ sender: NSButton) {
        if fileImport_button.state.rawValue == 1 {
            userDefaults.set(true, forKey: "fileImport")
            let toggleFileImport = (sender.title == "Browse") ? false:true
            
            DispatchQueue.main.async { [self] in
                let openPanel = NSOpenPanel()
            
                openPanel.canChooseDirectories = true
                openPanel.canChooseFiles       = false
            
                openPanel.begin { [self] (result) in
                    if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                        importFilesUrl = openPanel.url
                        
                        dataFilesRoot = (importFilesUrl!.path.last == "/") ? importFilesUrl!.path:importFilesUrl!.path + "/"

                        storeBookmark(theURL: importFilesUrl!)
                        
                        source_jp_server_field.stringValue = dataFilesRoot
                        JamfProServer.source               = dataFilesRoot
                        showHideUserCreds(x: true)
                        fileImport                         = true
                        
                        sourceUser_TextField.stringValue      = ""
                        source_pwd_field.stringValue       = ""
                        if LogLevel.debug { WriteToLog().message(stringOfText: "[fileImport] Set source folder to: \(String(describing: dataFilesRoot))\n") }
                        userDefaults.set("\(dataFilesRoot)", forKey: "dataFilesRoot")
                        JamfProServer.importFiles = 1
                        
                        // Note, merge this with xportFilesURL
//                        xportFolderPath = openPanel.url
                        
//                        userDefaults.synchronize()
                        browseFiles_button.isHidden        = false
                        saveSourceDestInfo(info: AppInfo.settings)
                        serverChanged(whichserver: "source")
                    } else {
                        if toggleFileImport {
                            showHideUserCreds(x: false)
                            fileImport                 = false
                            fileImport_button.state    = NSControl.StateValue(rawValue: 0)
                            JamfProServer.importFiles  = 0
                            userDefaults.set(false, forKey: "fileImport")
                        }
                    }
                } // openPanel.begin - end
//                serverOrFiles() {
//                    (result: String) in
//                }
                userDefaults.synchronize()
            }   // DispatchQueue.main.async - end
        } else {    // if fileImport_button.state - end
            userDefaults.set(false, forKey: "fileImport")
            DispatchQueue.main.async { [self] in
                source_jp_server_field.stringValue = ""
                showHideUserCreds(x: false)
//                source_user_field.isHidden  = false
//                source_pwd_field.isHidden   = false
                fileImport                  = false
                fileImport_button.state     = NSControl.StateValue(rawValue: 0)
                browseFiles_button.isHidden = true
                JamfProServer.importFiles   = 0
//                userDefaults.synchronize()
            }
        }
    }   // @IBAction func fileImport - end
    
    @IBAction func migrateToSite_action(_ sender: Any) {
        JamfProServer.toSite   = false
        JamfProServer.destSite = "None"
        if siteMigrate_button.state.rawValue == 1 {
            if dest_jp_server_field.stringValue == "" {
                _ = Alert().display(header: "Attention", message: "Destination URL is required", secondButton: "")
                return
            }
            if self.destinationUser_TextField.stringValue == "" || self.dest_pwd_field.stringValue == "" {
                _ = Alert().display(header: "Attention", message: "Credentials for the destination server are required", secondButton: "")
                return
            }
            
            itemToSite = true
            availableSites_button.removeAllItems()
            
            self.destCreds = "\(self.destinationUser_TextField.stringValue):\(self.dest_pwd_field.stringValue)"
            self.destBase64Creds = self.destCreds.data(using: .utf8)?.base64EncodedString() ?? ""

            DispatchQueue.main.async {
                self.siteMigrate_button.isEnabled = false
                self.sitesSpinner_ProgressIndicator.startAnimation(self)
            }
                    
            JamfPro().getToken(whichServer: "dest", serverUrl: "\(dest_jp_server_field.stringValue)", base64creds: JamfProServer.base64Creds["dest"] ?? "", localSource: false) { [self]
                (authResult: (Int,String)) in
                let (authStatusCode, _) = authResult

                if pref.httpSuccess.contains(authStatusCode) {
                    Sites().fetch(server: "\(dest_jp_server_field.stringValue)", creds: "\(destinationUser_TextField.stringValue):\(dest_pwd_field.stringValue)") { [self]
                        (result: (Int,[String])) in
                        let (httpStatus, destSitesArray) = result
                        if pref.httpSuccess.contains(httpStatus) {
                            if destSitesArray.count == 0 {destinationLabel_TextField.stringValue = "Site"
                                // no sites found - allow migration from a site to none
                                availableSites_button.addItems(withTitles: ["None"])
                            }
                            self.destinationLabel_TextField.stringValue = "Site"
                            self.availableSites_button.addItems(withTitles: ["None"])
                            for theSite in destSitesArray {
                                self.availableSites_button.addItems(withTitles: [theSite])
                            }
                            self.availableSites_button.isEnabled = true
                            JamfProServer.toSite                 = true
                            setDestSite_button.isHidden          = false
                            DispatchQueue.main.async {
                                self.sitesSpinner_ProgressIndicator.stopAnimation(self)
                                self.siteMigrate_button.isEnabled = true
                            }
                        } else {
                            setDestSite_button.isHidden                 = true
                            self.destinationLabel_TextField.stringValue = "Destination"
                            self.availableSites_button.isEnabled = false
                            self.destinationSite = ""
                            itemToSite = false
                            DispatchQueue.main.async {
                                self.sitesSpinner_ProgressIndicator.stopAnimation(self)
                                self.siteMigrate_button.isEnabled = true
                                self.siteMigrate_button.state = NSControl.StateValue(rawValue: 0)
                            }
                        }
                    }
                } else {
                    WriteToLog().message(stringOfText: "[migrateToSite] authenticate was not successful on \(dest_jp_server_field.stringValue)\n")
                    setDestSite_button.isHidden                 = true
                    self.destinationLabel_TextField.stringValue = "Destination"
                    self.availableSites_button.isEnabled = false
                    self.destinationSite = ""
                    itemToSite = false
                    DispatchQueue.main.async {
                        self.sitesSpinner_ProgressIndicator.stopAnimation(self)
                        self.siteMigrate_button.isEnabled = true
                        self.siteMigrate_button.state = NSControl.StateValue(rawValue: 0)
                    }
                }
            }
                
        } else {
            setDestSite_button.isHidden            = true
            destinationLabel_TextField.stringValue = "Destination"
            self.availableSites_button.isEnabled = false
            self.availableSites_button.removeAllItems()
            destinationSite = ""
            itemToSite = false
            DispatchQueue.main.async {
                self.sitesSpinner_ProgressIndicator.stopAnimation(self)
                self.siteMigrate_button.isEnabled = true
            }
        }
        
    }
    
    @IBAction func setDestSite_action(_ sender: Any) {
        JamfProServer.destSite = availableSites_button.selectedItem!.title
    }
    
    func serverChanged(whichserver: String) {
        if (whichserver == "source" && !wipeData.on) || (whichserver == "dest" && !export.saveOnly) {
            // post to notification center
            JamfProServer.whichServer = whichserver
            NotificationCenter.default.post(name: .resetListFields, object: nil)
        }
    }
   
    func fetchPassword(whichServer: String, url: String) {
        if setting.fullGUI {
            fileImport = userDefaults.bool(forKey: "fileImport")
        } else {
            fileImport = (JamfProServer.importFiles == 1) ? true:false
        }
        if !(whichServer == "source" && fileImport) {
            let theUser = (whichServer == "source") ? sourceUser_TextField.stringValue:destinationUser_TextField.stringValue
//            print("[fetchPassword] url: \(url.fqdnFromUrl), account: \(theUser), whichServer: \(whichServer)")
            let accountDict = Creds2.retrieve(service: url.fqdnFromUrl, account: theUser, whichServer: whichServer)
//            print("[fetchPassword] accountDict: \(accountDict)")
            
            
            if accountDict.count > 0 {
                for (username, password) in accountDict {
                    if whichServer == "source" {
                        if username == sourceUser_TextField.stringValue || accountDict.count == 1 {
                            JamfProServer.sourceUser = ""
                            JamfProServer.sourcePwd  = ""
                            if (url != "") {
                                if setting.fullGUI {
                                    sourceUser_TextField.stringValue = username
                                    source_pwd_field.stringValue  = password
                                    self.storedSourceUser         = username
                                    self.storedSourcePwd          = password
                                } else {
                                    source_user = username
                                    source_pass = password
                                }
                                JamfProServer.source     = url
                                JamfProServer.sourceUser = username
                                JamfProServer.sourcePwd  = password
                            }
                            break
                        }   // if username == source_user_field.stringValue
                        source_pwd_field.stringValue  = ""
                        hideCreds_button.state = .on
                        hideCreds_action(self)
                    } else {
                        // destination server
                        if username == destinationUser_TextField.stringValue || accountDict.count == 1 {
                            JamfProServer.destUser   = ""
                            JamfProServer.destPwd    = ""
                            if (url != "") {
                                if setting.fullGUI {
                                    destinationUser_TextField.stringValue = username
                                    dest_pwd_field.stringValue  = password
                                    self.storedDestUser         = username
                                    self.storedDestPwd          = password
                                }
                                dest_user = username
                                dest_pass = password
                                JamfProServer.destination = url
                                JamfProServer.destUser    = username
                                JamfProServer.destPwd     = password
                            } else {
                                if setting.fullGUI {
                                    dest_pwd_field.stringValue = ""
                                    if source_pwd_field.stringValue != "" {
                                        dest_pwd_field.becomeFirstResponder()
                                    }
                                }
                            }
                            break
                        }   // if username == dest_user_field.stringValue
                        dest_pwd_field.stringValue  = ""
                        hideCreds_button.state = .on
                        hideCreds_action(self)
                    }
                }   // for (username, password)
            } else {
                // credentials not found - blank out username / password fields
                if setting.fullGUI {
                    hideCreds_button.state = NSControl.StateValue(rawValue: 1)
                    // NSImage(named: NSImage.rightFacingTriangleTemplateName):NSImage(named: NSImage.touchBarGoDownTemplateName)
                    hideCreds_button.image = (hideCreds_button.state.rawValue == 0) ? NSImage(named: NSImage.rightFacingTriangleTemplateName):NSImage(named: NSImage.touchBarGoDownTemplateName)
                    hideCreds_action(self)
                    if whichServer == "source" {
//                        source_user_field.stringValue = ""
                        source_pwd_field.stringValue = ""
                        self.storedSourceUser = ""
                        sourceUser_TextField.becomeFirstResponder()
                    } else {
//                        dest_user_field.stringValue = ""
                        dest_pwd_field.stringValue = ""
                        self.storedSourceUser = ""
                        destinationUser_TextField.becomeFirstResponder()
                    }
                } else {
                    WriteToLog().message(stringOfText: "Validate URL and/or credentials are saved for both source and destination Jamf Pro instances.")
                    NSApplication.shared.terminate(self)
                }
            }
        } else {
            sourceUser_TextField.stringValue = ""
            source_pwd_field.stringValue = ""
            self.storedSourceUser = ""
        }
    }
    
    func controlTextDidChange(_ obj: Notification) {
        if let textField = obj.object as? NSTextField {
            switch textField.identifier!.rawValue {
            case "sourcePassword":
                JamfProServer.sourcePwd = source_pwd_field.stringValue
            case "destPassword":
                JamfProServer.destPwd = dest_pwd_field.stringValue
            default:
                break
            }
        }
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
//        print("enter controlTextDidEndEditing")
        if let textField = obj.object as? NSTextField {
            switch textField.identifier!.rawValue {
            case "sourceServer", "sourceUser", "sourcePassword":
                if JamfProServer.source != source_jp_server_field.stringValue {
                    serverChanged(whichserver: "source")
                }
                serverOrFiles() { [self]
                    (result: String) in
//                    if textField.identifier!.rawValue == "sourceServer" {
//                        fetchPassword(whichServer: "source", url: source_jp_server_field.stringValue)
//                    }
                    switch textField.identifier!.rawValue {
                    case "sourceServer", "sourceUser":
                        fetchPassword(whichServer: "source", url: source_jp_server_field.stringValue)
                    default:
                        break
                    }
                    
                    JamfProServer.source     = source_jp_server_field.stringValue
                    JamfProServer.sourceUser = sourceUser_TextField.stringValue
                    JamfProServer.sourcePwd  = source_pwd_field.stringValue
                }
            case "destServer", "destUser", "destPassword":
                if JamfProServer.destination != dest_jp_server_field.stringValue {
                    serverChanged(whichserver: "dest")
                }
                switch textField.identifier!.rawValue {
                case "destServer", "destUser":
                    fetchPassword(whichServer: "dest", url: dest_jp_server_field.stringValue)
                default:
                    break
                }
                
                JamfProServer.destination = dest_jp_server_field.stringValue
                JamfProServer.destUser    = destinationUser_TextField.stringValue
                JamfProServer.destPwd     = dest_pwd_field.stringValue
            default:
                break
            }
        }
    }
    
    @IBAction func disableExportOnly_action(_ sender: Any) {
        export.saveOnly       = false
        export.saveRawXml     = false
        export.saveTrimmedXml = false
        AppInfo.settings["xml"] = ["saveRawXml":export.saveRawXml,
                                "saveTrimmedXml":export.saveTrimmedXml,
                                "saveOnly":export.saveOnly,
                                "saveRawXmlScope":export.rawXmlScope,
                                "saveTrimmedXmlScope":export.trimmedXmlScope]
        saveSettings(settings: AppInfo.settings)
        NotificationCenter.default.post(name: .exportOff, object: nil)
        disableSource()
    }
    
    
    func disableSource() {
        if setting.fullGUI {
            DispatchQueue.main.async { [self] in
                dest_jp_server_field.isEnabled      = !export.saveOnly
                destServerList_button.isEnabled     = !export.saveOnly
                destinationUser_TextField.isEnabled           = !export.saveOnly
                dest_pwd_field.isEnabled            = !export.saveOnly
                siteMigrate_button.isEnabled        = !export.saveOnly
                destinationLabel_TextField.isHidden = export.saveOnly
                if export.saveOnly || siteMigrate_button.state.rawValue == 0 {
                    setDestSite_button.isHidden = true
                } else {
                    setDestSite_button.isHidden = false
                }
                disableExportOnly_button.isHidden   = !export.saveOnly
            }
        }
    }
    
    func updateServerArray(url: String, serverList: String, theArray: [String]) {
        if url != "" {
            var local_serverArray = theArray
            let positionInList = local_serverArray.firstIndex(of: url)
            if positionInList == nil {
                    local_serverArray.insert(url, at: 0)
            } else if positionInList! > 0 {
                local_serverArray.remove(at: positionInList!)
                local_serverArray.insert(url, at: 0)
            }
            while local_serverArray.count > sourceDestListSize {
                local_serverArray.removeLast()
            }
            for theServer in local_serverArray {
                if theServer == "" || theServer.first == " " || theServer.last == "\n" {
                    let arrayIndex = local_serverArray.firstIndex(of: theServer)
                    local_serverArray.remove(at: arrayIndex!)
                }
            }
            AppInfo.settings[serverList] = local_serverArray as Any?
            NSDictionary(dictionary: AppInfo.settings).write(toFile: AppInfo.plistPath, atomically: true)
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
        saveSourceDestInfo(info: AppInfo.settings)
    }
    
    func saveSourceDestInfo(info: [String:Any]) {
        AppInfo.settings                       = info

        AppInfo.settings["source_jp_server"]   = source_jp_server_field.stringValue as Any?
        AppInfo.settings["source_user"]        = sourceUser_TextField.stringValue as Any?
        AppInfo.settings["dest_jp_server"]     = dest_jp_server_field.stringValue as Any?
        AppInfo.settings["dest_user"]          = destinationUser_TextField.stringValue as Any?
        AppInfo.settings["storeSourceCreds"]   = JamfProServer.storeSourceCreds as Any?
        AppInfo.settings["storeDestCreds"]     = JamfProServer.storeDestCreds as Any?

        NSDictionary(dictionary: AppInfo.settings).write(toFile: AppInfo.plistPath, atomically: true)
        _ = readSettings()
    }
    
    @IBAction func setServerUrl_button(_ sender: NSPopUpButton) {
        let whichServer = sender.identifier!.rawValue
            if NSEvent.modifierFlags.contains(.option) {
                switch whichServer {
                case "source":
                    let selectedServer =  sourceServerList_button.titleOfSelectedItem!
                    let response = Alert().display(header: "", message: "Are you sure you want to remove \n\(selectedServer) \nfrom the list?", secondButton: "Cancel")
                    if response == "Cancel" {
                        return
                    }
                    sourceServerArray.removeAll(where: { $0 == sourceServerList_button.titleOfSelectedItem! })
                    sourceServerList_button.removeItem(withTitle: sourceServerList_button.titleOfSelectedItem!)
                    if source_jp_server_field.stringValue == selectedServer {
                        source_jp_server_field.stringValue = ""
                        sourceUser_TextField.stringValue   = ""
                        source_pwd_field.stringValue       = ""
                    }
                    AppInfo.settings["source_server_array"] = sourceServerArray as Any?
                case "dest":
                    let selectedServer =  destServerList_button.titleOfSelectedItem!
                    let response = Alert().display(header: "", message: "Are you sure you want to remove \n\(selectedServer) \nfrom the list?", secondButton: "Cancel")
                    if response == "Cancel" {
                        return
                    }
                    destServerArray.removeAll(where: { $0 == destServerList_button.titleOfSelectedItem! })
                    destServerList_button.removeItem(withTitle: destServerList_button.titleOfSelectedItem!)
                    if dest_jp_server_field.stringValue == selectedServer {
                        dest_jp_server_field.stringValue = ""
                        destinationUser_TextField.stringValue      = ""
                        dest_pwd_field.stringValue       = ""
                    }
                    AppInfo.settings["dest_server_array"] = destServerArray as Any?
                default:
                    break
                }
                saveSourceDestInfo(info: AppInfo.settings)
                
                
                return
            }
//        self.selectiveListCleared = false
        switch whichServer {
        case "source":
            if source_jp_server_field.stringValue != sourceServerList_button.titleOfSelectedItem! {
                JamfProServer.validToken["source"] = false
                serverChanged(whichserver: "source")
                if sourceServerArray.firstIndex(of: "\(source_jp_server_field.stringValue)") == nil {
                    updateServerArray(url: "\(source_jp_server_field.stringValue)", serverList: "source_server_array", theArray: sourceServerArray)
                }
            }
            JamfProServer.source = sourceServerList_button.titleOfSelectedItem!
            source_jp_server_field.stringValue = sourceServerList_button.titleOfSelectedItem!
            // see if we're migrating from files or a server
            serverOrFiles() { [self]
                (result: String) in
                saveSourceDestInfo(info: AppInfo.settings)
                fetchPassword(whichServer: "source", url: JamfProServer.source)
            }
        case "dest":
            if (self.dest_jp_server_field.stringValue != destServerList_button.titleOfSelectedItem!) && !export.saveOnly {
                JamfProServer.validToken["dest"] = false
                serverChanged(whichserver: "dest")
                if destServerArray.firstIndex(of: "\(dest_jp_server_field.stringValue)") == nil {
                    updateServerArray(url: "\(dest_jp_server_field.stringValue)", serverList: "dest_server_array", theArray: destServerArray)
                }
            }
            JamfProServer.destination = destServerList_button.titleOfSelectedItem!
            self.dest_jp_server_field.stringValue = destServerList_button.titleOfSelectedItem!
            fetchPassword(whichServer: "dest", url: JamfProServer.destination)
            // reset list of available sites
            if siteMigrate_button.state.rawValue == 1 {
                siteMigrate_button.state = NSControl.StateValue(rawValue: 0)
                availableSites_button.isEnabled = false
                availableSites_button.removeAllItems()
                destinationLabel_TextField.stringValue = "Destination"
                destinationSite = ""
                itemToSite = false
            }
        default: break
        }
    }
    
    func serverOrFiles(completion: @escaping (_ sourceType: String) -> Void) {
        // see if we last migrated from files or a server
        var sourceType = ""
        
//        DispatchQueue.main.async { [self] in
        if source_jp_server_field.stringValue != "" {
            if source_jp_server_field.stringValue.prefix(4).lowercased() == "http" {
//                print("source: server.")
                fileImport_button.state     = NSControl.StateValue(rawValue: 0)
                browseFiles_button.isHidden = true
                showHideUserCreds(x: false)
//                source_user_field.isHidden  = false
//                source_pwd_field.isHidden   = false
                fileImport                  = false
                sourceType                  = "server"
            } else {
//                print("source: local files")
                fileImport_button.state     = NSControl.StateValue(rawValue: 1)
                browseFiles_button.isHidden = false
                dataFilesRoot               = source_jp_server_field.stringValue
                JamfProServer.source        = source_jp_server_field.stringValue
                importFilesUrl            = URL(string: "file://\(dataFilesRoot.replacingOccurrences(of: " ", with: "%20"))")
                showHideUserCreds(x: true)
                fileImport                  = true
                sourceType                  = "files"
                
//                getAccess(theURL: importFilesUrl!)
                

            }
            JamfProServer.importFiles = fileImport_button.state.rawValue
        }
//        }
        userDefaults.set(fileImport, forKey: "fileImport")
        userDefaults.synchronize()
        completion(sourceType)
    }   // func serverOrFiles() - end
    
    func showHideUserCreds(x: Bool) {
        let hideState = hideCreds_button.state == .on ? x:true
        sourceUsername_TextField.isHidden      = hideState
        sourcePassword_TextField.isHidden      = hideState
        sourceUser_TextField.isHidden          = hideState
        source_pwd_field.isHidden              = hideState
        sourceStoreCredentials_button.isHidden = hideState
        sourceUseApiClient_button.isHidden     = hideState
    }
    
    override func viewDidAppear() {
        // set tab order
        // Use interface builder, right click a field and drag nextKeyView to the next
        source_jp_server_field.nextKeyView  = sourceUser_TextField
        sourceUser_TextField.nextKeyView       = source_pwd_field
        source_pwd_field.nextKeyView        = dest_jp_server_field
        dest_jp_server_field.nextKeyView    = destinationUser_TextField
        destinationUser_TextField.nextKeyView         = dest_pwd_field
        
    }   //viewDidAppear - end
    
    @objc func stickySessionToggle(_ notification: Notification) {
        stickySessions_label.isHidden = !JamfProServer.stickySession
    }
    @objc func toggleExportOnly(_ notification: Notification) {
        disableSource()
    }
    @objc func updateSourceServerList(_ notification: Notification) {
        updateServerArray(url: JamfProServer.source, serverList: "source_server_array", theArray: self.sourceServerArray)
    }
    @objc func updateDestServerList(_ notification: Notification) {
        updateServerArray(url: JamfProServer.destination, serverList: "dest_server_array", theArray: self.destServerArray)
    }
    @objc func setColorScheme_sdvc(_ notification: Notification) {
        let whichColorScheme = userDefaults.string(forKey: "colorScheme") ?? ""
        if appColor.schemes.firstIndex(of: whichColorScheme) != nil {
            self.view.wantsLayer = true
            source_jp_server_field.drawsBackground = true
            source_jp_server_field.backgroundColor = appColor.highlight[whichColorScheme]
            sourceUser_TextField.drawsBackground = true
            sourceUser_TextField.backgroundColor = appColor.highlight[whichColorScheme]
            source_pwd_field.drawsBackground = true
            source_pwd_field.backgroundColor = appColor.highlight[whichColorScheme]
            dest_jp_server_field.drawsBackground = true
            dest_jp_server_field.backgroundColor = appColor.highlight[whichColorScheme]
            dest_pwd_field.backgroundColor   = appColor.highlight[whichColorScheme]
            destinationUser_TextField.drawsBackground  = true
            destinationUser_TextField.backgroundColor  = appColor.highlight[whichColorScheme]
            dest_pwd_field.drawsBackground   = true
            self.view.layer?.backgroundColor = appColor.background[whichColorScheme]
        }
    }
    
    
//    var jamfpro: JamfPro?
    override func viewDidLoad() {
        super.viewDidLoad()
//        hardSetLdapId = false

//        debug = true
        
        print("test defaults: \(userDefaults.integer(forKey: "sourceDestListSize"))")
        
        // Do any additional setup after loading the view
        if !FileManager.default.fileExists(atPath: AppInfo.bookmarksPath) {
            FileManager.default.createFile(atPath: AppInfo.bookmarksPath, contents: nil)
        }
        ViewController().rmDELETE()
        
        NotificationCenter.default.addObserver(self, selector: #selector(setColorScheme_sdvc(_:)), name: .setColorScheme_sdvc, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deleteMode_sdvc(_:)), name: .deleteMode_sdvc, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(toggleExportOnly(_:)), name: .saveOnlyButtonToggle, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(stickySessionToggle(_:)), name: .stickySessionToggle, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateSourceServerList(_:)), name: .updateSourceServerList, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateDestServerList(_:)), name: .updateDestServerList, object: nil)
        
        NotificationCenter.default.post(name: .setColorScheme_sdvc, object: self)
        
        source_jp_server_field.delegate = self
        sourceUser_TextField.delegate      = self
        source_pwd_field.delegate       = self
        dest_jp_server_field.delegate   = self
        destinationUser_TextField.delegate        = self
        dest_pwd_field.delegate         = self
        
//        jamfpro = JamfPro(sdController: self)
        fileImport = userDefaults.bool(forKey: "fileImport")
        JamfProServer.stickySession = userDefaults.bool(forKey: "stickySession")
        stickySessions_label.isHidden = !JamfProServer.stickySession
    
        initVars()
        
        if !hideGui {
            hideCreds_button.state = NSControl.StateValue(rawValue: userDefaults.integer(forKey: "hideCreds"))
            hideCreds_button.image = (hideCreds_button.state.rawValue == 0) ? NSImage(named: NSImage.rightFacingTriangleTemplateName):NSImage(named: NSImage.touchBarGoDownTemplateName)
//            print("viewDidLoad - hideCreds_button.state.rawValue: \(hideCreds_button.state.rawValue)")
            setWindowSize(setting: hideCreds_button.state.rawValue)
//            source_jp_server_field.becomeFirstResponder()
        }
        
    }   //override func viewDidLoad() - end
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    override func viewDidDisappear() {
        // Insert code here to tear down your application
//        saveSettings()
//        logCleanup()
    }
    
    func initVars() {
        // create log directory if missing - start
        if !fm.fileExists(atPath: logPath!) {
            do {
                try fm.createDirectory(atPath: logPath!, withIntermediateDirectories: true, attributes: nil )
            } catch {
                _ = Alert().display(header: "Error:", message: "Unable to create log directory:\n\(String(describing: logPath))\nTry creating it manually.", secondButton: "")
                exit(0)
            }
        }
        // create log directory if missing - end
        
        maxLogFileCount = (userDefaults.integer(forKey: "logFilesCountPref") < 1) ? 20:userDefaults.integer(forKey: "logFilesCountPref")
        logFile = TimeDelegate().getCurrent().replacingOccurrences(of: ":", with: "") + "_migration.log"
        History.logFile = TimeDelegate().getCurrent().replacingOccurrences(of: ":", with: "") + "_migration.log"

        isDir = false
        if !(fm.fileExists(atPath: logPath! + logFile, isDirectory: &isDir)) {
            fm.createFile(atPath: logPath! + logFile, contents: nil, attributes: nil)
        }
        sleep(1)
        
        if !(fm.fileExists(atPath: userDefaults.string(forKey: "saveLocation") ?? ":missing:", isDirectory: &isDir)) {
            userDefaults.setValue(NSHomeDirectory() + "/Downloads/Jamf Migrator/", forKey: "saveLocation")
            userDefaults.synchronize()
        }
        
        let saved_sourceDestListSize = userDefaults.integer(forKey: "sourceDestListSize")
        sourceDestListSize = (saved_sourceDestListSize == 0) ? 20:saved_sourceDestListSize
        
        if setting.fullGUI {
            if !FileManager.default.fileExists(atPath: AppInfo.plistPath) {
                do {
                    if !FileManager.default.fileExists(atPath: AppInfo.plistPath.replacingOccurrences(of: "settings.plist", with: "")) {
                        // create directory
                        try FileManager.default.createDirectory(atPath: AppInfo.plistPath.replacingOccurrences(of: "settings.plist", with: ""), withIntermediateDirectories: true, attributes: nil)
                    }
                    try FileManager.default.copyItem(atPath: Bundle.main.path(forResource: "settings", ofType: "plist")!, toPath: AppInfo.plistPath)
                    WriteToLog().message(stringOfText: "[SourceDestVC] Created default setting from  \(Bundle.main.path(forResource: "settings", ofType: "plist")!)\n")
                } catch {
                    WriteToLog().message(stringOfText: "[SourceDestVC] Unable to find/create \(AppInfo.plistPath)\n")
                    WriteToLog().message(stringOfText: "[SourceDestVC] Try to manually copy the file from \(Bundle.main.path(forResource: "settings", ofType: "plist")!) to \(AppInfo.plistPath)\n")
                    NSApplication.shared.terminate(self)
                }
            }
            
            // read environment settings from plist - start
//            plistData -> appInfo.settings
            _ = readSettings()

            if AppInfo.settings["source_jp_server"] as? String != nil {
                source_jp_server = AppInfo.settings["source_jp_server"] as! String
                JamfProServer.source = source_jp_server
                
//                if setting.fullGUI {
                    source_jp_server_field.stringValue = source_jp_server
                    if source_jp_server.count > 0 {
                        self.browseFiles_button.isHidden = (source_jp_server.first! == "/") ? false:true
                    }
//                }
            } else {
//                if setting.fullGUI {
                    self.browseFiles_button.isHidden = true
//                }
            }
            
            if AppInfo.settings["source_user"] != nil {
                source_user = AppInfo.settings["source_user"] as! String
//                if setting.fullGUI {
                    sourceUser_TextField.stringValue = source_user
//                }
                storedSourceUser = source_user
            }
            
            if AppInfo.settings["dest_jp_server"] != nil {
                dest_jp_server = AppInfo.settings["dest_jp_server"] as! String
                dest_jp_server_field.stringValue = dest_jp_server
                JamfProServer.destination = dest_jp_server
            }
            
            if AppInfo.settings["dest_user"] != nil {
                dest_user = AppInfo.settings["dest_user"] as! String
//                if setting.fullGUI {
                    destinationUser_TextField.stringValue = dest_user
//                }
            }
            
//            if setting.fullGUI {
                if AppInfo.settings["source_server_array"] != nil {
                    sourceServerArray = AppInfo.settings["source_server_array"] as! [String]
                    for theServer in sourceServerArray {
                        self.sourceServerList_button.addItems(withTitles: [theServer])
                    }
                }
                if AppInfo.settings["dest_server_array"] != nil {
                    destServerArray = AppInfo.settings["dest_server_array"] as! [String]
                    for theServer in destServerArray {
                        self.destServerList_button.addItems(withTitles: [theServer])
                    }
                }
            
            JamfProServer.storeSourceCreds = userDefaults.integer(forKey: "storeSourceCreds")
            sourceStoreCredentials_button.state = NSControl.StateValue(rawValue: JamfProServer.storeSourceCreds)
    
            JamfProServer.storeDestCreds = userDefaults.integer(forKey: "storeDestCreds")
            destStoreCredentials_button.state = NSControl.StateValue(rawValue: JamfProServer.storeDestCreds)
            
            
            JamfProServer.sourceUseApiClient = userDefaults.integer(forKey: "sourceApiClient")
            sourceUseApiClient_button.state = NSControl.StateValue(rawValue: JamfProServer.sourceUseApiClient)
            setLabels(whichServer: "source")

            JamfProServer.destUseApiClient = userDefaults.integer(forKey: "destApiClient")
            destUseApiClient_button.state = NSControl.StateValue(rawValue: JamfProServer.destUseApiClient)
            setLabels(whichServer: "dest")
            
            // read xml settings - start
            if AppInfo.settings["xml"] != nil {
                xmlPrefOptions       = AppInfo.settings["xml"] as! Dictionary<String,Bool>

                if (xmlPrefOptions["saveRawXml"] != nil) {
                    export.saveRawXml = xmlPrefOptions["saveRawXml"]!
                } else {
                    export.saveRawXml = false
                    xmlPrefOptions["saveRawXml"] = export.saveRawXml
                }
                
                if (xmlPrefOptions["saveTrimmedXml"] != nil) {
                    export.saveTrimmedXml = xmlPrefOptions["saveTrimmedXml"]!
                } else {
                    export.saveTrimmedXml = false
                    xmlPrefOptions["saveTrimmedXml"] = export.saveTrimmedXml
                }

                if (xmlPrefOptions["saveOnly"] != nil) {
                    export.saveOnly = xmlPrefOptions["saveOnly"]!
                } else {
                    export.saveOnly = false
                    xmlPrefOptions["saveOnly"] = export.saveOnly
                }
                disableSource()
                
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
            
            serverOrFiles() { [self]
                (result: String) in
                hideCreds_button.state = NSControl.StateValue(rawValue: userDefaults.integer(forKey: "hideCreds"))
                hideCreds_button.image = (hideCreds_button.state.rawValue == 0) ? NSImage(named: NSImage.rightFacingTriangleTemplateName):NSImage(named: NSImage.touchBarGoDownTemplateName)
                source_jp_server_field.becomeFirstResponder()
            }
//            print("initVars - hideCreds_button.state.rawValue: \(hideCreds_button.state.rawValue)")
//            print("fileImport: \(fileImport)")
//            print("source: \(theSource)")
//            setWindowSize(setting: hideCreds_button.state.rawValue)
            
        } else {
//            didRun = true
            source_jp_server = JamfProServer.source
            dest_jp_server   = JamfProServer.destination
        }   // if setting.fullGUI (else) - end

        // check for stored passwords - start
        if (JamfProServer.source != "") && JamfProServer.importFiles == 0 {
            fetchPassword(whichServer: "source", url: JamfProServer.source)
        }
        if (JamfProServer.destination != "") {
            fetchPassword(whichServer: "dest", url: JamfProServer.destination)
        }
//        if (storedSourcePwd == "") || (storedDestPwd == "") {
//            self.validCreds = false
//        }
        // check for stored passwords - end
        
        if !setting.fullGUI {
            ViewController().initVars()
        }
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(  URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
}

extension Notification.Name {
    public static let setColorScheme_sdvc    = Notification.Name("setColorScheme_sdvc")
    public static let deleteMode_sdvc        = Notification.Name("deleteMode_sdvc")
    public static let saveOnlyButtonToggle   = Notification.Name("toggleExportOnly")
    public static let stickySessionToggle    = Notification.Name("stickySessionToggle")
    public static let updateSourceServerList = Notification.Name("updateSourceServerList")
    public static let updateDestServerList   = Notification.Name("updateDestServerList")
}
