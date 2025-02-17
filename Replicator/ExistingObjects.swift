//
//  ExistingObjects.swift
//  Replicator
//
//  Created by leslie on 12/2/24.
//  Copyright © 2024 Jamf. All rights reserved.
//

import Foundation

class ExistingObjects: NSObject, URLSessionDelegate {
    
    static let shared    = ExistingObjects()
    var existingObjectsQ = OperationQueue() // DispatchQueue(label: "com.jamf.existingObjectsQ", qos: DispatchQoS.utility)
    
    var updateUiDelegate: UpdateUiDelegate?
    func updateView(_ info: [String: Any]) {
        updateUiDelegate?.updateUi(info: info)
    }
 
    func capi(skipLookup: Bool, theDestEndpoint: String, completion: @escaping (_ result: (String,String)) -> Void) {
        existingObjectsQ.maxConcurrentOperationCount = 2
        // query destination server
        if skipLookup {
            completion(("skipping lookup",theDestEndpoint))
            return
        }
        if pref.stopMigration {
            updateView(["function": "stopButton"])
//            stopButton(self)
            completion(("",""))
            return
        }
                
        if LogLevel.debug { WriteToLog.shared.message("[ExistingObjects.capi] enter - destination endpoint: \(theDestEndpoint)") }
        
        if pref.stopMigration {
//                    print("[\(#function)] \(#line) stopMigration")
            updateView(["function": "stopButton"])
            completion(("",""))
            return
        }
        
        if !export.saveOnly {
            URLCache.shared.removeAllCachedResponses()
            currentEPs.removeAll()
//            currentEPDict.removeAll()
            
            var destEndpoint         = theDestEndpoint
//            var existingDestUrl      = "\(JamfProServer.destination)"
            var destXmlName          = ""
            var destXmlID:Int?
            var existingEndpointNode = ""
            var een                  = ""
            
//            var duplicatePackages      = false
//            var duplicatePackagesDict  = [String:[String]]()
            
            if Counter.shared.crud[destEndpoint] == nil {
                Counter.shared.crud[destEndpoint] = ["create":0, "update":0, "fail":0, "skipped":0, "total":0]
                Counter.shared.summary[destEndpoint] /*summary Dict[destEndpoint]*/ = ["create":[], "update":[], "fail":[]]
            }

            switch destEndpoint {
            case "smartusergroups", "staticusergroups":
                destEndpoint = "usergroups"
                existingEndpointNode = "usergroups"
            case "smartcomputergroups", "staticcomputergroups":
                destEndpoint = "computergroups"
                existingEndpointNode = "computergroups"
            case "smartmobiledevicegroups", "staticmobiledevicegroups":
                destEndpoint = "mobiledevicegroups"
                existingEndpointNode = "mobiledevicegroups"
            case "jamfusers", "jamfgroups":
                existingEndpointNode = "accounts"
//            case "patch-software-title-configurations":
//                existingEndpointNode = "patch-software-title-configurations"
            default:
                existingEndpointNode = destEndpoint
            }
            
    //        print("\nGetting existing endpoints: \(existingEndpointNode)")
            var destEndpointDict:(Any)? = nil
            var endpointParent = ""
            switch destEndpoint {
            // macOS items
            case "advancedcomputersearches":
                endpointParent = "advanced_computer_searches"
            case "macapplications":
                endpointParent = "mac_applications"
            case "computerextensionattributes":
                endpointParent = "computer_extension_attributes"
            case "computergroups":
                endpointParent = "computer_groups"
//            case "computerconfigurations":
//                endpointParent = "computer_configurations"
            case "diskencryptionconfigurations":
                endpointParent = "disk_encryption_configurations"
            case "distributionpoints":
                endpointParent = "distribution_points"
            case "directorybindings":
                endpointParent = "directory_bindings"
            case "dockitems":
                endpointParent = "dock_items"
//            case "netbootservers":
//                endpointParent = "netboot_servers"
            case "osxconfigurationprofiles":
                endpointParent = "os_x_configuration_profiles"
            case "patches":
                endpointParent = "patch_management_software_titles"
            case "patchpolicies":
                endpointParent = "patch_policies"
            case "restrictedsoftware":
                endpointParent = "restricted_software"
            case "softwareupdateservers":
                endpointParent = "software_update_servers"
            // iOS items
            case "advancedmobiledevicesearches":
                endpointParent = "advanced_mobile_device_searches"
            case "mobiledeviceconfigurationprofiles":
                endpointParent = "configuration_profiles"
            case "mobiledeviceextensionattributes":
                endpointParent = "mobile_device_extension_attributes"
            case "mobiledevicegroups":
                endpointParent = "mobile_device_groups"
            case "mobiledeviceapplications":
                endpointParent = "mobile_device_applications"
            case "mobiledevices":
                endpointParent = "mobile_devices"
            // general items
            case "advancedusersearches":
                endpointParent = "advanced_user_searches"
            case "ldapservers":
                endpointParent = "ldap_servers"
            case "networksegments":
                endpointParent = "network_segments"
            case "userextensionattributes":
                endpointParent = "user_extension_attributes"
            case "usergroups":
                endpointParent = "user_groups"
            case "jamfusers", "jamfgroups":
                endpointParent = "accounts"
            default:
                endpointParent = "\(destEndpoint)"
            }
            
            var endpointDependencyArray = Dependencies.current
//                    var waiting                 = false
            ExistingEndpoints.shared.waiting   = false
            ExistingEndpoints.shared.completed = 0
            
            if UiVar.activeTab == "Selective" && endpointParent == "policies" && Setting.migrateDependencies && UiVar.goSender == "goButton" {
                endpointDependencyArray.append(existingEndpointNode)
            } else {
                endpointDependencyArray = ["\(existingEndpointNode)"]
            }
            if LogLevel.debug { WriteToLog.shared.message("[ExistingObjects.capi] endpointDependencyArray: \(endpointDependencyArray)") }
            
//            print("                    completed: \(completed)")
//            print("endpointDependencyArray.count: \(endpointDependencyArray.count)")
//            print("                      waiting: \(waiting)")
            
//            let semaphore = DispatchSemaphore(value: 1)
            existingObjectsQ.addOperation /* async */{ [self] in
//                while (ExistingEndpoints.shared.completed < endpointDependencyArray.count) {
//                    
//                    if !ExistingEndpoints.shared.waiting && (ExistingEndpoints.shared.completed < endpointDependencyArray.count) {
                        print("[ExistingObjects.capi] waiting: \(ExistingEndpoints.shared.waiting), completed: \(ExistingEndpoints.shared.completed), endpointDependencyArray.count: \(endpointDependencyArray.count)")
                        URLCache.shared.removeAllCachedResponses()
                        ExistingEndpoints.shared.waiting = true
                        
                        print("[ExistingObjects.capi] line: \(#line) get all \(existingEndpointNode)")
                        ObjectDelegate.shared.getAll(whichServer: "dest", endpoint: existingEndpointNode) { [self]
                            (result: [Any]) in
                            if let responseData = result as? [[String: Int]], responseData.count > 0 {
                                if let statusCode = responseData[0]["statusCode"], (statusCode < 200 || statusCode > 299) {
                                    if Setting.fullGUI {
                                        _ = Alert.shared.display(header: "Attention:", message: "Failed to get existing \(existingEndpointNode)\nStatus code: \(statusCode)", secondButton: "")
                                    } else {
                                        WriteToLog.shared.message("[ExistingObjects.capi] Failed to get existing \(existingEndpointNode)    Status code: \(statusCode)")
                                    }
                                    pref.stopMigration = true
                                    DispatchQueue.main.async { [self] in
                                        DataArray.source.removeAll()
                                        DataArray.staticSource.removeAll()
                                        
                                        updateView(["function": "clearSourceObjectsList"])
                                        //                                        clearSourceObjectsList()
                                        staticSourceObjectList.removeAll()
                                        
//                                        print("[\(#function)] \(#line) - finished getting \(existingEndpointNode)")
                                        updateView(["function": "goButtonEnabled", "button_status": true])
                                        completion(("Failed to get existing \(existingEndpointNode)\nStatus code: \(statusCode)",""))
                                        return
                                    }
                                }
                            }
                            
                            do {
                                
                                if LogLevel.debug { WriteToLog.shared.message("[ExistingObjects.capi]  --------------- Getting all \(destEndpoint) ---------------") }
                                
//                                print("[\(#function)] \(#line) - existingEndpointNode: \(existingEndpointNode)")
                                switch existingEndpointNode {
                                case "patch-software-title-configurations":
                                    do {
                                        let jsonData = try? JSONSerialization.data(withJSONObject: result, options: [])
                                        PatchTitleConfigurations.destination = try JSONDecoder().decode([PatchSoftwareTitleConfiguration].self, from: jsonData!)
                                        print("test count: \(PatchTitleConfigurations.source.count)")
                                    } catch {
                                        print("error getting patch software title configurations: \(error)")
                                    }
                                    //                                    PatchTitleConfigurations.destination = try! JSONDecoder().decode(PatchSoftwareTitleConfigurations.self, from: data ?? Data())
                                    
                                    // add site name to patch title config
                                    for i in 0..<PatchTitleConfigurations.destination.count {
                                        PatchTitleConfigurations.destination[i].siteName = JamfProSites.destination.first(where: {$0.id == PatchTitleConfigurations.destination[i].siteId})?.name ?? "NONE"
                                    }
                                    
                                    if LogLevel.debug { WriteToLog.shared.message("[ExistingObjects.capi] Found \(PatchTitleConfigurations.destination.count) patch configurations.") }
                                    
                                    for patchObject in PatchTitleConfigurations.destination as [PatchSoftwareTitleConfiguration] {
                                        let displayName = patchObject.displayName
                                        let softwareTitleName = patchObject.softwareTitleName
                                        //                                                    if patchObject.softwareTitlePublisher.range(of: "(Deprecated Definition)") != nil {
                                        //                                                        displayName.append(" (Deprecated Definition)")
                                        //                                                    }
                                        print("[ExistingObjects.capi] softwareTitleName: \(softwareTitleName)")
                                        //                                                    displayNames.append(displayName)
                                        
                                        if softwareTitleName.isEmpty {
                                            if LogLevel.debug { WriteToLog.shared.message("[ExistingObjects.capi] skipping id: \(Int(patchObject.id ?? "") ?? 0), could not determine the display name.") }
                                        } else {
                                            currentEPs[softwareTitleName] = Int(patchObject.id ?? "") ?? 0
                                        }
                                    }
                                    
                                    currentEPDict[destEndpoint] = currentEPs
                                    //                                                print("[ExistingObjects.capi] \(destEndpoint) current endpoints: \(currentEPDict[destEndpoint] ?? [:])")
                                    
                                case "packages":
//                                    print("destEndpointJSON count: \(result.count)")
                                    var packageIDsNames = [Int:String]()
                                    currentEPs.removeAll()
                                    if Packages.destination.count > 0 {
                                        for thePackage in Packages.destination {
                                            if let id = thePackage.id, let idNum = Int(id), let name = thePackage.fileName {
                                                packageIDsNames[idNum] = name
                                                currentEPs[name] = idNum
                                            }
                                        }
                                        ExistingEndpoints.shared.completed += 1

                                        ExistingEndpoints.shared.waiting = (ExistingEndpoints.shared.completed < endpointDependencyArray.count) ? false:true
                                            
                                        if !pref.stopMigration {
                                            print("[ExistingObjects.capi] \(destEndpoint) current endpoints: \(currentEPs)")
                                            currentEPDict["packages"] = currentEPs
                                            
                                            if endpointParent != "policies" {
                                                completion(
                                                    ("[ExistingObjects.capi] Current packages on \(JamfProServer.destination) - \(currentEPs)\n","packages"))
                                            }
                                        } else {
                                            currentEPDict["packages"] = [:]
                                            if endpointParent != "policies" {
                                                completion(("[ExistingObjects.capi] Migration process was stopped\n","packages"))
                                            }
                                            updateView(["function": "stopButton"])
                                        }
                                    } else {   // Packages.destination.count > 0
                                        // no packages were found
                                        currentEPDict["packages"] = [:]
                                        ExistingEndpoints.shared.completed += 1
                                        
                                        ExistingEndpoints.shared.waiting = (ExistingEndpoints.shared.completed < endpointDependencyArray.count) ? false:true
//                                                    existingObjectsQ.resume()
                                        completion(("[ExistingObjects.capi] No packages were found on \(JamfProServer.destination)\n","packages"))
                                    }

                                default:
                                    //                                    let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
//                                    print("[ExistingObjects.capi] destEndpointJSON: \(result.description)")
                                    if let objectArray = result as? [[String: Any]] {
                                        let destEndpointJSON = objectArray[0]
//                                        print("[ExistingObjects.capi] destEndpointJSON: \(destEndpointJSON)")
                                        if LogLevel.debug { WriteToLog.shared.message("[ExistingObjects.capi] existing destEndpointJSON: \(destEndpointJSON)") }
//                                        switch existingEndpointNode {
                                            
                                            /*
                                             // need to revisit as name isn't the best indicatory on whether or not a computer exists
                                             case "-computers":
                                             if LogLevel.debug { WriteToLog.shared.message("[ExistingObjects.capi] getting current computers") }
                                             if let destEndpointInfo = destEndpointJSON["computers"] as? [Any] {
                                             let destEndpointCount: Int = destEndpointInfo.count
                                             if LogLevel.debug { WriteToLog.shared.message("[ExistingObjects.capi] existing \(destEndpoint) found: \(destEndpointCount)") }
                                             if LogLevel.debug { WriteToLog.shared.message("[ExistingObjects.capi] destEndpointInfo: \(destEndpointInfo)") }
                                             
                                             if destEndpointCount > 0 {
                                             for i in (0..<destEndpointCount) {
                                             let destRecord = destEndpointInfo[i] as! [String : AnyObject]
                                             destXmlID = (destRecord["id"] as! Int)
                                             //                                            print("computer ID: \(destXmlID)")
                                             if let destEpGeneral = destEndpointJSON["computers/id/\(String(describing: destXmlID))/subset/General"] as? [Any] {
                                             //                                                    print("destEpGeneral: \(destEpGeneral)")
                                             let destRecordGeneral = destEpGeneral[0] as! [String : AnyObject]
                                             //                                                    print("destRecordGeneral: \(destRecordGeneral)")
                                             let destXmlUdid: String = (destRecordGeneral["udid"] as! String)
                                             currentEPs[destXmlUdid] = destXmlID
                                             }
                                             //print("Dest endpoint name: \(destXmlName)")
                                             }
                                             }   // if destEndpointCount > 0
                                             }   //if let destEndpointInfo = destEndpointJSON - end
                                             */
                                            
                                            if destEndpoint == "jamfusers" || destEndpoint == "jamfgroups" {
                                                let accountsDict = destEndpointJSON as [String: Any]
                                                let usersGroups = accountsDict["accounts"] as! [String: Any]
                                                //                                    print("users: \(String(describing: usersGroups["users"]))")
                                                //                                    print("groups: \(String(describing: usersGroups["groups"]))")
                                                destEndpoint == "jamfusers" ? (destEndpointDict = usersGroups["users"] as Any):(destEndpointDict = usersGroups["groups"] as Any)
                                            } else {
                                                een = endpointParent
                                                destEndpointDict = destEndpointJSON["\(een)"]
                                            }
                                            if LogLevel.debug { WriteToLog.shared.message("[ExistingObjects.capi] getting current \(existingEndpointNode) on destination server") }
                                            if let destEndpointInfo = destEndpointDict as? [Any] {
                                                let destEndpointCount: Int = destEndpointInfo.count
                                                if LogLevel.debug { WriteToLog.shared.message("[ExistingObjects.capi] existing \(existingEndpointNode) found: \(destEndpointCount) on destination server") }
                                                
                                                if destEndpointCount > 0 {
                                                    for i in (0..<destEndpointCount) {
                                                        
                                                        let destRecord = destEndpointInfo[i] as! [String : AnyObject]
                                                        if LogLevel.debug { WriteToLog.shared.message("[ExistingObjects.capi] Processing: \(destRecord).") }
                                                        destXmlID = (destRecord["id"] as! Int)
                                                        if destRecord["name"] != nil {
                                                            destXmlName = destRecord["name"] as! String
                                                        } else {
                                                            destXmlName = ""
                                                        }
                                                        if destXmlName != "" {
                                                            if "\(String(describing: destXmlID))" != "" {
                                                                
                                                                // filter out policies created from casper remote - start
                                                                if destXmlName.range(of:"[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] at", options: .regularExpression) == nil && destXmlName != "Update Inventory" {
                                                                    //                                                                            print("[ExistingObjects.capi] [\(existingEndpointNode)] adding \(destXmlName) (id: \(String(describing: destXmlID!))) to currentEP array.")
                                                                    if LogLevel.debug { WriteToLog.shared.message("[ExistingObjects.capi] adding \(destXmlName) (id: \(String(describing: destXmlID!))) to currentEP array.") }
                                                                    currentEPs[destXmlName] = destXmlID
                                                                }
                                                                // filter out policies created from casper remote - end
                                                                
                                                                if LogLevel.debug { WriteToLog.shared.message("[ExistingObjects.capi]    Array has \(currentEPs.count) entries.") }
                                                            } else {
                                                                if LogLevel.debug { WriteToLog.shared.message("[ExistingObjects.capi] skipping object: \(destXmlName), could not determine its id.") }
                                                            }
                                                        } else {
                                                            if LogLevel.debug { WriteToLog.shared.message("[ExistingObjects.capi] skipping id: \(String(describing: destXmlID)), could not determine its name.") }
                                                        }
                                                        
                                                    }   // for i in (0..<destEndpointCount) - end
                                                } else {   // if destEndpointCount > 0 - end
                                                    if LogLevel.debug { WriteToLog.shared.message("[ExistingObjects.capi] No endpoints found, clearing entries.") }
                                                    currentEPs.removeAll()
                                                }
                                                
                                                //                                                print("\n[ExistingObjects.capi] endpointParent: \(endpointParent) \t existingEndpointNode: \(existingEndpointNode) \t destEndpoint: \(destEndpoint)\ncurrentEPs: \(currentEPs)")
                                                switch endpointParent {
                                                case "policies":
                                                    currentEPDict[existingEndpointNode] = currentEPs
                                                default:
                                                    currentEPDict[destEndpoint] = currentEPs
                                                }
//                                                print("\n[ExistingObjects.capi] currentEPDict: \(currentEPDict)\n")
                                                
                                                //                                                        currentEPs.removeAll()
                                                
                                            }   // if let destEndpointInfo - end
//                                        }   // switch - end
                                    } else {
                                        if LogLevel.debug { WriteToLog.shared.message("[ExistingObjects.capi] current endpoint dict: \(currentEPs)") }
                                        if LogLevel.debug { WriteToLog.shared.message("[ExistingObjects.capi] clearing existing current endpoints: \(existingEndpointNode)") }
                                        currentEPs.removeAll()
                                        currentEPDict[existingEndpointNode] = [:]
                                        //                                        completion("error parsing JSON")
                                    }   // if let destEndpointJSON - end
                                    
                                }
                                
                                
                                
                            }   // end do/catch
                            
                            if existingEndpointNode != "packages" {
                                
                                ExistingEndpoints.shared.completed += 1
                                
                                //                                if httpResponse.statusCode > 199 && httpResponse.statusCode <= 299 {
                                //                                    print(httpResponse.statusCode)
                                if LogLevel.debug { WriteToLog.shared.message("[ExistingObjects.capi] returning existing \(existingEndpointNode) endpoints: \(currentEPs)") }
                                //                            print("returning existing endpoints: \(currentEPs)")
                                ExistingEndpoints.shared.completed += 1
                                //                                                self.updateExistingCounter(change: 1)
                                ExistingEndpoints.shared.waiting = (ExistingEndpoints.shared.completed < endpointDependencyArray.count) ? false:true
//                                if ExistingEndpoints.shared.completed >= endpointDependencyArray.count {
                                    if endpointParent == "ldap_servers" {
                                        currentLDAPServers = currentEPDict[destEndpoint]!
                                    }
                                    if let _ =  currentEPDict[destEndpoint] {
                                        currentEPs = currentEPDict[destEndpoint]!
                                    } else {
                                        currentEPs = [:]
                                    }
                                    completion(("[ExistingObjects.capi] Current \(destEndpoint) - \(currentEPs)\n","\(existingEndpointNode)"))
//                                }
                                //                                } else {
                                //                                    // something went wrong
                                //                                    ExistingEndpoints.shared.completed += 1
                                //                                    //                                                self.updateExistingCounter(change: 1)
                                //                                    ExistingEndpoints.shared.waiting = (ExistingEndpoints.shared.completed < endpointDependencyArray.count) ? false:true
                                //                                    if ExistingEndpoints.shared.completed == endpointDependencyArray.count {
                                //                                        //                                        print("status code: \(httpResponse.statusCode)")
                                //                                        //                                        print("currentEPDict[] - error: \(String(describing: currentEPDict))")
                                //                                        if LogLevel.debug { WriteToLog.shared.message("[ExistingObjects.capi] endpoint: \(destEndpoint)") }
                                //                                        if LogLevel.debug { WriteToLog.shared.message("[ExistingObjects.capi] error - status code: \(httpResponse.statusCode)") }
                                //                                        if LogLevel.debug { WriteToLog.shared.message("[ExistingObjects.capi] xml: \(String(describing: currentEPDict))") }
                                //                                        currentEPs = currentEPDict[destEndpoint]!
                                //                                        completion(("\ndestination count error","\(existingEndpointNode)"))
                                //                                    }
                                //
                                //                                }   // if httpResponse/else - end
                            } //else {
                            //                                    return
                            //                                }
                            
                            //                        } else {   // if let httpResponse - end
                            //                            completion(("Failed to get response for existing \(existingEndpointNode)",""))
                            //                            return
                            //                        }
                            //                        semaphore.signal()
                            //                        if error != nil {
                            //                            completion(("error for existing \(existingEndpointNode) - error: \(String(describing: error))",""))
                            //                            return
                            //                        }
                            //                        })  // let task = destSession - end
                            //
                            //                        task.resume()
                            //                    } else {  //if !waiting - end
                            //                        usleep(100)
                            //                    }
                            
                            // single completion after waiting...
                            
                            //                    print("completed: \(completed) of \(endpointDependencyArray.count) dependencies")
//                        }
//                    }
                    
                }   // while (ExistingEndpoints.shared.completed < endpointDependencyArray.count)
                
//                print("[\(endpointParent)] ExistingEndpoints.shared.completed \(completed) of \(endpointDependencyArray.count)")
            }   // destEPQ - end
        } else {
            currentEPs["_"] = 0
            if LogLevel.debug { WriteToLog.shared.message("[ExistingObjects.capi] exit - save only enabled, endpoint: \(theDestEndpoint) not needed.") }
            completion(("Current endpoints - export.saveOnly, not needed.","\(theDestEndpoint)"))
        }
    }
}
