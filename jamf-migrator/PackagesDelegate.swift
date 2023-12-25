//
//  PackagesDelegate.swift
//  jamf-migrator
//
//  Created by Leslie Helou on 12/13/21.
//  Copyright © 2021 jamf. All rights reserved.
//

import Foundation

class PackagesDelegate: NSObject, URLSessionDelegate {
    
    var packageGetQ     = DispatchQueue(label: "com.jamf.packageGetQ", qos: DispatchQoS.background)
    // get the package filename, rather than display name
    func getFilename(whichServer: String, theServer: String, base64Creds: String, theEndpoint: String, theEndpointID: Int, skip: Bool, currentTry: Int, completion: @escaping (_ result: (Int,String)) -> Void) {

//        if skip {
//            completion((theEndpointID,""))
//            return
//        }
        let theServerUrl = (whichServer == "source") ? JamfProServer.source:JamfProServer.destination
//        JamfPro().getToken(whichServer: "dest", serverUrl: theServerUrl, base64creds: JamfProServer.base64Creds[whichServer] ?? "") { [self]
        JamfPro().getToken(whichServer: whichServer, serverUrl: theServerUrl, base64creds: JamfProServer.base64Creds[whichServer] ?? "") { [self]
            (result: (Int,String)) in
            let (statusCode, theResult) = result
            //            print("[endpointByIdQueue] token check")
            if theResult == "success" {
                
                let maxTries   = 4
                let getRecordQ = OperationQueue()
            
                URLCache.shared.removeAllCachedResponses()
                var existingDestUrl = ""
                
                existingDestUrl = "\(theServer)/JSSResource/\(theEndpoint)/id/\(theEndpointID)"
                existingDestUrl = existingDestUrl.urlFix
                
                if LogLevel.debug { WriteToLog().message(stringOfText: "[PackagesDelegate.getFilename] Looking up: \(existingDestUrl)\n") }

                let destEncodedURL = URL(string: existingDestUrl)
                let jsonRequest    = NSMutableURLRequest(url: destEncodedURL! as URL)
                
                getRecordQ.maxConcurrentOperationCount = 3
                let semaphore = DispatchSemaphore(value: 0)
                getRecordQ.addOperation {
                    
                    jsonRequest.httpMethod = "GET"
                    let destConf = URLSessionConfiguration.ephemeral

                    destConf.httpAdditionalHeaders = ["Authorization" : "\(JamfProServer.authType[whichServer] ?? "Bearer") \(JamfProServer.authCreds[whichServer] ?? "")", "Content-Type" : "application/json", "Accept" : "application/json", "User-Agent" : AppInfo.userAgentHeader]
                    let destSession = Foundation.URLSession(configuration: destConf, delegate: self, delegateQueue: OperationQueue.main)
                    
                    let task = destSession.dataTask(with: jsonRequest as URLRequest, completionHandler: {
                        (data, response, error) -> Void in
                        destSession.finishTasksAndInvalidate()
                        
                        if LogLevel.debug {
                            WriteToLog().message(stringOfText: "[PackagesDelegate.getFilename] jsonRequest: \(String(describing: jsonRequest.url!))\n")
                            WriteToLog().message(stringOfText: "[PackagesDelegate.getFilename] response: \(String(describing: response))\n")
                            if let _ = response as? HTTPURLResponse {
                                WriteToLog().message(stringOfText: "[PackagesDelegate.getFilename] data: \(String(describing: String(data:data!, encoding: .utf8)))\n\n")
                            }
                        }
                        
                        if let httpResponse = response as? HTTPURLResponse {
        //                if (response as? HTTPURLResponse != nil) && !(currentTry < 5 && theEndpointID == 75) {
        //                    let httpResponse = response as! HTTPURLResponse
                            if pref.httpSuccess.contains(httpResponse.statusCode) {
        //                    if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
                                    let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                                    if let destEndpointJSON = json as? [String: Any] {
        //                                print("[PackagesDelegate.getFilename] destEndpointJSON: \(String(describing: destEndpointJSON))")
                                        if let destEndpointInfo = destEndpointJSON["package"] as? [String:Any] {
                                            let packageFilename = "\(String(describing: destEndpointInfo["filename"]!))"
        //                                    print("[PackagesDelegate.getFilename] destEndpointJSON[filename]: \(String(describing: packageFilename))")
        //                                    print("[PackagesDelegate.getFilename] destEndpointJSON[name]: \(String(describing: destEndpointInfo["name"]!))")
                                            // adjust what is returned based on whether we're removing records
                                            let returnedName = skip ? "\(String(describing: destEndpointInfo["name"]!))":packageFilename
                                            print("[PackageDelegate.getFilename] packageFilename: \(packageFilename) (id: \(theEndpointID))")
                                            completion((httpResponse.statusCode,returnedName))
                                        }
                                    }
                            } else {
                                WriteToLog().message(stringOfText: "[PackagesDelegate.getFilename] error HTTP Status Code: \(httpResponse.statusCode)\n")
        //                        print("[PackagesDelegate.getFilename] error HTTP Status Code: \(httpResponse.statusCode)\n")
                                completion((httpResponse.statusCode,""))
                                
                            }
                        } else {
                            WriteToLog().message(stringOfText: "[PackagesDelegate.getFilename] error with response for package ID \(theEndpointID) from \(String(describing: jsonRequest.url!))\n")
        //                    print("[PackagesDelegate.getFilename] response error for package ID \(theEndpointID) on try \(currentTry)\n")
                            if currentTry < maxTries {
                                self.getFilename(whichServer: whichServer, theServer: theServer, base64Creds: base64Creds, theEndpoint: "packages", theEndpointID: theEndpointID, skip: false, currentTry: currentTry+1) {
                                (result: (Int,String)) in
                                    let (resultCode,returnedName) = result
        //                            print("[PackagesDelegate.getFilename] got filename (\(returnedName)) for package ID \(theEndpointID) on try \(currentTry+1)\n")
                                    if returnedName != "" {
                                        completion((resultCode,returnedName))
                                    }
                                }
                            } else {
                                completion((0,""))
                            }
                        }   // if let httpResponse - end
                        semaphore.signal()
                        if error != nil {
                        }
                    })  // let task = destSession - end
                    //print("GET")
                    task.resume()
                    semaphore.wait()
                }   // getRecordQ - end
        //        getRecordQ.waitUntilAllOperationsAreFinished()
            } else {
                completion((0,""))
            }
        }
        
    }
    
