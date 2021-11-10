//
//  HomeVC.swift
//  flickr_app
//
//  Created by Andrew Masters on 10/12/21.
//

import UIKit


class HomeVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UISearchResultsUpdating,
              UISearchControllerDelegate, UISearchBarDelegate {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    private let dispatch_group = DispatchGroup()
    
    var allPostItems = [CollectionPostData]()
    var pageNumber = 1
    var dataManager = DataManager()
    var downloadInProgress: Bool = false
    
    var retrievePostMetaData = CollectionPostData()
    
    var filteredSearchItems = [CollectionPostData]()
    var searchPageNumber = 1
    var searchActive: Bool = false
    var continueDownloading: Bool = true
    
    let searchController = UISearchController(searchResultsController: nil)
    
    var user = User()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Setting up Collection View
        collectionView.dataSource = self
        collectionView.delegate = self
        
        //Setting Up Activity Monitor
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        
        //Setting up Search Bar
        searchBar.delegate = self
        searchBar.sizeToFit()

        // Edit Navigation Bar Title Attributes
        let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor(red: 74/255, green: 144/255, blue: 266/255, alpha: 1), NSAttributedString.Key.font: UIFont(name: "Scriptina", size: 25.0)]
        self.navigationController?.navigationBar.titleTextAttributes = textAttributes as [NSAttributedString.Key : Any]
        
        // Download First Post Items
        downloadRecentPhotos()
        
        // Setup User if it exists
        if user.loggedIn() {
            user.setUser(completion: {})
        }
    }
    
    // Button for users to login
    @IBAction func profileButton(_ sender: Any){
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let loginController = storyBoard.instantiateViewController(withIdentifier: "Authentication") as! UserVC
        
        loginController.user = self.user
        loginController.passUserDataDelegate = self
        loginController.modalPresentationStyle = .popover
        self.navigationController?.pushViewController(loginController, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "postDetailsSegue" {
            let destination = segue.destination as? PostDetailsVC
            destination?.postData = retrievePostMetaData
            destination?.user = user
        }
    }
    
    // Download user data if 'user_id' exists in keychain
    func initUser() {
        if(user.loggedIn()){
            user.setUser(completion: {})
        }
    }

    //MARK: - Search Bar Configuration
    func updateSearchResults(for searchController: UISearchController) {}
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false
        continueDownloading = true
        self.dismiss(animated: true, completion: nil)
        downloadRecentPhotos()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActive = true
        self.collectionView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let checkForEmptyText = searchBar.text
        if checkForEmptyText == "" {
            return
        }
        if checkForEmptyText?.replacingOccurrences(of: " ", with: "") == "" {
            return
        }
        // Empty Post Items
        if !allPostItems.isEmpty {
            pageNumber = 1
            allPostItems.removeAll()
        }
        
        // Reset Filtered Search
        searchPageNumber = 1
        continueDownloading = true
        filteredSearchItems.removeAll()
        self.collectionView.reloadData()
        downloadSearchPhotos(search_text: searchBar.text!)
    }
    
    
    // Alert for Null Data
    func emptyDataAlert() {
        let message = "No items were found in your search\nEdit your search for better results"
        let title = "Search Results Empty"
        print("Web Request returned NULL data")
        print(message)
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Close", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}


//MARK: - Collection View Configuration
extension HomeVC {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if searchActive {
            return filteredSearchItems.count
        } else {
            return allPostItems.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if searchActive {
            if(indexPath.row > (filteredSearchItems.count - 10) && !downloadInProgress && continueDownloading){
                print("Downloading more posts")
                searchPageNumber += 1
                downloadSearchPhotos(search_text: searchBar.text!)
            }
            if(indexPath.row <= filteredSearchItems.count){
                if let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "postCell", for: indexPath) as? PostCell {
                    let postData = filteredSearchItems[indexPath.row]
                    cell.setCellData(image_url: postData.postImageURL, title: postData.postTitle)
                    return cell
                }
            } else if (indexPath.row > filteredSearchItems.count) {
                if let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "postCell", for: indexPath) as? PostCell {
                    cell.defaultCell()
                    return cell
                }
            }
        } else {
            if(indexPath.row > (allPostItems.count - 10) && !downloadInProgress && continueDownloading){
                print("Downloading more posts")
                pageNumber += 1
                downloadRecentPhotos()
            }
            if(indexPath.row <= allPostItems.count){
                if let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "postCell", for: indexPath) as? PostCell {
                    let postData = allPostItems[indexPath.row]
                    cell.setCellData(image_url: postData.postImageURL, title: postData.postTitle)
                    return cell
                }
            } else if (indexPath.row > allPostItems.count) {
                if let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "postCell", for: indexPath) as? PostCell {
                    cell.defaultCell()
                    return cell
                }
            }
        }
        
        return UICollectionViewCell()
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if searchActive {
            retrievePostMetaData = filteredSearchItems[indexPath.row]

        } else {
            retrievePostMetaData = allPostItems[indexPath.row]
        }
        performSegue(withIdentifier: "postDetailsSegue", sender: nil)
    }
    
}


//MARK: - Download Posts
extension HomeVC {
    // Download Recent Photos as an introductory of photos
    func downloadRecentPhotos() {
        activityIndicator.startAnimating()
        downloadInProgress = true
        dispatch_group.enter()
        dataManager.downloadRecentPhotos(page: pageNumber, completion: { collectionData in
            self.dispatch_group.leave()

            self.dispatch_group.notify(queue: .main, execute: {
                self.downloadInProgress = false
                
                if collectionData.isEmpty {
                    self.continueDownloading = false
                } else {
                    self.allPostItems += collectionData
                }
                
                if self.allPostItems.isEmpty {
                    self.emptyDataAlert()
                } else {
                    self.collectionView.reloadData()
                }

                self.activityIndicator.stopAnimating()
                print("Number of Post Items: \(self.allPostItems.count)")
            })
        })
    }
    
    // Search for photos using the text searched
    func downloadSearchPhotos(search_text: String){
        activityIndicator.startAnimating()
        downloadInProgress = true
        dispatch_group.enter()
        
        dataManager.downloadSearchedPhotos(tags_to_parse: search_text, page: searchPageNumber, completion: { collectionData in
            self.dispatch_group.leave()
            
            print("Number of Search Items: \(self.filteredSearchItems.count)")
            self.dispatch_group.notify(queue: .main, execute: {
                self.downloadInProgress = false
                
                if collectionData.isEmpty {
                    self.continueDownloading = false
                } else {
                    self.filteredSearchItems += collectionData
                }
                
                if self.filteredSearchItems.isEmpty {
                    self.emptyDataAlert()
                } else {
                    self.collectionView.reloadData()
                }
                
                self.activityIndicator.stopAnimating()
                print("Number of Search Items: \(self.filteredSearchItems.count)")
            })
        })
    }
}

// Delete user information
extension HomeVC: userDelegate {
    func userData(_ deleted: Bool, user: User) {
        if deleted {
            self.user.clearData()
        } else {
            self.user = user
        }
    }
}
