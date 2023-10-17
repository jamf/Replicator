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
    var jamfpro: JamfPro?
    
    func action(serverUrl: String, endpoint: String, apiData: [String:Any], id: String, token: String, method: String, completion: @escaping (_ returnedJSON: [String: Any]) -> Void) {
        
        jamfpro = JamfPro(controller: ViewController())
        
        let whichServer = (serverUrl == JamfProServer.source) ? "source":"destination"
        jamfpro!.getToken(whichServer: whichServer, serverUrl: serverUrl, base64creds: JamfProServer.base64Creds[whichServer] ?? "") { [self]
            (result: (Int,String)) in
            let (statusCode, theResult) = result
//            print("[jpapi.action] token check")
            if theResult == "success" {
                
                // cookie stuff
        //        var cookies:[HTTPCookie]?
                var sessionCookie: HTTPCookie?
                var cookieName         = "" // name of cookie to look for
                
                if method.lowercased() == "skip" {
                    if LogLevel.debug { WriteToLog().message(stringOfText: "[Jpapi.action] skipping \(endpoint) endpoint with id \(id).\n") }
                    let JPAPI_result = (endpoint == "auth/invalidate-token") ? "no valid token":"failed"
                    completion(["JPAPI_result":JPAPI_result, "JPAPI_response":000])
                    return
                }
                
                URLCache.shared.removeAllCachedResponses()
                var path = ""

                switch endpoint {
                case  "buildings", "csa/token", "icon", "jamf-pro-version", "auth/invalidate-token":
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
                
                configuration.httpAdditionalHeaders = ["Authorization" : "Bearer \(token)", "Content-Type" : "application/json", "Accept" : "application/json", "User-Agent" : AppInfo.userAgentHeader]
                
        //        print("jpapi sticky session for \(serverUrl)")
                // sticky session
                if JamfProServer.sessionCookie.count > 0 && JamfProServer.stickySession {
                    URLSession.shared.configuration.httpCookieStorage!.setCookies(JamfProServer.sessionCookie, for: URL(string: serverUrl), mainDocumentURL: URL(string: serverUrl))
                }
                
                let session = Foundation.URLSession(configuration: configuration, delegate: self as URLSessionDelegate, delegateQueue: OperationQueue.main)
                let task = session.dataTask(with: request as URLRequest, completionHandler: {
                    (data, response, error) -> Void in
                    session.finishTasksAndInvalidate()
                    if let httpResponse = response as? HTTPURLResponse {
                        if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
                            
        //                    print("[jpapi] endpoint: \(endpoint)")

                            if endpoint == "jamf-pro-version" {
                                JamfProServer.sessionCookie.removeAll()
                    //            let cookies = HTTPCookieStorage.shared.cookies!
                    //            print("total cookies: \(cookies.count)")
                                
                                for theCookie in HTTPCookieStorage.shared.cookies! {
        //                            print("cookie name \(theCookie.name)")
                                    if ["jpro-ingress", "APBALANCEID"].contains(theCookie.name) {
                                        sessionCookie = theCookie
                                        cookieName    = theCookie.name
                                        break
                                    }
                                }
                                // look for alternalte cookie to use with sticky sessions
                                if sessionCookie == nil {
                                    for theCookie in HTTPCookieStorage.shared.cookies! {
        //                                print("cookie name \(theCookie.name)")
                                        if ["AWSALB"].contains(theCookie.name) {
                                            sessionCookie = theCookie
                                            cookieName    = theCookie.name
                                            break
                                        }
                                    }
                                }
                                
                                if sessionCookie != nil && (sessionCookie?.domain == JamfProServer.destination.urlToFqdn) {
                                    WriteToLog().message(stringOfText: "[Jpapi.action] set cookie (name:value) \(String(describing: cookieName)):\(String(describing: sessionCookie!.value)) for \(String(describing: sessionCookie!.domain))\n")
                                    JamfProServer.sessionCookie.append(sessionCookie!)
                                } else {
                                    HTTPCookieStorage.shared.removeCookies(since: History.startTime)
                                }
                            }
                            
                            let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                            if let endpointJSON = json as? [String:Any] {
                                if LogLevel.debug { WriteToLog().message(stringOfText: "[Jpapi.action] Data retrieved from \(urlString).\n") }
                                completion(endpointJSON)
                                return
                            } else {    // if let endpointJSON error
                                if httpResponse.statusCode == 204 && endpoint == "auth/invalidate-token" {
                                    completion(["JPAPI_result":"token terminated", "JPAPI_response":httpResponse.statusCode])
                                } else {
                                    if LogLevel.debug { WriteToLog().message(stringOfText: "[Jpapi.action] JSON error.  Returned data: \(String(describing: json))\n") }
                                    completion(["JPAPI_result":"failed", "JPAPI_response":httpResponse.statusCode])
                                }
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
            } else {
                if endpoint == "auth/invalidate-token" {
                    completion(["JPAPI_result":"token is not valid", "JPAPI_method":"", "JPAPI_response":"", "JPAPI_server":"", "JPAPI_token":""])
                    return
                } else {
                    completion([:])
                    return
                }
            }
        }
    }   // func action - end
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(  URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
}
