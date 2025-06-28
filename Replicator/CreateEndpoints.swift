//
//  CreateEndpoints.swift
//  Replicator
//
//  Created by leslie on 11/30/24.
//  Copyright © 2024 Jamf. All rights reserved.
//

import AppKit
import Foundation
import OSLog

class CreateEndpoints: NSObject, URLSessionDelegate {
    
    static let shared = CreateEndpoints()
    
    let counter = Counter()
    
    var destEPQ       = DispatchQueue(label: "com.jamf.destEPs", qos: DispatchQoS.utility)
    var updateUiDelegate: UpdateUiDelegate?
    
    func queue(endpointType: String, endpointName: String = "", endPointXML: String = "", endPointJSON: [String:Any] = [:], endpointCurrent: Int, endpointCount: Int, action: String, sourceEpId: Int, destEpId: String, ssIconName: String, ssIconId: String, ssIconUri: String, retry: Bool, completion: @escaping (_ result: String) -> Void) {
        logFunctionCall()
                
        if pref.stopMigration {
//                    print("[\(#function)] \(#line) stopMigration")
            SendQueue.shared.operationQueue.cancelAllOperations()
            updateUiDelegate?.updateUi(info: ["function": "stopButton"])
            completion("stop")
            return
        }
        completion("return from createEndpointsQueue")
//        print("[createEndpointsQueue]                   action: \(action)")
//        print("[createEndpointsQueue] setting.onlyCopyExisting: \(setting.onlyCopyExisting)")
//        print("[createEndpointsQueue]  setting.onlyCopyMissing: \(setting.onlyCopyMissing)")

        if (Setting.onlyCopyExisting && action == "create") || (Setting.onlyCopyMissing && action == "update") {
            WriteToLog.shared.message("[createEndpointsQueue] skip \(action) for \(endpointType) with name: \(endpointName)")
            Counter.shared.crud[endpointType]?["skipped"]! += 1
            if destEpId != "-1" {
                updateUiDelegate?.updateUi(info: ["function": "putStatusUpdate", "endpoint": endpointType, "total": endpointCount])
            }
            return
        }
        
        
        destEPQ.async { [self] in
            
            if LogLevel.debug { WriteToLog.shared.message("[createEndpointsQueue] que \(endpointType) with id \(sourceEpId) for upload")}
            createArray.append(ObjectInfo(endpointType: endpointType, endPointXml: endPointXML, endPointJSON: endPointJSON, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, sourceEpId: sourceEpId, destEpId: "\(destEpId)", ssIconName: ssIconName, ssIconId: ssIconId, ssIconUri: ssIconUri, retry: retry))
            
            currentObject = ObjectInfo(endpointType: endpointType, endPointXml: endPointXML, endPointJSON: endPointJSON, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, sourceEpId: sourceEpId, destEpId: "\(destEpId)", ssIconName: ssIconName, ssIconId: ssIconId, ssIconUri: ssIconUri, retry: retry)
            
            if LogLevel.debug { WriteToLog.shared.message("\n[createEndpointQueue] createArray.count: \(createArray.count)\n")}
            
            switch endpointType {
            case "buildings":
                SendQueue.shared.addOperation { [self] in
                    jpapi(endpointType: currentObject.endpointType, endPointJSON: currentObject.endPointJSON, endpointCurrent: currentObject.endpointCurrent, endpointCount: currentObject.endpointCount, action: currentObject.action, sourceEpId: "\(currentObject.sourceEpId)", destEpId: currentObject.destEpId, ssIconName: "", ssIconId: "", ssIconUri: "", retry: false) {
                        (result: String) in
                        if LogLevel.debug { WriteToLog.shared.message("[endPointByID] \(result)") }
                        if endpointCurrent == endpointCount {
                            completion("last")
                        } else {
                            completion("")
                        }
                    }
                }
            default:
                SendQueue.shared.addOperation { [self] in
                    capi(endpointType: currentObject.endpointType, endPointXML: currentObject.endPointXml.prettyPrint, endpointCurrent: currentObject.endpointCurrent, endpointCount: currentObject.endpointCount, action: currentObject.action, sourceEpId: currentObject.sourceEpId, destEpId: currentObject.destEpId, ssIconName: currentObject.ssIconName, ssIconId: currentObject.ssIconId, ssIconUri: currentObject.ssIconUri, retry: currentObject.retry) {
                        (result: String) in
                    }
                }
            }
        }
    }
    
