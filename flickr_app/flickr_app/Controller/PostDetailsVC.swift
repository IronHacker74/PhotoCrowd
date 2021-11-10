//
//  PostDetailsVC.swift
//  flickr_app
//
//  Created by Andrew Masters on 10/13/21.
//

import UIKit

class PostDetailsVC: UIViewController {

    private let dispatch_group = DispatchGroup()
    var postData: CollectionPostData!
    var dataManager = DataManager()
    var user = User()
    var isFavorite: Bool = false
    
    var postComments = [CommentData]()

    @IBOutlet weak var postTitle: UILabel!
    @IBOutlet weak var postImage: UIImageView!
    @IBOutlet weak var postDescription: UITextView!
    @IBOutlet weak var ownerLbl: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var detailView: UIView!
    @IBOutlet weak var commentView: UIStackView!
    
    @IBOutlet weak var interactiveView: UIView!
    @IBOutlet weak var favoriteBtn: UIButton!
    @IBOutlet weak var currentUserLbl: UILabel!
    @IBOutlet weak var addCommentText: UITextView!
    @IBOutlet weak var addCommentBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Assign TableView to ViewController
        tableView.delegate = self
        tableView.dataSource = self
        
        // Edit Radius of Views
        detailView.layer.cornerRadius = 10
        detailView.layer.borderColor = CGColor.init(red: 74/255, green: 144/255, blue: 266/255, alpha: 1)
        detailView.layer.borderWidth = 1
        
        // Edit Interactive View
        interactiveView.layer.cornerRadius = 10
        interactiveView.layer.borderColor = CGColor.init(red: 0, green: 0, blue: 0, alpha: 1)
        interactiveView.layer.borderWidth = 1
        
        // Edit Favorite Button
        favoriteBtn.layer.cornerRadius = 5
    
        
        // Edit Comment Text Field
        addCommentText.layer.cornerRadius = 10
        addCommentText.delegate = self
        addCommentText.text = "Write a Comment"
        addCommentText.textColor = .lightGray
        
        // Check if user is logged in
        if user.loggedIn() {
            currentUserLbl.text = "Logged In As: " + user.userName
        } else {
            currentUserLbl.text = "Login to Interact"
        }
        
        // Edit Navigation Bar Title
        let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.black, NSAttributedString.Key.font: UIFont(name: "Avenir Next", size: 15)]
        self.navigationController?.navigationBar.titleTextAttributes = textAttributes as [NSAttributedString.Key : Any]

        // Download Post Meta Data
        initDetailsDownload()
    }
    
    // Button for users to login
    @IBAction func profileButton(_ sender: Any){
        pushUserVC()
    }
    
    func changeFavoriteImage() {
        if isFavorite {
            favoriteBtn.setImage(UIImage(systemName: "heart.fill"), for: .normal)
        } else {
            favoriteBtn.setImage(UIImage(systemName: "heart"), for: .normal)
        }
    }
    
    @IBAction func favoriteBtnTapped(_ sender: UIButton){
        favoriteBtn.isEnabled = false
        if isFavorite {
            dataManager.removeFavorite(postData.postID, completion: { result in
                if result {
                    self.isFavorite = false
                    self.changeFavoriteImage()
                } else {
                    print("Could not remove favorite")
                    self.userNotLoggedIn()
                }
                self.favoriteBtn.isEnabled = true
            })
        } else {
            dataManager.addFavorite(postData.postID, completion: { result in
                if result {
                    self.isFavorite = true
                    self.changeFavoriteImage()
                } else {
                    print("Could not add favorite")
                    self.userNotLoggedIn()
                }
                self.favoriteBtn.isEnabled = true
            })
        }
    }
    
    @IBAction func addCommentBtnTapped(_ sender: UIButton){
        if addCommentText.text.isEmpty {
            return
        }
        if addCommentText.text.replacingOccurrences(of: " ", with: "").isEmpty {
            return
        }
        
        addCommentBtn.isEnabled = false
        addCommentText.isEditable = false
        dataManager.uploadComment(addCommentText.text, with: postData.postID, completion: { result in
            if result {
                self.textViewDidEndEditing(self.addCommentText)
                self.downloadComments()
            } else {
                self.userNotLoggedIn() ///ALERT USER TO LOGIN
            }
            self.addCommentText.isEditable = true
            self.addCommentBtn.isEnabled = true
        })
    }
    
    // Alert for User to Login
    func userNotLoggedIn() {
        let message = "You must Login to Gain Access to Likes and Comments"
        let title = "Login To Like Or Comment"
        print(message)
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ignore", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Login", style: .default, handler: {_ in
            self.pushUserVC() ///PULL UP LOGIN
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func pushUserVC() {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let loginController = storyBoard.instantiateViewController(withIdentifier: "Authentication") as! UserVC
        
        loginController.user = self.user
        loginController.passUserDataDelegate = self
        loginController.modalPresentationStyle = .popover
        self.navigationController?.pushViewController(loginController, animated: true)
    }
}

/// EDITING COMMENT VIEW UI
extension PostDetailsVC: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if addCommentText.textColor == .lightGray {
            addCommentText.text = ""
            addCommentText.textColor = .black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if addCommentText.text.isEmpty {
            addCommentText.text = "Write a Comment"
            addCommentText.textColor = .lightGray
        }
    }
}

