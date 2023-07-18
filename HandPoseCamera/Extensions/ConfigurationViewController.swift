//
//  ConfigurationViewController.swift
//  HGCam
//
//  Created by Aly Salman on 18/07/23.
//  Copyright © 2023 CB Gang. All rights reserved.
//

import Foundation
import UIKit


class ConfigurationViewController: UIViewController, UITextFieldDelegate {
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
        You must write one word.
        
        for better functionality, use English words.
        """
        
        // Word 1 Label
        let word1Label = UILabel()
        word1Label.translatesAutoresizingMaskIntoConstraints = false
        word1Label.textColor = .white
        word1Label.text = "Take Picture Command:"
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
        word1TextField.delegate = self // Set the text field delegate
        
        // Word 2 Label
        let word2Label = UILabel()
        word2Label.translatesAutoresizingMaskIntoConstraints = false
        word2Label.textColor = .white
        word2Label.text = "Start Video Recording Command:"
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
        word2TextField.delegate = self // Set the text field delegate
        
        // Word 3 Label
        let word3Label = UILabel()
        word3Label.translatesAutoresizingMaskIntoConstraints = false
        word3Label.textColor = .white
        word3Label.text = "Stop Video Recording Command:"
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
        word3TextField.delegate = self // Set the text field delegate
        
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
        view.addSubview(saveButton)
        
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
        
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc func saveButtonTapped() {
        guard let word1 = word1TextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !word1.isEmpty,
              let word2 = word2TextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !word2.isEmpty,
              let word3 = word3TextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !word3.isEmpty else {
            return
        }
        
        // Save the words to UserDefaults
        let defaults = UserDefaults.standard
        defaults.set(word1, forKey: "Word1")
        defaults.set(word2, forKey: "Word2")
        defaults.set(word3, forKey: "Word3")
        
        delegate?.wordsDidChange(word1: word1, word2: word2, word3: word3)
        dismiss(animated: true, completion: nil)
    }

}
protocol ConfigurationViewControllerDelegate: AnyObject {
    func wordsDidChange(word1: String, word2: String, word3: String)
    
}
