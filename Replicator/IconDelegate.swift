//
//  IconDelegate.swift
//  Replicator
//
//  Created by leslie on 12/1/24.
//  Copyright © 2024 Jamf. All rights reserved.
//

import Foundation
import OSLog

class IconDelegate: NSObject, URLSessionDelegate {
    
    static let shared = IconDelegate()
    
    var updateUiDelegate: UpdateUiDelegate?
    
    let theIconsQ     = OperationQueue() // que to upload/download icons
    let iconHoldQ     = DispatchQueue(label: "com.jamf.iconhold")
    
    var iconDictArray = [String:[[String:String]]]()
    var uploadedIcons = [String:Int]()
    
    @MainActor func icons(endpointType: String, action: String, ssInfo: [String: String], f_createDestUrl: String, responseData: String, sourcePolicyId: String) {
        
        logFunctionCall()
        
        var createDestUrl        = f_createDestUrl
        var iconToUpload         = ""
        var action               = "GET"
        var newSelfServiceIconId = 0
        var iconXml              = ""
        
        let ssIconName           = ssInfo["ssIconName"]!
        let ssIconUri            = ssInfo["ssIconUri"]!
        let ssIconId             = ssInfo["ssIconId"]!
        let ssXml                = ssInfo["ssXml"]!
//        print("[ViewController] ssIconId: \(ssIconId)")

        if (ssIconName != "") && (ssIconUri != "") {
            
            var iconNode     = "policies"
            var iconNodeSave = "selfservicepolicyicon"
            switch endpointType {
            case "macapplications":
                iconNode     = "macapplicationsicon"
                iconNodeSave = "macapplicationsicon"
            case "mobiledeviceapplications":
                iconNode     = "mobiledeviceapplicationsicon"
                iconNodeSave = "mobiledeviceapplicationsicon"
            default:
                break
            }
//          print("new policy id: \(tagValue(xmlString: responseData, xmlTag: "id"))")
//          print("iconName: "+ssIconName+"\tURL: \(ssIconUri)")

            // set icon source
            if fileImport {
                action         = "SKIP"
                let sourcePath = JamfProServer.source.suffix(1) != "/" ? "\(JamfProServer.source)/":JamfProServer.source
                iconToUpload   = "\(sourcePath)\(iconNodeSave)/\(ssIconId)/\(ssIconName)"
            } else {
                iconToUpload = "\(NSHomeDirectory())/Library/Caches/icons/\(ssIconId)/\(ssIconName)"
            }
            
            // set icon destination
            if Setting.csa {
                // cloud connector
                createDestUrl = "\(createDestUrlBase)/v1/icon"
                createDestUrl = createDestUrl.replacingOccurrences(of: "/JSSResource", with: "/api")
            } else {
                createDestUrl = "\(createDestUrlBase)/fileuploads/\(iconNode)/id/\(tagValue(xmlString: responseData, xmlTag: "id"))"
            }
            createDestUrl = createDestUrl.urlFix
            
            // Get or skip icon from Jamf Pro
            if LogLevel.debug { WriteToLog.shared.message("[ViewController.icons] before icon download.") }

            if Iconfiles.pendingDict["\(ssIconId)"] ?? "" != "pending" {
                if Iconfiles.pendingDict["\(ssIconId)"] ?? "" != "ready" {
                    Iconfiles.pendingDict["\(ssIconId)"] = "pending"
                    WriteToLog.shared.message("[ViewController.icons] marking icon for \(iconNode) id \(sourcePolicyId) as pending")
                } else {
                    action = "SKIP"
                }
                
                // download the icon - action = "GET"
                iconMigrate(action: action, ssIconUri: ssIconUri, ssIconId: ssIconId, ssIconName: ssIconName, _iconToUpload: "", createDestUrl: "") {
                    (result: Int) in
//                    print("action: \(action)")
//                    print("Icon url: \(ssIconUri)")
                    if LogLevel.debug { WriteToLog.shared.message("[ViewController.icons] after icon download.") }
                    
                    if result > 199 && result < 300 {
                        if LogLevel.debug { WriteToLog.shared.message("[ViewController.icons] retuned from icon id \(ssIconId) GET with result: \(result)") }
//                        print("\ncreateDestUrl: \(createDestUrl)")

                        if LogLevel.debug { WriteToLog.shared.message("[ViewController.icons] retrieved icon from \(ssIconUri)") }
                        if export.saveRawXml || export.saveTrimmedXml {
                            var saveFormat = export.saveRawXml ? "raw":"trimmed"
                            if export.backupMode {
                                saveFormat = "\(JamfProServer.source.fqdnFromUrl)_export_\(backupDate.string(from: History.startTime))"
                            }
                            if LogLevel.debug { WriteToLog.shared.message("[ViewController.icons] saving icon: \(ssIconName) for \(iconNode).") }
                            DispatchQueue.main.async {
                                XmlDelegate.shared.save(node: iconNodeSave, xml: "\(NSHomeDirectory())/Library/Caches/icons/\(ssIconId)/\(ssIconName)", rawName: ssIconName, id: ssIconId, format: "\(saveFormat)")
                            }
                        }   // if export.saveRawXml - end
                        // upload icon if not in export only mode
                        if !export.saveOnly {
                            
                            // see if the icon has been downloaded
//                            if iconfiles.policyDict["\(ssIconId)"]?["policyId"] == nil || iconfiles.policyDict["\(ssIconId)"]?["policyId"] == "" {
                            let downloadedIcon = Iconfiles.policyDict["\(ssIconId)"]?["policyId"]
                            if downloadedIcon?.fixOptional == nil || downloadedIcon?.fixOptional == "" {
//                                print("[ViewController.icons] iconfiles.policyDict value for icon id \(ssIconId.fixOptional): \(String(describing: iconfiles.policyDict["\(ssIconId)"]?["policyId"]))")
                                Iconfiles.policyDict["\(ssIconId)"] = ["policyId":"", "destinationIconId":""]
                                if LogLevel.debug { WriteToLog.shared.message("[ViewController.icons] upload icon (id=\(ssIconId)) to: \(createDestUrl)") }
//                                        print("createDestUrl: \(createDestUrl)")
                                if LogLevel.debug { WriteToLog.shared.message("[ViewController.icons] POST icon (id=\(ssIconId)) to: \(createDestUrl)") }
                                
                                self.iconMigrate(action: "POST", ssIconUri: "", ssIconId: ssIconId, ssIconName: ssIconName, _iconToUpload: "\(iconToUpload)", createDestUrl: createDestUrl) {
                                        (iconMigrateResult: Int) in

                                        if LogLevel.debug { WriteToLog.shared.message("[ViewController.icons] result of icon POST: \(iconMigrateResult).") }
                                        // verify icon uploaded successfully
                                        if iconMigrateResult != 0 {
                                            // associate self service icon to new policy id
                                            if LogLevel.debug { WriteToLog.shared.message("[ViewController.icons] source icon (id=\(ssIconId)) successfully uploaded and has id=\(iconMigrateResult).") }

//                                            iconfiles.policyDict["\(ssIconId)"] = ["policyId":"\(iconMigrateResult)", "destinationIconId":""]
                                            Iconfiles.policyDict["\(ssIconId)"]?["policyId"]          = "\(iconMigrateResult)"
                                            Iconfiles.policyDict["\(ssIconId)"]?["destinationIconId"] = ""
                                            
                                            
                                            if LogLevel.debug { WriteToLog.shared.message("[ViewController.icons] future usage of source icon id \(ssIconId) should reference new policy id \(iconMigrateResult) for the icon id") }
//                                            print("iconfiles.policyDict[\(ssIconId)]: \(String(describing: iconfiles.policyDict["\(ssIconId)"]!))")
                                            
                                            usleep(100)

                                            // removed cached icon
                                            if fm.fileExists(atPath: "\(NSHomeDirectory())/Library/Caches/icons/\(ssIconId)/") {
                                                do {
                                                    if LogLevel.debug { WriteToLog.shared.message("[ViewController.icons] removing cached icon: \(NSHomeDirectory())/Library/Caches/icons/\(ssIconId)/") }
                                                    try FileManager.default.removeItem(at: URL(fileURLWithPath: "\(NSHomeDirectory())/Library/Caches/icons/\(ssIconId)/"))
                                                }
                                                catch let error as NSError {
                                                    if LogLevel.debug { WriteToLog.shared.message("[ViewController.icons] unable to delete \(NSHomeDirectory())/Library/Caches/icons/\(ssIconId)/.  Error \(error).") }
                                                }
                                            }
                                            
                                            if Setting.csa {
                                                switch endpointType {
                                                case "policies":
                                                    iconXml = "<?xml version='1.0' encoding='UTF-8' standalone='yes'?><policy><self_service>\(ssXml)<self_service_icon><id>\(iconMigrateResult)</id></self_service_icon></self_service></policy>"
                                                case "mobiledeviceapplications":
//                                                    let newAppIcon = iconfiles.policyDict["\(ssIconId)"]?["policyId"] ?? "0"
                                                    iconXml = "<?xml version='1.0' encoding='UTF-8' standalone='yes'?><mobile_device_application><general><icon><id>\(iconMigrateResult)</id><name>\(ssIconName)</name><uri>\(ssIconUri)</uri></icon></general></mobile_device_application>"
                                                default:
                                                    break
                                                }
                                                
                                                let policyUrl = "\(createDestUrlBase)/\(endpointType)/id/\(tagValue(xmlString: responseData, xmlTag: "id"))"
                                                self.iconMigrate(action: "PUT", ssIconUri: "", ssIconId: ssIconId, ssIconName: "", _iconToUpload: iconXml, createDestUrl: policyUrl) {
                                                    (result: Int) in
                                                
                                                    if result > 199 && result < 300 {
                                                        if LogLevel.debug { WriteToLog.shared.message("[ViewController.icons] successfully updated policy (id: \(tagValue(xmlString: responseData, xmlTag: "id"))) with icon id \(iconMigrateResult)") }
//                                                        print("successfully used new icon id \(newSelfServiceIconId)")
                                                    }
                                                }
                                                
                                            }
                                        } else {
                                            // icon failed to upload
                                            if LogLevel.debug { WriteToLog.shared.message("[ViewController.icons] source icon (id=\(ssIconId)) failed to upload") }
                                            Iconfiles.policyDict["\(ssIconId)"] = ["policyId":"", "destinationIconId":""]
                                        }

                                    }
                            
                            } else {    // if !(iconfiles.policyDict["\(ssIconId)"]?["policyId"] == nil - else
                                // icon has been downloaded
//                                print("already defined icon/policy icon id \(ssIconId)")
//                                print("iconfiles.policyDict: \(String(describing: iconfiles.policyDict["\(ssIconId)"]!["policyID"]))")
//                                while iconfiles.policyDict["\(ssIconId)"]!["policyID"] == "-1" || iconfiles.policyDict["\(ssIconId)"]!["policyID"] != nil {
//                                    sleep(1)
//                                    print("waiting for icon id \(ssIconId)")
//                                }

                                // destination policy to upload icon to
                                let thePolicyID = "\(tagValue(xmlString: responseData, xmlTag: "id"))"
                                let policyUrl   = "\(createDestUrlBase)/\(endpointType)/id/\(thePolicyID)"
//                                print("\n[ViewController.icons] iconfiles.policyDict value for icon id \(ssIconId.fixOptional): \(String(describing: iconfiles.policyDict["\(ssIconId)"]?["policyId"]))")
//                                print("[ViewController.icons] policyUrl: \(policyUrl)")
                                
                                if Iconfiles.policyDict["\(ssIconId.fixOptional)"]!["destinationIconId"]! == "" {
                                    if LogLevel.debug { WriteToLog.shared.message("[ViewController.icons] getting downloaded icon id from destination server, policy id: \(String(describing: Iconfiles.policyDict["\(ssIconId.fixOptional)"]!["policyId"]!))") }
                                    var policyIconDict = Iconfiles.policyDict

                                    Json.shared.getRecord(whichServer: "dest", base64Creds: JamfProServer.base64Creds["dest"] ?? "", theEndpoint: "\(endpointType)/id/\(thePolicyID)/subset/SelfService")  {
                                        (objectRecord: Any) in
                                        let result = objectRecord as? [String: AnyObject] ?? [:]
//                                        print("[icons] result of Json().getRecord: \(result)")
                                        if LogLevel.debug { WriteToLog.shared.message("[ViewController.icons] Returned from Json.getRecord.  Retreived Self Service info.") }
                                        
//                                        if !setting.csa {
                                            if result.count > 0 {
                                                let theKey = (endpointType == "policies") ? "policy":"mobile_device_application"
                                                let selfServiceInfoDict = result[theKey]?["self_service"] as! [String:Any]
//                                                print("[icons] selfServiceInfoDict: \(selfServiceInfoDict)")
                                                let selfServiceIconDict = selfServiceInfoDict["self_service_icon"] as! [String:Any]
                                                newSelfServiceIconId = selfServiceIconDict["id"] as? Int ?? 0
                                                
                                                if newSelfServiceIconId != 0 {
                                                    policyIconDict["\(ssIconId)"]!["destinationIconId"] = "\(newSelfServiceIconId)"
                                                    Iconfiles.policyDict = policyIconDict
            //                                        iconfiles.policyDict["\(ssIconId)"]!["destinationIconId"] = "\(newSelfServiceIconId)"
                                                    if LogLevel.debug { WriteToLog.shared.message("[ViewController.icons] Returned from Json.getRecord: \(result)") }
                                                                                            
                                                    iconXml = "<?xml version='1.0' encoding='UTF-8' standalone='yes'?><policy><self_service>\(ssXml)<self_service_icon><id>\(newSelfServiceIconId)</id></self_service_icon></self_service></policy>"
                                                } else {
                                                    WriteToLog.shared.message("[ViewController.icons] Unable to locate icon on destination server for: policies/id/\(thePolicyID)")
                                                    iconXml = "<?xml version='1.0' encoding='UTF-8' standalone='yes'?><policy><self_service>\(ssXml)<self_service_icon></self_service_icon></self_service></policy>"
                                                }
                                            } else {
                                                iconXml = "<?xml version='1.0' encoding='UTF-8' standalone='yes'?><policy><self_service>\(ssXml)<self_service_icon></self_service_icon></self_service></policy>"
                                            }
                                        
                                            self.iconMigrate(action: "PUT", ssIconUri: "", ssIconId: ssIconId, ssIconName: "", _iconToUpload: iconXml, createDestUrl: policyUrl) {
                                            (result: Int) in
                                                if LogLevel.debug { WriteToLog.shared.message("[ViewController.icons] after updating policy with icon id.") }
                                            
                                                if result > 199 && result < 300 {
                                                    WriteToLog.shared.message("[ViewController.icons] successfully used new icon id \(newSelfServiceIconId)")
                                                }
                                            }
//                                        }
                                        
                                    }
                                } else {
                                    WriteToLog.shared.message("[ViewController.icons] using new icon id from destination server")
                                    newSelfServiceIconId = Int(Iconfiles.policyDict["\(ssIconId)"]!["destinationIconId"]!) ?? 0
                                    
                                        switch endpointType {
                                        case "policies":
                                            iconXml = "<?xml version='1.0' encoding='UTF-8' standalone='yes'?><policy><self_service>\(ssXml)<self_service_icon><id>\(newSelfServiceIconId)</id></self_service_icon></self_service></policy>"
                                        case "mobiledeviceapplications":
//                                                    let newAppIcon = iconfiles.policyDict["\(ssIconId)"]?["policyId"] ?? "0"
                                            iconXml = "<?xml version='1.0' encoding='UTF-8' standalone='yes'?><mobile_device_application><general><icon><id>\(newSelfServiceIconId)</id><uri>\(ssIconUri)</uri></icon></general></mobile_device_application>"
                                        default:
                                            break
                                        }
                                    
                                    iconXml = "<?xml version='1.0' encoding='UTF-8' standalone='yes'?><policy><self_service><self_service_icon><id>\(newSelfServiceIconId)</id></self_service_icon></self_service></policy>"
        //                                            print("iconXml: \(iconXml)")
                                    self.iconMigrate(action: "PUT", ssIconUri: "", ssIconId: ssIconId, ssIconName: "", _iconToUpload: iconXml, createDestUrl: policyUrl) {
                                        (result: Int) in
                                            if LogLevel.debug { WriteToLog.shared.message("[CreateEndpoints.icon] after updating policy with icon id.") }
                                        
                                            if result > 199 && result < 300 {
                                                WriteToLog.shared.message("[ViewController.icons] successfully used new icon id \(newSelfServiceIconId)")
                                            }
                                        }
                                }
                            }
                        }  // if !export.saveOnly - end
                    } else {
                        if LogLevel.debug { WriteToLog.shared.message("[CreateEndpoints.icon] failed to retrieved icon from \(ssIconUri).") }
                    }
                }   // iconMigrate - end
                
            } else {
                // hold processing already used icon until it's been uploaded to the new server
                if !export.saveOnly {
                    if LogLevel.debug { WriteToLog.shared.message("[CreateEndpoints.icon] sending policy id \(sourcePolicyId) to icon queue while icon id \(ssIconId) is processed") }
                    iconMigrationHold(ssIconId: "\(ssIconId)", newIconDict: ["endpointType": endpointType, "action": action, "ssIconId": "\(ssIconId)", "ssIconName": ssIconName, "ssIconUri": ssIconUri, "f_createDestUrl": f_createDestUrl, "responseData": responseData, "sourcePolicyId": sourcePolicyId])
                }
            }//                }   // if !(iconfiles.policyDict["\(ssIconId)"]?["policyId"] - end
        }   // if (ssIconName != "") && (ssIconUri != "") - end
    }   // func icons - end
    
