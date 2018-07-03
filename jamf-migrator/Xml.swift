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
//    var saveXmlFolder = ""
    
    func save(node: String, xml: String, name: String, id: Int, format: String) {
        // Create folder to store xml files if needed - start
        let saveXmlFolder = baseXmlFolder+"/"+format
        if !(fm.fileExists(atPath: saveXmlFolder)) {
            do {
                try fm.createDirectory(atPath: saveXmlFolder, withIntermediateDirectories: true, attributes: nil)
            } catch {
                if vc.debug { vc.writeToLog(stringOfText: "Problem creating \(saveXmlFolder) folder: Error \(error)") }
                return
            }
        }
        // Create folder to store xml files if needed - end
        
        // Create endpoint type to store xml files if needed - start
        let endpointPath = saveXmlFolder+"/"+node
        if !(fm.fileExists(atPath: endpointPath)) {
            do {
                try fm.createDirectory(atPath: endpointPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                if vc.debug { vc.writeToLog(stringOfText: "Problem creating \(endpointPath) folder: Error \(error)") }
                return
            }
        }
        // Create endpoint type to store xml files if needed - end
        
        // Save endpoint xml - start
        let xmlFile = "\(name)-\(id).xml"
        do {
            try xml.write(toFile: endpointPath+"/"+xmlFile, atomically: true, encoding: .utf8)
        } catch {
            if vc.debug { vc.writeToLog(stringOfText: "Problem writing \(endpointPath) folder: Error \(error)") }
            return
        }
        // Save endpoint xml - end
        
        func trim(rawXml: String, endpoint: String) -> String {
            
            return ""
        }
        
    }
}
