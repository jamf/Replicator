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
        updateUiDelegate?.updateUi(info: info)
    }
    
    private let lockQueue          = DispatchQueue(label: "lock.queue")
    private let putStatusLockQueue = DispatchQueue(label: "putStatusLock.queue")
    private let removeMeterQ       = OperationQueue() //DispatchQueue(label: "com.jamf.removeEPs", qos: DispatchQoS.background)
    private let removeObjectQ      = OperationQueue() //DispatchQueue(label: "com.jamf.removeEPs", qos: DispatchQoS.background)
    
    var removeArray          = [ObjectInfo]()
    
    func queue(endpointType: String, endPointID: String, endpointName: String, endpointCurrent: Int, endpointCount: Int) {

        if endpointCurrent == 1 {
            Counter.shared.crud[endpointType]!["total"] = endpointCount
        }
        
        removeMeterQ.maxConcurrentOperationCount = 4
        let semaphore = DispatchSemaphore(value: 0)
        
        removeMeterQ.addOperation { [self] in
            lockQueue.async { [self] in
//                print("[removeEndpointQueue] add \(endpointType) with id \(endPointID) to removeArray")
                removeArray.append(ObjectInfo(endpointType: endpointType, endPointXml: endpointName, endPointJSON: [:], endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: "", sourceEpId: -1, destEpId: endPointID, ssIconName: "", ssIconId: "", ssIconUri: "", retry: false))
//                print("[removeEndpointQueue] added \(endpointType) with id \(endPointID) to removeArray, removeArray.count: \(removeArray.count)")
            }
            var breakQueue = false
            lockQueue.async { [self] in
                while removeArray.count > 0 {
//                    print("[removeEndpointsQueue] 1 Counter.shared.pendingSend: \(Counter.shared.pendingSend), removeArray.count: \(removeArray.count)")
                    if Counter.shared.pendingSend < removeMeterQ.maxConcurrentOperationCount && removeArray.count > 0 {
                        Counter.shared.pendingSend += 1
//                        updatePendingCounter(caller: #function.short, change: 1)
                        usleep(10)
                        let nextEndpoint = removeArray.remove(at: 0)
                        
                        print("[removeEndpointsQueue] call removeEndpoints to removed id: \(nextEndpoint.destEpId)")
                        capi(endpointType: nextEndpoint.endpointType, endPointID: "\(nextEndpoint.destEpId)", endpointName: nextEndpoint.endPointXml, endpointCurrent: nextEndpoint.endpointCurrent, endpointCount: nextEndpoint.endpointCount) {
                            (result: String) in
                            
                            if result == "-1" {
                                breakQueue = true
                            } else {
                                Counter.shared.pendingSend -= 1
//                                updatePendingCounter(caller: #function.short, change: -1)
                            }
                            semaphore.signal()
                        }
                    } else {
                        print("[removeEndpointsQueue] 2 Counter.shared.pendingSend: \(Counter.shared.pendingSend), removeArray.count: \(removeArray.count)")
                        sleep(1)
                        if Counter.shared.pendingSend == 0 && removeArray.count == 0 && breakQueue { break }
                    }
                    semaphore.wait()
                }   // while Counter.shared.pendingSend > 0 || removeArray.count > 0
            }
        }
    }
    
    func capi(endpointType: String, endPointID: String, endpointName: String, endpointCurrent: Int, endpointCount: Int, completion: @escaping (_ result: String) -> Void) {
        
        if endPointID == "-1" && UiVar.activeTab == "Selective" {
            print("[removeEndpoints] selective - finished removing \(endpointType)")
            completion("-1")
            return
        }

        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[RemoveEndpoints] enter") }

        var removeDestUrl = ""
                
        if endpointCurrent == 1 {
            if !setting.migrateDependencies || ["patch-software-title-configurations", "policies"].contains(endpointType) {
                updateView(["function": "setLevelIndicatorFillColor", "fn": "RemoveObjects.capi-\(endpointCurrent)", "endpointType": endpointType, "fillColor": NSColor.green])
//                setLevelIndicatorFillColor(fn: "RemoveEndpoints-\(endpointCurrent), line: \(#line)", endpointType: endpointType, fillColor: .green)
            }
        } else {
            if let _ = PutLevelIndicator.shared.indicatorColor[endpointType] /* self.put_levelIndicatorFillColor[endpointType] */{
                if setting.migrateDependencies {
                    updateView(["function": "setLevelIndicatorFillColor", "fn": "RemoveObjects.capi-\(endpointCurrent)", "endpointType": endpointType, "fillColor": PutLevelIndicator.shared.indicatorColor[endpointType] ?? NSColor.green])
//                        self.setLevelIndicatorFillColor(fn: "RemoveEndpoints-\(endpointCurrent), line: \(#line)", endpointType: endpointType, fillColor: PutLevelIndicator.shared.indicatorColor[endpointType] ?? .green)
                }
            }
        }
        
        // whether the operation was successful or not, either delete or fail
        var methodResult = "create"
        
        removeObjectQ.maxConcurrentOperationCount = maxConcurrentThreads
        
//        let semaphore = DispatchSemaphore(value: 0)
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
            default:
                removeDestUrl = "\(JamfProServer.destination)/JSSResource/" + localEndPointType + "/id/\(endPointID)"
                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[RemoveEndpoints] raw removal URL: \(removeDestUrl)") }
                removeDestUrl = removeDestUrl.urlFix
    //            removeDestUrl = removeDestUrl.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
                removeDestUrl = removeDestUrl.replacingOccurrences(of: "/JSSResource/jamfusers/id", with: "/JSSResource/accounts/userid")
                removeDestUrl = removeDestUrl.replacingOccurrences(of: "/JSSResource/jamfgroups/id", with: "/JSSResource/accounts/groupid")
                removeDestUrl = removeDestUrl.replacingOccurrences(of: "id/id/", with: "id/")
            }
            print("[removeEndpoints] removeDestUrl: \(removeDestUrl)\n")
            
            
            if export.saveRawXml {
                //change to endpointByIDQueue?
                EndpointXml.shared.getById(endpoint: endpointType, endpointID: "\(endPointID)", endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: "", destEpId: "0", destEpName: endpointName) {
//                endPointByID(endpoint: endpointType, endpointID: "\(endPointID)", endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: "", destEpId: 0, destEpName: endpointName) {
                    (result: String) in
                }
            }
            if export.saveOnly {
                if endpointCurrent == endpointCount {
                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[removeEndpoints] Last item in \(localEndPointType) complete.") }
                    nodesMigrated+=1    // ;print("added node: \(localEndPointType) - removeEndpoints")
                    //            print("remove nodes complete: \(nodesMigrated)")
                }
                return
            }
            
            removeObjectQ.addOperation {
                        
                DispatchQueue.main.async {
                    // look to see if we are processing the next endpointType - start
                    if endpointInProgress != endpointType || endpointInProgress == "" {
                        endpointInProgress = endpointType
                        UiVar.changeColor  = true
                        Counter.shared.postSuccess = 0
                        WriteToLog.shared.message(stringOfText: "[RemoveEndpoints] Removing \(endpointType)")
                    }   // look to see if we are processing the next endpointType - end
                }
                
                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[RemoveEndpoints] removing \(endpointType) with ID \(endPointID)  -  Object \(endpointCurrent) of \(endpointCount)") }
                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[RemoveEndpoints] removal URL: \(removeDestUrl)") }
                
                let encodedURL = URL(string: removeDestUrl)
                let request = NSMutableURLRequest(url: encodedURL! as URL)
                request.httpMethod = "DELETE"
                let configuration = URLSessionConfiguration.ephemeral
                
                configuration.httpAdditionalHeaders = ["Authorization" : "\(JamfProServer.authType["dest"] ?? "Bearer") \(JamfProServer.authCreds["dest"] ?? "")", "Content-Type" : "text/xml", "Accept" : "text/xml", "User-Agent" : AppInfo.userAgentHeader]
                
                let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
                let task = session.dataTask(with: request as URLRequest, completionHandler: { [self]
                    (data, response, error) -> Void in
                    session.finishTasksAndInvalidate()
                    
                    completion("\(endPointID)")
                    
                    print("[RemoveEndpoints] \(#line) removeObjectQ.operationCount: \(removeObjectQ.operationCount)")
                    if let httpResponse = response as? HTTPURLResponse {
                        print("[RemoveEndpoints] \(#line) removed response code: \(httpResponse.statusCode)")
                        //print(httpResponse)
                        if httpResponse.statusCode >= 199 && httpResponse.statusCode <= 299 {
                            // remove items from the list as they are removed from the server
                            if UiVar.activeTab == "Selective" {
                                //                                print("endPointID: \(endPointID)")
                                
                                let lineNumber = SourceObjects.list.firstIndex(where: {$0.objectId == endPointID})!
                                let objectToRemove = SourceObjects.list[lineNumber].objectName
                                
                                DataArray.staticSource.removeAll(where: { $0 == objectToRemove})
//                                        print("[removeEndpoints] DataArray.staticSource:\(DataArray.staticSource)")
                                /*
                                if let staticLineNumber = ( endpointType == "policies" ) ? DataArray.staticSource.firstIndex(of: "\(objectToRemove) (\(endPointID))"):DataArray.staticSource.firstIndex(of: objectToRemove) {
                                    DataArray.staticSource.remove(at: staticLineNumber)
                                }
                                 */
                                
                                DispatchQueue.main.async { [self] in
                                    
//                                    var objectIndex = (self.sourceObjectList_AC.arrangedObjects as! [SelectiveObject]).firstIndex(where: { $0.objectName == objectToRemove })
                                    var objectIndex = SourceObjects.list.firstIndex(where: { $0.objectName == objectToRemove })
                                    updateView(["function": "sourceObjectList_AC.remove", "objectId": endPointID as Any])
//                                    updateView(["function": "sourceObjectList_AC.remove", "objectIndex": objectIndex as Any])

                                    objectIndex = staticSourceObjectList.firstIndex(where: { $0.objectId == endPointID })
                                    staticSourceObjectList.remove(at: objectIndex!)
                                    
//                                    srcSrvTableView.isEnabled = false
                                }
                            }
                            
                            WriteToLog.shared.message(stringOfText: "    [RemoveEndpoints] [\(endpointType)] \(endpointName) (id: \(endPointID))")
                            Counter.shared.postSuccess += 1
                        } else {
                            methodResult = "fail"
                            updateView(["function": "labelColor", "endpoint": endpointType, "theColor": "yellow"])
//                            labelColor(endpoint: endpointType, theColor: self.yellowText)
                            if !setting.migrateDependencies || ["patch-software-title-configurations", "policies"].contains(endpointType) {
                                PutLevelIndicator.shared.indicatorColor[endpointType]  = .systemYellow
                                updateView(["function": "put_levelIndicator", "fillColor": PutLevelIndicator.shared.indicatorColor[endpointType] as Any])
                            }
                            UiVar.changeColor  = false
                            WriteToLog.shared.message(stringOfText: "    [RemoveEndpoints] [\(endpointType)] **** Failed to remove: \(endpointName) (id: \(endPointID)), statusCode: \(httpResponse.statusCode)")
                            
                            if httpResponse.statusCode == 400 {
                                WriteToLog.shared.message(stringOfText: "    [RemoveEndpoints] [\(endpointType)]      Verify other items are not dependent on \(endpointName) (id: \(endPointID))")
                                WriteToLog.shared.message(stringOfText: "    [RemoveEndpoints] [\(endpointType)]      For example, \(endpointName) is not used in a policy")
                            }
                            
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "\n") }
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[RemoveEndpoints] ---------- endpoint info ----------") }
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[RemoveEndpoints] Type: \(endpointType)\t Name: \(endpointName)\t id: \(endPointID)") }
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[RemoveEndpoints] ---------- status code ----------") }
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[RemoveEndpoints] \(httpResponse.statusCode)") }
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[RemoveEndpoints] ---------- response ----------") }
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[RemoveEndpoints] \(httpResponse)") }
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[RemoveEndpoints] ---------- response ----------\n") }
                        }
                        
                        // update global counters
//                        let localTmp = (Counter.shared.crud[endpointType]?[methodResult])!
                        Counter.shared.crud[endpointType]?[methodResult]! += 1
                        if var summaryArray = Counter.shared.summary[endpointType]?[methodResult] {
                            if summaryArray.firstIndex(of: endpointName) == nil {
                                summaryArray.append(endpointName)
                                Counter.shared.summary[endpointType]?[methodResult] = summaryArray
                            }
                        }
                        
                        Summary.totalDeleted   = Counter.shared.crud[endpointType]?["create"] ?? 0
                        Summary.totalFailed    = Counter.shared.crud[endpointType]?["fail"] ?? 0
                        Summary.totalCompleted = Summary.totalDeleted + Summary.totalFailed
                        
                        putStatusLockQueue.async { [self] in
//                        DispatchQueue.main.async { [self] in
                            if Summary.totalCompleted > 0 {
                                print("[\(#function)] total: \(Counter.shared.crud[endpointType]!["total"]!)")
                                updateUiDelegate?.updateUi(info: ["function": "putStatusUpdate2", "endpoint": endpointType, "total": Counter.shared.crud[endpointType]!["total"]!])
//                                putStatusUpdate2(endpoint: endpointType, total: Counter.shared.crud[endpointType]!["total"]!)
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
                    
                    if UiVar.activeTab != "selective" {
                        //                        print("localEndPointType: \(localEndPointType) \t count: \(endpointCount)")
                        if ToMigrate.objects.last == localEndPointType && endPointID == "-1" /*(endpointCount == endpointCurrent || endpointCount == 0)*/ {
                            // check for file that allows deleting data from destination server, delete if found - start
                            updateView(["function": "rmDELETE"])
                            JamfProServer.validToken["source"] = false
                            JamfProServer.version["source"]    = ""
                            //                            print("[removeEndpoints] endpoint: \(endpointType)")
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[removeEndpoints] endpoint: \(endpointType)") }
                            //                            self.resetAllCheckboxes()
                            // check for file that allows deleting data from destination server, delete if found - end
                            print("[\(#function)] bulk - finished removing \(endpointType)")
                            updateView(["function": "goButtonEnabled", "button_status": true])
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "Done") }
                        }
                        if error != nil {
                        }
                    } else {
                        // selective
                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[removeEndpoints] endpointCount: \(endpointCount)\t endpointCurrent: \(endpointCurrent)") }
                        
                        if endpointCount == endpointCurrent {
                            // check for file that allows deleting data from destination server, delete if found - start
                            updateView(["function": "rmDELETE"])
                            JamfProServer.validToken["source"] = false
                            JamfProServer.version["source"]    = ""
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[removeEndpoints] endpoint: \(endpointType)") }
                            //                            print("[removeEndpoints] endpoint: \(endpointType)")
                            //                            self.resetAllCheckboxes()
                            // check for file that allows deleting data from destination server, delete if found - end
                            //self.go_button.isEnabled = true
//                            print("[\(#function)] \(#line) selective - finished removing \(endpointType)")
                            updateView(["function": "goButtonEnabled", "button_status": true])
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "Done") }
                        }
                    }
                    if endpointCurrent == endpointCount {
                        WriteToLog.shared.message(stringOfText: "[removeEndpoints] Last item in \(localEndPointType) complete.")
                        nodesMigrated += 1
                        //            print("remove nodes complete: \(nodesMigrated)")
                    }
                })  // let task = session.dataTask - end
                task.resume()
            }   // removeObjectQ.addOperation - end
        }
        // moved 241026
//        if endpointCurrent == endpointCount {
//            WriteToLog.shared.message(stringOfText: "[removeEndpoints] Last item in \(localEndPointType) complete.")
//            nodesMigrated += 1
//            //            print("remove nodes complete: \(nodesMigrated)")
//        }
    }
    
    
}
