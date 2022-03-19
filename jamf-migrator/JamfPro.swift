//
//  JamfPro.swift
//  jamf-migrator
//
//  Created by Leslie Helou on 12/11/19.
//  Copyright © 2019 Leslie Helou. All rights reserved.
//

import Foundation

class JamfPro: NSObject, URLSessionDelegate {
    
    var renewQ = DispatchQueue(label: "com.jamfmigrator.token_refreshQ", qos: DispatchQoS.background)   // running background process for refreshing token
    
    let userDefaults = UserDefaults.standard
    
    func getVersion(whichServer: String, jpURL: String, basicCreds: String, localSource: Bool, completion: @escaping (_ authResult: (Int,String)) -> Void) {
        if ((whichServer == "source" && (!wipeData.on && !localSource)) || (whichServer == "destination" && !export.saveOnly)) {
            var versionString  = ""
            let semaphore      = DispatchSemaphore(value: 0)
            
            OperationQueue().addOperation {
                let encodedURL     = NSURL(string: "\(jpURL)/JSSCheckConnection")
                let request        = NSMutableURLRequest(url: encodedURL! as URL)
                request.httpMethod = "GET"
                let configuration  = URLSessionConfiguration.default
                let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
                let task = session.dataTask(with: request as URLRequest, completionHandler: { [self]
                    (data, response, error) -> Void in
                    session.finishTasksAndInvalidate()
    //                if let httpResponse = response as? HTTPURLResponse {
                        versionString = String(data: data!, encoding: .utf8) ?? ""
    //                    print("httpResponse: \(httpResponse)")
    //                    print("raw versionString: \(versionString)")
                        if versionString != "" {
                            let tmpArray = versionString.components(separatedBy: ".")
                            if tmpArray.count > 2 {
                                for i in 0...2 {
                                    switch i {
                                    case 0:
                                        JamfProServer.majorVersion = Int(tmpArray[i]) ?? 0
                                    case 1:
                                        JamfProServer.minorVersion = Int(tmpArray[i]) ?? 0
                                    case 2:
                                        let tmp = tmpArray[i].components(separatedBy: "-")
                                        JamfProServer.patchVersion = Int(tmp[0]) ?? 0
                                        if tmp.count > 1 {
                                            JamfProServer.build = tmp[1]
                                        }
                                    default:
                                        break
                                    }
                                }
                            }
                        }
    //                }
                    WriteToLog().message(stringOfText: "[JamfPro.getVersion] Jamf Pro Version: \(versionString)\n")
                        getToken(serverUrl: jpURL, whichServer: whichServer, base64creds: basicCreds) {
                            (authResult: (Int,String)) in
                            if ( JamfProServer.majorVersion > 9 && JamfProServer.minorVersion > 34 ) {
                                JamfProServer.authType[whichServer] = "Bearer"
                            } else {
                                JamfProServer.authType[whichServer]  = "Basic"
                                JamfProServer.authCreds[whichServer] = basicCreds
                            }
                            completion(authResult)
                        }
                    
                })  // let task = session - end
                task.resume()
                semaphore.wait()
            }
        } else {
            completion((200,"success"))
        }
    }
    
