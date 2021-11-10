//
//  UserData.swift
//  flickr_app
//
//  Created by Andrew Masters on 10/13/21.
//

import Foundation
import OAuthSwift
import CryptoKit

class User {
    
    var dataManager = DataManager()
    private var keychainService = KeychainService()
        
    var emptyClass: Bool = true
    var fullName: String! = ""
    var userName: String! = ""
    var userLocation: String! = ""
    var userDescription: String! = ""
    
    func loggedIn() -> Bool {
        if keychainService.retrieveData(key: "user_id").isEmpty {
            print("No User Exists")
            return false
        }
        print("User Exists")
        return true
    }
    
    // Setup the User for all the data that we want to display to the user
    func setUser(_ user_data: [String : String] = ["" : ""], completion: @escaping () -> Void) {
        
        if(!loggedIn() && user_data.count > 1){
            parseOAuthJSON(data: user_data)
        } else if emptyClass {
            // check existing token and add username
            dataManager.checkToken(completion: {result in
                let userJSON = result!["user"] as? [String : AnyObject]
                let usernameJSON = userJSON!["username"] as? [String : String]
                self.userName = usernameJSON!["_content"]!
            })
        }
        dataManager.downloadProfileData(completion: {result in
            self.parseProfileData(data: result)
            completion()
        })
        
        emptyClass = false
    }
    
    // Parse the Data given by the OAuth Authorizer
    func parseOAuthJSON(data: [String : String]){
        if let userName = data["username"] {
            self.userName = userName
        }
        if !keychainService.saveData(key: "user_token", value: data["oauth_token"]!) {
            print("token was not saved in keychain successfully")
        }
        if !keychainService.saveData(key: "user_id", value: data["user_nsid"]!) {
            print("id was not saved in keychain successfully")
        }
        if !keychainService.saveData(key: "user_secret", value: data["oauth_token_secret"]!) {
            print("secret was not saved in keychain successfully")
        }
    }
    
    // Parse the Data given by Flickr getProfile call
    func parseProfileData(data: [String : AnyObject]){
        if let firstName = data["first_name"] as? String {
            self.fullName = firstName
        }
        if let lastName = data["last_name"] as? String {
            if self.fullName.isEmpty {
                self.fullName = lastName
            } else {
                self.fullName += " " + lastName
            }
        }
        if let city = data["city"] as? String {
            self.userLocation = city
        }
        if let country = data["country"] as? String {
            if !self.userLocation.isEmpty {
                self.userLocation += ", " + country
            }
        }
        if self.userLocation.isEmpty {
            self.userLocation = "UNKNOWN"
        }
        
        let profile_description = data["profile_description"] as! String
        if profile_description.isEmpty {
            self.userDescription = " 'You have not set up a profile description' "
        }
    }
    
    
    func logOut() {
        if(loggedIn()){
            deleteSensitiveData()
        } else {
            print("No user Logged In")
        }
    }
    
    // Helper function to delete all User sensitive data in keychain
    func deleteSensitiveData(){
        if keychainService.deleteData(key: "user_id") {
            print("id was successfully deleted from keychain")
        } else {
            print("id failed to delete in keychain")
        }
        if keychainService.deleteData(key: "user_token") {
            print("token was successfully deleted from keychain")
        } else {
            print("token failed to delete in keychain")
        }
        if keychainService.deleteData(key: "user_secret") {
            print("key was successfully deleted from keychain")
        } else {
            print("key failed to delete in keychain")
        }
    }
    
    func clearData() {
        if !loggedIn() {
            emptyClass = true
            fullName = ""
            userName = ""
            userLocation = ""
            userDescription = ""
        }
    }
}
