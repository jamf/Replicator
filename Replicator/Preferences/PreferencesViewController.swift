//
//  PreferencesViewController.swift
//  Replicator
//
//  Created by Leslie Helou on 11/25/18.
//  Copyright 2024 Jamf. All rights reserved.
//

import AppKit
import Cocoa
import CoreFoundation

class PreferencesViewController: NSViewController, NSTextFieldDelegate {
    
//    let userDefaults = UserDefaults.standard
    // copy prefs
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
    
    @IBOutlet weak var onlyCopyMissing_button: NSButton!
    @IBOutlet weak var onlyCopyExisting_button: NSButton!
    
    // export prefs
    @IBOutlet weak var saveRawXml_button: NSButton!
    @IBOutlet weak var saveTrimmedXml_button: NSButton!
    @IBOutlet weak var saveOnly_button: NSButton!
    @IBOutlet weak var saveRawXmlScope_button: NSButton!
    @IBOutlet weak var saveTrimmedXmlScope_button: NSButton!
    @IBOutlet weak var showSaveLocation_button: NSButton!
    @IBOutlet var saveLocation_textfield: NSTextField!
    @IBOutlet weak var select_button: NSButton!
    
    @IBOutlet var site_View: NSView!
    
    @IBOutlet weak var groupsAction_button: NSPopUpButton!
    @IBOutlet weak var policiesAction_button: NSPopUpButton!
    @IBOutlet weak var profilesAction_button: NSPopUpButton!

    // app prefs
    @IBOutlet weak var concurrentThreads_slider: NSSlider!
    @IBOutlet weak var concurrentThreads_textfield: NSTextField!
    @IBOutlet weak var logFilesCountPref_textfield: NSTextField!
    @IBOutlet weak var stickySession_button: NSButton!
    @IBOutlet weak var maskServerNames_button: NSButton!
    @IBOutlet weak var colorScheme_button: NSPopUpButton!
    @IBOutlet weak var sourceDestListSize_button: NSPopUpButton!
    
    // computer prefs
    @IBOutlet weak var migrateAsManaged_button: NSButton!
    @IBOutlet weak var prefMgmtAcct_label: NSTextField!
    @IBOutlet weak var prefMgmtAcct_textfield: NSTextField!
    @IBOutlet weak var prefMgmtPwd_label: NSTextField!
    @IBOutlet weak var prefMgmtPwd_textfield: NSSecureTextField!
    @IBOutlet weak var removeCA_ID_button: NSButton!

    // passwords prefs
    @IBOutlet weak var useLoginKeychain_button: NSButton!
    @IBOutlet weak var prefBindPwd_button: NSButton!
    @IBOutlet weak var prefLdapPwd_button: NSButton!
    @IBOutlet weak var prefFileSharePwd_button: NSButton!
    @IBOutlet weak var prefBindPwd_textfield: NSSecureTextField!
    @IBOutlet weak var prefLdapPwd_textfield: NSSecureTextField!
    @IBOutlet weak var prefFsRwPwd_textfield: NSSecureTextField!
    @IBOutlet weak var prefFsRoPwd_textfield: NSSecureTextField!
    
    
    @IBAction func onlyCopy_action(_ sender: NSButton) {
        let whichButton = sender.identifier?.rawValue
        switch whichButton {
        case "copyMissing":
            if onlyCopyMissing_button.state == .on {
                onlyCopyExisting_button.state = .off
            }
        case "copyExisting":
            if onlyCopyExisting_button.state == .on {
                onlyCopyMissing_button.state = .off
            }
        default:
            break
        }
        userDefaults.set(onlyCopyMissing_button.state.rawValue, forKey: "copyMissing")
        userDefaults.set(onlyCopyExisting_button.state.rawValue, forKey: "copyExisting")
        Setting.onlyCopyMissing  = onlyCopyMissing_button.state.rawValue == 1 ? true:false
        Setting.onlyCopyExisting = onlyCopyExisting_button.state.rawValue == 1 ? true:false
    }
    
