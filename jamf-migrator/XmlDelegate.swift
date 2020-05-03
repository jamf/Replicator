//
//  SaveXml.swift
//  jamf-migrator
//
//  Created by Leslie Helou on 6/28/18.
//  Copyright © 2018 jamf. All rights reserved.
//

import Cocoa
import Foundation

class XmlDelegate: NSURL, URLSessionDelegate {

    let fm = FileManager()
    let baseXmlFolder = NSHomeDirectory() + "/Downloads/Jamf Migrator"
    var saveXmlFolder = ""
    var endpointPath  = ""

    func apiAction(method: String, theServer: String, base64Creds: String, theEndpoint: String, completion: @escaping (_ result: (Int,String)) -> Void) {
        
        if theEndpoint != "skip" {
                    let getRecordQ = OperationQueue()   //DispatchQueue(label: "com.jamf.getRecordQ", qos: DispatchQoS.background)
                
                    URLCache.shared.removeAllCachedResponses()
                    var existingDestUrl = ""
                    
                    existingDestUrl = "\(theServer)/JSSResource/\(theEndpoint)"
                    existingDestUrl = existingDestUrl.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
                    
                    if LogLevel.debug { WriteToLog().message(stringOfText: "[Xml.apiAction] Looking up: \(existingDestUrl)\n") }
//                    print("[Xml.apiAction] existing endpoints URL: \(existingDestUrl)")
                    let destEncodedURL = NSURL(string: existingDestUrl)
                    let xmlRequest     = NSMutableURLRequest(url: destEncodedURL! as URL)
                    
                    let semaphore = DispatchSemaphore(value: 1)
                    getRecordQ.maxConcurrentOperationCount = 3
                    getRecordQ.addOperation {
                        
                        xmlRequest.httpMethod = "\(method.uppercased())"
                        let destConf = URLSessionConfiguration.default
                        destConf.httpAdditionalHeaders = ["Authorization" : "Basic \(base64Creds)", "Content-Type" : "text/xml", "Accept" : "text/xml"]
                        let destSession = Foundation.URLSession(configuration: destConf, delegate: self, delegateQueue: OperationQueue.main)
                        let task = destSession.dataTask(with: xmlRequest as URLRequest, completionHandler: {
                            (data, response, error) -> Void in
                            if let httpResponse = response as? HTTPURLResponse {
            //                    print("[Xml.apiAction] httpResponse: \(String(describing: httpResponse))")
                                if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
                                    do {
                                        let returnedXML = String(data: data!, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!

                                        completion((httpResponse.statusCode,returnedXML))
                                    }
                                } else {
                                    WriteToLog().message(stringOfText: "[Xml.apiAction] error HTTP Status Code: \(httpResponse.statusCode)\n")
            //                        print("[Xml.apiAction] error HTTP Status Code: \(httpResponse.statusCode)\n")
                                    if method != "DELETE" {
                                        completion((httpResponse.statusCode,""))
                                    } else {
                                        completion((httpResponse.statusCode,""))
                                    }
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
        
    
    func save(node: String, xml: String, name: String, id: Int, format: String) {
                
        if LogLevel.debug { WriteToLog().message(stringOfText: "[saveXML] saving \(name), format: \(format), to folder \(node)\n") }
        // Create folder to store xml files if needed - start
        saveXmlFolder = baseXmlFolder+"/"+format
        if !(fm.fileExists(atPath: saveXmlFolder)) {
            do {
                try fm.createDirectory(atPath: saveXmlFolder, withIntermediateDirectories: true, attributes: nil)
            } catch {
                if LogLevel.debug { WriteToLog().message(stringOfText: "[Xml.save] Problem creating \(saveXmlFolder) folder: Error \(error)\n") }
                return
            }
        }
        // Create folder to store xml files if needed - end
        
        // Create endpoint type to store xml files if needed - start
        switch node {
        case "selfservicepolicyicon", "macapplicationsicon", "mobiledeviceapplicationsicon":
            endpointPath = saveXmlFolder+"/"+node+"/\(id)"
        case "jamfgroups":
            endpointPath = saveXmlFolder+"/accounts/groupid"
        case "jamfusers":
            endpointPath = saveXmlFolder+"/accounts/userid"
        default:
            endpointPath = saveXmlFolder+"/"+node
        }
        if !(fm.fileExists(atPath: endpointPath)) {
            do {
                try fm.createDirectory(atPath: endpointPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                if LogLevel.debug { WriteToLog().message(stringOfText: "[Xml.save] Problem creating \(endpointPath) folder: Error \(error)\n") }
                return
            }
        }
        // Create endpoint type to store xml files if needed - end
        
        switch node {
        case "selfservicepolicyicon", "macapplicationsicon", "mobiledeviceapplicationsicon":
            
            let iconSource = "\(xml)"
            let iconDest   = "\(endpointPath)/\(name)"

//            print("copy from \(iconSource) to: \(iconDest)")
            do {
                try fm.copyItem(atPath: iconSource, toPath: iconDest)
//                print("Copied \(iconSource) to: \(iconDest)")
            } catch {
//                print("Problem copying \(iconSource) to: \(iconDest)")
                if LogLevel.debug { WriteToLog().message(stringOfText: "[Xml.save] Problem copying \(iconSource) to: \(iconDest)\n") }
            }
        default:
            let xmlFile = "\(name)-\(id).xml"
            if let xmlDoc = try? XMLDocument(xmlString: xml, options: .nodePrettyPrint) {
                if let _ = try? XMLElement.init(xmlString:"\(xml)") {
                    let data = xmlDoc.xmlData(options:.nodePrettyPrint)
                    let formattedXml = String(data: data, encoding: .utf8)!
                    //                print("policy xml:\n\(formattedXml)")
                    
                    do {
                        try formattedXml.write(toFile: endpointPath+"/"+xmlFile, atomically: true, encoding: .utf8)
                        if LogLevel.debug { WriteToLog().message(stringOfText: "[Xml.save] saved to: \(endpointPath)\n") }
                    } catch {
                        if LogLevel.debug { WriteToLog().message(stringOfText: "[Xml.save] Problem writing \(endpointPath) folder: Error \(error)\n") }
                        return
                    }
                }   // if let prettyXml - end
            }
        }
        
    }   // func save
    
    func encodeSpecialChars(textString: String) -> String {
        
        let newString = textString.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
        
        return newString
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(  URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
}