    func filenameIdDict(whichServer: String, theServer: String, base64Creds: String, currentPackageIDsNames: [Int:String], currentPackageNamesIDs: [String:Int], currentDuplicates: [String:[String]], currentTry: Int, maxTries: Int, completion: @escaping (_ result: [String:Int]) -> Void) {
        
//        print("[PackageDelegate.filenameIdDict] lookup attempt \(currentTry) of \(maxTries)")
        
        var packageIDsNames       = currentPackageIDsNames
        var existingNameId        = currentPackageNamesIDs
        var duplicatePackagesDict = currentDuplicates
        
//        var message     = ""
        var lookupCount = 0
        
        let packageCount = packageIDsNames.count
        
        print("filenameIdDict server: \(whichServer)")
        print("           the server: \(theServer)")
        
        var i = 0
        var getsPending = 0
        packageGetQ.async { [self] in
            while i < packageCount {
                if getsPending < maxConcurrentThreads && packageIDsNames.count > 0 {
                    let (packageID, packageName) = packageIDsNames.popFirst()!
                    i += 1
                    getsPending += 1
                    
                        getFilename(whichServer: whichServer, theServer: theServer, base64Creds: base64Creds, theEndpoint: "packages", theEndpointID: packageID, skip: false, currentTry: 3) { [self]
                            (result: (Int,String)) in
                            getsPending -= 1
                            lookupCount += 1
            //                print("[PackageDelegate.filenameIdDict] destRecord: \(result)")
                            let (resultCode,packageFilename) = result

                            print("[getFilename] looked up: \(lookupCount) of \(packageCount)")
                            print("[getFilename] packageFilename: \(packageFilename) server: \(theServer)")
                            if pref.httpSuccess.contains(resultCode) {
                                // found name, remove from list
                                packageIDsNames[packageID] = nil

                                if packageFilename != "" && existingNameId[packageFilename] == nil {
            //                        print("add package to dict")
            //                      print("[PackageDelegate.filenameIdDict] add \(packageFilename) to package dict")
                                    existingNameId[packageFilename]        = packageID
                                    // used to check for duplicates: duplicatePackagesDict[packageFilename].count > 1?
                                    duplicatePackagesDict[packageFilename] = [packageName]
            //                      WriteToLog().message(stringOfText: "[PackageDelegate.filenameIdDict] Duplicate filename found on \(self.dest_jp_server): \(packageFilename), id: \(packageID)\n")
                                } else {
                                    if packageFilename != "" {
                                        duplicatePackagesDict[packageFilename]!.append(packageName)
                                    } else {
                                        WriteToLog().message(stringOfText: "[PackageDelegate.filenameIdDict] Failed to lookup filename for \(packageName)\n")
                                    }

                                    if wipeData.on {
                                        existingNameId[packageName] = packageID
                                    }
                                }
                            } else {  // if pref.httpSuccess.contains(resultCode) - end
            //                  print("[PackageDelegate.filenameIdDict] failed looking up \(packageName)")
                                WriteToLog().message(stringOfText: "[PackageDelegate.filenameIdDict] Failed to lookup \(packageName).  Status code: \(resultCode)\n")
                            }
                            // looked up last package in list
            //                print("           currentTry: \(currentTry)")
            //                print("             maxTries: \(maxTries+1)")
            //                print("packageIDsNames.count: \(packageIDsNames.count)")
                            JamfProServer.pkgsNotFound = packageIDsNames.count
                            if lookupCount == packageCount {
            //                    print("[PackageDelegate.filenameIdDict] done looking up packages on \(theServer)")
                                if currentTry < maxTries+1 && packageIDsNames.count > 0 {
                                    WriteToLog().message(stringOfText: "[PackageDelegate.filenameIdDict] \(packageIDsNames.count) filename(s) were not found.  Retry attempt \(currentTry)\n")
                                    filenameIdDict(whichServer: whichServer, theServer: theServer, base64Creds: base64Creds, currentPackageIDsNames: packageIDsNames, currentPackageNamesIDs: existingNameId, currentDuplicates: duplicatePackagesDict, currentTry: currentTry+1, maxTries: maxTries) {
                                        (result: [String:Int]) in
                                        WriteToLog().message(stringOfText: "[PackageDelegate.filenameIdDict] returned from retry \(currentTry)\n")
            //                            print("               currentTry1: \(currentTry)")
            //                            print("JamfProServer.pkgsNotFound: \(JamfProServer.pkgsNotFound)")
                                        if JamfProServer.pkgsNotFound == 0 || currentTry >= maxTries {
            //                                print("call out dups and completion")
                                            print("[filenameIdDict] \(#line) server: \(theServer)")
                                            self.callOutDuplicates(duplicatesDict: duplicatePackagesDict, theServer: theServer)
                                            completion(existingNameId)
                                        }
                                    }
                                } else {
                                    // call out duplicates
                                    print("[filenameIdDict] completed filenames id for server: \(theServer)")
                                    callOutDuplicates(duplicatesDict: duplicatePackagesDict, theServer: theServer)
                                    completion(existingNameId)
                                }
                            }   // if lookupCount == packageIDsNames.count - end
                        }
                } else {
                    sleep(1)
                }
            }
        }
    }
    
    
    
    
    func callOutDuplicates(duplicatesDict: [String:[String]], theServer: String) {
        // call out duplicates
        print("[callOutDuplicates] \(#line) server: \(theServer)")
        var message = ""
        for (pkgFilename, displayNames) in duplicatesDict {
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
                }
            }
//                            WriteToLog().message(stringOfText: "[PackageDelegate.filenameIdDict] Duplicate references to the same package were found on \(theServer)\n\(message)\n")
        }
    }
}



