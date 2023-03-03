//
//  CameraViewController.swift
//  HGCam
//
//  Created by Aly Salman on 18/02/23.
//  Copyright © 2023 CB Gang. All rights reserved.
////
//  CameraViewController.swift
//  HGCam
//
//  Created by Aly Salman on 18/02/23.
//  Copyright © 2023 CB Gang. All rights reserved.
//

import UIKit
import AVKit
import Foundation
import AVFoundation
import Vision
import Photos
import SnapKit

class CameraViewController: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    let videoQueue = DispatchQueue(label: "com.example.videoQueue") // queue for saving video, so we can pioritize video saving and keep it from interruptions
    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var audioPlayer: AVAudioPlayer? //for playing shutter sound
    private let movieOutput = AVCaptureMovieFileOutput()
    private var videoDeviceInput: AVCaptureDeviceInput!
    private let handPoseRequest = VNDetectHumanHandPoseRequest()
    private let handGestureProcessor = HandGestureProcessor()
    static var isRecording = false
    private weak var timerLabel: UILabel?
    private var isTimerRunning = false
    var currentCameraPosition: AVCaptureDevice.Position = .front
    private var activityIndicator: UIActivityIndicatorView!


    // Declare a timer and a counter variable to track elapsed time
    var timer: Timer?
    var counter = 0
    
    
    // Declare a UILabel to display the time elapsed
    let recordLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.font = UIFont.systemFont(ofSize: 39, weight: .semibold)
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.isHidden = true
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
    
    let flashButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 35)
        button.setImage(UIImage(systemName:"bolt.slash.circle", withConfiguration: config), for: .normal)
        button.tintColor = .white
        return button
    }()

    
//     gallery button
    let galleryButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 50)
        button.setImage(UIImage(systemName: "photo.fill", withConfiguration: config), for: .normal)
        button.tintColor = .white
        return button
    }()

    //function to get the most recent media from the photos app
    @objc private func openPhotosApp() {
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized:
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                let allAssets = PHAsset.fetchAssets(with: fetchOptions)
                guard let mostRecentAsset = allAssets.firstObject else { return }
                
                if mostRecentAsset.mediaType == .image {
                    PHImageManager.default().requestImageDataAndOrientation(for: mostRecentAsset, options: nil) { (data, _, _, info) in
                        if let imageData = data, let image = UIImage(data: imageData) {
                            DispatchQueue.main.async {
                                let imageView = UIImageView(image: image)
                                imageView.frame = self.view.bounds
                                imageView.contentMode = .scaleAspectFit
                                imageView.backgroundColor = .black
                                imageView.isUserInteractionEnabled = true
                                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissImageView))
                                imageView.addGestureRecognizer(tapGesture)
                                self.view.addSubview(imageView)
                            }
                        }
                    }
                } else if mostRecentAsset.mediaType == .video {
                    let requestOptions = PHVideoRequestOptions()
                    requestOptions.version = .original
                    
                    PHImageManager.default().requestAVAsset(forVideo: mostRecentAsset, options: requestOptions) { (asset, audioMix, info) in
                        if let urlAsset = asset as? AVURLAsset {
                            let videoURL = urlAsset.url
                            DispatchQueue.main.async {
                                let player = AVPlayer(url: videoURL)
                                let playerViewController = AVPlayerViewController()
                                playerViewController.player = player
                                self.present(playerViewController, animated: true) {
                                    playerViewController.player?.play()
                                }
                            }
                        }
                    }
                }
            case .denied, .restricted:
                print("Access to photo library is denied or restricted")
            case .notDetermined:
                print("Access to photo library has not been determined")
            case .limited:
                print("Allow access to all photos")
            @unknown default:
                fatalError("Unexpected case occurred while requesting photo library authorization")
            }
        }
    }
//  function to exit the gallery view defined in the function above, you can use by clicking on the black borders
    @objc private func dismissImageView() {
        for subview in self.view.subviews {
            if let imageView = subview as? UIImageView {
                imageView.removeFromSuperview()
            }
        }
        self.setNeedsStatusBarAppearanceUpdate()
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
//  function to get a thumbnail of the most recent media for the gallery button.
    private func setupGalleryButton() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let fetchResult = PHAsset.fetchAssets(with: fetchOptions)

        guard let latestAsset = fetchResult.firstObject else {
            // There are no assets in the user's library
            return
        }

        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.deliveryMode = .fastFormat
        requestOptions.isSynchronous = true

        imageManager.requestImage(for: latestAsset, targetSize: CGSize(width: 75, height: 75), contentMode: .aspectFill, options: requestOptions) { (image, info) in
            if let image = image {
                DispatchQueue.main.async {
                    self.galleryButton.setImage(image, for: .normal)
                }
            }
        }
    }


