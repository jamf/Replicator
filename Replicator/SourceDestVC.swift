//
//  SourceDestVC.swift
//  Replicator
//
//  Created by lnh on 12/9/16.
//  Copyright 2024 Jamf. All rights reserved.
//

import AppKit
import Cocoa
import Foundation

class SourceDestVC: NSViewController, URLSessionDelegate, NSTableViewDelegate, NSTableViewDataSource, NSTextFieldDelegate {
    
    let lastUserManager = LastUserManager()
    
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
//    let Creds2           = Credentials()
//    var validCreds       = true     // used to deterine if keychain has valid credentials
    var storedSourceUser = ""       // source user account stored in the keychain
    var storedSourcePwd  = ""       // source user account password stored in the keychain
    var storedDestUser   = ""       // destination user account stored in the keychain
    var storedDestPwd    = ""       // destination user account password stored in the keychain
    
    @IBOutlet weak var hideCreds_button: NSButton!
    @IBAction func hideCreds_action(_ sender: Any) {
        logFunctionCall()
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
        logFunctionCall()
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
        logFunctionCall()
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
        logFunctionCall()
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
        logFunctionCall()
        JamfProServer.storeSourceCreds = sourceStoreCredentials_button.state.rawValue
        JamfProServer.storeDestCreds   = destStoreCredentials_button.state.rawValue
        
        userDefaults.set(JamfProServer.storeSourceCreds, forKey: "storeSourceCreds")
        userDefaults.set(JamfProServer.storeDestCreds, forKey: "storeDestCreds")
    }
     
    @IBOutlet weak var siteMigrate_button: NSButton!
    @IBOutlet weak var availableSites_button: NSPopUpButtonCell!
    @IBOutlet weak var stickySessions_label: NSTextField!
    
    var itemToSite      = false
    
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
    var maxLogFileCount     = 20
    var historyFile: String = ""
    var logFile:     String = ""
    let logPathOld: String? = (NSHomeDirectory() + "/Library/Logs/jamf-migrator/")
//    let logPath:    String? = (NSHomeDirectory() + "/Library/Logs/Replicator/")
    
    // xml prefs
    var xmlPrefOptions: Dictionary<String,Bool> = [:]
    
    var sourceServerArray   = [String]()
    var destServerArray     = [String]()
    
    // credentials
    var sourceCreds = ""
    var destCreds   = ""
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
        
    // import file vars
    var dataFilesRoot   = ""
        
    var sortQ       = DispatchQueue(label: "com.jamf.sortQ", qos: DispatchQoS.default)
//    var iconHoldQ   = DispatchQueue(label: "com.jamf.iconhold")
    
    var concurrentThreads = 2
    
    var migrateOrWipe: String = ""
    var httpStatusCode: Int = 0
    var URLisValid: Bool = true
    
