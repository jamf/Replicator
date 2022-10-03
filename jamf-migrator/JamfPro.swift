//
//  JamfPro.swift
//  jamf-migrator
//
//  Created by Leslie Helou on 12/11/19.
//  Copyright © 2019 Leslie Helou. All rights reserved.
//

import Foundation

class JamfPro: NSObject, URLSessionDelegate {
    
    var controller: ViewController? = nil
    init(controller: ViewController) {
      self.controller = controller
    }
    var sdController: SourceDestVC? = nil
    init(sdController: SourceDestVC) {
      self.sdController = sdController
    }
    
    var renewQ = DispatchQueue(label: "com.jamfmigrator.token_refreshQ", qos: DispatchQoS.background)   // running background process for refreshing token
    
    let userDefaults = UserDefaults.standard
    
    func getToken(whichServer: String, serverUrl: String, base64creds: String, localSource: Bool, completion: @escaping (_ authResult: (Int,String)) -> Void) {

        if !((whichServer == "source" && (!wipeData.on && !localSource)) || (whichServer == "destination" && !export.saveOnly)) {
            WriteToLog().message(stringOfText: "[JamfPro.getToken] Skip getToken for \(serverUrl)\n")
            completion((200, "success"))
            return
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
        
        if !(JamfProServer.validToken[whichServer] ?? false) || (JamfProServer.base64Creds[whichServer] != base64creds) {
            WriteToLog().message(stringOfText: "[JamfPro.getToken] Attempting to retrieve token from \(String(describing: tokenUrl!))\n")
            
            configuration.httpAdditionalHeaders = ["Authorization" : "Basic \(base64creds)", "Content-Type" : "application/json", "Accept" : "application/json", "User-Agent" : appInfo.userAgentHeader]
            let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
            let task = session.dataTask(with: request as URLRequest, completionHandler: {
                (data, response, error) -> Void in
                session.finishTasksAndInvalidate()
                if let httpResponse = response as? HTTPURLResponse {
                    if pref.httpSuccess.contains(httpResponse.statusCode) {
                        let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                        if let endpointJSON = json! as? [String: Any], let _ = endpointJSON["token"], let _ = endpointJSON["expires"] {
                            JamfProServer.validToken[whichServer]  = true
                            JamfProServer.authCreds[whichServer]   = endpointJSON["token"] as? String
                            JamfProServer.authExpires[whichServer] = "\(endpointJSON["expires"] ?? "")"
                            JamfProServer.authType[whichServer]    = "Bearer"
                            JamfProServer.base64Creds[whichServer] = base64creds
                            if wipeData.on && whichServer == "destination" {
                                JamfProServer.authCreds["source"]   = JamfProServer.authCreds[whichServer]
                                JamfProServer.authExpires["source"] = JamfProServer.authExpires[whichServer]
                                JamfProServer.authType["source"]    = JamfProServer.authType[whichServer]
                            }
                            
    //                      if LogLevel.debug { WriteToLog().message(stringOfText: "[JamfPro.getToken] Retrieved token: \(token)") }
    //                      print("[JamfPro] result of token request: \(endpointJSON)")
                            WriteToLog().message(stringOfText: "[JamfPro.getToken] new token created for \(serverUrl)\n")
                            
                            if JamfProServer.version[whichServer] == "" {
                                // get Jamf Pro version - start
                                Jpapi().action(serverUrl: serverUrl, endpoint: "jamf-pro-version", apiData: [:], id: "", token: JamfProServer.authCreds[whichServer]!, method: "GET") {
                                    (result: [String:Any]) in
                                    if let versionString = result["version"] as? String {
                                        
                                        if versionString != "" {
                                            WriteToLog().message(stringOfText: "[JamfPro.getVersion] Jamf Pro Version: \(versionString)\n")
                                            JamfProServer.version[whichServer] = versionString
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
                                                if ( JamfProServer.majorVersion > 9 && JamfProServer.minorVersion > 34 ) {
                                                    JamfProServer.authType[whichServer] = "Bearer"
                                                    WriteToLog().message(stringOfText: "[JamfPro.getVersion] \(serverUrl) set to use OAuth\n")
                                                    
                                                } else {
                                                    JamfProServer.authType[whichServer]  = "Basic"
                                                    JamfProServer.authCreds[whichServer] = base64creds
                                                    WriteToLog().message(stringOfText: "[JamfPro.getVersion] \(serverUrl) set to use Basic\n")
                                                }
                                                if JamfProServer.authType[whichServer] == "Bearer" {
                                                    self.refresh(server: serverUrl, whichServer: whichServer, b64Creds: JamfProServer.base64Creds[whichServer]!, localSource: localSource)
                                                }
                                                completion((200, "success"))
                                                return
                                            }
                                        }
                                    } else {   // if let versionString - end
                                        WriteToLog().message(stringOfText: "[JamfPro.getToken] failed to get version information from \(String(describing: serverUrl))\n")
                                        JamfProServer.validToken[whichServer]  = false
                                        _ = Alert().display(header: "Attention", message: "Failed to get version information from \(String(describing: serverUrl))", secondButton: "")
                                        completion((httpResponse.statusCode, "failed"))
                                        return
                                    }
                                }
                                // get Jamf Pro version - end
                            } else {
                                if JamfProServer.authType[whichServer] == "Bearer" {
                                    WriteToLog().message(stringOfText: "[JamfPro.getVersion] call token refresh process for \(serverUrl)\n")
                                    self.refresh(server: serverUrl, whichServer: whichServer, b64Creds: JamfProServer.base64Creds[whichServer]!, localSource: localSource)
                                }
                                completion((200, "success"))
                                return
                            }
                        } else {    // if let endpointJSON error
                            WriteToLog().message(stringOfText: "[JamfPro.getToken] JSON error.\n\(String(describing: json))\n")
                            JamfProServer.validToken[whichServer]  = false
                            completion((httpResponse.statusCode, "failed"))
                            return
                        }
                    } else {    // if httpResponse.statusCode <200 or >299
                        _ = Alert().display(header: "\(serverUrl)", message: "Failed to authenticate to \(serverUrl). \nStatus Code: \(httpResponse.statusCode)", secondButton: "")
                        WriteToLog().message(stringOfText: "[JamfPro.getToken] Failed to authenticate to \(serverUrl).  Response error: \(httpResponse.statusCode).\n")
                        JamfProServer.validToken[whichServer]  = false
                        completion((httpResponse.statusCode, "failed"))
                        return
                    }
                } else {
                    _ = Alert().display(header: "\(serverUrl)", message: "Failed to connect. \nUnknown error, verify url and port.", secondButton: "")
                    WriteToLog().message(stringOfText: "[JamfPro.getToken] token response error from \(serverUrl).  Verify url and port.\n")
                    JamfProServer.validToken[whichServer]  = false
                    completion((0, "failed"))
                    return
                }
            })
            task.resume()
        } else {
            WriteToLog().message(stringOfText: "[JamfPro.getToken] Use existing token from \(String(describing: tokenUrl!))\n")
            completion((200, "success"))
            return
        }
        
    }
    
    func refresh(server: String, whichServer: String, b64Creds: String, localSource: Bool) {
        if controller!.stop_button.isHidden {
            JamfProServer.validToken["source"]      = false
            JamfProServer.validToken["destination"] = false
            WriteToLog().message(stringOfText: "[JamfPro.refresh] terminated token refresh\n")
            return
        }
        WriteToLog().message(stringOfText: "[JamfPro.refresh] queue token refresh for \(server)\n")
        renewQ.async { [self] in
            sleep(token.refreshInterval)
            JamfProServer.validToken[whichServer] = false
            getToken(whichServer: whichServer, serverUrl: server, base64creds: JamfProServer.base64Creds[whichServer]!, localSource: localSource) {
                (result: (Int, String)) in
//                print("[JamfPro.refresh] returned: \(result)")
            }
        }
    }
}
