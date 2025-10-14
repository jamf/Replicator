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
    var localEndPointType = ""
    var endpointPath      = ""
    
    let counter = Counter()
    var deleteObjectsArray: [DeleteObject] = []
    var currentDeleteObject = DeleteObject(endpointType: "", endpointName: "", endpointId: "", endpointCurrent: -1, endpointCount: -1)
    
    var destEPQ       = DispatchQueue(label: "com.jamf.destEPs", qos: DispatchQoS.utility)
    var updateUiDelegate: UpdateUiDelegate?
    
//    func queue(endpointType: String, endPointID: String, endpointName: String, endpointCurrent: Int, endpointCount: Int, completion: @escaping (_ result: String) -> Void) {
    func queue(endpointType: String, endPointID: String, endpointName: String, endpointCurrent: Int, endpointCount: Int) {
        logFunctionCall()
        
        print("[RemoveObjects.queue] endPointID: \(endPointID), endpointCount: \(endpointCount)")
                
        if pref.stopMigration {
//                    print("[\(#function)] \(#line) stopMigration")
            SendQueue.shared.operationQueue.cancelAllOperations()
            updateUiDelegate?.updateUi(info: ["function": "stopButton"])
//            completion("stop")
            return
        }
        
        destEPQ.async { [self] in
            
            if LogLevel.debug { WriteToLog.shared.message("[removeEndpointsQueue] que \(endpointType) with name: \(endpointName) for removal")}
            deleteObjectsArray.append(DeleteObject(endpointType: endpointType, endpointName: endpointName, endpointId: endPointID, endpointCurrent: endpointCurrent, endpointCount: endpointCount))
            
            currentDeleteObject = DeleteObject(endpointType: endpointType, endpointName: endpointName, endpointId: endPointID, endpointCurrent: endpointCurrent, endpointCount: endpointCount)
            
            if LogLevel.debug { WriteToLog.shared.message("\n[removeEndpointsQueue] createArray.count: \(createArray.count)\n")}
            
            switch endpointType {
            case "buildings":
                print("later")
//                    jpapi(endpointType: currentDeleteObject.endpointType, endPointID: currentDeleteObject.endpointId, endpointName: currentDeleteObject.endpointName, endpointCurrent: currentDeleteObject.endpointCurrent, endpointCount: currentDeleteObject.endpointCount) {
//                        (result: String) in
//                        if LogLevel.debug { WriteToLog.shared.message("[endPointByID] \(result)") }
//                        if endpointCurrent == endpointCount {
//                            completion("last")
//                        } else {
//                            completion("")
//                        }
//                    }
            default:
                capi(endpointType: currentDeleteObject.endpointType, endPointID: currentDeleteObject.endpointId, endpointName: currentDeleteObject.endpointName, endpointCurrent: currentDeleteObject.endpointCurrent, endpointCount: currentDeleteObject.endpointCount) {
                        (result: String) in
                    }
            }
        }
    }
    
    fileprivate func updateCounts(endpointType: String, endpointName: String, result: String, endpointCount: Int, endpointCurrent: Int, endPointID: String) {
        
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
//        print("[CreateEndpoints.capi] \(apiAction) endpointType: \(endpointType)")
        
        Summary.totalCreated   = Counter.shared.crud[endpointType]?["create"] ?? 0
        Summary.totalFailed    = Counter.shared.crud[endpointType]?["fail"] ?? 0
        Summary.totalCompleted = Summary.totalCreated + Summary.totalFailed
        
        if var summaryArray = Counter.shared.summary[endpointType]?[result] {
            summaryArray.append(endpointName)
            Counter.shared.summary[endpointType]?[result] = summaryArray
        }
        
        print("[RemoveEndpoints]   Summary.totalCreated: \(Summary.totalCreated)")
        print("[RemoveEndpoints]    Summary.totalFailed: \(Summary.totalFailed)")
        print("[RemoveEndpoints] Summary.totalCompleted: \(Summary.totalCompleted)")
        print("[RemoveEndpoints]             endPointID: \(endPointID)")
        
        if Summary.totalCompleted > 0  {
//                                print("[RemoveEndpoints] counters: \(counters)")
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
    
    func capi(endpointType: String, endPointID: String, endpointName: String, endpointCurrent: Int, endpointCount: Int, completion: @escaping (_ result: String) -> Void) {
        logFunctionCall()
                
        if pref.stopMigration {
            SendQueue.shared.operationQueue.cancelAllOperations()
            updateUiDelegate?.updateUi(info: ["function": "stopButton"])
            completion("stop")
            return
        }
                
        if LogLevel.debug { WriteToLog.shared.message("[RemoveEndpoints] enter for \(endpointType), name: \(endpointName), id: \(endPointID)") }

        let destinationEpId = endPointID
//        let apiAction       = "create"
        
        // counters for completed endpoints
        if endpointCurrent == 1 {
            updateUiDelegate?.updateUi(info: ["function": "labelColor", "endpoint": endpointType, "theColor": "green"])
        }
        
        // this is where we create the new endpoint
        if !export.saveOnly {
            if LogLevel.debug { WriteToLog.shared.message("[RemoveEndpoints] Removing: \(endpointType), - name: \(endpointName), id: \(endPointID)") }
        } else {
            if LogLevel.debug { WriteToLog.shared.message("[RemoveEndpoints] Save only selected, skipping delete for: \(endpointType), - name: \(endpointName), id: \(endPointID)") }
        }

        var createDestUrl = "\(createDestUrlBase)"
        
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
            
            
        switch endpointType {
        case "buildings":
            endpointPath = "/v1/buildings/\(endPointID)"
        case "jamfusers":
            endpointPath = "/JSSResource/accounts/userid/\(endPointID)"
        case "jamfgroups":
            endpointPath = "/JSSResource/accounts/groupid/\(endPointID)"
        default:
            endpointPath = "/JSSResource/\(endpointType)/id/\(endPointID)"
        }
        
        print("[RemoveObjects.capi] AppInfo.dryRun: \(AppInfo.dryRun)")
        
        if AppInfo.dryRun {
            updateCounts(endpointType: endpointType, endpointName: endpointName, result: "create", endpointCount: endpointCount, endpointCurrent: endpointCurrent, endPointID: endPointID)
            completion("")
            return
        }
        
        var responseData = ""
        createDestUrl = "\(createDestUrl)/" + localEndPointType + "/id/\(destinationEpId)"
        
        
        if LogLevel.debug { WriteToLog.shared.message("[RemoveEndpoints] Original Dest. URL: \(createDestUrl)") }
        createDestUrl = createDestUrl.urlFix
        
        SendQueue.shared.addOperation { [self] in
            
            if export.saveOnly {
                if ToMigrate.objects.last!.contains(localEndPointType) && endpointCount == endpointCurrent {
                    updateUiDelegate?.updateUi(info: ["function": "rmDELETE"])
//                    print("[\(#function)] \(#line) - finished creating \(endpointType)")
                    updateUiDelegate?.updateUi(info: ["function": "goButtonEnabled", "button_status": true])
                }
                completion("")
                return
            }
            
            if LogLevel.debug { WriteToLog.shared.message("[RemoveEndpoints] Action: DELETE     URL: \(createDestUrl)     Object \(endpointCurrent) of \(endpointCount)") }
            
            counter.post = (endpointCurrent == 1) ? 1 : counter.post + 1
                                            
            let encodedURL = URL(string: createDestUrl)
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
                        //                        if LogLevel.debug { WriteToLog.shared.message("[RemoveEndpoints] \n\nfull response from create:\n\(responseData)") }
                        //                        print("create data response: \(responseData)")
                    } else {
                        if LogLevel.debug { WriteToLog.shared.message("\n\n[RemoveEndpoints] No data was returned from delete.") }
                    }
                    
                    // look to see if we are processing the next endpointType - start
                    if endpointInProgress != endpointType || endpointInProgress == "" {
                        WriteToLog.shared.message("[RemoveEndpoints] Replicating \(endpointType)")
                        endpointInProgress = endpointType
                        Counter.shared.postSuccess = 0
                    }   // look to see if we are processing the next localEndPointType - end
                    
                    if httpResponse.statusCode > 199 && httpResponse.statusCode <= 299 {
                        WriteToLog.shared.message("    [RemoveEndpoints] [\(localEndPointType)] delete succeeded: \(endpointName)")
                        
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
                        updateCounts(endpointType: endpointType, endpointName: endpointName, result: "create", endpointCount: endpointCount, endpointCurrent: endpointCurrent, endPointID: endPointID)
//                        Counter.shared.postSuccess += 1
//                        
////                        if let _ = Counter.shared.progressArray["\(endpointType)"] {
////                            Counter.shared.progressArray["\(endpointType)"] = Counter.shared.progressArray["\(endpointType)"]!+1
////                        }
//                        Counter.shared.progressArray["\(endpointType)"] = (Counter.shared.progressArray["\(endpointType)"] == nil) ? 1 : Counter.shared.progressArray["\(endpointType)"]! + 1
//                        Counter.shared.crud[endpointType]?["create"]? += 1
////                        print(("[RevomeObjects.capi] Counter.shared.crud \(endpointType) - delete - \(endpointName) - success total: \(Counter.shared.crud[endpointType]?["create"] ?? 0)"))
//                        
//                        if var summaryArray = Counter.shared.summary[endpointType]?["create"] {
//                            let objectName = endpointName
//                            if !summaryArray.contains(objectName) {
//                                summaryArray.append(objectName)
//                                Counter.shared.summary[endpointType]?["create"] = summaryArray
//                            }
//                        }
                        
                    } else {
                        // remove failed
                        updateUiDelegate?.updateUi(info: ["function": "labelColor", "endpoint": endpointType, "theColor": "yellow"])
                        if (!Setting.migrateDependencies && endpointType != "patchpolicies") || ["patch-software-title-configurations", "policies"].contains(endpointType) {
                            if endPointID != "-1" {
                                updateUiDelegate?.updateUi(info: ["function": "setLevelIndicatorFillColor", "fn": "CreateEndpoints-\(endpointCurrent)", "endpointType": endpointType, "fillColor": NSColor.systemYellow])
                            }
                        }
                        
                        var localErrorMsg = ""
                        
                        //                            print("[RemoveEndpoints]   identifier: \(identifier)")
                        //                            print("[RemoveEndpoints] responseData: \(responseData)")
                        //                            print("[RemoveEndpoints]       status: \(httpResponse.statusCode)")
                        
                        let errorMsg = tagValue2(xmlString: responseData, startTag: "<p>Error: ", endTag: "</p>")
                        
                        errorMsg != "" ? (localErrorMsg = "delete error: \(errorMsg)"):(localErrorMsg = "delete error: \(tagValue2(xmlString: responseData, startTag: "<p>", endTag: "</p>"))")
                        
                        WriteToLog.shared.message("[RemoveEndpoints] [\(localEndPointType)] \(endpointName) - Failed (\(httpResponse.statusCode)).  \(localErrorMsg).\n")
                        
                        //                                    if LogLevel.debug { WriteToLog.shared.message("\n") }
                        if LogLevel.debug { WriteToLog.shared.message("[RemoveEndpoints] ---------- status code ----------") }
                        if LogLevel.debug { WriteToLog.shared.message("[RemoveEndpoints] \(httpResponse.statusCode)") }
                        if LogLevel.debug { WriteToLog.shared.message("[RemoveEndpoints] ---------- response data ----------\n\(responseData)") }
                        if LogLevel.debug { WriteToLog.shared.message("[RemoveEndpoints] -----------------------------------\n") }
                        
                        updateCounts(endpointType: endpointType, endpointName: endpointName, result: "fail", endpointCount: endpointCount, endpointCurrent: endpointCurrent, endPointID: endPointID)
//                        Counter.shared.crud[endpointType]?["fail"]! += 1
//                        if var summaryArray = Counter.shared.summary[endpointType]?["fail"] {
//                            let objectName = endpointName
//                            if !summaryArray.contains(objectName) {
//                                summaryArray.append(objectName)
//                                Counter.shared.summary[endpointType]?["fail"] = summaryArray
//                            }
//                        }
//                        
//                        if endPointID != "-1" {
//                            updateUiDelegate?.updateUi(info: ["function": "putStatusUpdate", "endpoint": endpointType, "total": Counter.shared.crud[endpointType]!["total"]!])
//                        }
                    }   // remove failed - end
                    
//                    Summary.totalCreated   = Counter.shared.crud[endpointType]?["create"] ?? 0
//                    Summary.totalFailed    = Counter.shared.crud[endpointType]?["fail"] ?? 0
//                    Summary.totalCompleted = Summary.totalCreated + Summary.totalFailed
                    
                    // update UI
//                    if Summary.totalCompleted > 0  {
//                        if (!Setting.migrateDependencies && endpointType != "patchpolicies") || ["patch-software-title-configurations", "policies"].contains(endpointType) {
//                            if endPointID != "-1" {
//                                updateUiDelegate?.updateUi(info: ["function": "putStatusUpdate", "endpoint": endpointType, "total": Counter.shared.crud[endpointType]!["total"]!])
//                            }
//                        }
//                    }
                    
                    
                    if Setting.fullGUI && Summary.totalCompleted == endpointCount {
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
                    completion("remove func: \(endpointCurrent) of \(endpointCount) complete.")
                } else {  // if let httpResponse = response - end
                    // update global counters - no http response
                    
                    updateCounts(endpointType: endpointType, endpointName: endpointName, result: "fail", endpointCount: endpointCount, endpointCurrent: endpointCurrent, endPointID: endPointID)
//                    let localTmp = (Counter.shared.crud[endpointType]?["fail"])!
//                    Counter.shared.crud[endpointType]?["fail"] = localTmp + 1
//                    if var summaryArray = Counter.shared.summary[endpointType]?["fail"] {
//                        let objectName = endpointName
//                        if summaryArray.contains(objectName) {
//                            summaryArray.append(objectName)
//                            Counter.shared.summary[endpointType]?["fail"] = summaryArray
//                        }
//                    }
                    
                    if Setting.fullGUI && Summary.totalCompleted == endpointCount {

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
                
                
//                Summary.totalCreated   = Counter.shared.crud[endpointType]?["create"] ?? 0
//                Summary.totalFailed    = Counter.shared.crud[endpointType]?["fail"] ?? 0
//                Summary.totalCompleted = Summary.totalCreated + Summary.totalFailed
//                
//                print("[RemoveEndpoints]   Summary.totalCreated: \(Summary.totalCreated)")
//                print("[RemoveEndpoints]    Summary.totalFailed: \(Summary.totalFailed)")
//                print("[RemoveEndpoints] Summary.totalCompleted: \(Summary.totalCompleted)")
//                print("[RemoveEndpoints] endPointID: \(endPointID)")
//                
//                if Summary.totalCompleted > 0  {
////                                print("[RemoveEndpoints] counters: \(counters)")
//                    if (endpointType != "patchpolicies") || ["patch-software-title-configurations", "policies"].contains(endpointType) {
//                        if endPointID != "-1" {
//                            updateUiDelegate?.updateUi(info: ["function": "putStatusUpdate", "endpoint": endpointType, "total": Counter.shared.crud[endpointType]!["total"]!])
//                        }
//                    }
//                }
                                
                if endpointCurrent > 0 {
                    if LogLevel.debug { WriteToLog.shared.message("[RemoveEndpoints] endpoint: \(localEndPointType)-\(endpointCurrent)\t Total: \(endpointCount)\t Succeeded: \(Counter.shared.postSuccess)\t Failed: \(Summary.totalFailed)\t SuccessArray \(Counter.shared.progressArray["\(localEndPointType)"] ?? 0)") }
                }
//                            semaphore.signal()
                if error != nil {
                }

                if endpointCurrent == endpointCount {
                    if LogLevel.debug { WriteToLog.shared.message("[RemoveEndpoints] Last item in \(localEndPointType) complete.") }
                    nodesMigrated+=1    // ;print("added node: \(localEndPointType) - createEndpoints")
//                    print("nodes complete: \(nodesMigrated)")
                }
            })
            task.resume()
            semaphore.wait()
            
        }   // SendQueue - end
    }
    
/*
    func jpapi(endpointType: String, endPointID: String, endpointName: String, endpointCurrent: Int, endpointCount: Int, completion: @escaping (_ result: String) -> Void) {
        logFunctionCall()
                
        if pref.stopMigration {
            updateUiDelegate?.updateUi(info: ["function": "stopButton"])
            completion("stop")
            return
        }

        if Counter.shared.crud[endpointType] == nil {
            Counter.shared.crud[endpointType] = ["create":0, "update":0, "fail":0, "skipped":0, "total":0]
        } else {
            Counter.shared.crud[endpointType]!["total"] = endpointCount
        }
        if Counter.shared.summary[endpointType] == nil {
            Counter.shared.summary[endpointType] = ["create":[], "update":[], "fail":[]]
        }
        
        var destinationEpId = endPointID
        var apiAction       = "DELETE"
                
        // counterts for completed endpoints
        if endpointCurrent == 1 {
            Summary.totalCreated   = 0
            Summary.totalUpdated   = 0
            Summary.totalFailed    = 0
            Summary.totalCompleted = 0
        }
        
        // this is where we create the new endpoint
        if !export.saveOnly {
            if LogLevel.debug { WriteToLog.shared.message("[removeEndpoints.jpapi] Creating new: \(endpointType)") }
        } else {
            if LogLevel.debug { WriteToLog.shared.message("[removeEndpoints.jpapi] Save only selected, skipping DELETE for: \(endpointType)") }
        }
        //if LogLevel.debug { WriteToLog.shared.message("[removeEndpoints.jpapi] ----- Posting #\(endpointCurrent): \(endpointType) -----") }
        
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
        
        print("[removeEndpoints.jpapi] AppInfo.dryRun: \(AppInfo.dryRun)")
        if AppInfo.dryRun {
            updateCounts(endpointType: endpointType, apiAction: "create", endPointJson: [:], localEndPointType: localEndPointType, endpointCount: endpointCurrent, endpointCurrent: endpointCurrent)
            completion("")
            return
        }
                
        if LogLevel.debug { WriteToLog.shared.message("[removeEndpoints.jpapi] Original Dest. URL: \(createDestUrlBase)") }
       
        SendQueue.shared.addOperation { [self] in
            if export.saveOnly {
                if ToMigrate.objects.last == localEndPointType && endpointCount == endpointCurrent {
                    updateUiDelegate?.updateUi(info: ["function": "rmDELETE"])
//                    print("[\(#function)] \(#line) - finished creating \(endpointType)")
                    updateUiDelegate?.updateUi(info: ["function": "goButtonEnabled", "button_status": true])
                }
                completion("")
                return
            }
            
            // don't create object if we're removing objects
            if !WipeData.state.on {
                if LogLevel.debug { WriteToLog.shared.message("[removeEndpoints.jpapi] Action: DELETE\t URL: \(createDestUrlBase)\t Object \(endpointCurrent) of \(endpointCount)") }
                if LogLevel.debug { WriteToLog.shared.message("[removeEndpoints.jpapi] Object JSON: \(endPointJSON)") }
    //            print("[removeEndpoints.jpapi] [\(localEndPointType)] process start: \(getName(endpoint: endpointType, objectXML: endPointXML))")
                
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
                    PatchManagementApi.shared.createUpdate(serverUrl: createDestUrlBase.replacingOccurrences(of: "/JSSResource", with: ""), endpoint: endpointType, apiData: endPointJSON, sourceEpId: sourceEpId, destEpId: destinationEpId, token: JamfProServer.authCreds["dest"] ?? "", method: "create") { [self]
                        (jpapiResonse: [String:Any]) in
    //                    print("[removeEndpoints.jpapi] returned from Jpapi.action, jpapiResonse: \(jpapiResonse)")
                        var jpapiResult = "succeeded"
                        if let _ = jpapiResonse["JPAPI_result"] as? String {
                            jpapiResult = jpapiResonse["JPAPI_result"] as! String
                        }
    //                    if let httpResponse = response as? HTTPURLResponse {
//                        var apiMethod = apiAction
                        if apiAction.lowercased() == "skip" || jpapiResult != "succeeded" {
//                            apiMethod = "fail"
                            DispatchQueue.main.async { [self] in
                                if Setting.fullGUI && apiAction.lowercased() != "skip" {
                                    updateUiDelegate?.updateUi(info: ["function": "labelColor", "endpoint": endpointType, "theColor": "yellow"])
                                    if (!Setting.migrateDependencies && endpointType != "patchpolicies") || ["patch-software-title-configurations", "policies"].contains(endpointType) {
                                        updateUiDelegate?.updateUi(info: ["function": "setLevelIndicatorFillColor", "fn": "CreateEndpoints-\(endpointCurrent)", "endpointType": endpointType, "fillColor": NSColor.systemYellow])
                                    }
                                }
                            }
                            WriteToLog.shared.message("    [removeEndpoints.jpapi] [\(localEndPointType)]    failed: \(endPointJSON["name"] ?? "unknown")")
                        } else {
                            WriteToLog.shared.message("    [removeEndpoints.jpapi] [\(localEndPointType)] succeeded: \(endPointJSON["name"] ?? "unknown")")
                            
                            if endpointCurrent == 1 && !retry {
                                migrationComplete.isDone = false
                                if (!Setting.migrateDependencies && endpointType != "patchpolicies") || ["patch-software-title-configurations", "policies"].contains(endpointType) {
                                    updateUiDelegate?.updateUi(info: ["function": "setLevelIndicatorFillColor", "fn": "CreateEndpoints-\(endpointCurrent)", "endpointType": endpointType, "fillColor": NSColor.green])
                                }
                            } else if !retry {
                                if let _ = PutLevelIndicator.shared.indicatorColor[endpointType] {
                                    updateUiDelegate?.updateUi(info: ["function": "setLevelIndicatorFillColor", "fn": "CreateEndpoints-\(endpointCurrent)", "endpointType": endpointType, "fillColor": PutLevelIndicator.shared.indicatorColor[endpointType] ?? NSColor.green])
                                }
                            }
                        }
                                                
                        // look to see if we are processing the next endpointType - start
                        if endpointInProgress != endpointType || endpointInProgress == "" {
                            WriteToLog.shared.message("[removeEndpoints.jpapi] Migrating \(endpointType)")
                            endpointInProgress = endpointType
                            Counter.shared.postSuccess = 0
                        }   // look to see if we are processing the next localEndPointType - end
                                             
                        Counter.shared.postSuccess += 1
                        
//                            print("endpointType: \(endpointType)")
//                            print("Counter.shared.progressArray: \(String(describing: Counter.shared.progressArray["\(endpointType)"]))")
                        
                        if let _ = Counter.shared.progressArray["\(endpointType)"] {
                            Counter.shared.progressArray["\(endpointType)"] = Counter.shared.progressArray["\(endpointType)"]!+1
                        }

                        Summary.totalCreated   = Counter.shared.crud[endpointType]?["create"] ?? 0
                        Summary.totalUpdated   = Counter.shared.crud[endpointType]?["update"] ?? 0
                        Summary.totalFailed    = Counter.shared.crud[endpointType]?["fail"] ?? 0
                        Summary.totalCompleted = Summary.totalCreated + Summary.totalUpdated + Summary.totalFailed
                        
                        // update counters
//                                print("[removeEndpoints.jpapi] endpointType: \(endpointType)")
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
                        
                        if LogLevel.debug { WriteToLog.shared.message("[removeEndpoints.jpapi] POST, PUT, or skip - operation: \(apiAction)") }
                        
                        if endpointCurrent > 0 {
                            if LogLevel.debug { WriteToLog.shared.message("[removeEndpoints.jpapi] endpoint: \(localEndPointType)-\(endpointCurrent)\t Total: \(endpointCount)\t Succeeded: \(Counter.shared.postSuccess)\t Failed: \(Summary.totalFailed)\t SuccessArray \(String(describing: Counter.shared.progressArray["\(localEndPointType)"]!))") }
                        }

        //                print("create func: \(endpointCurrent) of \(endpointCount) complete.  \(nodesMigrated) nodes migrated.")
                        if endpointCurrent == endpointCount {
                            if LogLevel.debug { WriteToLog.shared.message("[removeEndpoints.jpapi] Last item in \(localEndPointType) complete.") }
                            nodesMigrated+=1
                            // print("added node: \(localEndPointType) - createEndpoints")
        //                    print("nodes complete: \(nodesMigrated)")
                        }
                    }
                } else {
//                    print("[removeEndpoints.jpapi] \(#line) endPointJSON: \(endPointJSON)")
                    let nameAttribute = ["api-roles", "api-integrations"].contains(endpointType) ? "displayName" : "name"
                    Jpapi.shared.action(whichServer: "dest", endpoint: endpointType, apiData: endPointJSON, id: "\(destinationEpId)", token: JamfProServer.authCreds["dest"] ?? "", method: apiAction) { [self]
                        (jpapiResonse: [String:Any]) in
//                        print("[removeEndpoints.jpapi] returned from Jpapi.action, jpapiResonse: \(jpapiResonse)")
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
                            WriteToLog.shared.message("    [removeEndpoints.jpapi] [\(localEndPointType)]    failed: \(endPointJSON[nameAttribute] ?? "unknown")")
                        } else {
                            WriteToLog.shared.message("    [removeEndpoints.jpapi] [\(localEndPointType)] succeeded: \(endPointJSON[nameAttribute] ?? "unknown")")
                            
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
                                WriteToLog.shared.message("[removeEndpoints.jpapi] Migrating \(endpointType)")
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
                        
                        if LogLevel.debug { WriteToLog.shared.message("[removeEndpoints.jpapi] POST, PUT, or skip - operation: \(apiAction)") }
                        
                        if endpointCurrent > 0 {
                            if LogLevel.debug { WriteToLog.shared.message("[removeEndpoints.jpapi] endpoint: \(localEndPointType)-\(endpointCurrent)\t Total: \(endpointCount)\t Succeeded: \(Counter.shared.postSuccess)\t Failed: \(Summary.totalFailed)\t SuccessArray \(String(describing: Counter.shared.progressArray["\(localEndPointType)"]!))") }
                        }

        //                print("create func: \(endpointCurrent) of \(endpointCount) complete.  \(nodesMigrated) nodes migrated.")
                        if endpointCurrent == endpointCount {
                            if LogLevel.debug { WriteToLog.shared.message("[removeEndpoints.jpapi] Last item in \(localEndPointType) complete.") }
                            nodesMigrated+=1
                            // print("added node: \(localEndPointType) - createEndpoints")
        //                    print("nodes complete: \(nodesMigrated)")
                        }
                    }
                }
                
            }   // if !WipeData.state.on - end
        }   // SendQueue - end
    }
*/
}
