//
//  SaveXml.swift
//  jamf-migrator
//
//  Created by Leslie Helou on 6/28/18.
//  Copyright © 2018 jamf. All rights reserved.
//

import Foundation

class Xml {
    let vc = ViewController()
    let fm = FileManager()
    let baseXmlFolder = NSHomeDirectory() + "/Documents/Jamf Migrator"
    var saveXmlFolder = ""
    var endpointPath  = ""
    
    func save(node: String, xml: String, name: String, id: Int, format: String) {
        
        print("[saveXML] saving \(name), format: \(format), to folder \(node)")
        if vc.debug { vc.writeToLog(stringOfText: "[saveXML] saving \(name), format: \(format), to folder \(node)\n") }
        // Create folder to store xml files if needed - start
        saveXmlFolder = baseXmlFolder+"/"+format
        if !(fm.fileExists(atPath: saveXmlFolder)) {
            do {
                try fm.createDirectory(atPath: saveXmlFolder, withIntermediateDirectories: true, attributes: nil)
            } catch {
                if vc.debug { vc.writeToLog(stringOfText: "Problem creating \(saveXmlFolder) folder: Error \(error)\n") }
                return
            }
        }
        // Create folder to store xml files if needed - end
        
        // Create endpoint type to store xml files if needed - start
        switch node {
        case "macapplicationsicon", "mobiledeviceapplicationsicon":
            endpointPath = saveXmlFolder+"/"+node+"/\(id)"
        default:
            endpointPath = saveXmlFolder+"/"+node
        }
        if !(fm.fileExists(atPath: endpointPath)) {
            do {
                try fm.createDirectory(atPath: endpointPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                if vc.debug { vc.writeToLog(stringOfText: "Problem creating \(endpointPath) folder: Error \(error)\n") }
                return
            }
        }
        // Create endpoint type to store xml files if needed - end
        
        switch node {
        case "macapplicationsicon", "mobiledeviceapplicationsicon":
            
            let iconSource = "\(xml)"
            let iconDest   = "\(endpointPath)/\(name)"
//            guard let iconSourceUrl = URL(string: iconSource) else {
//                vc.writeToLog(stringOfText: "Problem converting \(iconSource) to URL\n")
//                return
//            }
//            guard let iconDestUrl = URL(string: iconDest) else {
//                vc.writeToLog(stringOfText: "Problem converting \(iconDest) to URL\n")
//                return
//            }
            print("copy from \(iconSource) to: \(iconDest)")
            do {
                try fm.copyItem(atPath: iconSource, toPath: iconDest)
                print("Copied \(iconSource) to: \(iconDest)")
            } catch {
                print("Problem copying \(iconSource) to: \(iconDest)")
                if vc.debug { vc.writeToLog(stringOfText: "Problem copying \(iconSource) to: \(iconDest)\n") }
            }
        default:
            let xmlFile = "\(name)-\(id).xml"
            if let xmlDoc = try? XMLDocument(xmlString: xml, options: .nodePrettyPrint) {
                if let prettyXml = try? XMLElement.init(xmlString:"\(xml)") {
                    let data = xmlDoc.xmlData(options:.nodePrettyPrint)
                    let formattedXml = String(data: data, encoding: .utf8)!
                    //                print("policy xml:\n\(formattedXml)")
                    
                    do {
                        try formattedXml.write(toFile: endpointPath+"/"+xmlFile, atomically: true, encoding: .utf8)
                    } catch {
                        if vc.debug { vc.writeToLog(stringOfText: "Problem writing \(endpointPath) folder: Error \(error)\n") }
                        return
                    }
                }
            }
        }
        
        // Save endpoint xml - start
//        let readableXml = xml.replacingOccurrences(of: "><", with: ">\n<")

        // Save endpoint xml - end
        
        func trim(rawXml: String, endpoint: String) -> String {
            
            return ""
        }
        
    }
}
