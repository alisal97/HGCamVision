//
//  CameraViewController.swift
//  HGCam
//
//  Created by Aly Salman on 18/02/23.
//  Copyright © 2023 CB Gang. All rights reserved.


import UIKit
import AVKit
import Foundation
import AVFoundation
import Vision
import Photos
import Speech
import AVFAudio

class CameraViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    let videoQueue = DispatchQueue(label: "com.example.videoQueue")
    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var audioPlayer: AVAudioPlayer? //for playing shutter sound
    private let movieOutput = AVCaptureMovieFileOutput()
    
    private var videoDeviceInput: AVCaptureDeviceInput!
    private let handPoseRequest = VNDetectHumanHandPoseRequest()
    
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
    let handPosePredictionInterval = 9
    
    let model = try? fullyaugmented175cleaned(configuration: MLModelConfiguration())
    private let handGestureProcessor = HandGestureProcessor()

    let segmentedControl = UISegmentedControl(items: ["Pose", "Gesture", "Voice", "Face"])

    var userSelection: Int = 1
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private let audioEngine = AVAudioEngine()
    let targetWords = ["cheese", "action", "stop"]
    private var lastSpokenWord: String = ""

    
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
        label.text = "00:00"
        label.font = UIFont.systemFont(ofSize: 39, weight: .regular)
        label.textColor = UIColor.white
        //        label.backgroundColor = UIColor.systemRed
        label.textAlignment = .center
        //        label.isHidden = true
        return label
    }()
    
    

    
    
    //      camera switch button
    let switchCameraButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 35)
        button.setImage(UIImage(systemName: "arrow.triangle.2.circlepath", withConfiguration: config), for: .normal)
        button.tintColor = .white
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
        UIApplication.shared.isIdleTimerDisabled = true
        prepareCaptureSession()
        prepareCaptureUI()
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleBackgroundTask(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        if let sound = Bundle.main.path(forResource: "shutter", ofType: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: sound))
            } catch {
                print("Error loading sound file: \(error.localizedDescription)")
            }
            
        }
        segmentedControl.selectedSegmentIndex = 1

        segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged), for: .valueChanged)

        addAudioInput()
        setupActivityIndicator()
        prepareTimerView()
        cameraUI()
        handPoseRequest.maximumHandCount = 1
        segmentedControl.isEnabled = !(CameraViewController.isRecording && CameraViewController.isCap)
        stopSpeechRecognition()
        
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)

        // Add observer for entering foreground
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)


    }
    
    @objc func appDidEnterBackground() {
        // Stop speech recognition when app enters the background
        stopSpeechRecognition()
    }

    @objc func appWillEnterForeground() {
        // Start speech recognition if userSelection == 2 when app enters the foreground
        if userSelection == 2 {
            startSpeechRecognition()
        }
    }

    
    
    func stopSpeechRecognition() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
    }

    
    private func startSpeechRecognition() {
        speechRecognizer.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation {
                if authStatus == .authorized && self.userSelection == 2 {
                    self.startRecognizing()
                }
            }
        }
    }
    
    private func startRecognizing() {
        guard !audioEngine.isRunning else { return }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine: \(error.localizedDescription)")
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                self.processRecognitionResult(result)
            }
            
            if let error = error {
                print("Speech recognition error: \(error.localizedDescription)")
            }
        }
    }
    
    private func processRecognitionResult(_ result: SFSpeechRecognitionResult) {
        
        if let lastSegment = result.bestTranscription.segments.last {
            let currentWord = lastSegment.substring
            print("Last spoken word: \(currentWord)")
            
            for targetWord in targetWords {
                if currentWord.lowercased().contains(targetWord) {
                    switch targetWord {
                        
                    case "cheese":
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
                    case "action":
                        if !CameraViewController.isTimerRunning && !CameraViewController.isRecording {
                            runTimer(seconds: 3, completion: { [weak self] in
                                guard let self else { return }
                                self.startRecording()
                            })
                        }
                    case "stop":
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
    
    @objc func handleBackgroundTask(_ notification: Notification) {
        UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        
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
        let minutes = counter / 60
        let seconds = counter % 60
        CameraViewController.recordLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
    

    func videoSaved() {
        let alert = UIAlertController(title: nil, message: "Video added to Photos successfully", preferredStyle: .alert)
        
        self.present(alert, animated: true, completion: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true, completion: nil)
        }
    }

    // for every 60 seconds it will add a minute
    func formattedTime() -> String {
        let minutes = counter / 60
        let seconds = counter % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
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
        
        captureSession.sessionPreset = .high
        self.captureSession = captureSession
        captureSession.addOutput(movieOutput)
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    func addAudioInput() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
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
        
        // Add audio input
        addAudioInput()
        // Restart the capture session
        
        DispatchQueue.global(qos: .background).async { [self] in
            captureSession?.startRunning()
        }
        
    }
    

    private func cameraUI() {
        // Create a new view for the grey rectangle
        let topView = UIView()
        topView.translatesAutoresizingMaskIntoConstraints = false
        topView.backgroundColor = UIColor.black.withAlphaComponent(0.79) // set the background color to transparent grey
        view.addSubview(topView)
        
        topView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        topView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        topView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        topView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.15).isActive = true
        
        // Create a new view for the grey rectangle
        let bottomView = UIView()
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        bottomView.backgroundColor = UIColor.black.withAlphaComponent(0.79) // set the background color to transparent grey
        view.addSubview(bottomView)
        
        bottomView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        bottomView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        bottomView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        bottomView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.17).isActive = true
        
        view.addSubview(CameraViewController.recordLabel)
        CameraViewController.recordLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            CameraViewController.recordLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -49),
            CameraViewController.recordLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        
        
        view.addSubview(switchCameraButton)
        
        switchCameraButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            switchCameraButton.widthAnchor.constraint(equalToConstant: 44),
            switchCameraButton.heightAnchor.constraint(equalToConstant: 44),
            switchCameraButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            switchCameraButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
        
        
        switchCameraButton.addTarget(self, action: #selector(toggleCamera), for: .touchUpInside)
        
        view.addSubview(activityLabel)
        
        NSLayoutConstraint.activate([
            activityLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            activityLabel.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ])

        
        view.addSubview(segmentedControl)


        segmentedControl.translatesAutoresizingMaskIntoConstraints = false

        segmentedControl.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true


    }
    
    
    private func prepareCaptureUI() {
        guard let session = captureSession else { return }
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer)
        
        self.videoPreviewLayer = videoPreviewLayer
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
    
    
    //  to record video
    func startRecording() {
        if !movieOutput.isRecording {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = "\(UUID().uuidString).mp4"
            let fileURL = documentsURL.appendingPathComponent(fileName)
            startTimer()
            CameraViewController.isRecording = true
            movieOutput.startRecording(to: fileURL, recordingDelegate: self)
            
        }
    }

    func startRecGesture() {
        if !movieOutput.isRecording {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = "\(UUID().uuidString).mp4"
            let fileURL = documentsURL.appendingPathComponent(fileName)
            startTimer()
            movieOutput.startRecording(to: fileURL, recordingDelegate: self)

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                CameraViewController.isRecording = true

            }

            
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
        let settings = AVCapturePhotoSettings()
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
    private func runTimer(seconds: Int, completion: @escaping () -> Void) {
        CameraViewController.isTimerRunning = true
        
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

        case 1:
            userSelection = 1
            stopSpeechRecognition()

        case 2:
            userSelection = 2
            if userSelection == 2 {
                startSpeechRecognition()
            }

        case 3:
            userSelection = 3
            stopSpeechRecognition()
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
        else if userSelection == 1 {
            
            let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, options: [:])
            
            do {
                try handler.perform([handPoseRequest])
                guard let observation = handPoseRequest.results?.first else {
                    return
                }
                
                let thumbPoints = try observation.recognizedPoints(.thumb)
                guard let thumbTipPoint = thumbPoints[.thumbTip]
                else {
                    return
                }
                let handBase = try observation.recognizedPoint(.wrist)
                
                let indexPoints =  try observation.recognizedPoints(.indexFinger)
                guard let indexTipPoint = indexPoints[.indexTip],
                      let indexPIPPoint = indexPoints[.indexPIP]
                else {
                    return
                }
                
                let littlePoints = try observation.recognizedPoints(.littleFinger)
                guard let littleDIPPoint = littlePoints[.littleDIP],
                      let littleTipPoint = littlePoints[.littleTip],
                      let littlePIPPoint = littlePoints[.littlePIP]
                else {
                    return
                }
                let ringPoints =  try observation.recognizedPoints(.ringFinger)
                guard let ringDIPPoint = ringPoints[.ringDIP],
                      let ringTipPoint = ringPoints[.ringTip],
                      let ringPIPPoint = ringPoints[.ringPIP]
                else {
                    return
                }
                
                let middlePoints =  try observation.recognizedPoints(.middleFinger)
                guard let middleDIPPoint = middlePoints[.middleDIP],
                      let middlePIPPoint = middlePoints[.middlePIP]
                else {
                    return
                }
                
                self.processPoints(thumbTipPoint: thumbTipPoint,
                                   indexTipPoint: indexTipPoint,
                                   littleDIPPoint: littleDIPPoint,
                                   ringDIPPoint: ringDIPPoint,
                                   middleDIPPoint: middleDIPPoint,
                                   littleTipPoint: littleTipPoint,
                                   handBase: handBase,
                                   ringTipPoint: ringTipPoint,
                                   indexPIPPoint: indexPIPPoint,
                                   littlePIPPoint: littlePIPPoint,
                                   ringPIPPoint: ringPIPPoint,
                                   middlePIPPoint: middlePIPPoint )
            } catch {
                print(error)
            }
            
        }
        else if userSelection == 3 {
            
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
//                       let leftBrow = landmarks.leftEyebrow
                        let innerLips = landmarks.innerLips {
                        
                        
//                        let faceContourPoints = faceContour.normalizedPoints
                        let leftEyePoints = leftEye.normalizedPoints
                        let rightEyePoints = rightEye.normalizedPoints
//                        let outerLipsPoints = outerLips.normalizedPoints
                        let innerLipsPoints = innerLips.normalizedPoints
//                        let leftEyebrowPoints = leftBrow.normalizedPoints
//                        let rightEyebrowPoints = rightBrow.normalizedPoints
//
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

                        
                        
                        let smileThreshold: CGFloat = 0.15
                        let topLipCenter = innerLipsPoints[3].y
                        let bottomLipCenter = innerLipsPoints[0].y
                        let mouthOpenDistance = topLipCenter - bottomLipCenter
                        let isSmiling = mouthOpenDistance > smileThreshold
                        

                        
                        // Check if the left eye is closed
                        let eyeClosedThreshold: CGFloat = 0.06
                        let leftEyeTopPoint = leftEyePoints[1]
                        let leftEyeBottomPoint = leftEyePoints[4]
                        let leftEyeOpenDistance = abs(leftEyeTopPoint.y - leftEyeBottomPoint.y)
                        let isLeftEyeClosed = leftEyeOpenDistance <= eyeClosedThreshold
                        

                        print(leftEyeOpenDistance)

                        let rightEyeTopPoint = rightEyePoints[1]
                        let rightEyeBottomPoint = rightEyePoints[4]
                        let rightEyeOpenDistance = abs(rightEyeTopPoint.y - rightEyeBottomPoint.y)
                        let isRightEyeClosed = rightEyeOpenDistance <= eyeClosedThreshold
                        


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
                                self?.startRecGesture()
                            })
                        } else if isSmiling && ( isLeftEyeClosed || isRightEyeClosed ) && !CameraViewController.isTimerRunning && CameraViewController.isRecording {
                            self?.stopRecording()
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

            if confidence > 0.95 {
                DispatchQueue.main.async { [self] in
                    let currentPrediction = try? model!.prediction(poses: keypointsMultiArray)
                    let currentLabel = currentPrediction?.label

                    let isHandMoving = isHandPoseMoving(previous: previousKeypointsMultiArray, current: keypointsMultiArray)

                    previousKeypointsMultiArray = keypointsMultiArray

                    if currentLabel == label && confidence > 0.95 && !isHandMoving {
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
                }
            }
        } catch {
            print("Prediction error")
        }
    }
   private func processPoints(thumbTipPoint: VNRecognizedPoint, indexTipPoint: VNRecognizedPoint, littleDIPPoint: VNRecognizedPoint, ringDIPPoint: VNRecognizedPoint, middleDIPPoint: VNRecognizedPoint, littleTipPoint:VNRecognizedPoint, handBase: VNRecognizedPoint ,ringTipPoint: VNRecognizedPoint, indexPIPPoint: VNRecognizedPoint, littlePIPPoint: VNRecognizedPoint, ringPIPPoint: VNRecognizedPoint, middlePIPPoint: VNRecognizedPoint ) {
       
       // Ignore low confidence points.
       guard thumbTipPoint.confidence > 0.91 && indexTipPoint.confidence > 0.89 && littleDIPPoint.confidence > 0.85 && ringDIPPoint.confidence > 0.85 && middleDIPPoint.confidence > 0.89 && littleTipPoint.confidence > 0.83 && ringTipPoint.confidence > 0.85 && indexPIPPoint.confidence > 0.81  && littlePIPPoint.confidence > 0.87 && ringPIPPoint.confidence > 0.81 && middlePIPPoint.confidence > 0.81 && handBase.confidence > 0.83
       else {
           return
       }
       guard let handBaseUIKitPoint = videoPreviewLayer?.layerPointConverted(fromCaptureDevicePoint: handBase.toAVFoundationPoint) else {
           return
       }
       guard let thumbTipUIKitPoint = videoPreviewLayer?.layerPointConverted(fromCaptureDevicePoint: thumbTipPoint.toAVFoundationPoint) else {
           return
       }
       
       guard let indexTipUIKitPoint = videoPreviewLayer?.layerPointConverted(fromCaptureDevicePoint: indexTipPoint.toAVFoundationPoint) else {
           return
       }
       
       guard let littleDIPUIKitPoint = videoPreviewLayer?.layerPointConverted(fromCaptureDevicePoint: littleDIPPoint.toAVFoundationPoint),
             let littleTipUIKitPoint = videoPreviewLayer?.layerPointConverted(fromCaptureDevicePoint: littleTipPoint.toAVFoundationPoint) else {
           return
       }
       
       guard let ringDIPUIKitPoint = videoPreviewLayer?.layerPointConverted(fromCaptureDevicePoint: ringDIPPoint.toAVFoundationPoint),
             let ringTipUIKitPoint = videoPreviewLayer?.layerPointConverted(fromCaptureDevicePoint: ringTipPoint.toAVFoundationPoint)
       else {
           return
       }
       
       guard let middleDIPUIKitPoint = videoPreviewLayer?.layerPointConverted(fromCaptureDevicePoint: middleDIPPoint.toAVFoundationPoint) else {
           return
       }
       
       guard let indexPIPUIKitPoint = videoPreviewLayer?.layerPointConverted(fromCaptureDevicePoint: indexPIPPoint.toAVFoundationPoint) else {
           return
       }

       guard let littlePIPUIKitPoint = videoPreviewLayer?.layerPointConverted(fromCaptureDevicePoint: littlePIPPoint.toAVFoundationPoint) else {
           return
       }

       guard let ringPIPUIKitPoint = videoPreviewLayer?.layerPointConverted(fromCaptureDevicePoint: ringPIPPoint.toAVFoundationPoint) else {
           return
       }
       guard let middlePIPUIKitPoint = videoPreviewLayer?.layerPointConverted(fromCaptureDevicePoint: middlePIPPoint.toAVFoundationPoint) else {
           return
       }

   let state = handGestureProcessor.getHandState(thumbTip: thumbTipUIKitPoint, indexTip: indexTipUIKitPoint, littleDIP: littleDIPUIKitPoint, ringDIP: ringDIPUIKitPoint, middleDIP: middleDIPUIKitPoint, ringTip: ringTipUIKitPoint,handBase: handBaseUIKitPoint, littleTip: littleTipUIKitPoint, indexPIP: indexPIPUIKitPoint, littlePIP: littlePIPUIKitPoint, ringPIP: ringPIPUIKitPoint, middlePIP: middlePIPUIKitPoint)
           
           switch state {
           case .capturePhoto:
               if !CameraViewController.isTimerRunning && !CameraViewController.isCap {
                   runTimer(seconds: 3, completion: { [weak self] in
                       guard let self else { return }
                       CameraViewController.isCap = true
                       self.captureImage()
                       DispatchQueue.main.asyncAfter(deadline: .now() + 2.95) {
                           CameraViewController.isCap = false
                       }
                   })
               }
           case .quickPhoto:
               if !CameraViewController.isTimerRunning && !CameraViewController.isCap {
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
           case .vidRec:
               if !CameraViewController.isTimerRunning {
                   runTimer(seconds: 3, completion: { [weak self] in
                       guard let self else { return }
                       self.startRecGesture()
                   })
               }
           case .vidStop:
               if !CameraViewController.isTimerRunning {
                   self.stopRecording()
               }
           case .unknown:
               break
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
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        let recordingTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "SaveVideoToPhotos") // Start the background task

        videoQueue.async { // adding to queue for piortizing and to proof from interruptions
            DispatchQueue.main.async { // animating on the main thread.
                self.activityIndicator.startAnimating()
                self.activityLabel.isHidden = false
            }

            if let error = error {
                print("Error recording video: \(error.localizedDescription)")
                return
                
            }
            
            let asset = AVAsset(url: outputFileURL)
            guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
                print("Export session could not be created")
                return
            }
            
            guard FileManager.default.fileExists(atPath: outputFileURL.path) else {
                print("Output file does not exist")
                return
            }
            
            let outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("trimmedVideo.mp4")
            
            if FileManager.default.fileExists(atPath: outputURL.path) {
                do {
                    try FileManager.default.removeItem(at: outputURL)
                } catch {
                    print("Error removing file at path: \(outputURL.path)")
                }
            }
            // method to cut the last 3 seconds of the video.
            exportSession.outputURL = outputURL
            exportSession.outputFileType = .mp4
            exportSession.shouldOptimizeForNetworkUse = true
            
            let duration = asset.duration
            let startTime = CMTime.zero
            let endTime = CMTimeSubtract(duration, CMTimeMakeWithSeconds( 1 , preferredTimescale: 1)) // to make it cut 5 seconds for example, we just put 5 instead of 3.
            let timeRange = CMTimeRangeFromTimeToTime(start: startTime, end: endTime)
            exportSession.timeRange = timeRange
            
            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    PHPhotoLibrary.requestAuthorization { status in
                        if status == .authorized {
                            PHPhotoLibrary.shared().performChanges({
                                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL)
                            }) { success, error in
                                if success {
                                    print("Video saved to photos")
                                    UIApplication.shared.endBackgroundTask(recordingTaskIdentifier) 
                                    DispatchQueue.main.async {
                                        self.activityIndicator.stopAnimating()
                                        self.activityLabel.isHidden = true
                                        CameraViewController.isRecording = false
                                        self.videoSaved()
                                    }

                                } else { // starting here are just debugging for error checking.
                                    print("Error saving video to photos: \(error?.localizedDescription ?? "unknown error")")
                                    DispatchQueue.main.async {
                                        self.activityIndicator.stopAnimating()
                                        CameraViewController.isRecording = false
                                        self.activityLabel.isHidden = true
                                    }

                                }
                            }
                        } else {
                            print("Access to photo library denied")
                            DispatchQueue.main.async {
                                self.activityIndicator.stopAnimating()
                                CameraViewController.isRecording = false

                            }

                        }
                    }
                case .failed:
                    print("Export failed: \(exportSession.error?.localizedDescription ?? "unknown error")")
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                        CameraViewController.isRecording = false

                    }

                    print("Export error: \(String(describing: exportSession.error))")
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                        CameraViewController.isRecording = false

                    }

                case .cancelled:
                    print("Export cancelled")
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                        self.activityLabel.isHidden = true
                        CameraViewController.isRecording = false

                    }

                case .exporting:
                    print("Exporting...")
                case .waiting:
                    print("Waiting...")
                case .unknown:
                    print("Unknown status...")
                @unknown default:
                    print("Fatal Error")
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                        CameraViewController.isRecording = false
                        self.activityLabel.isHidden = true
                    }

                }
            }
        }
    }
}

