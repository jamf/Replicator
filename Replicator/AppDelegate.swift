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
    
    @IBAction func showSummaryWindow(_ sender: AnyObject) {
        NotificationCenter.default.post(name: .showSummaryWindow, object: self)
    }
    @IBAction func showLogFolder(_ sender: AnyObject) {
        NotificationCenter.default.post(name: .showLogFolder, object: self)
    }
    @IBAction func deleteMode(_ sender: AnyObject) {
        NotificationCenter.default.post(name: .deleteMode, object: self)
    }
    @IBAction func quit_menu(sender: AnyObject) {
        quitNow(sender: self)
    }

    public func quitNow(sender: AnyObject) {
        DispatchQueue.main.async {
            NSApp.hide(nil)
            let sourceMethod = (JamfProServer.validToken["source"] ?? false) ? "POST":"SKIP"
            let destMethod = (JamfProServer.validToken["dest"] ?? false) ? "POST":"SKIP"
            
            // check for file that sets mode to delete data from destination server, delete if found - start
            ViewController().rmDELETE()

            Jpapi.shared.action(whichServer: "source", endpoint: "auth/invalidate-token", apiData: [:], id: "", token: JamfProServer.authCreds["source"] ?? "", method: sourceMethod) {
                (returnedJSON: [String:Any]) in
                WriteToLog.shared.message(stringOfText: "source server token task: \(returnedJSON["JPAPI_result"] ?? "unknown response")")

                Jpapi.shared.action(whichServer: "dest", endpoint: "auth/invalidate-token", apiData: [:], id: "", token: JamfProServer.authCreds["dest"] ?? "", method: destMethod) {
                    (returnedJSON: [String:Any]) in
                    WriteToLog.shared.message(stringOfText: "destination server token task: \(returnedJSON["JPAPI_result"] ?? "unknown response")")
                    logFileW?.closeFile()
                    NSApplication.shared.terminate(self)
                }
            }
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("[\(#function.description)] loaded")
        
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
                case "-backup","-export":
                    export.backupMode = true
                    export.saveOnly   = true
                    export.saveRawXml = true
                    setting.fullGUI   = false
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
                    setting.ldapId = Int(CommandLine.arguments[index]) ?? -1
                    if setting.ldapId > 0 {
                        setting.hardSetLdapId = true
                    }
                case "-migrate":
                    setting.migrate = true
                    setting.fullGUI = false
                case "-objects":
                    index += 1
                    let objectsString = "\(CommandLine.arguments[index])".lowercased()
                    setting.objects = objectsString.components(separatedBy: ",")
                case "-scope":
                    index += 1
                    setting.copyScope = Bool(CommandLine.arguments[index].lowercased()) ?? true
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
//                    JamfProServer.url["source"] = JamfProServer.source
                case "-dest","-destination":
                    index += 1
                    JamfProServer.destination = "\(CommandLine.arguments[index])"
                    if JamfProServer.destination.prefix(4) != "http" && JamfProServer.destination.prefix(1) != "/" {
                        JamfProServer.destination = "https://\(JamfProServer.destination)"
                    }
//                    JamfProServer.url["destination"] = JamfProServer.source
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
                        setting.onlyCopyMissing = true
                        setting.onlyCopyExisting = false
                    } else {
                        setting.onlyCopyMissing = false
                    }
                case "-onlycopyexisting":
                    index += 1
                    if CommandLine.arguments[index].lowercased() == "true" || CommandLine.arguments[index].lowercased() == "1" {
                        setting.onlyCopyMissing = false
                        setting.onlyCopyExisting = true
                    } else {
                        setting.onlyCopyExisting = false
                    }
                case "-silent":
                    setting.fullGUI = false
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
        
        if setting.fullGUI {
            NSApp.setActivationPolicy(.regular)
            let storyboard = NSStoryboard(name: "Main", bundle: nil)
            let mainWindowController = storyboard.instantiateController(withIdentifier: "Main") as! NSWindowController
            mainWindowController.window?.hidesOnDeactivate = false
            mainWindowController.showWindow(self)
        }
        else {
            WriteToLog.shared.message(stringOfText: "[AppDelegate] Replicator is running silently")
            
            SourceDestVC().initVars()
        }
    }

    @IBAction func checkForUpdates(_ sender: AnyObject) {
        let verCheck = VersionCheck()
        
        let appInfo = Bundle.main.infoDictionary!
        let version = appInfo["CFBundleShortVersionString"] as! String
        
        verCheck.versionCheck() {
            (result: Bool, latest: String) in
            if result {
                self.versionAlert(header: "A new version (\(latest)) is available.", message: "Running Replicator: \(version)", updateAvail: result)
            } else {
                self.versionAlert(header: "Running Replicator: \(version)", message: "No updates are currently available.", updateAvail: result)
            }
        }
    }
    
    func versionAlert(header: String, message: String, updateAvail: Bool) {
        
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
            if let url = URL(string: "https://github.com/jamf/JamfMigrator/releases") {
                    NSWorkspace.shared.open(url)
            }
        }
    }   // func alert_dialog - end
    
    // Help Window
    @IBAction func showHelpWindow(_ sender: AnyObject) {
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
        PrefsWindowController().show()
    }
    
    // quit the app if the window is closed
    func applicationShouldTerminateAfterLastWindowClosed(_ app: NSApplication) -> Bool {
        quitNow(sender: self)
        return false
    }
    
}

