//
//  PackagesDelegate.swift
//  Replicator
//
//  Created by Leslie Helou on 12/13/21.
//  Copyright 2024 Jamf. All rights reserved.
//

import Foundation

struct JsonUapiPackages: Decodable {
    let totalCount: Int
    let results: [JsonUapiPackageDetail]
}

struct JsonUapiPackageDetail: Codable {
    let id: String?
    let packageName: String?
    let fileName: String?
    var categoryId: String?
    var info: String?
    var notes: String?
    var priority: Int?
    var osRequirements: String?
    var fillUserTemplate: Bool?
    var indexed: Bool?
    var uninstall: Bool?
    var fillExistingUsers: Bool?
    var swu: Bool?
    var rebootRequired: Bool?
    var selfHealNotify: Bool?
    var selfHealingAction: String?
    var osInstall: Bool?
    var serialNumber: String?
    var parentPackageId: String?
    var basePath: String?
    var suppressUpdates: Bool?
    var cloudTransferStatus: String?
    var ignoreConflicts: Bool?
    var suppressFromDock: Bool?
    var suppressEula: Bool?
    var suppressRegistration: Bool?
    var installLanguage: String?
    var md5: String?
    var sha256: String?
    var hashType: String?
    var hashValue: String?
    var size: String?
    var osInstallerVersion: String?
    var manifest: String?
    var manifestFileName: String?
    var format: String?

    init(package: Package) {
        if let srcId = package.jamfProId {
            id = String(srcId)
        } else {
            id = nil
        }
        packageName = package.displayName
        fileName = package.fileName
        categoryId = package.category
        categoryId = package.categoryId ?? "-1"
        priority = package.priority ?? 10
        fillUserTemplate = package.fillUserTemplate ?? false
        uninstall = package.uninstall ?? false
        rebootRequired = package.rebootRequired ?? false
        osInstall = package.osInstall ?? false
        suppressUpdates = package.suppressUpdates ?? false
        suppressFromDock = package.suppressFromDock ?? false
        suppressEula = package.suppressEula ?? false
        suppressRegistration = package.suppressRegistration ?? false
//        if let checksum = package.checksums.findChecksum(type: .MD5) {
//            md5 = checksum.value
//        } else {
//            md5 = nil
//        }
//        if let checksum = package.checksums.findChecksum(type: .SHA_256) {
//            sha256 = checksum.value
//        } else {
//            sha256 = nil
//        }
//        if let checksum = package.checksums.findChecksum(type: .SHA_512) {
//            hashType = "SHA_512"
//            hashValue = checksum.value
//        } else {
//            hashType = nil
//            hashValue = nil
//        }
        if let pkgSize = package.size {
            size = String(pkgSize)
        } else {
            size = nil
        }

        info = package.info
        notes = package.notes
        osRequirements = package.osRequirements
        indexed = package.indexed
        fillExistingUsers = package.fillExistingUsers
        swu = package.swu
        selfHealNotify = package.selfHealNotify
        selfHealingAction = package.selfHealingAction
        serialNumber = package.serialNumber
        parentPackageId = package.parentPackageId
        basePath = package.basePath
        cloudTransferStatus = package.cloudTransferStatus
        ignoreConflicts = package.ignoreConflicts
        installLanguage = package.installLanguage
        osInstallerVersion = package.osInstallerVersion
        format = package.format
    }
}
class Packages {
    static var source      = [JsonUapiPackageDetail]()
    static var destination = [JsonUapiPackageDetail]()
}

final class ExistingPackages {
    static let shared = ExistingPackages()

    private let existingQueue       = DispatchQueue(label: "existing.packages", qos: .default, attributes: .concurrent)
    private var _packageGetsPending = 0
    private var _packageIDsNames    = [Int: String]()
    
    var packageIDsNames: [Int: String] {
        get {
            var packageIDsNames: [Int: String] = [:]
            existingQueue.sync {
                packageIDsNames = _packageIDsNames
            }
            return packageIDsNames
        }
        set {
            existingQueue.async(flags: .barrier) {
                self._packageIDsNames = newValue
            }
        }
    }

    var packageGetsPending: Int {
        get {
            var packageGetsPending: Int?
            existingQueue.sync {
                packageGetsPending = _packageGetsPending
            }
            return packageGetsPending ?? 0
        }
        set {
            existingQueue.async(flags: .barrier) {
                self._packageGetsPending = newValue
            }
        }
    }
}


class PackagesDelegate: NSObject, URLSessionDelegate {
    
