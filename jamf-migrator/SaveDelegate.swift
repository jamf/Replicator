//
//  SaveDelegate.swift
//  jamf-migrator
//
//  Created by Leslie Helou on 12/28/21
//  Copyright © 2018 jamf. All rights reserved
//

import Cocoa
import Foundation

class SaveDelegate: NSObject, URLSessionDelegate {

    let fm           = FileManager()
    let userDefaults = UserDefaults.standard
    var baseFolder = ""
    var saveFolder = ""
    var endpointPath  = ""
 
    func exportObject(node: String, objectString: String, rawName: String, id: String, format: String) {
        
        var name = rawName.replacingOccurrences(of: ":", with: ";")
        name     = name.replacingOccurrences(of: "/", with: ":")
        if LogLevel.debug { WriteToLog().message(stringOfText: "[SaveDelegate.exportObject] saving \(name), format: \(format), to folder \(node)\n") }
        // Create folder to store objectString files if needed - start
//        let saveURL = userDefaults.url(forKey: "saveLocation") ?? nil
        baseFolder = userDefaults.string(forKey: "saveLocation") ?? ""
        if baseFolder == "" {
            baseFolder = (NSHomeDirectory() + "/Downloads/Jamf Migrator/")
        } else {
            baseFolder = baseFolder.replacingOccurrences(of: "file://", with: "")
            baseFolder = baseFolder.replacingOccurrences(of: "%20", with: " ")
        }
            
        saveFolder = baseFolder+format+"/"
        
        if !(fm.fileExists(atPath: saveFolder)) {
            do {
                try fm.createDirectory(atPath: saveFolder, withIntermediateDirectories: true, attributes: nil)
            } catch {
                if LogLevel.debug { WriteToLog().message(stringOfText: "[SaveDelegate.exportObject] Problem creating \(saveFolder) folder: Error \(error)\n") }
                return
            }
        }
        // Create folder to store objectString files if needed - end
        
        print("[SaveDelegate] node: \(node)")
        
        // Create endpoint type to store objectString files if needed - start
        switch node {
        case "selfservicepolicyicon", "macapplicationsicon", "mobiledeviceapplicationsicon":
            endpointPath = saveFolder+node+"/\(id)"
        case "accounts/groupid":
            endpointPath = saveFolder+"jamfgroups"
        case "accounts/userid":
            endpointPath = saveFolder+"jamfusers"
        case "computergroups":
            let isSmart = tagValue2(xmlString: objectString, startTag: "<is_smart>", endTag: "</is_smart>")
            if isSmart == "true" {
                endpointPath = saveFolder+"smartcomptergroups"
            } else {
                endpointPath = saveFolder+"staticcomptergroups"
            }
        default:
            endpointPath = saveFolder+node
        }
        if !(fm.fileExists(atPath: endpointPath)) {
            do {
                try fm.createDirectory(atPath: endpointPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                if LogLevel.debug { WriteToLog().message(stringOfText: "[SaveDelegate.exportObject] Problem creating \(endpointPath) folder: Error \(error)\n") }
                return
            }
        }
        // Create endpoint type to store objectString files if needed - end
        
        switch node {
        case "buildings":
            let jsonFile = "\(name)-\(id).json"
            var jsonString = objectString.dropFirst().dropLast()
            jsonString = "{\(jsonString)}"
            do {
                try jsonString.write(toFile: endpointPath+"/"+jsonFile, atomically: true, encoding: .utf8)
                if LogLevel.debug { WriteToLog().message(stringOfText: "[SaveDelegate.exportObject] saved to: \(endpointPath)\n") }
            } catch {
                if LogLevel.debug { WriteToLog().message(stringOfText: "[SaveDelegate.exportObject] Problem writing \(endpointPath) folder: Error \(error)\n") }
                return
            }

        case "selfservicepolicyicon", "macapplicationsicon", "mobiledeviceapplicationsicon":
            
            var copyIcon   = true
            let iconSource = "\(objectString)"
            let iconDest   = "\(endpointPath)/\(name)"

//            print("copy from \(iconSource) to: \(iconDest)")
            if self.fm.fileExists(atPath: iconDest) {
                do {
                    if LogLevel.debug { WriteToLog().message(stringOfText: "[SaveDelegate.exportObject] removing currently saved icon: \(iconDest)\n") }
                    try FileManager.default.removeItem(at: URL(fileURLWithPath: iconDest))
                }
                catch let error as NSError {
                    if LogLevel.debug { WriteToLog().message(stringOfText: "[SaveDelegate.exportObject] unable to delete cached icon: \(iconDest).  Error \(error).\n") }
                    copyIcon = false
                }
            }
            if copyIcon {
                if LogLevel.debug { WriteToLog().message(stringOfText: "[SaveDelegate.exportObject] saving icon to: \(iconDest)\n") }
                do {
                    try fm.copyItem(atPath: iconSource, toPath: iconDest)
                    if export.saveOnly {
                        do {
                            if LogLevel.debug { WriteToLog().message(stringOfText: "[SaveDelegate.exportObject] removing cached icon: \(iconSource)/\n") }
                            try FileManager.default.removeItem(at: URL(fileURLWithPath: "\(iconSource)/"))
                        }
                        catch let error as NSError {
                            if LogLevel.debug { WriteToLog().message(stringOfText: "[SaveDelegate.exportObject] unable to delete \(iconSource)/.  Error \(error)\n") }
                        }
                    }
                    
                }
                catch let error as NSError {
                    if LogLevel.debug { WriteToLog().message(stringOfText: "[SaveDelegate.exportObject] unable to save icon: \(iconDest).  Error \(error).\n") }
                    copyIcon = false
                }
            }
//                print("Copied \(iconSource) to: \(iconDest)")
            
        default:
            let xmlFile = "\(name)-\(id).xml"
            if let xmlDoc = try? XMLDocument(xmlString: objectString, options: .nodePrettyPrint) {
                if let _ = try? XMLElement.init(xmlString:"\(objectString)") {
                    let data = xmlDoc.xmlData(options:.nodePrettyPrint)
                    let formattedXml = String(data: data, encoding: .utf8)!
                    //                print("policy xml:\n\(formattedXml)")
                    
                    do {
                        try formattedXml.write(toFile: endpointPath+"/"+xmlFile, atomically: true, encoding: .utf8)
                        if LogLevel.debug { WriteToLog().message(stringOfText: "[SaveDelegate.exportObject] saved to: \(endpointPath)\n") }
                    } catch {
                        if LogLevel.debug { WriteToLog().message(stringOfText: "[SaveDelegate.exportObject] Problem writing \(endpointPath) folder: Error \(error)\n") }
                        return
                    }
                }   // if let prettyXml - end
            }
        }
        
    }   // func save
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(  URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
}