    func capi(endpointType: String, endPointXML: String, endpointCurrent: Int, endpointCount: Int, action: String, sourceEpId: Int, destEpId: String, ssIconName: String, ssIconId: String, ssIconUri: String, retry: Bool, completion: @escaping (_ result: String) -> Void) {
        logFunctionCall()
                
        if pref.stopMigration {
//                    print("[\(#function)] \(#line) stopMigration")
            SendQueue.shared.operationQueue.cancelAllOperations()
            updateUiDelegate?.updateUi(info: ["function": "stopButton"])
//            Setting.createIsRunning = false
            completion("stop")
            return
        }
        
//        Setting.createIsRunning = true
        
        if LogLevel.debug { WriteToLog.shared.message("[CreateEndpoints] enter for \(endpointType), id \(sourceEpId)") }

        if Counter.shared.crud[endpointType] == nil {
            Counter.shared.crud[endpointType] = ["create":0, "update":0, "fail":0, "skipped":0, "total":0]
//            Counter.shared.summary[endpointType] = ["create":[], "update":[], "fail":[]]
        } else {
            Counter.shared.crud[endpointType]!["total"] = endpointCount
        }
        if Counter.shared.summary[endpointType] == nil {
//            Counter.shared.crud[endpointType] = ["create":0, "update":0, "fail":0, "skipped":0, "total":0]
            Counter.shared.summary[endpointType] = ["create":[], "update":[], "fail":[]]
        }

        var destinationEpId = destEpId
        var apiAction       = action.lowercased()
        var sourcePolicyId  = ""
        
        print("[createEndpoints.capi] endpointType: \(endpointType), destinationEpId: \(destinationEpId) action: \(action)")
        // counterts for completed endpoints
        if endpointCurrent == 1 {
//            print("[CreateEndpoints] reset counters")
            updateUiDelegate?.updateUi(info: ["function": "labelColor", "endpoint": endpointType, "theColor": "green"])
//                    Summary.totalCreated   = 0
//                    Summary.totalUpdated   = 0
//                    Summary.totalFailed    = 0
//                    Summary.totalDeleted   = 0
//                    Summary.totalCompleted = 0
        }
        
        // if working a site migrations within a single server force create when copying an item
        if JamfProServer.toSite && sitePref == "Copy" {
            if endpointType != "users"{
                destinationEpId = "0"
                apiAction       = "create"
            }
        }
        
        // this is where we create the new endpoint
        if !export.saveOnly {
            if LogLevel.debug { WriteToLog.shared.message("[CreateEndpoints] Creating new: \(endpointType)") }
        } else {
            if LogLevel.debug { WriteToLog.shared.message("[CreateEndpoints] Save only selected, skipping \(apiAction) for: \(endpointType)") }
        }
        //if LogLevel.debug { WriteToLog.shared.message("[CreateEndpoints] ----- Posting #\(endpointCurrent): \(endpointType) -----") }
                
//        print("endPointXML:\n\(endPointXML)")
        
        var localEndPointType = ""
        var whichError        = ""
        var updateSent        = true

        var createDestUrl = "\(createDestUrlBase)"
        
        switch endpointType {
        case "patchpolicies":
            localEndPointType = (apiAction == "update") ? "patchpolicies": "patchpolicies/softwaretitleconfig"
            /*
             Update Patch Policy with PUT XML to classic api: /JSSResource/patchpolicies/id/<id>
             Create Patch Policy with POST XML to the classic api: /JSSResource/patchpolicies/softwaretitleconfig/id/<existing title id>
             */
        case "smartcomputergroups", "staticcomputergroups":
            localEndPointType = "computergroups"
        case "smartmobiledevicegroups", "staticmobiledevicegroups":
            localEndPointType = "mobiledevicegroups"
        case "smartusergroups", "staticusergroups":
            localEndPointType = "usergroups"
        default:
            localEndPointType = endpointType
        }
        var responseData = ""
        createDestUrl = "\(createDestUrl)/" + localEndPointType + "/id/\(destinationEpId)"

        
        // for computers/mobile devices POST to unique identifier
        let identifier = tagValue2(xmlString:endPointXML, startTag:"<udid>", endTag:"</udid>")
        if apiAction == "update" && (endpointType == "computers" || endpointType == "mobiledevices") {
//                    print("[createEndpoints] xml: \(endPointXML)")
            createDestUrl = createDestUrl.replacingOccurrences(of: "/id/\(destinationEpId)", with: "/udid/\(identifier)")
        }
//                print("[createEndpoints] createDestUrl: \(createDestUrl)")
        
        
        if LogLevel.debug { WriteToLog.shared.message("[CreateEndpoints] Original Dest. URL: \(createDestUrl)") }
        createDestUrl = createDestUrl.urlFix
//        createDestUrl = createDestUrl.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
        createDestUrl = createDestUrl.replacingOccurrences(of: "/JSSResource/jamfusers/id", with: "/JSSResource/accounts/userid")
        createDestUrl = createDestUrl.replacingOccurrences(of: "/JSSResource/jamfgroups/id", with: "/JSSResource/accounts/groupid")
        
        SendQueue.shared.addOperation { [self] in
            
            // save trimmed XML - start
            if export.saveTrimmedXml {
                let endpointName = getName(endpoint: endpointType, objectXML: endPointXML)
                if LogLevel.debug { WriteToLog.shared.message("[CreateEndpoints] Saving trimmed XML for \(endpointName) with id: \(sourceEpId).") }
                DispatchQueue.main.async {
                    let exportTrimmedXml = (export.trimmedXmlScope) ? endPointXML:RemoveData.shared.Xml(theXML: endPointXML, theTag: "scope", keepTags: false)
                    WriteToLog.shared.message("[CreateEndpoints] Exporting trimmed XML for \(endpointType) - \(endpointName).")
                    XmlDelegate().save(node: endpointType, xml: exportTrimmedXml, rawName: endpointName, id: "\(sourceEpId)", format: "trimmed")
                }
            }
            // save trimmed XML - end
//            print("[\(#line)-CreateEndpoints] sourceEpId: \(sourceEpId)")
//            print("[\(#line)-CreateEndpoints] ToMigrate.objects: \(ToMigrate.objects)")
//            print("[\(#line)-CreateEndpoints] \(endpointCurrent) of \(endpointCount)")
            if export.saveOnly {
                if (((endpointType == "policies") || (endpointType == "mobiledeviceapplications")) && (action == "create" || Setting.csa)) || export.backupMode {
                    sourcePolicyId = (endpointType == "policies") ? "\(sourceEpId)":""

                    let ssInfo: [String: String] = ["ssIconName": ssIconName, "ssIconId": ssIconId, "ssIconUri": ssIconUri, "ssXml": ""]
                    Task {
                        await IconDelegate.shared.icons(endpointType: endpointType, action: action, ssInfo: ssInfo, f_createDestUrl: createDestUrl, responseData: responseData, sourcePolicyId: sourcePolicyId)
                    }
                }
                if ToMigrate.objects.last!.contains(localEndPointType) && endpointCount == endpointCurrent {
                    updateUiDelegate?.updateUi(info: ["function": "rmDELETE"])
//                    print("[\(#function)] \(#line) - finished creating \(endpointType)")
                    updateUiDelegate?.updateUi(info: ["function": "goButtonEnabled", "button_status": true])
                }
                completion("")
                return
            }
            
            // don't create object if we're removing objects
            if !WipeData.state.on {
                if LogLevel.debug { WriteToLog.shared.message("[CreateEndpoints] Action: \(apiAction)     URL: \(createDestUrl)     Object \(endpointCurrent) of \(endpointCount)") }
                if LogLevel.debug { WriteToLog.shared.message("[CreateEndpoints] Object XML: \(endPointXML)") }
                
                if endpointCurrent == 1 {
                    if !retry {
                        counter.post = 1
                    }
                } else {
                    if !retry {
                        counter.post += 1
                    }
                }
                if retry {
                    DispatchQueue.main.async {
                        WriteToLog.shared.message("    [CreateEndpoints] [\(localEndPointType)] retrying: \(getName(endpoint: endpointType, objectXML: endPointXML))")
                    }
                }
                
//                if endpointType == "patchpolicies" {
                    print("\(apiAction.uppercased()) on \(createDestUrl)")
//                    print(endPointXML)
//                }
                let encodedXML = endPointXML.data(using: String.Encoding.utf8)
                                
                let encodedURL = URL(string: createDestUrl)
                let request = NSMutableURLRequest(url: encodedURL! as URL)
                if ["create", "post"].contains(apiAction.lowercased()) {
                    request.httpMethod = "POST"
                } else {
                    request.httpMethod = "PUT"
                }
                let configuration = URLSessionConfiguration.default

                configuration.httpAdditionalHeaders = ["Authorization" : "\(JamfProServer.authType["dest"] ?? "Bearer") \(JamfProServer.authCreds["dest"] ?? "")", "Content-Type" : "application/xml", "Accept" : "application/xml", "User-Agent" : AppInfo.userAgentHeader]
                
                var headers = [String: String]()
                for (header, value) in configuration.httpAdditionalHeaders ?? [:] {
                    headers[header as! String] = (header as! String == "Authorization") ? "Bearer ************" : value as? String
                }
                print("[apiCall] \(#function.description) method: \(request.httpMethod)")
                print("[apiCall] \(#function.description) headers: \(headers)")
                print("[apiCall] \(#function.description) endpoint: \(encodedURL?.absoluteString ?? "")")
                print("[apiCall]")
                
                // sticky session
                let cookieUrl = createDestUrlBase.replacingOccurrences(of: "JSSResource", with: "")
                if JamfProServer.sessionCookie.count > 0 && JamfProServer.stickySession {
                    URLSession.shared.configuration.httpCookieStorage!.setCookies(JamfProServer.sessionCookie, for: URL(string: cookieUrl), mainDocumentURL: URL(string: cookieUrl))
                }
                
                request.httpBody = encodedXML!
                let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
                let task = session.dataTask(with: request as URLRequest, completionHandler: { [self]
                    (data, response, error) -> Void in
                    session.finishTasksAndInvalidate()
                    if let httpResponse = response as? HTTPURLResponse {
                        
                        if let _ = String(data: data!, encoding: .utf8) {
                            responseData = String(data: data!, encoding: .utf8)!
    //                        if LogLevel.debug { WriteToLog.shared.message("[CreateEndpoints] \n\nfull response from create:\n\(responseData)") }
    //                        print("create data response: \(responseData)")
                        } else {
                            if LogLevel.debug { WriteToLog.shared.message("\n\n[CreateEndpoints] No data was returned from post/put.") }
                        }
                        
                        // look to see if we are processing the next endpointType - start
                        if endpointInProgress != endpointType || endpointInProgress == "" {
                            WriteToLog.shared.message("[CreateEndpoints] Replicating \(endpointType)")
                            endpointInProgress = endpointType
                            Counter.shared.postSuccess = 0
                        }   // look to see if we are processing the next localEndPointType - end
                        
                        if let _ = counter.createRetry["\(localEndPointType)-\(sourceEpId)"] {
                            counter.createRetry["\(localEndPointType)-\(sourceEpId)"]! += 1
                            if counter.createRetry["\(localEndPointType)-\(sourceEpId)"]! > 3 {
                                whichError = "skip"
                                counter.createRetry["\(localEndPointType)-\(sourceEpId)"] = 0
                                WriteToLog.shared.message("    [CreateEndpoints] [\(localEndPointType)] migration of id:\(sourceEpId) failed, retry count exceeded.")
                            }
                        } else {
                            counter.createRetry["\(localEndPointType)-\(sourceEpId)"] = 0
                        }
                                                    
                        if httpResponse.statusCode > 199 && httpResponse.statusCode <= 299 {
                            WriteToLog.shared.message("    [CreateEndpoints] [\(localEndPointType)] \(action) succeeded: \(getName(endpoint: endpointType, objectXML: endPointXML).xmlDecode)")
                            
                            counter.createRetry["\(localEndPointType)-\(sourceEpId)"] = 0
                            
                            if endpointCurrent == 1 && !retry {
                                migrationComplete.isDone = false
                                if (!Setting.migrateDependencies && endpointType != "patchpolicies") || ["patch-software-title-configurations", "policies"].contains(endpointType) {
                                    updateUiDelegate?.updateUi(info: ["function": "setLevelIndicatorFillColor", "fn": "CreateEndpoints-\(endpointCurrent)", "endpointType": endpointType, "fillColor": NSColor.green])
                                }
                            } else if !retry {
                                if let _ = PutLevelIndicator.shared.indicatorColor[endpointType] {
                                    updateUiDelegate?.updateUi(info: ["function": "setLevelIndicatorFillColor", "fn": "CreateEndpoints-\(endpointCurrent)", "endpointType": endpointType, "fillColor": NSColor.green])
                                }
                            }
                            
                            Counter.shared.postSuccess += 1
                                                                    
                            if let _ = Counter.shared.progressArray["\(endpointType)"] {
                                Counter.shared.progressArray["\(endpointType)"] = Counter.shared.progressArray["\(endpointType)"]!+1
                            }
                            print("[CreateEndpoints.capi] crud \(endpointType) \(apiAction) counter: \(Counter.shared.crud[endpointType]?["\(apiAction)"] ?? 0)")
                            Counter.shared.crud[endpointType]?["\(apiAction)"]! += 1
                            
                            if var summaryArray = Counter.shared.summary[endpointType]?["\(apiAction)"] {
                                let objectName = getName(endpoint: endpointType, objectXML: endPointXML)
                                if !summaryArray.contains(objectName) {
                                    summaryArray.append(objectName)
                                    Counter.shared.summary[endpointType]?["\(apiAction)"] = summaryArray
                                }
                            }
                            
                            // currently there is no way to upload mac app store icons; no api endpoint
                            // removed check for those -  || (endpointType == "macapplications")
                            // mobiledeviceapplication icon data is in the object xml
//                                print("setting.csa: \(setting.csa)")
//                                if ((endpointType == "policies") || (endpointType == "mobiledeviceapplications")) && (action == "create" || setting.csa) {
                            if (endpointType == "policies") && (action == "create" || Setting.csa) {
                                sourcePolicyId = (endpointType == "policies") ? "\(sourceEpId)":""

                                let ssInfo: [String: String] = ["ssIconName": ssIconName, "ssIconId": ssIconId, "ssIconUri": ssIconUri, "ssXml": "\(tagValue2(xmlString: endPointXML, startTag: "<self_service>", endTag: "</self_service>"))"]
                                IconDelegate.shared.icons(endpointType: endpointType, action: action, ssInfo: ssInfo, f_createDestUrl: createDestUrl, responseData: responseData, sourcePolicyId: sourcePolicyId)
                            }
                            
                        } else {
                            // create failed
                            updateSent = false
                            updateUiDelegate?.updateUi(info: ["function": "labelColor", "endpoint": endpointType, "theColor": "yellow"])
                            if (!Setting.migrateDependencies && endpointType != "patchpolicies") || ["patch-software-title-configurations", "policies"].contains(endpointType) {
                                if destEpId != "-1" {
                                    updateUiDelegate?.updateUi(info: ["function": "setLevelIndicatorFillColor", "fn": "CreateEndpoints-\(endpointCurrent)", "endpointType": endpointType, "fillColor": NSColor.systemYellow])
                                }
                            }
                            
                            var localErrorMsg = ""
                            
                            print("[createEndpoints]   identifier: \(identifier)")
                            print("[createEndpoints] responseData: \(responseData)")
                            print("[createEndpoints]       status: \(httpResponse.statusCode)")
                            
                            if httpResponse.statusCode == 404 {
                                // retry doing a POST
                                whichError = "device not found"
                            } else {
                                let errorMsg = tagValue2(xmlString: responseData, startTag: "<p>Error: ", endTag: "</p>")

                                errorMsg != "" ? (localErrorMsg = "\(action.capitalized) error: \(errorMsg)"):(localErrorMsg = "\(action.capitalized) error: \(tagValue2(xmlString: responseData, startTag: "<p>", endTag: "</p>"))")
                                
                                // Write xml for degugging - end
                                
                                if whichError != "skip" {
                                    if errorMsg.lowercased().range(of:"no match found for category") != nil || errorMsg.lowercased().range(of:"problem with category") != nil {
                                        whichError = "category"
                                    } else {
                                        whichError = errorMsg
                                    }
                                }
                            }
                            
                            print("[createEndpoints] whichError: \(whichError)")
                            // retry computers with dublicate serial or MAC - start
                            switch whichError {
                            case "device not found":
                                print("[createEndpoints] device not found, try to create")
                                capi(endpointType: endpointType, endPointXML: endPointXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: "create", sourceEpId: sourceEpId, destEpId: "0", ssIconName: ssIconName, ssIconId: ssIconId, ssIconUri: ssIconUri, retry: true) {
                                    (result: String) in
                                    //                                    if LogLevel.debug { WriteToLog.shared.message("[CreateEndpoints] \(result)") }
                                }
                                
                            case "Duplicate UDID":
                                print("[createEndpoints] Duplicate UDID, try to update")
                                capi(endpointType: endpointType, endPointXML: endPointXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: "update", sourceEpId: sourceEpId, destEpId: "-1", ssIconName: ssIconName, ssIconId: ssIconId, ssIconUri: ssIconUri, retry: true) {
                                    (result: String) in
                                    //                                    if LogLevel.debug { WriteToLog.shared.message("[CreateEndpoints] \(result)") }
                                }
                                    
                            case "Duplicate serial number", "Duplicate MAC address":
                                WriteToLog.shared.message("    [CreateEndpoints] [\(localEndPointType)] \(getName(endpoint: endpointType, objectXML: endPointXML)) - Conflict (\(httpResponse.statusCode)).  \(localErrorMsg).  Will retry without serial and MAC address (retry count: \(counter.createRetry["\(localEndPointType)-\(sourceEpId)"]!)).")
                                var tmp_endPointXML = endPointXML
                                for xmlTag in ["alt_mac_address", "mac_address", "serial_number"] {
                                    tmp_endPointXML = RemoveData.shared.Xml(theXML: tmp_endPointXML, theTag: xmlTag, keepTags: false)
                                }
                                capi(endpointType: endpointType, endPointXML: tmp_endPointXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, sourceEpId: sourceEpId, destEpId: destEpId, ssIconName: ssIconName, ssIconId: ssIconId, ssIconUri: ssIconUri, retry: true) {
                                    (result: String) in
                                    //                                    if LogLevel.debug { WriteToLog.shared.message("[CreateEndpoints] \(result)") }
                                }
                                
                            case "category":
                                WriteToLog.shared.message("    [CreateEndpoints] [\(localEndPointType)] \(getName(endpoint: endpointType, objectXML: endPointXML)) - Conflict (\(httpResponse.statusCode)).  \(localErrorMsg).  Will retry without the category (retry count: \(counter.createRetry["\(localEndPointType)-\(sourceEpId)"]!)).")
                                var tmp_endPointXML = endPointXML
                                for xmlTag in ["category"] {
                                    tmp_endPointXML = RemoveData.shared.Xml(theXML: tmp_endPointXML, theTag: xmlTag, keepTags: false)
                                }
                                capi(endpointType: endpointType, endPointXML: tmp_endPointXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, sourceEpId: sourceEpId, destEpId: destEpId, ssIconName: ssIconName, ssIconId: ssIconId, ssIconUri: ssIconUri, retry: true) {
                                    (result: String) in
                                }
                                
                            case "Problem with department in location":
                                WriteToLog.shared.message("    [CreateEndpoints] [\(localEndPointType)] \(getName(endpoint: endpointType, objectXML: endPointXML)) - Conflict (\(httpResponse.statusCode)).  \(localErrorMsg).  Will retry without the department (retry count: \(counter.createRetry["\(localEndPointType)-\(sourceEpId)"]!)).")
                                var tmp_endPointXML = endPointXML
                                for xmlTag in ["department"] {
                                    tmp_endPointXML = RemoveData.shared.Xml(theXML: tmp_endPointXML, theTag: xmlTag, keepTags: false)
                                }
                                capi(endpointType: endpointType, endPointXML: tmp_endPointXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, sourceEpId: sourceEpId, destEpId: destEpId, ssIconName: ssIconName, ssIconId: ssIconId, ssIconUri: ssIconUri, retry: true) {
                                    (result: String) in
                                }
                                
                            case "Problem with building in location":
                                WriteToLog.shared.message("    [CreateEndpoints] [\(localEndPointType)] \(getName(endpoint: endpointType, objectXML: endPointXML)) - Conflict (\(httpResponse.statusCode)).  \(localErrorMsg).  Will retry without the building (retry count: \(counter.createRetry["\(localEndPointType)-\(sourceEpId)"]!)).")
                                var tmp_endPointXML = endPointXML
                                for xmlTag in ["building"] {
                                    tmp_endPointXML = RemoveData.shared.Xml(theXML: tmp_endPointXML, theTag: xmlTag, keepTags: false)
                                }
                                capi(endpointType: endpointType, endPointXML: tmp_endPointXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, sourceEpId: sourceEpId, destEpId: destEpId, ssIconName: ssIconName, ssIconId: ssIconId, ssIconUri: ssIconUri, retry: true) {
                                    (result: String) in
                                    //                                    if LogLevel.debug { WriteToLog.shared.message("[CreateEndpoints] \(result)") }
                                }

                            // retry network segment without distribution point
                            case "Problem in assignment to distribution point":
                                WriteToLog.shared.message("    [CreateEndpoints] [\(localEndPointType)] \(getName(endpoint: endpointType, objectXML: endPointXML)) - Conflict (\(httpResponse.statusCode)).  \(localErrorMsg).  Will retry without the distribution point (retry count: \(counter.createRetry["\(localEndPointType)-\(sourceEpId)"]!)).")
                                var tmp_endPointXML = endPointXML
                                for xmlTag in ["distribution_point", "url"] {
                                    tmp_endPointXML = RemoveData.shared.Xml(theXML: tmp_endPointXML, theTag: xmlTag, keepTags: true)
                                }
                                capi(endpointType: endpointType, endPointXML: tmp_endPointXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, sourceEpId: sourceEpId, destEpId: destEpId, ssIconName: ssIconName, ssIconId: ssIconId, ssIconUri: ssIconUri, retry: true) {
                                    (result: String) in
//                                              if LogLevel.debug { WriteToLog.shared.message("[CreateEndpoints] \(result)") }
                                }

                            default:
//                                    counter.createRetry["\(localEndPointType)-\(sourceEpId)"] = 0
                                WriteToLog.shared.message("[CreateEndpoints] [\(localEndPointType)] \(getName(endpoint: endpointType, objectXML: endPointXML)) - Failed (\(httpResponse.statusCode)).  \(localErrorMsg).\n")
                                
//                                    if LogLevel.debug { WriteToLog.shared.message("\n") }
                                if LogLevel.debug { WriteToLog.shared.message("[CreateEndpoints]  ---------- xml of failed upload ----------\n\(endPointXML)") }
                                if LogLevel.debug { WriteToLog.shared.message("[CreateEndpoints] ---------- status code ----------") }
                                if LogLevel.debug { WriteToLog.shared.message("[CreateEndpoints] \(httpResponse.statusCode)") }
                                if LogLevel.debug { WriteToLog.shared.message("[CreateEndpoints] ---------- response data ----------\n\(responseData)") }
                                if LogLevel.debug { WriteToLog.shared.message("[CreateEndpoints] -----------------------------------\n") }
                                // 400 - likely the format of the xml is incorrect or wrong endpoint
                                // 401 - wrong username and/or password
                                // 409 - unable to create object; already exists or data missing or xml error
                                
                                // update global counters
                                counter.createRetry["\(localEndPointType)-\(sourceEpId)"] = 0
                                
//                                let localTmp = (Counter.shared.crud[endpointType]?["fail"])!
//                                Counter.shared.crud[endpointType]?["fail"] = localTmp + 1
                                Counter.shared.crud[endpointType]?["fail"]! += 1
                                if var summaryArray = Counter.shared.summary[endpointType]?["fail"] {
                                    let objectName = getName(endpoint: endpointType, objectXML: endPointXML)
                                    if !summaryArray.contains(objectName) {
                                        summaryArray.append(objectName)
                                        Counter.shared.summary[endpointType]?["fail"] = summaryArray
                                    }
                                }
                                
                                if destEpId != "-1" {
                                    updateUiDelegate?.updateUi(info: ["function": "putStatusUpdate", "endpoint": endpointType, "total": Counter.shared.crud[endpointType]!["total"]!])
                                }
                                
                                //new
//                                if counter.createRetry["\(localEndPointType)-\(sourceEpId)"] == 0 && Summary.totalCompleted > 0  {
//
//                                    print("[CreateEndpoints] endpointType: \(endpointType)")
//                                    if (!Setting.migrateDependencies && endpointType != "patchpolicies") || ["patch-software-title-configurations", "policies"].contains(endpointType) {
//                                        if destEpId != "-1" {
//                                            updateUiDelegate?.updateUi(info: ["function": "putStatusUpdate", "endpoint": endpointType, "total": Counter.shared.crud[endpointType]!["total"]!])
//                                        }
//                                    }
//                                }
                            }
                        }   // create failed - end

                        Summary.totalCreated   = Counter.shared.crud[endpointType]?["create"] ?? 0
                        Summary.totalUpdated   = Counter.shared.crud[endpointType]?["update"] ?? 0
                        Summary.totalFailed    = Counter.shared.crud[endpointType]?["fail"] ?? 0
                        Summary.totalCompleted = Summary.totalCreated + Summary.totalUpdated + Summary.totalFailed
                        
                        if counter.createRetry["\(localEndPointType)-\(sourceEpId)"] == 0 && Summary.totalCompleted > 0 && updateSent  {

                            print("[CreateEndpoints] endpointType: \(endpointType)")
                            if (!Setting.migrateDependencies && endpointType != "patchpolicies") || ["patch-software-title-configurations", "policies"].contains(endpointType) {
                                if destEpId != "-1" {
                                    updateUiDelegate?.updateUi(info: ["function": "putStatusUpdate", "endpoint": endpointType, "total": Counter.shared.crud[endpointType]!["total"]!])
                                }
                            }
                        }
                        
                        if Setting.fullGUI && Summary.totalCompleted == endpointCount {
//                                migrationComplete.isDone = true

                            if Summary.totalFailed == 0 {   // removed  && UiVar.changeColor  from if condition
                                updateUiDelegate?.updateUi(info: ["function": "labelColor", "endpoint": endpointType, "theColor": "green"])
                            } else if Summary.totalFailed == endpointCount {
                                updateUiDelegate?.updateUi(info: ["function": "labelColor", "endpoint": endpointType, "theColor": "red"])
                                if (!Setting.migrateDependencies && endpointType != "patchpolicies") || ["patch-software-title-configurations", "policies"].contains(endpointType) {
                                    PutLevelIndicator.shared.indicatorColor[endpointType] = .systemRed
                                    updateUiDelegate?.updateUi(info: ["function": "put_levelIndicator", "fillColor": PutLevelIndicator.shared.indicatorColor[endpointType] as Any])
                                }
                            }
                        }
                        completion("create func: \(endpointCurrent) of \(endpointCount) complete.")
                    
                    
//                        }   // DispatchQueue.main.async - end
                } else {  // if let httpResponse = response - end
                    
                    // update global counters - no http response
                    let localTmp = (Counter.shared.crud[endpointType]?["fail"])!
                    Counter.shared.crud[endpointType]?["fail"] = localTmp + 1
                    if var summaryArray = Counter.shared.summary[endpointType]?["fail"] {
                        let objectName = getName(endpoint: endpointType, objectXML: endPointXML)
                        if summaryArray.contains(objectName) {
                            summaryArray.append(objectName)
                            Counter.shared.summary[endpointType]?["fail"] = summaryArray
                        }
                    }
                    
                    Summary.totalCreated   = Counter.shared.crud[endpointType]?["create"] ?? 0
                    Summary.totalUpdated   = Counter.shared.crud[endpointType]?["update"] ?? 0
                    Summary.totalFailed    = Counter.shared.crud[endpointType]?["fail"] ?? 0
                    Summary.totalCompleted = Summary.totalCreated + Summary.totalUpdated + Summary.totalFailed
                    
                    if counter.createRetry["\(localEndPointType)-\(sourceEpId)"] == 0 && Summary.totalCompleted > 0  {
//                                print("[CreateEndpoints] counters: \(counters)")
                        if (!Setting.migrateDependencies && endpointType != "patchpolicies") || ["patch-software-title-configurations", "policies"].contains(endpointType) {
                            if destEpId != "-1" {
                                updateUiDelegate?.updateUi(info: ["function": "putStatusUpdate", "endpoint": endpointType, "total": Counter.shared.crud[endpointType]!["total"]!])
                            }
                        }
                    }
                    
                    if Setting.fullGUI && Summary.totalCompleted == endpointCount {
//                                migrationComplete.isDone = true

                        if Summary.totalFailed == 0 {   // removed  && UiVar.changeColor  from if condition
                            updateUiDelegate?.updateUi(info: ["function": "labelColor", "endpoint": endpointType, "theColor": "green"])
                        } else if Summary.totalFailed == endpointCount {
                            updateUiDelegate?.updateUi(info: ["function": "labelColor", "endpoint": endpointType, "theColor": "red"])
                            if (!Setting.migrateDependencies && endpointType != "patchpolicies") || ["patch-software-title-configurations", "policies"].contains(endpointType) {
                                PutLevelIndicator.shared.indicatorColor[endpointType] = .systemRed
                                updateUiDelegate?.updateUi(info: ["function": "put_levelIndicator", "fillColor": PutLevelIndicator.shared.indicatorColor[endpointType] as Any])
                            }
                        }
                    }
                    completion("create func: \(endpointCurrent) of \(endpointCount) complete.")
                    
                }
                    
                    if LogLevel.debug { WriteToLog.shared.message("[CreateEndpoints] POST or PUT Operation for \(endpointType): \(request.httpMethod)") }
                    
                    if endpointCurrent > 0 {
                        if LogLevel.debug { WriteToLog.shared.message("[CreateEndpoints] endpoint: \(localEndPointType)-\(endpointCurrent)\t Total: \(endpointCount)\t Succeeded: \(Counter.shared.postSuccess)\t Failed: \(Summary.totalFailed)\t SuccessArray \(Counter.shared.progressArray["\(localEndPointType)"] ?? 0)") }
                    }
//                            semaphore.signal()
                    if error != nil {
                    }

                    if endpointCurrent == endpointCount {
                        if LogLevel.debug { WriteToLog.shared.message("[CreateEndpoints] Last item in \(localEndPointType) complete.") }
                        nodesMigrated+=1    // ;print("added node: \(localEndPointType) - createEndpoints")
    //                    print("nodes complete: \(nodesMigrated)")
                    }
                })
                task.resume()
//                        semaphore.wait()
            }   // if !WipeData.state.on - end
            
        }   // SendQueue - end
    }
    
