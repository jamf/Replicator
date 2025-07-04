//
//  Jpapi.swift
//  Replicator
//
//  Created by Leslie Helou on 12/17/19.
//  Copyright 2024 Jamf. All rights reserved.
//

import Cocoa

class ExistingObject: NSObject {
    var type: String
    var id: Int
    var name: String
    var fileName: String?
    
    init(type: String, id: Int, name: String, fileName: String? = nil) {
        self.type = type
        self.id = id
        self.name = name
        self.fileName = fileName
    }
}

var existingObjects = [ExistingObject]()

class Jpapi: NSObject, URLSessionDelegate {
    
    static let shared = Jpapi()
    
    var updateUiDelegate: UpdateUiDelegate?
    func updateView(_ info: [String: Any]) {
        logFunctionCall()
        updateUiDelegate?.updateUi(info: info)
    }
    
    var rolePrivileges = [String]()
    
    func action(whichServer: String, endpoint: String, apiData: [String: Any], id: String, token: String, method: String, completion: @escaping (_ returnedJSON: [String: Any]) -> Void) {
        logFunctionCall()
        
        if method.lowercased() == "skip" {
            if LogLevel.debug { WriteToLog.shared.message("[Jpapi.action] skipping \(endpoint) endpoint with id \(id).") }
            let JPAPI_result = (endpoint == "auth/invalidate-token") ? "no valid token":"failed"
            completion(["JPAPI_result":JPAPI_result, "JPAPI_response":000])
            return
        }
        
        if whichServer == "source" && ["api-roles", "api-integrations"].contains(endpoint) {
            var returnedJSON: [String: Any] = [:]
            switch endpoint {
            case "api-roles":
                if let theObject = ApiRoles.source.first(where: { $0.id == id }) {
                    do {
                        let objectData = try JSONEncoder().encode(theObject)
                        if let objectJson = try JSONSerialization.jsonObject(with: objectData, options: []) as? [String: Any] {
                            returnedJSON = objectJson
                        }
                    } catch {
    //                        completion([:])
                    }
                }
            case "api-integrations":
                if let theObject = ApiIntegrations.source.first(where: { $0.id == id }) {
                    do {
                        let objectData = try JSONEncoder().encode(theObject)
                        if let objectJson = try JSONSerialization.jsonObject(with: objectData, options: []) as? [String: Any] {
                            returnedJSON = objectJson
                        }
                    } catch {
    //                        completion([:])
                    }
                }
            default:
                break
            }
            
            completion(returnedJSON)
            return
        }
        
        let serverUrl = (whichServer == "source") ? JamfProServer.source:JamfProServer.destination
                
        // cookie stuff
        var sessionCookie: HTTPCookie?
        var cookieName         = "" // name of cookie to look for
        
        URLCache.shared.removeAllCachedResponses()
        var path = ""
        var contentType: String = "application/json"
        var accept: String      = "application/json"

        print("[Jpapi.action] endpoint: \(endpoint)")
        switch endpoint {
        case  "buildings", "csa/token", "icon", "jamf-pro-version", "auth/invalidate-token", "sites", "api-roles", "api-integrations":
            path = "api/v1/\(endpoint)"
        case "patchinternalsources":
            path = "JSSResource/patchinternalsources"
        case "patchpolicies":
            path        = "JSSResource/patchpolicies"
            contentType = "text/xml"
            accept      = "text/xml"
        default:
            path = "api/v2/\(endpoint)"
        }

        var urlString = "\(serverUrl)/\(path)"
        urlString     = urlString.replacingOccurrences(of: "//api", with: "/api")
        urlString     = urlString.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
        if id != "" && id != "0" {
            urlString = (urlString.contains("/api/")) ? urlString + "/\(id)":urlString + "/id/\(id)"
        }
        print("[Jpaapi.action] \(endpoint) id \(id)")
        
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
        print("[Jpaapi.action] Perform \(request.httpMethod ?? "") on urlString: \(urlString)")
        
        if apiData.count > 0 {
            do {
                switch endpoint {
                case "api-integrations":
                    var trimmedJson = apiData
                    trimmedJson["clientId"] = nil
                    trimmedJson["appType"] = nil
                    request.httpBody = try JSONSerialization.data(withJSONObject: trimmedJson, options: .prettyPrinted)
                default:
                    request.httpBody = try JSONSerialization.data(withJSONObject: apiData, options: .prettyPrinted)
                }
            } catch let error {
                if LogLevel.debug { WriteToLog.shared.message("[Jpapi.action] error constructing httpBody to upload: \(error.localizedDescription)") }
            }
        }
        
        if LogLevel.debug { WriteToLog.shared.message("[Jpapi.action] attempting \(method) on \(urlString)") }
        
        configuration.httpAdditionalHeaders = ["Authorization" : "Bearer \(JamfProServer.accessToken[whichServer] ?? "")", "Content-Type" : contentType, "Accept" : accept, "User-Agent" : AppInfo.userAgentHeader]
        
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
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) -> Void in
            session.finishTasksAndInvalidate()
            