/// DOWNLOADING DATA
extension PostDetailsVC {
    func initDetailsDownload() {
        
        // Download Large Image in Background
        postImage.downloaded(from: self.postData.postImageURL, size: "b")
        postTitle.text = postData.postTitle
        
        // Download Post Meta Data
        if user.loggedIn() {
            downloadMetaDatawithAuth()
        } else {
            downloadMetaData()
        }
    }
    
    // Download Post Meta Data Without Authentication
    func downloadMetaData(){
        dispatch_group.enter()
        dataManager.downloadPostMetaData(post_id: postData.postID,
                                         post_secret: postData.postSecret, completion: {post in
            self.dispatch_group.leave()
            self.dispatch_group.notify(queue: .main, execute: {
                
                self.setViewObjects(post)
            })
        })
    }
    
    // Download Post Meta Data WITH Authentication
    func downloadMetaDatawithAuth(){
        dispatch_group.enter()
        dataManager.downloadPostMetaDatawithAuth(post_id: postData.postID, completion: {post in
            self.dispatch_group.leave()
            self.dispatch_group.notify(queue: .main, execute: {
                
                self.setViewObjects(post)
            })
        })
    }
    
    // Download Comments of Post
    func downloadComments(){
        dispatch_group.enter()
        dataManager.downloadPostComments(post_id: postData.postID, completion: { comments in
            self.dispatch_group.leave()
            
            self.dispatch_group.notify(queue: .main, execute: {
                print("Number of Comments: \(comments.count)")

                if comments.isEmpty {
                    print("No Comments were found")
                    self.tableView.alpha = 0
                } else {
                    self.postComments = comments
                    self.tableView.alpha = 1
                    self.tableView.reloadData()
                }
            })
        })
    }
    
    func setViewObjects(_ post: PostMetaData){
        self.postDescription.text = "Description: " + post.description
        self.ownerLbl.text! = "By: " + post.userName + " | " + post.realName
        
        // Download Post Comments (if possible)
        if !post.canComment {
            print("Cannot Comment on Post")
            self.commentView.alpha = 0
        } else {
            self.downloadComments()
        }
        self.isFavorite = post.isFavorite
        self.changeFavoriteImage()
    }
}


//MARK: - Table View for Comments
extension PostDetailsVC: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Post Comments"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postComments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath) as? CommentCell {
            let comment = postComments[indexPath.row]
            cell.configure(author: comment.commentAuthor, content: comment.commentContent)
            return cell
        }
        return CommentCell()
    }   
}


extension PostDetailsVC: userDelegate {
    func userData(_ deleted: Bool, user: User) {
        if deleted {
            print("Failed to login User")
        } else {
            self.user = user
        }
        viewDidLoad()
    }
}
