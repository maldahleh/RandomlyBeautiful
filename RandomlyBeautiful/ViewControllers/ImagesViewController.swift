//
//  ImagesViewController.swift
//  RandomlyBeautiful
//
//  Created by Mohammed Al-Dahleh on 2017-12-27.
//  Copyright © 2017 Mohammed Al-Dahleh. All rights reserved.
//

import UIKit

class ImagesViewController: UIViewController {
    @IBOutlet var activitySpinner: UIActivityIndicatorView!
    @IBOutlet var creditLabel: UILabel!
    
    let appID = "2663fbdc32f24e9786890858bfab5ffc029602abdce2e9a64e6225612b41697e"
    var category: String?
    
    var imageCounter = 0
    var imageViews: [UIImageView] = []
    var images: [JSON] = []
    
    var continueDownload = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageViews = view.subviews.flatMap { $0 as? UIImageView }
        imageViews.forEach { $0.alpha = 0 }
        
        creditLabel.alpha = 0
        creditLabel.clipsToBounds = true
        creditLabel.layer.cornerRadius = 15
        
        guard let url = URL(string: "https://api.unsplash.com/search/photos?client_id=\(appID)&query=\(category ?? "cats")&per_page=100") else { return }
        
        DispatchQueue.global(qos: .userInteractive).async {
            self.fetch(url)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        continueDownload = false
    }
    
    func fetch(_ url: URL) {
        if let data = try? Data(contentsOf: url) {
            let json = JSON(data)
            images = json["results"].arrayValue
            
            downloadImage()
        }
    }
    
    func downloadImage() {
        let currentImage = images[imageCounter % images.count]
        
        let imageName = currentImage["urls"]["full"].stringValue
        let imageCredit = currentImage["user"]["name"].stringValue
        imageCounter += 1
        
        guard let imageURL = URL(string: imageName) else { return }
        guard let imageData = try? Data(contentsOf: imageURL) else { return }
        
        guard let image = UIImage(data: imageData) else { return }
        
        DispatchQueue.main.async {
            self.show(image, credit: imageCredit)
        }
    }
    
    func show(_ image: UIImage, credit: String) {
        activitySpinner.stopAnimating()
        
        let imageViewToUse = imageViews[imageCounter % imageViews.count]
        let otherImageView = imageViews[(imageCounter + 1) % imageViews.count]
        
        UIView.animate(withDuration: 2.0, animations: {
            imageViewToUse.image = image
            imageViewToUse.alpha = 1
            
            self.creditLabel.alpha = 0
            
            self.view.sendSubview(toBack: otherImageView)
        }) { _ in
            self.creditLabel.text = "  \(credit.uppercased())"
            self.creditLabel.alpha = 1
            
            otherImageView.alpha = 0
            otherImageView.transform = .identity
            
            UIView.animate(withDuration: 10.0, animations: {
                imageViewToUse.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                }) { _ in
                DispatchQueue.global(qos: .userInteractive).async {
                    if continueDownload {
                        self.downloadImage()
                    }
                }
            }
        }
    }
}
