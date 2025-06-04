//
//  ObjectDelegate.swift
//  Replicator
//
//  Created by leslie on 12/6/24.
//  Copyright © 2024 Jamf. All rights reserved.
//

import Foundation
import OSLog

var duplicatePackages      = false
var duplicatePackagesDict  = [String:[String]]()

class ObjectDelegate: NSObject, URLSessionDelegate {
    
    static let shared    = ObjectDelegate()
 
    func getAll(whichServer: String, endpoint: String, completion: @escaping (_ result: [Any]) -> Void) {
        print("[ObjectDelegate] getAll \(whichServer) server, endpoint: \(endpoint)")
        
        logFunctionCall()
        existingObjects.removeAll()
        
        if Counter.shared.crud[endpoint] == nil {
            Counter.shared.crud[endpoint]    = ["create":0, "update":0, "fail":0, "skipped":0, "total":0]
            Counter.shared.summary[endpoint] = ["create":[], "update":[], "fail":[]]
        }
        
        switch endpoint {
        case "packages", "api-roles", "api-integrations":
            duplicatePackages = false
            duplicatePackagesDict.removeAll()
            Jpapi.shared.getAllDelegate(whichServer: (WipeData.state.on ? "dest":whichServer), theEndpoint: endpoint, whichPage: 0) {
                result in
                completion(result)
            }
        case "patch-software-title-configurations":
            Jpapi.shared.get(whichServer: (WipeData.state.on ? "dest":whichServer), theEndpoint: endpoint) {
                result in
                completion(result as [Any])
            }
        default:
            Json.shared.getRecord(whichServer: (WipeData.state.on ? "dest":whichServer), base64Creds: "", theEndpoint: endpoint) {
                (result: Any) in
//                print("[ObjectDelegate.getAll] default - \(endpoint): \(result)")
                completion([result])
            }
        }
    }
}

