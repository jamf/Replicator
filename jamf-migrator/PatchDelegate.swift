//
//  PatchDelegate.swift
//  Replicator
//
//  Created by leslie on 11/9/24.
//  Copyright © 2024 Jamf. All rights reserved.
//

import Cocoa

class PatchDelegate: NSObject {
    
    static let shared = PatchDelegate()
    var messageDelegate: SendMessageDelegate?
    
    func updateViewController(_ text: String) {
        messageDelegate?.sendMessage(text)
    }
    
    func getDependencies(whichServer: String, completion: @escaping (_ result: String) -> Void) {
        print("[getEndpoints] fetch categories from \(whichServer) server")
        self.updateViewController("fetching categories from \(whichServer) server")
        Jpapi.shared.getAllDelegate(whichServer: whichServer, theEndpoint: "categories", whichPage: 0) { result in
            print("[getEndpoints] fetch sites from \(whichServer) server")
            self.updateViewController("fetching sites from \(whichServer) server")
            Jpapi.shared.action(whichServer: whichServer, endpoint: "sites", apiData: [:], id: "", token: "", method: "GET") { result in
                
//                print("[getEndpoints] sites from \(whichServer) server: \(result["sites"])")
                
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: result["sites"] as Any)
                    if whichServer == "source" {
                        JamfProSites.source = try JSONDecoder().decode([Site].self, from: jsonData)
                        for i in 0..<PatchTitleConfigurations.source.count {
                            PatchTitleConfigurations.source[i].siteName = JamfProSites.source.first(where: {$0.id == PatchTitleConfigurations.source[i].siteId})?.name ?? "NONE"
                        }
                    } else {
                        JamfProSites.destination = try JSONDecoder().decode([Site].self, from: jsonData)
                    }
                } catch {
                    print("[getEndpoints] sites failed from \(whichServer) server")
                }
                print("[getEndpoints] fetch policy-details from \(whichServer) server")
                self.updateViewController("fetching policy-details from \(whichServer) server")
                Jpapi.shared.getAllDelegate(whichServer: whichServer, theEndpoint: "policy-details", whichPage: 0) { result in
                    self.updateViewController("fetching packages from \(whichServer) server")
                    Jpapi.shared.getAllDelegate(whichServer: whichServer, theEndpoint: "packages", whichPage: 0) { result in
                        if whichServer == "source" || export.saveOnly {
                            completion("finished getting patch dependencies from the \(whichServer) server")
                        } else {
                            // patchinternalsources
                            print("[getEndpoints] fetch patchinternalsources from \(whichServer) server")
                            Jpapi.shared.action(whichServer: "dest", endpoint: "patchinternalsources", apiData: [:], id: "", token: "", method: "GET") { result in
                                print("[getEndpoints] result of patchinternalsources: \(result)")
                                let decoder = JSONDecoder()
                                if let patchInternalSources = result["patch_internal_sources"] as? [[String: Any]] {
                                    for theSourceJson in patchInternalSources {
                                        do {
                                            let jsonData = try JSONSerialization.data(withJSONObject: theSourceJson, options: [])
                                            let theSource = try decoder.decode(NameId.self, from: jsonData)
                                            PatchSource.destination.append(theSource)
                                        } catch {
                                            WriteToLog.shared.message(stringOfText: "[getDependencies] failed to parse patch internal sources")
                                        }
                                    }
                                }
                                completion("finished getting patch dependencies from the \(whichServer) server")
                            }
                        }
                    }
                }
            }
        }
    }
}
