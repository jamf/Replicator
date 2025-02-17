//
//  Json.swift
//  Replicator
//
//  Created by Leslie Helou on 12/1/19.
//  Copyright 2024 Jamf. All rights reserved.
//

import Cocoa

class Json: NSObject, URLSessionDelegate {
    
    static let shared = Json()
    
    func getRecord(whichServer: String, base64Creds: String, theEndpoint: String, endpointBase: String = "0", endpointId: String = "0", completion: @escaping (_ objectRecord: Any) -> Void) {
        
        if theEndpoint == "skip" {
            completion([:])
            return
        }
        
        var existingDestUrl = (whichServer == "source") ? JamfProServer.source : JamfProServer.destination
        let objectEndpoint = theEndpoint.replacingOccurrences(of: "//", with: "/")
        WriteToLog.shared.message("[Json.getRecord] get endpoint: \(objectEndpoint) from server: \(existingDestUrl)")
    
        URLCache.shared.removeAllCachedResponses()
        
        switch endpointBase {
        case "patch-software-title-configurations":
            let theRecord = (whichServer == "source") ? PatchTitleConfigurations.source.filter({ $0.id == endpointId }):PatchTitleConfigurations.destination.filter({ $0.id == endpointId })
            if theRecord.count == 1 {
                print("[getRecord] [Json.getRecord] theRecord displayName \(theRecord[0].displayName)")
                completion(theRecord[0])
            } else {
                completion([])
            }
            return

        default:
            if ["jamfusers", "jamfgroups"].contains(objectEndpoint) {
                existingDestUrl = existingDestUrl.appending("/JSSResource/accounts").urlFix
            } else {
                existingDestUrl = existingDestUrl.appending("/JSSResource/\(objectEndpoint)").urlFix
            }
        }

        existingDestUrl = existingDestUrl.urlFix
        
        if LogLevel.debug { WriteToLog.shared.message("[Json.getRecord] Looking up: \(existingDestUrl)") }
        print("[Json.getRecord] existing endpoints URL: \(existingDestUrl)")
        
        let destEncodedURL = URL(string: existingDestUrl)
        let jsonRequest    = NSMutableURLRequest(url: destEncodedURL! as URL)
        
        jsonRequest.httpMethod = "GET"
        let destConf = URLSessionConfiguration.ephemeral

        destConf.httpAdditionalHeaders = ["Authorization" : "\(JamfProServer.authType[whichServer] ?? "Bearer") \(JamfProServer.authCreds[whichServer] ?? "")", "Content-Type" : "application/json", "Accept" : "application/json", "User-Agent" : AppInfo.userAgentHeader]
        
        var headers = [String: String]()
        for (header, value) in destConf.httpAdditionalHeaders ?? [:] {
            headers[header as! String] = (header as! String == "Authorization") ? "Bearer ************" : value as? String
        }
        print("[apiCall] \(#function.description) method: \(jsonRequest.httpMethod)")
        print("[apiCall] \(#function.description) headers: \(headers)")
        print("[apiCall] \(#function.description) endpoint: \(destEncodedURL?.absoluteString ?? "")")
        print("[apiCall]")
        

        q.getRecord.maxConcurrentOperationCount = userDefaults.integer(forKey: "concurrentThreads")
        
        let semaphore = DispatchSemaphore(value: 0)
        q.getRecord.addOperation {
            let destSession = Foundation.URLSession(configuration: destConf, delegate: self, delegateQueue: OperationQueue.main)
            let task = destSession.dataTask(with: jsonRequest as URLRequest, completionHandler: { [self]
                (data, response, error) -> Void in
                destSession.finishTasksAndInvalidate()
                if let httpResponse = response as? HTTPURLResponse {
//                    print("[Json.getRecord] httpResponse: \(String(describing: httpResponse))")
                    if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
                        do {
                            let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                            if let endpointJSON = json as? [String: AnyObject] {
                                WriteToLog.shared.message("[Json.getRecord] retrieved \(theEndpoint)")
//                                print("[getRecord] [Json.getRecord] \(endpointJSON)")
                                var finalJson = [String: AnyObject]()
                                if theEndpoint == "policies" {
                                    finalJson = ["policies": policyCleanup(policies: endpointJSON["policies"] as! [[String : AnyObject]])]
                                } else {
                                    finalJson = endpointJSON
                                }
                                if LogLevel.debug { WriteToLog.shared.message("[Json.getRecord] \(finalJson)") }
                                completion(finalJson)
                            } else {
                                WriteToLog.shared.message("[Json.getRecord] error parsing JSON for \(existingDestUrl)")
                                completion([:])
                            }
                        }
                    } else {
                        WriteToLog.shared.message("[Json.getRecord] error getting \(theEndpoint), HTTP Status Code: \(httpResponse.statusCode)")
                        completion([:])
                    }
                } else {
                    WriteToLog.shared.message("[Json.getRecord] unknown response from \(existingDestUrl)")
                    completion([:])
                }   // if let httpResponse - end
                semaphore.signal()
                if error != nil {
                }
            })  // let task = destSession - end
            //print("GET")
            task.resume()
            semaphore.wait()
        }   // getRecordQ - end
    }
    
    private func policyCleanup(policies: [[String: AnyObject]]) -> AnyObject {
        var cleanPolicies = [[String: AnyObject]]()
        for thePolicy in policies {
            if let policyId = thePolicy["id"], let policyName = thePolicy["name"] as? String {
                if policyName.range(of:"[0-9]{4}-[0-9]{2}-[0-9]{2} at [0-9]", options: .regularExpression) == nil && policyName != "Update Inventory" {
    //                                                                            print("[ExistingObjects.capi] [\(existingEndpointNode)] adding \(destXmlName) (id: \(String(describing: destXmlID!))) to currentEP array.")
                    if LogLevel.debug { WriteToLog.shared.message("[ExistingObjects.capi] adding \(policyName) (id: \(String(describing: policyId))) to policies array.") }
                    cleanPolicies.append(thePolicy)
                }
            }
        }
        return cleanPolicies as AnyObject
    }
}

