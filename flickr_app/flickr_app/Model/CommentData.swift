//
//  CommentData.swift
//  flickr_app
//
//  Created by Andrew Masters on 11/1/21.
//

import Foundation
import UIKit

class CommentData {
    var commentAuthor: String
    var commentContent: String
    
    init() {
        commentAuthor = "No Name Found"
        commentContent = "No Comment Content Found"
    }
    
    init?(json: Dictionary<String, AnyObject>) throws {
        guard
            let authorName = json["authorname"] as? String,
            let realName = json["realname"] as? String,
            let content = json["_content"] as? String
        else {
            return nil
        }
        
        self.commentAuthor = authorName + " | " + realName
        self.commentContent = content
    }
}
