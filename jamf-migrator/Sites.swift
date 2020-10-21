//
//  Sites.swift
//  jamf-migrator
//
//  Created by Leslie Helou on 8/21/19.
//  Copyright © 2019 jamf. All rights reserved.
//

import Foundation

class Sites: NSObject, URLSessionDelegate {
    
    let vc           = ViewController()
    var resourcePath = ""
    var token        = ""

    func fetch(server: String, creds: String, completion: @escaping ([String]) -> Void) {
        
        var siteArray = [String]()
//        var siteDict  = Dictionary<String, Any>()
        token         = Data("\(creds)".utf8).base64EncodedString()
        
        if "\(server)" == "" {
            vc.alert_dialog(header: "Attention:", message: "Destination Jamf server is required.")
            completion(siteArray)
        }
        
        if "\(creds)" == ":" {
            vc.alert_dialog(header: "Attention:", message: "Destination credentials are required.")
            completion(siteArray)
        }
        
        resourcePath = "\(server)/JSSResource/sites"
        resourcePath = resourcePath.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
        // get all the sites - start
        WriteToLog().message(stringOfText: "[Sites] Fetching sites from \(server)\n")
        getSites() {
            (result: [String]) in
            siteArray = result

            completion(siteArray)
            return siteArray
        }
        
    }
    
    func getSites(completion: @escaping ([String]) -> [String]) {
//        var local_allSites = Dictionary<String, Int>()
        var destSiteArray = [String]()
        
        let serverEncodedURL = URL(string: resourcePath)
        let serverRequest = NSMutableURLRequest(url: serverEncodedURL! as URL)
        //        print("serverRequest: \(serverRequest)")
        serverRequest.httpMethod = "GET"
        let serverConf = URLSessionConfiguration.default
        serverConf.httpAdditionalHeaders = ["Authorization" : "Basic \(token)", "Content-Type" : "application/json", "Accept" : "application/json"]
        let serverSession = Foundation.URLSession(configuration: serverConf, delegate: self, delegateQueue: OperationQueue.main)
        let task = serverSession.dataTask(with: serverRequest as URLRequest, completionHandler: {
            (data, response, error) -> Void in
            if let httpResponse = response as? HTTPURLResponse {
                // print("httpResponse: \(String(describing: response))")
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
                
                if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
                    //print(httpResponse.statusCode)
                    
                    //                        self.site_Button.isEnabled = true
                    destSiteArray = destSiteArray.sorted()
                    completion(destSiteArray)
                } else {
                    // something went wrong
                    WriteToLog().message(stringOfText: "[Sites] Unable to look up Sites.  Verify the account being used is able to login and view Sites.\nStatus Code: \(httpResponse.statusCode)\n")
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
            //            semaphore.signal()
        })  // let task = - end
        task.resume()
    }
    //    --------------------------------------- grab sites - end
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(  URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
}
