//
//  ExportItems.swift
//  Replicator
//
//  Created by leslie on 11/6/24.
//  Copyright © 2024 Jamf. All rights reserved.
//

import Cocoa
import OSLog

class ExportItem: NSObject {
    
    static let shared = ExportItem()
    
    fileprivate func saveLocation(_ format: String) -> String {
        // Create folder to store objectString files if needed - start
        logFunctionCall()
        var baseFolder = userDefaults.string(forKey: "saveLocation") ?? ""
        if baseFolder == "" {
            baseFolder = (NSHomeDirectory() + "/Downloads/Replicator/")
        } else {
            baseFolder = baseFolder.pathToString
        }
        
        let saveFolder = baseFolder+format+"/"
        
        if !(fm.fileExists(atPath: saveFolder)) {
            do {
                try fm.createDirectory(atPath: saveFolder, withIntermediateDirectories: true, attributes: nil)
            } catch {
                if LogLevel.debug { WriteToLog.shared.message("[ExportItem.export] Problem creating \(saveFolder) folder: Error \(error)") }
                return ""
            }
        }
        return saveFolder
    }
    
    func export(node: String, object: Any/*, endpointPath: String*/, theName: String = "", id: String = "", format: String = "raw") {
        
        logFunctionCall()
        
        var objectAsString = ""
        var exportFilename = ""
        var endpointPath   = ""
        
        let saveFolder = saveLocation(format)
        print("[export] saveFolder: \(saveFolder)")
        
        // Create endpoint type to store objectString files if needed - start
        switch node {
        case "selfservicepolicyicon", "macapplicationsicon", "mobiledeviceapplicationsicon":
            endpointPath = saveFolder+node+"/\(id)"
        case "accounts/groupid":
            endpointPath = saveFolder+"jamfgroups"
        case "accounts/userid":
            endpointPath = saveFolder+"jamfusers"
        case "computergroups":
            if let objectString = object as? String {
                let isSmart = tagValue2(xmlString: objectString, startTag: "<is_smart>", endTag: "</is_smart>")
                if isSmart == "true" {
                    endpointPath = saveFolder+"smartcomputergroups"
                } else {
                    endpointPath = saveFolder+"staticcomputergroups"
                }
            }
        default:
            endpointPath = saveFolder+node
        }
        print("[export] endpointPath: \(endpointPath)")
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            
            switch node {
            case "buildings":
                    if let object = object as? [String: Any], let displayName = object["name"] as? String, let id = object["id"] as? String {
                        exportFilename = "\(displayName)-\(id).json"
                    }
                    let prettyPrintedData = try JSONSerialization.data(withJSONObject: object, options: .prettyPrinted)
                    objectAsString = String(data: prettyPrintedData, encoding: .utf8)!
            case "api-roles", "api-integrations":
                if let object = object as? [String: Any], let displayName = object["displayName"] as? String, let id = object["id"] as? String {
                    exportFilename = "\(displayName)-\(id).json"
                }
                let prettyPrintedData = try JSONSerialization.data(withJSONObject: object, options: .prettyPrinted)
                objectAsString = String(data: prettyPrintedData, encoding: .utf8)!
            case "patchPolicyDetails":
                exportFilename = "patch-policies-policy-details.json"
                let t = object as? [PatchPolicyDetail]
                let prettyPrintedData = try encoder.encode(t)
                objectAsString = String(data: prettyPrintedData, encoding: .utf8)!
            case "patch-software-title-configurations":
                if let displayName = (object as? PatchSoftwareTitleConfiguration)?.displayName, let id = (object as? PatchSoftwareTitleConfiguration)?.id {
                    exportFilename = "\(displayName)-\(id).json"
                }
                let t = object as? PatchSoftwareTitleConfiguration
                let prettyPrintedData = try encoder.encode(t)
                objectAsString = String(data: prettyPrintedData, encoding: .utf8)!
            default:
                if let objectString = object as? String, objectString.isEmpty == false {
//                    var name = theName.replacingOccurrences(of: ":", with: ";")
//                    name     = name.replacingOccurrences(of: "/", with: "_")
                    if let xmlDoc = try? XMLDocument(xmlString: objectString, options: .nodePrettyPrint) {
                        if let _ = try? XMLElement.init(xmlString:"\(objectString)") {
                            exportFilename = "\(theName)-\(id).xml"
                            let data = xmlDoc.xmlData(options:.nodePrettyPrint)
                            objectAsString = String(data: data, encoding: .utf8)!
                            //                print("policy xml:\n\(formattedXml)")
                            
//                            do {
//                                try formattedXml.write(toFile: endpointPath+"/"+exportFilename, atomically: true, encoding: .utf8)
//                                if LogLevel.debug { WriteToLog.shared.message("[ExportItem.export] saved to: \(endpointPath)") }
//                            } catch {
//                                if LogLevel.debug { WriteToLog.shared.message("[ExportItem.export] Problem writing \(endpointPath) folder: Error \(error)") }
//                                return
//                            }
                        }   // if let prettyXml - end
                    }
                }
            }
            
//            if node == "patchPolicyDetails" {
//                let t = object as? [PatchPolicyDetail]
//                let prettyPrintedData = try encoder.encode(t)
//                rawExport = String(data: prettyPrintedData, encoding: .utf8)!
//            } else {
//                let t = object as? PatchSoftwareTitleConfiguration
//                let prettyPrintedData = try encoder.encode(t)
//                rawExport = String(data: prettyPrintedData, encoding: .utf8)!
//            }
            
            print("[ExportItem.export] rawExport for node \(node): \(objectAsString)")
            
            exportFilename = exportFilename.replacingOccurrences(of: ":", with: ";")
            exportFilename = exportFilename.replacingOccurrences(of: "/", with: "_")
            
            if !fm.fileExists(atPath: endpointPath) {
                try? fm.createDirectory(atPath: endpointPath, withIntermediateDirectories: true, attributes: nil)
            }
            
            try objectAsString.write(toFile: endpointPath+"/"+exportFilename, atomically: true, encoding: .utf8)
            if LogLevel.debug { WriteToLog.shared.message("[ExportItem.export] saved to: \(endpointPath)") }
        } catch {
            if LogLevel.debug { WriteToLog.shared.message("[ExportItem.export] Problem writing \(endpointPath) folder: Error \(error)") }
        }
    }
}