            let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
//            print("[Jpaapi.action] Api response for \(endpoint): \(String(data: data ?? Data(), encoding: .utf8))")

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
                            WriteToLog.shared.message("[Jpapi.action] set cookie (name:value) \(String(describing: cookieName)):\(String(describing: sessionCookie!.value)) for \(String(describing: sessionCookie!.domain))")
                            JamfProServer.sessionCookie.append(sessionCookie!)
                        } else {
                            HTTPCookieStorage.shared.removeCookies(since: History.startTime)
                        }
                    }
                    
                    if accept == "text/xml" {
                        let objectXml = String(data: data ?? Data(), encoding: .utf8) ?? ""
                        completion(["objectXml": objectXml])
                        return
                    }
                    
//                    let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                    if endpoint == "sites" {
                        if let allSites = json as? [[String: Any]] {
                            if LogLevel.debug { WriteToLog.shared.message("[Jpapi.action] Data retrieved from \(urlString).") }
                            completion(["sites":allSites])
                            return
                        } else {
                            completion(["JPAPI_result":"sites failed", "JPAPI_response":httpResponse.statusCode])
                            return
                        }
                    }
                    if let endpointJSON = json as? [String: Any] {
                        if LogLevel.debug { WriteToLog.shared.message("[Jpapi.action] Data retrieved from \(urlString).") }
                        completion(endpointJSON)
                        return
                    } else {    // if let endpointJSON error
                        if httpResponse.statusCode == 204 && endpoint == "auth/invalidate-token" {
                            completion(["JPAPI_result":"token terminated", "JPAPI_response":httpResponse.statusCode])
                        } else {
                            if LogLevel.debug { WriteToLog.shared.message("[Jpapi.action] JSON error.  Returned data: \(String(describing: json))") }
                            completion(["JPAPI_result":"failed", "JPAPI_response":httpResponse.statusCode])
                        }
                        return
                    }
                } else {    // if httpResponse.statusCode <200 or >299
                    WriteToLog.shared.message("[Jpapi.action] Response error: \(httpResponse.statusCode)")
                    if endpoint == "sites" {
                        completion(["sites":[]])
                    } else {
                        if let endpointJSON = json as? [String: Any], let errors = endpointJSON["errors"] as? [Any] {
                            WriteToLog.shared.message("[Jpapi.action] error: \(errors.description)")
                        }
                        completion(["JPAPI_result":"failed", "JPAPI_method":request.httpMethod ?? method, "JPAPI_response":httpResponse.statusCode, "JPAPI_server":urlString, "JPAPI_token":token])
                    }
                    return
                }
            } else {
                if LogLevel.debug { WriteToLog.shared.message("[Jpapi.action] GET response error.  Verify url and port.") }
                completion([:])
                return
            }
        })
        task.resume()
    }   // func action - end
    
    func getAllDelegate(whichServer: String, theEndpoint: String, whichPage: Int, lastPage: Bool = false, completion: @escaping (_ result: [Any]) -> Void) {
        logFunctionCall()
        
        print("[getAllDelegate] lastPage: \(lastPage), whichPage: \(whichPage), whichServer: \(whichServer) server, theEndpoint: \(theEndpoint).")
        if !lastPage {
            getAll(whichServer: whichServer, theEndpoint: theEndpoint, whichPage: whichPage) { [self]
                returnedResults in
                if theEndpoint == "packages" {
                    if duplicatePackages {
                        print("[getAllDelegate] duplicate packages found on \(whichServer) server.")
                        
                            var message = "\tFilename : Display Name\n"
                            for (pkgFilename, displayNames) in duplicatePackagesDict {
                                if displayNames.count > 1 {
                                    for dup in displayNames {
                                        message = "\(message)\t\(pkgFilename) : \(dup)\n"
                                    }
                                }
                            }
                        let theServer = (whichServer == "source") ? JamfProServer.source : JamfProServer.destination
                        WriteToLog.shared.message("[ViewController.getEndpoints] Duplicate references to the same package were found on \(theServer)\n\(message)")
                            if Setting.fullGUI {
                                let theButton = Alert.shared.display(header: "Warning:", message: "Several packages on \(theServer), having unique display names, are linked to a single file.  Check the log for 'Duplicate references to the same package' for details.", secondButton: "Stop")
                                if theButton == "Stop" {
                                    updateView(["function": "stopButton"])
//                                    stopButton(self)
                                }
                            }
                    }
                    duplicatePackages = false
                    duplicatePackagesDict.removeAll()
                }
                completion(returnedResults)
            }
        }
    }
    
    func getAll(whichServer: String, theEndpoint: String, whichPage: Int, completion: @escaping (_ result: [Any]) -> Void) {
        logFunctionCall()
        
        switch theEndpoint {
        case "categories", "policy-details", "packages", "sites", "api-roles", "api-integrations":
            print("[getAll] look for \(theEndpoint)")
            DispatchQueue.global(qos: .background).async { [self] in
                
                pagedGet(whichServer: whichServer, theEndpoint: theEndpoint, whichPage: whichPage) { [self]
                    returnedResults in
//                    pendingCalls -= 1
                    let returnedJson = returnedResults as? [String: Any] ?? [:]
//                    print("[getAll] pending calls: \(pendingCalls)")
                    let totalRecords = returnedJson["totalCount"] as? Int ?? 0
                    let pages = (totalRecords + (pageSize - 1)) / pageSize
                    
                    if let returnedRecords = returnedJson["results"] as? [[String: Any]], returnedRecords.count > 0 {
//                        print("[getAll] returnedRecords: \(returnedRecords)")
                        switch theEndpoint {
                        case "api-roles", "api-integrations":
                            var havePrivileges: Bool = false
                            for theObject in returnedRecords {
                                let id = "\(theObject["id"] ?? "0")"
                                
                                if let name = theObject["displayName"] as? String, name != "", id != "0" {
                                    
                                    if whichServer == "source" || WipeData.state.on {
                                        if theEndpoint == "api-roles" {
                                            ApiRoles.source.append(ApiRole(id: id, displayName: name, privileges: theObject["privileges"] as? [String] ?? []))
                                        } else {
                                            ApiIntegrations.source.append(ApiIntegration(id: id, displayName: name, enabled: theObject["enabled"] as? Bool ?? false,accessTokenLifetimeSeconds: theObject["accessTokenLifetimeSeconds"] as? Int ?? 0,appType: theObject["appType"] as? String ?? "", clientId: theObject["clientId"] as? String ?? "", authorizationScopes: theObject["authorizationScopes"] as? [String] ?? []))
                                        }
                                    } else {
                                        if theEndpoint == "api-roles" {
                                            // gets role-privileges on first object call
                                            get(whichServer: whichServer, theEndpoint: "api-role-privileges", skip: havePrivileges) {
                                                (privileges) in
                                                if privileges.count > 0, let privilegesDict = privileges[0] as? [String: Any], let privilegesArray = privilegesDict["privileges"] as? [String]  {
                                                    self.rolePrivileges = privilegesArray
//                                                    print("[Jpapi.getAll] role-privileges: \(self.rolePrivileges)")
                                                }
                                                ApiRoles.destination.append(ApiRole(id: id, displayName: name, privileges: theObject["privileges"] as? [String] ?? []))
                                            }
                                            havePrivileges = true
                                        } else {
                                            ApiIntegrations.destination.append(ApiIntegration(id: id, displayName: name, enabled: theObject["enabled"] as? Bool ?? false,accessTokenLifetimeSeconds: theObject["accessTokenLifetimeSeconds"] as? Int ?? 0,appType: theObject["appType"] as? String ?? "", clientId: theObject["clientId"] as? String ?? "", authorizationScopes: theObject["authorizationScopes"] as? [String] ?? []))
                                        }
                                    }
                                }
                            }
                            
                        case "packages":
                            do {
                                let jsonData = try JSONSerialization.data(withJSONObject: returnedRecords as Any)
                                let somePackages = try JSONDecoder().decode([JsonUapiPackageDetail].self, from: jsonData)
                                if whichServer == "source" {
//                                    print("getAll: somePackages count: \(somePackages.count)")
                                    Packages.source.append(contentsOf: somePackages)
                                    print("getAll: package count: \(Packages.source.count)")
                                    for thePackage in somePackages {
                                        if let id = thePackage.id, let idNum = Int(id), let packageName = thePackage.packageName, let fileName = thePackage.fileName {
                                            // looking for duplicates
                                            if duplicatePackagesDict[fileName] == nil {
//                                                AvailableObjsToMig.byId[idNum] = fileName
                                                duplicatePackagesDict[fileName] = [packageName]
                                            } else {
                                                duplicatePackages = true
                                                duplicatePackagesDict[fileName]!.append(packageName)
                                            }
                                            PatchPackages.source.append(PatchPackage(packageId: id, version: "", displayName: packageName, packageName: fileName))
                                            existingObjects.append(ExistingObject(type: theEndpoint, id: idNum, name: packageName, fileName: fileName))
                                        }
                                    }
                                } else {
                                    Packages.destination.append(contentsOf: somePackages)
                                    print("getAll: somePackages destination count: \(Packages.destination.count)")
                                    for thePackage in somePackages {
                                        if let id = thePackage.id, let idNum = Int(id), let packageName = thePackage.packageName, let fileName = thePackage.fileName {
                                            // looking for duplicates
                                            if duplicatePackagesDict[fileName] == nil {
                                                duplicatePackagesDict[fileName] = [packageName]
                                            } else {
                                                duplicatePackages = true
                                                duplicatePackagesDict[fileName]!.append(packageName)
                                            }
                                            PatchPackages.destination.append(PatchPackage(packageId: id, version: "", displayName: packageName, packageName: fileName))
                                            if WipeData.state.on {
                                                existingObjects.append(ExistingObject(type: theEndpoint, id: idNum, name: packageName, fileName: fileName))
                                            }
                                        }
                                    }
                                }
                            } catch {
                                print("[getAll] error decoding \(theEndpoint): \(error)")
                            }
                        default:
                            for theObject in returnedRecords {
                                switch theEndpoint {
                                case "categories":
                                    if whichServer == "source" {
                                        Categories.source.append(Category(id: theObject["id"] as? String ?? "-1", name: theObject["name"] as? String ?? "unknown category name", priority: theObject["priority"] as? Int ?? 9))
                                    } else {
                                        Categories.destination.append(Category(id: theObject["id"] as? String ?? "-1", name: theObject["name"] as? String ?? "unknown category name", priority: theObject["priority"] as? Int ?? 9))
//                                        print("[Jpapi.getAll] category id: \(theObject["id"] as? String ?? "-1"), category name: \(theObject["name"] as? String ?? "-1")")
                                    }
                                case "policy-details":
                                    if let id = theObject["id"] as? String, let name = theObject["name"] as? String, let enabled = theObject["enabled"] as? Bool, let targetPatchVersion = theObject["targetPatchVersion"] as? String, let deploymentMethod = theObject["deploymentMethod"] as? String, let softwareTitleId = theObject["softwareTitleId"] as? String, let softwareTitleConfigurationId = theObject["softwareTitleConfigurationId"] as? String, let killAppsDelayMinutes = theObject["killAppsDelayMinutes"] as? Int, let killAppsMessage = theObject["killAppsMessage"] as? String, let downgrade = theObject["downgrade"] as? Bool, let patchUnknownVersion = theObject["patchUnknownVersion"] as? Bool, let notificationHeader = theObject["notificationHeader"] as? String, let selfServiceEnforceDeadline = theObject["selfServiceEnforceDeadline"] as? Bool, let selfServiceDeadline = theObject["selfServiceDeadline"] as? Int, let installButtonText = theObject["installButtonText"] as? String, let selfServiceDescription = theObject["selfServiceDescription"] as? String, let iconId = theObject["iconId"] as? String, let reminderFrequency = theObject["reminderFrequency"] as? Int, let reminderEnabled = theObject["reminderEnabled"] as? Bool {
                                        //                                    print("[Jpapi] adding patch policy \(name) for targetPatchVersion \(targetPatchVersion) to \(whichServer) server")
                                        if whichServer == "source" {
                                            PatchPoliciesDetails.source.append(PatchPolicyDetail(id: id, name: name, enabled: enabled, targetPatchVersion: targetPatchVersion, deploymentMethod: deploymentMethod, softwareTitleId: softwareTitleId, softwareTitleConfigurationId: softwareTitleConfigurationId, killAppsDelayMinutes: killAppsDelayMinutes, killAppsMessage: killAppsMessage, downgrade: downgrade, patchUnknownVersion: patchUnknownVersion, notificationHeader: notificationHeader, selfServiceEnforceDeadline: selfServiceEnforceDeadline, selfServiceDeadline: selfServiceDeadline, installButtonText: installButtonText, selfServiceDescription: selfServiceDescription, iconId: iconId, reminderFrequency: reminderFrequency, reminderEnabled: reminderEnabled))
                                        } else {
                                            PatchPoliciesDetails.destination.append(PatchPolicyDetail(id: id, name: name, enabled: enabled, targetPatchVersion: targetPatchVersion, deploymentMethod: deploymentMethod, softwareTitleId: softwareTitleId, softwareTitleConfigurationId: softwareTitleConfigurationId, killAppsDelayMinutes: killAppsDelayMinutes, killAppsMessage: killAppsMessage, downgrade: downgrade, patchUnknownVersion: patchUnknownVersion, notificationHeader: notificationHeader, selfServiceEnforceDeadline: selfServiceEnforceDeadline, selfServiceDeadline: selfServiceDeadline, installButtonText: installButtonText, selfServiceDescription: selfServiceDescription, iconId: iconId, reminderFrequency: reminderFrequency, reminderEnabled: reminderEnabled))
                                        }
                                    }
                                case "sites":
                                    if whichServer == "source" {
                                        JamfProSites.source.append(Site(id: theObject["id"] as? String ?? "-1", name: theObject["name"] as? String ?? "unknown site name"))
                                    } else {
                                        JamfProSites.destination.append(Site(id: theObject["id"] as? String ?? "-1", name: theObject["name"] as? String ?? "unknown site name"))
                                    }
                                default:
                                    break
                                }
                            }
                        }
                        
                        print("[getAll] records (\(theEndpoint)) added: \(returnedRecords.count)")
                        WriteToLog.shared.message("[Jpapi.getAll] total records fetched \(returnedRecords.count) objects")
                    }
                    print("[getAll] page \(whichPage + 1) of \(pages) complete")
                    
                    if (whichPage + 1 >= pages ) {
                        print("[getAll] return to caller, record count: \(existingObjects.count)")
                        completion(existingObjects)
                    } else {
                        getAll(whichServer: whichServer, theEndpoint: theEndpoint, whichPage: whichPage + 1) {
                            returnedResults in
//                            print("[getAll] page \(whichPage + 1) of \(pages) complete")
//                            print("[getAll] finished fetching all \(theEndpoint)")
                            print("[getAll] call page \(whichPage + 1) for \(theEndpoint)")
                            completion(existingObjects)
                        }
                    }
                }
            }
        default:
            print("[getAll] look for \(theEndpoint) from \(whichServer)")
            // all records in one call
            get(whichServer: whichServer, theEndpoint: theEndpoint) {
                returnedJson in
//                if let returnedRecords = returnedJson as? [[String: Any]] {
                let isPolicy = theEndpoint == "policies"
                let currentCount = existingObjects.count
                for theObject in returnedJson {
                    if let id = theObject["id"] as? Int, id != 0, let name = theObject["name"] as? String, name != "" {
                        if !(isPolicy && name.range(of:"[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] at", options: .regularExpression) != nil) {
                            existingObjects.append(ExistingObject(type: theEndpoint, id: id, name: name))
//                                print("[getAll] added type: \(theEndpoint), name: \(name), id: \(id)")
                        }
                        
                    } else {
                        
                    }
                }
                print("[getAll] records returned: \(returnedJson.count)")
                print("[getAll]    records added: \(existingObjects.count - currentCount)")
//                                WriteToLog.shared.message("[Jpapi.getAll] total records fetched \(allRecords.count) objects")
//                }
                completion(existingObjects)
            }
            break
        }
    }
    
    func get(whichServer: String, theEndpoint: String, id: String = "", whichPage: Int = -1, skip: Bool = false, completion: @escaping (_ returnedJson: [[String: Any]]) -> Void) {
        logFunctionCall()
        if skip {
            completion([])
            return
        }
        var endpointVersion = ""
        switch theEndpoint {
        case "test3":
           endpointVersion = "v3"
        case "patch-software-title-configurations","patchsoftwaretitles":
           endpointVersion = "v2"
        case "categories", "packages", "jcds/files", "sites", "api-integrations", "api-roles", "api-role-privileges":
           endpointVersion = "v1"
        default:
            break
        }
        
        var endpointParent = ""
        switch theEndpoint {
        // macOS items
        case "advancedcomputersearches":
            endpointParent = "advanced_computer_searches"
        case "macapplications":
            endpointParent = "mac_applications"
        case "computerextensionattributes":
            endpointParent = "computer_extension_attributes"
        case "computergroups":
            endpointParent = "computer_groups"
        case "diskencryptionconfigurations":
            endpointParent = "disk_encryption_configurations"
        case "distributionpoints":
            endpointParent = "distribution_points"
        case "directorybindings":
            endpointParent = "directory_bindings"
        case "dockitems":
            endpointParent = "dock_items"
        case "osxconfigurationprofiles":
            endpointParent = "os_x_configuration_profiles"
        case "patches":
            endpointParent = "patch_management_software_titles"
        case "patchpolicies":
            endpointParent = "patch_policies"
        case "restrictedsoftware":
            endpointParent = "restricted_software"
        case "softwareupdateservers":
            endpointParent = "software_update_servers"
        // iOS items
        case "advancedmobiledevicesearches":
            endpointParent = "advanced_mobile_device_searches"
        case "mobiledeviceconfigurationprofiles":
            endpointParent = "configuration_profiles"
        case "mobiledeviceextensionattributes":
            endpointParent = "mobile_device_extension_attributes"
        case "mobiledevicegroups":
            endpointParent = "mobile_device_groups"
        case "mobiledeviceapplications":
            endpointParent = "mobile_device_applications"
        case "mobiledevices":
            endpointParent = "mobile_devices"
        // general items
        case "advancedusersearches":
            endpointParent = "advanced_user_searches"
        case "ldapservers":
            endpointParent = "ldap_servers"
        case "networksegments":
            endpointParent = "network_segments"
        case "userextensionattributes":
            endpointParent = "user_extension_attributes"
        case "usergroups":
            endpointParent = "user_groups"
        case "jamfusers", "jamfgroups":
            endpointParent = "accounts"
        default:
            endpointParent = "\(theEndpoint)"
        }
        
        print("[Jpapi.get] JamfProServer.url: \(JamfProServer.url)")
        var endpoint = (JamfProServer.url[whichServer] ?? "") + "/api/\(endpointVersion)/\(theEndpoint)"
        
        endpoint = endpoint.replacingOccurrences(of: "//api", with: "/api")
        print("[Jpapi.get] endpoint: \(endpoint)")
        
        guard let endpointUrl = URL(string: endpoint) else {
            completion([])
            return
        }
        
//        let endpointUrl = tmpUrl.appending(path: "/api/\(endpointVersion)/\(theEndpoint)")
        print("[Jpapi.get] endpointUrl: \(endpointUrl.path())")
//        let endpointUrl    = URL(string: "\(endpoint)")
        let configuration  = URLSessionConfiguration.ephemeral
        var request        = URLRequest(url: endpointUrl)
        request.httpMethod = "GET"
        configuration.httpAdditionalHeaders = ["Authorization" : "Bearer \(JamfProServer.accessToken[whichServer] ?? "")", "Content-Type" : "application/json", "Accept" : "application/json", "User-Agent" : AppInfo.userAgentHeader]
        
        var headers = [String: String]()
        for (header, value) in configuration.httpAdditionalHeaders ?? [:] {
            headers[header as! String] = (header as! String == "Authorization") ? "Bearer ************" : value as? String
        }
        print("[apiCall] \(#function.description) method: \(request.httpMethod ?? "")")
        print("[apiCall] \(#function.description) headers: \(headers)")
        print("[apiCall] \(#function.description) endpoint: \(endpointUrl.absoluteString)")
        print("[apiCall]")
        
        let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
        
        let semaphore = DispatchSemaphore(value: 0)
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) -> Void in
//            defer { semaphore.signal() }
            session.finishTasksAndInvalidate()
            if let httpResponse = response as? HTTPURLResponse {
                print("[Jpapi.get] response statusCode: \(httpResponse.statusCode)")
                if httpSuccess.contains(httpResponse.statusCode) {
//                    print("[Jpapi.get] data as string: \(String(data: data ?? Data(), encoding: .utf8))")
                    let responseData = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                    
                    switch theEndpoint {
                    case "patch-software-title-configurations","patchsoftwaretitles":
                        if let recordsArray = responseData as? [[String: Any]] {
//                            print("[Jpapi.get] \(theEndpoint) - found \(recordsArray.description)")
                            completion(recordsArray)
                        } else {
                            WriteToLog.shared.message("[Jpapi.get] No data was returned from the GET.")
                            completion([])
                        }
                    case "api-roles", "api-integrations":
                        if let recordsArray = responseData as? [String: Any], let results = recordsArray["results"] as? [[String: Any]] {
                            print("[Jpapi.get] \(theEndpoint) - found \(recordsArray["totalCount"] ?? "unknown")")
                            completion(results)
                        } else {
                            WriteToLog.shared.message("[Jpapi.get] No data was returned from the GET.")
                            completion([])
                        }
                    case "api-role-privileges":
                        if let priveleges = responseData as? [String: Any] {
                            print("[Jpapi.get] \(theEndpoint) - found \(priveleges.count)")
                            completion([priveleges])
                        } else {
                            WriteToLog.shared.message("[Jpapi.get] No data was returned from the GET.")
                            completion([])
                        }
                    default:
                        if let recordsJson = responseData as? [String: [[String: Any]]], let recordsArray = recordsJson[endpointParent] {
//                            print("[Jpapi.get] \(theEndpoint) - found \(recordsArray.description)")
                                completion(recordsArray)
                        } else {
                            WriteToLog.shared.message("[Jpapi.get] No data was returned from the GET.")
                            completion([])
                        }
                    }
                    
//                    if ["patch-software-title-configurations","patchsoftwaretitles"].contains(theEndpoint) {
//                        if let recordsArray = responseData as? [[String: Any]] {
////                            print("[Jpapi.get] \(theEndpoint) - found \(recordsArray.description)")
//                            completion(recordsArray)
//                        } else {
//                            WriteToLog.shared.message("[Jpapi.get] No data was returned from the GET.")
//                            completion([])
//                        }
//                    } else {
//                        if let recordsJson = responseData as? [String: [[String: Any]]], let recordsArray = recordsJson[endpointParent] {
////                            print("[Jpapi.get] \(theEndpoint) - found \(recordsArray.description)")
//                                completion(recordsArray)
//                        } else {
//                            WriteToLog.shared.message("[Jpapi.get] No data was returned from the GET.")
//                            completion([])
//                        }
//                    }
                } else {
                    WriteToLog.shared.message("[Jpapi.get] response statusCode: \(httpResponse.statusCode)")
                    completion([])
                }
            } else {
                WriteToLog.shared.message("[Jpapi.get] unable to read the response from the GET.")
                completion([])
            }
        })
        task.resume()