    @MainActor private func iconMigrate(action: String, ssIconUri: String, ssIconId: String, ssIconName: String, _iconToUpload: String, createDestUrl: String, completion: @escaping (Int) -> Void) {
        
        logFunctionCall()
        
        // fix id/hash being passed as optional
        let iconToUpload = _iconToUpload.fixOptional
        var curlResult   = 0
//        print("[ViewController] iconToUpload: \(iconToUpload)")
        
        var moveIcon     = true
        var savedURL:URL!
        
        iconNotification()

        switch action {
        case "GET":

//            print("checking iconfiles.policyDict[\(ssIconId)]: \(String(describing: iconfiles.policyDict["\(ssIconId)"]))")
                Iconfiles.policyDict["\(ssIconId)"] = ["policyId":"", "destinationIconId":""]
//                print("icon id \(ssIconId) is marked for download/cache")
                WriteToLog.shared.message("[iconMigrate.\(action)] fetching icon: \(ssIconUri)")
                // https://developer.apple.com/documentation/foundation/url_loading_system/downloading_files_from_websites
                let url = URL(string: "\(ssIconUri)")!
                            
                let downloadTask = URLSession.shared.downloadTask(with: url) {
                    urlOrNil, responseOrNil, errorOrNil in
                    // check for and handle errors:
                    // * errorOrNil should be nil
                    // * responseOrNil should be an HTTPURLResponse with statusCode in 200..<299
                    // create folder to download/cache icon if it doesn't exist
                    URLSession.shared.finishTasksAndInvalidate()
                    do {
                        let documentsURL = try
                            FileManager.default.url(for: .libraryDirectory,
                                                    in: .userDomainMask,
                                                    appropriateFor: nil,
                                                    create: false)
                        savedURL = documentsURL.appendingPathComponent("Caches/icons/\(ssIconId)/")
                        
                        if !(fm.fileExists(atPath: savedURL.path)) {
                            do {if LogLevel.debug { WriteToLog.shared.message("[iconMigrate.\(action)] creating \(savedURL.path) folder to cache icon") }
                                try fm.createDirectory(atPath: savedURL.path, withIntermediateDirectories: true, attributes: nil)
//                                usleep(1000)
                            } catch {
                                if LogLevel.debug { WriteToLog.shared.message("[iconMigrate.\(action)] problem creating \(savedURL.path) folder: Error \(error)") }
                                moveIcon = false
                            }
                        }
                    } catch {
                        if LogLevel.debug { WriteToLog.shared.message("[iconMigrate.\(action)] failed to set cache location: Error \(error)") }
                    }
                    
                    guard let fileURL = urlOrNil else { return }
                    do {
                        if moveIcon {
                            if LogLevel.debug { WriteToLog.shared.message("[iconMigrate.\(action)] saving icon to \(savedURL.appendingPathComponent("\(ssIconName)"))") }
                            if !FileManager.default.fileExists(atPath: savedURL.appendingPathComponent("\(ssIconName)").path) {
                                try FileManager.default.moveItem(at: fileURL, to: savedURL.appendingPathComponent("\(ssIconName)"))
                            }
                            
                            // Mark the icon as cached
                            if LogLevel.debug { WriteToLog.shared.message("[iconMigrate.\(action)] icon id \(ssIconId) is downloaded/cached to \(savedURL.appendingPathComponent("\(ssIconName)"))") }
//                            usleep(100)
                        }
                    } catch {
                        WriteToLog.shared.message("[iconMigrate.\(action)] Problem moving icon: Error \(error)")
                    }
                    let curlResponse = responseOrNil as! HTTPURLResponse
                    curlResult = curlResponse.statusCode
                    if LogLevel.debug { WriteToLog.shared.message("[iconMigrate.\(action)] result of Swift icon GET: \(curlResult).") }
                    completion(curlResult)
                }
                downloadTask.resume()
                // swift file download - end
            
        case "POST":
            if uploadedIcons[ssIconId.fixOptional] == nil || Setting.csa {
                // upload icon to fileuploads endpoint / icon server
                WriteToLog.shared.message("[iconMigrate.\(action)] sending icon: \(ssIconName)")
               
                var fileURL: URL!
                
                fileURL = URL(fileURLWithPath: iconToUpload)

                let boundary = "----WebKitFormBoundary\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"

                var httpResponse:HTTPURLResponse?
                var statusCode = 0
                
                theIconsQ.maxConcurrentOperationCount = 2
                let semaphore = DispatchSemaphore(value: 0)
                
                    self.theIconsQ.addOperation {

                        WriteToLog.shared.message("[iconMigrate.\(action)] uploading icon: \(iconToUpload)")

                        let startTime = Date()
                        var postData  = Data()
                        var newId     = 0
                        
    //                    WriteToLog.shared.message("[iconMigrate.\(action)] fileURL: \(String(describing: fileURL!))")
                        let fileType = NSURL(fileURLWithPath: "\(String(describing: fileURL!))").pathExtension
                    
                        WriteToLog.shared.message("[iconMigrate.\(action)] uploading \(ssIconName)")
                        
                        let serverURL = URL(string: createDestUrl)!
                        WriteToLog.shared.message("[iconMigrate.\(action)] uploading to: \(createDestUrl)")
                        
                        let sessionConfig = URLSessionConfiguration.default
                        let session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: OperationQueue.main)
                        
                        var request = URLRequest(url:serverURL)
                        request.addValue("\(String(describing: JamfProServer.authType["dest"] ?? "Bearer")) \(String(describing: JamfProServer.authCreds["dest"] ?? ""))", forHTTPHeaderField: "Authorization")
                        request.addValue("\(AppInfo.userAgentHeader)", forHTTPHeaderField: "User-Agent")
                        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                        
                        // prep the data for uploading
                        do {
                            postData.append("------\(boundary)\r\n".data(using: .utf8)!)
                            postData.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(ssIconName)\"\r\n".data(using: .utf8)!)
                            postData.append("Content-Type: image/\(fileType ?? "png")\r\n\r\n".data(using: .utf8)!)
                            let fileData = try Data(contentsOf:fileURL, options:[])
                            postData.append(fileData)

                            let closingBoundary = "\r\n--\(boundary)--\r\n"
                            if let d = closingBoundary.data(using: .utf8) {
                                postData.append(d)
                                WriteToLog.shared.message("[iconMigrate.\(action)] loaded \(ssIconName) to data.")
                            }
                            let dataLen = postData.count
                            request.addValue("\(dataLen)", forHTTPHeaderField: "Content-Length")
                            
                        } catch {
                            WriteToLog.shared.message("[iconMigrate.\(action)] unable to get file: \(iconToUpload)")
                        }

                        request.httpBody   = postData
                        request.httpMethod = action
                        
                        // start upload process
                        URLCache.shared.removeAllCachedResponses()
                        let task = session.dataTask(with: request, completionHandler: { [self] (data, response, error) -> Void in
                            defer { semaphore.signal() }
                            session.finishTasksAndInvalidate()
            //                if let httpResponse = response as? HTTPURLResponse {
                            if let _ = (response as? HTTPURLResponse)?.statusCode {
                                httpResponse = response as? HTTPURLResponse
                                statusCode = httpResponse!.statusCode
                                WriteToLog.shared.message("[iconMigrate.\(action)] \(ssIconName) - Response from server - Status code: \(statusCode)")
                                WriteToLog.shared.message("[iconMigrate.\(action)] Response data string: \(String(data: data!, encoding: .utf8)!)")
                            } else {
                                WriteToLog.shared.message("[iconMigrate.\(action)] \(ssIconName) - No response from the server.")
                                
                                completion(statusCode)
                            }

                            switch statusCode {
                            case 200, 201:
                                WriteToLog.shared.message("[iconMigrate.\(action)] file successfully uploaded.")
                                if let dataResponse = String(data: data!, encoding: .utf8) {
    //                                print("[ViewController.iconMigrate] dataResponse: \(dataResponse)")
                                    if Setting.csa {
                                        let jsonResponse = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String:Any]
                                        if let _ = jsonResponse?["id"] as? Int {
                                            newId = jsonResponse?["id"] as? Int ?? 0
                                        }
                                        
                                        uploadedIcons[ssIconId.fixOptional] = newId
                                        
                                    } else {
                                        newId = Int(tagValue2(xmlString: dataResponse, startTag: "<id>", endTag: "</id>")) ?? 0
                                    }
                                }
                                Iconfiles.pendingDict["\(ssIconId.fixOptional)"] = "ready"
                            case 401:
                                WriteToLog.shared.message("[iconMigrate.\(action)] **** Authentication failed.")
                            case 404:
                                WriteToLog.shared.message("[iconMigrate.\(action)] **** server / file not found.")
                            default:
                                WriteToLog.shared.message("[iconMigrate.\(action)] **** unknown error occured.")
                                WriteToLog.shared.message("[iconMigrate.\(action)] **** Error took place while uploading a file.")
                            }

                            let endTime = Date()
                            let components = Calendar.current.dateComponents([.second], from: startTime, to: endTime)

                            let timeDifference = Int(components.second!)
                            let (h,r) = timeDifference.quotientAndRemainder(dividingBy: 3600)
                            let (m,s) = r.quotientAndRemainder(dividingBy: 60)

                            WriteToLog.shared.message("[iconMigrate.\(action)] upload time: \(Utilities.shared.dd(value: h)):\(Utilities.shared.dd(value: m)):\(Utilities.shared.dd(value: s)) (h:m:s)")
                            
                            iconNotification()

                            completion(newId)
                            // upload checksum - end
                        })   // let task = session - end

    //                    let uploadObserver = task.progress.observe(\.fractionCompleted) { progress, _ in
    //                        let uploadPercentComplete = (round(progress.fractionCompleted*1000)/10)
    //                    }
                        task.resume()
                        semaphore.wait()
    //                    NotificationCenter.default.removeObserver(uploadObserver)
                    }   // theUploadQ.addOperation - end
            } else {
//                if let _ = uploadedIcons[ssIconId.fixOptional] {
                    completion(uploadedIcons[ssIconId.fixOptional]!)
//                } else {
//                    completion(0)
//                }
            }
            
        case "PUT":
            
            WriteToLog.shared.message("[iconMigrate.\(action)] setting icon for \(createDestUrl)")
            