    @IBAction func migrateAsManaged_action(_ sender: Any) {
        if "\(sender as AnyObject)" != "viewDidAppear" {
            userDefaults.set(migrateAsManaged_button.state.rawValue, forKey: "migrateAsManaged")
            userDefaults.synchronize()
        }

        prefMgmtAcct_label.isHidden     = !stateToBool(state: migrateAsManaged_button.state.rawValue)
        prefMgmtAcct_textfield.isHidden = !stateToBool(state: migrateAsManaged_button.state.rawValue)
        prefMgmtPwd_label.isHidden      = !stateToBool(state: migrateAsManaged_button.state.rawValue)
        prefMgmtPwd_textfield.isHidden  = !stateToBool(state: migrateAsManaged_button.state.rawValue)

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

        prefBindPwd_textfield.isEnabled = stateToBool(state: prefBindPwd_button.state.rawValue)
        prefLdapPwd_textfield.isEnabled = stateToBool(state: prefLdapPwd_button.state.rawValue)
        prefFsRwPwd_textfield.isEnabled = stateToBool(state: prefFileSharePwd_button.state.rawValue)
        prefFsRoPwd_textfield.isEnabled = stateToBool(state: prefFileSharePwd_button.state.rawValue)
    }
    
//    var credentialsArray = [String]()
    let vc               = ViewController()
//    var plistData:[String:Any] = [:]  //our server/username data
    
    // default scope preferences
    var scope_Options:           Dictionary<String,Dictionary<String,Bool>> = [:]
    var scope_McpCopy:           Bool = true   // mobileconfigurationprofiles copy scope
    var scope_PoliciesCopy:      Bool = true   // policies copy scope
    var scope_MaCopy:            Bool = true   // macapps copy scope
    var policy_PoliciesDisable:  Bool = false  // policies disable on copy
    var scope_OcpCopy:           Bool = true   // osxconfigurationprofiles copy scope
    var scope_RsCopy:            Bool = true   // restrictedsoftware copy scope
    var scope_IaCopy:            Bool = true   // iosapps copy scope
    var scope_ScgCopy:           Bool = true   // static computer groups copy scope
    var scope_SigCopy:           Bool = true   // static iOS device groups copy scope
    var scope_UsersCopy:         Bool = true   // static user groups copy scope
    
    var saveRawXml:             Bool = false
    var saveTrimmedXml:         Bool = false
    var saveOnly:               Bool = false
    var saveRawXmlScope:        Bool = true
    var saveTrimmedXmlScope:    Bool = true

    var xmlPrefOptions:         Dictionary<String,Bool> = [:]
//    var saveFolderURL: URL? {
//        didSet {
//            storeBookmark(theURL: saveFolderURL!)
//        }
//    }

    @IBAction func concurrentThreads_action(_ sender: Any) {
        concurrentThreads_textfield.stringValue = concurrentThreads_slider.stringValue
        userDefaults.set(Int(concurrentThreads_textfield.stringValue), forKey: "concurrentThreads")
        userDefaults.synchronize()
    }
    
    @IBAction func sourceDestListSize_action(_ sender: Any) {
        print("selected size: \(String(describing: sourceDestListSize_button.titleOfSelectedItem))")
        let listSize = Int(sourceDestListSize_button.titleOfSelectedItem!) ?? -1
        print("listSize: \(String(describing: listSize))")
        userDefaults.setValue(listSize, forKey: "sourceDestListSize")
    }
    
    
    @IBAction func stickySession_action(_ sender: NSButton) {
        if sender.state.rawValue == 1 {
            JamfProServer.stickySession = true
        } else {
            JamfProServer.stickySession = false
        }
        userDefaults.set(JamfProServer.stickySession, forKey: "stickySession")
        userDefaults.synchronize()
        NotificationCenter.default.post(name: .stickySessionToggle, object: self)
    }
    
