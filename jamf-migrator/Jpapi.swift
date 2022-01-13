//
//  Jpapi.swift
//  jamf-migrator
//
//  Created by Leslie Helou on 12/17/19.
//  Copyright © 2019 jamf. All rights reserved.
//

import Cocoa

class Jpapi: NSObject, URLSessionDelegate {
    
    var theUapiQ = OperationQueue() // create operation queue for API calls
    
    func action(serverUrl: String, endpoint: String, apiData: [String:Any], id: String, token: String, method: String, completion: @escaping (_ returnedJSON: [String: Any]) -> Void) {
        
        if method.lowercased() == "skip" {
            if LogLevel.debug { WriteToLog().message(stringOfText: "[Jpapi.action] skipping \(endpoint) endpoint with id \(id).\n") }
            completion(["JPAPI_result":"failed", "JPAPI_response":000])
            return
        }
        
        URLCache.shared.removeAllCachedResponses()
        var path = ""

        switch endpoint {
        case  "buildings", "jamf-pro-version":
            path = "v1/\(endpoint)"
        default:
            path = "v2/\(endpoint)"
        }

        var urlString = "\(serverUrl)/api/\(path)"
        urlString     = urlString.replacingOccurrences(of: "//api", with: "/api")
        if id != "" && id != "0" {
            urlString = urlString + "/\(id)"
        }
//        print("[Jpapi] urlString: \(urlString)")
        
        let url            = URL(string: "\(urlString)")
        let configuration  = URLSessionConfiguration.ephemeral
        var request        = URLRequest(url: url!)
        switch method.lowercased() {
        case "get":
            request.httpMethod = "GET"
        case "create", "post":
            request.httpMethod = "POST"
        default:
            request.httpMethod = "PUT"
        }
        
        if apiData.count > 0 {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: apiData, options: .prettyPrinted)
            } catch let error {
                print(error.localizedDescription)
            }
        }
        
        if LogLevel.debug { WriteToLog().message(stringOfText: "[Jpapi.action] Attempting \(method) on \(urlString).\n") }
//        print("[Jpapi.action] Attempting \(method) on \(urlString).")
        
        configuration.httpAdditionalHeaders = ["Authorization" : "Bearer \(token)", "Content-Type" : "application/json", "Accept" : "application/json"]
        let session = Foundation.URLSession(configuration: configuration, delegate: self as URLSessionDelegate, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) -> Void in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
                    let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                    if let endpointJSON = json! as? [String:Any] {
                        if LogLevel.debug { WriteToLog().message(stringOfText: "[Jpapi.action] Data retrieved from \(urlString).\n") }
                        completion(endpointJSON)
                        return
                    } else {    // if let endpointJSON error
                        if LogLevel.debug { WriteToLog().message(stringOfText: "[Jpapi.action] JSON error.  Returned data: \(String(describing: json))\n") }
                        completion(["JPAPI_result":"failed", "JPAPI_response":httpResponse.statusCode])
                        return
                    }
                } else {    // if httpResponse.statusCode <200 or >299
                if LogLevel.debug { WriteToLog().message(stringOfText: "[Jpapi.action] Response error: \(httpResponse.statusCode).\n") }
                    completion(["JPAPI_result":"failed", "JPAPI_method":request.httpMethod ?? method, "JPAPI_response":httpResponse.statusCode, "JPAPI_server":urlString, "JPAPI_token":token])
                    return
                }
            } else {
                if LogLevel.debug { WriteToLog().message(stringOfText: "[Jpapi.action] GET response error.  Verify url and port.\n") }
                completion([:])
                return
            }
        })
        task.resume()
        
    }   // func action - end

    
    func getToken(serverUrl: String, base64creds: String, completion: @escaping (_ returnedToken: String) -> Void) {
        
        URLCache.shared.removeAllCachedResponses()
        
        var token          = ""
        
        var tokenUrlString = "\(serverUrl)/api/v1/auth/token"
        tokenUrlString     = tokenUrlString.replacingOccurrences(of: "//api", with: "/api")
//        print("\(tokenUrlString)")
        
        let tokenUrl       = URL(string: "\(tokenUrlString)")
        let configuration  = URLSessionConfiguration.ephemeral
        var request        = URLRequest(url: tokenUrl!)
        request.httpMethod = "POST"
        
        if LogLevel.debug { WriteToLog().message(stringOfText: "[Jpapi.getToken] Attempting to retrieve token from \(String(describing: tokenUrl!)).\n") }
        
        configuration.httpAdditionalHeaders = ["Authorization" : "Basic \(base64creds)", "Content-Type" : "application/json", "Accept" : "application/json"]
        let session = Foundation.URLSession(configuration: configuration, delegate: self as URLSessionDelegate, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) -> Void in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
                    let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                    if let endpointJSON = json! as? Dictionary<String, Any>, let _ = endpointJSON["token"] {
                        token = endpointJSON["token"] as! String
                        if LogLevel.debug { WriteToLog().message(stringOfText: "[Jpapi.getToken] Retrieved token: \(token)\n") }
//                        print("[Jpapi] token: \(token)")
                        completion(token)
                        return
                    } else {    // if let endpointJSON error
                        if LogLevel.debug { WriteToLog().message(stringOfText: "[Jpapi.getToken] JSON error.\n\(String(describing: json))\n") }
                        completion("")
                        return
                    }
                } else {    // if httpResponse.statusCode <200 or >299
                    if LogLevel.debug { WriteToLog().message(stringOfText: "[Jpapi.getToken] response error: \(httpResponse.statusCode).\n") }
                    completion("")
                    return
                }
            } else {
                if LogLevel.debug { WriteToLog().message(stringOfText: "[Jpapi.getToken] token response error.  Verify url and port.\n") }
                completion("")
                return
            }
        })
        task.resume()
        
    }   // func token - end

}
