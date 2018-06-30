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
    let xmlFolder = NSHomeDirectory() + "/Documents/Jamf Migrator/xml"
    
    func save(node: String, xml: String, name: String, id: Int) {
        // Create folder to store xml files if needed - start
        if !(fm.fileExists(atPath: xmlFolder)) {
            do {
                try fm.createDirectory(atPath: xmlFolder, withIntermediateDirectories: true, attributes: nil)
            } catch {
                if vc.debug { vc.writeToLog(stringOfText: "Problem creating \(xmlFolder) folder: Error \(error)") }
                return
            }
        }
        // Create folder to store xml files if needed - end
        
        // Create endpoint type to store xml files if needed - start
        let endpointPath = xmlFolder+"/"+node
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
        
    }
}
