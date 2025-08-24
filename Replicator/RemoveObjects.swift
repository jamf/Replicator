//
//  RemoveObjects.swift
//  Replicator
//
//  Created by leslie on 12/3/24.
//  Copyright © 2024 Jamf. All rights reserved.
//

import AppKit
import Foundation

class RemoveObjects: NSObject, URLSessionDelegate {
    
    static let shared    = RemoveObjects()
    var updateUiDelegate: UpdateUiDelegate?
    func updateView(_ info: [String: Any]) {
        logFunctionCall()
        updateUiDelegate?.updateUi(info: info)
    }
    
    private let lockQueue          = DispatchQueue(label: "lock.queue")
    private let putStatusLockQueue = DispatchQueue(label: "putStatusLock.queue")
    private let removeMeterQ       = OperationQueue() 
    private let removeObjectQ      = OperationQueue() 
    
    var removeArray          = [ObjectInfo]()
    
    func queue(endpointType: String, endPointID: String, endpointName: String, endpointCurrent: Int, endpointCount: Int) {
        logFunctionCall()
        
        if endpointCurrent == 1 {
            Counter.shared.crud[endpointType]!["total"] = endpointCount
        }
        
        SendQueue.shared.addOperation { [self] in
            
            let theObject = ObjectInfo(endpointType: endpointType, endPointXml: endpointName, endPointJSON: [:], endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: "", sourceEpId: -1, destEpId: endPointID, ssIconName: "", ssIconId: "", ssIconUri: "", retry: false)
                        
            capi(endpointType: theObject.endpointType, endPointID: "\(theObject.destEpId)", endpointName: theObject.endPointXml, endpointCurrent: theObject.endpointCurrent, endpointCount: theObject.endpointCount) {
                (result: String) in
            }
        }
    }
    
