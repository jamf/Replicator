//
//  Sites.swift
//  Replicator
//
//  Created by Leslie Helou on 8/21/19.
//  Copyright 2024 Jamf. All rights reserved.
//

import Foundation

class Sites: NSObject, URLSessionDelegate {
    
    let vc           = ViewController()
    var resourcePath = ""
    var base64Creds  = ""
    
    var jamfpro: JamfPro?
    
    func fetch(server: String, creds: String, completion: @escaping ((Int,[String])) -> Void) {
        logFunctionCall()
        
//        jamfpro = JamfPro(controller: ViewController())
        var siteArray = [String]()
//        var siteDict  = Dictionary<String, Any>()
        base64Creds   = Data("\(creds)".utf8).base64EncodedString()
        
        if "\(server)" == "" {
            vc.alert_dialog(header: "Attention:", message: "Destination Jamf server is required.")
            completion((0,siteArray))
        }
        if "\(creds)" == ":" {
            vc.alert_dialog(header: "Attention:", message: "Destination credentials are required.")
            completion((401,siteArray))
        }
        
        resourcePath = "\(server)/JSSResource/sites"
        resourcePath = resourcePath.urlFix
        
        // get all the sites - start
        WriteToLog.shared.message("[Sites] Fetching sites from \(server)")

        getSites() {
            (result: [String]) in
            siteArray = result
            completion((200,siteArray))
            return siteArray
        }
    }
    
    func getSites(completion: @escaping ([String]) -> [String]) {
        logFunctionCall()
        
        var destSiteArray = [String]()
        
        let serverEncodedURL = URL(string: resourcePath)
        let serverRequest = NSMutableURLRequest(url: serverEncodedURL! as URL)
        //        print("serverRequest: \(serverRequest)")
        serverRequest.httpMethod = "GET"
        let serverConf = URLSessionConfiguration.ephemeral

        serverConf.httpAdditionalHeaders = ["Authorization" : "\(JamfProServer.authType["dest"] ?? "Bearer") \(JamfProServer.authCreds["dest"] ?? "")", "Content-Type" : "application/json", "Accept" : "application/json", "User-Agent" : AppInfo.userAgentHeader]
        
        var headers = [String: String]()
        for (header, value) in serverConf.httpAdditionalHeaders ?? [:] {
            headers[header as! String] = (header as! String == "Authorization") ? "Bearer ************" : value as? String
        }
        print("[apiCall] \(#function.description) method: \(serverRequest.httpMethod)")
        print("[apiCall] \(#function.description) headers: \(headers)")
        print("[apiCall] \(#function.description) endpoint: \(serverEncodedURL?.absoluteString ?? "")")
        print("[apiCall]")

        let serverSession = Foundation.URLSession(configuration: serverConf, delegate: self, delegateQueue: OperationQueue.main)
        
        let semaphore = DispatchSemaphore(value: 0)
        let task = serverSession.dataTask(with: serverRequest as URLRequest, completionHandler: {
            (data, response, error) -> Void in
//            defer { semaphore.signal() }
            serverSession.finishTasksAndInvalidate()
            if let httpResponse = response as? HTTPURLResponse {
                // print("httpResponse: \(String(describing: response))")
                
                if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
                    do {
                        let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                        //                    print("\(json)")
                        if let endpointJSON = json as? [String: Any] {
                            if let siteEndpoints = endpointJSON["sites"] as? [Any] {
                                let siteCount = siteEndpoints.count
                                if siteCount > 0 {
                                    for i in (0..<siteCount) {
                                        // print("site \(i): \(siteEndpoints[i])")
                                        let theSite = siteEndpoints[i] as! [String:Any]
                                        // print("theSite: \(theSite))")
                                        // print("site \(i) name: \(String(describing: theSite["name"]))")
                                        destSiteArray.append(theSite["name"] as! String)
                                    }
                                }
                            }
                        }   // if let serverEndpointJSON - end
                        
                    }  // end do/catch
                    //                        self.site_Button.isEnabled = true
                    destSiteArray = destSiteArray.sorted()
                    completion(destSiteArray)
                } else {
                    // something went wrong
                    WriteToLog.shared.message("[Sites] Unable to look up Sites.  Verify the account being used is able to login and view Sites.\nStatus Code: \(httpResponse.statusCode)")
                    self.vc.alert_dialog(header: "Alert", message: "Unable to look up Sites.  Verify the account being used is able to login and view Sites.\nStatus Code: \(httpResponse.statusCode)")
                    
                    //                        self.enableSites_Button.state = convertToNSControlStateValue(0)
                    //                        self.site_Button.isEnabled = false
                    destSiteArray = []
                    completion(destSiteArray)
                    
                }   // if httpResponse/else - end
            } else {   // if let httpResponse - end
                destSiteArray = []
                completion(destSiteArray)
            }
            semaphore.signal()
        })  // let task = - end
        task.resume()
        semaphore.wait()
    }
    //    --------------------------------------- grab sites - end
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        logFunctionCall()
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
}
