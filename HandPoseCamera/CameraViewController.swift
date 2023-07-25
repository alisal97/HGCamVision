//
//  CameraViewController.swift
//  HGCam
//
//  Created by Aly Salman on 18/02/23.
//  Copyright © 2023 Aly. All rights reserved.


import UIKit
import AVKit
import Foundation
import AVFoundation
import Vision
import Photos
import Speech
import AVFAudio


class CameraViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var audioPlayer: AVAudioPlayer?
    private let movieOutput = AVCaptureMovieFileOutput()
    
    private var videoDeviceInput: AVCaptureDeviceInput!
    private let handPoseRequest = VNDetectHumanHandPoseRequest()
    @IBOutlet private var feedbackLabel: UILabel!
    private var captureDevice: AVCaptureDevice?

    static var isRecording = false
    private weak var timerLabel: UILabel?
    static var isTimerRunning = false
    var currentCameraPosition: AVCaptureDevice.Position = .front
    private var activityIndicator: UIActivityIndicatorView!
    var savedTimer: Timer?
    
    static var isCap = false
    private var timer: DispatchSourceTimer?
    var counter = 0
    
    var previousKeypointsMultiArray: MLMultiArray?
    
    var frameCounter = 0
    let handPosePredictionInterval = 11
    
    let model = try? fullyaugmented175cleaned(configuration: MLModelConfiguration())

    let segmentedControl = UISegmentedControl(items: ["Hand Pose", "Voice Commands", "Face Control"])

    var userSelection: Int = 0
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private let audioEngine = AVAudioEngine()
    
    static var word1: String = "cheese"
    static var word2: String = "action"
    static var word3: String = "stop"
    
    var targetWords = [word1, word2, word3].map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
    private var lastSpokenWord: String = ""

    let fontSize: CGFloat = 13
    var isRecognitionTaskRunning = false
    private var flashMode: AVCaptureDevice.FlashMode = .off
    private var flashButton: UIButton!

    
    
    let activityLabel: UILabel = {
        let activityLabel = UILabel()
        activityLabel.text = "Saving Video..."
        activityLabel.textColor = UIColor.darkGray
        activityLabel.font = UIFont.boldSystemFont(ofSize: 28) // Set the font to bold
        activityLabel.textAlignment = .center // Center the text horizontally
        activityLabel.sizeToFit()
        activityLabel.isHidden = true
        activityLabel.translatesAutoresizingMaskIntoConstraints = false

        // Apply a subtle shadow
        activityLabel.layer.shadowColor = UIColor.white.cgColor
        activityLabel.layer.shadowOffset = CGSize(width: 1.5, height: 1.5)
        activityLabel.layer.shadowOpacity = 0.75
        activityLabel.layer.shadowRadius = 1
        
        // Add a pulsating animation
        UIView.animate(withDuration: 1.0, delay: 0, options: [.autoreverse, .repeat], animations: {
            activityLabel.alpha = 0.75
            activityLabel.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }, completion: nil)
        
        
        return activityLabel
    }()

    // Declare a UILabel to display the time elapsed
    static let recordLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00:00"
        label.font = UIFont.systemFont(ofSize: 37, weight: .regular)
        label.textColor = UIColor.white
        label.textAlignment = .center
        return label
    }()
    
    

    
    
    let switchCameraButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 39)
        let image = UIImage(systemName: "arrow.triangle.2.circlepath", withConfiguration: config)?.withTintColor(.white, renderingMode: .alwaysOriginal)
        
        let circleConfig = UIImage.SymbolConfiguration(pointSize: 87)

        let circleImage = UIImage(systemName: "circle.fill", withConfiguration: circleConfig)?.withTintColor(.darkGray, renderingMode: .alwaysOriginal)
        
        let combinedImage = circleImage?.overlayWith(image: image!, offsetX: 0, offsetY: 0)
        
        button.setImage(combinedImage, for: .normal)
        return button
    }()

    
    let questionButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure the question mark image
        let questionConfig = UIImage.SymbolConfiguration(pointSize: 39)
        let questionImage = UIImage(systemName: "questionmark", withConfiguration: questionConfig)?.withTintColor(.white, renderingMode: .alwaysOriginal)
        
        // Configure the circle background image
        let circleConfig = UIImage.SymbolConfiguration(pointSize: 87)
        let circleImage = UIImage(systemName: "circle.fill", withConfiguration: circleConfig)?.withTintColor(.darkGray, renderingMode: .alwaysOriginal)
        
        // Combine the circle background and question mark images
        let combinedImage = circleImage?.overlayWith(image: questionImage!, offsetX: 0, offsetY: 0)
        
        // Set the combined image as the button's image for the normal state
        button.setImage(combinedImage, for: .normal)
        

        return button
    }()

    
    private func setupActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.transform = CGAffineTransform(scaleX: 3.5, y: 3.5)
        activityIndicator.color = UIColor.darkGray
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)

        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let defaults = UserDefaults.standard
        if let savedWord1 = defaults.string(forKey: "Word1") {
            CameraViewController.word1 = savedWord1
        }
        if let savedWord2 = defaults.string(forKey: "Word2") {
            CameraViewController.word2 = savedWord2
        }
        if let savedWord3 = defaults.string(forKey: "Word3") {
            CameraViewController.word3 = savedWord3
        }
        
        updateTargetWords()
        
        
        
        UIApplication.shared.isIdleTimerDisabled = true
        prepareCaptureSession()
        prepareCaptureUI()
        
        addAudioInput()
        
        feedbackLabel = UILabel()
        feedbackLabel.translatesAutoresizingMaskIntoConstraints = false
        feedbackLabel.font = UIFont.boldSystemFont(ofSize: 24)
        feedbackLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        feedbackLabel.textColor = UIColor.white
        feedbackLabel.padding = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)

        view.addSubview(feedbackLabel)

        // Add constraints for the feedback label (adjust them as needed)
        NSLayoutConstraint.activate([
            feedbackLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            feedbackLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 150)
        ])

        
        if let sound = Bundle.main.path(forResource: "shutter", ofType: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: sound))
            } catch {
                print("Error loading sound file: \(error.localizedDescription)")
            }
            
        }
        segmentedControl.selectedSegmentIndex = userSelection

        segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged), for: .valueChanged)

        
        let fontAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: fontSize)]
        segmentedControl.setTitleTextAttributes(fontAttributes, for: .normal)

        
        setupActivityIndicator()
        prepareTimerView()
        cameraUI()
        handPoseRequest.maximumHandCount = 1
        
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)

        // Add observer for entering foreground
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)

    }
    
    func setupSegmentedControl() {
        if CameraViewController.isRecording || CameraViewController.isCap || CameraViewController.isTimerRunning {
            
            segmentedControl.isEnabled = false
            segmentedControl.isHidden = true
        } else if !CameraViewController.isRecording && !CameraViewController.isTimerRunning {
            segmentedControl.isEnabled = true
            segmentedControl.isHidden = false

        }


    }
    @objc func appDidEnterBackground() {
        // Stop speech recognition when app enters the background
        stopSpeechRecognition()
    }

    @objc func appWillEnterForeground() {
        if userSelection == 1 {
            startSpeechRecognition()
            updateTargetWords()

        }
    }

    @objc func questionButtonTapped() {
        if userSelection == 0 {
            let instructionsVC = InstructionsViewController()
            instructionsVC.modalPresentationStyle = .formSheet
            present(instructionsVC, animated: true, completion: nil)
        }

        else if userSelection == 1 {
            let configurationVC = ConfigurationViewController()
            configurationVC.delegate = self
            configurationVC.modalPresentationStyle = .formSheet
            present(configurationVC, animated: true, completion: nil)
        }
        else if userSelection == 2 {
            let instructionsVC = InstructionsViewController3()
            instructionsVC.modalPresentationStyle = .formSheet
            present(instructionsVC, animated: true, completion: nil)
        }
    }

    
    func stopSpeechRecognition() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        print("recognizing stopped")
    }

    func startSpeechRecognition() {
        speechRecognizer.delegate = self

        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation {
                if authStatus == .authorized && self.userSelection == 1 {
                    self.startRecognizing()
                    self.updateTargetWords()
                }
            }
        }
    }

    
    private func startRecognizing() {
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }

        guard !audioEngine.isRunning else { return }
        
        // Print a message to indicate that recognition is starting
        print("Recognizing started")

        let audioSession = AVAudioSession.sharedInstance()
        do { //playAndRecord mode is required for relaunching the audio session after background then foreground
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .defaultToSpeaker)
            try audioSession.overrideOutputAudioPort(.none)
            
            // Activate the audio session
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Error setting up audio session: \(error.localizedDescription)")
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.taskHint = .dictation

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine: \(error.localizedDescription)")
        }

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                self.processRecognitionResult(result)
            }
            

            if let error = error {
                print("Speech recognition error: \(error.localizedDescription)")
                // Handle the error appropriately, e.g., display an error message to the user
            }

            // Print a message to indicate that recognition task has completed
            print("Recognizing completed")

            // Restart the recognition task if it's still running
            if self.isRecognitionTaskRunning {
                self.startRecognizing()
            }
        }
    }

    private func processRecognitionResult(_ result: SFSpeechRecognitionResult) {
        
        if let lastSegment = result.bestTranscription.segments.last {
            let currentWord = lastSegment.substring
            print("Last spoken word: \(currentWord)")
            print(targetWords)
            
            for targetWord in targetWords {
                if currentWord.lowercased().contains(targetWord.lowercased()) {
                    switch targetWord {
                    case CameraViewController.word1:
                        if !CameraViewController.isTimerRunning && !CameraViewController.isRecording && !CameraViewController.isCap {
                            runTimer(seconds: 3) { [weak self] in
                                guard let self = self else { return }
                                CameraViewController.isCap = true
                                self.captureImage()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.95) {
                                    CameraViewController.isCap = false
                                }
                            }
                        } else if !CameraViewController.isTimerRunning && CameraViewController.isRecording && !CameraViewController.isCap {
                            runTimer(seconds: 1) { [weak self] in
                                guard let self = self else { return }
                                self.captureImage()
                                CameraViewController.isCap = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    CameraViewController.isCap = false
                                }
                            }
                        }
                    case CameraViewController.word2:
                        if !CameraViewController.isTimerRunning && !CameraViewController.isRecording {
                            runTimer(seconds: 3) { [weak self] in
                                guard let self = self else { return }
                                self.startRecording()
                            }
                        }
                    case CameraViewController.word3:
                        if !CameraViewController.isTimerRunning && CameraViewController.isRecording {
                            self.stopRecording()
                        }
                    default:
                        break
                    }
                }
            }
            
            // Update the last spoken word
            lastSpokenWord = currentWord
        }
    }
    
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        let newOrientation = UIDevice.current.orientation
        
        if let connection = self.videoPreviewLayer?.connection {
            switch newOrientation {
            case .portrait:
                connection.videoOrientation = .portrait
            case .landscapeRight:
                connection.videoOrientation = .landscapeLeft
            case .landscapeLeft:
                connection.videoOrientation = .landscapeRight
            case .portraitUpsideDown:
                connection.videoOrientation = .portraitUpsideDown
            default:
                connection.videoOrientation = .portrait
            }
        }
    }
    
    func startTimer() {
        if timer == nil {
            timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
            timer?.schedule(deadline: .now(), repeating: .seconds(1))
            CameraViewController.recordLabel.textColor = .red
            timer?.setEventHandler { [weak self] in
                self?.counter += 1
                DispatchQueue.main.async {
                    self?.updateTimerLabel()
                }
            }
            timer?.resume()
        }
    }

    func stopTimer() {
        timer?.cancel()
        timer = nil
        counter = 0
        CameraViewController.recordLabel.textColor = .white
        updateTimerLabel()
    }
    func updateTimerLabel() {
        let hours = counter / 3600
        let minutes = (counter % 3600) / 60
        let seconds = counter % 60
        CameraViewController.recordLabel.text = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    func videoSaved() {
        let alert = UIAlertController(title: nil, message: "Video added to Photos successfully", preferredStyle: .alert)
        
        self.present(alert, animated: true, completion: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true, completion: nil)
        }
    }

