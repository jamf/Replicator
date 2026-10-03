//
//  AppInstallersDelegate.swift
//  Replicator
//
//  Created by Jordy Thery on 10/3/26.
//  Copyright © 2026 Jamf. All rights reserved.
//

import Cocoa

class AppInstallersDelegate: NSObject {

    static let shared = AppInstallersDelegate()
    var messageDelegate: SendMessageDelegate?

    func updateViewController(_ text: String) {
        logFunctionCall()
        messageDelegate?.sendMessage(text)
    }

    // fetch categories, sites, and computer groups used to remap ids of an App Installer deployment
    func getDependencies(whichServer: String, completion: @escaping (_ result: String) -> Void) {
        logFunctionCall()
        if WipeData.state.on {
            completion("skipped")
            return
        }
        WriteToLog.shared.message("[getDependencies] fetching category records from \(whichServer) server")
        self.updateViewController("fetching category records from \(whichServer) server")
        Jpapi.shared.getAllDelegate(whichServer: whichServer, theEndpoint: "categories", whichPage: 0) { result in
            WriteToLog.shared.message("[getDependencies] fetching site records from \(whichServer) server")
            self.updateViewController("fetching site records from \(whichServer) server")
            Jpapi.shared.action(whichServer: whichServer, endpoint: "sites", apiData: [:], id: "", token: "", method: "GET") { result in

                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: result["sites"] as Any)
                    if whichServer == "source" {
                        JamfProSites.source = try JSONDecoder().decode([Site].self, from: jsonData)
                    } else {
                        if let destSites = try? JSONDecoder().decode([Site].self, from: jsonData) {
                            JamfProSites.destination = destSites
                        }
                    }
                } catch {
                    WriteToLog.shared.message("[getDependencies] fetching site records failed from \(whichServer) server")
                }

                WriteToLog.shared.message("[getDependencies] fetching computer group records from \(whichServer) server")
                self.updateViewController("fetching computer group records from \(whichServer) server")
                Json.shared.getRecord(whichServer: whichServer, base64Creds: "", theEndpoint: "computergroups") { (objectRecord: Any) in
                    var computerGroups = [NameId]()
                    if let objectJson = objectRecord as? [String: Any], let groupsArray = objectJson["computer_groups"] as? [[String: Any]] {
                        for theGroup in groupsArray {
                            if let id = theGroup["id"] as? Int, let name = theGroup["name"] as? String {
                                computerGroups.append(NameId(id: id, name: name))
                            }
                        }
                    } else {
                        WriteToLog.shared.message("[getDependencies] fetching computer group records failed from \(whichServer) server")
                    }
                    if whichServer == "source" {
                        ComputerGroups.source = computerGroups
                    } else {
                        ComputerGroups.destination = computerGroups
                    }
                    completion("finished getting app installer dependencies from the \(whichServer) server")
                }
            }
        }
    }
}
