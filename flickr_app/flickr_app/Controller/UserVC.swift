//
//  UserVC.swift
//  flickr_app
//
//  Created by Andrew Masters on 10/29/21.
//  Modified Code by Dongri Jin from OAuthSwift -> Demo
//

import Foundation
import OAuthSwift
import SafariServices

protocol userDelegate {
    func userData(_ deleted: Bool, user: User)
}

class UserVC: OAuthViewController {
    
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var locationLbl: UILabel!
    @IBOutlet weak var descriptionTF: UITextView!
    
    var passUserDataDelegate: userDelegate? = nil
    
    var user = User()
    var dataAuthorizer = DataAuthorizer()
    var oauthswift: OAuthSwift?
        
    lazy var internalWebController: WebVC = {
        let controller = WebVC()
        controller.view = UIView(frame: UIScreen.main.bounds) // needed if no nib or not loaded from storyboard
        controller.delegate = self
        controller.viewDidLoad()
        return controller
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if(!user.loggedIn()){
            // Trace for Bugs
            OAuthSwift.setLogLevel(.trace)
            // init now web view handler
            let _ = internalWebController.webView
            DispatchQueue.main.async {
                self.performAuthService()
            }
        } else if user.emptyClass {
            DispatchQueue.main.async {
                self.user.setUser(completion: {
                    self.viewDidLoad()
                })
            }
        }
        
        DispatchQueue.main.async {
            self.nameLbl.text = "User: " + self.user.userName + "\n" + self.user.fullName
            self.locationLbl.text = "Location: " + self.user.userLocation
            self.descriptionTF.text = "Description: " + self.user.userDescription
        }
    }
    
    @IBAction func logOutButtonTapped(_ sender: UIButton){
        user.logOut()
        passUserDataDelegate?.userData(true, user: self.user)
        self.navigationController?.popViewController(animated: true)
    }
}



//MARK: - Authentication Service

extension UserVC: OAuthWebViewControllerDelegate {
    func oauthWebViewControllerDidPresent() {}
    func oauthWebViewControllerDidDismiss() {}
    func oauthWebViewControllerWillAppear() {}
    func oauthWebViewControllerDidAppear() {}
    func oauthWebViewControllerWillDisappear() {}
    
    func oauthWebViewControllerDidDisappear() {
        // Ensure all listeners are removed if presented web view close
        oauthswift?.cancel()
    }
}


extension UserVC {
    // MARK: - Perform Authentication
    func performAuthService(){
        
        let oauthswift = dataAuthorizer.getOAuthToken()
        
        self.oauthswift = oauthswift
        oauthswift.authorizeURLHandler = getURLHandler()
        let _ = oauthswift.authorize(
        withCallbackURL: URL(string: "oauth-swift://oauth-callback/flickr")!) { result in
            switch result {
            case .success(let (_, _, credential)):
                let data = credential as! [String : String]
                let message = "You Successfully logged into Flickr with an existing Flickr Account"
                self.showAlertView(title: "Login Successful", message: message)
                self.passUserDataDelegate?.userData(false, user: self.user)
                self.user.setUser(data, completion: {
                    self.viewDidLoad()
                })
                
            case .failure(let error):
                print(error.description)
            }
        }
    }
    
    //MARK: - Alert for Success or Failed Login
    func showAlertView(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Close", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Handler to Open Web for Authentication
    func getURLHandler() -> OAuthSwiftURLHandlerType {
        if internalWebController.parent == nil {
            internalWebController.modalPresentationStyle = .popover
            self.addChild(internalWebController)
        }
        return internalWebController
    }
}
