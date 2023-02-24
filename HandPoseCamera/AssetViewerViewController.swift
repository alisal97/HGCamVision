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

        let options = PHImageRequestOptions()
        options.isSynchronous = true

        PHImageManager.default().requestImage(for: asset!, targetSize: view.bounds.size, contentMode: .aspectFit, options: options) { (image, info) in
            self.imageView.image = image
        }
    }
    func configure(with asset: PHAsset) {
        self.asset = asset
        
        let options = PHImageRequestOptions()
        options.isSynchronous = true

        PHImageManager.default().requestImage(for: asset, targetSize: view.bounds.size, contentMode: .aspectFit, options: options) { (image, info) in
            self.imageView.image = image
        }
    }

}

class AssetScrollViewController: UIViewController, UIScrollViewDelegate {
    
    let scrollView = UIScrollView()
    let stackView = UIStackView()
    var assets = [PHAsset]()
    
    convenience init(assets: [PHAsset]) {
        self.init()
        self.assets = assets
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate = self
        view.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        stackView.axis = .horizontal
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
        
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.fetchLimit = 50 // Limit the number of assets loaded to 50
        let fetchResult = PHAsset.fetchAssets(with: options)
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            fetchResult.enumerateObjects { (asset, index, stop) in
                guard let self = self else { return }
                self.assets.append(asset)
                
                DispatchQueue.main.async {
                    let assetView = AssetViewerViewController(asset: asset)
                    self.addChild(assetView)
                    self.stackView.addArrangedSubview(assetView.view)
                    assetView.didMove(toParent: self)
                }
            }
        }
    }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            let pageIndex = round(scrollView.contentOffset.x / scrollView.frame.size.width)
            guard let subview = stackView.arrangedSubviews[Int(pageIndex)] as? AssetViewerViewController else {
                return
            }
            if let assetIndex = stackView.arrangedSubviews.firstIndex(of: subview.view) {
                subview.configure(with: assets[assetIndex])
            }
        }
    }
    
    //
    //
    //
    //class AssetViewerViewController: UIViewController, UIScrollViewDelegate {
    //
    //    var asset: PHAsset?
    //    var imageView: UIImageView!
    //
    //
    //    init(asset: PHAsset) {
    //        self.asset = asset
    //        super.init(nibName: nil, bundle: nil)
    //    }
    //
    //    required init?(coder: NSCoder) {
    //        fatalError("init(coder:) has not been implemented")
    //    }
    //
    //    override func viewDidLoad() {
    //        super.viewDidLoad()
    //
    //        imageView = UIImageView(frame: view.bounds)
    //        imageView.contentMode = .scaleAspectFit
    //        view.addSubview(imageView)
    //
    //        if let asset = asset {
    //            let options = PHImageRequestOptions()
    //
    //            options.isSynchronous = true
    //
    //            PHImageManager.default().requestImage(for: asset, targetSize: view.bounds.size, contentMode: .aspectFit, options: options) { (image, info) in
    //                self.imageView.image = image
    //
    //            }
    //        }
    //    }
    //}

