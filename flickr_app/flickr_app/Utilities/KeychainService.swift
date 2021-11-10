//
//  Keychain Service.swift
//  flickr_app
//
//  Created by Andrew Masters on 10/29/21.
//

import Foundation
import CryptoKit
import SwiftKeychainWrapper

// Store Sensitive User Data in Keychain
class KeychainService {
    func saveData(key: String, value: String) -> Bool{
        print(key)
        return KeychainWrapper.standard.set(value, forKey: key)
    }
    func retrieveData(key: String) -> String {
        return KeychainWrapper.standard.string(forKey: key) ?? ""
    }
    func deleteData(key: String) -> Bool {
        return KeychainWrapper.standard.removeObject(forKey: key)
    }
}
