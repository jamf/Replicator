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

class Credentials {
    
    func save(service: String, account: String, data: String, whichServer: String = "") {
        if service != "" && service.first != "/" {
            var theService = service
            
            switch whichServer {
            case "source":
                if JamfProServer.sourceUseApiClient == 1 {
                    theService = "apiClient-" + theService
                }
            case "dest":
                if JamfProServer.destUseApiClient == 1 {
                    theService = "apiClient-" + theService
                }
            default:
                break
            }
            
//            if JamfProServer.sourceApiClient + JamfProServer.destApiClient != 0 {
//                theService = theService + "-apiClient"
//            }
            
            var keychainName = ( whichServer == "" ) ?  theService:"JamfProApps-\(theService)"
//            let keychainName = "JamfProApps-\(theService)"
            if let password = data.data(using: String.Encoding.utf8) {
                keychainQ.async { [self] in
                    var keychainQuery: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                                        kSecAttrService as String: keychainName,
                                                        kSecAttrAccount as String: account,
                                                        kSecValueData as String: password]
                    
                    // see if credentials already exist for server
                    let accountCheck = retrieve(service: keychainName)
                    if accountCheck.count == 0 {
                        // try to add new credentials, if account exists we'll try updating it
                        let addStatus = SecItemAdd(keychainQuery as CFDictionary, nil)
                        if (addStatus != errSecSuccess) {
                            if let addErr = SecCopyErrorMessageString(addStatus, nil) {
                                print("[addStatus] Write failed for new credentials: \(addErr)")
                            }
                        }
                    } else {
                        // credentials already exist, try to update
                        keychainQuery = [kSecClass as String: kSecClassGenericPasswordString,
                                         kSecAttrService as String: keychainName,
                                         kSecMatchLimit as String: kSecMatchLimitOne,
                                         kSecReturnAttributes as String: true]
                        let updateStatus = SecItemUpdate(keychainQuery as CFDictionary, [kSecAttrAccountString:account,kSecValueDataString:password] as [NSString : Any] as CFDictionary)
                        if (updateStatus != errSecSuccess) {
                            if let updateErr = SecCopyErrorMessageString(updateStatus, nil) {
                                print("[updateStatus] Update failed for existing credentials: \(updateErr)")
                            }
                        }
                    }
            }
            }
        }
    }   // func save - end
    
    func retrieve(service: String, whichServer: String = "") -> [String] {
        var keychainResult = [String]()
        var theService = service
        
//        print("[credentials] JamfProServer.sourceApiClient: \(JamfProServer.sourceUseApiClient)")
        
        switch whichServer {
        case "source":
            if JamfProServer.sourceUseApiClient == 1 {
                theService = "apiClient-" + theService
            }
        case "dest":
            if JamfProServer.destUseApiClient == 1 {
                theService = "apiClient-" + theService
            }
        default:
            break
        }
        
        
        var keychainName   = ( whichServer == "" ) ?  theService:"JamfProApps-\(theService)"
//        print("[credentials] keychainName: \(keychainName)")
        // look for common keychain item
        keychainResult = itemLookup(service: keychainName)
        // look for legacy keychain item
        if keychainResult.count < 2 {
            keychainName   = "\(prefix) - \(theService)"
            keychainResult = itemLookup(service: keychainName)
        }
        
        return keychainResult
    }
    
    private func itemLookup(service: String) -> [String] {
        
        var storedCreds = [String]()
        
        let keychainQuery: [String: Any] = [kSecClass as String: kSecClassGenericPasswordString,
                                            kSecAttrService as String: service,
                                            kSecMatchLimit as String: kSecMatchLimitOne,
                                            kSecReturnAttributes as String: true,
                                            kSecReturnData as String: true]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(keychainQuery as CFDictionary, &item)
        guard status != errSecItemNotFound else { return [] }
        guard status == errSecSuccess else { return [] }
        
        guard let existingItem = item as? [String : Any],
            let passwordData = existingItem[kSecValueData as String] as? Data,
            let account = existingItem[kSecAttrAccount as String] as? String,
            let password = String(data: passwordData, encoding: String.Encoding.utf8)
            else {
                return []
        }
        storedCreds.append(account)
        storedCreds.append(password)
        return storedCreds
    }
}
