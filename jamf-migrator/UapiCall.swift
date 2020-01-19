//
//  UapiCall.swift
//  jamf-migrator
//
//  Created by Leslie Helou on 12/17/19.
//  Copyright © 2019 jamf. All rights reserved.
//

import Cocoa

class UapiCall: NSObject, URLSessionDelegate {
    
    var theUapiQ = OperationQueue() // create operation queue for API calls
    
    func get(serverUrl: String, path: String, token: String, action: String, completion: @escaping (_ returnedJSON: [String:Any]) -> Void) {
        
        URLCache.shared.removeAllCachedResponses()
                
        var urlString = "\(serverUrl)/uapi/\(path)"
        urlString     = urlString.replacingOccurrences(of: "//uapi", with: "/uapi")
//        print("[UapiCall] urlString: \(urlString)")
        
        let url            = URL(string: "\(urlString)")
        let configuration  = URLSessionConfiguration.default
        var request        = URLRequest(url: url!)
        request.httpMethod = "\(action)"

        if LogLevel.debug { WriteToLog().message(stringOfText: "[UapiCall.get] Attempting to retrieve info from \(urlString).\n") }
        
        configuration.httpAdditionalHeaders = ["Authorization" : "Bearer \(token)", "Content-Type" : "application/json", "Accept" : "application/json"]
        let session = Foundation.URLSession(configuration: configuration, delegate: self as URLSessionDelegate, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) -> Void in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
                    let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                    if let endpointJSON = json! as? [String:Any] {
                        if LogLevel.debug { WriteToLog().message(stringOfText: "[UapiCall.get] Token retrieved from \(urlString).\n") }
                        completion(endpointJSON)
                        return
                    } else {    // if let endpointJSON error
                    if LogLevel.debug { WriteToLog().message(stringOfText: "[UapiCall.get] JSON error.\n") }
                        completion([:])
                        return
                    }
                } else {    // if httpResponse.statusCode <200 or >299
                if LogLevel.debug { WriteToLog().message(stringOfText: "[UapiCall.get] Response error: \(httpResponse.statusCode).\n") }
                    completion([:])
                    return
                }
            } else {
                if LogLevel.debug { WriteToLog().message(stringOfText: "[UapiCall.get] GET response error.  Verify url and port.\n") }
                completion([:])
                return
            }
        })
        task.resume()
        
    }   // func token - end

    
    func getToken(serverUrl: String, base64creds: String, completion: @escaping (_ returnedToken: String) -> Void) {
        
        URLCache.shared.removeAllCachedResponses()
        
        var token          = ""
        
        var tokenUrlString = "\(serverUrl)/uapi/auth/tokens"
        tokenUrlString     = tokenUrlString.replacingOccurrences(of: "//uapi", with: "/uapi")
//        print("\(tokenUrlString)")
        
        let tokenUrl       = URL(string: "\(tokenUrlString)")
        let configuration  = URLSessionConfiguration.default
        var request        = URLRequest(url: tokenUrl!)
        request.httpMethod = "POST"
        
        if LogLevel.debug { WriteToLog().message(stringOfText: "[UapiCall.getToken] Attempting to retrieve token from \(String(describing: tokenUrl!)).\n") }
        
        configuration.httpAdditionalHeaders = ["Authorization" : "Basic \(base64creds)", "Content-Type" : "application/json", "Accept" : "application/json"]
        let session = Foundation.URLSession(configuration: configuration, delegate: self as URLSessionDelegate, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) -> Void in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
                    let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                    if let endpointJSON = json! as? Dictionary<String, Any>, let _ = endpointJSON["token"] {
                        token = endpointJSON["token"] as! String
                        if LogLevel.debug { WriteToLog().message(stringOfText: "[UapiCall.getToken] Retrieved token.\n") }
                        completion(token)
                        return
                    } else {    // if let endpointJSON error
                        if LogLevel.debug { WriteToLog().message(stringOfText: "[UapiCall.getToken] JSON error.\n\(String(describing: json))\n") }
                        completion("")
                        return
                    }
                } else {    // if httpResponse.statusCode <200 or >299
                    if LogLevel.debug { WriteToLog().message(stringOfText: "[UapiCall.getToken] response error: \(httpResponse.statusCode).\n") }
                    completion("")
                    return
                }
            } else {
                if LogLevel.debug { WriteToLog().message(stringOfText: "[UapiCall.getToken] token response error.  Verify url and port.\n") }
                completion("")
                return
            }
        })
        task.resume()
        
    }   // func token - end

}