// activity indicator / loading icon for when the video is saving.
// since we are cutting the last 3 seconds of the recorded videos it takes a while to save.

    private func setupActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.transform = CGAffineTransform(scaleX: 3.5, y: 3.5)
        activityIndicator.color = UIColor.darkGray
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        DispatchQueue.main.async { [self] in
            view.addSubview(activityIndicator)
        }
    }

//  toggle the camera flash light
    @objc private func toggleFlash() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        guard device.hasTorch else { return }
        if currentCameraPosition == .back { // if statement to check if the back camera is in use before toggling on the flash
            do {
                try device.lockForConfiguration()
                
                if device.torchMode == .off {
                    device.torchMode = .on
                    let config = UIImage.SymbolConfiguration(pointSize: 35)
                    flashButton.setImage(UIImage(systemName:"bolt.circle.fill", withConfiguration: config), for: .normal)
                } else {
                    device.torchMode = .off
                    let config = UIImage.SymbolConfiguration(pointSize: 35)
                    flashButton.setImage(UIImage(systemName:"bolt.slash.circle", withConfiguration: config), for: .normal)
                }
                
                device.unlockForConfiguration()
            } catch {
                print("Error toggling flash: \(error.localizedDescription)")
            }
        }
    }
    // in viewDidLoad you should add all the UI elements and "constant" tasks like calling the cameraView, because viewDidLoad job's is to keep calling the functions constantly.
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
        addAudioInput()
        setupActivityIndicator()
        prepareTimerView()
        setupGalleryButton()
        cameraUI()
        handPoseRequest.maximumHandCount = 1
        
        // Add the timerLabel to the view and position it at the top
        view.addSubview(recordLabel)
        recordLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            recordLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -16),
            recordLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
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

        
        view.addSubview(galleryButton)

        NSLayoutConstraint.activate([
            galleryButton.widthAnchor.constraint(equalToConstant: 44),
            galleryButton.heightAnchor.constraint(equalToConstant: 44),
            galleryButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            galleryButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])

        galleryButton.addTarget(self, action: #selector(openPhotosApp), for: .touchUpInside)
        
        flashButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(flashButton)

        // Add constraints to position the flash button in the top right corner
        NSLayoutConstraint.activate([
            flashButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -16),
            flashButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
        ])
        flashButton.addTarget(self, action: #selector(toggleFlash), for: .touchUpInside)


    }
    // enabling backgroundTask, this way video saving will keep on working even if the user switches to another app or to home screen
    @objc func handleBackgroundTask(_ notification: Notification) {
       UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        
    }
//  adding support for landscape views.
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        // Get the new device orientation
        let newOrientation = UIDevice.current.orientation
        
        // Update the video orientation of the preview layer based on the new device orientation
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
    
//  timer to start counting seconds and minutes when recording starts
    func startTimer() {
        recordLabel.isHidden = false
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.counter += 1
            self?.recordLabel.text = self?.formattedTime()
        }
    }

    // Stop the timer when recording ends
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        counter = 0
        recordLabel.isHidden = true
        recordLabel.text = "00:00"
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
    }
    
    //instead of putting all these methods in viewDidLoad we wrap them in this function and call it in viewDidLoad

    private func prepareCaptureSession() {
            captureSession?.beginConfiguration()
            let captureSession = AVCaptureSession()
            
            // Select a front facing camera, make an input.
            
            guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraPosition) else { return }
            guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
            
            captureSession.addInput(input)
            
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: .main)
            captureSession.addOutput(videoOutput)
            
            
            let photoOutput = AVCapturePhotoOutput()
            captureSession.addOutput(photoOutput)
        
            // Add video input

            do {
                let videoDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
                if captureSession.canAddInput(videoDeviceInput) {
                    captureSession.addInput(videoDeviceInput)
                }
            } catch {
                fatalError("Could not create video device input: \(error.localizedDescription)")
            }
            
            // Add video output
            if captureSession.canAddOutput(movieOutput) {
                captureSession.addOutput(movieOutput)
            }
            
            self.captureSession?.sessionPreset = .high
            self.captureSession = captureSession
            
            DispatchQueue.global(qos: .background).async {
                self.captureSession?.startRunning()
            }

            
            captureSession.commitConfiguration()

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

