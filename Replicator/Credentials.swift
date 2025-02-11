//
//  Credentials.swift
//  Replicator
//
//  Created by Leslie Helou on 9/20/19.
//  Copyright 2024 Jamf. All rights reserved.
//

import Foundation
import Security

let kSecAttrAccountString          = NSString(format: kSecAttrAccount)
let kSecValueDataString            = NSString(format: kSecValueData)
let kSecClassGenericPasswordString = NSString(format: kSecClassGenericPassword)
let keychainQ                      = DispatchQueue(label: "com.jamf.creds", qos: DispatchQoS.background)

let sharedPrefix                   = "JPMA"
let accessGroup                    = "PS2F6S478M.jamfie.SharedJPMA"
var credentialsWhichServer         = ""

class Credentials {
    
    static let shared = Credentials()
    
    var userPassDict = [String:String]()
    
    private func theKeychainQuery(operation: String, theService: String, account: String = "", password: Data = Data()) -> [String: Any] {
        let useLoginKeychainPref = userDefaults.integer(forKey: "useLoginKeychain") == 1 ? true : false
        var useLoginKeychain = false
        var keychainQuery = [String: Any]()
        
        var loginKeychain: SecKeychain?
        let statusKeychain = SecKeychainOpen("login.keychain-db", &loginKeychain)
        
        if let loginKeychain = loginKeychain, statusKeychain == errSecSuccess, useLoginKeychainPref {
            useLoginKeychain = true
        }
        
        switch operation {
        case "save":
            if useLoginKeychain {
                print("[Credentials] Saving to Login Keychain...")
                keychainQuery = [kSecClass as String: kSecClassGenericPassword,
                                kSecAttrService as String: theService,
//                                kSecAttrAccessGroup as String: accessGroup,
                                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked, // Ensure access after login
                                kSecUseKeychain as String: loginKeychain as Any, // Explicitly store in Login Keychain
                                kSecAttrAccount as String: account,
                                kSecValueData as String: password]
            } else {
                print("[Credentials] Saving to default Keychain...")
                keychainQuery = [kSecClass as String: kSecClassGenericPassword,
                                kSecAttrService as String: theService,
                                kSecAttrAccessGroup as String: accessGroup,
                                kSecUseDataProtectionKeychain as String: true,
                                kSecAttrAccount as String: account,
                                kSecValueData as String: password]
            }
        case "lookup", "checkExisting":
            if useLoginKeychain {
                print("[Credentials] check Login Keychain...")
                keychainQuery = [kSecClass as String: kSecClassGenericPasswordString,
                                 kSecAttrService as String: theService,
//                                 kSecAttrAccessGroup as String: accessGroup,
//                                 kSecUseKeychain as String: loginKeychain as Any, // use Login Keychain
//                                 kSecMatchLimit as String: kSecMatchLimitAll,
                                 kSecReturnAttributes as String: true,
                                 kSecReturnData as String: true]
            } else {
                print("[Credentials] check default Keychain...")
                keychainQuery = [kSecClass as String: kSecClassGenericPasswordString,
                                 kSecAttrService as String: theService,
                                 kSecAttrAccessGroup as String: accessGroup,
                                 kSecUseDataProtectionKeychain as String: true,
//                                 kSecMatchLimit as String: kSecMatchLimitAll,
                                 kSecReturnAttributes as String: true,
                                 kSecReturnData as String: true]
                if operation == "lookup"{
                    keychainQuery[kSecMatchLimit as String] = kSecMatchLimitAll
                } else {
                    keychainQuery[kSecMatchLimit as String] = kSecMatchLimitOne
                }
            }
        default:
            break
        }
        
        if !account.isEmpty {
            keychainQuery[kSecAttrAccount as String] = account
        }
        return keychainQuery
    }
    
    func save(service: String, account: String, credential: String, whichServer: String = "") {
        if service != "" && account != "" && service.first != "/" {
            var theService = service
//            var useLoginKeychainPref = userDefaults.integer(forKey: "useLoginKeychain") == 1 ? true : false
//            var useLoginKeychain = false
//            var keychainQuery = [String: Any]()
//            
//            var loginKeychain: SecKeychain?
//            let statusKeychain = SecKeychainOpen("login.keychain-db", &loginKeychain)
//            
//            if let loginKeychain = loginKeychain, statusKeychain == errSecSuccess, useLoginKeychainPref {
//                useLoginKeychain = true
//            }
            
            switch whichServer {
            case "source":
                theService = ( JamfProServer.sourceUseApiClient == 1 ) ? "\(AppInfo.name)-apiClient-" + service:"\(sharedPrefix)-\(service)"
            case "dest":
                theService = ( JamfProServer.destUseApiClient == 1 ) ? "\(AppInfo.name)-apiClient-" + service:"\(sharedPrefix)-\(service)"
            default:
                break
            }

            if let password = credential.data(using: String.Encoding.utf8) {
//                if useLoginKeychain {
//                    print("[Credentials] Saving to Login Keychain...")
//                    keychainQuery = [kSecClass as String: kSecClassGenericPassword,
//                                    kSecAttrService as String: theService,
//                                    kSecAttrAccessGroup as String: accessGroup,
//                                    kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked, // Ensure access after login
//                                    kSecUseKeychain as String: loginKeychain as Any, // Explicitly store in Login Keychain
//                                    kSecAttrAccount as String: account,
//                                    kSecValueData as String: password]
//                } else {
//                    print("[Credentials] Saving to default Keychain...")
//                    keychainQuery = [kSecClass as String: kSecClassGenericPassword,
//                                                        kSecAttrService as String: theService,
//                                                        kSecAttrAccessGroup as String: accessGroup,
//                                                        kSecUseDataProtectionKeychain as String: true,
//                                                        kSecAttrAccount as String: account,
//                                                        kSecValueData as String: password]
//                }
                let keychainQuery = theKeychainQuery(operation: "save", theService: theService, account: account, password: password)
                keychainQ.async { [self] in
                    
                    // see if credentials already exist for server
                    let accountCheck = checkExisting(service: theService, account: account)
                    if accountCheck.count == 1 {
                        if credential != accountCheck[account] {
                            // credentials already exist, try to update
                            let updateStatus = SecItemUpdate(keychainQuery as CFDictionary, [kSecValueDataString:password] as [NSString : Any] as CFDictionary)
                            if LogLevel.debug { WriteToLog.shared.message("[Credentials.save] updateStatus for \(account) result: \(updateStatus)") }
                            if updateStatus == 0 {
                                WriteToLog.shared.message("keychain item for service \(theService), account \(account), has been updated.")
                            } else {
                                WriteToLog.shared.message("keychain item for service \(theService), account \(account), failed to update.")
                            }
                        } else {
                            if LogLevel.debug { WriteToLog.shared.message("[Credentials.save] password for \(account) is up-to-date") }
                        }
                    } else {
                        // try to add new credentials
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
                    }
                }
            }
        }
    }   // func save - end
    
