import UIKit
import Foundation
import AVFoundation
import Vision
import Photos
import SnapKit
import PhotosUI

class CameraViewController: UIViewController {

    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    private let movieOutput = AVCaptureMovieFileOutput()
    private var videoDeviceInput: AVCaptureDeviceInput!
    private let handPoseRequest = VNDetectHumanHandPoseRequest()
    private let handGestureProcessor = HandGestureProcessor()
//    private let recordButton = UIButton()
    static var isRecording = false

    private weak var timerLabel: UILabel?
    
    private var isTimerRunning = false
    
    
    // gallery button
    private lazy var galleryButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "square.grid.2x2.fill"), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(openGallery), for: .touchUpInside)
        return button
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareCaptureSession()
        prepareCaptureUI()
//        setupRecordButton()

        prepareTimerView()
        
        handPoseRequest.maximumHandCount = 1
        
        // Add the gallery thumbnail button to the view
        
        view.addSubview(galleryButton)
        
        // Position the gallery thumbnail button in the bottom left corner
        galleryButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            galleryButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            galleryButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            galleryButton.widthAnchor.constraint(equalToConstant: 44),
            galleryButton.heightAnchor.constraint(equalToConstant: 44)
        ])

    }
    @objc func openGallery() {
//        PHPhotoLibrary.r
        PHPhotoLibrary.requestAuthorization(for:.readWrite){ status in
            if status == .authorized {
                print("gallery tapped")
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                let allPhotos = PHAsset.fetchAssets(with: fetchOptions)
                guard let asset = allPhotos.firstObject else { return }

                // Open asset in a viewer
                DispatchQueue.main.async {
                    let viewer = AssetViewerViewController(asset: asset)
                    self.navigationController?.pushViewController(viewer, animated: true)
                }
            } else if status == .denied || status == .restricted {
                // Handle access denied or restricted
                print("Access to photo library denied or restricted")
            } else if status == .notDetermined {
                // Handle not determined
                print("Access to photo library not determined")
            }
        }
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
        
        self.videoPreviewLayer = videoPreviewLayer
    }
    
    

//
//    private func setupRecordButton() {
//        recordButton.backgroundColor = .red
//        recordButton.addTarget(self, action: #selector(recordButtonTapped), for: .touchUpInside)
//
//        view.addSubview(recordButton)
//
//        recordButton.snp.makeConstraints { make in
//            make.centerX.equalToSuperview()
//            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin).offset(-16)
//            make.width.height.equalTo(80)
//        }
//    }
//    @objc private func recordButtonTapped() {
//        if !CameraViewController.isRecording {
//            startRecording()
//            CameraViewController.isRecording = true
//            recordButton.backgroundColor = .green
//        } else {
//            stopRecording()
//            CameraViewController.isRecording = false
//            recordButton.backgroundColor = .red
//        }
//    }

    func startRecording() {
       if !movieOutput.isRecording {
           CameraViewController.isRecording = true
           let outputPath = NSTemporaryDirectory() + "output.mov"
           let outputFileURL = URL(fileURLWithPath: outputPath)
           movieOutput.startRecording(to: outputFileURL, recordingDelegate: self)
           
       }
   }
    func stopRecording() {
       if movieOutput.isRecording {
           movieOutput.stopRecording()
           CameraViewController.isRecording = false
       }
   }
    
    private func prepareTimerView() {
        let timerLabel = UILabel()
        timerLabel.textAlignment = .center
        timerLabel.font = UIFont.systemFont(ofSize: 300)
        
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
    }

    private func runTimer(seconds: Int, completion: @escaping () -> Void) {
        isTimerRunning = true

        var timeLeft = seconds
        
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { timer in
            self.timerLabel?.text = "\(timeLeft)"
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
        guard thumbTipPoint.confidence > 0.91 && indexTipPoint.confidence > 0.91 && littleDIPPoint.confidence > 0.91 && ringDIPPoint.confidence > 0.91 && middleDIPPoint.confidence > 0.91
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
                runTimer(seconds: 3, completion: {
                    print("pinched to stop vid")
                    self.stopRecording()
                    
                })
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
        let endTime = CMTimeSubtract(duration, CMTimeMake(value: 2, timescale: 1))
        let timeRange = CMTimeRangeFromTimeToTime(start: startTime, end: endTime)
        exportSession.timeRange = timeRange
        
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                PHPhotoLibrary.requestAuthorization(for: .readWrite ) { status in
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
            case .cancelled:
                print("Export cancelled")
            default:
                break
            }
        }
    }
    
}
    