//  function in objectiveC to switch the camera between back and front. we have to add audio input again after switching camera, otherwise it will not work.
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

        // Add constraints to position the top view at the top of the screen, taking up 9% of the screen height
        topView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        topView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        topView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        topView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.15).isActive = true

        // Create a new view for the grey rectangle
        let bottomView = UIView()
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        bottomView.backgroundColor = UIColor.black.withAlphaComponent(0.79) // set the background color to transparent grey
        view.addSubview(bottomView)

        // Add constraints to position the bottom view at the bottom of the screen, taking up 17% of the screen height
        bottomView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        bottomView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        bottomView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        bottomView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.17).isActive = true
            
    }
    
    private func prepareCaptureUI() {
        guard let session = captureSession else { return }
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer)
        
        self.videoPreviewLayer = videoPreviewLayer
    }
    // also to add support to landscape mode.
    
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
           CameraViewController.isRecording = true
           let outputPath = NSTemporaryDirectory() + "output.mov"
           let outputFileURL = URL(fileURLWithPath: outputPath)
           startTimer()
           movieOutput.startRecording(to: outputFileURL, recordingDelegate: self)

           
       }
   }
// to stop recording video
    func stopRecording() {
       if movieOutput.isRecording {
           movieOutput.stopRecording()
           CameraViewController.isRecording = false
           stopTimer()
       }
   }
// view for countdown timer for when taking a photo or a video
    private func prepareTimerView() {
        let timerLabel = UILabel()
        timerLabel.textAlignment = .center
        timerLabel.font = UIFont.systemFont(ofSize: 41)
        
        view.addSubview(timerLabel)
        timerLabel.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }
        
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
// function that actually defines the timer
    private func runTimer(seconds: Int, completion: @escaping () -> Void) {
        isTimerRunning = true

        var timeLeft = seconds
        
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { timer in
            self.timerLabel?.text = "Action in... \(timeLeft) "
            timeLeft -= 1
            
            if timeLeft < 0 {
                timer.invalidate()
                self.isTimerRunning = false
                self.timerLabel?.text = nil
            
                completion()
            }
        })
        
        RunLoop.current.add(timer, forMode: RunLoop.Mode.common)
    }
}

