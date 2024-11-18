//
//  Jpapi.swift
//  Jamf Transporter
//
//  Created by Leslie Helou on 12/17/19.
//  Copyright 2024 Jamf. All rights reserved.
//

import Cocoa

class PatchManagementApi: NSObject, URLSessionDelegate {
    
    static let shared = PatchManagementApi()
    
    func createUpdate(serverUrl: String, endpoint: String = "patchmanagement", apiData: [String: Any], sourceEpId: String, destEpId: String, token: String, method: String, completion: @escaping (_ returnedJSON: [String: Any]) -> Void) {
        
        if method.lowercased() == "skip" {
            completion(["JPAPI_result":"no valid token found", "JPAPI_response":0])
            return
        }
        
        var createUpdateMethod = method
        var contentType = ""
        var accept      = ""
        var objectInstance: PatchSoftwareTitleConfiguration?
        let whichServer = (serverUrl == JamfProServer.source) ? "source":"dest"
                
        print("\n[createUpdate] apiData: \(apiData)\n")
        
        let objectData = try? JSONSerialization.data(withJSONObject: apiData, options: [])
        

        if method.lowercased() == "skip" {
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[Jpapi.action] skipping \(endpoint) endpoint with id \(destEpId).") }
            let JPAPI_result = (endpoint == "auth/invalidate-token") ? "no valid token":"failed"
            completion(["JPAPI_result":JPAPI_result, "JPAPI_response":000])
            return
        }
        
        URLCache.shared.removeAllCachedResponses()
        var path = ""
        var requestBody = Data()

        print("[Jpaapi.action] endpoint: \(endpoint)")
        
        do {
            let decoder = JSONDecoder()
            objectInstance = try decoder.decode(PatchSoftwareTitleConfiguration.self, from: objectData!)
        } catch {
            print("[createUpdate] JSON decode error: \(error)")
            completion(["JPAPI_result":"failed", "JPAPI_response":000])
            return
        }
        
        switch endpoint {
        case  "patchmanagement":
            let patchTitle = createPatchsoftwaretitleXml(objectInstance: objectInstance!)
            //print("name_id: \(tagValue(xmlString: patchTitle, xmlTag: "name_id"))")
            let siteId = objectId(xml: patchTitle, object: "site")
            let sourceTitle = PatchTitleConfigurations.source.filter( { $0.id == sourceEpId } ).first
            let sourceSiteName = sourceTitle?.siteName ?? "NONE"
            let destTitle = PatchTitleConfigurations.destination.filter( { ($0.softwareTitleNameId == "\(tagValue(xmlString: patchTitle, xmlTag: "name_id"))") && ($0.siteName == sourceSiteName) } ).first
            let destSiteName = destTitle?.siteName ?? "NONE"
            //print("dest config name: \(destTitle?.displayName ?? "unknown")")
            //print("source site name: \(sourceTitle?.siteName ?? "NONE")")
            //print("  dest site name: \(destTitle?.siteName ?? "NONE")")
            if ((destTitle?.displayName) != nil && (sourceSiteName == destSiteName)) {
                createUpdateMethod = "PATCH"
                path = "/api/v2/patch-software-title-configurations/\(destTitle?.id ?? "0")"
                contentType = "application/merge-patch+json"
                accept      = "application/json"
                let _Title = PatchTitleConfigurations.source.filter( { $0.id == sourceEpId } ).first
                if let jamfOfficial = destTitle?.jamfOfficial,
                   let displayName = _Title?.displayName,
//                   let categoryId = destTitle?.categoryId,
//                   let siteId = destTitle?.siteId,
                   let uiNotifications = _Title?.uiNotifications,
                   let emailNotifications = _Title?.emailNotifications,
                   let softwareTitleId = destTitle?.softwareTitleId,
                   let softwareTitleName = destTitle?.softwareTitleName,
                   let softwareTitleNameId = _Title?.softwareTitleNameId,
                   let softwareTitlePublisher = _Title?.softwareTitlePublisher,
                   let patchSourceName = _Title?.patchSourceName,
                   let patchSourceEnabled = _Title?.patchSourceEnabled {
                   let putTitle: [String: Any] = ["jamfOfficial": jamfOfficial,
                          "displayName": displayName,
                          "categoryId": objectId(xml: patchTitle, object: "categories"),
                          "siteId": objectId(xml: patchTitle, object: "site"),
                          "uiNotifications": uiNotifications,
                          "emailNotifications": emailNotifications,
                          "softwareTitleId": softwareTitleId,
                          "softwareTitleName": softwareTitleName,
                          "softwareTitleNameId": softwareTitleNameId,
                          "softwareTitlePublisher": softwareTitlePublisher,
                          "patchSourceName": patchSourceName,
                          "patchSourceEnabled": patchSourceEnabled]
                    do {
                        requestBody = try JSONSerialization.data(withJSONObject: putTitle, options: .prettyPrinted)
                    } catch let error {
                        print("[createUpdate] requestBody: unable to decode")
                        print(error.localizedDescription)
                        completion([:])
                        return
                    }
                } else {
                    print("[createUpdate] requestBody: \(String(data: requestBody, encoding: .utf8) ?? "unable to decode")")
//                    print("[createUpdate] unable to set data for put")
                    completion([:])
                    return
                }
            } else {
                createUpdateMethod = "POST"
                path = "/JSSResource/patchsoftwaretitles/id/0"
                contentType = "text/xml"
                accept      = "text/xml"
                requestBody = patchTitle.data(using: String.Encoding.utf8) ?? Data()
            }
//            let destId = (createUpdateMethod == "PUT") ?? destTitle?.id ?? "0":"0"

            print("[createUpdate] \(createUpdateMethod) patchTitle: \(patchTitle)")
        case "patch-software-title-configurations":
            path = "/api/v2/patch-software-title-configurations/\(destEpId)"
            contentType = "application/merge-patch+json"
            accept      = "application/json"
            let patchPackages = apiData["packages"]
            
            let jsonPayload = ["softwareTitleId": "\(destEpId)", "packages": patchPackages]
            print("[createUpdate] jsonPayload: \(jsonPayload)")
            do {
                requestBody = try JSONSerialization.data(withJSONObject: jsonPayload, options: .prettyPrinted)
                print("[createUpdate] requestBody: \(String(data: requestBody, encoding: .utf8) ?? "unable to decode")")
            } catch let error {
                print(error.localizedDescription)
                completion([:])
                return
            }
        case "policy-details":
            print("[createUpdate] policy-details")
            path = (method.uppercased() == "POST") ? "/JSSResource/patchpolicies/softwaretitleconfig/id/\(destEpId)":"/JSSResource/patchpolicies/id/\(destEpId)"
            contentType = "text/xml"
            accept      = "text/xml"
            
        default:
            path = "v2/\(endpoint)"
        }

        var urlString = "\(serverUrl)/\(path)"
        urlString     = urlString.replacingOccurrences(of: "//api", with: "/api")
        urlString     = urlString.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
//        if id != "" && id != "0" {
//            urlString = urlString + "/\(id)"
//        }
        print("[createUpdate] urlString: \(urlString)")
        
        let url            = URL(string: "\(urlString)")
        let configuration  = URLSessionConfiguration.default
        var request        = URLRequest(url: url!)
        switch createUpdateMethod.uppercased() {
        case "CREATE":
            request.httpMethod = "POST"
        default:
            request.httpMethod = createUpdateMethod.uppercased()
        }
        
        /* move this
        if apiData.count > 0 {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: apiData, options: .prettyPrinted)
            } catch let error {
                print(error.localizedDescription)
            }
        }
         */
        request.httpBody = requestBody
        
        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[Jpapi.action] Attempting \(method) on \(urlString).") }
//        print("[Jpapi.action] Attempting \(method) on \(urlString).")
        
        configuration.httpAdditionalHeaders = ["Authorization" : "Bearer \(token)", "Content-Type" : contentType, "Accept" : accept, "User-Agent" : AppInfo.userAgentHeader]
//        print("[createUpdate] headers: \(configuration.httpAdditionalHeaders ?? [:])")
        
//        print("jpapi sticky session for \(serverUrl)")
        // sticky session
        if JamfProServer.sessionCookie.count > 0 && JamfProServer.stickySession {
            URLSession.shared.configuration.httpCookieStorage!.setCookies(JamfProServer.sessionCookie, for: URL(string: serverUrl), mainDocumentURL: URL(string: serverUrl))
        }
        
        let session = Foundation.URLSession(configuration: configuration, delegate: self as URLSessionDelegate, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request as URLRequest, completionHandler: { [self]
            (data, response, error) -> Void in
            session.finishTasksAndInvalidate()
            if let httpResponse = response as? HTTPURLResponse {
//                print("[createUpdate] httpResponse: \(httpResponse)")
                if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
                    
                    if endpoint == "patchmanagement" {
                        if let stringResponse = String(data: data!, encoding: .utf8) {
                            print("[createUpdate] patchmanagement stringResponse: \(stringResponse)")
                            let newId = (createUpdateMethod.uppercased() == "PATCH") ? tagValue2(xmlString: stringResponse, startTag: "<id>", endTag: "</id>"):tagValue2(xmlString: stringResponse, startTag: "\"id\" : \"", endTag: "\",")
                            if !newId.isEmpty || createUpdateMethod.uppercased() == "PATCH" {
                                // patch-software-title-configurations
                                print("[createUpdate] patch-software-title-configurations")
                                createUpdate(serverUrl: serverUrl, endpoint: "patch-software-title-configurations", apiData: apiData, sourceEpId: sourceEpId, destEpId: "\(newId)", token: JamfProServer.authCreds["dest"]!, method: "PATCH") {
                                    (jpapiResonse: [String:Any]) in
                                    print("[createUpdate] resulst of patch-software-title-configurations: \(jpapiResonse)")
                                    
                                }
                            }
                        }
                        return
                    }
                    
                    if endpoint == "patch-software-title-configurations" {
                        
                        // add patch policies
                        print("patch policies count: \(PatchPoliciesDetails.source.count)")
                        let patchPolicies = PatchPoliciesDetails.source.filter( {$0.softwareTitleConfigurationId == sourceEpId} )
                        print("patchPolicies count: \(patchPolicies.count)")
                        print("")
                        
                        do {
                            let jsonData = try JSONDecoder().decode(PatchSoftwareTitleConfiguration.self, from: data!)
                        } catch {
                            print("[createUpdate] failed to decode new patch-software-title-configuration")
                        }
                        if let stringResponse = String(data: data!, encoding: .utf8) {
                            print("[createUpdate] patch-software-title-configuration stringResponse: \(stringResponse)")
                        }
                        
                    }
                    
                    let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                    if let endpointJSON = json as? [String:Any] {
                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[Jpapi.action] Data retrieved from \(urlString).") }
                        completion(endpointJSON)
                        return
                    } else {    // if let endpointJSON error
                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[Jpapi.action] JSON error.  Returned data: \(String(describing: json))") }
                        completion(["JPAPI_result":"failed", "JPAPI_response":httpResponse.statusCode])
                        return
                    }
                } else {    // if httpResponse.statusCode <200 or >299
                    if let stringResponse = String(data: data!, encoding: .utf8) {
                        print("[createUpdate] \(endpoint) status code: \(httpResponse.statusCode)")
                        print("[createUpdate] \(endpoint) stringResponse: \(stringResponse)")
                    }
                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[Jpapi.action] Response error: \(httpResponse.statusCode).") }
                    completion(["JPAPI_result":"failed", "JPAPI_method":request.httpMethod ?? method, "JPAPI_response":httpResponse.statusCode, "JPAPI_server":urlString, "JPAPI_token":token])
                    return
                }
            } else {
                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[Jpapi.action] GET response error.  Verify url and port.") }
                completion([:])
                return
            }
        })
        task.resume()
    }   // func action - end
    
    private func createPatchsoftwaretitleXml(objectInstance: PatchSoftwareTitleConfiguration) -> String {
        
//        let categoryName = Categories.destination.filter { $0.id == objectInstance.categoryId }.first?.name ?? ""
        let patchSourceId = PatchSource.destination.filter { $0.name == objectInstance.patchSourceName }.first?.id ?? 0

        let patchSoftwareTitle = """
                <patch_software_title>
                    <name>\(objectInstance.displayName)</name>
                    <name_id>\(objectInstance.softwareTitleNameId)</name_id>
                    <source_id>\(patchSourceId)</source_id>
                    <site>
                        <id>\(objectInstance.siteId)</id>
                    </site>
                    <notifications>
                        <web_notification>\(objectInstance.uiNotifications)</web_notification>
                        <email_notification>\(objectInstance.emailNotifications)</email_notification>
                    </notifications>
                    <categories>
                        <id>\(objectInstance.categoryId)</id>
                    </categories>
                </patch_software_title>
                """
        return patchSoftwareTitle
    }
    
    private func createUpdatePatchPolicy() {
        
    }
    
    private func objectId(xml: String, object: String) -> String {
        let trimmed = tagValue(xmlString: xml, xmlTag: object)
        return tagValue(xmlString: trimmed, xmlTag: "id")
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
}
