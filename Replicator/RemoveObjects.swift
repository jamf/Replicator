//
//  RemoveObjects.swift
//  Replicator
//
//  Created by leslie on 12/3/24.
//  Copyright © 2024 Jamf. All rights reserved.
//

import AppKit
import Foundation

class DeleteObject: NSObject {
    @objc var endpointType    : String
    @objc var endpointName    : String
    @objc var endpointId      : String
    @objc var endpointCurrent : Int
    @objc var endpointCount   : Int
    
    init(endpointType: String, endpointName: String, endpointId: String, endpointCurrent: Int, endpointCount: Int) {
        self.endpointType    = endpointType
        self.endpointName    = endpointName
        self.endpointId      = endpointId
        self.endpointCurrent = endpointCurrent
        self.endpointCount   = endpointCount
    }
}

class RemoveObjects: NSObject, URLSessionDelegate {
    
    static let shared = RemoveObjects()
    
    let counter = Counter()
    var deleteObjectsArray: [DeleteObject] = []
    var currentDeleteObject = DeleteObject(endpointType: "", endpointName: "", endpointId: "", endpointCurrent: -1, endpointCount: -1)
    
    var destEPQ       = DispatchQueue(label: "com.jamf.destEPs", qos: DispatchQoS.utility)
    var updateUiDelegate: UpdateUiDelegate?
    var updateListSelectionDelegate: UpdateListSelectionDelegate?
    
    func queue(endpointType: String, endPointID: String, endpointName: String, endpointCurrent: Int, endpointCount: Int) {
        logFunctionCall()
        
        print("[RemoveObjects.queue] endPointID: \(endPointID), endpointCount: \(endpointCount)")
                
        if pref.stopMigration {
            SendQueue.shared.operationQueue.cancelAllOperations()
            updateUiDelegate?.updateUi(info: ["function": "stopButton"])
            return
        }
        
        destEPQ.async { [self] in
            
            if LogLevel.debug { WriteToLog.shared.message("[removeEndpointsQueue] que \(endpointType) with name: \(endpointName) for removal")}
            deleteObjectsArray.append(DeleteObject(endpointType: endpointType, endpointName: endpointName, endpointId: endPointID, endpointCurrent: endpointCurrent, endpointCount: endpointCount))
            
            currentDeleteObject = DeleteObject(endpointType: endpointType, endpointName: endpointName, endpointId: endPointID, endpointCurrent: endpointCurrent, endpointCount: endpointCount)
            
            if LogLevel.debug { WriteToLog.shared.message("\n[removeEndpointsQueue] createArray.count: \(createArray.count)\n")}
            
            if export.saveRawXml {
                EndpointData.shared.getById(endpoint: endpointType, endpointID: endPointID, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: "", destEpId: "0", destEpName: endpointName) { [self]
                    (result: String) in
                    process(endpointType: endpointType, endPointID: endPointID, endpointName: endpointName, endpointCurrent: endpointCurrent, endpointCount: endpointCount) {
                        (result: String) in
                    }
                }
            } else {
                process(endpointType: currentDeleteObject.endpointType, endPointID: currentDeleteObject.endpointId, endpointName: currentDeleteObject.endpointName, endpointCurrent: currentDeleteObject.endpointCurrent, endpointCount: currentDeleteObject.endpointCount) {
                    (result: String) in
                }
            }
        }
    }
    
    fileprivate func updateCounts(endpointType: String, localEndPointType: String, endpointName: String, result: String, endpointCount: Int, endpointCurrent: Int, endPointID: String) {
        
        print("[RemoveEndpoints.updateCounts]             endPointID: \(endPointID)")
        if endPointID == "-1" { return }
        
        if Counter.shared.crud[endpointType] == nil {
            Counter.shared.crud[endpointType] = ["create":0, "update":0, "fail":0, "skipped":0, "total": endpointCount]
        } else {
            Counter.shared.crud[endpointType]!["total"] = endpointCount
        }
        if Counter.shared.summary[endpointType] == nil {
            Counter.shared.summary[endpointType] = ["create":[], "update":[], "fail":[]]
        }
        
        Counter.shared.postSuccess += 1
        
        if let _ = Counter.shared.progressArray["\(endpointType)"] {
            Counter.shared.progressArray["\(endpointType)"] = Counter.shared.progressArray["\(endpointType)"]!+1
        } else {
            Counter.shared.progressArray["\(endpointType)"] = 1
        }
        if let _ = Counter.shared.crud[endpointType]?[result] {
            Counter.shared.crud[endpointType]?[result]! += 1
        } else {
            Counter.shared.crud[endpointType]?[result] = 1
        }
        
        Summary.totalCreated   = Counter.shared.crud[endpointType]?["create"] ?? 0
        Summary.totalFailed    = Counter.shared.crud[endpointType]?["fail"] ?? 0
        Summary.totalCompleted = Summary.totalCreated + Summary.totalFailed
        
        if var summaryArray = Counter.shared.summary[endpointType]?[result] {
            summaryArray.append(endpointName)
            Counter.shared.summary[endpointType]?[result] = summaryArray
        }
        
        if Summary.totalCompleted > 0  {
            if (endpointType != "patchpolicies") || ["patch-software-title-configurations", "policies"].contains(endpointType) {
                if endPointID != "-1" {
                    updateUiDelegate?.updateUi(info: ["function": "putStatusUpdate", "endpoint": endpointType, "total": Counter.shared.crud[endpointType]!["total"]!])
                }
            }
        }
        
        if ToMigrate.objects.last!.contains(localEndPointType) && endpointCount == endpointCurrent {
            updateUiDelegate?.updateUi(info: ["function": "rmDELETE"])
            updateUiDelegate?.updateUi(info: ["function": "goButtonEnabled", "button_status": true])
        }
    }
    
