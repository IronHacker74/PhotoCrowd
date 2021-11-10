//
//  PostCell.swift
//  flickr_app
//
//  Created by Andrew Masters on 10/13/21.
//

import UIKit

class PostCell: UICollectionViewCell {
    
    @IBOutlet weak var postImage: UIImageView!
    @IBOutlet weak var titleLbl: UILabel!
    
    func defaultCell(){
        postImage.image = UIImage(named: "placeHolder")
        titleLbl.text = "Post Title"
    }
    
    func setCellData(image_url: String, title: String){
        postImage.image = UIImage(named: "placeHolder")
        postImage.downloaded(from: image_url, size: "w")
        titleLbl.text = title
    }
}
