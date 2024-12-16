//
//  Untitled.swift
//  Replicator
//
//  Created by leslie on 12/6/24.
//  Copyright © 2024 Jamf. All rights reserved.
//

import Foundation

var duplicatePackages      = false
var duplicatePackagesDict  = [String:[String]]()
//var failedPkgNameLookup    = [String]()

class ObjectDelegate: NSObject, URLSessionDelegate {
    
    static let shared    = ObjectDelegate()
 
    func getAll(whichServer: String, endpoint: String, completion: @escaping (_ result: [Any]) -> Void) {
        
        if Counter.shared.crud[endpoint] == nil {
            Counter.shared.crud[endpoint]    = ["create":0, "update":0, "fail":0, "skipped":0, "total":0]
            Counter.shared.summary[endpoint] = ["create":[], "update":[], "fail":[]]
        }
        
        switch endpoint {
        case "packages":
            duplicatePackages = false
            duplicatePackagesDict.removeAll()
            Jpapi.shared.getAllDelegate(whichServer: whichServer, theEndpoint: endpoint, whichPage: 0) {
                result in
                
                completion(result)
            }
        case "patch-software-title-configurations", "patchmanagement":
            Jpapi.shared.get(whichServer: whichServer, theEndpoint: endpoint) {
                result in
                completion(result as [Any])
            }
        default:
            Json.shared.getRecord(whichServer: whichServer, base64Creds: "", theEndpoint: endpoint) {
                (result: Any) in
//                print("[ObjectDelegate.getAll] default - \(endpoint): \(result)")
                completion([result])
            }
        }
    }
    
}

