//
//  Json.swift
//  Jamf Transporter
//
//  Created by Leslie Helou on 12/1/19.
//  Copyright 2024 Jamf. All rights reserved.
//

import Cocoa

class Json: NSObject, URLSessionDelegate {
    func getRecord(whichServer: String, theServer: String, base64Creds: String, theEndpoint: String, endpointBase: String = "0", endpointId: String = "0", completion: @escaping (_ objectRecord: Any) -> Void) {
        
        if theEndpoint == "skip" {
            completion([:])
            return
        }
        
        let objectEndpoint = theEndpoint.replacingOccurrences(of: "//", with: "/")
        WriteToLog.shared.message(stringOfText: "[Json.getRecord] get endpoint: \(objectEndpoint) from server: \(theServer)")
    
        URLCache.shared.removeAllCachedResponses()
        var existingDestUrl = "\(theServer)"
        
        switch endpointBase {
        case "patchmanagement":
            let theRecord = (whichServer == "source") ? PatchTitleConfigurations.source.filter({ $0.id == endpointId }):PatchTitleConfigurations.destination.filter({ $0.id == endpointId })
            if theRecord.count == 1 {
                print("[getRecord] [Json.getRecord] theRecord displayName \(theRecord[0].displayName)")
                completion(theRecord[0])
            } else {
                completion([])
            }
            return

//            existingDestUrl = existingDestUrl.appending("/api/v2/\(objectEndpoint)").urlFix
        default:
            existingDestUrl = existingDestUrl.appending("/JSSResource/\(objectEndpoint)").urlFix
        }
//        existingDestUrl = "\(theServer)/JSSResource/\(objectEndpoint)"
        existingDestUrl = existingDestUrl.urlFix
        
        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[Json.getRecord] Looking up: \(existingDestUrl)") }
//        print("[getRecord] existing endpoints URL: \(existingDestUrl)")
        let destEncodedURL = URL(string: existingDestUrl)
        let jsonRequest    = NSMutableURLRequest(url: destEncodedURL! as URL)

        q.getRecord.maxConcurrentOperationCount = userDefaults.integer(forKey: "concurrentThreads")
        
        let semaphore = DispatchSemaphore(value: 0)
        q.getRecord.addOperation {
            
            jsonRequest.httpMethod = "GET"
            let destConf = URLSessionConfiguration.ephemeral

            destConf.httpAdditionalHeaders = ["Authorization" : "\(JamfProServer.authType[whichServer] ?? "Bearer") \(JamfProServer.authCreds[whichServer] ?? "")", "Content-Type" : "application/json", "Accept" : "application/json", "User-Agent" : AppInfo.userAgentHeader]
            let destSession = Foundation.URLSession(configuration: destConf, delegate: self, delegateQueue: OperationQueue.main)
            let task = destSession.dataTask(with: jsonRequest as URLRequest, completionHandler: {
                (data, response, error) -> Void in
                destSession.finishTasksAndInvalidate()
                if let httpResponse = response as? HTTPURLResponse {
//                    print("[Json.getRecord] httpResponse: \(String(describing: httpResponse))")
                    if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
                        do {
                            let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                            if let endpointJSON = json as? [String: AnyObject] {
                                WriteToLog.shared.message(stringOfText: "[Json.getRecord] retrieved \(theEndpoint)")
//                                print("[getRecord] [Json.getRecord] \(endpointJSON)")
                                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[Json.getRecord] \(endpointJSON)") }
                                completion(endpointJSON)
                            } else {
                                WriteToLog.shared.message(stringOfText: "[Json.getRecord] error parsing JSON for \(existingDestUrl)")
                                completion([:])
                            }
                        }
                    } else {
                        WriteToLog.shared.message(stringOfText: "[Json.getRecord] error getting \(theEndpoint), HTTP Status Code: \(httpResponse.statusCode)")
                        completion([:])
                    }
                } else {
                    WriteToLog.shared.message(stringOfText: "[Json.getRecord] unknown response from \(existingDestUrl)")
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
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
    
}

