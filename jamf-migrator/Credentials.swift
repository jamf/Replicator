//
//  credentials.swift
//  based on: https://gist.github.com/jeffrafter/6dc43c3341e12cf4e359092dc8c56f33
//  jamf-migrator
//
//  Created by Leslie Helou on 2/7/18.
//  Copyright © 2018 jamf. All rights reserved.
//

import Security
import Foundation

class Credentials {
    func save(_ service: String, account: String, data: String) {
        var item: SecKeychainItem? = nil
        
        var status = SecKeychainFindGenericPassword(
            nil,
            UInt32(service.utf8.count),
            service,
            UInt32(account.utf8.count),
            account,
            nil,
            nil,
            &item)
        
        if status != noErr && status != errSecItemNotFound {
            print("Error finding keychain item to modify: \(status), \(String(describing: SecCopyErrorMessageString(status, nil)))")
            return
        }
        
        if item != nil {
            status = SecKeychainItemModifyContent(item!, nil, UInt32(data.utf8.count), data)
        } else {
            status = SecKeychainAddGenericPassword(
                nil,
                UInt32(service.utf8.count),
                service,
                UInt32(account.utf8.count),
                account,
                UInt32(data.utf8.count),
                data,
                nil)
        }
        
        if status != noErr {
            print("Error setting keychain item: \(String(describing: SecCopyErrorMessageString(status, nil)))")
        }
    }
    
    func retrieve(_ service: String, account: String) -> String? {
        var passwordLength: UInt32 = 0
        var password: UnsafeMutableRawPointer? = nil
        
        let status = SecKeychainFindGenericPassword(
            nil,
            UInt32(service.utf8.count),
            service,
            UInt32(account.utf8.count),
            account,
            &passwordLength,
            &password,
            nil)
        
        if status == errSecSuccess {
            guard password != nil else { return nil }
            let result = NSString(bytes: password!, length: Int(passwordLength), encoding: String.Encoding.utf8.rawValue) as String?
            SecKeychainItemFreeContent(nil, password)
            return result
        }
        
        return nil
    }
}