    func process(endpointType: String, endPointID: String, endpointName: String, endpointCurrent: Int, endpointCount: Int, completion: @escaping (_ result: String) -> Void) {
        
        if endPointID == "-1" { return }
        
        logFunctionCall()
        
        if pref.stopMigration {
            SendQueue.shared.operationQueue.cancelAllOperations()
            updateUiDelegate?.updateUi(info: ["function": "stopButton"])
            completion("stop")
            return
        }
        
        // counters for completed endpoints
        if endpointCurrent == 1 {
            updateUiDelegate?.updateUi(info: ["function": "labelColor", "endpoint": endpointType, "theColor": "green"])
        }
        
        if LogLevel.debug { WriteToLog.shared.message("[RemoveObjects.process] Removing: \(endpointType) - name: \(endpointName), id: \(endPointID)") }

        var workingUrl = JamfProServer.url["dest"] ?? createDestUrlBase.replacingOccurrences(of: "/JSSResource", with: "")
        
        Task {@MainActor in
            TelemetryDeckConfig.parameters[endpointType] = "remove"
        }
        
        let localEndPointType: String = {
            switch endpointType {
            case "smartcomputergroups", "staticcomputergroups":
                return "computergroups"
            case "smartmobiledevicegroups", "staticmobiledevicegroups":
                return "mobiledevicegroups"
            case "smartusergroups", "staticusergroups":
                return "usergroups"
            default:
                return endpointType
            }
        }()
        
//        print("[RemoveObject] endpointType: \(endpointType)")
        let endpointPath: String = {
            switch endpointType {
            case "api-integrations", "api-roles":
                return "/api/v1/\(endpointType)/\(endPointID)"
            case "buildings":
                return "/api/v1/buildings/\(endPointID)"
            case "patch-software-title-configurations":
                return "/api/v2/\(endpointType)/\(endPointID)"
            case "smartcomputergroups", "staticcomputergroups", "smartmobiledevicegroups", "staticmobiledevicegroups", "smartusergroups", "staticusergroups":
                return "/JSSResource/\(localEndPointType)/id/\(endPointID)"
            case "jamfusers", "accounts/userid":
                return "/JSSResource/accounts/userid/\(endPointID)"
            case "jamfgroups", "accounts/groupid":
                return "/JSSResource/accounts/groupid/\(endPointID)"
            default:
                return "/JSSResource/\(endpointType)/id/\(endPointID)"
            }
        }()
        
//        print("[RemoveObject.capi]    endpointPath: \(endpointPath)")
//        print("[RemoveObjects.capi] AppInfo.dryRun: \(AppInfo.dryRun)")
        
        if AppInfo.dryRun {
            updateCounts(endpointType: endpointType, localEndPointType: localEndPointType, endpointName: endpointName, result: "create", endpointCount: endpointCount, endpointCurrent: endpointCurrent, endPointID: endPointID)
            completion("")
            return
        }
        
        var whichError   = ""
        var responseData = ""
        workingUrl       = workingUrl + endpointPath
        
        if LogLevel.debug { WriteToLog.shared.message("[RemoveObjects.process] Original Dest. URL: \(workingUrl)") }
        workingUrl = workingUrl.urlFix
        
        SendQueue.shared.addOperation { [self] in
            
            if LogLevel.debug { WriteToLog.shared.message("[RemoveObjects.process] Action: DELETE     URL: \(workingUrl)     Object \(endpointCurrent) of \(endpointCount)") }
            
            counter.post = (endpointCurrent == 1) ? 1 : counter.post + 1
                                            
            let encodedURL = URL(string: workingUrl)
            let request = NSMutableURLRequest(url: encodedURL! as URL)
            request.httpMethod = "DELETE"
           
            let configuration = URLSessionConfiguration.default

            configuration.httpAdditionalHeaders = ["Authorization" : "\(JamfProServer.authType["dest"] ?? "Bearer") \(JamfProServer.authCreds["dest"] ?? "")", "Content-Type" : "application/xml", "Accept" : "application/xml", "User-Agent" : AppInfo.userAgentHeader]
            
            var headers = [String: String]()
            for (header, value) in configuration.httpAdditionalHeaders ?? [:] {
                headers[header as! String] = (header as! String == "Authorization") ? "Bearer ************" : value as? String
            }
            print("[apiCall] \(#function.description) method: \(request.httpMethod)")
            print("[apiCall] \(#function.description) headers: \(headers)")
            print("[apiCall] \(#function.description) endpoint: \(encodedURL?.absoluteString ?? "")")
            print("")
            
            // sticky session
            let cookieUrl = createDestUrlBase.replacingOccurrences(of: "JSSResource", with: "")
            if JamfProServer.sessionCookie.count > 0 && JamfProServer.stickySession {
                URLSession.shared.configuration.httpCookieStorage!.setCookies(JamfProServer.sessionCookie, for: URL(string: cookieUrl), mainDocumentURL: URL(string: cookieUrl))
            }
                            
            let semaphore = DispatchSemaphore(value: 0)
            let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
            let task = session.dataTask(with: request as URLRequest, completionHandler: { [self]
                (data, response, error) -> Void in
                defer { semaphore.signal() }
                session.finishTasksAndInvalidate()
                if let httpResponse = response as? HTTPURLResponse {
                    if let _ = String(data: data!, encoding: .utf8) {
                        responseData = String(data: data!, encoding: .utf8)!
                    } else {
                        if LogLevel.debug { WriteToLog.shared.message("\n\n[RemoveObjects.process] No data was returned from delete.") }
                    }
                    
                    // look to see if we are processing the next endpointType - start
                    if endpointInProgress != endpointType || endpointInProgress == "" {
                        WriteToLog.shared.message("[RemoveObjects.process] Replicating \(endpointType)")
                        endpointInProgress = endpointType
                        Counter.shared.postSuccess = 0
                    }
                    
                    if let _ = counter.createDeleteRetry["\(localEndPointType)-\(endPointID)"] {
                        counter.createDeleteRetry["\(localEndPointType)-\(endPointID)"]! += 1
                        if counter.createDeleteRetry["\(localEndPointType)-\(endPointID)"]! > 3 {
                            whichError = "skip"
                            counter.createDeleteRetry["\(localEndPointType)-\(endPointID)"] = 0
                            WriteToLog.shared.message("    [RemoveObjects.process] [\(localEndPointType)] deletional of object \(endpointName) failed, retry count exceeded.")
                        }
                    } else {
                        counter.createDeleteRetry["\(localEndPointType)-\(endPointID)"] = 0
                    }
                    
                    if httpResponse.statusCode > 199 && httpResponse.statusCode <= 299 {
                        WriteToLog.shared.message("    [RemoveObjects.process] [\(localEndPointType)] delete succeeded: \(endpointName)")
                        
                        if endpointCurrent == 1 {
                            migrationComplete.isDone = false
                            if (!Setting.migrateDependencies && endpointType != "patchpolicies") || ["patch-software-title-configurations", "policies"].contains(endpointType) {
                                updateUiDelegate?.updateUi(info: ["function": "setLevelIndicatorFillColor", "fn": "RemoveObjects-\(endpointCurrent)", "endpointType": endpointType, "fillColor": NSColor.green])
                            }
                        } else {
                            if let _ = PutLevelIndicator.shared.indicatorColor[endpointType] {
                                updateUiDelegate?.updateUi(info: ["function": "setLevelIndicatorFillColor", "fn": "RemoveObjects-\(endpointCurrent)", "endpointType": endpointType, "fillColor": NSColor.green])
                            }
                        }
                        updateCounts(endpointType: endpointType, localEndPointType: localEndPointType, endpointName: endpointName, result: "create", endpointCount: endpointCount, endpointCurrent: endpointCurrent, endPointID: endPointID)
                        
                        // update view
                        updateListSelectionDelegate?.updateListSelection(objectId: endPointID, endpointType: localEndPointType)
                        
                    } else {
                        // remove failed
                        var localErrorMsg = ""
                        let errorMsg = tagValue2(xmlString: responseData, startTag: "<p>Error: ", endTag: "</p>")
                        
                        errorMsg != "" ? (localErrorMsg = "delete error: \(errorMsg)"):(localErrorMsg = "delete error: \(tagValue2(xmlString: responseData, startTag: "<p>", endTag: "</p>"))")
                        
                        if whichError != "skip" && endpointType.contains("smart") && localErrorMsg.contains("The following items are dependent on this") && localErrorMsg.contains("SMART_") {
                            WriteToLog.shared.message("    [RemoveObjects.process] [\(endpointType)] Problem removing a smart group, error: \(localErrorMsg).  Will queue for retry (retry count: \(counter.createDeleteRetry["\(localEndPointType)-\(endPointID)"]!)).")
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
                                queue(endpointType: endpointType, endPointID: endPointID, endpointName: endpointName, endpointCurrent: endpointCurrent, endpointCount: endpointCount)
                            }
                            
                            completion("")
                            return
                        }
                        
                        WriteToLog.shared.message("[RemoveObjects.process] [\(localEndPointType)] \(endpointName) - Failed (\(httpResponse.statusCode)).  \(localErrorMsg).\n")
                        
                        updateUiDelegate?.updateUi(info: ["function": "labelColor", "endpoint": endpointType, "theColor": "yellow"])
                        if (!Setting.migrateDependencies && endpointType != "patchpolicies") || ["patch-software-title-configurations", "policies"].contains(endpointType) {
                            if endPointID != "-1" {
                                updateUiDelegate?.updateUi(info: ["function": "setLevelIndicatorFillColor", "fn": "CreateEndpoints-\(endpointCurrent)", "endpointType": endpointType, "fillColor": NSColor.systemYellow])
                            }
                        }
                        
                        if LogLevel.debug { WriteToLog.shared.message("[RemoveObjects.process] ---------- status code ----------") }
                        if LogLevel.debug { WriteToLog.shared.message("[RemoveObjects.process] \(httpResponse.statusCode)") }
                        if LogLevel.debug { WriteToLog.shared.message("[RemoveObjects.process] ---------- response data ----------\n\(responseData)") }
                        if LogLevel.debug { WriteToLog.shared.message("[RemoveObjects.process] -----------------------------------\n") }
                        
                        updateCounts(endpointType: endpointType, localEndPointType: localEndPointType, endpointName: endpointName, result: "fail", endpointCount: endpointCount, endpointCurrent: endpointCurrent, endPointID: endPointID)
                    }
                    
                    if Setting.fullGUI && Summary.totalCompleted == endpointCount {
                        if Summary.totalFailed == 0 {
                            updateUiDelegate?.updateUi(info: ["function": "labelColor", "endpoint": endpointType, "theColor": "green"])
                        } else if Summary.totalFailed == endpointCount {
                            updateUiDelegate?.updateUi(info: ["function": "labelColor", "endpoint": endpointType, "theColor": "red"])
                            if (!Setting.migrateDependencies && endpointType != "patchpolicies") || ["patch-software-title-configurations", "policies"].contains(endpointType) {
                                PutLevelIndicator.shared.indicatorColor[endpointType] = .systemRed
                                updateUiDelegate?.updateUi(info: ["function": "put_levelIndicator", "fillColor": PutLevelIndicator.shared.indicatorColor[endpointType] as Any])
                            }
                        }
                    }
                    completion("remove func: \(endpointCurrent) of \(endpointCount) complete.")
                } else {
                    // update global counters - no http response
                    updateCounts(endpointType: endpointType, localEndPointType: localEndPointType, endpointName: endpointName, result: "fail", endpointCount: endpointCount, endpointCurrent: endpointCurrent, endPointID: endPointID)
                    
                    if Setting.fullGUI && Summary.totalCompleted == endpointCount {
                        if Summary.totalFailed == 0 {
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
                              
                if endpointCurrent > 0 {
                    if LogLevel.debug { WriteToLog.shared.message("[RemoveObjects.process] endpoint: \(localEndPointType)-\(endpointCurrent)\t Total: \(endpointCount)\t Succeeded: \(Counter.shared.postSuccess)\t Failed: \(Summary.totalFailed)\t SuccessArray \(Counter.shared.progressArray["\(localEndPointType)"] ?? 0)") }
                }
                if error != nil {
                }

                if endpointCurrent == endpointCount {
                    if LogLevel.debug { WriteToLog.shared.message("[RemoveObjects.process] Last item in \(localEndPointType) complete.") }
                    nodesMigrated+=1
                }
            })
            task.resume()
            semaphore.wait()
        }
    }
}
