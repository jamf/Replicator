//
//  PackagesDelegate.swift
//  jamf-migrator
//
//  Created by Leslie Helou on 12/13/21.
//  Copyright © 2021 jamf. All rights reserved.
//

import Foundation

class PackagesDelegate: NSObject, URLSessionDelegate {
    // get the package filename, rather than display name
    
    func getFilename(theServer: String, base64Creds: String, theEndpoint: String, theEndpointID: Int, skip: Bool, completion: @escaping (_ result: (Int,String)) -> Void) {

//        if skip {
//            completion((theEndpointID,""))
//            return
//        }
        print("[PackageDelegate.getFilename] wipe: \(skip)")
        let getRecordQ = OperationQueue()   //DispatchQueue(label: "com.jamf.getRecordQ", qos: DispatchQoS.background)
    
        URLCache.shared.removeAllCachedResponses()
        var existingDestUrl = ""
        
        existingDestUrl = "\(theServer)/JSSResource/\(theEndpoint)/id/\(theEndpointID)"
        existingDestUrl = existingDestUrl.urlFix
        
        if LogLevel.debug { WriteToLog().message(stringOfText: "[PackagesDelegate.getFilename] Looking up: \(existingDestUrl)\n") }
//                    if "\(existingDestUrl)" == "" { existingDestUrl = "https://localhost" }
        let destEncodedURL = URL(string: existingDestUrl)
        let jsonRequest    = NSMutableURLRequest(url: destEncodedURL! as URL)
        
        let semaphore = DispatchSemaphore(value: 1)
        getRecordQ.maxConcurrentOperationCount = 3
        getRecordQ.addOperation {
            
            jsonRequest.httpMethod = "GET"
            let destConf = URLSessionConfiguration.ephemeral
            destConf.httpAdditionalHeaders = ["Authorization" : "Basic \(base64Creds)", "Accept" : "application/json"]
            let destSession = Foundation.URLSession(configuration: destConf, delegate: self, delegateQueue: OperationQueue.main)
            
            let task = destSession.dataTask(with: jsonRequest as URLRequest, completionHandler: {
                (data, response, error) -> Void in
                if let httpResponse = response as? HTTPURLResponse {
//                    print("[PackagesDelegate.getFilename] httpResponse: \(String(describing: httpResponse))")
                    if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
//                                    do {
                            let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                            if let destEndpointJSON = json as? [String: Any] {
//                                print("[PackagesDelegate.getFilename] destEndpointJSON: \(String(describing: destEndpointJSON))")
                                if let destEndpointInfo = destEndpointJSON["package"] as? [String:Any] {
                                    let packageFilename = "\(String(describing: destEndpointInfo["filename"]!))"
                                    print("[PackagesDelegate.getFilename] destEndpointJSON[filename]: \(String(describing: packageFilename))")
                                    print("[PackagesDelegate.getFilename] destEndpointJSON[name]: \(String(describing: destEndpointInfo["name"]!))")
                                    // adjust what is returned based on whether we're removing records
                                    let returnedName = skip ? "\(String(describing: destEndpointInfo["name"]!))":packageFilename
                                    completion((httpResponse.statusCode,returnedName))
                                }
                            }
//                                    }
                    } else {
                        WriteToLog().message(stringOfText: "[PackagesDelegate.getFilename] error HTTP Status Code: \(httpResponse.statusCode)\n")
//                        print("[PackagesDelegate.getFilename] error HTTP Status Code: \(httpResponse.statusCode)\n")
                        completion((httpResponse.statusCode,""))
                        
                    }
                } else {
                    WriteToLog().message(stringOfText: "[PackagesDelegate.getFilename] error getting JSON for \(existingDestUrl)\n")
                    completion((0,""))
                }   // if let httpResponse - end
                semaphore.signal()
                if error != nil {
                }
            })  // let task = destSession - end
            //print("GET")
            task.resume()
            semaphore.wait()
        }   // getRecordQ - end
    }
}
