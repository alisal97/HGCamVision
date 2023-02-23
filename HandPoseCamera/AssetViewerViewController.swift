//
//  AssetViewerViewController.swift
//  HGCam
//
//  Created by Aly Salman on 23/02/23.
//  Copyright © 2023 CB Gang. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

class AssetViewerViewController: UIViewController {
    
    var asset: PHAsset?
    var imageView: UIImageView!
    
    
    init(asset: PHAsset) {
        self.asset = asset
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView = UIImageView(frame: view.bounds)
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
        
        if let asset = asset {
            let options = PHImageRequestOptions()
            
            options.isSynchronous = true
            
            PHImageManager.default().requestImage(for: asset, targetSize: view.bounds.size, contentMode: .aspectFit, options: options) { (image, info) in
                self.imageView.image = image

            }
        }
    }
}