// function to take photos for the vision framework to recognize the hand gesture.
extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])
        
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
            
            let indexPoints =  try observation.recognizedPoints(.indexFinger)
            guard let indexTipPoint = indexPoints[.indexTip] else {
                return
            }
            
            let littlePoints = try observation.recognizedPoints(.littleFinger)
            guard let littleDIPPoint = littlePoints[.littleDIP] else {
                return
            }
            
            let ringPoints =  try observation.recognizedPoints(.ringFinger)
            guard let ringDIPPoint = ringPoints[.ringDIP] else {
                return
            }
            
            let middlePPoints =  try observation.recognizedPoints(.middleFinger)
            guard let middleDIPPoint = middlePPoints[.middleDIP] else {
                return
            }
            
            self.processPoints(thumbTipPoint: thumbTipPoint,
                               indexTipPoint: indexTipPoint,
                               littleDIPPoint: littleDIPPoint,
                               ringDIPPoint: ringDIPPoint,
                               middleDIPPoint: middleDIPPoint)
        } catch {
            print(error)
        }
    }
    
    // after points are recognized, this function checks for the confidence of the points before processing them
    private func processPoints(thumbTipPoint: VNRecognizedPoint, indexTipPoint: VNRecognizedPoint, littleDIPPoint: VNRecognizedPoint, ringDIPPoint: VNRecognizedPoint, middleDIPPoint: VNRecognizedPoint) {
        
        // Ignore low confidence points.
        guard thumbTipPoint.confidence > 0.91 && indexTipPoint.confidence > 0.89 && littleDIPPoint.confidence > 0.85 && ringDIPPoint.confidence > 0.85 && middleDIPPoint.confidence > 0.89
        else {
            return
        }
        
        guard let thumbTipUIKitPoint = videoPreviewLayer?.layerPointConverted(fromCaptureDevicePoint: thumbTipPoint.toAVFoundationPoint) else {
            return
        }
        
        guard let indexTipUIKitPoint = videoPreviewLayer?.layerPointConverted(fromCaptureDevicePoint: indexTipPoint.toAVFoundationPoint) else {
            return
        }
        
        guard let littleDIPUIKitPoint = videoPreviewLayer?.layerPointConverted(fromCaptureDevicePoint: littleDIPPoint.toAVFoundationPoint) else {
            return
        }
        
        guard let ringDIPUIKitPoint = videoPreviewLayer?.layerPointConverted(fromCaptureDevicePoint: ringDIPPoint.toAVFoundationPoint) else {
            return
        }
        
        guard let middleDIPUIKitPoint = videoPreviewLayer?.layerPointConverted(fromCaptureDevicePoint: middleDIPPoint.toAVFoundationPoint) else {
            return
        }
// checking for hand gestures, it doesn't work well if I put them all in the same switch statement, I don't know why but I assume we have to call handGestureProcesor for each gesture using a different constant, because the processor might have a one time use limit.
        let state = handGestureProcessor.getHandState(thumbTip: thumbTipUIKitPoint, indexTip: indexTipUIKitPoint, littleDIP: littleDIPUIKitPoint, ringDIP: ringDIPUIKitPoint, middleDIP: middleDIPUIKitPoint)
        
        switch state {
        case .pinchedPhoto:
            if isTimerRunning == false {
                runTimer(seconds: 3, completion: {
                    self.captureImage()
                })
            }
        case .pinchedVidRec:
            break
        case .pinchedVidStop:
            break
        case .unknown:
            break
        }
        
        let startVid = handGestureProcessor.getHandState(thumbTip: thumbTipUIKitPoint, indexTip: indexTipUIKitPoint, littleDIP: littleDIPUIKitPoint, ringDIP: ringDIPUIKitPoint, middleDIP: middleDIPUIKitPoint)

        switch startVid {
        case .pinchedVidRec:
            if isTimerRunning == false {
                runTimer(seconds: 3, completion: {
                    print("pinched to start vid")
                    self.startRecording()
                    
                })
            }
        case .unknown:
            break
        case .pinchedPhoto:
            break
        case .pinchedVidStop:
            break
        }
        
        let stopVid = handGestureProcessor.getHandState(thumbTip: thumbTipUIKitPoint, indexTip: indexTipUIKitPoint, littleDIP: littleDIPUIKitPoint, ringDIP: ringDIPUIKitPoint, middleDIP: middleDIPUIKitPoint)
        switch stopVid {
        case .pinchedVidStop:
            if isTimerRunning == false {
                print("pinched to stop vid")
                self.stopRecording()
            }
        case .unknown:
            break
        case .pinchedPhoto:
            break
        case .pinchedVidRec:
            break
        }
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

// output for recorded videos, it's added to video queue for pioritizing with activity indicator to show that a video is being saved, and it's added to background tasks so it doesn't get interrupted when users switch to another app or homescreen.
extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        let recordingTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "SaveVideoToPhotos") // Start the background task

        videoQueue.async { // adding to queue for piortizing and to proof from interruptions
            DispatchQueue.main.async { // animating on the main thread.
                self.activityIndicator.startAnimating() //starting the activity loading indicator for when a video is taken.
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
            let endTime = CMTimeSubtract(duration, CMTimeMakeWithSeconds(2.3, preferredTimescale: 1)) // to make it cut 5 seconds for example, we just put 5 instead of 3.
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
                                    UIApplication.shared.endBackgroundTask(recordingTaskIdentifier) // when video saving is complete it will remove the app from background tasks
                                    DispatchQueue.main.async {
                                        self.activityIndicator.stopAnimating() // when saving video is complete it will stop the animation of the indicator and remove it from the view.
                                    }

                                } else { // starting here are just debugging for error checking.
                                    print("Error saving video to photos: \(error?.localizedDescription ?? "unknown error")")
                                    DispatchQueue.main.async {
                                        self.activityIndicator.stopAnimating()
                                    }

                                }
                            }
                        } else {
                            print("Access to photo library denied")
                            DispatchQueue.main.async {
                                self.activityIndicator.stopAnimating()
                            }

                        }
                    }
                case .failed:
                    print("Export failed: \(exportSession.error?.localizedDescription ?? "unknown error")")
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                    }

                    print("Export error: \(String(describing: exportSession.error))")
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                    }

                case .cancelled:
                    print("Export cancelled")
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
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
                    }

                }
            }
        }
    }
}


    



