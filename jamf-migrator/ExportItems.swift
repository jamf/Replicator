//
//  ExportItems.swift
//  Replicator
//
//  Created by leslie on 11/6/24.
//  Copyright © 2024 Jamf. All rights reserved.
//

import Cocoa

class ExportItems: NSObject {
    
    static let shared = ExportItems()
    
    fileprivate func saveLocation(_ format: String) -> String {
        // Create folder to store objectString files if needed - start
        var baseFolder = userDefaults.string(forKey: "saveLocation") ?? ""
        if baseFolder == "" {
            baseFolder = (NSHomeDirectory() + "/Downloads/Jamf Transporter/")
        } else {
            baseFolder = baseFolder.pathToString
        }
        
        let saveFolder = baseFolder+format+"/"
        
        if !(fm.fileExists(atPath: saveFolder)) {
            do {
                try fm.createDirectory(atPath: saveFolder, withIntermediateDirectories: true, attributes: nil)
            } catch {
                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.exportItems] Problem creating \(saveFolder) folder: Error \(error)") }
                return ""
            }
        }
        return saveFolder
    }
    
    fileprivate func export(_ node: String, _ object: Any, _ endpointPath: String, _ jsonFile: String) {
        var rawExport = ""
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            
            if node == "patchPolicyDetails" {
                let t = object as? [PatchPolicyDetail]
//                let count = t?.count ?? 0
                let prettyPrintedData = try encoder.encode(t)
                rawExport = String(data: prettyPrintedData, encoding: .utf8)!
//                rawExport = """
//                    {
//                        "totalCount": \(count),
//                        "results": \(rawExport)
//                    }
//                    """
            } else {
                let t = object as? PatchSoftwareTitleConfiguration
                let prettyPrintedData = try encoder.encode(t)
                rawExport = String(data: prettyPrintedData, encoding: .utf8)!
            }
            
            print("[exportItems] rawExport: \(rawExport)")
            
            try rawExport.write(toFile: endpointPath+"/"+jsonFile, atomically: true, encoding: .utf8)
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.exportItems] saved to: \(endpointPath)") }
        } catch {
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.exportItems] Problem writing \(endpointPath) folder: Error \(error)") }
        }
    }
    
    func patchmanagement(node: String, object: Any, rawName: String = "", id: String = "", format: String) {
        let saveFolder = saveLocation(format)
        var exportFilename = ""
        
        let endpointPath = saveFolder+node
        if endpointPath != node {
            if !(fm.fileExists(atPath: endpointPath)) {
                do {
                    try fm.createDirectory(atPath: endpointPath, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[ViewController.exportItems] Problem creating \(endpointPath) folder: Error \(error)") }
                    return
                }
            }
            if node == "patchPolicyDetails" {
                exportFilename = "patch-policies-policy-details.json"
            } else {
                if let displayName = (object as? PatchSoftwareTitleConfiguration)?.displayName, let id = (object as? PatchSoftwareTitleConfiguration)?.id {
                    exportFilename = "\(displayName)-\(id).json"
                }
            }
            if !exportFilename.isEmpty {
                export(node, object, endpointPath, exportFilename)
            }
        }
    }
}