//        semaphore.wait()
    }
    
    
    func pagedGet(whichServer: String, theEndpoint: String, id: String = "", whichPage: Int = -1, completion: @escaping (_ returnedResults:  Any) -> Void) {
        logFunctionCall()
        if export.saveOnly && whichServer == "dest" {
            completion([:])
            return
        }
        var endpointVersion = ""
        
        switch theEndpoint {
        case "test3":
           endpointVersion = "v3"
        case "patch-software-title-configurations","patchsoftwaretitles":
           endpointVersion = "v2"
        case "policy-details":
            endpointVersion = "v2/patch-policies"
        case "categories", "packages", "sites", "api-roles", "api-integrations":
           endpointVersion = "v1"
        default:
            break
        }
        
        guard let url = URL(string: JamfProServer.url[whichServer] ?? "") else {
            completion([] as Any)
            print("[Jpapi.pagedGet] can not convert \(JamfProServer.url[whichServer] ?? "") to URL")
            return
        }
        
        var endpointUrl = url.appendingPathComponent("/api/\(endpointVersion)/\(theEndpoint)")
        if theEndpoint != "sites" {
            let pageParameters = [URLQueryItem(name: "page", value: "\(whichPage)"), URLQueryItem(name: "page-size", value: "\(pageSize)")]
            endpointUrl = endpointUrl.appending(queryItems: pageParameters)
        }

//        print("[Jpapi.getAll] whichServer: \(whichServer)")
//        print("[Jpapi.getAll] accessToken: \(JamfProServer.accessToken[whichServer] ?? "")")
        print("[Jpapi.pagedGet] endpointUrl: \(endpointUrl.absoluteString)")
        
        let configuration  = URLSessionConfiguration.ephemeral
        var request        = URLRequest(url: endpointUrl)
        request.httpMethod = "GET"
        configuration.httpAdditionalHeaders = ["Authorization" : "Bearer \(JamfProServer.accessToken[whichServer] ?? "")", "Content-Type" : "application/json", "Accept" : "application/json", "User-Agent" : AppInfo.userAgentHeader]
        
        var headers = [String: String]()
        for (header, value) in configuration.httpAdditionalHeaders ?? [:] {
            headers[header as! String] = (header as! String == "Authorization") ? "Bearer ************" : value as? String
        }
        print("[apiCall] \(#function.description) method: \(request.httpMethod ?? "")")
        print("[apiCall] \(#function.description) headers: \(headers)")
        print("[apiCall] \(#function.description) endpoint: \(endpointUrl.absoluteString)")
        print("[apiCall]")
        
        let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
        
        let semaphore = DispatchSemaphore(value: 0)
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) -> Void in
//            defer { semaphore.signal() }
            session.finishTasksAndInvalidate()
            if let httpResponse = response as? HTTPURLResponse {
                print("[Jpapi.pagedGet] response statusCode: \(httpResponse.statusCode)")
                if httpSuccess.contains(httpResponse.statusCode) {
//                    print("[Jpapi.get] data as string: \(String(data: data ?? Data(), encoding: .utf8))")
                    let responseData = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                    if let endpointJSON = responseData! as? [String: Any] {
                        completion(endpointJSON)
                        //                           print("[Jpapi.get] endpointJSON for page \(whichPage): \(endpointJSON)")
                        return
                    } else {
                        WriteToLog.shared.message("[Jpapi.pagedGet] No data was returned from the GET.")
                        completion([:])
                    }
                }
            } else {
                WriteToLog.shared.message("[Jpapi.get] unable to read the response from the GET.")
                completion([:])
            }
            semaphore.signal()
        })
        task.resume()
        semaphore.wait()
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        logFunctionCall()
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
}
