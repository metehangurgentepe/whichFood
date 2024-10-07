//
//  KeychainManager.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 13.11.2023.
//

import Foundation
import UIKit

class KeychainManager {
    static let service = "com.whichFood.keychainManager"
    
    static var deviceId: String? {
        return UIDevice.current.identifierForVendor?.uuidString
    }
    
    static func save(account: String) throws{
        let query: [String: AnyObject] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service as AnyObject,
            kSecAttrAccount as String: account  as AnyObject,
            kSecValueData as String: deviceId?.data(using: .utf8) as AnyObject
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status != errSecDuplicateItem else {
            throw KeychainError.duplicateEntry
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }
    }
    
    static func get(account: String) -> Data? {
        let query: [String: AnyObject] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service as AnyObject,
            kSecAttrAccount as String: account  as AnyObject,
            kSecReturnData as String: kCFBooleanTrue,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        return result as? Data
    }
}
enum KeychainError: Error {
    case duplicateEntry
    case unknown(OSStatus)
}