    static let shared = PackagesDelegate()
    private override init() { }
    
    var packageGetQ     = DispatchQueue(label: "com.jamf.packageGetQ", qos: DispatchQoS.background)
    
    
    private func convertToPackage(jsonPackage: JsonUapiPackageDetail) -> Package? {
        guard let jamfProIdString = jsonPackage.id, let _ = Int(jamfProIdString), let _ = jsonPackage.packageName, let _ = jsonPackage.fileName else { return nil }
        return Package(uapiPackageDetail: jsonPackage)
    }
    
    func getFilename(whichServer: String, theServer: String, base64Creds: String, theEndpoint: String, theEndpointID: Int, skip: Bool, currentTry: Int, completion: @escaping (_ result: (Int,String)) -> Void) {

        if skip || WipeData.state.on {
            completion((theEndpointID,""))
            print("[PackagesDelegate.getFilename] skip filename lookup")
            return
        }
        let theServerUrl = (whichServer == "source") ? JamfProServer.source:JamfProServer.destination
                
            let maxTries   = 4
            let getRecordQ = OperationQueue()
        
            URLCache.shared.removeAllCachedResponses()
            var existingDestUrl = ""
            
            existingDestUrl = "\(theServer)/JSSResource/\(theEndpoint)/id/\(theEndpointID)"
            existingDestUrl = existingDestUrl.urlFix
            
            WriteToLog.shared.message(stringOfText: "[PackagesDelegate.getFilename] Get filename for package the following package: \(existingDestUrl)")

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
                                WriteToLog.shared.message(stringOfText: "[PackagesDelegate.getFilename] jsonRequest: \(String(describing: jsonRequest.url!))")
                                WriteToLog.shared.message(stringOfText: "[PackagesDelegate.getFilename] response: \(String(describing: response))")
                                if let _ = response as? HTTPURLResponse {
                                    WriteToLog.shared.message(stringOfText: "[PackagesDelegate.getFilename] data: \(String(describing: String(data:data!, encoding: .utf8)))\n")
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
                                    WriteToLog.shared.message(stringOfText: "[PackagesDelegate.getFilename] error HTTP Status Code: \(httpResponse.statusCode)")
                                    //                        print("[PackagesDelegate.getFilename] error HTTP Status Code: \(httpResponse.statusCode)")
                                    completion((httpResponse.statusCode,""))
                                    
                                }
                            } else {
                                WriteToLog.shared.message(stringOfText: "[PackagesDelegate.getFilename] error with response for package ID \(theEndpointID) from \(String(describing: jsonRequest.url!))")
                                //                    print("[PackagesDelegate.getFilename] response error for package ID \(theEndpointID) on try \(currentTry)")
                                if currentTry < maxTries {
                                    self.getFilename(whichServer: whichServer, theServer: theServer, base64Creds: base64Creds, theEndpoint: "packages", theEndpointID: theEndpointID, skip: false, currentTry: currentTry+1) {
                                        (result: (Int,String)) in
                                        let (resultCode,returnedName) = result
                                        //                            print("[PackagesDelegate.getFilename] got filename (\(returnedName)) for package ID \(theEndpointID) on try \(currentTry+1)")
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
//        }
    }
    
    func filenameIdDict(whichServer: String, theServer: String, base64Creds: String, currentPackageIDsNames: [Int:String], currentPackageNamesIDs: [String:Int], currentDuplicates: [String:[String]], currentTry: Int, maxTries: Int, completion: @escaping (_ result: [String:Int]) -> Void) {
        
//        print("[PackageDelegate.filenameIdDict] lookup attempt \(currentTry) of \(maxTries)")
        if WipeData.state.on {
            completion(currentPackageNamesIDs)
            return
        }
        
        ExistingPackages.shared.packageIDsNames = currentPackageIDsNames
        var existingNameId        = currentPackageNamesIDs
        var duplicatePackagesDict = currentDuplicates
        
        var lookupCount = 0
        
        let packageCount = ExistingPackages.shared.packageIDsNames.count
        
        print("filenameIdDict server: \(whichServer)")
        print("           the server: \(theServer)")
        
        var i = 0
        ExistingPackages.shared.packageGetsPending = 0
        packageGetQ.async { [self] in
            while i < packageCount {
                if ExistingPackages.shared.packageGetsPending < maxConcurrentThreads && ExistingPackages.shared.packageIDsNames.count > 0 {
                    let (packageID, packageName) = ExistingPackages.shared.packageIDsNames.popFirst()!
                    i += 1
                    ExistingPackages.shared.packageGetsPending += 1

                        getFilename(whichServer: whichServer, theServer: theServer, base64Creds: base64Creds, theEndpoint: "packages", theEndpointID: packageID, skip: false, currentTry: 3) { [self]
                            (result: (Int,String)) in
                            ExistingPackages.shared.packageGetsPending -= 1
                            lookupCount += 1
                            //                print("[PackageDelegate.filenameIdDict] destRecord: \(result)")
                            let (resultCode,packageFilename) = result
                            
                            print("[getFilename] looked up: \(lookupCount) of \(packageCount)")
                            print("[getFilename] packageFilename: \(packageFilename) server: \(theServer)")
                            WriteToLog.shared.message(stringOfText: "[PackagesDelegate.getFilename] fetched \(lookupCount) of \(packageCount) - packageFilename: \(packageFilename) server: \(theServer)")
                            if pref.httpSuccess.contains(resultCode) {
                                // found name, remove from list
                                ExistingPackages.shared.packageIDsNames[packageID] = nil
                                
                                if packageFilename != "" && existingNameId[packageFilename] == nil {
                                    //                        print("add package to dict")
                                    //                      print("[PackageDelegate.filenameIdDict] add \(packageFilename) to package dict")
                                    existingNameId[packageFilename]        = packageID
                                    // used to check for duplicates: duplicatePackagesDict[packageFilename].count > 1?
                                    duplicatePackagesDict[packageFilename] = [packageName]
                                    //                      WriteToLog.shared.message(stringOfText: "[PackageDelegate.filenameIdDict] Duplicate filename found on \(self.dest_jp_server): \(packageFilename), id: \(packageID)")
                                } else {
                                    if packageFilename != "" {
                                        duplicatePackagesDict[packageFilename]!.append(packageName)
                                    } else {
                                        WriteToLog.shared.message(stringOfText: "[PackageDelegate.filenameIdDict] Failed to lookup filename for \(packageName)")
                                    }
                                    
                                    if WipeData.state.on {
                                        existingNameId[packageName] = packageID
                                    }
                                }
                            } else {  // if pref.httpSuccess.contains(resultCode) - end
                                //                  print("[PackageDelegate.filenameIdDict] failed looking up \(packageName)")
                                WriteToLog.shared.message(stringOfText: "[PackageDelegate.filenameIdDict] Failed to lookup \(packageName).  Status code: \(resultCode)")
                            }
                            // looked up last package in list
                            //                print("           currentTry: \(currentTry)")
                            //                print("             maxTries: \(maxTries+1)")
                            //                print("ExistingPackages.shared.packageIDsNames.count: \(ExistingPackages.shared.packageIDsNames.count)")
                            JamfProServer.pkgsNotFound = ExistingPackages.shared.packageIDsNames.count
                            if lookupCount == packageCount {
                                //                    print("[PackageDelegate.filenameIdDict] done looking up packages on \(theServer)")
                                if currentTry < maxTries+1 && ExistingPackages.shared.packageIDsNames.count > 0 {
                                    WriteToLog.shared.message(stringOfText: "[PackageDelegate.filenameIdDict] \(ExistingPackages.shared.packageIDsNames.count) filename(s) were not found.  Retry attempt \(currentTry)")
                                    filenameIdDict(whichServer: whichServer, theServer: theServer, base64Creds: base64Creds, currentPackageIDsNames: ExistingPackages.shared.packageIDsNames, currentPackageNamesIDs: existingNameId, currentDuplicates: duplicatePackagesDict, currentTry: currentTry+1, maxTries: maxTries) {
                                        (result: [String:Int]) in
                                        WriteToLog.shared.message(stringOfText: "[PackageDelegate.filenameIdDict] returned from retry \(currentTry)")
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
                            }   // if lookupCount == ExistingPackages.shared.packageIDsNames.count - end
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
            
            if !WipeData.state.on {
                WriteToLog.shared.message(stringOfText: "[PackageDelegate.filenameIdDict] Duplicate references to the same package were found on \(theServer)\n\(message)")
                let theButton = Alert.shared.display(header: "Warning:", message: "Several packages on \(theServer), having unique display names, are linked to a single file.  Check the log for 'Duplicate references to the same package' for details.", secondButton: "Stop")
                if theButton == "Stop" {
                    pref.stopMigration = true
                }
            }
//                            WriteToLog.shared.message(stringOfText: "[PackageDelegate.filenameIdDict] Duplicate references to the same package were found on \(theServer)\n\(message)")
        }
    }
}