    @IBAction func maskServerNames_action(_ sender: Any) {
        userDefaults.set(Int(maskServerNames_button.state.rawValue), forKey: "maskServerNames")
        if maskServerNames_button.state == .on {
            AppInfo.maskServerNames = true
        } else {
            AppInfo.maskServerNames = false
        }
    }
    @IBAction func colorScheme_action(_ sender: NSButton) {
        let currentScheme = userDefaults.string(forKey: "colorScheme")
        let newScheme     = sender.title
        userDefaults.set(sender.title, forKey: "colorScheme")
//        userDefaults.synchronize()
        if (currentScheme != newScheme)  && newScheme == "default" {
            _ = Alert.shared.display(header: "Attention:", message: "App must be restarted to display default color scheme", secondButton: "")
        }
        NotificationCenter.default.post(name: .setColorScheme_sdvc, object: self)
        NotificationCenter.default.post(name: .setColorScheme_VC, object: self)
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
        AppInfo.settings["scope"] = ["osxconfigurationprofiles":["copy":stateToBool(state: copyScopeOCP_button.state.rawValue)],
                              "macapps":["copy":stateToBool(state: copyScopeMA_button.state.rawValue)],
                              "restrictedsoftware":["copy":stateToBool(state: copyScopeRS_button.state.rawValue)],
                              "policies":["copy":stateToBool(state: copyScopePolicy_button.state.rawValue),"disable":stateToBool(state: disablePolicies_button.state.rawValue)],
                              "mobiledeviceconfigurationprofiles":["copy":stateToBool(state: copyScopeMCP_button.state.rawValue)],
                              "iosapps":["copy":stateToBool(state: copyScopeIA_button.state.rawValue)],
                              "scg":["copy":stateToBool(state: copyScopeScg_button.state.rawValue)],
                              "sig":["copy":stateToBool(state: copyScopeSig_button.state.rawValue)],
                              "users":["copy":stateToBool(state: copyScopeUsers_button.state.rawValue)]] as Dictionary<String, Dictionary<String, Any>>
//        vc.savePrefs(prefs: plistData)
        saveSettings(settings: AppInfo.settings)
    }
    
    
    @objc func exportButtons(_ notification: Notification) {
        viewDidAppear()
    }
    
    @IBAction func updateExportPrefs_button(_ sender: NSButton) {
        
        if saveRawXml_button.state.rawValue == 1 || saveTrimmedXml_button.state.rawValue == 1 {
            saveOnly_button.isEnabled = true
        } else {
            saveOnly_button.isEnabled = false
            saveOnly_button.state     = NSControl.StateValue(rawValue: 0)
            export.saveOnly           = stateToBool(state: saveOnly_button.state.rawValue)
        }
        
        switch sender.identifier!.rawValue {
        case "rawSourceXml":
            export.saveRawXml = stateToBool(state: saveRawXml_button.state.rawValue)
        case "trimmedSourceXml":
            export.saveTrimmedXml = stateToBool(state: saveTrimmedXml_button.state.rawValue)
        case "saveOnly":
            export.saveOnly = stateToBool(state: saveOnly_button.state.rawValue)
        case "rawXmlScope":
            export.rawXmlScope = stateToBool(state: saveRawXmlScope_button.state.rawValue)
        case "trimmedXmlScope":
            export.trimmedXmlScope = stateToBool(state: saveTrimmedXmlScope_button.state.rawValue)
        default:
            break
        }
        
        AppInfo.settings["xml"] = ["saveRawXml":export.saveRawXml,
                            "saveTrimmedXml":export.saveTrimmedXml,
                            "saveOnly":export.saveOnly,
                            "saveRawXmlScope":export.rawXmlScope,
                            "saveTrimmedXmlScope":export.trimmedXmlScope]
        
        saveSettings(settings: AppInfo.settings)
        
        NotificationCenter.default.post(name: .saveOnlyButtonToggle, object: self)
    }
    
