//
//  Utilities.swift
//  Jamf Transporter
//
//  Created by leslie on 10/11/24.
//  Copyright © 2024 jamf. All rights reserved.
//

import Cocoa

class Utilities: NSObject {
    
    static let shared = Utilities()
    private override init() { }
    
    func dd(value: Int) -> String {
        let formattedValue = (value < 10) ? "0\(value)":"\(value)"
        return formattedValue
    }
    
    func zipIt(args: String..., completion: @escaping (_ result: String) -> Void) {

        var cmdArgs = ["-c"]
        for theArg in args {
            cmdArgs.append(theArg)
        }
        var status  = ""
        var statusArray  = [String]()
        let pipe    = Pipe()
        let task    = Process()
        
        task.launchPath     = "/bin/sh"
        task.arguments      = cmdArgs
        task.standardOutput = pipe
        
        task.launch()
        
        let outdata = pipe.fileHandleForReading.readDataToEndOfFile()
        if var string = String(data: outdata, encoding: .utf8) {
            string = string.trimmingCharacters(in: .newlines)
            statusArray = string.components(separatedBy: "")
            status = statusArray[0]
        }
        
        task.waitUntilExit()
        completion(status)
    }
}
