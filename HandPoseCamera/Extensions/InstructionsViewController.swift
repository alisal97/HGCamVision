//
//  InstructionsViewController.swift
//  HGCam
//
//  Created by Aly Salman on 14/07/23.
//  Copyright © 2023 CB Gang. All rights reserved.
//

import Foundation
import UIKit

class InstructionsViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the view
        view.backgroundColor = UIColor.black.withAlphaComponent(0.95)

        // Create and configure the label for the instructions
        let instructionsLabel = UILabel()
        instructionsLabel.translatesAutoresizingMaskIntoConstraints = false
        instructionsLabel.numberOfLines = 0
        instructionsLabel.textAlignment = .center
        instructionsLabel.textColor = UIColor.white
        instructionsLabel.font = UIFont.systemFont(ofSize: 17)
        instructionsLabel.text = """
        For best performance, it's better to show ony one hand, and you have to hold your hand steady until the timer comes up, otherwise it will detect your hands but ignore it, as a safety measure to avoid unwanted actions.
        
        After you see the timer starting you can safely lower your hand
        
        Use the peace sign "✌️" to start/stop recording video
        
        Use the okay sign "👌" to take a picture
        
        You can take pictures while recording, with a shorter timer!
        """
        
        
        
        // Add the instructions label to the view
        view.addSubview(instructionsLabel)
        
        // Set up constraints for the instructions label
        NSLayoutConstraint.activate([
            instructionsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            instructionsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            instructionsLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    
        let dismissButton = UIButton(type: .system)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        dismissButton.setTitle("Dismiss", for: .normal)
        dismissButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        dismissButton.setTitleColor(.white, for: .normal)
        dismissButton.backgroundColor = UIColor.darkGray
        dismissButton.layer.cornerRadius = 12
        dismissButton.addTarget(self, action: #selector(dismissButtonTapped), for: .touchUpInside)
    // Add the dismiss button to the view
    view.addSubview(dismissButton)
    
    // Set up constraints for the dismiss button
    NSLayoutConstraint.activate([
        dismissButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
        dismissButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        dismissButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -43)
    ])
    
    }
    
    @objc func dismissButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

}


class InstructionsViewController3: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the view
        view.backgroundColor = UIColor.black.withAlphaComponent(0.95)

        // Create and configure the label for the instructions
        let instructionsLabel = UILabel()
        instructionsLabel.translatesAutoresizingMaskIntoConstraints = false
        instructionsLabel.numberOfLines = 0
        instructionsLabel.textAlignment = .center
        instructionsLabel.textColor = UIColor.white
        instructionsLabel.font = UIFont.systemFont(ofSize: 18)
        instructionsLabel.text = """
        Disclaimer: this feature is relatively new and experimental, make sure you are in a well lit environment, and provide the developer with any feedback, thank you!
        
        When the timer starts, you can 
        
        Smile and close one eye (or both, but works with just one eye) "😉" to start/stop recording video
        
        Blink/close both of your eyes  "👁️👁️" to take a picture
        
        You can take pictures while recording, with a shorter timer!
        """
        
        
        
        // Add the instructions label to the view
        view.addSubview(instructionsLabel)
        
        // Set up constraints for the instructions label
        NSLayoutConstraint.activate([
            instructionsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            instructionsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            instructionsLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    
        let dismissButton = UIButton(type: .system)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        dismissButton.setTitle("Dismiss", for: .normal)
        dismissButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        dismissButton.setTitleColor(.white, for: .normal)
        dismissButton.backgroundColor = UIColor.darkGray
        dismissButton.layer.cornerRadius = 12
        dismissButton.addTarget(self, action: #selector(dismissButtonTapped), for: .touchUpInside)
    // Add the dismiss button to the view
    view.addSubview(dismissButton)
    
    // Set up constraints for the dismiss button
    NSLayoutConstraint.activate([
        dismissButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
        dismissButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        dismissButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -43)
    ])
    
    }
    
    @objc func dismissButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

}

