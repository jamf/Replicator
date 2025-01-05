//
//  JamfPro.swift
//  Replicator
//
//  Created by Leslie Helou on 12/11/19.
//  Copyright 2024 Jamf. All rights reserved.
//
// Reference: https://developer.jamf.com/jamf-pro/docs/jamf-pro-api-overview

import Foundation
import AppKit

class JamfPro: NSObject, URLSessionDelegate {
    
    static let shared = JamfPro()
    private override init() { }
    
    var authQ       = DispatchQueue(label: "com.jamf.auth")
            
    fileprivate func renewToken(renew: Bool, whichServer: String, baseUrl: String, base64creds: String) {
        if !migrationComplete.isDone && renew && JamfProServer.authType[whichServer] == "Bearer" {
            WriteToLog.shared.message(stringOfText: "[JamfPro.getVersion] \(whichServer.localizedCapitalized) server token renews in \(JamfProServer.authExpires[whichServer]! + 1) seconds")
            DispatchQueue.main.asyncAfter(deadline: .now() + JamfProServer.authExpires[whichServer]! + 1) { [self] in
                WriteToLog.shared.message(stringOfText: "[JamfPro.getVersion] renewing \(whichServer.localizedCapitalized) token")
                getToken(whichServer: whichServer, serverUrl: baseUrl, base64creds: base64creds) {
                    (result: (Int, String)) in
                }
            }
        }
    }
    
