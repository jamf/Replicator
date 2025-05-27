//
//  RemoveData.swift
//  Replicator
//
//  Copyright © 2024 Jamf. All rights reserved.
//

import Foundation

class RemoveData: NSObject {
    
    static let shared = RemoveData()
    
    func Json(rawJSON: [String:Any], theTag: String) -> String {
        logFunctionCall()
        var newJSON  = rawJSON
                // remove keys with <null> as the value
                for (key, value) in newJSON {
                    if "\(value)" == "<null>" || "\(value)" == ""  {
                        newJSON[key] = nil
                    } else {
                        newJSON[key] = "\(value)"
                    }
                }
                if theTag != "" {
                    if let _ = newJSON[theTag] {
                        newJSON[theTag] = nil
                    }
                }
        
        return "\(newJSON)"
    }
    
    func Xml(theXML: String, theTag: String, keepTags: Bool) -> String {
        logFunctionCall()
        var newXML         = ""
        var newXML_trimmed = ""
        let f_regexComp = try! NSRegularExpression(pattern: "<\(theTag)>(.|\n|\r)*?</\(theTag)>", options:.caseInsensitive)
        if keepTags {
            newXML = f_regexComp.stringByReplacingMatches(in: theXML, options: [], range: NSRange(0..<theXML.utf16.count), withTemplate: "<\(theTag)/>")
        } else {
            newXML = f_regexComp.stringByReplacingMatches(in: theXML, options: [], range: NSRange(0..<theXML.utf16.count), withTemplate: "")
        }

        // prevent removing blank lines from scripts
        if (theTag == "script_contents_encoded") || (theTag == "id") {
            newXML_trimmed = newXML
        } else {
//            if LogLevel.debug { WriteToLog.shared.message("Removing blank lines.") }
            newXML_trimmed = newXML.replacingOccurrences(of: "\n\n", with: "")
            newXML_trimmed = newXML.replacingOccurrences(of: "\r\r", with: "\r")
        }
        return newXML_trimmed
    }
    
    
    
}
