//
//  Credentials.swift
//  jamf-migrator
//
//  Created by Leslie Helou on 9/20/19.
//  Copyright © 2019 jamf. All rights reserved.
//

import Foundation
import Security

let kSecAttrAccountString          = NSString(format: kSecAttrAccount)
let kSecValueDataString            = NSString(format: kSecValueData)
let kSecClassGenericPasswordString = NSString(format: kSecClassGenericPassword)
let keychainQ                      = DispatchQueue(label: "com.jamf.creds", qos: DispatchQoS.background)
let prefix                         = "migrator"
let sharedPrefix                   = "JPMA"
let accessGroup                    = "PS2F6S478M.jamfie.SharedJPMA"

class Credentials {
    
    var userPassDict = [String:String]()
    
    func save(service: String, account: String, credential: String, whichServer: String = "") {
        if service != "" && account != "" && service.first != "/" {
            var theService = service
            
            switch whichServer {
            case "source":
                theService = ( JamfProServer.sourceUseApiClient == 1 ) ? "\(AppInfo.name)-apiClient-" + service:"\(sharedPrefix)-\(service)"
//                if JamfProServer.sourceUseApiClient == 1 {
//                    theService = "\(AppInfo.name)-apiClient-" + theService
//                }
            case "dest":
                theService = ( JamfProServer.destUseApiClient == 1 ) ? "\(AppInfo.name)-apiClient-" + service:"\(sharedPrefix)-\(service)"
//                if JamfProServer.destUseApiClient == 1 {
//                    theService = "\(AppInfo.name)-apiClient-" + theService
//                }
            default:
                break
            }
            
//            let keychainItemName = ( whichServer == "" ) ? theService:"JPMA-\(theService)"
            
//            print("[Credentials.save] save/update keychain item \(keychainItemName)")

            if let password = credential.data(using: String.Encoding.utf8) {
                keychainQ.async { [self] in
                    var keychainQuery: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                                        kSecAttrService as String: theService,
                                                        kSecAttrAccessGroup as String: accessGroup,
                                                        kSecUseDataProtectionKeychain as String: true,
                                                        kSecAttrAccount as String: account,
                                                        kSecValueData as String: password]
                    
                    // see if credentials already exist for server
                    let accountCheck = retrieve(service: theService, account: account)
                    if accountCheck.count == 0 {
                        // try to add new credentials, if account exists we'll try updating it
                        let addStatus = SecItemAdd(keychainQuery as CFDictionary, nil)
                        if (addStatus != errSecSuccess) {
                            if let addErr = SecCopyErrorMessageString(addStatus, nil) {
                                print("[addStatus] Write failed for new credentials: \(addErr)")
                                let deleteStatus = SecItemDelete(keychainQuery as CFDictionary)
                                print("[Credentials.save] the deleteStatus: \(deleteStatus)")
                                sleep(1)
                                let addStatus = SecItemAdd(keychainQuery as CFDictionary, nil)
                                if (addStatus != errSecSuccess) {
                                    if let addErr = SecCopyErrorMessageString(addStatus, nil) {
                                        print("[addStatus] Write failed for new credentials after deleting: \(addErr)")
                                    }
                                }
                            }
                        }
                    } else {
                        // credentials already exist, try to update
                        keychainQuery = [kSecClass as String: kSecClassGenericPasswordString,
                                         kSecAttrService as String: theService,
                                         kSecMatchLimit as String: kSecMatchLimitOne,
                                         kSecReturnAttributes as String: true]
                        
                        for (username, password) in accountCheck {
                            if account != username || credential != password {
                                // credentials already exist, try to update
                                if account == username {
                                    let updateStatus = SecItemUpdate(keychainQuery as CFDictionary, [kSecValueDataString:password] as [NSString : Any] as CFDictionary)
//                                    print("[Credentials.save] updateStatus result: \(updateStatus)")
                                } //else {
////                                    print("[addStatus] save password for: \(account)")
//                                    let addStatus = SecItemAdd(keychainQuery as CFDictionary, nil)
//                                    if (addStatus != errSecSuccess) {
//                                        if let addErr = SecCopyErrorMessageString(addStatus, nil) {
//                                            print("[addStatus] Write failed for new credentials: \(addErr)")
//                                        }
//                                    }
//                                }
                            }
                        }
                    }
                }
            }
        }
    }   // func save - end
    
    func retrieve(service: String, account: String, whichServer: String = "") -> [String:String] {
        
//        print("[Credentials.retrieve] start search for: \(service)")
        
        // running from the command line
        if !setting.fullGUI && (JamfProServer.sourceApiClient["id"] != "" && whichServer == "source" || JamfProServer.destApiClient["id"] != "" && whichServer == "dest") {
            if whichServer == "source" {
                return["\(String(describing: JamfProServer.sourceApiClient["id"]!))":"\(String(describing: JamfProServer.sourceApiClient["secret"]!))"]
            } else if whichServer == "dest" {
                return["\(String(describing: JamfProServer.destApiClient["id"]!))":"\(String(describing: JamfProServer.destApiClient["secret"]!))"]
            }
            return [:]
        }
        
        var keychainResult = [String:String]()
        var theService = service
        
//        print("[credentials] JamfProServer.sourceApiClient: \(JamfProServer.sourceUseApiClient)")
        
        switch whichServer {
        case "source":
            theService = ( JamfProServer.sourceUseApiClient == 1 ) ? "\(AppInfo.name)-apiClient-" + service:"\(sharedPrefix)-\(service)"
        case "dest":
            theService = ( JamfProServer.destUseApiClient == 1 ) ? "\(AppInfo.name)-apiClient-" + service:"\(sharedPrefix)-\(service)"
        default:
            break
        }
//        print("[credentials] whichServer: \(whichServer), theService: \(theService)")
        
        userPassDict.removeAll()
        
//        var keychainItemName = ( whichServer == "" ) ?  theService:"JPMA-\(theService)"
//        print("[credentials] keychainItemName: \(keychainItemName)")
        // look for common keychain item
        keychainResult = itemLookup(service: theService)
        // look for legacy keychain item
        if keychainResult.count == 0 {
            switch whichServer {
            case "source":
                if JamfProServer.sourceUseApiClient == 1 {
                    return keychainResult
                }
            case "dest":
                if JamfProServer.destUseApiClient == 1 {
                    return keychainResult
                }
            default:
                break
            }
            theService = "\(prefix) - \(service)"
            keychainResult   = oldItemLookup(service: theService)
            if keychainResult.count == 0 {
                switch whichServer {
                case "source":
                    if JamfProServer.sourceUseApiClient == 1 {
                        return keychainResult
                    }
                case "dest":
                    if JamfProServer.destUseApiClient == 1 {
                        return keychainResult
                    }
                default:
                    break
                }
                theService = "\(prefix)-\(account)-\(service)"
                keychainResult   = oldItemLookup(service: theService)
                if keychainResult.count == 0 {
                    switch whichServer {
                    case "source":
                        theService = ( JamfProServer.sourceUseApiClient == 1 ) ? "apiClient-" + service:service
                    case "dest":
                        theService = ( JamfProServer.destUseApiClient == 1 ) ? "apiClient-" + service:service
                    default:
                        break
                    }
                    theService = "JamfProApps-\(theService)"
                    keychainResult   = itemLookup(service: theService)
                }
            }
        }
        
        return keychainResult
    }
    
    private func itemLookup(service: String) -> [String:String] {
        
        print("[Credentials.itemLookup] start search for: \(service)")
        
        userPassDict.removeAll()
        let keychainQuery: [String: Any] = [kSecClass as String: kSecClassGenericPasswordString,
                                            kSecAttrService as String: service,
                                            kSecAttrAccessGroup as String: accessGroup,
                                            kSecUseDataProtectionKeychain as String: true,
                                            kSecMatchLimit as String: kSecMatchLimitAll,
                                            kSecReturnAttributes as String: true,
                                            kSecReturnData as String: true]
        
        var items_ref: CFTypeRef?
        
        let status = SecItemCopyMatching(keychainQuery as CFDictionary, &items_ref)
//        let status = SecItemCopyMatching(keychainQuery as CFDictionary, &item)
        guard status != errSecItemNotFound else {
            print("[Credentials.itemLookup] lookup error occurred for \(service): \(status.description)")
            return [:]
            
        }
        guard status == errSecSuccess else { return [:] }
        
        guard let items = items_ref as? [[String: Any]] else {
            print("[Credentials.itemLookup] unable to read keychain item: \(service)")
            return [:]
        }
        for item in items {
            if let account = item[kSecAttrAccount as String] as? String, let passwordData = item[kSecValueData as String] as? Data {
                let password = String(data: passwordData, encoding: String.Encoding.utf8)
                userPassDict[account] = password ?? ""
            }
        }

//        print("[Credentials.itemLookup] keychain item count: \(userPassDict.count) for \(service)")
        return userPassDict
    }
    
    private func oldItemLookup(service: String) -> [String:String] {
        
        print("[Credentials.oldItemLookup] start search for: \(service)")
        
        userPassDict.removeAll()
        let keychainQuery: [String: Any] = [kSecClass as String: kSecClassGenericPasswordString,
                                            kSecAttrService as String: service,
                                            kSecMatchLimit as String: kSecMatchLimitOne,
                                            kSecReturnAttributes as String: true,
                                            kSecReturnData as String: true]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(keychainQuery as CFDictionary, &item)
        guard status != errSecItemNotFound else {
            print("[Credentials.oldItemLookup] lookup error occurred: \(status.description)")
            return [:]
        }
        guard status == errSecSuccess else { return [:] }
        
        guard let existingItem = item as? [String : Any],
            let passwordData = existingItem[kSecValueData as String] as? Data,
            let account = existingItem[kSecAttrAccount as String] as? String,
            let password = String(data: passwordData, encoding: String.Encoding.utf8)
            else {
            return [:]
        }
        userPassDict[account] = password
        return userPassDict
    }

}