    func jpapi(endpointType: String, endPointJSON: [String: Any], policyDetails: [PatchPolicyDetail] = [], endpointCurrent: Int, endpointCount: Int, action: String, sourceEpId: String, destEpId: String, ssIconName: String, ssIconId: String, ssIconUri: String, retry: Bool, completion: @escaping (_ result: String) -> Void) {
        logFunctionCall()
                
        if pref.stopMigration {
//                    print("[\(#function)] \(#line) stopMigration")
            updateUiDelegate?.updateUi(info: ["function": "stopButton"])
            completion("stop")
            return
        }

        if Counter.shared.crud[endpointType] == nil {
            Counter.shared.crud[endpointType] = ["create":0, "update":0, "fail":0, "skipped":0, "total":0]
//            Counter.shared.summary[endpointType] = ["create":[], "update":[], "fail":[]]
        } else {
            Counter.shared.crud[endpointType]!["total"] = endpointCount
        }
        if Counter.shared.summary[endpointType] == nil {
//            Counter.shared.crud[endpointType] = ["create":0, "update":0, "fail":0, "skipped":0, "total":0]
            Counter.shared.summary[endpointType] = ["create":[], "update":[], "fail":[]]
        }
        
        var destinationEpId = destEpId
        var apiAction       = action
        
        print("[createEndpoints.jpapi] endpointType: \(endpointType), destinationEpId: \(destinationEpId) action: \(action)")
        
        // counterts for completed endpoints
        if endpointCurrent == 1 {
//            print("[CreateEndpoints2] reset counters")
            Summary.totalCreated   = 0
            Summary.totalUpdated   = 0
            Summary.totalFailed    = 0
            Summary.totalCompleted = 0
        }
        
        // if working a site migrations within a single server force create/POST when copying an item
        if JamfProServer.toSite && sitePref == "Copy" {
            if endpointType != "users" {
                destinationEpId = "0"
                apiAction       = "create"
            }
        }
        
        
        // this is where we create the new endpoint
        if !export.saveOnly {
            if LogLevel.debug { WriteToLog.shared.message("[createEndpoints.jpapi] Creating new: \(endpointType)") }
        } else {
            if LogLevel.debug { WriteToLog.shared.message("[createEndpoints.jpapi] Save only selected, skipping \(apiAction) for: \(endpointType)") }
        }
        //if LogLevel.debug { WriteToLog.shared.message("[createEndpoints.jpapi] ----- Posting #\(endpointCurrent): \(endpointType) -----") }
        
        var localEndPointType = ""
        
        switch endpointType {
        case "smartcomputergroups", "staticcomputergroups":
            localEndPointType = "computergroups"
        case "smartmobiledevicegroups", "staticmobiledevicegroups":
            localEndPointType = "mobiledevicegroups"
        case "smartusergroups", "staticusergroups":
            localEndPointType = "usergroups"
        default:
            localEndPointType = endpointType
        }
                
        if LogLevel.debug { WriteToLog.shared.message("[createEndpoints.jpapi] Original Dest. URL: \(createDestUrlBase)") }
       
        SendQueue.shared.addOperation { [self] in
            
            // save trimmed JSON - start
            if export.saveTrimmedXml {
                let endpointName = endPointJSON["name"] as! String   //getName(endpoint: endpointType, objectXML: endPointJSON)
                if LogLevel.debug { WriteToLog.shared.message("[createEndpoints.jpapi] Saving trimmed JSON for \(endpointName) with id: \(sourceEpId).") }
                DispatchQueue.main.async {
                    let exportTrimmedJson = (export.trimmedXmlScope) ? RemoveData.shared.Json(rawJSON: endPointJSON, theTag: ""):RemoveData.shared.Json(rawJSON: endPointJSON, theTag: "scope")
//                    print("exportTrimmedJson: \(exportTrimmedJson)")
                    WriteToLog.shared.message("[createEndpoints.jpapi] Exporting raw JSON for \(endpointType) - \(endpointName)")
                    ExportItem.shared.export(node: endpointType, object: exportTrimmedJson, theName: endpointName, id: "\(sourceEpId)", format: "trimmed")
//                    self.exportItems(node: endpointType, objectString: exportTrimmedJson, rawName: endpointName, id: "\(sourceEpId)", format: "trimmed")
//                    SaveDelegate().exportObject(node: endpointType, objectString: exportTrimmedJson, rawName: endpointName, id: "\(sourceEpId)", format: "trimmed")
                }
                
            }
            // save trimmed JSON - end
            
            if export.saveOnly {
                if ToMigrate.objects.last == localEndPointType && endpointCount == endpointCurrent {
                    //self.go_button.isEnabled = true
                    updateUiDelegate?.updateUi(info: ["function": "rmDELETE"])
//                    self.resetAllCheckboxes()
//                    print("[\(#function)] \(#line) - finished creating \(endpointType)")
                    updateUiDelegate?.updateUi(info: ["function": "goButtonEnabled", "button_status": true])
                }
                return
            }
            
            // don't create object if we're removing objects
            if !WipeData.state.on {
                if LogLevel.debug { WriteToLog.shared.message("[createEndpoints.jpapi] Action: \(apiAction)\t URL: \(createDestUrlBase)\t Object \(endpointCurrent) of \(endpointCount)") }
                if LogLevel.debug { WriteToLog.shared.message("[createEndpoints.jpapi] Object JSON: \(endPointJSON)") }
    //            print("[createEndpoints.jpapi] [\(localEndPointType)] process start: \(getName(endpoint: endpointType, objectXML: endPointXML))")
                
                if endpointCurrent == 1 {
                    if !retry {
                        counter.post = 1
                    }
                } else {
                    if !retry {
                        counter.post += 1
                    }
                }
                
                if endpointType == "patch-software-title-configurations" {
                    PatchManagementApi.shared.createUpdate(serverUrl: createDestUrlBase.replacingOccurrences(of: "/JSSResource", with: ""), endpoint: endpointType, apiData: endPointJSON, sourceEpId: sourceEpId, destEpId: destinationEpId, token: JamfProServer.authCreds["dest"] ?? "", method: apiAction) { [self]
                        (jpapiResonse: [String:Any]) in
    //                    print("[createEndpoints.jpapi] returned from Jpapi.action, jpapiResonse: \(jpapiResonse)")
                        var jpapiResult = "succeeded"
                        if let _ = jpapiResonse["JPAPI_result"] as? String {
                            jpapiResult = jpapiResonse["JPAPI_result"] as! String
                        }
    //                    if let httpResponse = response as? HTTPURLResponse {
                        var apiMethod = apiAction
                        if apiAction.lowercased() == "skip" || jpapiResult != "succeeded" {
                            apiMethod = "fail"
                            DispatchQueue.main.async { [self] in
                                if Setting.fullGUI && apiAction.lowercased() != "skip" {
                                    updateUiDelegate?.updateUi(info: ["function": "labelColor", "endpoint": endpointType, "theColor": "yellow"])
                                    if (!Setting.migrateDependencies && endpointType != "patchpolicies") || ["patch-software-title-configurations", "policies"].contains(endpointType) {
                                        updateUiDelegate?.updateUi(info: ["function": "setLevelIndicatorFillColor", "fn": "CreateEndpoints-\(endpointCurrent)", "endpointType": endpointType, "fillColor": NSColor.systemYellow])
                                    }
                                }
                            }
                            WriteToLog.shared.message("    [createEndpoints.jpapi] [\(localEndPointType)]    failed: \(endPointJSON["name"] ?? "unknown")")
                        } else {
                            WriteToLog.shared.message("    [createEndpoints.jpapi] [\(localEndPointType)] succeeded: \(endPointJSON["name"] ?? "unknown")")
                            
                            if endpointCurrent == 1 && !retry {
                                migrationComplete.isDone = false
                                if (!Setting.migrateDependencies && endpointType != "patchpolicies") || ["patch-software-title-configurations", "policies"].contains(endpointType) {
                                    updateUiDelegate?.updateUi(info: ["function": "setLevelIndicatorFillColor", "fn": "CreateEndpoints-\(endpointCurrent)", "endpointType": endpointType, "fillColor": NSColor.green])
//                                    self.setLevelIndicatorFillColor(fn: "createEndpoints.jpapi-\(endpointCurrent)", endpointType: endpointType, fillColor: NSColor.green)
                                }
                            } else if !retry {
                                if let _ = PutLevelIndicator.shared.indicatorColor[endpointType] {
                                    updateUiDelegate?.updateUi(info: ["function": "setLevelIndicatorFillColor", "fn": "CreateEndpoints-\(endpointCurrent)", "endpointType": endpointType, "fillColor": PutLevelIndicator.shared.indicatorColor[endpointType] ?? NSColor.green])
//                                    self.setLevelIndicatorFillColor(fn: "CreateEndpoints-\(endpointCurrent)", endpointType: endpointType, fillColor: PutLevelIndicator.shared.indicatorColor[endpointType] ?? NSColor.green)
                                }
                            }
                        }
                        
                        print("[CreateEndpoints.jpapi] crud \(endpointType) \(apiAction) counter: \(Counter.shared.crud[endpointType]?["\(apiAction)"] ?? 0)")
                        
                            // look to see if we are processing the next endpointType - start
                            if endpointInProgress != endpointType || endpointInProgress == "" {
                                WriteToLog.shared.message("[createEndpoints.jpapi] Migrating \(endpointType)")
                                endpointInProgress = endpointType
                                Counter.shared.postSuccess = 0
                            }   // look to see if we are processing the next localEndPointType - end
                            
    //                    DispatchQueue.main.async { [self] in
                            
                        
                                // ? remove creation of counters dict defined earlier ?
//                                if Counter.shared.crud[endpointType] == nil {
//                                    Counter.shared.crud[endpointType] = ["create":0, "update":0, "fail":0, "skipped":0, "total":0]
//                                    Counter.shared.summary[endpointType] = ["create":[], "update":[], "fail":[]]
//                                }
                            
                                                            
                                Counter.shared.postSuccess += 1
                                
    //                            print("endpointType: \(endpointType)")
    //                            print("Counter.shared.progressArray: \(String(describing: Counter.shared.progressArray["\(endpointType)"]))")
                                
                                if let _ = Counter.shared.progressArray["\(endpointType)"] {
                                    Counter.shared.progressArray["\(endpointType)"] = Counter.shared.progressArray["\(endpointType)"]!+1
                                }
                                
//                                let localTmp = (Counter.shared.crud[endpointType]?["\(apiMethod)"])!
        //                        print("localTmp: \(localTmp)")

                        
                                /*
                                // currently there is no way to upload mac app store icons; no api endpoint
                                // removed check for those -  || (endpointType == "macapplications")
                                if ((endpointType == "policies") || (endpointType == "mobiledeviceapplications")) && (action == "create") {
                                    sourcePolicyId = (endpointType == "policies") ? "\(sourceEpId)":""
                                    self.icons(endpointType: endpointType, action: action, ssIconName: ssIconName, ssIconId: ssIconId, ssIconUri: ssIconUri, f_createDestUrl: createDestUrl, responseData: responseData, sourcePolicyId: sourcePolicyId)
                                }
                                */

                                Summary.totalCreated   = Counter.shared.crud[endpointType]?["create"] ?? 0
                                Summary.totalUpdated   = Counter.shared.crud[endpointType]?["update"] ?? 0
                                Summary.totalFailed    = Counter.shared.crud[endpointType]?["fail"] ?? 0
                                Summary.totalCompleted = Summary.totalCreated + Summary.totalUpdated + Summary.totalFailed
                                
                                // update counters
//                                print("[CreateEndpoints.jpapi] endpointType: \(endpointType)")
                                if Summary.totalCompleted > 0 {
                                    if (!Setting.migrateDependencies && endpointType != "patchpolicies") || ["patch-software-title-configurations", "policies"].contains(endpointType) {
                                        if destEpId != "-1" {
                                            updateUiDelegate?.updateUi(info: ["function": "putStatusUpdate", "endpoint": endpointType, "total": Counter.shared.crud[endpointType]!["total"]!])
                                        }
                                    }
                                }
                                
                                if Setting.fullGUI && Summary.totalCompleted == endpointCount {

                                    if Summary.totalFailed == 0 {   // removed  && UiVar.changeColor   from if condition
                                        updateUiDelegate?.updateUi(info: ["function": "labelColor", "endpoint": endpointType, "theColor": "green"])
                                    } else if Summary.totalFailed == endpointCount {
                                        DispatchQueue.main.async { [self] in
                                            updateUiDelegate?.updateUi(info: ["function": "labelColor", "endpoint": endpointType, "theColor": "red"])
                                            if (!Setting.migrateDependencies && endpointType != "patchpolicies") || ["patch-software-title-configurations", "policies"].contains(endpointType) {
                                                PutLevelIndicator.shared.indicatorColor[endpointType] = .systemRed
                                                updateUiDelegate?.updateUi(info: ["function": "put_levelIndicator", "fillColor": PutLevelIndicator.shared.indicatorColor[endpointType] as Any])
                                            }
                                        }
                                        
                                    }
                                }
    //                        }   // DispatchQueue.main.async - end
                            completion("create func: \(endpointCurrent) of \(endpointCount) complete.")
    //                    }   // if let httpResponse = response - end
                        
                        if LogLevel.debug { WriteToLog.shared.message("[createEndpoints.jpapi] POST, PUT, or skip - operation: \(apiAction)") }
                        
                        if endpointCurrent > 0 {
                            if LogLevel.debug { WriteToLog.shared.message("[createEndpoints.jpapi] endpoint: \(localEndPointType)-\(endpointCurrent)\t Total: \(endpointCount)\t Succeeded: \(Counter.shared.postSuccess)\t Failed: \(Summary.totalFailed)\t SuccessArray \(String(describing: Counter.shared.progressArray["\(localEndPointType)"]!))") }
                        }

        //                print("create func: \(endpointCurrent) of \(endpointCount) complete.  \(nodesMigrated) nodes migrated.")
                        if endpointCurrent == endpointCount {
                            if LogLevel.debug { WriteToLog.shared.message("[createEndpoints.jpapi] Last item in \(localEndPointType) complete.") }
                            nodesMigrated+=1
                            // print("added node: \(localEndPointType) - createEndpoints")
        //                    print("nodes complete: \(nodesMigrated)")
                        }
                    }
                } else {
//                    print("[createEndpoints.jpapi] \(#line) endPointJSON: \(endPointJSON)")
                    let nameAttribute = ["api-roles", "api-integrations"].contains(endpointType) ? "displayName" : "name"
                    Jpapi.shared.action(whichServer: "dest", endpoint: endpointType, apiData: endPointJSON, id: "\(destinationEpId)", token: JamfProServer.authCreds["dest"] ?? "", method: apiAction) { [self]
                        (jpapiResonse: [String:Any]) in
//                        print("[createEndpoints.jpapi] returned from Jpapi.action, jpapiResonse: \(jpapiResonse)")
                        var jpapiResult = "succeeded"
                        if let _ = jpapiResonse["JPAPI_result"] as? String {
                            jpapiResult = jpapiResonse["JPAPI_result"] as! String
                        }
    //                    if let httpResponse = response as? HTTPURLResponse {
                        var apiMethod = apiAction
                        if apiAction.lowercased() == "skip" || jpapiResult != "succeeded" {
                            apiMethod = "fail"
                            DispatchQueue.main.async { [self] in
                                if Setting.fullGUI && apiAction.lowercased() != "skip" {
                                    updateUiDelegate?.updateUi(info: ["function": "labelColor", "endpoint": endpointType, "theColor": "yellow"])
                                    if (!Setting.migrateDependencies && endpointType != "patchpolicies") || ["patch-software-title-configurations", "policies"].contains(endpointType) {
                                        updateUiDelegate?.updateUi(info: ["function": "setLevelIndicatorFillColor", "fn": "CreateEndpoints-\(endpointCurrent)", "endpointType": endpointType, "fillColor": NSColor.systemYellow])
//                                        self.setLevelIndicatorFillColor(fn: "createEndpoints.jpapi-\(endpointCurrent)", endpointType: endpointType, fillColor: NSColor.systemYellow)
                                    }
                                }
                            }
                            WriteToLog.shared.message("    [createEndpoints.jpapi] [\(localEndPointType)]    failed: \(endPointJSON[nameAttribute] ?? "unknown")")
                        } else {
                            WriteToLog.shared.message("    [createEndpoints.jpapi] [\(localEndPointType)] succeeded: \(endPointJSON[nameAttribute] ?? "unknown")")
                            
                            if endpointCurrent == 1 && !retry {
                                migrationComplete.isDone = false
                                if (!Setting.migrateDependencies && endpointType != "patchpolicies") || ["patch-software-title-configurations", "policies"].contains(endpointType) {
                                    updateUiDelegate?.updateUi(info: ["function": "setLevelIndicatorFillColor", "fn": "CreateEndpoints-\(endpointCurrent)", "endpointType": endpointType, "fillColor": NSColor.green])
//                                    self.setLevelIndicatorFillColor(fn: "createEndpoints.jpapi-\(endpointCurrent)", endpointType: endpointType, fillColor: NSColor.green)
                                }
                            } else if !retry {
                                if let _ = PutLevelIndicator.shared.indicatorColor[endpointType] /*self.put_levelIndicatorFillColor[endpointType]*/ {
                                    updateUiDelegate?.updateUi(info: ["function": "setLevelIndicatorFillColor", "fn": "CreateEndpoints-\(endpointCurrent)", "endpointType": endpointType, "fillColor": PutLevelIndicator.shared.indicatorColor[endpointType] ?? NSColor.green])
//                                    self.setLevelIndicatorFillColor(fn: "CreateEndpoints-\(endpointCurrent)", endpointType: endpointType, fillColor: PutLevelIndicator.shared.indicatorColor[endpointType] ?? NSColor.green)
                                }
                            }
                        }

                            // look to see if we are processing the next endpointType - start
                            if endpointInProgress != endpointType || endpointInProgress == "" {
                                WriteToLog.shared.message("[createEndpoints.jpapi] Migrating \(endpointType)")
                                endpointInProgress = endpointType
                                Counter.shared.postSuccess = 0
                            }   // look to see if we are processing the next localEndPointType - end
                            
    //                    DispatchQueue.main.async { [self] in
                            
                                // ? remove creation of counters dict defined earlier ?
                                if Counter.shared.crud[endpointType] == nil {
                                    Counter.shared.crud[endpointType] = ["create":0, "update":0, "fail":0, "skipped":0, "total":0]
                                    Counter.shared.summary[endpointType] = ["create":[], "update":[], "fail":[]]
                                }
                            
                                                            
                                Counter.shared.postSuccess += 1
                                
    //                            print("endpointType: \(endpointType)")
    //                            print("Counter.shared.progressArray: \(String(describing: Counter.shared.progressArray["\(endpointType)"]))")
                                
                                if let _ = Counter.shared.progressArray["\(endpointType)"] {
                                    Counter.shared.progressArray["\(endpointType)"] = Counter.shared.progressArray["\(endpointType)"]!+1
                                }
                                
                                let localTmp = (Counter.shared.crud[endpointType]?["\(apiMethod)"])!
        //                        print("localTmp: \(localTmp)")
                                Counter.shared.crud[endpointType]?["\(apiMethod)"] = localTmp + 1
                                
                                
                                if var summaryArray = Counter.shared.summary[endpointType]?["\(apiMethod)"] {
                                    var objectName = "unknown name"
                                    switch endpointType {
                                    case "api-roles", "api-integrations":
                                        objectName = endPointJSON["displayName"] as? String ?? "unknown name"
                                    default:
                                        objectName = endPointJSON["name"] as? String ?? "unknown name"
                                    }
                                    if summaryArray.contains(objectName) == false {
                                        summaryArray.append(objectName)
                                        Counter.shared.summary[endpointType]?["\(apiMethod)"] = summaryArray
                                    }
                                }
                                /*
                                // currently there is no way to upload mac app store icons; no api endpoint
                                // removed check for those -  || (endpointType == "macapplications")
                                if ((endpointType == "policies") || (endpointType == "mobiledeviceapplications")) && (action == "create") {
                                    sourcePolicyId = (endpointType == "policies") ? "\(sourceEpId)":""
                                    self.icons(endpointType: endpointType, action: action, ssIconName: ssIconName, ssIconId: ssIconId, ssIconUri: ssIconUri, f_createDestUrl: createDestUrl, responseData: responseData, sourcePolicyId: sourcePolicyId)
                                }
                                */

                                Summary.totalCreated   = Counter.shared.crud[endpointType]?["create"] ?? 0
                                Summary.totalUpdated   = Counter.shared.crud[endpointType]?["update"] ?? 0
                                Summary.totalFailed    = Counter.shared.crud[endpointType]?["fail"] ?? 0
                                Summary.totalCompleted = Summary.totalCreated + Summary.totalUpdated + Summary.totalFailed
                                
                                // update counters
                                if Summary.totalCompleted > 0 {
                                    if (!Setting.migrateDependencies && endpointType != "patchpolicies") || ["patch-software-title-configurations", "policies"].contains(endpointType) {
                                        if destEpId != "-1" {
                                            updateUiDelegate?.updateUi(info: ["function": "putStatusUpdate", "endpoint": endpointType, "total": Counter.shared.crud[endpointType]!["total"]!])
                                        }
                                    }
                                }
                                
                                if Setting.fullGUI && Summary.totalCompleted == endpointCount {

                                    if Summary.totalFailed == 0 {   // removed  && UiVar.changeColor   from if condition
                                        updateUiDelegate?.updateUi(info: ["function": "labelColor", "endpoint": endpointType, "theColor": "green"])
                                    } else if Summary.totalFailed == endpointCount {
                                        DispatchQueue.main.async { [self] in
                                            updateUiDelegate?.updateUi(info: ["function": "labelColor", "endpoint": endpointType, "theColor": "red"])
                                            
                                            if (!Setting.migrateDependencies && endpointType != "patchpolicies") || ["patch-software-title-configurations", "policies"].contains(endpointType) {
                                                PutLevelIndicator.shared.indicatorColor[endpointType] = .systemRed
                                                updateUiDelegate?.updateUi(info: ["function": "put_levelIndicator", "fillColor": PutLevelIndicator.shared.indicatorColor[endpointType] as Any])
                                            }
                                        }
                                        
                                    }
                                }
    //                        }   // DispatchQueue.main.async - end
                            completion("create func: \(endpointCurrent) of \(endpointCount) complete.")
    //                    }   // if let httpResponse = response - end
                        
                        if LogLevel.debug { WriteToLog.shared.message("[createEndpoints.jpapi] POST, PUT, or skip - operation: \(apiAction)") }
                        
                        if endpointCurrent > 0 {
                            if LogLevel.debug { WriteToLog.shared.message("[createEndpoints.jpapi] endpoint: \(localEndPointType)-\(endpointCurrent)\t Total: \(endpointCount)\t Succeeded: \(Counter.shared.postSuccess)\t Failed: \(Summary.totalFailed)\t SuccessArray \(String(describing: Counter.shared.progressArray["\(localEndPointType)"]!))") }
                        }

        //                print("create func: \(endpointCurrent) of \(endpointCount) complete.  \(nodesMigrated) nodes migrated.")
                        if endpointCurrent == endpointCount {
                            if LogLevel.debug { WriteToLog.shared.message("[createEndpoints.jpapi] Last item in \(localEndPointType) complete.") }
                            nodesMigrated+=1
                            // print("added node: \(localEndPointType) - createEndpoints")
        //                    print("nodes complete: \(nodesMigrated)")
                        }
                    }
                }
                
                
                
            }   // if !WipeData.state.on - end
        }   // SendQueue - end
    }
}