    @IBAction func useLoginKeychain_Action(_ sender: NSButton) {
        if sender.state.rawValue == 1 {
            userDefaults.set(true, forKey: "useLoginKeychain")
        } else {
            userDefaults.set(false, forKey: "useLoginKeychain")
        }
    }
    
    func boolToState(TF: Bool) -> NSControl.StateValue {
        let state = (TF) ? 1:0
        return NSControl.StateValue(rawValue: state)
    }
    
    func stateToBool(state: Int) -> Bool {
        let boolValue = (state == 0) ? false:true
        return boolValue
    }
    
    @IBAction func selectExportFolder(_ sender: Any) {
        saveLocation()
    }
    
    
    @IBAction func showExportFolder(_ sender: Any) {
        
        var isDir: ObjCBool = true
        var exportFilePath:String? = userDefaults.string(forKey: "saveLocation") ?? (NSHomeDirectory() + "/Downloads/Replicator/")

        exportFilePath = exportFilePath?.pathToString
        
        if (FileManager().fileExists(atPath: exportFilePath!, isDirectory: &isDir)) {
//            print("open exportFilePath: \(exportFilePath!)")
//            NSWorkspace.shared.openFile("\(exportFilePath!)")
            NSWorkspace.shared.open(URL(fileURLWithPath: exportFilePath!))
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
                        Credentials.shared.save(service: "migrator-mgmtAcct", account: prefMgmtAcct_textfield.stringValue, credential: prefMgmtPwd_textfield.stringValue)
                    }
//                }
            case "Passwords":
                switch "\(textField.identifier!.rawValue)" {
                case "bind_textfield":
                    if prefBindPwd_textfield.stringValue != "" {
                        Credentials.shared.save(service: "migrator-bind", account: "bind", credential: prefBindPwd_textfield.stringValue)
                    }
                case "ldap_textfield":
                    if prefLdapPwd_textfield.stringValue != "" {
                        Credentials.shared.save(service: "migrator-ldap", account: "ldap", credential: prefLdapPwd_textfield.stringValue)
                    }
                case "fsrw":
                    if prefFsRwPwd_textfield.stringValue != "" {
                        Credentials.shared.save(service: "migrator-fsrw", account: "FsRw", credential: prefFsRwPwd_textfield.stringValue)
                    }
                case "fsro":
                    if prefFsRoPwd_textfield.stringValue != "" {
                        Credentials.shared.save(service: "migrator-fsro", account: "FsRo", credential: prefFsRoPwd_textfield.stringValue)
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
        select_button.isEnabled = false
        DispatchQueue.main.async {
            let openPanel = NSOpenPanel()
        
            openPanel.canCreateDirectories = true
            openPanel.canChooseDirectories = true
            openPanel.canChooseFiles       = false
            openPanel.allowsMultipleSelection = false
            
            openPanel.begin { [self] (result) in
                if result.rawValue == NSApplication.ModalResponse.OK.rawValue {

                    userDefaults.set(openPanel.url!.absoluteString.pathToString, forKey: "saveLocation")
                    userDefaults.synchronize()
                    
//                    saveFolderURL = openPanel.url
                    
                    SecurityScopedBookmarks.shared.create(for: openPanel.url!)
//                    storeBookmark(theURL: openPanel.url!)
                    
                    var theTooltip = "\(openPanel.url!.absoluteString.pathToString)"
                    let homePathArray = NSHomeDirectory().split(separator: "/")
                    if homePathArray.count > 1 {
                        theTooltip = theTooltip.replacingOccurrences(of: "/\(homePathArray[0])/\(homePathArray[1])", with: "~")
                    }
                    
                    showSaveLocation_button.toolTip    = "\(theTooltip.replacingOccurrences(of: "/Library/Containers/com.jamf.jamf-migrator/Data", with: ""))"
                    saveLocation_textfield.stringValue = "Export to: \(theTooltip.replacingOccurrences(of: "/Library/Containers/com.jamf.jamf-migrator/Data", with: ""))"
                    
                }
                select_button.isEnabled = true
            } // openPanel.begin - end
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(exportButtons(_:)), name: .exportOff, object: nil)
        
        // Set view sizes
        self.preferredContentSize = NSMakeSize(self.view.frame.size.width, self.view.frame.size.height)
//        self.view.wantsLayer = true
//        self.view.layer?.backgroundColor = CGColor(red: 0x5C/255.0, green: 0x78/255.0, blue: 0x94/255.0, alpha: 0.4)

        NSApp.activate(ignoringOtherApps: true)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        var saveLocationText = ""
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
//            userDefaults.synchronize()
        }

        if self.title! == "App" {
            sourceDestListSize_button.addItem(withTitle: "none")
            for i in stride(from: 5, to: 55, by: 5) {
                sourceDestListSize_button.addItem(withTitle: "\(i)")
            }
            let theSize = (sourceDestListSize < 5) ? "none":"\(sourceDestListSize)"
            sourceDestListSize_button.selectItem(withTitle: theSize)
            
            concurrentThreads_textfield.stringValue = "\((userDefaults.integer(forKey: "concurrentThreads") < 1) ? 2:userDefaults.integer(forKey: "concurrentThreads"))"
            concurrentThreads_slider.stringValue = concurrentThreads_textfield.stringValue
            logFilesCountPref_textfield.stringValue = "\((userDefaults.integer(forKey: "logFilesCountPref") < 1) ? 20:userDefaults.integer(forKey: "logFilesCountPref"))"
            stickySession_button.state = userDefaults.bool(forKey: "stickySession") ? NSControl.StateValue(1):NSControl.StateValue(0)
            
            maskServerNames_button.state = NSControl.StateValue(userDefaults.integer(forKey: "maskServerNames"))
            let currentTitle = userDefaults.string(forKey: "colorScheme")
            colorScheme_button.selectItem(withTitle: currentTitle ?? "default")
        }
        
        _ = readSettings()
//        plistData = vc.readSettings()
        
        if AppInfo.settings["scope"] != nil {
            Scope.options = AppInfo.settings["scope"] as! Dictionary<String,Dictionary<String,Bool>>
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
            if Scope.options["scg"] != nil {
                if Scope.options["scg"]!["copy"] != nil {
                    Scope.scgCopy = Scope.options["scg"]!["copy"]!
                }
                if Scope.options["sig"]!["copy"] != nil {
                    Scope.sigCopy = Scope.options["sig"]!["copy"]!
                }
                if Scope.options["users"]!["copy"] != nil {
                    Scope.usersCopy = Scope.options["users"]!["copy"]!
                }
            } else {
                AppInfo.settings["scope"] = ["osxconfigurationprofiles":["copy":true],
                                      "macapps":["copy":true],
                                      "policies":["copy":true,"disable":false],
                                      "restrictedsoftware":["copy":true],
                                      "mobiledeviceconfigurationprofiles":["copy":true],
                                      "iosapps":["copy":true],
                                      "scg":["copy":true],
                                      "sig":["copy":true],
                                      "users":["copy":true]] as Any
//                vc.saveSettings(settings: plistData)
                saveSettings(settings: AppInfo.settings)
            }
        } else {
            // initilize new settings
            AppInfo.settings["scope"] = ["osxconfigurationprofiles":["copy":true],
                                  "macapps":["copy":true],
                                  "policies":["copy":true,"disable":false],
                                  "restrictedsoftware":["copy":true],
                                  "mobiledeviceconfigurationprofiles":["copy":true],
                                  "iosapps":["copy":true],
                                  "scg":["copy":true],
                                  "sig":["copy":true],
                                  "users":["copy":true]] as Any
//            vc.saveSettings(settings: plistData)
            saveSettings(settings: AppInfo.settings)
        }
        // read xml settings - start
        if AppInfo.settings["xml"] != nil {
            xmlPrefOptions       = AppInfo.settings["xml"] as! [String:Bool]
            saveRawXml           = (xmlPrefOptions["saveRawXml"] != nil) ? xmlPrefOptions["saveRawXml"]!:false
            saveTrimmedXml       = (xmlPrefOptions["saveTrimmedXml"] != nil) ? xmlPrefOptions["saveTrimmedXml"]!:false
            saveOnly             = (xmlPrefOptions["saveOnly"] != nil) ? xmlPrefOptions["saveOnly"]!:false
            saveRawXmlScope      = (xmlPrefOptions["saveRawXmlScope"] != nil) ? xmlPrefOptions["saveRawXmlScope"]!:true
            saveTrimmedXmlScope  = (xmlPrefOptions["saveTrimmedXmlScope"] != nil) ? xmlPrefOptions["saveTrimmedXmlScope"]!:true
        } else {
            // set default values
            AppInfo.settings["xml"] = ["saveRawXml":false,
                                "saveTrimmedXml":false,
                                "saveOnly":false,
                                "saveRawXmlScope":true,
                                "saveTrimmedXmlScope":true] as Any
//            vc.saveSettings(settings: plistData)
            saveSettings(settings: AppInfo.settings)
            
            saveRawXml           = false
            saveTrimmedXml       = false
            saveOnly             = false
            saveRawXmlScope      = true
            saveTrimmedXmlScope  = true
//            userDefaults.set(false, forKey: "saveRawXml")
//            userDefaults.set(false, forKey: "saveTrimmedXml")
//            userDefaults.set(false, forKey: "saveOnly")
//            userDefaults.set(true, forKey: "saveRawXmlScope")
//            userDefaults.set(true, forKey: "saveTrimmedXmlScope")
//            userDefaults.synchronize()
        }
        // read xml settings - end

        if self.title! == "Copy" {
            copyScopeMCP_button.state    = boolToState(TF: Scope.mcpCopy)
            copyScopeMA_button.state     = boolToState(TF: Scope.maCopy)
            copyScopeRS_button.state     = boolToState(TF: Scope.rsCopy)
            copyScopePolicy_button.state = boolToState(TF: Scope.policiesCopy)
            disablePolicies_button.state = boolToState(TF: Scope.policiesDisable)
            copyScopeOCP_button.state    = boolToState(TF: Scope.ocpCopy)
            copyScopeIA_button.state     = boolToState(TF: Scope.iaCopy)
            copyScopeScg_button.state    = boolToState(TF: Scope.scgCopy)
            copyScopeSig_button.state    = boolToState(TF: Scope.sigCopy)
            copyScopeUsers_button.state  = boolToState(TF: Scope.usersCopy)
            
            onlyCopyMissing_button.state = (userDefaults.integer(forKey: "copyMissing") == 1) ? .on:.off
            onlyCopyExisting_button.state = (userDefaults.integer(forKey: "copyExisting") == 1) ? .on:.off
        }
        if self.title! == "Export" {
            var isDir: ObjCBool = true
            saveRawXml_button.state          = boolToState(TF: saveRawXml)
            saveTrimmedXml_button.state      = boolToState(TF: saveTrimmedXml)
            if !saveRawXml && !saveTrimmedXml {
                saveOnly_button.isEnabled    = false
                saveOnly_button.state        = boolToState(TF: false)
            } else {
                saveOnly_button.state        = boolToState(TF: saveOnly)
            }
            saveRawXmlScope_button.state     = boolToState(TF: saveRawXmlScope)
            saveTrimmedXmlScope_button.state = boolToState(TF: saveTrimmedXmlScope)
            
            export.saveLocation = userDefaults.string(forKey: "saveLocation") ?? (NSHomeDirectory() + "/Downloads/Replicator/")
            if !(FileManager().fileExists(atPath: export.saveLocation, isDirectory: &isDir)) {
                userDefaults.set("\(export.saveLocation)", forKey: "saveLocation")
                userDefaults.synchronize()
            }
            
            export.saveLocation = export.saveLocation.pathToString
            
            let homePathArray = NSHomeDirectory().split(separator: "/")
            if homePathArray.count > 1 {
                saveLocationText = export.saveLocation.replacingOccurrences(of: "/\(homePathArray[0])/\(homePathArray[1])", with: "~")
            }
            
            showSaveLocation_button.toolTip    = "\(saveLocationText.replacingOccurrences(of: "/Library/Containers/com.jamf.jamf-migrator/Data", with: ""))"
            saveLocation_textfield.stringValue = "Export to: \(saveLocationText.replacingOccurrences(of: "/Library/Containers/com.jamf.jamf-migrator/Data", with: ""))"
        }
        if self.title! == "Computer" {
            
            prefMgmtAcct_textfield.delegate = self
            prefMgmtPwd_textfield.delegate  = self
            migrateAsManaged_button.state   = NSControl.StateValue(rawValue: userDefaults.integer(forKey: "migrateAsManaged"))
            accountDict                     = Credentials.shared.retrieve(service: "migrator-mgmtAcct", account: "")
            removeCA_ID_button.state        = NSControl.StateValue(rawValue: userDefaults.integer(forKey: "removeCA_ID"))

            if accountDict.count == 1 {
                for (username, password) in accountDict {
                    prefMgmtAcct_textfield.stringValue = username
                    prefMgmtPwd_textfield.stringValue  = password
                }
            } else {
                prefMgmtAcct_textfield.stringValue = ""
                prefMgmtPwd_textfield.stringValue  = ""
            }
            migrateAsManaged_action("viewDidAppear")
        }
        if self.title! == "Passwords" {
            preferredContentSize = CGSize(width: 400, height: 266)
//            preferredContentSize = CGSize(width: 400, height: 306)    // to include login keychain option
            prefBindPwd_textfield.delegate = self
            prefLdapPwd_textfield.delegate = self
            prefFsRwPwd_textfield.delegate = self
            prefFsRoPwd_textfield.delegate = self

            useLoginKeychain_button.state = NSControl.StateValue(rawValue: userDefaults.integer(forKey: "useLoginKeychain"))
            prefBindPwd_button.state      = NSControl.StateValue(rawValue: userDefaults.integer(forKey: "prefBindPwd"))
            prefLdapPwd_button.state      = NSControl.StateValue(rawValue: userDefaults.integer(forKey: "prefLdapPwd"))
            prefFileSharePwd_button.state = NSControl.StateValue(rawValue: userDefaults.integer(forKey: "prefFileSharePwd"))

            
            accountDict = Credentials.shared.retrieve(service: "migrator-bind", account: "")
            if accountDict.count == 1 {
                for (_, password) in accountDict {
                    prefBindPwd_textfield.stringValue  = password
                }
            } else {
                prefBindPwd_textfield.stringValue = ""
            }
            
            accountDict = Credentials.shared.retrieve(service: "migrator-ldap", account: "")
            if accountDict.count == 1 {
                for (_, password) in accountDict {
                    prefLdapPwd_textfield.stringValue = password
                }
            } else {
                prefLdapPwd_textfield.stringValue = ""
            }
            
            accountDict = Credentials.shared.retrieve(service: "migrator-fsrw", account: "")
            if accountDict.count == 1 {
                for (_, password) in accountDict {
                    prefFsRwPwd_textfield.stringValue = password
                }
            } else {
                prefFsRwPwd_textfield.stringValue = ""
            }
            
            accountDict = Credentials.shared.retrieve(service: "migrator-fsro", account: "")
            if accountDict.count == 1 {
                for (_, password) in accountDict {
                    prefFsRoPwd_textfield.stringValue = password
                }
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

extension Notification.Name {
    public static let exportOff = Notification.Name("exportButtons")
}
