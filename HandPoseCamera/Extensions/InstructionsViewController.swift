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
        instructionsLabel.font = UIFont.systemFont(ofSize: 18)
        instructionsLabel.text = """
        You have to hold your hand steady until the timer comes up, otherwise it will not work
        
        After you see the timer you can safely lower your hand
        
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

class ConfigurationViewController: UIViewController {
    weak var delegate: ConfigurationViewControllerDelegate?
    private var word1TextField: UITextField!
    private var word2TextField: UITextField!
    private var word3TextField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.95)
        
        // Instructions Label
        let instructionsLabel = UILabel()
        instructionsLabel.translatesAutoresizingMaskIntoConstraints = false
        instructionsLabel.textColor = .white
        instructionsLabel.font = UIFont.systemFont(ofSize: 18)
        instructionsLabel.numberOfLines = 0
        instructionsLabel.textAlignment = .center
        instructionsLabel.text = """
        You can change the voice command words here
        
        You must write one word, for better functionality,
        
        use English words.
        """

        
        
        
        // Word 1 Label
        let word1Label = UILabel()
        word1Label.translatesAutoresizingMaskIntoConstraints = false
        word1Label.textColor = .white
        word1Label.text = "Take Pictures:"
        word1Label.textAlignment = .left
        word1Label.font = UIFont.systemFont(ofSize: 16)

        // Word 1 TextField
        word1TextField = UITextField()
        word1TextField.text = CameraViewController.word1
        word1TextField.translatesAutoresizingMaskIntoConstraints = false
        word1TextField.placeholder = "To Take Pictures"
        word1TextField.textColor = .white
        word1TextField.backgroundColor = .darkGray
        word1TextField.layer.cornerRadius = 8

        // Word 2 Label
        let word2Label = UILabel()
        word2Label.translatesAutoresizingMaskIntoConstraints = false
        word2Label.textColor = .white
        word2Label.text = "Start Video Recording:"
        word2Label.textAlignment = .left
        word2Label.font = UIFont.systemFont(ofSize: 16)

        // Word 2 TextField
        word2TextField = UITextField()
        word2TextField.translatesAutoresizingMaskIntoConstraints = false
        word2TextField.text = CameraViewController.word2
        word2TextField.placeholder = "To Start Recording Video"
        word2TextField.textColor = .white
        word2TextField.backgroundColor = .darkGray
        word2TextField.layer.cornerRadius = 8

        // Word 3 Label
        let word3Label = UILabel()
        word3Label.translatesAutoresizingMaskIntoConstraints = false
        word3Label.textColor = .white
        word3Label.text = "Stop Video Recording"
        word3Label.textAlignment = .left
        word3Label.font = UIFont.systemFont(ofSize: 16)

        // Word 3 TextField
        word3TextField = UITextField()
        word3TextField.translatesAutoresizingMaskIntoConstraints = false
        word3TextField.text = CameraViewController.word3
        word3TextField.placeholder = "To Stop Recording Video"
        word3TextField.textColor = .white
        word3TextField.backgroundColor = .darkGray
        word3TextField.layer.cornerRadius = 8

        // Save Button
        let saveButton = UIButton(type: .system)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.setTitle("Save", for: .normal)
        saveButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.backgroundColor = UIColor.systemBlue
        saveButton.layer.cornerRadius = 12
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)


        
        
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        // Add UI elements to the container view
        container.addSubview(word1Label)
        container.addSubview(word1TextField)
        container.addSubview(word2Label)
        container.addSubview(word2TextField)
        container.addSubview(word3Label)
        container.addSubview(word3TextField)
        container.addSubview(instructionsLabel)

        NSLayoutConstraint.activate([
            instructionsLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 100),
            instructionsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            container.topAnchor.constraint(equalTo: instructionsLabel.bottomAnchor, constant: 20),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            word1Label.topAnchor.constraint(equalTo: container.topAnchor),
            word1Label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            word1Label.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            word1TextField.topAnchor.constraint(equalTo: word1Label.bottomAnchor, constant: 5),
            word1TextField.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            word1TextField.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            word2Label.topAnchor.constraint(equalTo: word1TextField.bottomAnchor, constant: 20),
            word2Label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            word2Label.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            word2TextField.topAnchor.constraint(equalTo: word2Label.bottomAnchor, constant: 5),
            word2TextField.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            word2TextField.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            word3Label.topAnchor.constraint(equalTo: word2TextField.bottomAnchor, constant: 20),
            word3Label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            word3Label.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            word3TextField.topAnchor.constraint(equalTo: word3Label.bottomAnchor, constant: 5),
            word3TextField.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            word3TextField.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            saveButton.topAnchor.constraint(equalTo: container.bottomAnchor, constant: 20),
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 30),
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -70)
        ])


        // Set up constraints
        NSLayoutConstraint.activate([
            instructionsLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 100),
            instructionsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            word1Label.topAnchor.constraint(equalTo: instructionsLabel.bottomAnchor, constant: 20),
            word1Label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            word1Label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            word1TextField.topAnchor.constraint(equalTo: word1Label.bottomAnchor, constant: 5),
            word1TextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            word1TextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            word2Label.topAnchor.constraint(equalTo: word1TextField.bottomAnchor, constant: 20),
            word2Label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            word2Label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            word2TextField.topAnchor.constraint(equalTo: word2Label.bottomAnchor, constant: 5),
            word2TextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            word2TextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            word3Label.topAnchor.constraint(equalTo: word2TextField.bottomAnchor, constant: 20),
            word3Label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            word3Label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            word3TextField.topAnchor.constraint(equalTo: word3Label.bottomAnchor, constant: 5),
            word3TextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            word3TextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            saveButton.topAnchor.constraint(equalTo: word3TextField.bottomAnchor, constant: 20),
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 30),
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -70)
        ])

        // Add tap gesture recognizer to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc func saveButtonTapped() {
        guard let word1 = word1TextField.text,
              let word2 = word2TextField.text,
              let word3 = word3TextField.text else {
            return
        }
        delegate?.wordsDidChange(word1: word1, word2: word2, word3: word3)
        dismiss(animated: true, completion: nil)

    }
    @objc func cancelButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

}
protocol ConfigurationViewControllerDelegate: AnyObject {
    func wordsDidChange(word1: String, word2: String, word3: String)
}

class InstructionsViewController3: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the view
        view.backgroundColor = UIColor.clear
        
        // Create and configure the label for the instructions
        let instructionsLabel = UILabel()
        instructionsLabel.translatesAutoresizingMaskIntoConstraints = false
        instructionsLabel.numberOfLines = 0
        instructionsLabel.textAlignment = .center
        instructionsLabel.textColor = UIColor.white
        instructionsLabel.font = UIFont.systemFont(ofSize: 18)
        instructionsLabel.text = """
        Disclaimer: this feature is relatively new and experimental, make sure you are in a well lit environment, and provide the developer with any feedback, thank you!
        
        After you see the timer you can safely lower your hand
        
        Smile and close one eye (or both, but works with just one eye) "😉" to start/stop recording video
        
        Blink/close both of your eyes  "👁️👁️" to take a picture
        
        You can take pictures while recording, with a shorter timer!
        """
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.69)
        
        
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