    private func checkExisting(service: String, account: String) -> [String:String] {
        
        print("[Credentials.oldItemLookup] start search for: \(service)")
        
        userPassDict.removeAll()
//        let keychainQuery: [String: Any] = [kSecClass as String: kSecClassGenericPasswordString,
//                                            kSecAttrAccessGroup as String: accessGroup,
//                                            kSecAttrService as String: service,
//                                            kSecAttrAccount as String: account,
//                                            kSecMatchLimit as String: kSecMatchLimitOne,
//                                            kSecReturnAttributes as String: true,
//                                            kSecReturnData as String: true]
//        
        let keychainQuery = theKeychainQuery(operation: "checkExisting", theService: service, account: account)
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(keychainQuery as CFDictionary, &item)
        guard status != errSecItemNotFound else {
            print("[Credentials.checkExisting] lookup error occurred: \(status.description)")
            return [:]
        }
        guard status == errSecSuccess else { return [:] }
        
        guard let existingItem = item as? [String : Any],
            let passwordData = existingItem[kSecValueData as String] as? Data,
//            let account = existingItem[kSecAttrAccount as String] as? String,
            let password = String(data: passwordData, encoding: String.Encoding.utf8)
        else {
            return [:]
        }
        userPassDict[account] = password
        return userPassDict
    }
    
    func retrieve(service: String, account: String, whichServer: String = "") -> [String:String] {
        
        print("[Credentials.retrieve]     start search for: \(service)")
        print("[Credentials.retrieve] JamfProServer.source: \(JamfProServer.source)")
        
        if JamfProServer.source != JamfProServer.destination {
            credentialsWhichServer = ( service == JamfProServer.source.fqdnFromUrl ) ? "source":"destination"
        }
        JamfProServer.validToken[credentialsWhichServer] = false
        
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
        
        // look for common keychain item
        keychainResult = itemLookup(service: theService)
        
        return keychainResult
    }
    
    private func itemLookup(service: String) -> [String:String] {
        
        print("[Credentials.itemLookup] start search for: \(service)")
        
        userPassDict.removeAll()
//        let keychainQuery: [String: Any] = [kSecClass as String: kSecClassGenericPasswordString,
//                                            kSecAttrService as String: service,
//                                            kSecAttrAccessGroup as String: accessGroup,
//                                            kSecUseDataProtectionKeychain as String: true,
//                                            kSecMatchLimit as String: kSecMatchLimitAll,
//                                            kSecReturnAttributes as String: true,
//                                            kSecReturnData as String: true]
        
        let keychainQuery = theKeychainQuery(operation: "lookup", theService: service)
        print("[Credentials.itemLookup] keychainQuery: \(keychainQuery)")
        
        var items_ref: CFTypeRef?
        
        let status = SecItemCopyMatching(keychainQuery as CFDictionary, &items_ref)

        guard status != errSecItemNotFound else {
            print("[Credentials.itemLookup] lookup error occurred for \(service): \(status.description)")
            return [:]
            
        }
        guard status == errSecSuccess else {
            print("[Credentials.itemLookup] status error occurred for \(service): \(status.description)")
            return [:]
        }
        
        if userDefaults.integer(forKey: "useLoginKeychain") == 1 {
            guard let items = items_ref as? [String: Any] else {
                print("[Credentials.itemLookup] unable to read keychain item: \(service)")
                return [:]
            }
            if let account = items[kSecAttrAccount as String] as? String, let passwordData = items[kSecValueData as String] as? Data {
                let password = String(data: passwordData, encoding: String.Encoding.utf8)
                userPassDict[account] = password ?? ""
            }
        } else {
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
        }

        print("[Credentials.itemLookup] keychain item count: \(userPassDict.count) for \(service)")
//        print("[Credentials.itemLookup] userPassDict: \(userPassDict)")
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
