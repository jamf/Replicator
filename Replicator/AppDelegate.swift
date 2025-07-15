//
//  AppDelegate.swift
//  Replicator
//
//  Created by Leslie N. Helou on 12/9/16.
//  Copyright 2024 Jamf. All rights reserved.
//

import AppKit
import ApplicationServices
import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    static let shared = AppDelegate()
    private override init() { }
    
    var prefWindowController: NSWindowController?
    
    @IBOutlet weak var resetVersionAlert_MenuItem: NSMenuItem!
    @IBAction func resetVersionAlert_Action(_ sender: Any) {
        resetVersionAlert_MenuItem.isEnabled = false
        resetVersionAlert_MenuItem.isHidden = true
        userDefaults.set(false, forKey: "hideVersionAlert")
    }
    
    
    @IBAction func showSummaryWindow(_ sender: AnyObject) {
        logFunctionCall()
        NotificationCenter.default.post(name: .showSummaryWindow, object: self)
    }
    @IBAction func showLogFolder(_ sender: AnyObject) {
        logFunctionCall()
        NotificationCenter.default.post(name: .showLogFolder, object: self)
    }
    @IBAction func deleteMode(_ sender: AnyObject) {
        logFunctionCall()
        NotificationCenter.default.post(name: .deleteMode, object: self)
    }
    @IBAction func quit_menu(sender: AnyObject) {
        logFunctionCall()
        quitNow(sender: self)
    }

    public func quitNow(sender: AnyObject) {
        logFunctionCall()
        DispatchQueue.main.async {
            NSApp.hide(nil)
            let sourceMethod = (JamfProServer.validToken["source"] ?? false) ? "POST":"SKIP"
            let destMethod = (JamfProServer.validToken["dest"] ?? false) ? "POST":"SKIP"
            
            // check for file that sets mode to delete data from destination server, delete if found - start
            ViewController().rmDELETE()

            Jpapi.shared.action(whichServer: "source", endpoint: "auth/invalidate-token", apiData: [:], id: "", token: JamfProServer.authCreds["source"] ?? "", method: sourceMethod) {
                (returnedJSON: [String:Any]) in
                WriteToLog.shared.message("source server token task: \(returnedJSON["JPAPI_result"] ?? "unknown response")")

                Jpapi.shared.action(whichServer: "dest", endpoint: "auth/invalidate-token", apiData: [:], id: "", token: JamfProServer.authCreds["dest"] ?? "", method: destMethod) {
                    (returnedJSON: [String:Any]) in
                    WriteToLog.shared.message("destination server token task: \(returnedJSON["JPAPI_result"] ?? "unknown response")")

                    NSApplication.shared.terminate(self)
                }
            }
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        logFunctionCall()
        print("[\(#function.description)] loaded")
        
        if Setting.fullGUI {
            let hideVersionAlert = userDefaults.bool(forKey: "hideVersionAlert")
            resetVersionAlert_MenuItem.isEnabled = hideVersionAlert
            resetVersionAlert_MenuItem.isHidden = !hideVersionAlert
        
            // create log directory if missing - start
            if !fm.fileExists(atPath: History.logPath) {
                do {
                    try fm.createDirectory(atPath: History.logPath, withIntermediateDirectories: true, attributes: nil )
                } catch {
                    _ = Alert.shared.display(header: "Error:", message: "Unable to create log directory:\n\(String(describing: History.logPath))\nTry creating it manually.", secondButton: "")
                    exit(0)
                }
            }
            // create log directory if missing - endlogFile = TimeDelegate().getCurrent().replacingOccurrences(of: ":", with: "") + "_replicator.log"
            History.logFile = TimeDelegate().getCurrent().replacingOccurrences(of: ":", with: "") + "_replicator.log"
            
            //            isDir = false
            if !(fm.fileExists(atPath: History.logPath + History.logFile/*, isDirectory: &isDir*/)) {
                fm.createFile(atPath: History.logPath + History.logFile, contents: nil, attributes: nil)
            }
            sleep(1)
            if !(fm.fileExists(atPath: History.logPath + History.logFile/*, isDirectory: &isDir*/)) {
                print("Unable to create log file:\n\(History.logPath + History.logFile)")
            }
        }
        
                
        if !fm.fileExists(atPath: AppInfo.plistPath) {
            _ = readSettings(thePath: AppInfo.plistPathOld)
//                isDir = true
            if !fm.fileExists(atPath: AppInfo.appSupportPath/*, isDirectory: &isDir*/) {
                try? fm.createDirectory(atPath: AppInfo.appSupportPath, withIntermediateDirectories: true)
            }
            saveSettings(settings: AppInfo.settings)
        }
        
        // read command line arguments - start
        var numberOfArgs = 0
//        var startPos     = 1
        // read commandline args
        numberOfArgs = CommandLine.arguments.count
        print("all arguments: \(CommandLine.arguments)")
//        if CommandLine.arguments.contains("-debug") {
//            numberOfArgs -= 1
//            startPos+=1
//            LogLevel.debug = true
//        }
        var index = 1
        while index < numberOfArgs {
            print("[\(#line)-applicationDidFinishLaunching] index: \(index)\t argument: \(CommandLine.arguments[index])")
            let cmdLineSwitch = CommandLine.arguments[index].lowercased()
                switch cmdLineSwitch {
                case "-debug":
                    LogLevel.debug = true
                case "-dryrun":
                    LogLevel.debug = true
                case "-backup","-export":
                    export.backupMode = true
                    export.saveOnly   = true
                    export.saveRawXml = true
                    Setting.fullGUI   = false
                case "-saverawxml":
                    export.saveRawXml = true
                case "-savetrimmedxml":
                    export.saveTrimmedXml = true
                case "-export.saveonly":
                    export.saveOnly = true
//                case "-forceldapid":
//                    index += 1
//                    forceLdapId = Bool(CommandLine.arguments[index]) ?? false
                case "-help":
                    print("\(helpText)")
                    NSApplication.shared.terminate(self)
                case "-ldapid":
                    index += 1
                    Setting.ldapId = Int(CommandLine.arguments[index]) ?? -1
                    if Setting.ldapId > 0 {
                        Setting.hardSetLdapId = true
                    }
                case "-migrate":
                    Setting.migrate = true
                    Setting.fullGUI = false
                case "-objects":
                    index += 1
                    let objectsString = "\(CommandLine.arguments[index])".lowercased()
                    Setting.objects = objectsString.components(separatedBy: ",")
                case "-scope":
                    index += 1
                    Setting.copyScope = Bool(CommandLine.arguments[index].lowercased()) ?? true
                case "-site":
                    index += 1
                    JamfProServer.toSite   = true
                    JamfProServer.destSite = "\(CommandLine.arguments[index])"
                case "-source":
                    index += 1
                    JamfProServer.source = "\(CommandLine.arguments[index])"
                    if JamfProServer.source.prefix(4) != "http" && JamfProServer.source.prefix(1) != "/" {
                        JamfProServer.source = "https://\(JamfProServer.source)"
                    } else if JamfProServer.source.prefix(1) == "/" {
                        JamfProServer.importFiles = 1   // importing files
                    }

                case "-dest","-destination":
                    index += 1
                    JamfProServer.destination = "\(CommandLine.arguments[index])"
                    if JamfProServer.destination.prefix(4) != "http" && JamfProServer.destination.prefix(1) != "/" {
                        JamfProServer.destination = "https://\(JamfProServer.destination)"
                    }

                case "-sourceuseclientid", "-destuseclientid":
                    index += 1
                    let useApiClient = ( "\(CommandLine.arguments[index])".lowercased() == "yes" || "\(CommandLine.arguments[index])".lowercased() == "true" ) ? 1:0
                    if cmdLineSwitch ==  "-sourceuseclientid" {
                        JamfProServer.sourceUseApiClient = useApiClient
                    } else {
                        JamfProServer.destUseApiClient = useApiClient
                    }
                case "-sourceclientid":
                    index += 1
                    JamfProServer.sourceApiClient["id"] = CommandLine.arguments[index]
                    JamfProServer.sourceUser = JamfProServer.sourceApiClient["id"] ?? ""
                    JamfProServer.sourceUseApiClient = 1
                case "-destclientid":
                    index += 1
                    JamfProServer.destApiClient["id"] = CommandLine.arguments[index]
                    JamfProServer.destUser = JamfProServer.destApiClient["id"] ?? ""
                    JamfProServer.destUseApiClient = 1
                case "-sourceclientsecret":
                    index += 1
                    JamfProServer.sourceApiClient["secret"] = CommandLine.arguments[index]
                    JamfProServer.sourcePwd = JamfProServer.sourceApiClient["secret"] ?? ""
                case "-sourceuser":
                    index += 1
                    JamfProServer.sourceUser = CommandLine.arguments[index]
//                    JamfProServer.sourcePwd = JamfProServer.sourceApiClient["secret"] ?? ""
                case "-destuser":
                    index += 1
                    JamfProServer.destUser = CommandLine.arguments[index]
                case "-destclientsecret":
                    index += 1
                    JamfProServer.destApiClient["secret"] = CommandLine.arguments[index]
                    JamfProServer.destPwd = JamfProServer.destApiClient["secret"] ?? ""
                case "-onlycopymissing":
                    index += 1
                    if "\(CommandLine.arguments[index].lowercased())" == "true" || "\(CommandLine.arguments[index].lowercased())" == "1" {
                        Setting.onlyCopyMissing = true
                        Setting.onlyCopyExisting = false
                    } else {
                        Setting.onlyCopyMissing = false
                    }
                case "-onlycopyexisting":
                    index += 1
                    if CommandLine.arguments[index].lowercased() == "true" || CommandLine.arguments[index].lowercased() == "1" {
                        Setting.onlyCopyMissing = false
                        Setting.onlyCopyExisting = true
                    } else {
                        Setting.onlyCopyExisting = false
                    }
                case "-silent":
                    Setting.fullGUI = false
                case "-sticky":
                    JamfProServer.stickySession = true
                case "-NSDocumentRevisionsDebugMode":
                    index += 1
                    break
                default:
                    if !CommandLine.arguments[index].contains(AppInfo.name) {
                        print("unknown switch passed: \(CommandLine.arguments[index])")
                    }
                }
            index += 1
        }
        // read command line arguments - end
//        print("done reading command line args - index: \(index)")
        
        export.saveLocation = userDefaults.string(forKey: "saveLocation") ?? ""
        if export.saveLocation == "" || !(FileManager().fileExists(atPath: export.saveLocation)) {
            export.saveLocation = (NSHomeDirectory() + "/Downloads/Replicator/")
            userDefaults.set("\(export.saveLocation)", forKey: "saveLocation")
        } else {
            export.saveLocation = export.saveLocation.pathToString
//            self.userDefaults.synchronize()
        }
        
        if Setting.fullGUI {
            DispatchQueue.main.async { [self] in
                NSApp.setActivationPolicy(.regular)
                let storyboard = NSStoryboard(name: "Main", bundle: nil)
                let mainWindowController = storyboard.instantiateController(withIdentifier: "Main") as! NSWindowController
                mainWindowController.window?.hidesOnDeactivate = false
                mainWindowController.showWindow(self)
                checkForUpdates(self)
            }
        }
        else {
            WriteToLog.shared.message("[AppDelegate] Replicator is running silently")
            
            SourceDestVC().initVars()
        }
    }

    @IBAction func checkForUpdates(_ sender: AnyObject) {
        logFunctionCall()
        let verCheck = VersionCheck()
        
        var manualCheck = false
        if let _ = sender as? NSMenuItem {
            manualCheck = true
        }
        
        verCheck.versionCheck() {
            (result: Bool, latest: String) in
            if result {
                if Setting.fullGUI {
                    Alert.shared.versionDialog(header: "A new version (\(latest)) is available.", message: "Running Replicator: \(AppInfo.version)", updateAvail: result, manualCheck: manualCheck)
                }
                WriteToLog.shared.message("A new version (\(latest)) is available")
            } else {
                if manualCheck && Setting.fullGUI {
                    Alert.shared.versionDialog(header: "Running Replicator: \(AppInfo.version)", message: "No updates are currently available.", updateAvail: result, manualCheck: manualCheck)
                }
            }
        }
    }
    
    func versionAlert(header: String, message: String, updateAvail: Bool) {
        logFunctionCall()
        
        let dialog: NSAlert = NSAlert()
        dialog.messageText = header
        dialog.informativeText = message
        dialog.alertStyle = NSAlert.Style.informational
        if updateAvail {
            dialog.addButton(withTitle: "View")
            dialog.addButton(withTitle: "Ignore")
        } else {
            dialog.addButton(withTitle: "OK")
        }
        
        let clicked:NSApplication.ModalResponse = dialog.runModal()

        if clicked.rawValue == 1000 && updateAvail {
            if let url = URL(string: "https://github.com/jamf/Replicator/releases") {
                    NSWorkspace.shared.open(url)
            }
        }
    }   // func alert_dialog - end
    
    // Help Window
    @IBAction func showHelpWindow(_ sender: AnyObject) {
        logFunctionCall()
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let helpWindowController = storyboard.instantiateController(withIdentifier: "Help View Controller") as! NSWindowController
        if !ViewController().windowIsVisible(windowName: "Help") {
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
    
    @IBAction func showPreferences(_ sender: Any) {
        logFunctionCall()
        PrefsWindowController().show()
    }
    
    // quit the app if the window is closed
    func applicationShouldTerminateAfterLastWindowClosed(_ app: NSApplication) -> Bool {
        logFunctionCall()
        quitNow(sender: self)
        return false
    }
    
}

