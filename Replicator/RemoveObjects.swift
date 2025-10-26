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
            
                
            if export.saveRawXml {
                EndpointData.shared.getById(endpoint: endpointType, endpointID: endPointID, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: "", destEpId: "0", destEpName: endpointName) { [self]
                    (result: String) in
                    
//                    print("[RemoveEndpoints.queue]      endPointID: \(endPointID)")
//                    print("[RemoveEndpoints.queue]    endpointName: \(endpointName)")
//                    print("[RemoveEndpoints.queue] endpointCurrent: \(endpointCurrent)")
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
    
    fileprivate func updateCounts(endpointType: String, endpointName: String, result: String, endpointCount: Int, endpointCurrent: Int, endPointID: String) {
        
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
//        print("[RemoveEndpoints.updateCounts] \(apiAction) endpointType: \(endpointType)")
        
        Summary.totalCreated   = Counter.shared.crud[endpointType]?["create"] ?? 0
        Summary.totalFailed    = Counter.shared.crud[endpointType]?["fail"] ?? 0
        Summary.totalCompleted = Summary.totalCreated + Summary.totalFailed
        
        if var summaryArray = Counter.shared.summary[endpointType]?[result] {
            summaryArray.append(endpointName)
            Counter.shared.summary[endpointType]?[result] = summaryArray
        }
        
//        print("[RemoveEndpoints.updateCounts]   Summary.totalCreated: \(Summary.totalCreated)")
//        print("[RemoveEndpoints.updateCounts]    Summary.totalFailed: \(Summary.totalFailed)")
//        print("[RemoveEndpoints.updateCounts] Summary.totalCompleted: \(Summary.totalCompleted)")
        
        if Summary.totalCompleted > 0  {
//                                print("[RemoveEndpoints.updateCounts] counters: \(counters)")
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
        
        // this is where we remove the new endpoint
        if LogLevel.debug { WriteToLog.shared.message("[RemoveEndpoints] Removing: \(endpointType), - name: \(endpointName), id: \(endPointID)") }

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
                        
                        if LogLevel.debug { WriteToLog.shared.message("[RemoveEndpoints] ---------- status code ----------") }
                        if LogLevel.debug { WriteToLog.shared.message("[RemoveEndpoints] \(httpResponse.statusCode)") }
                        if LogLevel.debug { WriteToLog.shared.message("[RemoveEndpoints] ---------- response data ----------\n\(responseData)") }
                        if LogLevel.debug { WriteToLog.shared.message("[RemoveEndpoints] -----------------------------------\n") }
                        
                        updateCounts(endpointType: endpointType, endpointName: endpointName, result: "fail", endpointCount: endpointCount, endpointCurrent: endpointCurrent, endPointID: endPointID)
                    }   // remove failed - end
                    
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
}
