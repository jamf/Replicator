//
//  AppDelegate.swift
//  jamf-migrator
//
//  Created by Leslie N. Helou on 12/9/16.
//  Copyright © 2016 jamf. All rights reserved.
//

import ApplicationServices
import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
//    let userDefaults = UserDefaults.standard
    
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
        // check for file that sets mode to delete data from destination server, delete if found - start
        ViewController().rmDELETE()
        // check for file that allows deleting data from destination server, delete if found - end
//        self.goButtonEnabled(button_status: true)
        quitNow(sender: self)
        
    }

    public func quitNow(sender: AnyObject) {
        
//        print("[quitNow] JamfProServer.validToken[\"source\"]: \(JamfProServer.validToken["source"] ?? false)")
//        print("[quitNow] JamfProServer.validToken[\"dest\"]: \(JamfProServer.validToken["dest"] ?? false)")
        let sourceMethod = (JamfProServer.validToken["source"] ?? false) ? "POST":"SKIP"
//        print("[quitNow] sourceMethod: \(sourceMethod)")
        Jpapi().action(serverUrl: JamfProServer.source, endpoint: "auth/invalidate-token", apiData: [:], id: "", token: JamfProServer.authCreds["source"] ?? "", method: sourceMethod) {
            (returnedJSON: [String:Any]) in
            WriteToLog().message(stringOfText: "source server token task: \(returnedJSON["JPAPI_result"] ?? "unknown response")\n")
            let destMethod = (JamfProServer.validToken["dest"] ?? false) ? "POST":"SKIP"
//                    print("[quitNow] destMethod: \(destMethod)")
            Jpapi().action(serverUrl: JamfProServer.destination, endpoint: "auth/invalidate-token", apiData: [:], id: "", token: JamfProServer.authCreds["dest"] ?? "", method: destMethod) {
                (returnedJSON: [String:Any]) in
                WriteToLog().message(stringOfText: "destination server token task: \(returnedJSON["JPAPI_result"] ?? "unknown response")\n")
                WriteToLog().logFileW?.closeFile()
                NSApplication.shared.terminate(self)
            }
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // read command line arguments - start
        var numberOfArgs = 0
        var startPos     = 1
        // read commandline args
        numberOfArgs = CommandLine.arguments.count
//        print("all arguments: \(CommandLine.arguments)")
        if CommandLine.arguments.contains("-debug") {
            numberOfArgs -= 1
            startPos+=1
            LogLevel.debug = true
        }
        var index = 0
        while index < numberOfArgs {
//                print("[\(#line)-applicationDidFinishLaunching] index: \(index)\t argument: \(CommandLine.arguments[index])")
            let cmdLineSwitch = CommandLine.arguments[index].lowercased()
                switch cmdLineSwitch {
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
                case "-destclientsecret":
                    index += 1
                    JamfProServer.destApiClient["secret"] = CommandLine.arguments[index]
                    JamfProServer.destPwd = JamfProServer.destApiClient["secret"] ?? ""
                case "-silent":
                    setting.fullGUI = false
                case "-sticky":
                    JamfProServer.stickySession = true
                default:
                    if CommandLine.arguments[index].lowercased().suffix(13) != "jamf-migrator" && CommandLine.arguments[index].lowercased() != "-debug"{
                        print("unknown switch passed: \(CommandLine.arguments[index])")
                    }
                }
            index += 1
        }
        // read command line arguments - end
//        print("done reading command line args - index: \(index)")
        
        export.saveLocation = userDefaults.string(forKey: "saveLocation") ?? ""
        if export.saveLocation == "" || !(FileManager().fileExists(atPath: export.saveLocation)) {
            export.saveLocation = (NSHomeDirectory() + "/Downloads/Jamf Migrator/")
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
            WriteToLog().message(stringOfText: "[AppDelegate] jamf migrator is running silently\n")
            print("running silently")
            
            SourceDestVC().initVars()
//            ViewController().initVars()
        }
    }

    @IBAction func checkForUpdates(_ sender: AnyObject) {
        let verCheck = VersionCheck()
        
        let appInfo = Bundle.main.infoDictionary!
        let version = appInfo["CFBundleShortVersionString"] as! String
        
        verCheck.versionCheck() {
            (result: Bool, latest: String) in
            if result {
                self.alert_dialog(header: "A new version (\(latest)) is available.", message: "Running Jamf Migrator: \(version)", updateAvail: result)
            } else {
                self.alert_dialog(header: "Running Jamf Migrator: \(version)", message: "No updates are currently available.", updateAvail: result)
            }
        }
    }
    
    func alert_dialog(header: String, message: String, updateAvail: Bool) {
        
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

        //return true
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