//    func formattedTime() -> String {
//        let minutes = counter / 60
//        let seconds = counter % 60
//        return String(format: "%02d:%02d", minutes, seconds)
//    }
    // to keep screen on when recording.
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Re-enable idle timer when the app goes into the background or is closed
        UIApplication.shared.isIdleTimerDisabled = false
        
        stopSpeechRecognition()

    }
    
    
    private func prepareCaptureSession() {
        let captureSession = AVCaptureSession()
        
        // Select a front facing camera, make an input.
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else { return }
        
        // Lock the device for configuration
        do {
            try captureDevice.lockForConfiguration()
            
            let desiredFrameRate: Double = 60.0
            
            for format in captureDevice.formats {
                for range in format.videoSupportedFrameRateRanges {
                    if range.maxFrameRate >= desiredFrameRate && range.minFrameRate <= desiredFrameRate {
                        captureDevice.activeFormat = format
                        captureDevice.activeVideoMinFrameDuration = CMTime(value: 1, timescale: CMTimeScale(desiredFrameRate))
                        captureDevice.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: CMTimeScale(desiredFrameRate))
                        break
                    }
                }
            }
            
            // Unlock the device after configuration
            captureDevice.unlockForConfiguration()
        } catch {
            fatalError("Failed to configure video capture device: \(error)")
        }
        
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        
        captureSession.addInput(input)
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: .main)
        captureSession.addOutput(videoOutput)
        
        let photoOutput = AVCapturePhotoOutput()
        captureSession.addOutput(photoOutput)
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            fatalError("Could not get video device")
        }
        
        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            if captureSession.canAddInput(videoDeviceInput) {
                captureSession.addInput(videoDeviceInput)
            }
        } catch {
            fatalError("Could not create video device input: \(error.localizedDescription)")
        }
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption(_:)), name: AVAudioSession.interruptionNotification, object: nil)

        captureSession.sessionPreset = .high
        self.captureSession = captureSession
        captureSession.addOutput(movieOutput)
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    
    @objc func handleInterruption(_ notification: Notification) {
        guard let interruptionType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt else {
            return
        }

        let interruptionTypeValue = AVAudioSession.InterruptionType(rawValue: interruptionType)

        if interruptionTypeValue == .began {
            // Recording interrupted, stop the recording
            if movieOutput.isRecording {
                stopTimer()
                movieOutput.stopRecording()
            }
        }
    }

    func addAudioInput() {
        
           let audioSession = AVAudioSession.sharedInstance()
           do {
               
               try audioSession.setCategory(.playAndRecord, mode: .videoRecording)

//               try audioSession.setCategory(.playAndRecord, mode: .videoRecording, options: [.allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker])
               try audioSession.setActive(true, options: .init())
               let audioDevice = AVCaptureDevice.default(for: AVMediaType.audio)!
               let audioInput = try AVCaptureDeviceInput(device: audioDevice)
               if ((captureSession?.canAddInput(audioInput)) != nil) {
                   captureSession!.addInput(audioInput)
               }
               
               
           } catch {
               print("Error setting up audio input: \(error.localizedDescription)")
           }
       }

    @objc private func toggleCamera() {
        
        // Toggle the camera position
        currentCameraPosition = (currentCameraPosition == .front) ? .back : .front
        
        // Stop the capture session and remove the inputs
        captureSession?.stopRunning()
        for input in captureSession!.inputs {
            captureSession?.removeInput(input)
        }
        
        // Re-add the inputs for the new camera position
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraPosition) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSession?.addInput(input)
        
        addAudioInput()

        DispatchQueue.global(qos: .background).async { [self] in
            captureSession?.startRunning()
        }
        
    }
    

    private func cameraUI() {
        // Create a new view for the grey rectangle
        let topView = UIView()
        topView.translatesAutoresizingMaskIntoConstraints = false
        topView.backgroundColor = UIColor.black.withAlphaComponent(0.83) // set the background color to transparent grey
        view.addSubview(topView)
        
        topView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        topView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        topView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        topView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.17).isActive = true
        
        // Create a new view for the grey rectangle
        let bottomView = UIView()
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        bottomView.backgroundColor = UIColor.black.withAlphaComponent(0.83) // set the background color to transparent grey
        view.addSubview(bottomView)
        
        bottomView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        bottomView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        bottomView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        bottomView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.19).isActive = true
        
        view.addSubview(CameraViewController.recordLabel)
        CameraViewController.recordLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            CameraViewController.recordLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 23),
            CameraViewController.recordLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        
        
        view.addSubview(switchCameraButton)
        
        switchCameraButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            switchCameraButton.widthAnchor.constraint(equalToConstant: 45),
            switchCameraButton.heightAnchor.constraint(equalToConstant: 45),
            switchCameraButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            switchCameraButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15)
        ])
        
        
        switchCameraButton.addTarget(self, action: #selector(toggleCamera), for: .touchUpInside)
        
        view.addSubview(activityLabel)
        
        NSLayoutConstraint.activate([
            activityLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            activityLabel.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ])
        
        
        view.addSubview(questionButton)


        NSLayoutConstraint.activate([
            questionButton.widthAnchor.constraint(equalToConstant: 45),
            questionButton.heightAnchor.constraint(equalToConstant: 45),
            questionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            questionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15)
        ])
        
        questionButton.addTarget(self, action: #selector(questionButtonTapped), for: .touchUpInside)

        
        view.addSubview(segmentedControl)


        segmentedControl.translatesAutoresizingMaskIntoConstraints = false

        segmentedControl.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        segmentedControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -85 ).isActive = true
        
        
        flashButton = UIButton(type: .custom)
        let flashConfig = UIImage.SymbolConfiguration(pointSize: 27)
        
        flashButton.translatesAutoresizingMaskIntoConstraints = false
        flashButton.setImage(UIImage(systemName: "bolt.slash.circle", withConfiguration: flashConfig)?.withTintColor(.white, renderingMode: .alwaysOriginal), for: .normal)
        flashButton.addTarget(self, action: #selector(flashButtonTapped(_:)), for: .touchUpInside)
        view.addSubview(flashButton)
        
        flashButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20.0).isActive = true
        flashButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 75).isActive = true
        flashButton.widthAnchor.constraint(equalToConstant: 40.0).isActive = true
        flashButton.heightAnchor.constraint(equalToConstant: 40.0).isActive = true
        flashButton.clipsToBounds = true


    }
    
    
    private func prepareCaptureUI() {
        guard let session = captureSession else { return }
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer)
        
        self.videoPreviewLayer = videoPreviewLayer
        }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if userSelection == 1 {
            startSpeechRecognition()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopSpeechRecognition()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        

        
        if let connection =  self.videoPreviewLayer?.connection {
            let currentDevice: UIDevice = UIDevice.current
            let orientation: UIDeviceOrientation = currentDevice.orientation
            let previewLayerConnection : AVCaptureConnection = connection
            
            if previewLayerConnection.isVideoOrientationSupported {
                switch (orientation) {
                case .portrait:
                    previewLayerConnection.videoOrientation = .portrait
                case .landscapeRight:
                    previewLayerConnection.videoOrientation = .landscapeLeft
                case .landscapeLeft:
                    previewLayerConnection.videoOrientation = .landscapeRight
                case .portraitUpsideDown:
                    previewLayerConnection.videoOrientation = .portraitUpsideDown
                default:
                    previewLayerConnection.videoOrientation = .portrait
                }
                self.videoPreviewLayer?.frame = self.view.bounds
            }
        }
    }
    
    
    func startRecording() {
        if !movieOutput.isRecording {
            let outputPath = NSTemporaryDirectory() + "output\(Date().timeIntervalSince1970).mov"
            let outputFileURL = URL(fileURLWithPath: outputPath)

            movieOutput.startRecording(to: outputFileURL, recordingDelegate: self)
            startTimer()
            CameraViewController.isRecording = true
            setupSegmentedControl()
        }
    }

    // to stop recording video
    func stopRecording() {
        if movieOutput.isRecording {
            movieOutput.stopRecording()
            stopTimer()
        }
    }
    
    private func prepareTimerView() {
        let timerLabel = UILabel()
        timerLabel.textAlignment = .center
        timerLabel.font = UIFont.systemFont(ofSize: 300)

        view.addSubview(timerLabel)
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timerLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        self.timerLabel = timerLabel
    }

    // capturing images
    private func captureImage() {
        guard let photoOutput = captureSession?.outputs.first(where: { $0 is AVCapturePhotoOutput }) as? AVCapturePhotoOutput else { return }
        
        // Create AVCapturePhotoSettings with the appropriate flash mode
        let settings = AVCapturePhotoSettings()
        settings.flashMode = flashMode
        
        photoOutput.capturePhoto(with: settings, delegate: self)
        
        let shutterView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        shutterView.backgroundColor = UIColor.black
        shutterView.alpha = 0.0
        view.addSubview(shutterView)
        
        UIView.animate(withDuration: 0.1, animations: {
            shutterView.alpha = 1.0
        }, completion: { _ in
            UIView.animate(withDuration: 0.13, animations: {
                shutterView.alpha = 0.0
            }, completion: { _ in
                shutterView.removeFromSuperview()
            })
        })
        audioPlayer?.play()
    }
    private func toggleFlash() {
        switch flashMode {
        case .off:
            flashMode = .on
        case .on:
            flashMode = .auto
        case .auto:
            flashMode = .off
        default:
            break
        }
        updateFlashButtonAppearance()
    }
    
    private func updateFlashButtonAppearance() {
        let flashConfig = UIImage.SymbolConfiguration(pointSize: 27)
        
        switch flashMode {
        case .off:
            flashButton.setImage(UIImage(systemName: "bolt.slash.circle", withConfiguration: flashConfig)?.withTintColor(.white, renderingMode: .alwaysOriginal), for: .normal)
        case .on:
            flashButton.setImage(UIImage(systemName: "bolt.circle.fill", withConfiguration: flashConfig)?.withTintColor(.white, renderingMode: .alwaysOriginal), for: .normal)
        case .auto:
            flashButton.setImage(UIImage(systemName: "a.circle.fill", withConfiguration: flashConfig)?.withTintColor(.white, renderingMode: .alwaysOriginal), for: .normal)
        default:
            break
        }
    }
    
    @IBAction func flashButtonTapped(_ sender: Any) {
        toggleFlash()
    }
    private func runTimer(seconds: Int, completion: @escaping () -> Void) {
        CameraViewController.isTimerRunning = true
        
        setupSegmentedControl()

        var timeLeft = seconds
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        timer.schedule(deadline: .now(), repeating: .seconds(1))
        
        timer.setEventHandler { [weak self] in
            self?.timerLabel?.text = "\(timeLeft)"
            timeLeft -= 1
            
            if timeLeft < 0 {
                timer.cancel()
                CameraViewController.isTimerRunning = false
                self?.timerLabel?.text = nil
                self?.setupSegmentedControl()

                completion()
            }
        }
        
        timer.resume()
    }

}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @objc func segmentedControlValueChanged(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            userSelection = 0
            stopSpeechRecognition()
            feedbackLabel.isHidden = false

        case 1:
            userSelection = 1
            startSpeechRecognition()
            feedbackLabel.isHidden = true
            updateTargetWords()


        case 2:
            userSelection = 2
            stopSpeechRecognition()
            feedbackLabel.isHidden = true

            

//        case 3:
//            userSelection = 3
//            stopSpeechRecognition()
        default:
            break
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if userSelection == 0 {
            let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .leftMirrored, options: [:])
            
            do {
                try handler.perform([handPoseRequest])
            } catch {
                print(error)
            }
            
            guard let handPoses = handPoseRequest.results, !handPoses.isEmpty else {
                return
            }
            
            guard let observation = handPoses.first else {return}
            
            frameCounter += 1
            if frameCounter % handPosePredictionInterval == 0 {
                makePrediction(handPoseObservation: observation)
                frameCounter = 0
            }
        }
            
        else if userSelection == 2 {
            
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            
            let faceDetectionRequest = VNDetectFaceLandmarksRequest(completionHandler: { [weak self] request, error in
                guard let observations = request.results as? [VNFaceObservation], !observations.isEmpty else { return }
                
                for observation in observations {
                    if let landmarks = observation.landmarks,
//                       let faceContour = landmarks.faceContour,
                       let leftEye = landmarks.leftEye,
                       let rightEye = landmarks.rightEye,
//                       let outerLips = landmarks.outerLips,
//                       let rightBrow = landmarks.rightEyebrow,
//                       let leftBrow = landmarks.leftEyebrow,
                        let innerLips = landmarks.innerLips {
                        
                        
//                        let faceContourPoints = faceContour.normalizedPoints
                        let leftEyePoints = leftEye.normalizedPoints
                        let rightEyePoints = rightEye.normalizedPoints
//                        let outerLipsPoints = outerLips.normalizedPoints
                        let innerLipsPoints = innerLips.normalizedPoints
//                        let leftEyebrowPoints = leftBrow.normalizedPoints
//                        let rightEyebrowPoints = rightBrow.normalizedPoints

//                        let eyebrowRaiseThreshold: CGFloat = 0.06 // Adjust the threshold value as needed
//
//
//
//
//                        let leftEyebrowTopPoint = leftEyebrowPoints[2]
//                        let leftEyebrowBottomPoint = leftEyebrowPoints[5]
//                        let leftEyebrowRaiseDistance = abs(leftEyebrowTopPoint.y - leftEyebrowBottomPoint.y)
//                        let isLeftEyebrowRaised = leftEyebrowRaiseDistance >= eyebrowRaiseThreshold
//
//                        let rightEyebrowTopPoint = rightEyebrowPoints[2]
//                        let rightEyebrowBottomPoint = rightEyebrowPoints[5]
//                        let rightEyebrowRaiseDistance = abs(rightEyebrowTopPoint.y - rightEyebrowBottomPoint.y)
//                        let isRightEyebrowRaised = rightEyebrowRaiseDistance >= eyebrowRaiseThreshold

                        
                        
                        let smileThreshold: CGFloat = 0.143
                        let topLipCenter = innerLipsPoints[3].y
                        let bottomLipCenter = innerLipsPoints[0].y
                        let mouthOpenDistance = topLipCenter - bottomLipCenter
                        let isSmiling = mouthOpenDistance > smileThreshold

                        
                        // Check if the left eye is closed
                        let LeyeClosedThreshold: CGFloat = 0.0671
                        let leftEyeTopPoint = leftEyePoints[1]
                        let leftEyeBottomPoint = leftEyePoints[4]
                        let leftEyeOpenDistance = abs(leftEyeBottomPoint.y - leftEyeTopPoint.y)
                        let isLeftEyeClosed = leftEyeOpenDistance <= LeyeClosedThreshold
                        
                        
                        let ReyeClosedThreshold: CGFloat = 0.0613
                        let rightEyeTopPoint = rightEyePoints[1]
                        let rightEyeBottomPoint = rightEyePoints[4]
                        let rightEyeOpenDistance = abs(rightEyeBottomPoint.y - rightEyeTopPoint.y)
                        let isRightEyeClosed = rightEyeOpenDistance <= ReyeClosedThreshold

//                        print("right eye \(rightEyeOpenDistance)...left eye \(leftEyeOpenDistance)")

                        if !isSmiling && (isLeftEyeClosed && isRightEyeClosed) && !CameraViewController.isTimerRunning && !CameraViewController.isRecording && !CameraViewController.isCap {
                            self?.runTimer(seconds: 3, completion: {
                                CameraViewController.isCap = true
                                self?.captureImage()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.95) {
                                    CameraViewController.isCap = false
                                }
                            })
                        } else if !isSmiling && (isLeftEyeClosed && isRightEyeClosed) && !CameraViewController.isTimerRunning && CameraViewController.isRecording && !CameraViewController.isCap {
                            self?.runTimer(seconds: 1, completion: {
                                CameraViewController.isCap = true
                                self?.captureImage()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    CameraViewController.isCap = false
                                }
                            })
                            
                        } else if isSmiling && ( isLeftEyeClosed || isRightEyeClosed ) && !CameraViewController.isTimerRunning && !CameraViewController.isRecording && !CameraViewController.isCap {
                            self?.runTimer(seconds: 3, completion: {
                                self?.startRecording()
                            })
                        } else if isSmiling && ( isLeftEyeClosed || isRightEyeClosed ) && !CameraViewController.isTimerRunning && CameraViewController.isRecording {
                            self?.stopRecording()
                            CameraViewController.isRecording = true
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
                                CameraViewController.isCap = false
                            }
                        }
                    }
                }
            }
            )
            faceDetectionRequest.revision = VNDetectFaceLandmarksRequestRevision3

            // Create a request handler
            let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer ,options: [:])
            
            // Perform the face detection request
            do {
                try requestHandler.perform([faceDetectionRequest])
            } catch {
                print("Error performing face detection: \(error)")
            }
            
        }
    }

    func makePrediction(handPoseObservation: VNHumanHandPoseObservation) {
        guard let keypointsMultiArray = try? handPoseObservation.keypointsMultiArray() else { fatalError() }
        do {
            let prediction = try model!.prediction(poses: keypointsMultiArray)
            let label = prediction.label
            guard let confidence = prediction.labelProbabilities[label] else { return }
            print("label: \(prediction.label)\nconfidence: \(confidence)")
        
            if confidence > 0.97 {
                DispatchQueue.main.async { [self] in
                    let currentPrediction = try? model!.prediction(poses: keypointsMultiArray)
                    let currentLabel = currentPrediction?.label
                    
                    let isHandMoving = isHandPoseMoving(previous: previousKeypointsMultiArray, current: keypointsMultiArray)
                    
                    previousKeypointsMultiArray = keypointsMultiArray
                    
                    self.feedbackLabel.text = isHandMoving ? "Hold still until you see the timer!": ""
                    
                    if CameraViewController.isTimerRunning || CameraViewController.isRecording || CameraViewController.isCap {
                        
                        self.feedbackLabel.text = "Now you can lower your hand!"
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3 ) {
                            
                            self.feedbackLabel.isHidden = true
                            
                        }
                        
                    } else if !CameraViewController.isTimerRunning && !CameraViewController.isRecording && !CameraViewController.isCap {
                        feedbackLabel.isHidden = false
                    }
                    
                    
                    
                    
                    if currentLabel == label && confidence > 0.97 && !isHandMoving {
                        switch label {
                        case "ok":
                            if !CameraViewController.isTimerRunning && !CameraViewController.isRecording && !CameraViewController.isCap {
                                runTimer(seconds: 3, completion: { [weak self] in
                                    guard let self else { return }
                                    CameraViewController.isCap = true
                                    self.captureImage()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.95) {
                                        CameraViewController.isCap = false
                                    }
                                })
                            }
                            else if !CameraViewController.isTimerRunning && CameraViewController.isRecording && !CameraViewController.isCap {
                                
                                runTimer(seconds: 1, completion: { [weak self] in
                                    guard let self else { return }
                                    
                                    self.captureImage()
                                    CameraViewController.isCap = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        CameraViewController.isCap = false
                                    }
                                    
                                }
                                    )
                                         }
                        case "peace":
                            if !CameraViewController.isTimerRunning && !CameraViewController.isRecording {
                                runTimer(seconds: 3, completion: { [weak self] in
                                    guard let self else { return }
                                    self.startRecording()
                                })
                            }
                            else if !CameraViewController.isTimerRunning && CameraViewController.isRecording {
                                self.stopRecording()
                            }

                        default:
                            break
                        }
                    }
                    switch label {
                    case "backgrounds":
                        if !self.feedbackLabel.isHidden {
                            
                            self.feedbackLabel.isHidden = true
                        }


                    default:
                        break
                    }

                }
            }
            
        } catch {
            print("Prediction error")
        }
    }
    

    // Function to check if the hand pose is moving
    func isHandPoseMoving(previous: MLMultiArray?, current: MLMultiArray) -> Bool {
        guard let previous = previous else { return true }

        // Compare the previous and current hand pose arrays
        let poseDistance = calculatePoseDistance(previous, current)

        // Define a threshold for movement detection
        let movementThreshold: Double = 0.037
        
        // If the pose distance is above the threshold, consider it as moving
        return poseDistance > movementThreshold
    }
    
    
    func calculatePoseDistance(_ pose1: MLMultiArray, _ pose2: MLMultiArray) -> Double {
        let numKeypoints = 21

        var distanceSum: Double = 0.0
        

        for i in 0..<numKeypoints {
            let pose1X = pose1[i].doubleValue
            let pose1Y = pose1[i + numKeypoints].doubleValue
            let pose1Z = pose1[i + (2 * numKeypoints)].doubleValue

            let pose2X = pose2[i].doubleValue
            let pose2Y = pose2[i + numKeypoints].doubleValue
            let pose2Z = pose2[i + (2 * numKeypoints)].doubleValue

            // Calculate the Euclidean distance between the keypoints
            let distance = sqrt(pow(pose2X - pose1X, 2) + pow(pose2Y - pose1Y, 2) + pow(pose2Z - pose1Z, 2))

            // Add the distance to the sum
            distanceSum += distance
        }

        // Calculate the average distance
        let averageDistance = distanceSum / Double(numKeypoints)

        return averageDistance
        
    }


}
// output for captured photos
extension CameraViewController: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else { return }
        guard let image = UIImage(data: imageData) else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
}

extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("Started recording to \(fileURL)")
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error recording video: \(error.localizedDescription)")
            CameraViewController.isRecording = false
            stopTimer()
            
        } else {
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
                    }) { success, error in
                        if success {
                            DispatchQueue.main.async { [self] in
                                videoSaved()
                                CameraViewController.isRecording = false
                                self.setupSegmentedControl()

                            }

                        } else {
                            print("Error saving video to photos: \(error?.localizedDescription ?? "unknown error")")
                            CameraViewController.isRecording = false
                            self.setupSegmentedControl()


                        }
                    }
                } else {
                    print("Access to photo library denied")
                    CameraViewController.isRecording = false
                    self.setupSegmentedControl()

                }
            }

        }
    }
}

extension CameraViewController: ConfigurationViewControllerDelegate {
    func wordsDidChange(word1: String, word2: String, word3: String) {
        CameraViewController.word1 = word1
        CameraViewController.word2 = word2
        CameraViewController.word3 = word3
        updateTargetWords()
    }

    private func updateTargetWords() {
        targetWords = [CameraViewController.word1, CameraViewController.word2, CameraViewController.word3].map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
    }
}
