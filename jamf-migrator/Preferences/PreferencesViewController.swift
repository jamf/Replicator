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

class PreferencesViewController: NSViewController {
    
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
    @IBOutlet weak var saveRawXml_button: NSButton!
    @IBOutlet weak var saveTrimmedXml_button: NSButton!
    @IBOutlet weak var saveOnly_button: NSButton!
    
    let vc = ViewController()
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
    
    var xmlPrefOptions:         Dictionary<String,Bool> = [:]
    
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
    @IBAction func updateExportPrefs_button(_ sender: Any) {
                plistData["xml"] = ["saveRawXml":convertToBool(state: saveRawXml_button.state.rawValue),
                                    "saveTrimmedXml":convertToBool(state: saveTrimmedXml_button.state.rawValue),
                                    "saveOnly":convertToBool(state: saveOnly_button.state.rawValue)]
        vc.savePrefs(prefs: plistData)
    }
    
    func boolToState(TF: Bool) -> NSControl.StateValue {
        let state = (TF) ? 1:0
        return NSControl.StateValue(rawValue: state)
    }
    
    func convertToBool(state: Int) -> Bool {
        let boolValue = (state == 0) ? false:true
        return boolValue
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set view sizes
        self.preferredContentSize = NSMakeSize(self.view.frame.size.width, self.view.frame.size.height)
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = CGColor(red: 0x5C/255.0, green: 0x78/255.0, blue: 0x94/255.0, alpha: 0.4)
        
            }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        // set window title
        self.parent?.view.window?.title = self.title!
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
            xmlPrefOptions  = plistData["xml"] as! Dictionary<String,Bool>
            saveRawXml      = (xmlPrefOptions["saveRawXml"] != nil) ? xmlPrefOptions["saveRawXml"]!:false
            saveTrimmedXml  = (xmlPrefOptions["saveTrimmedXml"] != nil) ? xmlPrefOptions["saveTrimmedXml"]!:false
            saveOnly        = (xmlPrefOptions["saveOnly"] != nil) ? xmlPrefOptions["saveOnly"]!:false
        } else {
            // set default values
            plistData["xml"] = ["saveRawXml":false,
                                "saveTrimmedXml":false,
                                "saveOnly":false] as Any
            vc.saveSettings()
        }
        // read xml settings - end

        if self.title! == "Copy" {
            copyScopeMCP_button.state = boolToState(TF: scopeMcpCopy)
            copyScopeMA_button.state = boolToState(TF: scopeMaCopy)
            copyScopeRS_button.state = boolToState(TF: scopeRsCopy)
            copyScopePolicy_button.state = boolToState(TF: scopePoliciesCopy)
            disablePolicies_button.state = boolToState(TF: policyPoliciesDisable)
            copyScopeOCP_button.state = boolToState(TF: scopeOcpCopy)
            copyScopeIA_button.state = boolToState(TF: scopeIaCopy)
            copyScopeScg_button.state = boolToState(TF: scopeScgCopy)
            copyScopeSig_button.state = boolToState(TF: scopeSigCopy)
            copyScopeUsers_button.state = boolToState(TF: scopeUsersCopy)
        }
        if self.title! == "Export" {
            saveRawXml_button.state = boolToState(TF: saveRawXml)
            saveTrimmedXml_button.state = boolToState(TF: saveTrimmedXml)
            saveOnly_button.state = boolToState(TF: saveOnly)
        }
    }
    
}