    func capi(endpointType: String, endPointID: String, endpointName: String, endpointCurrent: Int, endpointCount: Int, completion: @escaping (_ result: String) -> Void) {
        
        logFunctionCall()
        if endPointID == "-1" && UiVar.activeTab == "Selective" {
//            WriteToLog.shared.message("[removeEndpoints] selective - finished removing \(endpointType)")
            completion("-1")
            return
        }

        if LogLevel.debug { WriteToLog.shared.message("[RemoveEndpoints] enter") }

        var removeDestUrl = ""
                
        if endpointCurrent == 1 {
            if (!Setting.migrateDependencies && endpointType != "patchpolicies") || ["patch-software-title-configurations", "policies"].contains(endpointType) {
                updateView(["function": "setLevelIndicatorFillColor", "fn": "RemoveObjects.capi-\(endpointCurrent)", "endpointType": endpointType, "fillColor": NSColor.green])
            }
        } else {
            if let _ = PutLevelIndicator.shared.indicatorColor[endpointType] /* self.put_levelIndicatorFillColor[endpointType] */{
                if Setting.migrateDependencies {
                    updateView(["function": "setLevelIndicatorFillColor", "fn": "RemoveObjects.capi-\(endpointCurrent)", "endpointType": endpointType, "fillColor": PutLevelIndicator.shared.indicatorColor[endpointType] ?? NSColor.green])
                }
            }
        }
        
        // whether the operation was successful or not, either delete or fail
        var methodResult = "create"
        
        var localEndPointType = ""
        switch endpointType {
        case "smartcomputergroups", "staticcomputergroups":
            localEndPointType = "computergroups"
        case "smartmobiledevicegroups", "staticmobiledevicegroups":
            localEndPointType = "mobiledevicegroups"
        case "smartusergroups", "staticusergroups":
            localEndPointType = "usergroups"
        case "patch-software-title-configurations":
            localEndPointType = "patch-software-title-configurations"
        default:
            localEndPointType = endpointType
        }

        if endpointName != "All Managed Clients" && endpointName != "All Managed Servers" && endpointName != "All Managed iPads" && endpointName != "All Managed iPhones" && endpointName != "All Managed iPod touches" {
            
            switch localEndPointType {
            case "patch-software-title-configurations":
                removeDestUrl = "\(JamfProServer.destination)/api/v2/patch-software-title-configurations/\(endPointID)"
            case "api-roles", "api-integrations":
                removeDestUrl = "\(JamfProServer.destination)/api/v1/\(localEndPointType)/\(endPointID)"
            default:
                removeDestUrl = "\(JamfProServer.destination)/JSSResource/" + localEndPointType + "/id/\(endPointID)"
                if LogLevel.debug { WriteToLog.shared.message("[RemoveEndpoints] raw removal URL: \(removeDestUrl)") }
                removeDestUrl = removeDestUrl.urlFix
    //            removeDestUrl = removeDestUrl.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
                removeDestUrl = removeDestUrl.replacingOccurrences(of: "/JSSResource/jamfusers/id", with: "/JSSResource/accounts/userid")
                removeDestUrl = removeDestUrl.replacingOccurrences(of: "/JSSResource/jamfgroups/id", with: "/JSSResource/accounts/groupid")
                removeDestUrl = removeDestUrl.replacingOccurrences(of: "id/id/", with: "id/")
            }
            
            if export.saveRawXml {
                //change to endpointByIDQueue?
                EndpointXml.shared.getById(endpoint: endpointType, endpointID: "\(endPointID)", endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: "", destEpId: "0", destEpName: endpointName) {
//                endPointByID(endpoint: endpointType, endpointID: "\(endPointID)", endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: "", destEpId: 0, destEpName: endpointName) {
                    (result: String) in
                }
            }
            if export.saveOnly {
                if endpointCurrent == endpointCount {
                    if LogLevel.debug { WriteToLog.shared.message("[removeEndpoints] Last item in \(localEndPointType) complete.") }
                    nodesMigrated+=1    // ;print("added node: \(localEndPointType) - removeEndpoints")
                    //            print("remove nodes complete: \(nodesMigrated)")
                }
                return
            }
            
            SendQueue.shared.addOperation {
                        
                DispatchQueue.main.async {
                    // look to see if we are processing the next endpointType - start
                    if endpointInProgress != endpointType || endpointInProgress == "" {
                        endpointInProgress = endpointType
                        UiVar.changeColor  = true
                        Counter.shared.postSuccess = 0
                        WriteToLog.shared.message("[RemoveEndpoints] removing \(endpointType)")
                    }   // look to see if we are processing the next endpointType - end
                }
                
                if LogLevel.debug { WriteToLog.shared.message("[RemoveEndpoints] removing \(endpointType) with ID \(endPointID)  -  Object \(endpointCurrent) of \(endpointCount)") }
                if LogLevel.debug { WriteToLog.shared.message("[RemoveEndpoints] removal URL: \(removeDestUrl)") }
                
                let encodedURL = URL(string: removeDestUrl)
                let request = NSMutableURLRequest(url: encodedURL! as URL)
                request.httpMethod = "DELETE"
                let configuration = URLSessionConfiguration.ephemeral
                
                configuration.httpAdditionalHeaders = ["Authorization" : "\(JamfProServer.authType["dest"] ?? "Bearer") \(JamfProServer.authCreds["dest"] ?? "")", "Content-Type" : "text/xml", "Accept" : "text/xml", "User-Agent" : AppInfo.userAgentHeader]
                
                var headers = [String: String]()
                for (header, value) in configuration.httpAdditionalHeaders ?? [:] {
                    headers[header as! String] = (header as! String == "Authorization") ? "Bearer ************" : value as? String
                }
                print("[apiCall] \(#function.description) method: \(request.httpMethod)")
                print("[apiCall] \(#function.description) headers: \(headers)")
                print("[apiCall] \(#function.description) endpoint: \(encodedURL?.absoluteString ?? "")")
                print("")

                let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
                
                let semaphore = DispatchSemaphore(value: 0)
                
                let task = session.dataTask(with: request as URLRequest, completionHandler: { [self]
                    (data, response, error) -> Void in
                    
                    defer { semaphore.signal() }
                    session.finishTasksAndInvalidate()
                    
                    completion("\(endPointID)")
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        WriteToLog.shared.message("[RemoveEndpoints] \(#line) id \(endpointCurrent) removed response code: \(httpResponse.statusCode)")
                        //print(httpResponse)
                        if httpResponse.statusCode >= 199 && httpResponse.statusCode <= 299 {
                            // remove items from the list as they are removed from the server
                            if UiVar.activeTab == "Selective" {
                                //                                print("endPointID: \(endPointID)")
                                
                                let lineNumber = SourceObjects.list.firstIndex(where: {$0.objectId == endPointID})!
                                let objectToRemove = SourceObjects.list[lineNumber].objectName
                                
                                DataArray.staticSource.removeAll(where: { $0 == objectToRemove})
//                                        print("[removeEndpoints] DataArray.staticSource:\(DataArray.staticSource)")
                                                                    
                                var objectIndex = SourceObjects.list.firstIndex(where: { $0.objectName == objectToRemove })
                                updateView(["function": "sourceObjectList_AC.remove", "objectId": endPointID as Any])

                                objectIndex = staticSourceObjectList.firstIndex(where: { $0.objectId == endPointID })
                                staticSourceObjectList.remove(at: objectIndex!)
                            }
                            
                            WriteToLog.shared.message("    [RemoveEndpoints] [\(endpointType)] \(endpointName) (id: \(endPointID))")
                            Counter.shared.postSuccess += 1
                        } else if endpointCurrent != -1 {
                            methodResult = "fail"
                            updateView(["function": "labelColor", "endpoint": endpointType, "theColor": "yellow"])
//                            labelColor(endpoint: endpointType, theColor: self.yellowText)
                            if (!Setting.migrateDependencies && endpointType != "patchpolicies") || ["patch-software-title-configurations", "policies"].contains(endpointType) {
                                PutLevelIndicator.shared.indicatorColor[endpointType]  = .systemYellow
                                updateView(["function": "put_levelIndicator", "fillColor": PutLevelIndicator.shared.indicatorColor[endpointType] as Any])
                            }
                            UiVar.changeColor  = false
                            WriteToLog.shared.message("    [RemoveEndpoints] [\(endpointType)] **** Failed to remove: \(endpointName) (id: \(endPointID)), statusCode: \(httpResponse.statusCode)")
                            
                            if httpResponse.statusCode == 400 {
                                WriteToLog.shared.message("    [RemoveEndpoints] [\(endpointType)]      Verify other items are not dependent on \(endpointName) (id: \(endPointID))")
                                WriteToLog.shared.message("    [RemoveEndpoints] [\(endpointType)]      For example, \(endpointName) is not used in a policy")
                            }
                            
                            if LogLevel.debug { WriteToLog.shared.message("\n") }
                            if LogLevel.debug { WriteToLog.shared.message("[RemoveEndpoints] ---------- endpoint info ----------") }
                            if LogLevel.debug { WriteToLog.shared.message("[RemoveEndpoints] Type: \(endpointType)\t Name: \(endpointName)\t id: \(endPointID)") }
                            if LogLevel.debug { WriteToLog.shared.message("[RemoveEndpoints] ---------- status code ----------") }
                            if LogLevel.debug { WriteToLog.shared.message("[RemoveEndpoints] \(httpResponse.statusCode)") }
                            if LogLevel.debug { WriteToLog.shared.message("[RemoveEndpoints] ---------- response ----------") }
                            if LogLevel.debug { WriteToLog.shared.message("[RemoveEndpoints] \n\(String(data: data ?? Data(), encoding: .utf8) ?? "unknown")") }
                            if LogLevel.debug { WriteToLog.shared.message("[RemoveEndpoints] ---------- response ----------\n") }
                        }
                        
                        if endPointID != "-1" {
                            // update global counters
                            //                        let localTmp = (Counter.shared.crud[endpointType]?[methodResult])!
                            Counter.shared.crud[endpointType]?[methodResult]! += 1

                            if var summaryArray = Counter.shared.summary[endpointType]?[methodResult] {
                                if summaryArray.firstIndex(of: endpointName) == nil {
                                    summaryArray.append(endpointName)
                                    Counter.shared.summary[endpointType]?[methodResult] = summaryArray
                                }
                            }
                            
                            
                            putStatusLockQueue.async { [self] in
                                Summary.totalDeleted   = Counter.shared.crud[endpointType]?["create"] ?? 0
                                Summary.totalFailed    = Counter.shared.crud[endpointType]?["fail"] ?? 0
                                Summary.totalCompleted = Summary.totalDeleted + Summary.totalFailed
                                //                        DispatchQueue.main.async { [self] in
                                if Summary.totalCompleted > 0 {
                                    updateView(["function": "putStatusUpdate", "endpoint": endpointType, "total": Counter.shared.crud[endpointType]!["total"]!])
                                }
                                
                                if Summary.totalDeleted == endpointCount && UiVar.changeColor  {
                                    updateView(["function": "labelColor", "endpoint": endpointType, "theColor": "green"])
                                    //                                labelColor(endpoint: endpointType, theColor: greenText)
                                } else if Summary.totalFailed == endpointCount {
                                    updateView(["function": "labelColor", "endpoint": endpointType, "theColor": "red"])
                                    //                                labelColor(endpoint: endpointType, theColor: redText)
                                    updateView(["function": "setLevelIndicatorFillColor", "fn": "RemoveObjects.capi-\(endpointCurrent)", "endpointType": endpointType, "fillColor": NSColor.systemRed])
                                    //                                setLevelIndicatorFillColor(fn: "RemoveEndpoints-\(endpointCurrent)", endpointType: endpointType, fillColor: .systemRed)
                                }
                            }
                        }
                    }
                    
                    if UiVar.activeTab != "selective" {
                        //                        print("localEndPointType: \(localEndPointType) \t count: \(endpointCount)")
                        if ToMigrate.objects.last == localEndPointType && endPointID == "-1" /*(endpointCount == endpointCurrent || endpointCount == 0)*/ {
                            // check for file that allows deleting data from destination server, delete if found - start
                            updateView(["function": "rmDELETE"])
                            JamfProServer.validToken["source"] = false
                            JamfProServer.version["source"]    = ""
                            //                            print("[removeEndpoints] endpoint: \(endpointType)")
                            if LogLevel.debug { WriteToLog.shared.message("[removeEndpoints] endpoint: \(endpointType)") }
                            //                            self.resetAllCheckboxes()
                            // check for file that allows deleting data from destination server, delete if found - end

                            updateView(["function": "goButtonEnabled", "button_status": true])
                            if LogLevel.debug { WriteToLog.shared.message("Done") }
                        }
                        if error != nil {
                        }
                    } else {
                        // selective
                        if LogLevel.debug { WriteToLog.shared.message("[removeEndpoints] endpointCount: \(endpointCount)\t endpointCurrent: \(endpointCurrent)") }
                        
                        if endpointCount == endpointCurrent {
                            // check for file that allows deleting data from destination server, delete if found - start
                            updateView(["function": "rmDELETE"])
                            JamfProServer.validToken["source"] = false
                            JamfProServer.version["source"]    = ""
                            if LogLevel.debug { WriteToLog.shared.message("[removeEndpoints] endpoint: \(endpointType)") }
                            //                            print("[removeEndpoints] endpoint: \(endpointType)")
                            //                            self.resetAllCheckboxes()
                            // check for file that allows deleting data from destination server, delete if found - end
                            //self.go_button.isEnabled = true
//                            print("[\(#function)] \(#line) selective - finished removing \(endpointType)")
                            updateView(["function": "goButtonEnabled", "button_status": true])
                            if LogLevel.debug { WriteToLog.shared.message("Done") }
                        }
                    }
                    if endpointCurrent == endpointCount {
                        WriteToLog.shared.message("[removeEndpoints] Last item in \(localEndPointType) complete.")
                        nodesMigrated += 1
                        //            print("remove nodes complete: \(nodesMigrated)")
                    }
                })  // let task = session.dataTask - end
                task.resume()
                
                // Wait until task completes before exiting the Operation
                semaphore.wait()
            }   // removeObjectQ.addOperation - end
        }
    }
}