/*
class PackagesDelegate: NSObject, URLSessionDelegate {
    // get the package filename, rather than display name
    func getFilename(whichServer: String, theServer: String, base64Creds: String, theEndpoint: String, theEndpointID: Int, skip: Bool, currentTry: Int, completion: @escaping (_ result: (Int,String)) -> Void) {

//        if skip {
//            completion((theEndpointID,""))
//            return
//        }
        let maxTries   = 4
        let getRecordQ = OperationQueue()
    
        URLCache.shared.removeAllCachedResponses()
        var existingDestUrl = ""
        
        existingDestUrl = "\(theServer)/JSSResource/\(theEndpoint)/id/\(theEndpointID)"
        existingDestUrl = existingDestUrl.urlFix
        
        if LogLevel.debug { WriteToLog().message(stringOfText: "[PackagesDelegate.getFilename] Looking up: \(existingDestUrl)\n") }

        let destEncodedURL = URL(string: existingDestUrl)
        let jsonRequest    = NSMutableURLRequest(url: destEncodedURL! as URL)
        
        getRecordQ.maxConcurrentOperationCount = 3
        let semaphore = DispatchSemaphore(value: 0)
        getRecordQ.addOperation {
            
            jsonRequest.httpMethod = "GET"
            let destConf = URLSessionConfiguration.ephemeral

            destConf.httpAdditionalHeaders = ["Authorization" : "\(JamfProServer.authType[whichServer] ?? "Bearer") \(JamfProServer.authCreds[whichServer] ?? "")", "Content-Type" : "application/json", "Accept" : "application/json", "User-Agent" : AppInfo.userAgentHeader]
            let destSession = Foundation.URLSession(configuration: destConf, delegate: self, delegateQueue: OperationQueue.main)
            
            let task = destSession.dataTask(with: jsonRequest as URLRequest, completionHandler: {
                (data, response, error) -> Void in
                destSession.finishTasksAndInvalidate()
                
                if LogLevel.debug {
                    WriteToLog().message(stringOfText: "[PackagesDelegate.getFilename] jsonRequest: \(String(describing: jsonRequest.url!))\n")
                    WriteToLog().message(stringOfText: "[PackagesDelegate.getFilename] response: \(String(describing: response))\n")
                    if let _ = response as? HTTPURLResponse {
                        WriteToLog().message(stringOfText: "[PackagesDelegate.getFilename] data: \(String(describing: String(data:data!, encoding: .utf8)))\n\n")
                    }
                }
                
                if let httpResponse = response as? HTTPURLResponse {
//                if (response as? HTTPURLResponse != nil) && !(currentTry < 5 && theEndpointID == 75) {
//                    let httpResponse = response as! HTTPURLResponse
                    if pref.httpSuccess.contains(httpResponse.statusCode) {
//                    if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
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
                    } else {
                        WriteToLog().message(stringOfText: "[PackagesDelegate.getFilename] error HTTP Status Code: \(httpResponse.statusCode)\n")
//                        print("[PackagesDelegate.getFilename] error HTTP Status Code: \(httpResponse.statusCode)\n")
                        completion((httpResponse.statusCode,""))
                        
                    }
                } else {
                    WriteToLog().message(stringOfText: "[PackagesDelegate.getFilename] error with response for package ID \(theEndpointID) from \(String(describing: jsonRequest.url!))\n")
//                    print("[PackagesDelegate.getFilename] response error for package ID \(theEndpointID) on try \(currentTry)\n")
                    if currentTry < maxTries {
                        self.getFilename(whichServer: whichServer, theServer: theServer, base64Creds: base64Creds, theEndpoint: "packages", theEndpointID: theEndpointID, skip: false, currentTry: currentTry+1) {
                        (result: (Int,String)) in
                            let (resultCode,returnedName) = result
//                            print("[PackagesDelegate.getFilename] got filename (\(returnedName)) for package ID \(theEndpointID) on try \(currentTry+1)\n")
                            if returnedName != "" {
                                completion((resultCode,returnedName))
                            }
                        }
                    } else {
                        completion((0,""))
                    }
                }   // if let httpResponse - end
                semaphore.signal()
                if error != nil {
                }
            })  // let task = destSession - end
            //print("GET")
            task.resume()
            semaphore.wait()
        }   // getRecordQ - end
//        getRecordQ.waitUntilAllOperationsAreFinished()
    }
    
    func filenameIdDict(whichServer: String, theServer: String, base64Creds: String, currentPackageIDsNames: [Int:String], currentPackageNamesIDs: [String:Int], currentDuplicates: [String:[String]], currentTry: Int, maxTries: Int, completion: @escaping (_ result: [String:Int]) -> Void) {
        
//        print("[PackageDelegate.filenameIdDict] lookup attempt \(currentTry) of \(maxTries)")
        
        var packageIDsNames       = currentPackageIDsNames
        var existingNameId        = currentPackageNamesIDs
        var duplicatePackagesDict = currentDuplicates
        
//        var message     = ""
        var lookupCount = 0
        
        let packageCount = packageIDsNames.count
        
        print("filenameIdDict server: \(whichServer)")
        print("           the server: \(theServer)")
        
        for (packageID, packageName) in packageIDsNames {
            getFilename(whichServer: whichServer, theServer: theServer, base64Creds: base64Creds, theEndpoint: "packages", theEndpointID: packageID, skip: false, currentTry: 3) { [self]
                (result: (Int,String)) in
                lookupCount += 1
//                print("[PackageDelegate.filenameIdDict] destRecord: \(result)")
                let (resultCode,packageFilename) = result
//                if pref.httpSuccess.contains(resultCode) && !(currentTry == 1 && (packageName == "connection package 2" || packageName == "connection package 3")) { // for testing
                print("[getFilename] \(#line) server: \(theServer)")
                if pref.httpSuccess.contains(resultCode) {
                    // found name, remove from list
                    packageIDsNames[packageID] = nil

                    if packageFilename != "" && existingNameId[packageFilename] == nil {
//                        print("add package to dict")
//                      print("[PackageDelegate.filenameIdDict] add \(packageFilename) to package dict")
                        existingNameId[packageFilename]        = packageID
                        // used to check for duplicates: duplicatePackagesDict[packageFilename].count > 1?
                        duplicatePackagesDict[packageFilename] = [packageName]
//                      WriteToLog().message(stringOfText: "[PackageDelegate.filenameIdDict] Duplicate filename found on \(self.dest_jp_server): \(packageFilename), id: \(packageID)\n")
                    } else {
                        if packageFilename != "" {
                            duplicatePackagesDict[packageFilename]!.append(packageName)
                        } else {
                            WriteToLog().message(stringOfText: "[PackageDelegate.filenameIdDict] Failed to lookup filename for \(packageName)\n")
                        }

                        if wipeData.on {
                            existingNameId[packageName] = packageID
                        }
                    }
                } else {  // if pref.httpSuccess.contains(resultCode) - end
//                  print("[PackageDelegate.filenameIdDict] failed looking up \(packageName)")
                    WriteToLog().message(stringOfText: "[PackageDelegate.filenameIdDict] Failed to lookup \(packageName).  Status code: \(resultCode)\n")
                }
                // looked up last package in list
//                print("           currentTry: \(currentTry)")
//                print("             maxTries: \(maxTries+1)")
//                print("packageIDsNames.count: \(packageIDsNames.count)")
                JamfProServer.pkgsNotFound = packageIDsNames.count
                if lookupCount == packageCount {
//                    print("[PackageDelegate.filenameIdDict] done looking up packages on \(theServer)")
                    if currentTry < maxTries+1 && packageIDsNames.count > 0 {
                        WriteToLog().message(stringOfText: "[PackageDelegate.filenameIdDict] \(packageIDsNames.count) filename(s) were not found.  Retry attempt \(currentTry)\n")
                        filenameIdDict(whichServer: whichServer, theServer: theServer, base64Creds: base64Creds, currentPackageIDsNames: packageIDsNames, currentPackageNamesIDs: existingNameId, currentDuplicates: duplicatePackagesDict, currentTry: currentTry+1, maxTries: maxTries) {
                            (result: [String:Int]) in
                            WriteToLog().message(stringOfText: "[PackageDelegate.filenameIdDict] returned from retry \(currentTry)\n")
//                            print("               currentTry1: \(currentTry)")
//                            print("JamfProServer.pkgsNotFound: \(JamfProServer.pkgsNotFound)")
                            if JamfProServer.pkgsNotFound == 0 || currentTry >= maxTries {
//                                print("call out dups and completion")
                                print("[filenameIdDict] \(#line) server: \(theServer)")
                                self.callOutDuplicates(duplicatesDict: duplicatePackagesDict, theServer: theServer)
                                completion(existingNameId)
                            }
                        }
                    } else {
                        // call out duplicates
                        print("[filenameIdDict] \(#line) server: \(theServer)")
                        callOutDuplicates(duplicatesDict: duplicatePackagesDict, theServer: theServer)
                        completion(existingNameId)
                    }
                }   // if lookupCount == packageIDsNames.count - end
            }   // getFilename(whichServer: - end
        }   // for (packageID, packageName) - end
    }
    
    func callOutDuplicates(duplicatesDict: [String:[String]], theServer: String) {
        // call out duplicates
        print("[callOutDuplicates] \(#line) server: \(theServer)")
        var message = ""
        for (pkgFilename, displayNames) in duplicatesDict {
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
                }
            }
        }
    }
}
*/