    @objc func deleteMode_sdvc(_ sender: Any) {
        logFunctionCall()
        if (fm.fileExists(atPath: NSHomeDirectory() + "/Library/Application Support/Replicator/DELETE", isDirectory: &isDir))  {
            DispatchQueue.main.async { [self] in
                // disable source server, username and password fields (to finish)
                if source_jp_server_field.isEnabled {
//                    source_jp_server_field.textColor   = NSColor.white
                    fileImport_button.isEnabled       = false
                    browseFiles_button.isEnabled      = false
                    source_jp_server_field.isEnabled  = false
                    sourceServerList_button.isEnabled = false
                    sourceUser_TextField.isEnabled    = false
                    source_pwd_field.isEnabled        = false
                }
            }
        } else {
            DispatchQueue.main.async { [self] in
                // enable source server, username and password fields (to finish)
                if !source_jp_server_field.isEnabled {
                    fileImport_button.isEnabled        = true
                    browseFiles_button.isEnabled       = true
                    source_jp_server_field.isEnabled   = true
                    sourceServerList_button.isEnabled  = true
                    sourceUser_TextField.isEnabled     = true
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
        logFunctionCall()
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
                        
                        SecurityScopedBookmarks.shared.create(for: importFilesUrl!)
//                        storeBookmark(theURL: importFilesUrl!)
                        
                        source_jp_server_field.stringValue = dataFilesRoot
                        JamfProServer.source               = dataFilesRoot
                        showHideUserCreds(x: true)
                        fileImport                         = true
                        
                        sourceUser_TextField.stringValue      = ""
                        source_pwd_field.stringValue       = ""
                        if LogLevel.debug { WriteToLog.shared.message("[fileImport] Set source folder to: \(String(describing: dataFilesRoot))") }
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
//                userDefaults.synchronize()
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
        logFunctionCall()
        JamfProServer.toSite   = false
        JamfProServer.destSite = "None"
        if siteMigrate_button.state == .on {
            if dest_jp_server_field.stringValue == "" {
                _ = Alert.shared.display(header: "Attention", message: "Destination URL is required", secondButton: "")
                return
            }
            if self.destinationUser_TextField.stringValue == "" || self.dest_pwd_field.stringValue == "" {
                _ = Alert.shared.display(header: "Attention", message: "Credentials for the destination server are required", secondButton: "")
                return
            }
            
            itemToSite = true
            availableSites_button.removeAllItems()
            
            self.destCreds = "\(self.destinationUser_TextField.stringValue):\(self.dest_pwd_field.stringValue)"
            self.destBase64Creds = self.destCreds.data(using: .utf8)?.base64EncodedString() ?? ""
            JamfProServer.base64Creds["dest"] = self.destCreds.data(using: .utf8)?.base64EncodedString() ?? ""

            DispatchQueue.main.async {
                self.siteMigrate_button.isEnabled = false
                self.sitesSpinner_ProgressIndicator.startAnimation(self)
            }
                    
            JamfPro.shared.getToken(whichServer: "dest", serverUrl: "\(dest_jp_server_field.stringValue)", base64creds: JamfProServer.base64Creds["dest"] ?? "", localSource: false, renew: false) { [self]
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
                            itemToSite = false
                            DispatchQueue.main.async {
                                self.sitesSpinner_ProgressIndicator.stopAnimation(self)
                                self.siteMigrate_button.isEnabled = true
                                self.siteMigrate_button.state = NSControl.StateValue(rawValue: 0)
                            }
                        }
                    }
                } else {
                    WriteToLog.shared.message("[migrateToSite] authenticate was not successful on \(dest_jp_server_field.stringValue)")
                    setDestSite_button.isHidden                 = true
                    self.destinationLabel_TextField.stringValue = "Destination"
                    self.availableSites_button.isEnabled = false
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
            itemToSite = false
            DispatchQueue.main.async {
                self.sitesSpinner_ProgressIndicator.stopAnimation(self)
                self.siteMigrate_button.isEnabled = true
            }
        }
        
    }
    
    @IBAction func setDestSite_action(_ sender: Any) {
        logFunctionCall()
        JamfProServer.destSite = availableSites_button.selectedItem!.title
    }
    
    func serverChanged(whichserver: String) {
        logFunctionCall()
        if (whichserver == "source" && !WipeData.state.on) || (whichserver == "dest" && !export.saveOnly) {
            // post to notification center
            JamfProServer.whichServer = whichserver
            JamfProServer.validToken[whichserver] = false
            if whichserver == "source" {
                sourceUser_TextField.stringValue = ""
            } else {
                destinationUser_TextField.stringValue = ""
            }
            NotificationCenter.default.post(name: .resetListFields, object: nil)
        }
    }
   
    func fetchPassword(whichServer: String, url: String) {
        logFunctionCall()
        if Setting.fullGUI {
            fileImport = userDefaults.bool(forKey: "fileImport")
        } else {
            fileImport = (JamfProServer.importFiles == 1) ? true:false
        }

        var theUser     = ""
        if !(whichServer == "source" && fileImport) {
            if Setting.fullGUI {
                theUser = (whichServer == "source") ? sourceUser_TextField.stringValue:destinationUser_TextField.stringValue
                //            print("[fetchPassword] url: \(url.fqdnFromUrl), account: \(theUser), whichServer: \(whichServer)")
            } else {
                theUser = (whichServer == "source") ? JamfProServer.sourceUser:JamfProServer.destUser
            }
            accountDict = Credentials.shared.retrieve(service: url.fqdnFromUrl, account: theUser, whichServer: whichServer)
//            print("[fetchPassword] accountDict: \(accountDict)")
            
            
            if accountDict.count > 0 {
                for (username, password) in accountDict {
                    if whichServer == "source" {
//                        if username == theUser || accountDict.count == 1 {
                        if username == "" || (username == theUser) {
                            JamfProServer.sourceUser = ""
                            JamfProServer.sourcePwd  = ""
                            if (url != "") {
                                if Setting.fullGUI {
                                    sourceUser_TextField.stringValue = username
                                    source_pwd_field.stringValue     = password
                                    self.storedSourceUser            = username
                                    self.storedSourcePwd             = password
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
                        if Setting.fullGUI {
                            source_pwd_field.stringValue  = ""
                            hideCreds_button.state = .on
                            hideCreds_action(self)
                        }
                    } else {
                        // destination server
//                        if username == theUser || accountDict.count == 1 {
                        if username == "" || (username == theUser) {
                            JamfProServer.destUser   = ""
                            JamfProServer.destPwd    = ""
                            if (url != "") {
                                if Setting.fullGUI {
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
                                if Setting.fullGUI {
                                    dest_pwd_field.stringValue = ""
                                    if source_pwd_field.stringValue != "" {
                                        dest_pwd_field.becomeFirstResponder()
                                    }
                                }
                            }
                            break
                        }   // if username == dest_user_field.stringValue
                        if Setting.fullGUI {
                            dest_pwd_field.stringValue  = ""
                            hideCreds_button.state = .on
                            hideCreds_action(self)
                        }
                    }
                }   // for (username, password)
            } else {
                // credentials not found - blank out username / password fields
                if Setting.fullGUI {
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
                    WriteToLog.shared.message("Validate URL and/or credentials are saved for both source and destination Jamf Pro instances.")
                    NSApplication.shared.terminate(self)
                }
            }
        } else {
            if Setting.fullGUI {
                sourceUser_TextField.stringValue = ""
                source_pwd_field.stringValue = ""
            }
            self.storedSourceUser = ""
        }
    }
    
    func controlTextDidChange(_ obj: Notification) {
        logFunctionCall()
        if let textField = obj.object as? NSTextField {
            let whichField = textField.identifier!.rawValue
            
            if whichField.range(of: "^source", options: [.regularExpression, .caseInsensitive]) != nil {
                JamfProServer.sourceUser = sourceUser_TextField.stringValue
                JamfProServer.sourcePwd  = source_pwd_field.stringValue
                let sourceCreds = "\(sourceUser_TextField.stringValue):\(source_pwd_field.stringValue)"
                sourceBase64Creds = sourceCreds.data(using: .utf8)?.base64EncodedString() ?? ""
                JamfProServer.validToken["source"] = false
            } else {
                JamfProServer.destUser = destinationUser_TextField.stringValue
                JamfProServer.destPwd  = dest_pwd_field.stringValue
                let destCreds = "\(destinationUser_TextField.stringValue):\(dest_pwd_field.stringValue)"
                destBase64Creds = destCreds.data(using: .utf8)?.base64EncodedString() ?? ""
                JamfProServer.validToken["dest"] = false
            }
        }
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
//        print("enter controlTextDidEndEditing")
        logFunctionCall()
        if let textField = obj.object as? NSTextField {
            let whichField = textField.identifier?.rawValue ?? ""
            switch whichField {
            case "sourceServer", "sourceUser", "sourcePassword":
                if JamfProServer.source != source_jp_server_field.stringValue {
                    serverChanged(whichserver: "source")
                }
                
                serverOrFiles() { [self]
                    (result: String) in
                    switch textField.identifier!.rawValue {
                    case "sourceServer", "sourceUser":
                        fetchPassword(whichServer: "source", url: source_jp_server_field.stringValue)
                    default:
                        break
                    }
                    
                    JamfProServer.source     = baseUrl(source_jp_server_field.stringValue, whichServer: "source")    // source_jp_server_field.stringValue.baseUrl
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
                
                JamfProServer.destination = baseUrl(dest_jp_server_field.stringValue, whichServer: "dest")    // dest_jp_server_field.stringValue.baseUrl
                JamfProServer.destUser    = destinationUser_TextField.stringValue
                JamfProServer.destPwd     = dest_pwd_field.stringValue
            default:
                break
            }
        }
    }
    
    @IBAction func disableExportOnly_action(_ sender: Any) {
        logFunctionCall()
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
        logFunctionCall()
        if Setting.fullGUI {
            DispatchQueue.main.async { [self] in
                dest_jp_server_field.isEnabled      = !export.saveOnly
                destServerList_button.isEnabled     = !export.saveOnly
                destinationUser_TextField.isEnabled = !export.saveOnly
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
        logFunctionCall()
        let whichServer = (serverList == "source_server_array") ? "source" : "destination"
        WriteToLog.shared.message("[updateServerArray] set current \(whichServer) server: \(url)")
        if url != "" {
            var local_serverArray = theArray
            if let positionInList = local_serverArray.firstIndex(of: url) {
                local_serverArray.remove(at: positionInList)
            }
            local_serverArray.insert(url, at: 0)
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
        logFunctionCall()
        if LogLevel.debug && !AppInfo.maskServerNames { WriteToLog.shared.message("[\(#function.description)] info: \(info)") }
        AppInfo.settings                       = info

        AppInfo.settings["source_jp_server"]   = baseUrl(source_jp_server_field.stringValue, whichServer: "source")    // source_jp_server_field.stringValue.baseUrl as Any?
        AppInfo.settings["source_user"]        = sourceUser_TextField.stringValue as Any?
        AppInfo.settings["dest_jp_server"]     = baseUrl(dest_jp_server_field.stringValue, whichServer: "dest")    // dest_jp_server_field.stringValue.baseUrl as Any?
        AppInfo.settings["dest_user"]          = destinationUser_TextField.stringValue as Any?
        AppInfo.settings["storeSourceCreds"]   = JamfProServer.storeSourceCreds as Any?
        AppInfo.settings["storeDestCreds"]     = JamfProServer.storeDestCreds as Any?

        NSDictionary(dictionary: AppInfo.settings).write(toFile: AppInfo.plistPath, atomically: true)
        _ = readSettings()
    }
    
    @IBAction func setServerUrl_action(_ sender: NSPopUpButton) {
        logFunctionCall()
        let whichServer = sender.identifier!.rawValue
        if NSEvent.modifierFlags.contains(.option) {
            switch whichServer {
            case "source":
                let selectedServer =  sourceServerList_button.titleOfSelectedItem!
                let response = Alert.shared.display(header: "", message: "Are you sure you want to remove \n\(selectedServer) \nfrom the list?", secondButton: "Cancel")
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
                let response = Alert.shared.display(header: "", message: "Are you sure you want to remove \n\(selectedServer) \nfrom the list?", secondButton: "Cancel")
                if response == "Cancel" {
                    return
                }
                destServerArray.removeAll(where: { $0 == destServerList_button.titleOfSelectedItem! })
                destServerList_button.removeItem(withTitle: destServerList_button.titleOfSelectedItem!)
                if dest_jp_server_field.stringValue == selectedServer {
                    dest_jp_server_field.stringValue      = ""
                    destinationUser_TextField.stringValue = ""
                    dest_pwd_field.stringValue            = ""
                }
                AppInfo.settings["dest_server_array"] = destServerArray as Any?
            default:
                break
            }
            saveSourceDestInfo(info: AppInfo.settings)
            
            return
        }
        
        JamfProServer.version[whichServer] = ""
        
//        self.selectiveListCleared = false
        print("\(#line) - whichServer: \(whichServer)")
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
                if let lastUserInfo = lastUserManager.query(server: JamfProServer.source) {
                    sourceUser_TextField.stringValue = lastUserInfo.lastUser
                    sourceUseApiClient_button.state = lastUserInfo.apiClient ? .on : .off
                    useApiClient_action(sourceUseApiClient_button)
                }
                fetchPassword(whichServer: "source", url: JamfProServer.source)
            }
        case "dest":
            print(#line)
            if (self.dest_jp_server_field.stringValue != destServerList_button.titleOfSelectedItem!) && !export.saveOnly {
                print(#line)
                JamfProServer.validToken["dest"] = false
                serverChanged(whichserver: "dest")
                if destServerArray.firstIndex(of: "\(dest_jp_server_field.stringValue)") == nil {
                    updateServerArray(url: "\(dest_jp_server_field.stringValue)", serverList: "dest_server_array", theArray: destServerArray)
                }
            }
            JamfProServer.destination = destServerList_button.titleOfSelectedItem!
            self.dest_jp_server_field.stringValue = destServerList_button.titleOfSelectedItem!

            if let lastUserInfo = lastUserManager.query(server: JamfProServer.destination) {
                print("[SourceDestVC] lastUser query lastUser: \(lastUserInfo.lastUser), apiClient: \(lastUserInfo.apiClient)")
                destinationUser_TextField.stringValue = lastUserInfo.lastUser
                destUseApiClient_button.state = lastUserInfo.apiClient ? .on : .off
                useApiClient_action(destUseApiClient_button)
            }
            fetchPassword(whichServer: "dest", url: JamfProServer.destination)
            // reset list of available sites
            if siteMigrate_button.state.rawValue == 1 {
                siteMigrate_button.state = NSControl.StateValue(rawValue: 0)
                availableSites_button.isEnabled = false
                availableSites_button.removeAllItems()
                destinationLabel_TextField.stringValue = "Destination"
                itemToSite = false
            }
        default: break
        }
    }
    
    func serverOrFiles(whichServer: String = "source", completion: @escaping (_ sourceType: String) -> Void) {
        logFunctionCall()
        if whichServer != "source" {
            return
        }
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
        logFunctionCall()
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
        logFunctionCall()
        source_jp_server_field.nextKeyView  = sourceUser_TextField
        sourceUser_TextField.nextKeyView       = source_pwd_field
        source_pwd_field.nextKeyView        = dest_jp_server_field
        dest_jp_server_field.nextKeyView    = destinationUser_TextField
        destinationUser_TextField.nextKeyView         = dest_pwd_field
        
    }   //viewDidAppear - end
    
    @objc func stickySessionToggle(_ notification: Notification) {
        logFunctionCall()
        stickySessions_label.isHidden = !JamfProServer.stickySession
    }
    @objc func toggleExportOnly(_ notification: Notification) {
        logFunctionCall()
        disableSource()
    }
    @objc func updateSourceServerList(_ notification: Notification) {
        logFunctionCall()
        updateServerArray(url: JamfProServer.source, serverList: "source_server_array", theArray: self.sourceServerArray)
    }
    @objc func updateDestServerList(_ notification: Notification) {
        logFunctionCall()
        updateServerArray(url: JamfProServer.destination, serverList: "dest_server_array", theArray: self.destServerArray)
    }
    @objc func setColorScheme_sdvc(_ notification: Notification) {
        logFunctionCall()
        let whichColorScheme = userDefaults.string(forKey: "colorScheme") ?? ""
        if AppColor.schemes.firstIndex(of: whichColorScheme) != nil {
            self.view.wantsLayer = true
            source_jp_server_field.drawsBackground = true
            source_jp_server_field.backgroundColor = AppColor.highlight[whichColorScheme]
            sourceUser_TextField.drawsBackground = true
            sourceUser_TextField.backgroundColor = AppColor.highlight[whichColorScheme]
            source_pwd_field.drawsBackground = true
            source_pwd_field.backgroundColor = AppColor.highlight[whichColorScheme]
            dest_jp_server_field.drawsBackground = true
            dest_jp_server_field.backgroundColor = AppColor.highlight[whichColorScheme]
            dest_pwd_field.backgroundColor   = AppColor.highlight[whichColorScheme]
            destinationUser_TextField.drawsBackground  = true
            destinationUser_TextField.backgroundColor  = AppColor.highlight[whichColorScheme]
            dest_pwd_field.drawsBackground   = true
            self.view.layer?.backgroundColor = AppColor.background[whichColorScheme]
        }
    }
    
    
//    var jamfpro: JamfPro?
    override func viewDidLoad() {
        super.viewDidLoad()
//        hardSetLdapId = false

//        debug = true
        
//        print("test defaults: \(userDefaults.integer(forKey: "sourceDestListSize"))")
        
        // Do any additional setup after loading the view
//        if !FileManager.default.fileExists(atPath: AppInfo.bookmarksPath) {
//            FileManager.default.createFile(atPath: AppInfo.bookmarksPath, contents: nil)
//        }
        logFunctionCall()
        ViewController().rmDELETE()
        
        NotificationCenter.default.addObserver(self, selector: #selector(setColorScheme_sdvc(_:)), name: .setColorScheme_sdvc, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deleteMode_sdvc(_:)), name: .deleteMode_sdvc, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(toggleExportOnly(_:)), name: .saveOnlyButtonToggle, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(stickySessionToggle(_:)), name: .stickySessionToggle, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateSourceServerList(_:)), name: .updateSourceServerList, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateDestServerList(_:)), name: .updateDestServerList, object: nil)
        
        NotificationCenter.default.post(name: .setColorScheme_sdvc, object: self)
        
        source_jp_server_field.delegate    = self
        sourceUser_TextField.delegate      = self
        source_pwd_field.delegate          = self
        dest_jp_server_field.delegate      = self
        destinationUser_TextField.delegate = self
        dest_pwd_field.delegate            = self
        
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
        logFunctionCall()
        // create log directory if missing - start
//        if !fm.fileExists(atPath: History.logPath) {
//            do {
//                try fm.createDirectory(atPath: History.logPath, withIntermediateDirectories: true, attributes: nil )
//            } catch {
//                _ = Alert.shared.display(header: "Error:", message: "Unable to create log directory:\n\(String(describing: History.logPath))\nTry creating it manually.", secondButton: "")
//                exit(0)
//            }
//        }
//        // create log directory if missing - end
//                
//        if !fm.fileExists(atPath: AppInfo.plistPath) {
//            _ = readSettings(thePath: AppInfo.plistPathOld)
//            isDir = true
//            if !fm.fileExists(atPath: AppInfo.appSupportPath, isDirectory: &isDir) {
//                try? fm.createDirectory(atPath: AppInfo.appSupportPath, withIntermediateDirectories: true)
//            }
//            saveSettings(settings: AppInfo.settings)
//        }
        
        maxLogFileCount = (userDefaults.integer(forKey: "logFilesCountPref") < 1) ? 20:userDefaults.integer(forKey: "logFilesCountPref")
//        logFile = TimeDelegate().getCurrent().replacingOccurrences(of: ":", with: "") + "_replicator.log"
//        History.logFile = TimeDelegate().getCurrent().replacingOccurrences(of: ":", with: "") + "_replicator.log"
//
//        isDir = false
//        if !(fm.fileExists(atPath: History.logPath + logFile, isDirectory: &isDir)) {
//            fm.createFile(atPath: History.logPath + logFile, contents: nil, attributes: nil)
//        }
//        sleep(1)
        
        if !(fm.fileExists(atPath: userDefaults.string(forKey: "saveLocation") ?? ":missing:", isDirectory: &isDir)) {
            userDefaults.setValue(NSHomeDirectory() + "/Downloads/Replicator/", forKey: "saveLocation")
            userDefaults.synchronize()
        }
        
        let saved_sourceDestListSize = userDefaults.integer(forKey: "sourceDestListSize")
        sourceDestListSize = (saved_sourceDestListSize == 0) ? 20:saved_sourceDestListSize
        
        if Setting.fullGUI {
            if !FileManager.default.fileExists(atPath: AppInfo.plistPath) {
                do {
                    if !FileManager.default.fileExists(atPath: AppInfo.plistPath.replacingOccurrences(of: "settings.plist", with: "")) {
                        // create directory
                        try FileManager.default.createDirectory(atPath: AppInfo.plistPath.replacingOccurrences(of: "settings.plist", with: ""), withIntermediateDirectories: true, attributes: nil)
                    }
                    try FileManager.default.copyItem(atPath: Bundle.main.path(forResource: "settings", ofType: "plist")!, toPath: AppInfo.plistPath)
                    WriteToLog.shared.message("[SourceDestVC] Created default setting from  \(Bundle.main.path(forResource: "settings", ofType: "plist")!)")
                } catch {
                    WriteToLog.shared.message("[SourceDestVC] Unable to find/create \(AppInfo.plistPath)")
                    WriteToLog.shared.message("[SourceDestVC] Try to manually copy the file from \(Bundle.main.path(forResource: "settings", ofType: "plist")!) to \(AppInfo.plistPath)")
                    NSApplication.shared.terminate(self)
                }
            }
            
            // read environment settings from plist - start
            _ = readSettings()

            AppInfo.maskServerNames = userDefaults.integer(forKey: "maskServerNames") == 1
            WriteToLog.shared.message("[SourceDestVC] mask server names: \(AppInfo.maskServerNames)")
//            print("raw maskServerNames: \(userDefaults.integer(forKey: "maskServerNames"))")
//            print("maskServerNames: \(AppInfo.maskServerNames)")
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
        
        if !Setting.fullGUI {
            ViewController().initVars()
        }
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        logFunctionCall()
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
