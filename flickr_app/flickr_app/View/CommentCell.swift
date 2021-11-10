//
//  CommentCell.swift
//  flickr_app
//
//  Created by Andrew Masters on 10/31/21.
//

import UIKit

class CommentCell: UITableViewCell {

    @IBOutlet weak var authorLbl: UILabel!
    @IBOutlet weak var contentLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(author: String, content: String){
        authorLbl.text = author
        contentLbl.text = content
    }

}
