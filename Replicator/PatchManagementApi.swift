//
//  Jpapi.swift
//  Replicator
//
//  Created by Leslie Helou on 12/17/19.
//  Copyright 2024 Jamf. All rights reserved.
//

import Cocoa

class PatchManagementApi: NSObject, URLSessionDelegate {
    
    static let shared = PatchManagementApi()
    var updateUiDelegate: UpdateUiDelegate?
    
    func createUpdate(serverUrl: String, endpoint: String = "patch-software-title-configurations", apiData: [String: Any], sourceEpId: String, destEpId: String, token: String, method: String, completion: @escaping (_ returnedJSON: [String: Any]) -> Void) {
        
        if method.lowercased() == "skip" {
            completion(["JPAPI_result":"no valid token found", "JPAPI_response":0])
            return
        }
        
        var createUpdateMethod = method
        var contentType = ""
        var accept      = ""
        var objectInstance: PatchSoftwareTitleConfiguration?
                
        print("\n[PatchManagementApi.createUpdate] apiData: \(apiData)\n")
        
        let objectData = try? JSONSerialization.data(withJSONObject: apiData, options: [])
        

        if method.lowercased() == "skip" {
            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[PatchManagementApi.createUpdate] skipping \(endpoint) endpoint with id \(destEpId).") }
            let JPAPI_result = (endpoint == "auth/invalidate-token") ? "no valid token":"failed"
            completion(["JPAPI_result":JPAPI_result, "JPAPI_response":000])
            return
        }
        
        URLCache.shared.removeAllCachedResponses()
        var path = ""
        var requestBody = Data()

        print("[PatchManagementApi.action] endpoint: \(endpoint)")
        
        do {
            let decoder = JSONDecoder()
            objectInstance = try decoder.decode(PatchSoftwareTitleConfiguration.self, from: objectData!)
        } catch {
            print("[PatchManagementApi.createUpdate] JSON decode error: \(error)")
            completion(["JPAPI_result":"failed", "JPAPI_response":000])
            return
        }
        
        switch endpoint {
        case  "patch-software-title-configurations":
            print("[PatchManagementApi.createUpdate] patch title: \(objectInstance?.displayName ?? "unknown")")
            print("[PatchManagementApi.createUpdate] patch category id: \(objectInstance?.categoryId ?? "unknown")")
            print("[PatchManagementApi.createUpdate] patch category name: \(objectInstance?.categoryName ?? "unknown")")
            print("[PatchManagementApi.createUpdate] patch site id: \(objectInstance?.siteId ?? "unknown")")
            print("[PatchManagementApi.createUpdate] patch site name: \(objectInstance?.siteName ?? "unknown")")
            let patchTitle = createPatchsoftwaretitleXml(objectInstance: objectInstance!)
//            print("name_id: \(tagValue(xmlString: patchTitle, xmlTag: "name_id"))")
            let siteId = objectId(xml: patchTitle, object: "site")
            let sourceTitle = PatchTitleConfigurations.source.filter( { $0.id == sourceEpId } ).first
            let sourceSiteName = sourceTitle?.siteName ?? "NONE"
            let destTitle = PatchTitleConfigurations.destination.filter( { ($0.softwareTitleNameId == "\(tagValue(xmlString: patchTitle, xmlTag: "name_id"))") && ($0.siteName == sourceSiteName) } ).first
            let destSiteName = destTitle?.siteName ?? "NONE"
            print("[PatchManagementApi.createUpdate] patch destination display name: \(destTitle?.displayName ?? "unknown")")
            print("[PatchManagementApi.createUpdate] patch destination softwareTitleNameId: \(destTitle?.softwareTitleNameId ?? "unknown")")
            print("[PatchManagementApi.createUpdate] patch destination site: \(destTitle?.siteName ?? "unknown")")
            
            let sourceCategoryName = sourceTitle?.categoryName
            print("[PatchManagementApi.createUpdate] source category: \(sourceCategoryName ?? "NONE")")
            let destCategoryId = objectInstance?.categoryId /*Categories.destination.first(where: {$0.name == sourceCategoryName})?.id ?? nil*/
            print("[PatchManagementApi.createUpdate] dest category id: \(destCategoryId ?? "")")
            //print("dest config name: \(destTitle?.displayName ?? "unknown")")
            //print("source site name: \(sourceTitle?.siteName ?? "NONE")")
            //print("  dest site name: \(destTitle?.siteName ?? "NONE")")
            if ((destTitle?.displayName) != nil && (sourceSiteName == destSiteName)) {
                createUpdateMethod = "PATCH"
                path = "/api/v2/patch-software-title-configurations/\(destTitle?.id ?? "0")"
                contentType = "application/merge-patch+json"
                accept      = "application/json"
                let _Title = objectInstance /*PatchTitleConfigurations.source.filter( { $0.id == sourceEpId } ).first*/
                if let jamfOfficial = destTitle?.jamfOfficial,
                   let displayName = _Title?.displayName,
                   let categoryId = destCategoryId,
//                   let siteId = _Title?.siteId,
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
                          "categoryId": categoryId,
                          "siteId": siteId,  //objectId(xml: patchTitle, object: "site"),
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
                        print("[PatchManagementApi.createUpdate] putTitle: \(String(data: requestBody, encoding: .utf8) ?? "unable to decode")")
                    } catch let error {
                        print("[PatchManagementApi.createUpdate] requestBody: unable to decode")
                        print(error.localizedDescription)
                        completion([:])
                        return
                    }
                } else {
                    print("[PatchManagementApi.createUpdate] requestBody: \(String(data: requestBody, encoding: .utf8) ?? "unable to decode")")
//                    print("[PatchManagementApi.createUpdate] unable to set data for put")
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

            print("[PatchManagementApi.createUpdate] api action: \(createUpdateMethod) on patchTitle: \(patchTitle)")
        case "patch-software-title-packages":
            path = "/api/v2/patch-software-title-configurations/\(destEpId)"
            contentType = "application/merge-patch+json"
            accept      = "application/json"
            let patchPackages = apiData["packages"]
            
            let jsonPayload = ["softwareTitleId": "\(destEpId)", "packages": patchPackages]
            print("[PatchManagementApi.createUpdate] jsonPayload: \(jsonPayload)")
            do {
                requestBody = try JSONSerialization.data(withJSONObject: jsonPayload, options: .prettyPrinted)
                print("[PatchManagementApi.createUpdate] requestBody: \(String(data: requestBody, encoding: .utf8) ?? "unable to decode")")
            } catch let error {
                print(error.localizedDescription)
                completion([:])
                return
            }
            // unused? -> CreateEndpoints capi
//        case "policy-details":
//            print("\n\n[PatchManagementApi.createUpdate] policy-details\n\n")
//            path = (method.uppercased() == "POST") ? "/JSSResource/patchpolicies/softwaretitleconfig/id/\(destEpId)":"/JSSResource/patchpolicies/id/\(destEpId)"
//            contentType = "text/xml"
//            accept      = "text/xml"
            
        default:
            path = "v2/\(endpoint)"
        }

        var urlString = "\(serverUrl)/\(path)"
        urlString     = urlString.replacingOccurrences(of: "//api", with: "/api")
        urlString     = urlString.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
//        if id != "" && id != "0" {
//            urlString = urlString + "/\(id)"
//        }
        
        let url            = URL(string: "\(urlString)")
        let configuration  = URLSessionConfiguration.default
        var request        = URLRequest(url: url!)
        switch createUpdateMethod.uppercased() {
        case "CREATE":
            request.httpMethod = "POST"
        default:
            request.httpMethod = createUpdateMethod.uppercased()
        }
        print("[PatchManagementApi.createUpdate] \(request.httpMethod ?? "unknown") on urlString: \(urlString)")
        
        request.httpBody = requestBody
        
        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[PatchManagementApi.createUpdate] Attempting \(method) on \(urlString).") }
//        print("[PatchManagementApi.createUpdate] Attempting \(method) on \(urlString).")
        
        configuration.httpAdditionalHeaders = ["Authorization" : "Bearer \(token)", "Content-Type" : contentType, "Accept" : accept, "User-Agent" : AppInfo.userAgentHeader]
        
        var headers = [String: String]()
        for (header, value) in configuration.httpAdditionalHeaders ?? [:] {
            headers[header as! String] = (header as! String == "Authorization") ? "Bearer ************" : value as? String
        }
        print("[apiCall] \(#function.description) method: \(request.httpMethod ?? "")")
        print("[apiCall] \(#function.description) headers: \(headers)")
        print("[apiCall] \(#function.description) endpoint: \(url?.absoluteString ?? "")")
        print("[apiCall]")

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
//                print("[PatchManagementApi.createUpdate] httpResponse: \(httpResponse)")
                if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
                    let method = createUpdateMethod.lowercased() == "patch" ? "update" : "create"
                    
                    Counter.shared.crud[endpoint]?[method]! += 1
                    Summary.totalCreated   = Counter.shared.crud[endpoint]?["create"] ?? 0
                    Summary.totalUpdated   = Counter.shared.crud[endpoint]?["update"] ?? 0
                    Summary.totalFailed    = Counter.shared.crud[endpoint]?["fail"] ?? 0
                    Summary.totalCompleted = Summary.totalCreated + Summary.totalUpdated + Summary.totalFailed
                    
                    if endpoint == "patch-software-title-configurations" {
                        if Summary.totalCompleted > 0 {
                            updateUiDelegate?.updateUi(info: ["function": "putStatusUpdate2", "endpoint": endpoint, "total": Counter.shared.crud[endpoint]!["total"] as Any])
                        }
                        
                        if let stringResponse = String(data: data!, encoding: .utf8) {
                            print("[PatchManagementApi.createUpdate] patchmanagement stringResponse: \(stringResponse)")
                            let newId = (createUpdateMethod.uppercased() == "PATCH") ? tagValue2(xmlString: stringResponse, startTag: "\"id\" : \"", endTag: "\","):tagValue2(xmlString: stringResponse, startTag: "<id>", endTag: "</id>")
                            if !newId.isEmpty || createUpdateMethod.uppercased() == "PATCH" {
                                // patch-software-title-configurations - handle packages
                                print("[PatchManagementApi.createUpdate] patch-software-title-configurations - add packages")
                                createUpdate(serverUrl: serverUrl, endpoint: "patch-software-title-packages", apiData: apiData, sourceEpId: sourceEpId, destEpId: "\(newId)", token: JamfProServer.authCreds["dest"]!, method: "PATCH") {
                                    (jpapiResonse: [String:Any]) in
                                    print("[PatchManagementApi.createUpdate] result of patch-software-title-packages: \(jpapiResonse)")
                                    
                                }
                            }
                        }
                        return
                    }
                    
                    if endpoint == "patch-software-title-packages" {
                        
                        // add patch policies
                        print("patch policies count: \(PatchPoliciesDetails.source.count)")
                        let patchPolicies = PatchPoliciesDetails.source.filter( {$0.softwareTitleConfigurationId == sourceEpId} )
                        print("patchPolicies count: \(patchPolicies.count)")
                        
                        let existingPatchPolicies = PatchPoliciesDetails.destination.filter( {$0.softwareTitleConfigurationId == destEpId} )
                        print("software title (id: \(destEpId)) has existing patch policies count: \(existingPatchPolicies.count)")
                        for patchPolicy in patchPolicies {
//                            let patchPolicyId = patchPolicy.id
                            print("patch version: \(patchPolicy.targetPatchVersion)")
                            let patchExists = existingPatchPolicies.filter( {$0.targetPatchVersion == patchPolicy.targetPatchVersion} ).count > 0
                            var apiAction = "create"
                            var objectId = destEpId
                            if patchExists {
                                apiAction = "update"
                                objectId = existingPatchPolicies.filter( {$0.targetPatchVersion == patchPolicy.targetPatchVersion} ).first!.id
                            }
                            // need to query capi to get full patch policy config
                            Jpapi.shared.action(whichServer: "source", endpoint: "patchpolicies", apiData: [:], id: patchPolicy.id, token: JamfProServer.authCreds["source"] ?? "", method: "GET") {
                                (returnedJson: [String:Any]) in
//                                    print("patch policy Dictionary: \(returnedJson.description)")
                                
                                var objectXml = returnedJson["objectXml"] as? String ?? ""
                                print("\nadd patch policy to software title id: \(destEpId)")
                                print("patch policy XML: \(objectXml.prettyPrint)")
                                

                                if let titleId = Int(destEpId), !objectXml.isEmpty {
                                    // remove id from xml
                                    
//                                    let idPattern = "\(NSRegularExpression.escapedPattern(for: "<id>")).*?\(NSRegularExpression.escapedPattern(for: "</id>"))"
                                    do {
//                                        let regex = try NSRegularExpression(pattern: idPattern, options: [])
                                        let regex = try NSRegularExpression(pattern: "<id>(.*?)</id>", options:.caseInsensitive)
                                        
                                        // remove id
                                        let range = NSRange(objectXml.startIndex..<objectXml.endIndex, in: objectXml)
                                        objectXml = regex.stringByReplacingMatches(in: objectXml, options: [], range: range, withTemplate: "")
                                        objectXml = objectXml.replacingOccurrences(of: "\n\n", with: "\n")
                                        
                                    } catch {
                                        print("Invalid regex: \(error.localizedDescription)")
                                    }
//                                    let titlePattern = "\(NSRegularExpression.escapedPattern(for: "<software_title_configuration_id>")).*?\(NSRegularExpression.escapedPattern(for: "</software_title_configuration_id>"))"
                                    do {
//                                        let regex = try NSRegularExpression(pattern: titlePattern, options: [])
                                        let regex = try NSRegularExpression(pattern: "<software_title_configuration_id>(.*?)</software_title_configuration_id>", options:.caseInsensitive)
                                        
                                        // update software_title_configuration_id to id on destination server
                                        let range = NSRange(objectXml.startIndex..<objectXml.endIndex, in: objectXml)
                                        objectXml = regex.stringByReplacingMatches(in: objectXml, options: [], range: range, withTemplate: "<software_title_configuration_id>\(titleId)</software_title_configuration_id>")

                                        
                                    } catch {
                                        print("Invalid regex: \(error.localizedDescription)")
                                    }
                                    objectXml = objectXml.prettyPrint
                                    print("updated patch policy XML: \(objectXml)")
                                    CreateEndpoints.shared.queue(endpointType: "patchpolicies", endPointXML: objectXml, endpointCurrent: 0, endpointCount: patchPolicies.count, action: apiAction, sourceEpId: -1, destEpId: objectId, ssIconName: "", ssIconId: "", ssIconUri: "", retry: false) {
                                        (result: String) in
                                    }
                                }
                                
                            }
                        }
                        print("")
                        
                        do {
//                            let jsonData = try JSONDecoder().decode(PatchSoftwareTitleConfiguration.self, from: data!)
                            let _ = try JSONDecoder().decode(PatchSoftwareTitleConfiguration.self, from: data!)
                        } catch {
                            print("[PatchManagementApi.createUpdate] failed to decode new patch-software-title-configuration")
                        }
                        if let stringResponse = String(data: data!, encoding: .utf8) {
                            print("[PatchManagementApi.createUpdate] patch-software-title-configuration stringResponse: \(stringResponse)")
                        }
                        
                    }
                    
                    let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                    if let endpointJSON = json as? [String:Any] {
                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[PatchManagementApi.createUpdate] Data retrieved from \(urlString).") }
                        completion(endpointJSON)
                        return
                    } else {    // if let endpointJSON error
                        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[PatchManagementApi.createUpdate] JSON error.  Returned data: \(String(describing: json))") }
                        completion(["JPAPI_result":"failed", "JPAPI_response":httpResponse.statusCode])
                        return
                    }
                } else {    // if httpResponse.statusCode <200 or >299
                    if let stringResponse = String(data: data!, encoding: .utf8) {
                        print("[PatchManagementApi.createUpdate] \(endpoint) status code: \(httpResponse.statusCode)")
                        print("[PatchManagementApi.createUpdate] \(endpoint) stringResponse: \(stringResponse)")
                    }
                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[PatchManagementApi.createUpdate] Response error: \(httpResponse.statusCode).") }
                    completion(["JPAPI_result":"failed", "JPAPI_method":request.httpMethod ?? method, "JPAPI_response":httpResponse.statusCode, "JPAPI_server":urlString, "JPAPI_token":token])
                    return
                }
            } else {
                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[PatchManagementApi.createUpdate] GET response error.  Verify url and port.") }
                completion([:])
                return
            }
        })
        task.resume()
    }   // func action - end
    
    private func createPatchsoftwaretitleXml(objectInstance: PatchSoftwareTitleConfiguration) -> String {
        
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
                    <category>
                        <id>\(objectInstance.categoryId)</id>
                    </category>
                </patch_software_title>
                """
        print("[PatchManagementApi] createPatchsoftwaretitleXml: \(patchSoftwareTitle)")
        return patchSoftwareTitle
    }
    
    /*
    private func createPatchPolicyXml(from dictionary: [String: Any]) -> XMLElement {
        let root = XMLElement(name: "patch_policy")
        for (key, value) in dictionary {
            let element = XMLElement(name: key)
            if let nestedDictionary = value as? [String: Any] {
                element.addChild(createPatchPolicyXml(from: nestedDictionary))
            } else if let array = value as? [Any] {
                for item in array {
                    if let nestedDictionary = item as? [String: Any] {
                        element.addChild(createPatchPolicyXml(from:nestedDictionary))
                    } else {
                        let itemElement = XMLElement(name: "item", stringValue: "\(item)")
                        element.addChild(itemElement)
                    }
                }
            } else {
                element.stringValue = "\(value)"
            }
            root.addChild(element)
        }
        return root
    }
    */
    
    private func objectId(xml: String, object: String) -> String {
        let trimmed = tagValue(xmlString: xml, xmlTag: object)
        return tagValue(xmlString: trimmed, xmlTag: "id")
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
}
