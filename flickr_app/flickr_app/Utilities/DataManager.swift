//
//  DataManager.swift
//  flickr_app
//
//  Created by Andrew Masters on 10/13/21.
//

import Foundation
import UIKit

/*
 Manages data between the views and calling URLs and tokens through the
 'Authorization' class.
 */
class DataManager {

    private var dataAuthorizer = DataAuthorizer()

    private let apiKey = "&api_key=429fa1b44e81fc88d12d6088452bf13d"
    private let baseURL = "https://www.flickr.com/services/rest/?"
    private let jsonFormat = "&format=json&nojsoncallback=1"
   
    
    func downloadRecentPhotos(page: Int, completion: @escaping ([CollectionPostData]) -> Void) {
        print("Calling dataDownloader.getRecentPhotos() - Page: \(page)")

        let url = dataAuthorizer.getRecentPhotoURL(page: page)
        downloadData(url: url, completion: { json in
            if json["photos"] == nil {
                completion([])
            }
            
            let jsonData = json["photos"] as! [String : AnyObject]
            let pageNumber = jsonData["pages"] as! Int
            if(page > pageNumber){
                return
            }
            
            let data = jsonData["photo"] as! [Dictionary<String, AnyObject>]
            
            var collectionData = [CollectionPostData]()
            for index in 0..<(data.count) {
                do {
                    let postObject = try CollectionPostData(json: data[index])
                    collectionData.append(postObject!)
                } catch {
                    // post Object did not load into collectionData
                    print("Data did not successfully parse into post data object")
                }
            }
            completion(collectionData)
        })
    }


    func downloadSearchedPhotos(tags_to_parse: String, page: Int,
                    completion: @escaping ([CollectionPostData]) -> Void) {
        print("Calling dataDownloader.downloadSearchPhotos() - Page: \(page)")
        
        let tagsWithRemovedSpaces = tags_to_parse.replacingOccurrences(of: " ", with: "")
        let tags = tagsWithRemovedSpaces.replacingOccurrences(of: ", ", with: "%2C+")
        let url = dataAuthorizer.getPhotosSearchURL(tags: tags, page: page)
        
        downloadData(url: url, completion: { json in
            if json["photos"] == nil {
                print("Data Downloaded is Empty")
                completion([])
            }
            
            let jsonData = json["photos"] as! [String : AnyObject]
            let data = jsonData["photo"] as! [Dictionary<String, AnyObject>]
            if data.isEmpty {
                completion([])
            }
            
            let pageNumber = jsonData["pages"] as! Int
            if(page > pageNumber){
                print("Max Pages")
                return
            }
            
            var collectionData = [CollectionPostData]()
            
            for index in 0..<(data.count) {
                do {
                    let postObject = try CollectionPostData(json: data[index])
                    collectionData.append(postObject!)
                } catch {
                    // post Object did not load into collectionData
                    print("Data did not successfully parse into post data object")
                }
            }
            completion(collectionData)
        })
    }
    
    
    func downloadPostMetaData(post_id: String, post_secret: String, completion: @escaping (PostMetaData) -> Void) {
        print("Calling dataDownloader.getSinglePost()")
        
        if post_id.isEmpty {
            print("photo ID was not added, cannot call singlePost for post meta data")
            return
        }
        
        let url = dataAuthorizer.getPostInfoURL(post_id: post_id, post_secret: post_secret)
        downloadData(url: url, completion: { json in
            let postMetaData = PostMetaData.init(json: json)
            
            completion(postMetaData)
        })
    }
    
    
    func downloadPostComments(post_id: String, completion: @escaping ([CommentData]) -> Void) {
        print("Calling dataDownloader.getList()")

        if post_id.isEmpty {
            print("photo ID was not added, cannot call getList for post meta data")
            return
        }
        let url = dataAuthorizer.getPhotoCommentsURL(post_id: post_id)
        
        downloadData(url: url, completion: { json in
            guard let jsonData = json["comments"] as? [String : AnyObject] else {
                completion([])
                return
            }
            guard let jsonComments = jsonData["comment"] as? [Dictionary<String, AnyObject>] else {
                completion([])
                return
            }
            var allComments = [CommentData]()

            for index in 0..<(jsonComments.count) {
                do {
                    let comment = try CommentData(json: jsonComments[index])
                    allComments.append(comment!)
                } catch {
                    // post Object did not load into collectionData
                    print("Data did not successfully parse into post data object")
                }
            }
            completion(allComments)
        })
    }
    
    func downloadProfileData(completion: @escaping ([String : AnyObject]) -> Void){
        print("Calling dataDownloader.getProfile()")

        let url = dataAuthorizer.getProfileURL()
        
        downloadData(url: url, completion: { json in
            let profileData = json["profile"] as! [String : AnyObject]
            
            completion(profileData)
        })
    }
    
    
    /*
     The Following functions use Oauth Authentication
     */
    func checkToken(completion: @escaping ([String : AnyObject]?) -> Void){
        print("Checking Existing Token")
        dataAuthorizer.checkToken(completion: {data in
            completion(data)
        })
    }

    func uploadComment(_ comment_text: String, with photo_id: String, completion: @escaping (Bool) -> Void){
        print("Uploading Comment to Flickr API")
        dataAuthorizer.uploadCommentToAPI(comment_text, with: photo_id, completion: { result in
            completion(result)
        })
    }
    
    func addFavorite(_ photo_id: String, completion: @escaping (Bool) -> Void){
        print("Adding Favorite to Flickr API")
        dataAuthorizer.addPostasFavoritetoAPI(photo_id, completion: { result in
            completion(result)
        })
    }
    
    func removeFavorite(_ photo_id: String, completion: @escaping (Bool) -> Void){
        print("Removing Favorite to Flickr API")
        dataAuthorizer.removePostasFavoritetoAPI(photo_id, completion: { result in
            completion(result)
        })
    }
    
    func downloadPostMetaDatawithAuth(post_id: String, completion: @escaping (PostMetaData) -> Void) {
        print("Calling dataDownloader.getInfo() with Oauth")
        
        if post_id.isEmpty {
            print("photo ID was not added, cannot call singlePost for post meta data")
            return
        }
        
        dataAuthorizer.getInfoofPostwithAuth(post_id, completion: { result in
            let postData = PostMetaData.init(json: result!)
            completion(postData)
        })
    }
    
    //MARK: - Will download data from the URL argument and returns a dictionary of data
    
    var dispatch_group = DispatchGroup()

    private func downloadData(url: URL, completion: @escaping ([String: AnyObject]) -> Void) {
        
        dispatch_group.enter()
        
        // Make Call to Flickr API
        URLSession.shared.dataTask(with: url, completionHandler: { data, response, error in
            self.dispatch_group.leave()
            var json = [String : AnyObject]()
                        
            if let error = error {
                print("Downloading Failed!")
                print(error)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                      print("ERROR: \(String(describing: response))")
                      return
                  }
            if(data != nil){
                json = try! JSONSerialization.jsonObject(with: data!, options: []) as! [String : AnyObject]
                print("Successfully Downloaded Data")
            } else {
                print("ERROR: Data is nil")
            }
            completion(json)
        }).resume()
    }
    
    
}
