//
//  EndpointXml.swift
//  Replicator
//
//  Copyright © 2024 Jamf. All rights reserved.
//

import Foundation

class EndpointXml: NSObject, URLSessionDelegate {
    
    static let shared = EndpointXml()
    
    var getStatusDelegate: GetStatusDelegate?
    func sendGetStatus(endpoint: String, total: Int, index: Int) {
        print("[EndpointXml] call updateGetStatus")
        getStatusDelegate?.updateGetStatus(endpoint: endpoint, total: total, index: index)
    }
    var updateUiDelegate: UpdateUiDelegate?
    
    let endpointXmlQ = DispatchQueue(label: "com.jamf.endpointXml", qos: DispatchQoS.utility)
    let endpointsIdQ = OperationQueue() // create operation queue for API calls
    var getArray     = [ObjectInfo]()
    
    func endPointByIdQueue(endpoint: String, endpointID: String, endpointCurrent: Int, endpointCount: Int, action: String, destEpId: Int, destEpName: String) {
        
        endpointXmlQ.async { [self] in
            
            print("[EndpointXml.endPointByIDQueue] queue \(endpoint) with name \(destEpName) for get")
            getArray.append(ObjectInfo(endpointType: endpoint, endPointXml: "", endPointJSON: [:], endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, sourceEpId: Int(endpointID)!, destEpId: "\(destEpId)", ssIconName: destEpName, ssIconId: "", ssIconUri: "", retry: false))
            
            while Counter.shared.pendingGet > 0 || getArray.count > 0 {
//                print("[endPointByIDQueue] Counter.shared.pendingGet: \(Counter.shared.pendingGet)")
                if Counter.shared.pendingGet < maxConcurrentThreads && getArray.count > 0 {
                    Counter.shared.pendingGet += 1
                    let nextEndpoint = getArray[0]
                    getArray.remove(at: 0)
                    
                    getById(endpoint: nextEndpoint.endpointType, endpointID: "\(nextEndpoint.sourceEpId)", endpointCurrent: nextEndpoint.endpointCurrent, endpointCount: nextEndpoint.endpointCount, action: nextEndpoint.action, destEpId: nextEndpoint.destEpId, destEpName: nextEndpoint.ssIconName) {
                            (result: String) in
                        Counter.shared.pendingGet -= 1
                    }
                } else {
//                    sleep(1)
                    usleep(5000)
                }
            }
        }
    }
    
