//
//  PreferencesViewController.swift
//  jamf-migrator
//
//  Created by Leslie Helou on 11/25/18.
//  Copyright © 2018 jamf. All rights reserved.
//

import AppKit
import Cocoa
import CoreFoundation

class PreferencesViewController: NSViewController, NSTextFieldDelegate {
    
    @IBOutlet weak var copyScopeOCP_button: NSButton!       // os x config profiles
    @IBOutlet weak var copyScopeMA_button: NSButton!        // mac applications
    @IBOutlet weak var copyScopeRS_button: NSButton!        // restricted software
    @IBOutlet weak var copyScopePolicy_button: NSButton!    // policies
    @IBOutlet weak var disablePolicies_button: NSButton!    // policies - disable
    @IBOutlet weak var copyScopeMCP_button: NSButton!       // mobile config profiles
    @IBOutlet weak var copyScopeIA_button: NSButton!        // ios applications
    @IBOutlet weak var copyScopeScg_button: NSButton!       // static computer groups
    @IBOutlet weak var copyScopeSig_button: NSButton!       // static ios groups
    @IBOutlet weak var copyScopeUsers_button: NSButton!     // static user groups
    
    // export prefs
    @IBOutlet weak var saveRawXml_button: NSButton!
    @IBOutlet weak var saveTrimmedXml_button: NSButton!
    @IBOutlet weak var saveOnly_button: NSButton!
    @IBOutlet weak var saveRawXmlScope_button: NSButton!
    @IBOutlet weak var saveTrimmedXmlScope_button: NSButton!
    @IBOutlet weak var showSaveLocation_button: NSButton!
    
    
    @IBOutlet var site_View: NSView!
    
    @IBOutlet weak var groupsAction_button: NSPopUpButton!
    @IBOutlet weak var policiesAction_button: NSPopUpButton!
    @IBOutlet weak var profilesAction_button: NSPopUpButton!

    // app prefs
    @IBOutlet weak var concurrentThreads_slider: NSSlider!
    @IBOutlet weak var concurrentThreads_textfield: NSTextField!
    @IBOutlet weak var logFilesCountPref_textfield: NSTextField!

    // computer prefs
    @IBOutlet weak var migrateAsManaged_button: NSButton!
    @IBOutlet weak var prefMgmtAcct_label: NSTextField!
    @IBOutlet weak var prefMgmtAcct_textfield: NSTextField!
    @IBOutlet weak var prefMgmtPwd_label: NSTextField!
    @IBOutlet weak var prefMgmtPwd_textfield: NSSecureTextField!
    @IBOutlet weak var removeCA_ID_button: NSButton!

    // passwords prefs
    @IBOutlet weak var prefBindPwd_button: NSButton!
    @IBOutlet weak var prefLdapPwd_button: NSButton!
    @IBOutlet weak var prefFileSharePwd_button: NSButton!
    @IBOutlet weak var prefBindPwd_textfield: NSSecureTextField!
    @IBOutlet weak var prefLdapPwd_textfield: NSSecureTextField!
    @IBOutlet weak var prefFsRwPwd_textfield: NSSecureTextField!
    @IBOutlet weak var prefFsRoPwd_textfield: NSSecureTextField!

    @IBAction func migrateAsManaged_action(_ sender: Any) {
        if "\(sender as AnyObject)" != "viewDidAppear" {
            userDefaults.set(migrateAsManaged_button.state.rawValue, forKey: "migrateAsManaged")
            userDefaults.synchronize()
        }

        prefMgmtAcct_label.isHidden     = !convertToBool(state: migrateAsManaged_button.state.rawValue)
        prefMgmtAcct_textfield.isHidden = !convertToBool(state: migrateAsManaged_button.state.rawValue)
        prefMgmtPwd_label.isHidden      = !convertToBool(state: migrateAsManaged_button.state.rawValue)
        prefMgmtPwd_textfield.isHidden  = !convertToBool(state: migrateAsManaged_button.state.rawValue)

    }

    @IBAction func removeCA_ID_action(_ sender: Any) {
        if "\(sender as AnyObject)" != "viewDidAppear" {
            userDefaults.set(removeCA_ID_button.state.rawValue, forKey: "removeCA_ID")
            userDefaults.synchronize()
        }
    }

