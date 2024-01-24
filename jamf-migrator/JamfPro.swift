//
//  JamfPro.swift
//  jamf-migrator
//
//  Created by Leslie Helou on 12/11/19.
//  Copyright © 2019 Leslie Helou. All rights reserved.
//
// Reference: https://developer.jamf.com/jamf-pro/docs/jamf-pro-api-overview

import Foundation
import AppKit

class JamfPro: NSObject, URLSessionDelegate {
    
    var renewQ = DispatchQueue(label: "com.jamfmigrator.token_refreshQ", qos: DispatchQoS.background)   // running background process for refreshing token
    
//    let userDefaults = UserDefaults.standard
    
    func getToken(whichServer: String, serverUrl: String, base64creds: String, localSource: Bool = false, completion: @escaping (_ authResult: (Int,String)) -> Void) {
        
        let tokenAge = (whichServer == "source") ? "sourceTokenAge":"destTokenAge"
        let tokenAgeInSeconds = timeDiff(forWhat: tokenAge).3
        
        
//        print("\n[getToken] \(Date())")
//        print("[getToken]           \(whichServer) valid token: \(JamfProServer.validToken[whichServer] ?? false)")
//        print("[getToken]     \(whichServer) tokenAgeInSeconds: \(tokenAgeInSeconds)")
//        print("[getToken]           \(whichServer) authExpires: \(JamfProServer.authExpires[whichServer]!)")
//        print("[getToken]           \(whichServer) wipeData.on: \(wipeData.on)")
//        print("[getToken]           \(whichServer) localSource: \(localSource)")
//        print("[getToken]     \(whichServer) export.saveRawXml: \(export.saveRawXml)")
//        print("[getToken] \(whichServer) export.saveTrimmedXml: \(export.saveTrimmedXml)")
//        print("[getToken]      \(whichServer) !export.saveOnly: \(!export.saveOnly)")
//        
//        print("[getToken]                          source test: \( whichServer == "source" && ( wipeData.on || localSource ))")
//        print("[getToken]                            dest test: \( whichServer == "dest" && ( whichServer == "dest" && export.saveOnly ))")
        
        
//        if !((whichServer == "source" && ( !wipeData.on && !localSource )) || (whichServer == "dest" && !export.saveOnly)) {
        if ((whichServer == "source" && ( wipeData.on || localSource )) || (whichServer == "dest" && export.saveOnly)) {
            WriteToLog().message(stringOfText: "[JamfPro.getToken] Skip getToken for \(whichServer): \(serverUrl)\n")
            completion((200, "success"))
            return
        }
        
        let forceBasicAuth = (userDefaults.integer(forKey: "forceBasicAuth") == 1) ? true:false
//        WriteToLog().message(stringOfText: "[JamfPro.getToken] Force basic authentication on \(serverUrl): \(forceBasicAuth)\n")
        
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
//        let clientType = apiClient ? "API client/secret":"username/password"
//        WriteToLog().message(stringOfText: "[JamfPro.getToken] Using \(clientType) to generate token for \(serverUrl.fqdnFromUrl).\n")
        
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
        
        if !(JamfProServer.validToken[whichServer] ?? false) || tokenAgeInSeconds >= JamfProServer.authExpires[whichServer]! || (JamfProServer.base64Creds[whichServer] != base64creds) {
            if JamfProServer.authType[whichServer] == "Bearer" {
                WriteToLog().message(stringOfText: "[JamfPro.getToken] Token for \(whichServer) server is \(Int(tokenAgeInSeconds/60)) minutes old.\n")
            }
            WriteToLog().message(stringOfText: "[JamfPro.getToken] Attempting to retrieve token from \(String(describing: tokenUrl!))\n")
            
//            print("[JamfPro]         \(whichServer) tokenAge: \(minutesOld) minutes")
            
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
//                            print("[getToken] endpointJSON: \(endpointJSON)")
                            if apiClient {
                                JamfProServer.authExpires[whichServer] = (endpointJSON["expires_in"] as? Double ?? 60.0)
                            } else {
                                JamfProServer.authExpires[whichServer] = (endpointJSON["expires"] as? Double ?? 20.0)!*60
                            }
                            // for testing
//                            JamfProServer.authExpires[whichServer] = 20.0*60
                            
                            JamfProServer.authExpires[whichServer] = JamfProServer.authExpires[whichServer]!*0.75
                            JamfProServer.validToken[whichServer]  = true
                            JamfProServer.authCreds[whichServer]   = apiClient ? endpointJSON["access_token"] as? String:endpointJSON["token"] as? String ?? ""

                            JamfProServer.authType[whichServer]    = "Bearer"
                            JamfProServer.base64Creds[whichServer] = base64creds
                            if wipeData.on && whichServer == "dest" {
                                JamfProServer.validToken["source"]  = JamfProServer.validToken[whichServer]
                                JamfProServer.authCreds["source"]   = JamfProServer.authCreds[whichServer]
//                                JamfProServer.authExpires["source"] = JamfProServer.authExpires[whichServer]
                                JamfProServer.authType["source"]    = JamfProServer.authType[whichServer]
                            }
                            JamfProServer.tokenCreated[whichServer] = Date()
                            
    //                      if LogLevel.debug { WriteToLog().message(stringOfText: "[JamfPro.getToken] Retrieved token: \(token)") }
                            print("[JamfPro] \(whichServer) received a new token")
                            WriteToLog().message(stringOfText: "[JamfPro.getToken] new token created for \(whichServer): \(serverUrl)\n")
                            
                            if JamfProServer.version[whichServer] == "" {
                                // get Jamf Pro version - start
                                Jpapi().action(serverUrl: serverUrl, endpoint: "jamf-pro-version", apiData: [:], id: "", token: JamfProServer.authCreds[whichServer]!, method: "GET") {
                                    (result: [String:Any]) in
                                    if let versionString = result["version"] as? String {
                                        
                                        if versionString != "" {
                                            WriteToLog().message(stringOfText: "[JamfPro.getVersion] \(whichServer) Jamf Pro Version: \(versionString)\n")
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
                                print("[JamfPro] \(whichServer) Jamf Pro version: \(String(describing: JamfProServer.version[whichServer]))")
                                completion((202, "success"))
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
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(  URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
}