//            theIconsQ.maxConcurrentOperationCount = 2
            let semaphore    = DispatchSemaphore(value: 0)
            let encodedXML   = iconToUpload.data(using: String.Encoding.utf8)
             
            SendQueue.shared.addOperation {
//            self.theIconsQ.addOperation {
            
                let encodedURL = URL(string: createDestUrl)
                let request = NSMutableURLRequest(url: encodedURL! as URL)

                request.httpMethod = action
               
                let configuration = URLSessionConfiguration.default

                configuration.httpAdditionalHeaders = ["Authorization" : "\(JamfProServer.authType["dest"] ?? "Bearer") \(JamfProServer.authCreds["dest"] ?? "")", "Content-Type" : "text/xml", "Accept" : "text/xml", "User-Agent" : AppInfo.userAgentHeader]
                
                var headers = [String: String]()
                for (header, value) in configuration.httpAdditionalHeaders ?? [:] {
                    headers[header as! String] = (header as! String == "Authorization") ? "Bearer ************" : value as? String
                }
                print("[apiCall] \(#function.description) method: \(request.httpMethod)")
                print("[apiCall] \(#function.description) headers: \(headers)")
                print("[apiCall] \(#function.description) endpoint: \(encodedURL?.absoluteString ?? "")")
                print("")
        
                request.httpBody = encodedXML!
                let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
                let task = session.dataTask(with: request as URLRequest, completionHandler: { [self]
                    (data, response, error) -> Void in
                    defer { semaphore.signal() }
                    session.finishTasksAndInvalidate()
                    if let httpResponse = response as? HTTPURLResponse {
                        
                            if httpResponse.statusCode > 199 && httpResponse.statusCode <= 299 {
                                WriteToLog.shared.message("[iconMigrate.\(action)] icon updated on \(createDestUrl)")
//                                WriteToLog.shared.message("[iconMigrate.\(action)] posted xml: \(iconToUpload)")
                            } else {
                                WriteToLog.shared.message("[iconMigrate.\(action)] **** error code: \(httpResponse.statusCode) failed to update icon on \(createDestUrl)")
                                if LogLevel.debug { WriteToLog.shared.message("[iconMigrate.\(action)] posted xml: \(iconToUpload)") }
//                                print("[iconMigrate.\(action)] iconToUpload: \(iconToUpload)")
                                
                            }
                        completion(httpResponse.statusCode)
                    } else {   // if let httpResponse = response - end
                        WriteToLog.shared.message("[iconMigrate.\(action)] no response from server")
                        completion(0)
                    }
                    
                    if LogLevel.debug { WriteToLog.shared.message("[iconMigrate.\(action)] POST or PUT Operation: \(request.httpMethod)") }
                    
                    iconNotification()
                })
                task.resume()
                semaphore.wait()
            }   // theUploadQ.addOperation - end
            // end upload procdess
                    
                        
        default:
            WriteToLog.shared.message("[iconMigrate.\(action)] skipping icon: \(ssIconName).")
            completion(200)
        }
     
    }
    
    private func iconNotification() {
        logFunctionCall()
        DispatchQueue.main.async { [self] in
            if Setting.fullGUI {
                updateUiDelegate?.updateUi(info: ["function": "uploadingIcons_textfield", "isHidden": (theIconsQ.operationCount > 0) ? false:true])
//                uploadingIcons_textfield.isHidden = (theIconsQ.operationCount > 0) ? false:true
//                uploadingIcons2_textfield.isHidden = (theIconsQ.operationCount > 0) ? false:true
            }
            if migrationComplete.isDone == true && theIconsQ.operationCount == 0 {
                updateUiDelegate?.updateUi(info: ["function": "runComplete"])
//                runComplete()
            }
        }
    }
    
    // hold icon migrations while icon is being cached/uploaded to the new server
    private func iconMigrationHold(ssIconId: String, newIconDict: [String:String]) {
        logFunctionCall()
        if iconDictArray["\(ssIconId)"] == nil {
            iconDictArray["\(ssIconId)"] = [newIconDict]
            if LogLevel.debug { WriteToLog.shared.message("[ViewController.iconMigration] first entry for iconDictArray[\(ssIconId)]: \(newIconDict)") }
        } else {
            iconDictArray["\(ssIconId)"]?.append(contentsOf: [newIconDict])
            if LogLevel.debug { WriteToLog.shared.message("[ViewController.iconMigration] updated iconDictArray[\(ssIconId)]: \(String(describing: iconDictArray["\(ssIconId)"]))") }
        }
        iconHoldQ.async {
            while Iconfiles.pendingDict.count > 0 {
                if pref.stopMigration {
                    break
                }
                sleep(1)
                for (iconId, state) in Iconfiles.pendingDict {
                    if (state == "ready") {
                        if let _ = self.iconDictArray["\(iconId)"] {
                            for iconDict in self.iconDictArray["\(iconId)"]! {
                                if let endpointType = iconDict["endpointType"], let action = iconDict["action"], let ssIconName = iconDict["ssIconName"], let ssIconUri = iconDict["ssIconUri"], let f_createDestUrl = iconDict["f_createDestUrl"], let responseData = iconDict["responseData"], let sourcePolicyId = iconDict["sourcePolicyId"] {
                                
//                                    let ssIconUriArray = ssIconUri.split(separator: "/")
//                                    let ssIconId = String("\(ssIconUriArray.last)")
                                    let ssIconId = getIconId(iconUri: ssIconUri, endpoint: endpointType)
                                    
                                    let ssInfo: [String: String] = ["ssIconName": ssIconName, "ssIconId": ssIconId, "ssIconUri": ssIconUri, "ssXml": ""]
                                    self.icons(endpointType: endpointType, action: action, ssInfo: ssInfo, f_createDestUrl: f_createDestUrl, responseData: responseData, sourcePolicyId: sourcePolicyId)
                                }
                            }
                            self.iconDictArray.removeValue(forKey: iconId)
                        }
                    } else {
//                        print("waiting for icon id \(iconId) to become ready (uploaded to destination server)")
                        if LogLevel.debug { WriteToLog.shared.message("[ViewController.iconMigration] waiting for icon id \(iconId) to become ready (uploaded to destination server)") }
                    }
                }   // for (pending, state) - end
            }   // while - end
        }   // DispatchQueue.main.async - end
    }
    
}