    func getToken(whichServer: String, serverUrl: String, base64creds: String, localSource: Bool = false, renew: Bool = true, completion: @escaping (_ authResult: (Int,String)) -> Void) {
        
        if JamfProServer.authType[whichServer] == "Basic" {
            completion((200, "success"))
            return
        }
        
        let tokenAge = (whichServer == "source") ? "sourceTokenAge":"destTokenAge"
        let tokenAgeInSeconds = timeDiff(forWhat: tokenAge).3
        
//        print("\n[getToken] \(Date())")
//        print("[getToken]           \(whichServer) valid token: \(JamfProServer.validToken[whichServer] ?? false)")
//        print("[getToken]     \(whichServer) tokenAgeInSeconds: \(tokenAgeInSeconds)")
//        print("[getToken]           \(whichServer) authExpires: \(JamfProServer.authExpires[whichServer]!)")
//        print("[getToken]           \(whichServer) WipeData.state.on: \(WipeData.state.on)")
//        print("[getToken]           \(whichServer) localSource: \(localSource)")
//        print("[getToken]     \(whichServer) export.saveRawXml: \(export.saveRawXml)")
//        print("[getToken] \(whichServer) export.saveTrimmedXml: \(export.saveTrimmedXml)")
//        print("[getToken]      \(whichServer) !export.saveOnly: \(!export.saveOnly)")
//        
//        print("[getToken]                          source test: \( whichServer == "source" && ( WipeData.state.on || localSource ))")
//        print("[getToken]                            dest test: \( whichServer == "dest" && ( whichServer == "dest" && export.saveOnly ))")
        
//        if !((whichServer == "source" && ( !WipeData.state.on && !localSource )) || (whichServer == "dest" && !export.saveOnly)) {
        if ((whichServer == "source" && ( WipeData.state.on || localSource )) || (whichServer == "dest" && export.saveOnly)) {
            completion((200, "success"))
            return
        }
        
        let forceBasicAuth = (userDefaults.integer(forKey: "forceBasicAuth") == 1) ? true:false
//        print("forceBasicAuth: \(forceBasicAuth)")
        
        if serverUrl.prefix(4) != "http" {
            completion((0, "skipped"))
            return
        }
        URLCache.shared.removeAllCachedResponses()
                
        let baseUrl = serverUrl.baseUrl
        var tokenUrlString = "\(baseUrl)/api/v1/auth/token"
        var apiClient = false
        switch whichServer {
        case "source":
            if JamfProServer.sourceUseApiClient == 1 {
                tokenUrlString = "\(baseUrl)/api/oauth/token"
                apiClient = true
            }
        case "dest":
            if JamfProServer.destUseApiClient == 1 {
                tokenUrlString = "\(baseUrl)/api/oauth/token"
                apiClient = true
            }
        default:
            break
        }
         
        tokenUrlString     = tokenUrlString.replacingOccurrences(of: "//api", with: "/api")
//        print("[getToken] tokenUrlString: \(tokenUrlString)")

        let tokenUrl = URL(string: "\(tokenUrlString)")
        guard let _ = tokenUrl else {
            print("problem constructing the URL from \(tokenUrlString)")
            completion((500, "failed"))
            return
        }
        let configuration  = URLSessionConfiguration.ephemeral
        var request        = URLRequest(url: tokenUrl!)
        request.httpMethod = "POST"
        
        if !(JamfProServer.validToken[whichServer] ?? false) || tokenAgeInSeconds >= JamfProServer.authExpires[whichServer] ?? 0 || (JamfProServer.base64Creds[whichServer] != base64creds) {
            if JamfProServer.authType[whichServer] == "Bearer" {
                WriteToLog.shared.message(stringOfText: "[JamfPro.getToken] Token for \(whichServer) server is \(Int(tokenAgeInSeconds/60)) minutes old. Expires in \(JamfProServer.authExpires[whichServer] ?? 0) seconds.")
            }
            
            if apiClient {
                WriteToLog.shared.message(stringOfText: "[JamfPro.getToken] using API client/secret to generate token for \(whichServer) server")
            } else {
                WriteToLog.shared.message(stringOfText: "[JamfPro.getToken] using username/password to generate token for \(whichServer) server")
            }
            
            WriteToLog.shared.message(stringOfText: "[JamfPro.getToken] Attempting to retrieve token from \(String(describing: tokenUrl!))")
            
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
//            print("[getToken] configuration.httpAdditionalHeaders: \(configuration.httpAdditionalHeaders)")
            
            let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
            let task = session.dataTask(with: request as URLRequest, completionHandler: { [self]
                (data, response, error) -> Void in
                session.finishTasksAndInvalidate()
                if let httpResponse = response as? HTTPURLResponse {
                    if pref.httpSuccess.contains(httpResponse.statusCode) {
                        do {
                            let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                            if let endpointJSON = json as? [String: Any] {
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
                                JamfProServer.accessToken[whichServer] = JamfProServer.authCreds[whichServer]
                                
                                JamfProServer.authType[whichServer]    = "Bearer"
                                JamfProServer.base64Creds[whichServer] = base64creds
                                if WipeData.state.on && whichServer == "dest" {
                                    JamfProServer.validToken["source"]  = JamfProServer.validToken[whichServer]
                                    JamfProServer.authCreds["source"]   = JamfProServer.authCreds[whichServer]
                                    JamfProServer.accessToken["source"] = JamfProServer.accessToken[whichServer]
                                    JamfProServer.authType["source"]    = JamfProServer.authType[whichServer]
                                }
                                JamfProServer.tokenCreated[whichServer] = Date()
                                
                                print("[JamfPro] \(whichServer) received a new token")
                                WriteToLog.shared.message(stringOfText: "[JamfPro.getToken] new token created for \(whichServer): \(baseUrl)")
                                
                                if JamfProServer.version[whichServer] == "" {
                                    if whichServer == "source" {
                                        JamfProServer.source = baseUrl
                                    } else {
                                        JamfProServer.destination = baseUrl
                                    }
                                    // get Jamf Pro version - start
                                    Jpapi.shared.action(whichServer: whichServer, endpoint: "jamf-pro-version", apiData: [:], id: "", token: JamfProServer.authCreds[whichServer]!, method: "GET") { [self]
                                        (result: [String:Any]) in
                                        if let versionString = result["version"] as? String {
                                            
                                            if versionString != "" {
                                                WriteToLog.shared.message(stringOfText: "[JamfPro.getVersion] \(whichServer) Jamf Pro Version: \(versionString)")
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
                                                        WriteToLog.shared.message(stringOfText: "[JamfPro.getVersion] \(baseUrl) set to use Bearer Token")
                                                        
                                                        
                                                    } else {
                                                        JamfProServer.authType[whichServer]  = "Basic"
                                                        JamfProServer.validToken[whichServer] = false
                                                        JamfProServer.authCreds[whichServer] = base64creds
                                                        WriteToLog.shared.message(stringOfText: "[JamfPro.getVersion] \(baseUrl) set to use Basic Authentication")
                                                    }
                                                    
                                                    print("[JamfPro] migrationComplete.isDone: \(migrationComplete.isDone)")
                                                    print("[JamfPro] renew: \(renew)")
                                                    renewToken(renew: renew, whichServer: whichServer, baseUrl: baseUrl, base64creds: base64creds)
                                                    
                                                    completion((200, "success"))
                                                    return
                                                    
                                                }
                                            }
                                        } else {   // if let versionString - end
                                            WriteToLog.shared.message(stringOfText: "[JamfPro.getToken] failed to get version information from \(String(describing: baseUrl))")
                                            JamfProServer.validToken[whichServer]  = false
                                            _ = Alert.shared.display(header: "Attention", message: "Failed to get version information from \(String(describing: baseUrl))", secondButton: "")
                                            completion((httpResponse.statusCode, "failed"))
                                            return
                                        }
                                    }
                                    // get Jamf Pro version - end
                                } else {
                                    renewToken(renew: renew, whichServer: whichServer, baseUrl: baseUrl, base64creds: base64creds)
                                    //                                if !migrationComplete.isDone && renew {
                                    //                                    WriteToLog.shared.message(stringOfText: "[JamfPro.getVersion] \(whichServer.localizedCapitalized) server token renews in \(JamfProServer.authExpires[whichServer]! + 1) seconds")
                                    //                                    DispatchQueue.main.asyncAfter(deadline: .now() + JamfProServer.authExpires[whichServer]! + 1) { [self] in
                                    //                                        WriteToLog.shared.message(stringOfText: "[JamfPro.getVersion] renewing \(whichServer.localizedCapitalized) token")
                                    //                                        getToken(whichServer: whichServer, serverUrl: baseUrl, base64creds: base64creds) {
                                    //                                            (result: (Int, String)) in
                                    //                                        }
                                    //                                    }
                                    //                                }
                                    //                                print("[JamfPro] \(whichServer) Jamf Pro version: \(String(describing: JamfProServer.version[whichServer]))")
                                    completion((202, "success"))
                                    return
                                }
                            } else {    // if let endpointJSON error
                                WriteToLog.shared.message(stringOfText: "[JamfPro.getToken] JSON error.\n\(String(describing: json))")
                                JamfProServer.validToken[whichServer]  = false
                                completion((httpResponse.statusCode, "failed"))
                                return
                            }
                        } catch {
                            WriteToLog.shared.message(stringOfText: "[JamfPro.getToken] failed to parse JSON from token request. Returned data: \(String(decoding: data ?? Data(), as: UTF8.self))")
                        }
                    } else {    // if httpResponse.statusCode <200 or >299
                        WriteToLog.shared.message(stringOfText: "[JamfPro.getToken] Failed to authenticate to \(baseUrl).  Response error: \(httpResponse.statusCode).")
                        if setting.fullGUI {
                            _ = Alert.shared.display(header: "\(baseUrl)", message: "Failed to authenticate to \(baseUrl). \nStatus Code: \(httpResponse.statusCode)", secondButton: "")
                        } else {
                            NSApplication.shared.terminate(self)
                        }
                        JamfProServer.validToken[whichServer]  = false
                        completion((httpResponse.statusCode, "failed"))
                        return
                    }
                } else {
                    _ = Alert.shared.display(header: "\(baseUrl)", message: "Failed to connect. \nUnknown error, verify url and port.", secondButton: "")
                    WriteToLog.shared.message(stringOfText: "[JamfPro.getToken] token response error from \(baseUrl).  Verify url and port.")
                    JamfProServer.validToken[whichServer]  = false
                    completion((0, "failed"))
                    return
                }
            })
            task.resume()
        } else {
//            WriteToLog.shared.message(stringOfText: "[JamfPro.getToken] Use existing token from \(String(describing: tokenUrl!))")
            completion((200, "success"))
            return
        }
        
    }
    
    func checkURL2(whichServer: String, serverURL: String, completion: @escaping (Bool) -> Void) {
//        print("enter checkURL2")
        if (whichServer == "dest" && export.saveOnly) || (whichServer == "source" && (WipeData.state.on || JamfProServer.importFiles == 1)) {
            completion(true)
        } else {
            var available:Bool = false
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[checkURL2] --- checking availability of server: \(serverURL)") }
        
            authQ.sync {
                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[checkURL2] checking: \(serverURL)") }
                
                var healthCheckURL = "\(serverURL)/healthCheck.html"
                healthCheckURL = healthCheckURL.replacingOccurrences(of: "//healthCheck.html", with: "/healthCheck.html")
                
                guard let encodedURL = URL(string: healthCheckURL) else {
                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[checkURL2] --- Cannot cast to URL: \(healthCheckURL)") }
                    completion(false)
                    return
                }
                let configuration = URLSessionConfiguration.ephemeral

                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[checkURL2] --- checking healthCheck page.") }
                var request = URLRequest(url: encodedURL)
                request.httpMethod = "GET"

                let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
                let task = session.dataTask(with: request as URLRequest, completionHandler: {
                    (data, response, error) -> Void in
                    session.finishTasksAndInvalidate()
                    if let httpResponse = response as? HTTPURLResponse {
                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[checkURL2] Server check: \(healthCheckURL), httpResponse: \(httpResponse.statusCode)") }
                        
                        //                    print("response: \(response)")
                        if let responseData = String(data: data!, encoding: .utf8) {
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[checkURL2] checkURL2 data: \(responseData)") }
                        } else {
                            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[checkURL2] checkURL2 data: none") }
                        }
                        available = true
                        
                    } // if let httpResponse - end
                    // server is not reachable - availability is still false
                    completion(available)
                })  // let task = session - end
                task.resume()
            }   // authQ - end
        }
    }   // func checkURL2 - end
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
}
