//
//  Extensions.swift
//  flickr_app
//
//  Created by Andrew Masters on 10/31/21.
//

import Foundation
import UIKit

extension UIImageView {
    
    //MARK: - Download Image of Size: size variable
    private func downloaded(from url: URL, contentMode mode: ContentMode = .scaleAspectFit) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() { [weak self] in
                self?.image = image
            }
        }.resume()
    }
    
    func downloaded(from photo_url: String, size: String, contentMode mode: ContentMode = .scaleAspectFit) {
        if(photo_url.isEmpty || size.isEmpty) {
            DispatchQueue.main.async() { [weak self] in
                self?.image = UIImage(named: "PostImage PlaceHolder")!
                return
            }
        }
        let urlpath = "https://live.staticflickr.com/\(photo_url)_\(size).jpg"
        
        guard let url = URL(string: urlpath) else { return }
        downloaded(from: url, contentMode: mode)
    }
}
