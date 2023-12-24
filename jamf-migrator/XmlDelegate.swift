//
//  XmlDelegate.swift
//  jamf-migrator
//
//  Created by Leslie Helou on 6/28/18.
//  Copyright © 2018 jamf. All rights reserved.
//

import Cocoa
import Foundation

class XmlDelegate: NSObject, URLSessionDelegate {

    let fm           = FileManager()
//    let userDefaults = UserDefaults.standard
//    let baseXmlFolder = NSHomeDirectory() + "/Downloads/Jamf Migrator"
    var baseXmlFolder = ""
    var saveXmlFolder = ""
    var endpointPath  = ""
//    let backupDate    = DateFormatter()

    func apiAction(method: String, theServer: String, base64Creds: String, theEndpoint: String, completion: @escaping (_ result: (Int,String)) -> Void) {
        
        if theEndpoint.prefix(4) != "skip" {
            let getRecordQ = OperationQueue()
        
            URLCache.shared.removeAllCachedResponses()
            var existingDestUrl = ""
            
            existingDestUrl = "\(theServer)/JSSResource/\(theEndpoint)"
            existingDestUrl = existingDestUrl.urlFix
//            existingDestUrl = existingDestUrl.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
                    
            if LogLevel.debug { WriteToLog().message(stringOfText: "[Xml.apiAction] Looking up: \(existingDestUrl)\n") }
//                    if "\(existingDestUrl)" == "" { existingDestUrl = "https://localhost" }
            let destEncodedURL = URL(string: existingDestUrl)
            let xmlRequest     = NSMutableURLRequest(url: destEncodedURL! as URL)
            
            let semaphore = DispatchSemaphore(value: 1)
            getRecordQ.maxConcurrentOperationCount = 3
            getRecordQ.addOperation {
                
                xmlRequest.httpMethod = "\(method.uppercased())"
                let destConf = URLSessionConfiguration.default

                destConf.httpAdditionalHeaders = ["Authorization" : "\(JamfProServer.authType["dest"] ?? "Bearer") \(JamfProServer.authCreds["dest"] ?? "")", "Content-Type" : "text/xml", "Accept" : "text/xml", "User-Agent" : AppInfo.userAgentHeader]
                
                // sticky session
                if JamfProServer.sessionCookie.count > 0 && JamfProServer.stickySession {
//                    print("xml sticky session for \(theServer)")
                    URLSession.shared.configuration.httpCookieStorage!.setCookies(JamfProServer.sessionCookie, for: URL(string: theServer), mainDocumentURL: URL(string: theServer))
                }
                
                let destSession = Foundation.URLSession(configuration: destConf, delegate: self, delegateQueue: OperationQueue.main)
                let task = destSession.dataTask(with: xmlRequest as URLRequest, completionHandler: {
                    (data, response, error) -> Void in
                    destSession.finishTasksAndInvalidate()
                    if let httpResponse = response as? HTTPURLResponse {
                        if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
                            do {
                                let returnedXML = String(data: data!, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!

                                completion((httpResponse.statusCode,returnedXML))
                            }
                        } else {
                            WriteToLog().message(stringOfText: "[Xml.apiAction] error HTTP Status Code: \(httpResponse.statusCode)\n")
                            completion((httpResponse.statusCode,""))
                        }
                    } else {
                        WriteToLog().message(stringOfText: "[Xml.apiAction] error getting XML for \(existingDestUrl)\n")
                        completion((0,""))
                    }   // if let httpResponse - end
                    semaphore.signal()
                    if error != nil {
                    }
                })  // let task = destSession - end
                //print("GET")
                task.resume()
            }   // getRecordQ - end
        } else {
            completion((200,""))
        }
    }
        
    
    func save(node: String, xml: String, rawName: String, id: String, format: String) {
        
        var name = rawName.replacingOccurrences(of: ":", with: ";")
        name     = name.replacingOccurrences(of: "/", with: ":")
        if LogLevel.debug { WriteToLog().message(stringOfText: "[XmlDelegate.save] saving \(name), format: \(format), to folder \(node)\n") }
        // Create folder to store xml files if needed - start
        baseXmlFolder = userDefaults.string(forKey: "saveLocation") ?? ""
        if baseXmlFolder == "" {
            baseXmlFolder = (NSHomeDirectory() + "/Downloads/Jamf Migrator/")
        } else {
            baseXmlFolder = baseXmlFolder.pathToString
        }
            
        saveXmlFolder = baseXmlFolder+format+"/"
        
        if !(fm.fileExists(atPath: saveXmlFolder)) {
            do {
                try fm.createDirectory(atPath: saveXmlFolder, withIntermediateDirectories: true, attributes: nil)
            } catch {
                WriteToLog().message(stringOfText: "[XmlDelegate.save] Problem creating \(saveXmlFolder) folder: Error \(error)\n")
                return
            }
        }
        // Create folder to store xml files if needed - end
        
        print("[XmlDelegate] node: \(node)")
        
        
        // Create endpoint type to store xml files if needed - start
        switch node {
        case "selfservicepolicyicon", "macapplicationsicon", "mobiledeviceapplicationsicon":
//            print("[icons] saveFolder: \(saveXmlFolder)")
            endpointPath = saveXmlFolder+node+"/\(id)"
        case "accounts/groupid":
            endpointPath = saveXmlFolder+"jamfgroups"
        case "accounts/userid":
            endpointPath = saveXmlFolder+"jamfusers"
        case "computergroups":
            let isSmart = tagValue2(xmlString: xml, startTag: "<is_smart>", endTag: "</is_smart>")
            if isSmart == "true" {
                endpointPath = saveXmlFolder+"smartcomputergroups"
            } else {
                endpointPath = saveXmlFolder+"staticcomputergroups"
            }
        default:
            endpointPath = saveXmlFolder+node
        }
        if !(fm.fileExists(atPath: endpointPath)) {
            do {
                try fm.createDirectory(atPath: endpointPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                if LogLevel.debug { WriteToLog().message(stringOfText: "[XmlDelegate.save] Problem creating \(endpointPath) folder: Error \(error)\n") }
                return
            }
        }
        // Create endpoint type to store xml files if needed - end
        
        switch node {
        case "selfservicepolicyicon", "macapplicationsicon", "mobiledeviceapplicationsicon":
            
            var copyIcon   = true
            let iconSource = "\(xml)"
//            let iconDest   = (export.backupMode) ? "\(JamfProServer.source.urlToFqdn)_export_\(backupDate.string(from: History.startTime))":"\(endpointPath)/\(name)"
            let iconDest   = "\(endpointPath)/\(name)"

//            print("copy from \(iconSource) to: \(iconDest)")
            if self.fm.fileExists(atPath: iconDest) {
                do {
                    if LogLevel.debug { WriteToLog().message(stringOfText: "[XmlDelegate.save] removing currently saved icon: \(iconDest)\n") }
                    try FileManager.default.removeItem(at: URL(fileURLWithPath: iconDest))
                } catch let error as NSError {
                    if LogLevel.debug { WriteToLog().message(stringOfText: "[XmlDelegate.save] unable to delete cached icon: \(iconDest).  Error \(error).\n") }
                    copyIcon = false
                }
            }
            if copyIcon {
                if LogLevel.debug { WriteToLog().message(stringOfText: "[XmlDelegate.save] saving icon to: \(iconDest)\n") }
                do {
//                    print("[icons] copy to: \(iconDest)")
                    try fm.copyItem(atPath: iconSource, toPath: iconDest)
                    if export.saveOnly {
                        do {
                            if LogLevel.debug { WriteToLog().message(stringOfText: "[XmlDelegate.save] removing cached icon: \(iconSource)/\n") }
                            try FileManager.default.removeItem(at: URL(fileURLWithPath: "\(iconSource)/"))
                        } catch let error as NSError {
                            if LogLevel.debug { WriteToLog().message(stringOfText: "[XmlDelegate.save] unable to delete \(iconSource)/.  Error \(error)\n") }
                        }
                    }
                    
                } catch let error as NSError {
                    if LogLevel.debug { WriteToLog().message(stringOfText: "[XmlDelegate.save] unable to save icon: \(iconDest).  Error \(error).\n") }
                    copyIcon = false
                }
            }
//                print("Copied \(iconSource) to: \(iconDest)")
            
        default:
            let xmlFile = "\(name)-\(id).xml"
            if let xmlDoc = try? XMLDocument(xmlString: xml, options: .nodePrettyPrint) {
                if let _ = try? XMLElement.init(xmlString:"\(xml)") {
                    let data = xmlDoc.xmlData(options:.nodePrettyPrint)
                    var formattedXml = String(data: data, encoding: .utf8)!
                    if node == "scripts" {
                        formattedXml = formattedXml.xmlDecode
                    }
                    //                print("policy xml:\n\(formattedXml)")
                    do {
                        try formattedXml.write(toFile: endpointPath+"/"+xmlFile, atomically: true, encoding: .utf8)
                        if LogLevel.debug { WriteToLog().message(stringOfText: "[XmlDelegate.save] saved to: \(endpointPath)\n") }
                    } catch {
                        if LogLevel.debug { WriteToLog().message(stringOfText: "[XmlDelegate.save] Problem writing \(endpointPath) folder: Error \(error)\n") }
                        return
                    }
                }   // if let prettyXml - end
            }
        }
        
    }   // func save
    
    func encodeSpecialChars(textString: String) -> String {
        
        let newString = textString.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
        
        return newString
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(  URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
}
