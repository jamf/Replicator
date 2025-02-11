//
//  WriteToLog.swift
//  Replicator
//
//  Created by Leslie Helou on 2/21/19.
//  Copyright 2024 Jamf. All rights reserved.
//

import Foundation

//var logFileW = FileHandle(forUpdatingAtPath: (History.logPath + History.logFile))

class WriteToLog {
    
    static let shared = WriteToLog()
    
//    func message(stringOfText: String) {
//        let logString = (LogLevel.debug) ? "\(TimeDelegate().getCurrent()) [- debug -] \(stringOfText)\n":"\(TimeDelegate().getCurrent()) \(stringOfText)\n"
////        print("[WriteToLog] \(logString)")
//
//        logFileW?.seekToEndOfFile()
//        if let historyText = (logString as NSString).data(using: String.Encoding.utf8.rawValue) {
//            logFileW?.write(historyText)
//        }
//    }
    func message(_ message: String) {
        let logString = (LogLevel.debug) ? "\(TimeDelegate().getCurrent()) [- debug -] \(message)\n":"\(TimeDelegate().getCurrent()) \(message)\n"
//        print("[WriteToLog] \(logString)")

        guard let logData = logString.data(using: .utf8) else { return }
        let logURL = URL(fileURLWithPath: History.logPath + History.logFile)

        do {
            let fileHandle = try FileHandle(forWritingTo: logURL)
            defer { fileHandle.closeFile() } // Ensure file is closed
            
            fileHandle.seekToEndOfFile()
            fileHandle.write(logData)
        } catch {
            print("[Log Error] Failed to write to log file: \(error.localizedDescription)")
        }
    }
    
    func logCleanup() {
        let maxLogFileCount = (userDefaults.integer(forKey: "logFilesCountPref") < 1) ? 20:userDefaults.integer(forKey: "logFilesCountPref")
        var logArray: [String] = []
        var logCount: Int = 0
        do {
            let logFiles = try fm.contentsOfDirectory(atPath: History.logPath)
            
            for logFile in logFiles {
                let filePath: String = History.logPath + logFile
                logArray.append(filePath)
            }
            logArray.sort()
            logCount = logArray.count
            if didRun {
                // remove old history files
                if logCount > maxLogFileCount {
                    for i in (0..<logCount-maxLogFileCount) {
                        if LogLevel.debug { WriteToLog.shared.message("Deleting log file: " + logArray[i] + "") }
                        
                        do {
                            try fm.removeItem(atPath: logArray[i])
                        }
                        catch let error as NSError {
                            if LogLevel.debug { WriteToLog.shared.message("Error deleting log file:\n    " + logArray[i] + "\n    \(error)") }
                        }
                    }
                }
            } else {
                // delete empty log file
                if logCount > 0 {
                    
                }
                do {
                    try fm.removeItem(atPath: logArray[0])
                }
                catch let error as NSError {
                    if LogLevel.debug { WriteToLog.shared.message("Error deleting log file:    \n" + History.logPath + logArray[0] + "\n    \(error)") }
                }
            }
        } catch {
            WriteToLog.shared.message("no log files found")
        }
    }
}
