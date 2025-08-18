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
    var updateUiDelegate: UpdateUiDelegate?
    func updateView(_ info: [String: Any]) {
        logFunctionCall()
        updateUiDelegate?.updateUi(info: info)
    }
    
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
    
    func exportObject(node: String, object: Any, theName: String = "", id: String = "", format: String = "raw") {
        
        logFunctionCall()
        
        if JamfProServer.source.range(of: "^/", options: [.regularExpression, .caseInsensitive]) != nil {
            WriteToLog.shared.message("[exportObject] skipping \(node) with id \(id), cannot export when the source is a folder")
            return
        }
        
        var objectAsString = ""
        var exportFilename = ""
        var endpointPath   = ""
        
        let saveFolder = saveLocation(format)
        
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
                let rawData = object as? [PatchPolicyDetail]
                let prettyPrintedData = try encoder.encode(rawData)
                objectAsString = String(data: prettyPrintedData, encoding: .utf8)!
            case "patch-software-title-configurations":
                if let displayName = (object as? PatchSoftwareTitleConfiguration)?.displayName, let id = (object as? PatchSoftwareTitleConfiguration)?.id {
                    exportFilename = "\(displayName)-\(id).json"
                }
                let rawData = object as? PatchSoftwareTitleConfiguration
                let prettyPrintedData = try encoder.encode(rawData)
                objectAsString = String(data: prettyPrintedData, encoding: .utf8)!
//                let thePatchPolicies = PatchPoliciesDetails.source.filter( { $0.softwareTitleConfigurationId == (object as? PatchSoftwareTitleConfiguration)?.id } ).map { $0.id }
//                let theIndex = ToMigrate.objects.firstIndex(of: "patch-software-title-configurations") ?? 0
//                print("[ExportItem] thePatchPolicies: \(thePatchPolicies)")
//                print()
            default:
                if let objectString = object as? String, objectString.isEmpty == false {
                    if let xmlDoc = try? XMLDocument(xmlString: objectString, options: .nodePrettyPrint) {
                        if let _ = try? XMLElement.init(xmlString:"\(objectString)") {
                            exportFilename = (node == "patchpolicies") ? "\(id).xml" : "\(theName)-\(id).xml"
                            let data = xmlDoc.xmlData(options:.nodePrettyPrint)
                            objectAsString = String(data: data, encoding: .utf8)!
                        }
                    }
                }
            }
                        
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
        
        if export.saveOnly {
            let fixedNode = (node == "patchPolicyDetails") ? "patchpolicies" : node
            updateView(["function": "putStatusUpdate", "endpoint": fixedNode, "total": Counter.shared.crud[fixedNode]!["total"]!])
        }
    }
}