    @IBAction func enableField_action(_ sender: Any) {
        if let buttonName = (sender as? NSButton)?.identifier?.rawValue {
            switch buttonName {
            case "bind":
                userDefaults.set(prefBindPwd_button.state.rawValue, forKey: "prefBindPwd")
            case "ldap":
                userDefaults.set(prefLdapPwd_button.state.rawValue, forKey: "prefLdapPwd")
            case "fileshare":
                userDefaults.set(prefFileSharePwd_button.state.rawValue, forKey: "prefFileSharePwd")
            default:
                break
            }
            userDefaults.synchronize()
        }

        prefBindPwd_textfield.isEnabled = convertToBool(state: prefBindPwd_button.state.rawValue)
        prefLdapPwd_textfield.isEnabled = convertToBool(state: prefLdapPwd_button.state.rawValue)
        prefFsRwPwd_textfield.isEnabled = convertToBool(state: prefFileSharePwd_button.state.rawValue)
        prefFsRoPwd_textfield.isEnabled = convertToBool(state: prefFileSharePwd_button.state.rawValue)
    }

    let Creds2           = Credentials2()
    var credentialsArray = [String]()
    let vc               = ViewController()
    let userDefaults     = UserDefaults.standard
    var plistData:[String:Any] = [:]  //our server/username data
    
    // default scope preferences
    var scopeOptions:           Dictionary<String,Dictionary<String,Bool>> = [:]
    var scopeMcpCopy:           Bool = true   // mobileconfigurationprofiles copy scope
    var scopePoliciesCopy:      Bool = true   // policies copy scope
    var scopeMaCopy:            Bool = true   // macapps copy scope
    var policyPoliciesDisable:  Bool = false  // policies disable on copy
    var scopeOcpCopy:           Bool = true   // osxconfigurationprofiles copy scope
    var scopeRsCopy:            Bool = true   // restrictedsoftware copy scope
    var scopeIaCopy:            Bool = true   // iosapps copy scope
    var scopeScgCopy:           Bool = true   // static computer groups copy scope
    var scopeSigCopy:           Bool = true   // static iOS device groups copy scope
    var scopeUsersCopy:         Bool = true   // static user groups copy scope
    
    var saveRawXml:             Bool = false
    var saveTrimmedXml:         Bool = false
    var saveOnly:               Bool = false
    var saveRawXmlScope:        Bool = true
    var saveTrimmedXmlScope:    Bool = true

    var xmlPrefOptions:         Dictionary<String,Bool> = [:]
    var saveFolderPath: URL? {
        didSet {
            do {
                let bookmark = try saveFolderPath?.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                self.userDefaults.set(bookmark, forKey: "bookmark")
            } catch let error as NSError {
                print("Set Bookmark Fails: \(error.description)")
            }
        }
    }

    @IBAction func concurrentThreads_action(_ sender: Any) {
        concurrentThreads_textfield.stringValue = concurrentThreads_slider.stringValue
        userDefaults.set(Int(concurrentThreads_textfield.stringValue), forKey: "concurrentThreads")
        userDefaults.synchronize()
    }

    @IBAction func siteGroup_action(_ sender: Any) {
        userDefaults.set("\(groupsAction_button.selectedItem!.title)", forKey: "siteGroupsAction")
        userDefaults.synchronize()
    }
    @IBAction func sitePolicy_action(_ sender: Any) {
        userDefaults.set("\(policiesAction_button.selectedItem!.title)", forKey: "sitePoliciesAction")
        userDefaults.synchronize()
    }
    @IBAction func siteProfiles_action(_ sender: Any) {
        userDefaults.set("\(profilesAction_button.selectedItem!.title)", forKey: "siteProfilesAction")
        userDefaults.synchronize()
    }

//    var buttonState = true
    
    @IBAction func updateCopyPrefs_button(_ sender: Any) {
        plistData["scope"] = ["osxconfigurationprofiles":["copy":convertToBool(state: copyScopeOCP_button.state.rawValue)],
                              "macapps":["copy":convertToBool(state: copyScopeMA_button.state.rawValue)],
                              "restrictedsoftware":["copy":convertToBool(state: copyScopeRS_button.state.rawValue)],
                              "policies":["copy":convertToBool(state: copyScopePolicy_button.state.rawValue),"disable":convertToBool(state: disablePolicies_button.state.rawValue)],
                              "mobiledeviceconfigurationprofiles":["copy":convertToBool(state: copyScopeMCP_button.state.rawValue)],
                              "iosapps":["copy":convertToBool(state: copyScopeIA_button.state.rawValue)],
                              "scg":["copy":convertToBool(state: copyScopeScg_button.state.rawValue)],
                              "sig":["copy":convertToBool(state: copyScopeSig_button.state.rawValue)],
                              "users":["copy":convertToBool(state: copyScopeUsers_button.state.rawValue)]] as Dictionary<String, Dictionary<String, Any>>
        vc.savePrefs(prefs: plistData)
    }
    
