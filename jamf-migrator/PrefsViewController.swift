//
//  PrefsViewController.swift
//  jamf-migrator
//
//  Created by Leslie Helou on 6/1/18.
//  Copyright © 2018 jamf. All rights reserved.
//

import AppKit
import Cocoa
import CoreFoundation

class PrefsViewController: NSViewController {
    
    @IBOutlet var preferences_View: NSView!
    
    @IBOutlet weak var copyScopeMCP_button: NSButton!       // mobile config profiles
    @IBOutlet weak var copyScopePolicy_button: NSButton!    // policies
    @IBOutlet weak var copyScopeOCP_button: NSButton!       // os x config profiles
    @IBOutlet weak var copyScopeRS_button: NSButton!        // restricted software
    @IBOutlet weak var disablePolicies_button: NSButton!    // policies
    @IBOutlet weak var copyScopeScg_button: NSButton!       // smart computer groups
    @IBOutlet weak var copyScopeSig_button: NSButton!       // smart ios groups
    @IBOutlet weak var copyScopeUsers_button: NSButton!     // smart user groups
    @IBOutlet weak var saveRawXml_button: NSButton!
    @IBOutlet weak var saveTrimmedXml_button: NSButton!
    @IBOutlet weak var saveOnly_button: NSButton!
    
    let vc = ViewController()
    var plistData:[String:Any] = [:]  //our server/username data
    
    // default scope preferences
    var scopeOptions:           Dictionary<String,Dictionary<String,Bool>> = [:]
    var scopeMcpCopy:           Bool = true   // mobileconfigurationprofiles copy scope
    var scopePoliciesCopy:      Bool = true   // policies copy scope
    var policyPoliciesDisable:  Bool = false  // policies disable on copy
    var scopeOcpCopy:           Bool = true   // osxconfigurationprofiles copy scope
    var scopeRsCopy:            Bool = true   // restrictedsoftware copy scope
    var scopeScgCopy:           Bool = true // static computer groups copy scope
    var scopeSigCopy:           Bool = true // static iOS device groups copy scope
    var scopeUsersCopy:         Bool = true // static user groups copy scope
    var saveRawXml:             Bool = false
    var saveTrimmedXml:         Bool = false
    var saveOnly:               Bool = false
    
    var xmlPrefOptions:         Dictionary<String,Bool> = [:]
    
    var buttonState = true
    
    @IBOutlet weak var copy_TextField: NSTextField!
    @IBOutlet weak var export_TextField: NSTextField!
    
    
    @IBOutlet weak var preferenceTabs_TabView: NSTabView!
    
    
    @IBAction func showCopyOptions_fn(_ sender: NSButton) {
        setFocus(whichTab: 0)
    }
    @IBAction func showExportOptions_fn(_ sender: NSButton) {
        setFocus(whichTab: 1)
    }
    
    @IBAction func updatePrefs_button(_ sender: Any) {
        plistData["scope"] = ["mobiledeviceconfigurationprofiles":["copy":convertToBool(state: copyScopeMCP_button.state.rawValue)],
                              "policies":["copy":convertToBool(state: copyScopePolicy_button.state.rawValue),"disable":convertToBool(state: disablePolicies_button.state.rawValue)],
                              "osxconfigurationprofiles":["copy":convertToBool(state: copyScopeOCP_button.state.rawValue)],
                              "restrictedsoftware":["copy":convertToBool(state: copyScopeRS_button.state.rawValue)],
                              "scg":["copy":convertToBool(state: copyScopeScg_button.state.rawValue)],
                              "sig":["copy":convertToBool(state: copyScopeSig_button.state.rawValue)],
                              "users":["copy":convertToBool(state: copyScopeUsers_button.state.rawValue)]] as Dictionary<String, Dictionary<String, Any>>
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
    
    func setFocus(whichTab: Int) {
        var opacity:CGFloat?
        opacity = (whichTab == 0) ? 100.0:0.0
        copy_TextField.backgroundColor = NSColor(calibratedRed: 0xE8/255.0, green:0xE8/255.0, blue:0xE8/255.0, alpha: opacity!)
        opacity = (whichTab == 1) ? 100.0:0.0
        export_TextField.backgroundColor = NSColor(calibratedRed: 0xE8/255.0, green:0xE8/255.0, blue:0xE8/255.0, alpha: opacity!)
        preferenceTabs_TabView.selectTabViewItem(at: whichTab)
    }
    
    override func viewDidAppear() {
//        super.viewDidAppear()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        plistData = vc.readSettings()
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
                vc.saveSettings()
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
        
        copyScopeMCP_button.state = boolToState(TF: scopeMcpCopy)
        copyScopePolicy_button.state = boolToState(TF: scopePoliciesCopy)
        disablePolicies_button.state = boolToState(TF: policyPoliciesDisable)
        copyScopeOCP_button.state = boolToState(TF: scopeOcpCopy)
        copyScopeRS_button.state = boolToState(TF: scopeRsCopy)
        copyScopeScg_button.state = boolToState(TF: scopeScgCopy)
        copyScopeSig_button.state = boolToState(TF: scopeSigCopy)
        copyScopeUsers_button.state = boolToState(TF: scopeUsersCopy)
        saveRawXml_button.state = boolToState(TF: saveRawXml)
        saveTrimmedXml_button.state = boolToState(TF: saveTrimmedXml)
        saveOnly_button.state = boolToState(TF: saveOnly)
        
        setFocus(whichTab: 0)
            self.view.wantsLayer = true
            self.view.layer?.backgroundColor = CGColor(red: 0x5C/255.0, green: 0x78/255.0, blue: 0x94/255.0, alpha: 0.4)
        
    }
}
