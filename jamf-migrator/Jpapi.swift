//
//  Jpapi.swift
//  jamf-migrator
//
//  Created by Leslie Helou on 12/17/19.
//  Copyright © 2019 jamf. All rights reserved.
//

import Cocoa

class Jpapi: NSObject, URLSessionDelegate {
    
//    var theUapiQ = OperationQueue() // create operation queue for API calls
    
    func action(serverUrl: String, endpoint: String, apiData: [String:Any], id: String, token: String, method: String, completion: @escaping (_ returnedJSON: [String: Any]) -> Void) {
        
        // cookie stuff
//        var cookies:[HTTPCookie]?
        var sessionCookie: HTTPCookie?
        var cookieName         = "" // name of cookie to look for
        var currentCookieValue = ""
        var cookieJar          = [String: HTTPCookie]()
        
        if method.lowercased() == "skip" {
            if LogLevel.debug { WriteToLog().message(stringOfText: "[Jpapi.action] skipping \(endpoint) endpoint with id \(id).\n") }
            completion(["JPAPI_result":"failed", "JPAPI_response":000])
            return
        }
        
        URLCache.shared.removeAllCachedResponses()
        var path = ""

        switch endpoint {
        case  "buildings", "csa/token", "icon", "jamf-pro-version":
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
        let configuration  = URLSessionConfiguration.default
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
        
        configuration.httpAdditionalHeaders = ["Authorization" : "Bearer \(token)", "Content-Type" : "application/json", "Accept" : "application/json", "User-Agent" : appInfo.userAgentHeader]
        
        // sticky session
//        let cookieUrl = self.createDestUrlBase.replacingOccurrences(of: "JSSResource", with: "")
        print("jpapi sticky session for \(serverUrl)")
        if JamfProServer.sessionCookie.count > 0 {
            URLSession.shared.configuration.httpCookieStorage!.setCookies(JamfProServer.sessionCookie, for: URL(string: serverUrl), mainDocumentURL: URL(string: serverUrl))
        }
        
        let session = Foundation.URLSession(configuration: configuration, delegate: self as URLSessionDelegate, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) -> Void in
            session.finishTasksAndInvalidate()
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
                    
                    if endpoint == "csa/token" {
                        JamfProServer.sessionCookie.removeAll()
                        currentCookieValue = ""
            //            let cookies = HTTPCookieStorage.shared.cookies!
            //            print("total cookies: \(cookies.count)")

                        if let cookie = HTTPCookieStorage.shared.cookies?.first(where: { $0.name == "jpro-ingress" }) {
                            sessionCookie = cookie
                            cookieName = "jpro-ingress"
                            currentCookieValue = cookie.value
                            print("\(endpoint) cookie name, \(cookieName): \(cookie.value)")
                        } else {
                            if let cookie = HTTPCookieStorage.shared.cookies?.first(where: { $0.name == "APBALANCEID" }) {
                                sessionCookie = cookie
                                cookieName = "APBALANCEID"
                                currentCookieValue = cookie.value
                                print("\(endpoint) cookie name, \(cookieName): \(cookie.value)")
                            } else {
                                // some other cookie to identify node
                                if let cookie = HTTPCookieStorage.shared.cookies?.first(where: { $0.name == "???xxxx???" }) {
                                    sessionCookie = cookie
                                    cookieName = "???xxxx???"
                                    currentCookieValue = cookie.value
                                    print("\(endpoint) cookie name, \(cookieName): \(cookie.value)")
                                } else {
                                    sessionCookie = nil
                                }
                            }
                        }
                        if sessionCookie != nil {
                            JamfProServer.sessionCookie.append(sessionCookie!)
                        }
                    }
                    
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
}
