//
//  OnboardingViewController.swift
//  HGCam
//
//  Created by Aly Salman on 18/07/23.
//  Copyright © 2023 CB Gang. All rights reserved.
//

import Foundation
import UIKit


class OnboardingViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        
        // Create and configure the onboarding label
        let onboardingLabel = UILabel()
        onboardingLabel.translatesAutoresizingMaskIntoConstraints = false
        onboardingLabel.textColor = .white
        onboardingLabel.font = UIFont.systemFont(ofSize: 24)
        onboardingLabel.textAlignment = .center
        onboardingLabel.numberOfLines = 0
        onboardingLabel.text = "Welcome to SayCheese!\n\nSayCheese is a camera app designed to make content creation accessible, choose your prefered camera control mode using the menu at the bottom, then tap the '?' button for instrutions!"
        
        // Add the label to the view
        view.addSubview(onboardingLabel)
        
        // Set up constraints for the label (adjust them as needed)
        NSLayoutConstraint.activate([
            onboardingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            onboardingLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Create the "Enter" button
        let enterButton = UIButton(type: .system)
        enterButton.translatesAutoresizingMaskIntoConstraints = false
        enterButton.setTitle("Enter", for: .normal)
        enterButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        enterButton.setTitleColor(.white, for: .normal)
        enterButton.backgroundColor = UIColor.systemBlue
        enterButton.layer.cornerRadius = 12
        enterButton.addTarget(self, action: #selector(enterButtonTapped), for: .touchUpInside)
        
        // Add the button to the view
        view.addSubview(enterButton)
        
        // Set up constraints for the button (adjust them as needed)
        NSLayoutConstraint.activate([
            enterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            enterButton.topAnchor.constraint(equalTo: onboardingLabel.bottomAnchor, constant: 20),
            enterButton.widthAnchor.constraint(equalToConstant: 120),
            enterButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    @objc func enterButtonTapped() {
        onboardingCompleted()
    }
    
    func onboardingCompleted() {
        // Store any necessary information or update flags to indicate that the onboarding is completed
        
        let mainViewController = CameraViewController()
        present(mainViewController, animated: true, completion: nil)
    }
}