    func getToken(serverUrl: String, whichServer: String, base64creds: String, completion: @escaping (_ authResult: (Int,String)) -> Void) {
        
        if wipeData.on && whichServer == "source" {
            completion((200, "success"))
        }
        
//        print("\(serverUrl.prefix(4))")
        if serverUrl.prefix(4) != "http" {
            completion((0, "skipped"))
            return
        }
        URLCache.shared.removeAllCachedResponses()
                
        var tokenUrlString = "\(serverUrl)/api/v1/auth/token"
        tokenUrlString     = tokenUrlString.replacingOccurrences(of: "//api", with: "/api")
    //        print("\(tokenUrlString)")
        
        let tokenUrl       = URL(string: "\(tokenUrlString)")
        let configuration  = URLSessionConfiguration.ephemeral
        var request        = URLRequest(url: tokenUrl!)
        request.httpMethod = "POST"
        
        WriteToLog().message(stringOfText: "[JamfPro.getToken] Attempting to retrieve token from \(String(describing: tokenUrl!))\n")
        
        configuration.httpAdditionalHeaders = ["Authorization" : "Basic \(base64creds)", "Content-Type" : "application/json", "Accept" : "application/json"]
        let session = Foundation.URLSession(configuration: configuration, delegate: self as URLSessionDelegate, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) -> Void in
            session.finishTasksAndInvalidate()
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
                    let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                    if let endpointJSON = json! as? [String: Any], let _ = endpointJSON["token"], let _ = endpointJSON["expires"] {
                        /*
                        switch whichServer {
                        case "source":
                            token.sourceServer  = endpointJSON["token"] as! String
                            token.sourceExpires = "\(endpointJSON["expires"] ?? "")"
                            
//                            print("\n[TokenDelegate] token for \(serverUrl): \(token.sourceServer)")
                        default:
                            token.destinationServer  = endpointJSON["token"] as! String
                            token.destinationExpires = "\(endpointJSON["expires"] ?? "")"
//                            print("\n[TokenDelegate] token for \(serverUrl): \(token.destServer)")
                        }
                        */
                        
                        JamfProServer.authCreds[whichServer]   = endpointJSON["token"] as? String
                        JamfProServer.authExpires[whichServer] = "\(endpointJSON["expires"] ?? "")"
                        JamfProServer.authType[whichServer]    = "Bearer"
                        if wipeData.on && whichServer == "destination" {
                            JamfProServer.authCreds["source"]   = JamfProServer.authCreds[whichServer]
                            JamfProServer.authExpires["source"] = JamfProServer.authExpires[whichServer]
                            JamfProServer.authType["source"]    = JamfProServer.authType[whichServer]
                        }
                        
//                      if LogLevel.debug { WriteToLog().message(stringOfText: "[JamfPro.getToken] Retrieved token: \(token)") }
//                      print("[JamfPro] result of token request: \(endpointJSON)")
                        WriteToLog().message(stringOfText: "[JamfPro.getToken] new token created for \(serverUrl)\n")
                        if JamfProServer.authType[whichServer] == "Bearer" {
                            self.refresh(server: serverUrl, whichServer: whichServer, b64Creds: base64creds)
                        }
                        completion((200, "success"))
                        return
                    } else {    // if let endpointJSON error
                        WriteToLog().message(stringOfText: "[JamfPro.getToken] JSON error.\n\(String(describing: json))\n")
                        completion((httpResponse.statusCode, "failed"))
                        return
                    }
                } else {    // if httpResponse.statusCode <200 or >299
                    _ = Alert().display(header: "\(serverUrl)", message: "Failed to authenticate to \(serverUrl). \nStatus Code: \(httpResponse.statusCode)", secondButton: "")
                    WriteToLog().message(stringOfText: "[JamfPro.getToken] Failed to authenticate to \(serverUrl).  Response error: \(httpResponse.statusCode).\n")
                    completion((httpResponse.statusCode, "failed"))
                    return
                }
            } else {
                _ = Alert().display(header: "\(serverUrl)", message: "Failed to connect. \nUnknown error, verify url and port.", secondButton: "")
                WriteToLog().message(stringOfText: "[JamfPro.getToken] token response error from \(serverUrl).  Verify url and port.\n")
                completion((0, "failed"))
                return
            }
        })
        task.resume()
    }
    
    func refresh(server: String, whichServer: String, b64Creds: String) {
        renewQ.async { [self] in
//        sleep(1200) // 20 minutes
            sleep(token.refreshInterval)
            getToken(serverUrl: server, whichServer: whichServer, base64creds: b64Creds) {
                (result: (Int, String)) in
//                print("[JamfPro.refresh] returned: \(result)")
            }
        }
    }
}
