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
//           = ["Authorization" : "Basic \(base64Creds)", "Accept" : "application/json"]
            destConf.httpAdditionalHeaders = ["Authorization" : "\(String(describing: JamfProServer.authType["source"]!)) \(String(describing: JamfProServer.authCreds["source"]!))", "Content-Type" : "application/json", "Accept" : "application/json", "User-Agent" : appInfo.userAgentHeader]
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
//                                    print("[PackagesDelegate.getFilename] destEndpointJSON[filename]: \(String(describing: packageFilename))")
//                                    print("[PackagesDelegate.getFilename] destEndpointJSON[name]: \(String(describing: destEndpointInfo["name"]!))")
                                    // adjust what is returned based on whether we're removing records
                                    let returnedName = skip ? "\(String(describing: destEndpointInfo["name"]!))":packageFilename
//                                    print("[PackageDelegate.getFilename] packageFilename: \(packageFilename) (id: \(theEndpointID))")
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
    
    func filenameIdDict(theServer: String, base64Creds: String, currentPackageIDsNames: [Int:String], currentPackageNamesIDs: [String:Int], currentDuplicates: [String:[String]], currentTry: Int, maxTries: Int, completion: @escaping (_ result: [String:Int]) -> Void) {
        
//        print("[PackageDelegate.filenameIdDict] lookup attempt \(currentTry) of \(maxTries)")
        
        var packageIDsNames       = currentPackageIDsNames
        var existingNameId        = currentPackageNamesIDs
        var duplicatePackagesDict = currentDuplicates
        
        var message = ""
        var lookupCount = 0
        let packageCount = packageIDsNames.count
        
        for (packageID, packageName) in packageIDsNames {
            getFilename(theServer: theServer, base64Creds: base64Creds, theEndpoint: "packages", theEndpointID: packageID, skip: false) { [self]
                (result: (Int,String)) in
                lookupCount += 1
//                print("[PackageDelegate.filenameIdDict] destRecord: \(result)")
                let (resultCode,packageFilename) = result
                if pref.httpSuccess.contains(resultCode) {
                    
                    packageIDsNames[packageID] = nil

                    if packageFilename != "" && existingNameId[packageFilename] == nil {
//                        print("[PackageDelegate.filenameIdDict] add \(packageFilename) to package dict")
                        existingNameId[packageFilename] = packageID
                        duplicatePackagesDict[packageFilename] = [packageName]
                    } else {
                        if packageFilename != "" {
                            duplicatePackagesDict[packageFilename]!.append(packageName)
                        } else {
                            WriteToLog().message(stringOfText: "[PackageDelegate.filenameIdDict] Failed to lookup filename for \(packageName)\n")
                        }

//                        print("[PackageDelegate.filenameIdDict] Duplicate package filename found on \(theServer): \(packageFilename), id: \(packageID)\n")
//                                                            WriteToLog().message(stringOfText: "[PackageDelegate.filenameIdDict] Duplicate filename found on \(self.dest_jp_server): \(packageFilename), id: \(packageID)\n")
                        if wipeData.on {
                            existingNameId[packageName] = packageID
                        }
                    }
                } else {  // if pref.httpSuccess.contains(resultCode) - end
//                    print("[PackageDelegate.filenameIdDict] failed looking up \(packageName)")
                    WriteToLog().message(stringOfText: "[PackageDelegate.filenameIdDict] Failed to lookup \(packageName).  Status code: \(resultCode)\n")
                }
                // looked up last package in list
                if lookupCount == packageCount {
//                    print("[PackageDelegate.filenameIdDict] done looking up packages on \(theServer)")
                    
                    if currentTry < maxTries+1 && packageIDsNames.count > 0 {
                        filenameIdDict(theServer: theServer, base64Creds: base64Creds, currentPackageIDsNames: packageIDsNames, currentPackageNamesIDs: existingNameId, currentDuplicates: duplicatePackagesDict, currentTry: currentTry+1, maxTries: maxTries) {
                            (result: [String:Int]) in
                        }
                    } else {
                        // call out duplicates
                        for (pkgFilename, displayNames) in duplicatePackagesDict {
                            if displayNames.count > 1 {
                                for dup in displayNames {
                                    message = "\(message)\t\(pkgFilename) : \(dup)\n"
                                }
                            }
                        }
                        if message != "" {
                            message = "\tFilename : Display Name\n\(message)"
                            
                            if !wipeData.on {
                                WriteToLog().message(stringOfText: "[PackageDelegate.filenameIdDict] Duplicate references to the same package were found on \(theServer)\n\(message)\n")
                                let theButton = Alert().display(header: "Warning:", message: "Several packages on \(theServer), having unique display names, are linked to a single file.  Check the log for 'Duplicate references to the same package' for details.", secondButton: "Stop")
                                if theButton == "Stop" {
                                    pref.stopMigration = true
    //                                ViewController().stopButton(self)
                                }
                            }
//                            WriteToLog().message(stringOfText: "[PackageDelegate.filenameIdDict] Duplicate references to the same package were found on \(theServer)\n\(message)\n")
                        }
                        completion(existingNameId)
                    }
                }
            }
        }   // for (packageID, packageName) - end
    }
}
