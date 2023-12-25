//
//  JamfPro.swift
//  jamf-migrator
//
//  Created by Leslie Helou on 12/11/19.
//  Copyright © 2019 Leslie Helou. All rights reserved.
//

import Foundation
import AppKit

class JamfPro: NSObject, URLSessionDelegate {
    
//    var controller: ViewController? = nil
//    init(controller: ViewController) {
//      self.controller = controller
//    }
//    var sdController: SourceDestVC? = nil
//    init(sdController: SourceDestVC) {
//      self.sdController = sdController
//    }
    
    var renewQ = DispatchQueue(label: "com.jamfmigrator.token_refreshQ", qos: DispatchQoS.background)   // running background process for refreshing token
    
//    let userDefaults = UserDefaults.standard
    
    func getToken(whichServer: String, serverUrl: String, base64creds: String, localSource: Bool = false, completion: @escaping (_ authResult: (Int,String)) -> Void) {
       
        if !((whichServer == "source" && (!wipeData.on && !localSource)) || (whichServer == "dest" && !export.saveOnly)) {
            WriteToLog().message(stringOfText: "[JamfPro.getToken] Skip getToken for \(serverUrl)\n")
            completion((200, "success"))
            return
        }
        
        let forceBasicAuth = (userDefaults.integer(forKey: "forceBasicAuth") == 1) ? true:false
//        WriteToLog().message(stringOfText: "[JamfPro.getToken] Force basic authentication on \(serverUrl): \(forceBasicAuth)\n")
        
//        print("\(serverUrl.prefix(4))")
        if serverUrl.prefix(4) != "http" {
            completion((0, "skipped"))
            return
        }
        URLCache.shared.removeAllCachedResponses()
                
        var tokenUrlString = "\(serverUrl)/api/v1/auth/token"
        var apiClient = false
        switch whichServer {
        case "source":
            if JamfProServer.sourceUseApiClient == 1 {
                tokenUrlString = "\(serverUrl)/api/oauth/token"
                apiClient = true
            }
        case "dest":
            if JamfProServer.destUseApiClient == 1 {
                tokenUrlString = "\(serverUrl)/api/oauth/token"
                apiClient = true
            }
        default:
            break
        }
        
        tokenUrlString     = tokenUrlString.replacingOccurrences(of: "//api", with: "/api")
//        print("[getToken] tokenUrlString: \(tokenUrlString)")

        let tokenUrl       = URL(string: "\(tokenUrlString)")
        guard let _ = tokenUrl else {
            print("problem constructing the URL from \(tokenUrlString)")
            completion((500, "failed"))
            return
        }
        let configuration  = URLSessionConfiguration.ephemeral
        var request        = URLRequest(url: tokenUrl!)
        request.httpMethod = "POST"
        
        let forWhat = (whichServer == "source") ? "sourceTokenAge":"destTokenAge"
        let (_, minutesOld, _) = timeDiff(forWhat: forWhat)
        
        if !(JamfProServer.validToken[whichServer] ?? false) || (JamfProServer.base64Creds[whichServer] != base64creds) || ( minutesOld > (token.refreshInterval[whichServer] ?? 29) ) {
            WriteToLog().message(stringOfText: "[JamfPro.getToken] Attempting to retrieve token from \(String(describing: tokenUrl!)) for version look-up\n")
            
            print("[JamfPro]         \(whichServer) tokenAge: \(minutesOld) minutes")
            print("[JamfPro] \(whichServer) refresh interval: \(token.refreshInterval[whichServer] ?? 29) minutes")
            
            if apiClient {
                let clientId = ( whichServer == "source" ) ? JamfProServer.sourceUser:JamfProServer.destUser
                let secret   = ( whichServer == "source" ) ? JamfProServer.sourcePwd:JamfProServer.destPwd
                let clientString = "grant_type=client_credentials&client_id=\(String(describing: clientId))&client_secret=\(String(describing: secret))"
//                print("[getToken] clientString: \(clientString)")

                let requestData = clientString.data(using: .utf8)
                request.httpBody = requestData
                configuration.httpAdditionalHeaders = ["Content-Type" : "application/x-www-form-urlencoded", "Accept" : "application/json", "User-Agent" : AppInfo.userAgentHeader]
            } else {
                configuration.httpAdditionalHeaders = ["Authorization" : "Basic \(base64creds)", "Content-Type" : "application/json", "Accept" : "application/json", "User-Agent" : AppInfo.userAgentHeader]
            }
            
            let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
            let task = session.dataTask(with: request as URLRequest, completionHandler: {
                (data, response, error) -> Void in
                session.finishTasksAndInvalidate()
                if let httpResponse = response as? HTTPURLResponse {
                    if pref.httpSuccess.contains(httpResponse.statusCode) {
                        let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
//                        if let endpointJSON = json! as? [String: Any], let _ = endpointJSON["token"], let _ = endpointJSON["expires"] {
                        if let endpointJSON = json! as? [String: Any] {
                            JamfProServer.validToken[whichServer]  = true
                            JamfProServer.authCreds[whichServer]   = apiClient ? endpointJSON["access_token"] as? String:endpointJSON["token"] as? String ?? ""
//                            JamfProServer.authExpires[whichServer] = apiClient ? endpointJSON["expires_in"] as? Int ?? 35:35
                            token.refreshInterval[whichServer]     = UInt32(apiClient ? endpointJSON["expires_in"] as? Int ?? 29:29)
                            JamfProServer.authType[whichServer]    = "Bearer"
                            JamfProServer.base64Creds[whichServer] = base64creds
                            if wipeData.on && whichServer == "dest" {
                                JamfProServer.authCreds["source"]   = JamfProServer.authCreds[whichServer]
//                                JamfProServer.authExpires["source"] = JamfProServer.authExpires[whichServer]
                                JamfProServer.authType["source"]    = JamfProServer.authType[whichServer]
                            }
                            JamfProServer.tokenCreated[whichServer] = Date()
                            
    //                      if LogLevel.debug { WriteToLog().message(stringOfText: "[JamfPro.getToken] Retrieved token: \(token)") }
                            print("[JamfPro] \(whichServer) received a new token")
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
                                                if ( JamfProServer.majorVersion > 10 || ( JamfProServer.majorVersion > 9 && JamfProServer.minorVersion > 34 ) ) && !forceBasicAuth {
                                                    JamfProServer.authType[whichServer] = "Bearer"
                                                    JamfProServer.validToken[whichServer] = true
                                                    WriteToLog().message(stringOfText: "[JamfPro.getVersion] \(serverUrl) set to use Bearer Token\n")
                                                    
                                                } else {
                                                    JamfProServer.authType[whichServer]  = "Basic"
                                                    JamfProServer.validToken[whichServer] = false
                                                    JamfProServer.authCreds[whichServer] = base64creds
                                                    WriteToLog().message(stringOfText: "[JamfPro.getVersion] \(serverUrl) set to use Basic Authentication\n")
                                                }
//                                                if JamfProServer.authType[whichServer] == "Bearer" {
//                                                    self.refresh(server: serverUrl, whichServer: whichServer, b64Creds: JamfProServer.base64Creds[whichServer]!, localSource: localSource)
//                                                }
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
//                                if JamfProServer.authType[whichServer] == "Bearer" {
//                                    WriteToLog().message(stringOfText: "[JamfPro.getVersion] call token refresh process for \(serverUrl)\n")
//                                    self.refresh(server: serverUrl, whichServer: whichServer, b64Creds: JamfProServer.base64Creds[whichServer]!, localSource: localSource)
//                                }
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
                        WriteToLog().message(stringOfText: "[JamfPro.getToken] Failed to authenticate to \(serverUrl).  Response error: \(httpResponse.statusCode).\n")
                        if setting.fullGUI {
                            _ = Alert().display(header: "\(serverUrl)", message: "Failed to authenticate to \(serverUrl). \nStatus Code: \(httpResponse.statusCode)", secondButton: "")
                        } else {
                            NSApplication.shared.terminate(self)
                        }
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
//            WriteToLog().message(stringOfText: "[JamfPro.getToken] Use existing token from \(String(describing: tokenUrl!))\n")
            completion((200, "success"))
            return
        }
        
    }
    
    func refresh(server: String = "", whichServer: String = "", b64Creds: String, localSource: Bool) {
//        if controller!.go_button.title == "Stop" {
        DispatchQueue.main.async { [self] in
            if migrationComplete.isDone {
                JamfProServer.validToken["source"]      = false
                JamfProServer.validToken["dest"] = false
                WriteToLog().message(stringOfText: "[JamfPro.refresh] terminated token refresh\n")
                return
            }
            WriteToLog().message(stringOfText: "[JamfPro.refresh] queue token refresh for \(server)\n")
            renewQ.async { [self] in
                
                if JamfProServer.authType["source"] == "Bearer" {
                    sleep(token.refreshInterval["source"] ?? 29)
                    WriteToLog().message(stringOfText: "[JamfPro.refresh] new token for source server\n")
                    JamfProServer.validToken["source"] = false
                    getToken(whichServer: "source", serverUrl: JamfProServer.source, base64creds: JamfProServer.base64Creds["source"]!, localSource: localSource) {
                        (result: (Int, String)) in
    //                    print("[JamfPro.refresh] returned: \(result)")
                    }
                }
                if JamfProServer.authType["dest"] == "Bearer" {
                    sleep(token.refreshInterval["dest"] ?? 29)
                    WriteToLog().message(stringOfText: "[JamfPro.refresh] new token for destination server\n")
                    JamfProServer.validToken["dest"] = false
                    getToken(whichServer: "dest", serverUrl: JamfProServer.destination, base64creds: JamfProServer.base64Creds["dest"]!, localSource: localSource) {
                        (result: (Int, String)) in
    //                    print("[JamfPro.refresh] returned: \(result)")
                    }
                }
            }
        }
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(  URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
}
