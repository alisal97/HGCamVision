import UIKit
import Foundation
import AVFoundation
import Vision
import Photos
import SnapKit

var isRecording = false

class CameraViewController: UIViewController {

    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    private let movieOutput = AVCaptureMovieFileOutput()
    private var videoDeviceInput: AVCaptureDeviceInput!

    private let handPoseRequest = VNDetectHumanHandPoseRequest()
    private let handGestureProcessor = HandGestureProcessor()
//    private let recordButton = UIButton()
    private var isRecording = false

    private weak var timerLabel: UILabel?
    
    private var isTimerRunning = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareCaptureSession()
        prepareCaptureUI()
//        setupRecordButton()

        prepareTimerView()
        
        handPoseRequest.maximumHandCount = 1
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
        self.captureSession?.startRunning()
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
//        if !isRecording {
//            startRecording()
//            isRecording = true
//            recordButton.backgroundColor = .green
//        } else {
//            stopRecording()
//            isRecording = false
//            recordButton.backgroundColor = .red
//        }
//    }

    func startRecording() {
       if !movieOutput.isRecording {
           isRecording = true
           let outputPath = NSTemporaryDirectory() + "output.mov"
           let outputFileURL = URL(fileURLWithPath: outputPath)
           movieOutput.startRecording(to: outputFileURL, recordingDelegate: self)
           
       }
   }
    func stopRecording() {
       if movieOutput.isRecording {
           movieOutput.stopRecording()
           isRecording = false
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
            
            let middlePoints = try observation.recognizedPoints(.middleFinger)
            guard let middleTipPoint = middlePoints[.middleTip] else {
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
                               middleTipPoint: middleTipPoint,
                               ringDIPPoint: ringDIPPoint,
                               middleDIPPoint: middleDIPPoint)
        } catch {
            print(error)
        }
    }
    
    private func processPoints(thumbTipPoint: VNRecognizedPoint, indexTipPoint: VNRecognizedPoint, middleTipPoint: VNRecognizedPoint, ringDIPPoint: VNRecognizedPoint, middleDIPPoint: VNRecognizedPoint) {
        
        // Ignore low confidence points.
        guard thumbTipPoint.confidence > 0.9 && indexTipPoint.confidence > 0.9 && middleTipPoint.confidence > 0.9 && ringDIPPoint.confidence > 0.9 && middleDIPPoint.confidence > 0.9
        else {
            return
        }
        
        guard let thumbTipUIKitPoint = videoPreviewLayer?.layerPointConverted(fromCaptureDevicePoint: thumbTipPoint.toAVFoundationPoint) else {
            return
        }
        
        guard let indexTipUIKitPoint = videoPreviewLayer?.layerPointConverted(fromCaptureDevicePoint: indexTipPoint.toAVFoundationPoint) else {
            return
        }
        
        guard let middleTipUIKitPoint = videoPreviewLayer?.layerPointConverted(fromCaptureDevicePoint: middleTipPoint.toAVFoundationPoint) else {
            return
        }
        
        guard let ringDIPUIKitPoint = videoPreviewLayer?.layerPointConverted(fromCaptureDevicePoint: ringDIPPoint.toAVFoundationPoint) else {
            return
        }
        
        guard let middleDIPUIKitPoint = videoPreviewLayer?.layerPointConverted(fromCaptureDevicePoint: middleDIPPoint.toAVFoundationPoint) else {
            return
        }

        let state = handGestureProcessor.getHandState(thumbTip: thumbTipUIKitPoint, indexTip: indexTipUIKitPoint, middleTip: middleTipUIKitPoint, ringDIP: ringDIPUIKitPoint, middleDIP: middleDIPUIKitPoint)
        
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
        
        let startVid = handGestureProcessor.getHandState(thumbTip: thumbTipUIKitPoint, indexTip: indexTipUIKitPoint, middleTip: middleTipUIKitPoint, ringDIP: ringDIPUIKitPoint, middleDIP: middleDIPUIKitPoint)

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
        
        let stopVid = handGestureProcessor.getHandState(thumbTip: thumbTipUIKitPoint, indexTip: indexTipUIKitPoint, middleTip: middleTipUIKitPoint, ringDIP: ringDIPUIKitPoint, middleDIP: middleDIPUIKitPoint)
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
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("Started recording to \(fileURL)")
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error recording video: \(error.localizedDescription)")
        } else {
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
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
        }
    }
}


