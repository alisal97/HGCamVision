import UIKit
import Foundation
import AVFoundation
import Vision
import Photos
import SnapKit
import PhotosUI

class CameraViewController: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {

    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var audioPlayer: AVAudioPlayer?
    private let movieOutput = AVCaptureMovieFileOutput()
    private var videoDeviceInput: AVCaptureDeviceInput!
    private let handPoseRequest = VNDetectHumanHandPoseRequest()
    private let handGestureProcessor = HandGestureProcessor()
    static var isRecording = false
    private weak var timerLabel: UILabel?
    
    private var isTimerRunning = false
    
    let switchCameraButton = UIButton()

    
    // Declare a timer and a counter variable to track elapsed time
    var timer: Timer?
    var counter = 0
    
    // Declare a UILabel to display the time elapsed
    let recordLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.font = UIFont.systemFont(ofSize: 37, weight: .heavy)
        label.textColor = UIColor.red
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    
//     gallery button
    let galleryButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 50)
        button.setImage(UIImage(systemName: "photo.fill", withConfiguration: config), for: .normal)
        return button
    }()

    
    @objc func onGalleryButtonClick(sender: UIButton){
        let assetViewer = AssetViewerViewController() // or get a reference to an existing instance
        
        self.addChild(assetViewer)
        view.addSubview(assetViewer.view)
        assetViewer.didMove(toParent: self)
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = ["public.image", "public.movie"] // Set supported media types
        imagePicker.delegate = assetViewer.self
        assetViewer.present(imagePicker, animated: true, completion: nil)
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.isIdleTimerDisabled = true
        prepareCaptureSession()
        prepareCaptureUI()
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    print("Access to photo library granted")
                } else {
                    print("Access to photo library denied")
                }
            }
        } else if status == .authorized {
            print("Access to photo library granted")
        } else {
            print("Access to photo library denied")
        }
        
        if let sound = Bundle.main.path(forResource: "shutter", ofType: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: sound))
            } catch {
                print("Error loading sound file: \(error.localizedDescription)")
            }
        } else {
            print("Error: Sound file not found.")
        }
        prepareTimerView()
        
        handPoseRequest.maximumHandCount = 1
        
        
        // Add the timerLabel to the view and position it at the top
        view.addSubview(recordLabel)
        recordLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            recordLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            recordLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        


        
        // Configure the switch camera button
        switchCameraButton.setImage(UIImage(systemName: "camera.rotate"), for: .normal)
//        switchCameraButton.addTarget(self, action: #selector(switchCamera), for: .touchUpInside)
        switchCameraButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(switchCameraButton)

        // Position the button in the bottom right corner
        NSLayoutConstraint.activate([
            switchCameraButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            switchCameraButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            switchCameraButton.widthAnchor.constraint(equalToConstant: 44),
            switchCameraButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        

        view.addSubview(galleryButton)

        NSLayoutConstraint.activate([
            galleryButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            galleryButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            galleryButton.widthAnchor.constraint(equalToConstant: 44),
            galleryButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        galleryButton.addTarget(self, action: #selector(onGalleryButtonClick), for: .touchUpInside)

    }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait, .landscapeLeft, .landscapeRight]
    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { [weak self] _ in
            guard let self = self else { return }
            let isLandscape = UIDevice.current.orientation.isLandscape
            self.updateConstraintsForOrientation(isLandscape)
        }, completion: nil)
    }

    private func updateConstraintsForOrientation(_ isLandscape: Bool) {
        // Update your constraints here based on the current orientation
        // For example:
        if isLandscape {
            recordLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 23).isActive = true
        } else {
            recordLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 13).isActive = true
        }
    }
    
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
    func formattedTime() -> String {
        let minutes = counter / 60
        let seconds = counter % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Re-enable idle timer when the app goes into the background or is closed
        UIApplication.shared.isIdleTimerDisabled = false
    }


    private func prepareCaptureSession() {
        captureSession?.beginConfiguration()
        let captureSession = AVCaptureSession()
        
        // Select a front facing camera, make an input.
        
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        
        captureSession.addInput(input)
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: .main)
        captureSession.addOutput(videoOutput)
        
        
        let photoOutput = AVCapturePhotoOutput()
        captureSession.addOutput(photoOutput)
        
        // Add video input
        
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
        // Add audio input
        guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
            fatalError("Could not get audio device")
        }
        
        do {
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
            
            if captureSession.canAddInput(audioDeviceInput) {
                captureSession.addInput(audioDeviceInput)
            }
        } catch {
            fatalError("Could not create audio device input: \(error.localizedDescription)")
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
    
    private func prepareCaptureUI() {
        guard let session = captureSession else { return }
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer)
        
        if let previewLayerConnection = videoPreviewLayer.connection {
            let currentDeviceOrientation = UIDevice.current.orientation
            let videoOrientation: AVCaptureVideoOrientation
            
            switch currentDeviceOrientation {
            case .portrait:
                videoOrientation = .portrait
            case .landscapeLeft:
                videoOrientation = .landscapeRight
            case .landscapeRight:
                videoOrientation = .landscapeLeft
            default:
                videoOrientation = .portrait
            }
            
            previewLayerConnection.videoOrientation = videoOrientation
        }
        
        self.videoPreviewLayer = videoPreviewLayer
    }
    
    


    func startRecording() {
       if !movieOutput.isRecording {
           CameraViewController.isRecording = true
           let outputPath = NSTemporaryDirectory() + "output.mov"
           let outputFileURL = URL(fileURLWithPath: outputPath)
           
           startTimer()
           movieOutput.startRecording(to: outputFileURL, recordingDelegate: self)

           
       }
   }
    func stopRecording() {
       if movieOutput.isRecording {
           movieOutput.stopRecording()
           CameraViewController.isRecording = false
           stopTimer()
       }
   }
    
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

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])
        
        do {
            try handler.perform([handPoseRequest])
            
//            guard let observation = handPoseRequest.results?.first as? VNRecognizedPointsObservation else {
//                return
//            }
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
    
    private func processPoints(thumbTipPoint: VNRecognizedPoint, indexTipPoint: VNRecognizedPoint, littleDIPPoint: VNRecognizedPoint, ringDIPPoint: VNRecognizedPoint, middleDIPPoint: VNRecognizedPoint) {
        
        // Ignore low confidence points.
        guard thumbTipPoint.confidence > 0.91 && indexTipPoint.confidence > 0.85 && littleDIPPoint.confidence > 0.83 && ringDIPPoint.confidence > 0.85 && middleDIPPoint.confidence > 0.85
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


extension CameraViewController: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else { return }
        guard let image = UIImage(data: imageData) else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
}


extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
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
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        
        let duration = asset.duration
        let startTime = CMTime.zero
        let endTime = CMTimeSubtract(duration, CMTimeMakeWithSeconds(3, preferredTimescale: 1))
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
                            } else {
                                print("Error saving video to photos: \(error?.localizedDescription ?? "unknown error")")
                            }
                        }
                    } else {
                        print("Access to photo library denied")
                    }
                }
            case .failed:
                print("Export failed: \(exportSession.error?.localizedDescription ?? "unknown error")")
                print("Export error: \(String(describing: exportSession.error))")
            case .cancelled:
                print("Export cancelled")
            case .exporting:
                print("Exporting...")
            case .waiting:
                print("Waiting...")
            case .unknown:
                print("Unknown status...")
            @unknown default:
                print("Fatal Error")
            }
        }
    }
}


    




