//
//  WebVC.swift
//  flickr_app
//
//  Created by Andrew Masters on 10/29/21.
//  Modified Code by Dongri Jin
//

import Foundation
import OAuthSwift

import UIKit
import WebKit
typealias WebView = WKWebView

class WebVC: OAuthWebViewController {

    var targetURL: URL?
    let webView: WebView = WebView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.webView.frame = self.view.bounds
        self.webView.navigationDelegate = self
        self.webView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.webView)
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-0-[view]-0-|", options: [], metrics: nil, views: ["view":self.webView]))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[view]-0-|", options: [], metrics: nil, views: ["view":self.webView]))
        loadAddressURL()
    }

    override func handle(_ url: URL) {
        targetURL = url
        super.handle(url)
        self.loadAddressURL()
    }
    
    func loadAddressURL() {
        guard let url = targetURL else {
            return
        }
        let req = URLRequest(url: url)
        DispatchQueue.main.async {
            self.webView.load(req)
        }
    }
}

// MARK: delegate

extension WebVC: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        // here we handle internally the callback url and call method that call handleOpenURL (not app scheme used)
        if let url = navigationAction.request.url , url.scheme == "oauth-swift" {
            
            AppDelegate.sharedInstance.applicationHandle(url: url)
            decisionHandler(.cancel)
            
            self.dismissWebViewController()
            return
        }
        
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("\(error)")
        self.dismissWebViewController()
        // maybe cancel request...
    }
    /* override func webView(webView: WebView!, decidePolicyForNavigationAction actionInformation: [NSObject : AnyObject]!, request: URLRequest!, frame: WebFrame!, decisionListener listener: WebPolicyDecisionListener!) {
     
     if request.URL?.scheme == "oauth-swift" {
     self.dismissWebViewController()
     }
     
     } */
}