    @IBAction func updateExportPrefs_button(_ sender: NSButton) {
                plistData["xml"] = ["saveRawXml":convertToBool(state: saveRawXml_button.state.rawValue),
                                    "saveTrimmedXml":convertToBool(state: saveTrimmedXml_button.state.rawValue),
                                    "saveOnly":convertToBool(state: saveOnly_button.state.rawValue),
                                    "saveRawXmlScope":convertToBool(state: saveRawXmlScope_button.state.rawValue),
                                    "saveTrimmedXmlScope":convertToBool(state: saveTrimmedXmlScope_button.state.rawValue)]
        vc.savePrefs(prefs: plistData)

        export.rawXmlScope = convertToBool(state: saveRawXmlScope_button.state.rawValue)
        export.trimmedXmlScope = convertToBool(state: saveTrimmedXmlScope_button.state.rawValue)

    }
    
    func boolToState(TF: Bool) -> NSControl.StateValue {
        let state = (TF) ? 1:0
        return NSControl.StateValue(rawValue: state)
    }
    
    func convertToBool(state: Int) -> Bool {
        let boolValue = (state == 0) ? false:true
        return boolValue
    }
    
    @IBAction func selectExportFolder(_ sender: Any) {
        saveLocation()
    }
    
    
    @IBAction func showExportFolder(_ sender: Any) {
        
        var isDir: ObjCBool = true
        var exportFilePath:String? = self.userDefaults.string(forKey: "saveLocation") ?? (NSHomeDirectory() + "/Downloads/Jamf Migrator/")
//        let exportFilePath:String? = (NSHomeDirectory() + "/Downloads/Jamf Migrator/")
        exportFilePath = exportFilePath?.pathToString
        print("exportFilePath: \(String(describing: exportFilePath!))")
        
        if (FileManager().fileExists(atPath: exportFilePath!, isDirectory: &isDir)) {
//            print("open exportFilePath: \(exportFilePath!)")
//            NSWorkspace.shared.openFile("exportFilePath!")
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: "\(exportFilePath!)")
        } else {
            ViewController().alert_dialog(header: "Alert", message: "There are currently no export files to display.")
        }
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        if let textField = obj.object as? NSTextField {
            switch self.title! {
            case "Computer":
//                if textField.identifier?.rawValue == "prefMgmtAcct" || textField.identifier?.rawValue == "prefMgmtPwd" {
                    if prefMgmtAcct_textfield.stringValue != "" && prefMgmtPwd_textfield.stringValue != "" {
                        userDefaults.set(prefMgmtAcct_textfield.stringValue, forKey: "prefMgmtAcct")
                        Creds2.save(service: "migrator-mgmtAcct", account: prefMgmtAcct_textfield.stringValue, data: prefMgmtPwd_textfield.stringValue)
                    }
//                }
            case "Passwords":
                switch "\(textField.identifier!.rawValue)" {
                case "bind_textfield":
                    if prefBindPwd_textfield.stringValue != "" {
                        Creds2.save(service: "migrator-bind", account: "bind", data: prefBindPwd_textfield.stringValue)
                    }
                case "ldap_textfield":
                    if prefLdapPwd_textfield.stringValue != "" {
                        Creds2.save(service: "migrator-ldap", account: "ldap", data: prefLdapPwd_textfield.stringValue)
                    }
                case "fsrw":
                    if prefFsRwPwd_textfield.stringValue != "" {
                        Creds2.save(service: "migrator-fsrw", account: "FsRw", data: prefFsRwPwd_textfield.stringValue)
                    }
                case "fsro":
                    if prefFsRoPwd_textfield.stringValue != "" {
                        Creds2.save(service: "migrator-fsro", account: "FsRo", data: prefFsRoPwd_textfield.stringValue)
                    }
                default:
                    break
                }
            default:
                break
            }
            userDefaults.synchronize()
        }
    }
    
    func saveLocation() {
        DispatchQueue.main.async {
            let openPanel = NSOpenPanel()
        
            openPanel.canCreateDirectories = true
            openPanel.canChooseDirectories = true
            openPanel.canChooseFiles       = false
            openPanel.allowsMultipleSelection = false
            
            openPanel.begin { (result) in
                if result.rawValue == NSApplication.ModalResponse.OK.rawValue {

                    self.userDefaults.set(openPanel.url!.absoluteString, forKey: "saveLocation")
                    self.userDefaults.synchronize()
                    
                    self.saveFolderPath = openPanel.url
                    
                    self.showSaveLocation_button.toolTip = "\(openPanel.url!.absoluteString.pathToString)"
                    
                }
            } // openPanel.begin - end
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set view sizes
        self.preferredContentSize = NSMakeSize(self.view.frame.size.width, self.view.frame.size.height)
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = CGColor(red: 0x5C/255.0, green: 0x78/255.0, blue: 0x94/255.0, alpha: 0.4)


//        print("[PreferencesViewController] viewDidLoad")
        NSApp.activate(ignoringOtherApps: true)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()

        // set window title
        self.parent?.view.window?.title = self.title!
        
        if self.title! == "Site" {
            if (userDefaults.string(forKey: "siteGroupsAction") == "Copy" || userDefaults.string(forKey: "siteGroupsAction") == "Move")  {
                groupsAction_button.selectItem(withTitle: userDefaults.string(forKey: "siteGroupsAction")!)
            } else {
                userDefaults.set("Copy", forKey: "siteGroupsAction")
            }
            if (userDefaults.string(forKey: "sitePoliciesAction") == "Copy" || userDefaults.string(forKey: "sitePoliciesAction") == "Move") {
                policiesAction_button.selectItem(withTitle: userDefaults.string(forKey: "sitePoliciesAction")!)
            } else {
                userDefaults.set("Copy", forKey: "sitePoliciesAction")
            }
            if (userDefaults.string(forKey: "siteProfilesAction") == "Copy" || userDefaults.string(forKey: "siteProfilesAction") == "Move") {
                profilesAction_button.selectItem(withTitle: userDefaults.string(forKey: "siteProfilesAction")!)
            } else {
                userDefaults.set("Copy", forKey: "siteProfilesAction")
            }
            userDefaults.synchronize()
        }

        if self.title! == "App" {
            concurrentThreads_textfield.stringValue = "\((userDefaults.integer(forKey: "concurrentThreads") < 1) ? 5:userDefaults.integer(forKey: "concurrentThreads"))"
            concurrentThreads_slider.stringValue = concurrentThreads_textfield.stringValue
            logFilesCountPref_textfield.stringValue = "\((userDefaults.integer(forKey: "logFilesCountPref") < 1) ? 20:userDefaults.integer(forKey: "logFilesCountPref"))"
            userDefaults.synchronize()
        }
        
        plistData = vc.readSettings()
        
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
                plistData["scope"] = ["osxconfigurationprofiles":["copy":true],
                                      "macapps":["copy":true],
                                      "policies":["copy":true,"disable":false],
                                      "restrictedsoftware":["copy":true],
                                      "mobiledeviceconfigurationprofiles":["copy":true],
                                      "iosapps":["copy":true],
                                      "scg":["copy":true],
                                      "sig":["copy":true],
                                      "users":["copy":true]] as Any
                vc.saveSettings()
            }
        } else {
            // initilize new settings
            plistData["scope"] = ["osxconfigurationprofiles":["copy":true],
                                  "macapps":["copy":true],
                                  "policies":["copy":true,"disable":false],
                                  "restrictedsoftware":["copy":true],
                                  "mobiledeviceconfigurationprofiles":["copy":true],
                                  "iosapps":["copy":true],
                                  "scg":["copy":true],
                                  "sig":["copy":true],
                                  "users":["copy":true]] as Any
            vc.saveSettings()
        }
        // read xml settings - start
        if plistData["xml"] != nil {
            xmlPrefOptions       = plistData["xml"] as! Dictionary<String,Bool>
            saveRawXml           = (xmlPrefOptions["saveRawXml"] != nil) ? xmlPrefOptions["saveRawXml"]!:false
            saveTrimmedXml       = (xmlPrefOptions["saveTrimmedXml"] != nil) ? xmlPrefOptions["saveTrimmedXml"]!:false
            saveOnly             = (xmlPrefOptions["saveOnly"] != nil) ? xmlPrefOptions["saveOnly"]!:false
            saveRawXmlScope      = (xmlPrefOptions["saveRawXmlScope"] != nil) ? xmlPrefOptions["saveRawXmlScope"]!:true
            saveTrimmedXmlScope  = (xmlPrefOptions["saveTrimmedXmlScope"] != nil) ? xmlPrefOptions["saveTrimmedXmlScope"]!:true
        } else {
            // set default values
            plistData["xml"] = ["saveRawXml":false,
                                "saveTrimmedXml":false,
                                "saveOnly":false,
                                "saveRawXmlScope":true,
                                "saveTrimmedXmlScope":true] as Any
            vc.saveSettings()
        }
        // read xml settings - end

        if self.title! == "Copy" {
            copyScopeMCP_button.state    = boolToState(TF: scopeMcpCopy)
            copyScopeMA_button.state     = boolToState(TF: scopeMaCopy)
            copyScopeRS_button.state     = boolToState(TF: scopeRsCopy)
            copyScopePolicy_button.state = boolToState(TF: scopePoliciesCopy)
            disablePolicies_button.state = boolToState(TF: policyPoliciesDisable)
            copyScopeOCP_button.state    = boolToState(TF: scopeOcpCopy)
            copyScopeIA_button.state     = boolToState(TF: scopeIaCopy)
            copyScopeScg_button.state    = boolToState(TF: scopeScgCopy)
            copyScopeSig_button.state    = boolToState(TF: scopeSigCopy)
            copyScopeUsers_button.state  = boolToState(TF: scopeUsersCopy)
        }
        if self.title! == "Export" {
            saveRawXml_button.state          = boolToState(TF: saveRawXml)
            saveTrimmedXml_button.state      = boolToState(TF: saveTrimmedXml)
            saveOnly_button.state            = boolToState(TF: saveOnly)
            saveRawXmlScope_button.state     = boolToState(TF: saveRawXmlScope)
            saveTrimmedXmlScope_button.state = boolToState(TF: saveTrimmedXmlScope)
            var saveLocation = userDefaults.string(forKey: "saveLocation") ?? (NSHomeDirectory() + "/Downloads/Jamf Migrator/")
            saveLocation = saveLocation.pathToString

            showSaveLocation_button.toolTip = "\(saveLocation)"
        }
        if self.title! == "Computer" {
            credentialsArray.removeAll()
            prefMgmtAcct_textfield.delegate = self
            prefMgmtPwd_textfield.delegate  = self
            migrateAsManaged_button.state   = NSControl.StateValue(rawValue: userDefaults.integer(forKey: "migrateAsManaged"))
            credentialsArray                = Creds2.retrieve(service: "migrator-mgmtAcct")
            removeCA_ID_button.state   = NSControl.StateValue(rawValue: userDefaults.integer(forKey: "removeCA_ID"))

            if credentialsArray.count == 2 {
                prefMgmtAcct_textfield.stringValue = credentialsArray[0]
                prefMgmtPwd_textfield.stringValue  = credentialsArray[1]
            } else {
                prefMgmtAcct_textfield.stringValue = ""
                prefMgmtPwd_textfield.stringValue = ""
            }
            migrateAsManaged_action("viewDidAppear")
        }
        if self.title! == "Passwords" {
            credentialsArray.removeAll()
            prefBindPwd_textfield.delegate = self
            prefLdapPwd_textfield.delegate = self
            prefFsRwPwd_textfield.delegate = self
            prefFsRoPwd_textfield.delegate = self

            prefBindPwd_button.state      = NSControl.StateValue(rawValue: userDefaults.integer(forKey: "prefBindPwd"))
            prefLdapPwd_button.state      = NSControl.StateValue(rawValue: userDefaults.integer(forKey: "prefLdapPwd"))
            prefFileSharePwd_button.state = NSControl.StateValue(rawValue: userDefaults.integer(forKey: "prefFileSharePwd"))

            credentialsArray.removeAll()
            credentialsArray = Creds2.retrieve(service: "migrator-bind")
            if credentialsArray.count == 2 {
                prefBindPwd_textfield.stringValue  = credentialsArray[1]
            } else {
                prefBindPwd_textfield.stringValue = ""
            }
            credentialsArray.removeAll()
            credentialsArray = Creds2.retrieve(service: "migrator-ldap")
            if credentialsArray.count == 2 {
                prefLdapPwd_textfield.stringValue  = credentialsArray[1]
            } else {
                prefLdapPwd_textfield.stringValue = ""
            }
            credentialsArray.removeAll()
            credentialsArray = Creds2.retrieve(service: "migrator-fsrw")
            if credentialsArray.count == 2 {
                prefFsRwPwd_textfield.stringValue  = credentialsArray[1]
            } else {
                prefFsRwPwd_textfield.stringValue = ""
            }
            credentialsArray.removeAll()
            credentialsArray = Creds2.retrieve(service: "migrator-fsro")
            if credentialsArray.count == 2 {
                prefFsRoPwd_textfield.stringValue  = credentialsArray[1]
            } else {
                prefFsRoPwd_textfield.stringValue = ""
            }

            enableField_action("viewDidAppear")

        }
    }

    override func viewDidDisappear() {
        if title! == "App" {
            userDefaults.set(Int(logFilesCountPref_textfield.stringValue), forKey: "logFilesCountPref")
            userDefaults.synchronize()
        }
    }
}
