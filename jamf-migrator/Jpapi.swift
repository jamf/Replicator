//
//  Jpapi.swift
//  Jamf Transporter
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
    private override init() { }
    
//    var theUapiQ = OperationQueue() // create operation queue for API calls
    
    func action(serverUrl: String, endpoint: String, apiData: [String:Any], id: String, token: String, method: String, completion: @escaping (_ returnedJSON: [String: Any]) -> Void) {
        
        if method.lowercased() == "skip" {
            completion(["JPAPI_result":"no valid token found", "JPAPI_response":0])
            return
        }
        
        let whichServer = (serverUrl == JamfProServer.source) ? "source":"dest"
                
                // cookie stuff
                var sessionCookie: HTTPCookie?
                var cookieName         = "" // name of cookie to look for
                
                if method.lowercased() == "skip" {
                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[Jpapi.action] skipping \(endpoint) endpoint with id \(id).") }
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
                
                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[Jpapi.action] Attempting \(method) on \(urlString).") }
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
                                    WriteToLog.shared.message(stringOfText: "[Jpapi.action] set cookie (name:value) \(String(describing: cookieName)):\(String(describing: sessionCookie!.value)) for \(String(describing: sessionCookie!.domain))")
                                    JamfProServer.sessionCookie.append(sessionCookie!)
                                } else {
                                    HTTPCookieStorage.shared.removeCookies(since: History.startTime)
                                }
                            }
                            
                            let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                            if let endpointJSON = json as? [String:Any] {
                                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[Jpapi.action] Data retrieved from \(urlString).") }
                                completion(endpointJSON)
                                return
                            } else {    // if let endpointJSON error
                                if httpResponse.statusCode == 204 && endpoint == "auth/invalidate-token" {
                                    completion(["JPAPI_result":"token terminated", "JPAPI_response":httpResponse.statusCode])
                                } else {
                                    if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[Jpapi.action] JSON error.  Returned data: \(String(describing: json))") }
                                    completion(["JPAPI_result":"failed", "JPAPI_response":httpResponse.statusCode])
                                }
                                return
                            }
                        } else {    // if httpResponse.statusCode <200 or >299
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
    
    func getAll(whichServer: String, theEndpoint: String, whichPage: Int, completion: @escaping (_ result: [Any]) -> Void) {
        var fetchedAllRecords = false
        var pendingCalls  = 0
        let maxConcurrent = 3
        var currentPage   = 0
        
        switch theEndpoint {
        case "packages":
            print("[getAll] look for \(theEndpoint)")
            DispatchQueue.global(qos: .background).async { [self] in
                repeat {
                    if pendingCalls < maxConcurrent {
                        pendingCalls += 1
                        pagedGet(whichServer: whichServer, theEndpoint: theEndpoint, whichPage: currentPage) {
                            returnedJson in
                            pendingCalls -= 1
                            print("[getAll] pending calls: \(pendingCalls)")
                            if let returnedRecords = returnedJson["results"] as? [[String: Any]], returnedRecords.count > 0 {
                                for theObject in returnedRecords {
                                    if let id = theObject["id"] as? Int, id != 0, let name = theObject["displayName"] as? String, name != "", let fileName = theObject["fileName"] as? String, fileName != "" {
                                            existingObjects.append(ExistingObject(type: theEndpoint, id: id, name: name, fileName: fileName))
                                    } else {
                                        
                                    }
                                }
                                print("[getAll] records added: \(returnedRecords.count)")
                                WriteToLog.shared.message(stringOfText: "[Jpapi.getAll] total records fetched \(returnedRecords.count) objects")
                            } else {
                                fetchedAllRecords = true
                            }
                            if fetchedAllRecords && pendingCalls == 0 {
                                completion(existingObjects)
                            }
                        }
                        currentPage += 1
                    } else {
                        usleep(10000)
                    }
                    usleep(10000)
                } while !fetchedAllRecords
            }
        default:
            print("[getAll] look for \(theEndpoint)")
            // all records in one call
            get(whichServer: whichServer, theEndpoint: theEndpoint) {
                returnedJson in
//                if let returnedRecords = returnedJson as? [[String: Any]] {
                var currentCount = existingObjects.count
                    for theObject in returnedJson {
//                    for thePackage in returnedJson {
                        if let id = theObject["id"] as? Int, id != 0, let name = theObject["name"] as? String, name != "" {
                            if !(theEndpoint == "policies" && name.range(of:"[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] at ", options: .regularExpression) != nil) {
                                existingObjects.append(ExistingObject(type: theEndpoint, id: id, name: name))
//                                print("[getAll] added type: \(theEndpoint), name: \(name), id: \(id)")
                            }
                            
                        } else {
                            
                        }
                    }
                print("[getAll] records returned: \(returnedJson.count)")
                print("[getAll]    records added: \(existingObjects.count - currentCount)")
//                                WriteToLog.shared.message(stringOfText: "[Jpapi.getAll] total records fetched \(allRecords.count) objects")
//                }
                completion(existingObjects)
            }
            break
        }
    }
    
    func get(whichServer: String, theEndpoint: String, id: String = "", whichPage: Int = -1, completion: @escaping (_ returnedJson: [[String: Any]]) -> Void) {
        var endpointVersion = ""
        switch theEndpoint {
        case "test3":
           endpointVersion = "v3"
        case "patch-software-title-configurations","patchsoftwaretitles":
           endpointVersion = "v2"
        case "packages", "jcds/files":
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
        
        var endpoint = "\(String(describing: JamfProServer.url[whichServer]))/api/\(endpointVersion)/\(theEndpoint)"
        
        endpoint = endpoint.replacingOccurrences(of: "//api", with: "/api")
        print("[ExistingObjects.get] endpoint: \(endpoint)")
        
        let endpointUrl    = URL(string: "\(endpoint)")
        let configuration  = URLSessionConfiguration.ephemeral
        var request        = URLRequest(url: endpointUrl!)
        request.httpMethod = "GET"
        configuration.httpAdditionalHeaders = ["Authorization" : "Bearer \(String(describing: JamfProServer.accessToken[whichServer]))", "Content-Type" : "application/json", "Accept" : "application/json", "User-Agent" : AppInfo.userAgentHeader]
//        print("[getAllPolicies] configuration.httpAdditionalHeaders: \(configuration.httpAdditionalHeaders ?? [:])")
        let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) -> Void in
            session.finishTasksAndInvalidate()
            if let httpResponse = response as? HTTPURLResponse {
                print("[ExistingObjects.get] response statusCode: \(httpResponse.statusCode)")
                if httpSuccess.contains(httpResponse.statusCode) {
//                    print("[ExistingObjects.get] data as string: \(String(data: data ?? Data(), encoding: .utf8))")
                    let responseData = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                    
                    if ["patch-software-title-configurations","patchsoftwaretitles"].contains(theEndpoint) {
                        if let recordsArray = responseData as? [[String: Any]] {
//                            print("[ExistingObjects.get] \(theEndpoint) - found \(recordsArray.description)")
                            completion(recordsArray)
                        } else {
                            WriteToLog.shared.message(stringOfText: "[ExistingObjects.get] No data was returned from the GET.")
                            completion([])
                        }
                    } else {
                        if let recordsJson = responseData as? [String: [[String: Any]]], let recordsArray = recordsJson[endpointParent] {
//                            print("[ExistingObjects.get] \(theEndpoint) - found \(recordsArray.description)")
                                completion(recordsArray)
                        } else {
                            WriteToLog.shared.message(stringOfText: "[ExistingObjects.get] No data was returned from the GET.")
                            completion([])
                        }
                    }
                }
            } else {
                WriteToLog.shared.message(stringOfText: "[ExistingObjects.get] unable to read the response from the GET.")
                completion([])
            }
        })
        task.resume()
        
    }
    
    
    func pagedGet(whichServer: String, theEndpoint: String, id: String = "", whichPage: Int = -1, completion: @escaping (_ returnedJSON: [String: Any]) -> Void) {
        var endpointVersion = ""
        switch theEndpoint {
        case "test3":
           endpointVersion = "v3"
        case "patch-software-title-configurations","patchsoftwaretitles":
           endpointVersion = "v2"
        case "packages":
           endpointVersion = "v1"
        default:
            break
        }
        
        var endpoint = "\(String(describing: JamfProServer.url[whichServer]))/api/\(endpointVersion)/\(theEndpoint)"
        if id == "" {
            endpoint = endpoint + "?page=\(whichPage)&page-size=\(pageSize)&sort=id%3Aasc"
        }
        endpoint = endpoint.replacingOccurrences(of: "//api", with: "/api")
        print("[ExistingObjects.get] endpoint: \(endpoint)")
        
        let endpointUrl    = URL(string: "\(endpoint)")
        let configuration  = URLSessionConfiguration.ephemeral
        var request        = URLRequest(url: endpointUrl!)
        request.httpMethod = "GET"
        configuration.httpAdditionalHeaders = ["Authorization" : "Bearer \(String(describing: JamfProServer.accessToken[whichServer]))", "Content-Type" : "application/json", "Accept" : "application/json", "User-Agent" : AppInfo.userAgentHeader]
//        print("[getAllPolicies] configuration.httpAdditionalHeaders: \(configuration.httpAdditionalHeaders ?? [:])")
        let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) -> Void in
            session.finishTasksAndInvalidate()
            if let httpResponse = response as? HTTPURLResponse {
                print("[ExistingObjects.get] response statusCode: \(httpResponse.statusCode)")
                if httpSuccess.contains(httpResponse.statusCode) {
//                    print("[ExistingObjects.get] data as string: \(String(data: data ?? Data(), encoding: .utf8))")
                    let responseData = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                    if let endpointJSON = responseData! as? [String: Any] {
                        completion(endpointJSON)
                        //                           print("[ExistingObjects.get] endpointJSON for page \(whichPage): \(endpointJSON)")
                        return
                    } else {
                        WriteToLog.shared.message(stringOfText: "[ExistingObjects.get] No data was returned from the GET.")
                        completion([:])
                    }
                }
            } else {
                WriteToLog.shared.message(stringOfText: "[ExistingObjects.get] unable to read the response from the GET.")
                completion([:])
            }
        })
        task.resume()
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(  URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
}
