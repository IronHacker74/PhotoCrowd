//
//  Authorization.swift
//  flickr_app
//
//  Created by Andrew Masters on 11/3/21.
//

import Foundation
import UIKit
import OAuthSwift

/*
 The DataAuthorizer helps pass sensitive data and creates proper URLs to
 call Flickr's API.
 */
class DataAuthorizer {
    
//    var oauthSwift: OAuth1Swift?
    
    private let keychainService = KeychainService()
    private let baseURL = "https://www.flickr.com/services/rest/?"
    private let jsonFormat = "&format=json&nojsoncallback=1"
    
    private func getAPIKey() -> String {
        if let apiKey = Bundle.main.infoDictionary?["API_KEY"] as? String {
            return apiKey
        }
        print("API KEY did not successfully load.")
        return "APIKEY"
    }
    
    private func getAPISecret() -> String {
        if let apiSecret = Bundle.main.infoDictionary?["API_SECRET"] as? String {
            return apiSecret
        }
        print("API SECRET did not successfully load.")
        return "APISecret"
    }
    
    private func getAPIKeyforURL() -> String {
        if let apiKey = Bundle.main.infoDictionary?["API_KEY"] as? String {
            return "&api_key=\(apiKey)"
        }
        print("API KEY did not successfully load.")
        return "APIKEY"
    }
    
    
    /* URL to get Recent Photos from Flickr API
     Example: https://www.flickr.com/services/rest/?method=flickr.photos
     .getRecent&api_key=(APIKEY)&per_page=50
     &format=json&nojsoncallback=1
    */
    func getRecentPhotoURL(page: Int) -> URL{
        let method = "method=flickr.photos.getRecent"
        let extraParameters = "&per_page=25&page=\(page)"
        let urlPath = baseURL + method + getAPIKeyforURL() + extraParameters + jsonFormat
        print("Attempting to Download from URL: \(urlPath)")
        
        let url = URL(string: urlPath)!
        return url
    }
    
    /* URL to get list of photos with specified tag from Flickr API
     Example: https://www.flickr.com/services/rest/?method=flickr.photos.search
     &api_key=(APIKEY)&tags=scenery&per_page=25
     &page=1&format=json&nojsoncallback=1
     */
    func getPhotosSearchURL(tags: String, page: Int) -> URL{
        let method = "method=flickr.photos.search"
        let pageParameters = "&per_page=25&page=\(page)"
        let tags = "&tags=\(tags)"
        let urlPath = baseURL + method + getAPIKeyforURL() + tags + pageParameters + jsonFormat
        print("Attempting to Download from URL: \(urlPath)")

        let url = URL(string: urlPath)!
        return url
    }
    
    /* URL to get meta data of the 'post_id' from the Flickr API
     Example: https://www.flickr.com/services/rest/?method=flickr.photos
     .getInfo&api_key=(APIKEY)&photo_id=(PHOTOID)&secret=(PHOTOSECRET)
     &format=json&nojsoncallback=1
     */
    func getPostInfoURL(post_id: String, post_secret: String) -> URL{
        let method = "method=flickr.photos.getInfo"
        let photoID = "&photo_id=\(post_id)"
        
        var secretID = "&secret=\(post_secret)"
        if post_secret.isEmpty {
            secretID = ""
        }
        
        let urlPath = baseURL + method + getAPIKeyforURL() + photoID + secretID + jsonFormat
        print("Attempting to Download from URL: \(urlPath)")
        
        let url = URL(string: urlPath)!
        return url
    }
    
    /* URL to get all the comments of the specified 'post_id' from the Flickr API
     URL Example: https://www.flickr.com/services/rest/?method=flickr.photos.comments
     .getList&api_key=(APIKEY)&photo_id=(PHOTOID)&format=json&nojsoncallback=1
     */
    func getPhotoCommentsURL(post_id: String) -> URL{
        let method = "method=flickr.photos.comments.getList"
        let photoID = "&photo_id=\(post_id)"
        
        let urlPath = baseURL + method + getAPIKeyforURL() + photoID + jsonFormat
        print("Attempting to Download from URL: \(urlPath)")
        
        let url = URL(string: urlPath)!
        return url
    }
    
    /* URL to get all profile data of specified 'user_id' from the Flickr API
     URL Example: https://www.flickr.com/services/rest/?method=flickr.profile
     .getProfile&api_key=(APIKEY)&user_id=(USERID)&format=json&nojsoncallback=1
     ONLY CALL IF USER IS LOGGED IN
     */
    func getProfileURL() -> URL{
        
        let method = "method=flickr.profile.getProfile"
        let user = "&user_id=\(keychainService.retrieveData(key: "user_id"))"
        
        let urlPath = baseURL + method + getAPIKeyforURL() + user + jsonFormat
        print("Attempting to Download from URL: \(urlPath)")

        let url = URL(string: urlPath)!
        return url
    }
    
    
    /*
     Generate a OAuth1Swift Web Request to pull data from Flickr's OAuth Service
     */
    func getOAuthToken() -> OAuth1Swift {
        let oauth1swift = OAuth1Swift(
            consumerKey     :  getAPIKey(),
            consumerSecret  :  getAPISecret(),
            requestTokenUrl :  "https://www.flickr.com/services/oauth/request_token",
            authorizeUrl    :  "https://www.flickr.com/services/oauth/authorize",
            accessTokenUrl  :  "https://www.flickr.com/services/oauth/access_token"
        )
        return oauth1swift
    }
    
