//
//  AssetViewerViewController.swift
//  HGCam
//
//  Created by Aly Salman on 23/02/23.
//  Copyright © 2023 CB Gang. All rights reserved.
////
import UIKit
import AVKit

class AssetViewerViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    private let playerViewController = AVPlayerViewController()
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var imageView: UIImageView! // add this line


    let button: UIButton = {
        let view = UIButton()
        view.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 50)
        view.setImage(UIImage(systemName: "play.fill", withConfiguration: config), for: .normal)

        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupPlayerView()
        setupButton()
    }

    func setupButton() {
        self.view.addSubview(button)

        button.addTarget(self, action: #selector(onButtonClick(sender:)), for: .touchUpInside)

        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 44),
            button.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    func setupPlayerView() {
        self.addChild(playerViewController)
        self.view.addSubview(playerViewController.view)

        playerViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playerViewController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            playerViewController.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            playerViewController.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            playerViewController.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }

    @objc func onButtonClick(sender: UIButton){
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = ["public.image", "public.movie"] // Set supported media types
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true) {
            if let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String {
                if mediaType == "public.movie", let videoURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
                    let player = AVPlayer(url: videoURL)
                    self.playerViewController.player = player
                    player.play()
                } else if mediaType == "public.image", let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                    self.imageView?.image = image
                }
            }
        }
    }

}
