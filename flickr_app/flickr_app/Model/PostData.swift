//
//  PostData.swift
//  flickr_app
//
//  Created by Andrew Masters on 10/13/21.
//

import Foundation
import UIKit

//Post class for Collection View in HomeVC
class CollectionPostData {
    var postImageURL: String
    var postTitle: String
    var postOwner: String
    var postID: String
    var postSecret: String
    
    //Default init class
    init(){
        postImageURL = ""
        postTitle = "TITLE"
        postOwner = "OWNER"
        postID = "ID"
        postSecret = "SECRET"
    }
    
    
    //Parse JSON data to fill CollectionPostData class
    init?(json: Dictionary<String, AnyObject>) throws {
        guard
            let id = json["id"] as? String,
            let owner = json["owner"] as? String,
            let title = json["title"] as? String,
            let secret = json["secret"] as? String,
            let server = json["server"] as? String
        else {
            return nil
        }
        
        self.postImageURL = "\(server)/\(id)_\(secret)"
        self.postID = id
        self.postSecret = secret
        
        if title.isEmpty {
            self.postTitle = "No Title"
        } else {
            self.postTitle = title
        }
        if owner.isEmpty {
            self.postOwner = "No Owner Listed"
        } else {
            self.postOwner = owner
        }

    }
    

}


//Meta Data class for a post in PostDetailsVC
class PostMetaData {
    var imageURL: String
    var title: String
    var userName: String
    var realName: String
    var description: String
    var canComment: Bool
    var isFavorite: Bool
    
    
    init() {
        imageURL = ""
        title = "NO TITLE"
        userName = "NO USER"
        realName = "NO REAL NAME"
        description = "NO DESCRIPTION"
        canComment = false
        isFavorite = false
    }
    
    //Parse through JSON data
    init(json: [String : Any]){
        let data = json["photo"] as? [String : AnyObject]
        let photo_id = data?["id"] as? String
        let photo_secret = data?["secret"] as? String
        let photo_server = data?["server"] as? String
        let photo_is_favorite = data?["isfavorite"] as? Int
        
        let owner = data?["owner"] as? [String : AnyObject]
        let user_name_from_owner = owner?["username"] as? String
        let real_name_from_owner = owner?["realname"] as? String
        
        let json_title = data?["title"] as? [String : AnyObject]
        let contentTitle = json_title!["_content"] as? String
        
        let json_description = data?["description"] as? [String : AnyObject]
        let contentDesc = json_description?["_content"] as? String
        
        let editability = data?["publiceditability"] as? [String : AnyObject]
        let ability_to_comment = editability?["cancomment"] as? Int
        
        imageURL = "\(photo_server!)/\(photo_id!)_\(photo_secret!)"
        userName = user_name_from_owner ?? "User Name not Found"
        if userName.isEmpty {
            userName = "No Username"
        }
        realName = real_name_from_owner ?? "Real Name not Found"
        if realName.isEmpty {
            realName = "No Real Name"
        }
        title = contentTitle ?? "NO TITLE"
        if title.isEmpty {
            title = "No Title"
        }
        description = contentDesc ?? "NO DESCRIPTION"
        if description.isEmpty {
            description = "None Available"
        }
        
        // Deciding if you can comment on the post
        if(ability_to_comment == 1){
            canComment = true
        } else {
            canComment = false
        }
        
        if(photo_is_favorite == 1){
            isFavorite = true
        } else {
            isFavorite = false
        }
    }
}