    // Checks user's token store in the keychain
    // ONLY CALL IF USER IS LOGGED IN
    func checkToken(completion: @escaping ([String : AnyObject]?) -> Void) {
        if keychainService.retrieveData(key: "user_id").isEmpty {
            print("User not logged in")
            return
        }
        
        let oauthSwift = getOAuthToken()
        oauthSwift.client.credential.oauthToken = keychainService.retrieveData(key: "user_token")
        oauthSwift.client.credential.oauthTokenSecret = keychainService.retrieveData(key: "user_secret")
        let url :String = "https://www.flickr.com/services/rest"
        let parameters :Dictionary = [
            "method"         : "flickr.test.login",
            "nojsoncallback" : "1",
            "format"         : "json"
        ]
        let _ = oauthSwift.client.get(url, parameters: parameters) { result in
            switch result {
            case .success(let response):
                let jsonDict = try? response.jsonObject() as? [String : AnyObject]
                print("Token Check Successful")
                completion(jsonDict)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    // Upload Comment into Flickr API
    func uploadCommentToAPI(_ comment_text: String, with photo_id: String, completion: @escaping (Bool) -> Void) {
        if keychainService.retrieveData(key: "user_id").isEmpty {
            print("User not logged in")
            completion(false)
        }
        print("Going to try and push comment onto API")
        let oauthSwift = getOAuthToken()
        oauthSwift.client.credential.oauthToken = keychainService.retrieveData(key: "user_token")
        oauthSwift.client.credential.oauthTokenSecret = keychainService.retrieveData(key: "user_secret")
        let url :String = "https://www.flickr.com/services/rest"
        let parameters :Dictionary = [
            "method"         : "flickr.photos.comments.addComment",
            "photo_id"       : photo_id,
            "comment_text"   : comment_text,
            "nojsoncallback" : "1",
            "format"         : "json"
        ]
        let _ = oauthSwift.client.post(url, parameters: parameters) { result in
            switch result {
            case .success(let response):
                // Receive Comment ID as response
                print(response)
                print("Comment Successfully Uploaded")
                completion(true)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    // Upload Favorite into Flickr API
    func addPostasFavoritetoAPI(_ photo_id: String, completion: @escaping (Bool) -> Void) {
        if keychainService.retrieveData(key: "user_id").isEmpty {
            print("User not logged in")
            completion(false)
        }
        let oauthSwift = getOAuthToken()
        oauthSwift.client.credential.oauthToken = keychainService.retrieveData(key: "user_token")
        oauthSwift.client.credential.oauthTokenSecret = keychainService.retrieveData(key: "user_secret")
        let url :String = "https://www.flickr.com/services/rest"
        let parameters :Dictionary = [
            "method"         : "flickr.favorites.add",
            "photo_id"       : photo_id,
            "nojsoncallback" : "1",
            "format"         : "json"
        ]
        let _ = oauthSwift.client.post(url, parameters: parameters) { result in
            switch result {
            case .success(_):
                // Receive Favorite ID as response
                print("Favorite Successfully Added")
                completion(true)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    // Upload Favorite into Flickr API
    func removePostasFavoritetoAPI(_ photo_id: String, completion: @escaping (Bool) -> Void) {
        if keychainService.retrieveData(key: "user_id").isEmpty {
            print("User not logged in")
            completion(false)
        }
        let oauthSwift = getOAuthToken()
        oauthSwift.client.credential.oauthToken = keychainService.retrieveData(key: "user_token")
        oauthSwift.client.credential.oauthTokenSecret = keychainService.retrieveData(key: "user_secret")
        let url :String = "https://www.flickr.com/services/rest"
        let parameters :Dictionary = [
            "method"         : "flickr.favorites.remove",
            "photo_id"       : photo_id,
            "nojsoncallback" : "1",
            "format"         : "json"
        ]
        let _ = oauthSwift.client.post(url, parameters: parameters) { result in
            switch result {
            case .success(_):
                // Receive Favorite ID as response
                print("Favorite Successfully Removed")
                completion(true)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    // Upload Favorite into Flickr API
    func getInfoofPostwithAuth(_ photo_id: String, completion: @escaping ([String : AnyObject]?) -> Void) {
                        
        if keychainService.retrieveData(key: "user_id").isEmpty {
            print("User not logged in")
            completion([:])
        }
        
        let oauthSwift = getOAuthToken()
        oauthSwift.client.credential.oauthToken = keychainService.retrieveData(key: "user_token")
        oauthSwift.client.credential.oauthTokenSecret = keychainService.retrieveData(key: "user_secret")
        let url :String = "https://www.flickr.com/services/rest"
        let parameters :Dictionary = [
            "method"         : "flickr.photos.getInfo",
            "photo_id"       : photo_id,
            "nojsoncallback" : "1",
            "format"         : "json"
        ]
        let _ = oauthSwift.client.get(url, parameters: parameters) { result in
            switch result {
            case .success(let response):
                // Receive Favorite ID as response
                print("Successfully Download Post Meta Data with Auth")
                let data = try? response.jsonObject() as? [String : AnyObject]
                completion(data)
            case .failure(let error):
                print(error)
            }
        }
    }

}