    func getById(endpoint: String, endpointID: String, endpointCurrent: Int, endpointCount: Int, action: String, destEpId: String, destEpName: String, completion: @escaping (_ result: String) -> Void) {
        
        URLCache.shared.removeAllCachedResponses()
        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[getById] endpoint passed to endPointByID: \(endpoint) id \(endpointID)") }
        
        endpointsIdQ.maxConcurrentOperationCount = maxConcurrentThreads
        
        var localEndPointType = ""
//        var theEndpoint       = endpoint
        
        switch endpoint {
//      adjust the lookup endpoint
        case "smartcomputergroups", "staticcomputergroups":
            localEndPointType = "computergroups"
        case "smartmobiledevicegroups", "staticmobiledevicegroups":
            localEndPointType = "mobiledevicegroups"
        case "smartusergroups", "staticusergroups":
            localEndPointType = "usergroups"
//      adjust the where the data is sent
        case "accounts/userid":
            localEndPointType = "jamfusers"
        case "accounts/groupid":
            localEndPointType = "jamfgroups"
//        case "patch-software-title-configurations":
//            localEndPointType = "patch-software-title-configurations"
        default:
            localEndPointType = endpoint
        }

        // split queries between classic and Jamf Pro API
        switch localEndPointType {
        case "buildings":
            // Jamf Pro API
                endpointsIdQ.addOperation {
                    
                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[getById] fetching JSON for: \(localEndPointType) with id: \(endpointID)") }
            Jpapi.shared.action(whichServer: "source", endpoint: localEndPointType, apiData: [:], id: "\(endpointID)", token: JamfProServer.authCreds["source"]!, method: "GET" ) { [self]
                        (returnedJSON: [String:Any]) in
                        completion(destEpName)
//                                if statusCode == 202 {
//                                    print("[getById] \(#line) returnedJSON: \(returnedJSON)")
//                                }
                        //                        print("returnedJSON: \(returnedJSON)")
                        if returnedJSON.count > 0 {
                            sendGetStatus(endpoint: endpoint, total: endpointCount, index: -1)
//                                    self.getStatusUpdate2(endpoint: endpoint, total: endpointCount)
                            // save source JSON - start
                            if export.saveRawXml {
                                DispatchQueue.main.async {
                                    let exportRawJson = (export.rawXmlScope) ? RemoveData.shared.Json(rawJSON: returnedJSON, theTag: ""):RemoveData.shared.Json(rawJSON: returnedJSON, theTag: "scope")
                                    //                                    print("exportRawJson: \(exportRawJson)")
                                    WriteToLog.shared.message(stringOfText: "[getById] Exporting raw JSON for \(endpoint) - \(destEpName)")
                                    let exportFormat = (export.backupMode) ? "\(JamfProServer.source.fqdnFromUrl)_export_\(backupDate.string(from: History.startTime))":"raw"
                                    ExportItem.shared.export(node: endpoint, object: exportRawJson, theName: destEpName, id: "\(endpointID)", format: exportFormat)
//                                            exportItems(node: endpoint, objectString: exportRawJson, rawName: destEpName, id: "\(endpointID)", format: "\(exportFormat)")
                                }
                            }
                            // save source JSON - end
                            
                            if !export.saveOnly {
                                Cleanup.shared.Json(endpoint: endpoint, JSON: returnedJSON, endpointID: "\(endpointID)", endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, destEpId: destEpId, destEpName: destEpName) {
//                                        cleanupJSON(endpoint: endpoint, JSON: returnedJSON, endpointID: "\(endpointID)", endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, destEpId: destEpId, destEpName: destEpName) {
                                    (cleanJSON: String) in
                                }
                            } else {
                                // check progress
                                //                                print("[getById] node: \(endpoint)")
                                //                                // print("[getById] endpoint \(endpointCurrent) of \(endpointCount) complete")
                                Endpoints.countDict[endpoint]! -= 1
                                //                                print("[getById] \(String(describing: Endpoints.countDict[endpoint])) remaining")
                                if Endpoints.countDict[endpoint] == 0 {
                                    //                                     print("[getById] saved last \(endpoint)")
                                    //                                     print("[getById] endpoint \(Endpoints.read) of \(ToMigrate.objects.count) endpoints complete")
                                    
                                    if Endpoints.read == ToMigrate.objects.count {
                                        // print("[getById] zip it up")
//                                        print("[\(#function)] \(#line) - finished getting \(endpoint)")
                                        updateUiDelegate?.updateUi(info: ["function": "goButtonEnabled", "button_status": true])
//                                                goButtonEnabled(button_status: true)
                                    }
                                }
                            }
                        }
                    }
                }   // endpointsIdQ - end
        case "patch-software-title-configurations":
            var sourceObject = PatchTitleConfigurations.source.first(where: { $0.id == endpointID })
            print("[getById] displayName: \(sourceObject?.displayName ?? "unknown")")
            completion(sourceObject?.displayName ?? "unknown")
            
            if !(sourceObject?.id ?? "").isEmpty {
                sendGetStatus(endpoint: endpoint, total: endpointCount, index: -1)
//                self.getStatusUpdate2(endpoint: endpoint, total: endpointCount)
//                for theSourceObj in JamfProSites.source {
//                    print("[getById] sourceObject?.siteId: \(theSourceObj.id),   name: \(theSourceObj.name)")
//                }
//                print("[getById] sourceObject?.siteId: \(sourceObject?.siteId)")
                let categoryName = Categories.source.filter { $0.id == sourceObject?.categoryId }.first?.name ?? ""
                let siteName     = JamfProSites.source.filter { $0.id == sourceObject?.siteId }.first?.name ?? "None"
                
                let sourcePatchPackages = sourceObject?.packages ?? []
                var updatedPatchPackages: [PatchPackage] = []
                for thePatchPackage in sourcePatchPackages {
                    if let packageName = PatchPackages.source.filter({ $0.packageId == thePatchPackage.packageId }).first?.packageName, !packageName.isEmpty {
//                        print("[getById] update info for package \(packageName) (displayName: \(thePatchPackage.displayName ?? "unknown"))")
                        updatedPatchPackages.append(PatchPackage(packageId: thePatchPackage.packageId, version: thePatchPackage.version, displayName: thePatchPackage.displayName, packageName: packageName))
                    } else {
//                        print("[getById] unable to get package name (filename) for displayName: \(thePatchPackage.displayName ?? "unknown")")
                    }
                }
                sourceObject?.packages = updatedPatchPackages
                
                let instance = PatchSoftwareTitleConfiguration(id: sourceObject?.id ?? "0", jamfOfficial: sourceObject?.jamfOfficial ?? false, displayName: sourceObject?.displayName ?? "", categoryId: sourceObject?.categoryId ?? "", categoryName: categoryName, siteId: sourceObject?.siteId ?? "", siteName: siteName, uiNotifications: sourceObject?.uiNotifications ?? false, emailNotifications: sourceObject?.emailNotifications ?? false, softwareTitleId: sourceObject?.softwareTitleId ?? "", extensionAttributes: sourceObject?.extensionAttributes ?? [], softwareTitleName: sourceObject?.softwareTitleName ?? "", softwareTitleNameId: sourceObject?.softwareTitleNameId ?? "", softwareTitlePublisher: sourceObject?.softwareTitlePublisher ?? "", patchSourceName: sourceObject?.patchSourceName ?? "", patchSourceEnabled: sourceObject?.patchSourceEnabled ?? false, packages: sourceObject?.packages ?? [])
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted  // Optional: makes the JSON easier to read

                do {
                    let jsonData = try encoder.encode(instance)
                    
                    if let jsonString = String(data: jsonData, encoding: .utf8) {
                        print("[getById] exported jsonString: \(jsonString)")
                        
//                        print("[getById] export.saveRawXml: \(export.saveRawXml)")
//                        print("[getById] export.backupMode: \(export.backupMode)")
                        // save source JSON - start
                        if export.saveRawXml {
                            DispatchQueue.main.async {
//                                let exportRawJson = (export.rawXmlScope) ? rmJsonData(rawJSON: jsonString, theTag: ""):rmJsonData(rawJSON: jsonString, theTag: "scope")
                                //                                    print("exportRawJson: \(exportRawJson)")
                                WriteToLog.shared.message(stringOfText: "[getById] Exporting raw JSON for \(endpoint) - \(destEpName)")
                                let exportFormat = (export.backupMode) ? "\(JamfProServer.source.fqdnFromUrl)_export_\(backupDate.string(from: History.startTime))":"raw"
//                                exportItems(node: endpoint, objectString: jsonString, rawName: sourceObject?.displayName ?? "", id: sourceObject?.id ?? "0", format: exportFormat)
                                ExportItem.shared.export(node: "patch-software-title-configurations", object: instance, theName: sourceObject?.displayName ?? "", id: sourceObject?.id ?? "0", format: exportFormat)
                            }
                        }
                        // save source JSON - end
                        
                        if !export.saveOnly {
                            do {
                                let objectJson = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] ?? [:]
                                Cleanup.shared.Json(endpoint: endpoint, JSON: objectJson, endpointID: "\(endpointID)", endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, destEpId: destEpId, destEpName: destEpName) {
                                    (cleanJSON: String) in
                                }
                            } catch {
                                print(error.localizedDescription)
                            }
                             
                        } else {
                            // check progress
                            //                                print("[getById] node: \(endpoint)")
                            //                                print("[getById] endpoint \(endpointCurrent) of \(endpointCount) complete")
                            Endpoints.countDict[localEndPointType]! -= 1
                            //                                print("[getById] \(String(describing: Endpoints.countDict[endpoint])) remaining")
                            if Endpoints.countDict[localEndPointType] == 0 {
                                //                                     print("[getById] saved last \(endpoint)")
                                //                                     print("[getById] endpoint \(Endpoints.read) of \(ToMigrate.objects.count) endpoints complete")
                                
                                if Endpoints.read == ToMigrate.objects.count {
                                    // print("[getById] zip it up")
//                                    print("[\(#function)] \(#line) - finished getting \(endpoint)")
                                    updateUiDelegate?.updateUi(info: ["function": "goButtonEnabled", "button_status": true])
                                }
                            }
                        }
                    }
                } catch {
                    print("Error encoding JSON: \(error)")
                }

            }
            
        default:
            // classic API
            if !( endpoint == "jamfuser" && endpointID == "\(jamfAdminId)") {
                var myURL = "\(JamfProServer.source)/JSSResource/\(localEndPointType)/id/\(endpointID)"
                myURL = myURL.urlFix

                myURL = myURL.replacingOccurrences(of: "/JSSResource/jamfusers/id", with: "/JSSResource/accounts/userid")
                myURL = myURL.replacingOccurrences(of: "/JSSResource/jamfgroups/id", with: "/JSSResource/accounts/groupid")
                myURL = myURL.replacingOccurrences(of: "id/id/", with: "id/")
                
                endpointsIdQ.addOperation {
                    
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[getById] fetching XML from: \(myURL)") }
                            //                print("NSURL line 3")
                            //                if "\(myURL)" == "" { myURL = "https://localhost" }
                            let encodedURL = URL(string: myURL)
                            let request = NSMutableURLRequest(url: encodedURL! as URL)
                            request.httpMethod = "GET"
                            let configuration = URLSessionConfiguration.ephemeral
                            
                            configuration.httpAdditionalHeaders = ["Authorization" : "\(JamfProServer.authType["source"] ?? "Bearer") \(JamfProServer.authCreds["source"] ?? "")", "Content-Type" : "text/xml", "Accept" : "text/xml", "User-Agent" : AppInfo.userAgentHeader]
                            let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
                            let task = session.dataTask(with: request as URLRequest, completionHandler: { [self]
                                (data, response, error) -> Void in
                                session.finishTasksAndInvalidate()
                                completion(destEpName)
                                
//                                if statusCode == 202 {
//                                    print("[getById] \(#line) retrieved object")
//                                }
                                
                                if let httpResponse = response as? HTTPURLResponse {
                                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[getById] HTTP response code of GET for \(destEpName): \(httpResponse.statusCode)") }
                                    let PostXML = String(data: data!, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
                                    sendGetStatus(endpoint: endpoint, total: endpointCount, index: -1)
//                                    self.getStatusUpdate2(endpoint: endpoint, total: endpointCount)
                                    // save source XML - start
                                    if export.saveRawXml {
                                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[getById] Saving raw XML for \(destEpName) with id: \(endpointID).") }
                                        DispatchQueue.main.async {
                                            // added option to remove scope
                                            //                                    print("[getById] export.rawXmlScope: \(export.rawXmlScope)")
                                            let exportRawXml = (export.rawXmlScope) ? PostXML:RemoveData.shared.Xml(theXML: PostXML, theTag: "scope", keepTags: false)
//                                            let exportRawXml = (export.rawXmlScope) ? PostXML:rmXmlData(theXML: PostXML, theTag: "scope", keepTags: false)
                                            
                                            WriteToLog.shared.message(stringOfText: "[getById] Exporting raw XML for \(endpoint) - \(destEpName)")
                                            let exportFormat = (export.backupMode) ? "\(JamfProServer.source.fqdnFromUrl)_export_\(backupDate.string(from: History.startTime))":"raw"
                                            XmlDelegate().save(node: endpoint, xml: exportRawXml, rawName: destEpName, id: "\(endpointID)", format: "\(exportFormat)")
                                        }
                                    }
                                    // save source XML - end
                                    if !export.backupMode {
                                        
                                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[getById] Starting to clean-up the XML for \(endpoint) with id \(endpointID).") }
                                        Cleanup.shared.Xml(endpoint: endpoint, Xml: PostXML, endpointID: "\(endpointID)", endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, destEpId: destEpId, destEpName: destEpName) {
                                            (result: String) in
                                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[getById] Returned from cleanupXml") }
                                        }
                                    } else {
                                        // to back-up icons
                                        if endpoint == "policies" {
                                            Cleanup.shared.Xml(endpoint: endpoint, Xml: PostXML, endpointID: endpointID, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, destEpId: destEpId, destEpName: destEpName) {
                                                (result: String) in
                                            }
                                        }
                                        // check progress
                                        //                                print("[getById] node: \(endpoint)")
                                        //                                // print("[getById] endpoint \(endpointCurrent) of \(endpointCount) complete")
                                        Endpoints.countDict[endpoint]! -= 1
                                        //                                print("[getById] \(String(describing: Endpoints.countDict[endpoint])) remaining")
                                        if Endpoints.countDict[endpoint] == 0 {
                                            //                                     print("[getById] saved last \(endpoint)")
                                            //                                     print("[getById] endpoint \(Endpoints.read) of \(ToMigrate.objects.count) endpoints complete")
                                            Endpoints.countDict[endpoint] = nil
                                            //                                    print("[getById] nodes remaining \(Endpoints.countDict)")
//                                            if Endpoints.countDict.count == 0 && Endpoints.read == ToMigrate.objects.count {
                                            if Endpoints.countDict.count == 0 && Endpoints.read == ToMigrate.objects.count {
                                                // print("[getById] zip it up")
//                                                print("[\(#function)] \(#line) - finished getting \(endpoint)")
                                                updateUiDelegate?.updateUi(info: ["function": "goButtonEnabled", "button_status": true])
                                            }
                                        }
                                    }
                                } else {   // if let httpResponse - end
                                    // check progress
                                    //                            print("[endpointById-error] node: \(endpoint)")
                                    //                            print("[endpointById-error] endpoint \(endpointCurrent) of \(endpointCount) complete")
                                    Endpoints.countDict[endpoint]! -= 1
                                    //                            print("[endpointById-error] \(String(describing: Endpoints.countDict[endpoint])) remaining")
                                    if Endpoints.countDict[endpoint] == 0 {
                                        //                                print("[endpointById-error] saved last \(endpoint)")
                                        //                                print("[endpointById-error] endpoint \(Endpoints.read) of \(ToMigrate.objects.count) endpoints complete")
                                        Endpoints.countDict[endpoint] = nil
                                        //                                print("[endpointById-error] nodes remaining \(Endpoints.countDict)")
                                        if Endpoints.countDict.count == 0 && Endpoints.read == ToMigrate.objects.count {
                                            //                                    print("[endpointById-error] zip it up")
//                                            print("[\(#function)] \(#line) - finished getting \(endpoint)")
                                            updateUiDelegate?.updateUi(info: ["function": "goButtonEnabled", "button_status": true])
                                        }
                                    }
                                }
//                                semaphore.signal()
                                if error != nil {
                                }
                            })  // let task = session - end
                            //print("GET")
                            task.resume()
//                            semaphore.wait()
                }   // endpointsIdQ - end
            }
        }
    }
}

