//
//  Headless.swift
//  Replicator
//
//  Created by leslie on 10/11/24.
//  Copyright © 2024 jamf. All rights reserved.
//

import Cocoa

class Headless: NSObject {
    
    static let shared = Headless()
    private override init() { }
    
    func runComplete(backupDate: DateFormatter, nodesMigrated: Int, objectsToMigrate: [String], counters: [String:[String:Int]]) {
        if export.backupMode {
//                if theOpQ.operationCount == 0 && nodesMigrated > 0 {
            Utilities.shared.zipIt(args: "cd \"\(export.saveLocation)\" ; /usr/bin/zip -rm -o \(JamfProServer.source.fqdnFromUrl)_export_\(backupDate.string(from: History.startTime)).zip \(JamfProServer.source.fqdnFromUrl)_export_\(backupDate.string(from: History.startTime))/") {
                    (result: String) in
//                            print("zipIt result: \(result)")
                    do {
                        if fm.fileExists(atPath: "\"\(export.saveLocation)\(JamfProServer.source.fqdnFromUrl)_export_\(backupDate.string(from: History.startTime))\"") {
                            try fm.removeItem(at: URL(string: "\"\(export.saveLocation)\(JamfProServer.source.fqdnFromUrl)_export_\(backupDate.string(from: History.startTime))\"")!)
                        }
                        WriteToLog.shared.message(stringOfText: "[Backup Complete] Backup created: \(export.saveLocation)\(JamfProServer.source.fqdnFromUrl)_export_\(backupDate.string(from: History.startTime)).zip")
                        
                        let (h,m,s, _) = timeDiff(forWhat: "runTime")
                        WriteToLog.shared.message(stringOfText: "[Backup Complete] runtime: \(Utilities.shared.dd(value: h)):\(Utilities.shared.dd(value: m)):\(Utilities.shared.dd(value: s)) (h:m:s)")
                    } catch let error as NSError {
                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "Unable to delete backup folder! Something went wrong: \(error)") }
                    }
                }
                
            WriteToLog.shared.logCleanup()
                NSApplication.shared.terminate(self)
//                }   //zipIt(args: "cd - end
        } else {
            if nodesMigrated > 0 {
//                        print("summaryDict: \(summaryDict)")
//                        print("counters: \(counters)")
                var summary = ""
                var otherLine: Bool = true
                var paddingChar = " "
                let sortedObjects = ToMigrate.objects.sorted()
                // find longest length of objects migrated
                var column1Padding = ""
                for theObject in ToMigrate.objects {
                    if theObject.count+1 > column1Padding.count {
                        column1Padding = "".padding(toLength: theObject.count+1, withPad: " ", startingAt: 0)
                    }
                }
                let leading = LogLevel.debug ? "                             ":"                 "
                
                summary = " ".padding(toLength: column1Padding.count-7, withPad: " ", startingAt: 0) + "Object".padding(toLength: 7, withPad: " ", startingAt: 0) +
                      "created".padding(toLength: 10, withPad: " ", startingAt: 0) +
                      "updated".padding(toLength: 10, withPad: " ", startingAt: 0) +
                      "failed".padding(toLength: 10, withPad: " ", startingAt: 0) +
                      "total".padding(toLength: 10, withPad: " ", startingAt: 0) + "\n"
                for theObject in sortedObjects {
                    if Counter.shared.crud[theObject] != nil {
                        let counts = Counter.shared.crud[theObject]!
                        let rightJustify = leading.padding(toLength: leading.count+(column1Padding.count-theObject.count-2), withPad: " ", startingAt: 0)
                        otherLine.toggle()
                        paddingChar = otherLine ? " ":"."
                        summary = summary.appending(rightJustify + "\(theObject)".padding(toLength: column1Padding.count+(7-"\(counts["create"]!)".count-(column1Padding.count-theObject.count-1)), withPad: paddingChar, startingAt: 0) +
                                                    "\(String(describing: counts["create"]!))".padding(toLength: (10-"\(counts["update"]!)".count+"\(counts["create"]!)".count), withPad: paddingChar, startingAt: 0) +
                                                    "\(String(describing: counts["update"]!))".padding(toLength: (9-"\(counts["fail"]!)".count+"\(counts["update"]!)".count), withPad: paddingChar, startingAt: 0) +
                                                    "\(String(describing: counts["fail"]!))".padding(toLength: (9-"\(counts["total"]!)".count+"\(counts["fail"]!)".count), withPad: paddingChar, startingAt: 0) +
                                                    "\(String(describing: counts["total"]!))".padding(toLength: 10, withPad: " ", startingAt: 0) + "")
                    }
                }
                WriteToLog.shared.message(stringOfText: summary)
                let (h,m,s, _) = timeDiff(forWhat: "runTime")
                WriteToLog.shared.message(stringOfText: "[Migration Complete] runtime: \(Utilities.shared.dd(value: h)):\(Utilities.shared.dd(value: m)):\(Utilities.shared.dd(value: s)) (h:m:s)")
                
                WriteToLog.shared.logCleanup()
                NSApplication.shared.terminate(self)
            }
        }

    }
    
}
    
