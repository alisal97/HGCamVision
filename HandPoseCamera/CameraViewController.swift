import UIKit
import Foundation
import AVFoundation
import Vision
import Photos
import SnapKit

class CameraViewController: UIViewController {

    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    private let handPoseRequest = VNDetectHumanHandPoseRequest()
    private let handGestureProcessor = HandGestureProcessor()
    
    private weak var timerLabel: UILabel?
    
    private var isTimerRunning = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareCaptureSession()
        prepareCaptureUI()
        
        prepareTimerView()
//        prepareBottomControls()
        
        handPoseRequest.maximumHandCount = 1
    }

    private func prepareCaptureSession() {
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
        
        
        self.captureSession?.sessionPreset = .high
        self.captureSession = captureSession
        self.captureSession?.startRunning()
    }
    
    private func prepareCaptureUI() {
        guard let session = captureSession else { return }
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer)
        
        self.videoPreviewLayer = videoPreviewLayer
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
    
//    private func prepareBottomControls() {
//        let captureButton = UIButton()
//        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 100, weight: .bold, scale: .large)
//        let symbolImage = UIImage(systemName: "camera.circle", withConfiguration: symbolConfig)
//        captureButton.setImage(symbolImage, for: .normal)
//        captureButton.tintColor = .systemYellow
//        captureButton.addTarget(self, action: #selector(captureButtonDidTap), for: .touchUpInside)
//
//        view.addSubview(captureButton)
//        captureButton.snp.makeConstraints { maker in
//            maker.bottom.equalToSuperview().offset(-40)
//            maker.centerX.equalToSuperview()
//            maker.width.height.equalTo(100)
//        }
//    }
    

    
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
            guard let middleDIPPoint = middlePoints[.middleDIP] else {
                return
            }
            
            let ringPoints =  try observation.recognizedPoints(.ringFinger)
            guard let ringTipPoint = ringPoints[.ringTip] else {
                return
            }
            
            let littlePoints =  try observation.recognizedPoints(.littleFinger)
            guard let littleDIPPoint = littlePoints[.littleDIP] else {
                return
            }
            
            self.processPoints(thumbTipPoint: thumbTipPoint,
                               indexTipPoint: indexTipPoint,
                               middleDIPPoint: middleDIPPoint,
                               ringTipPoint: ringTipPoint,
                               littleDIPPoint: littleDIPPoint)
        } catch {
            print(error)
        }
    }
    
    private func processPoints(thumbTipPoint: VNRecognizedPoint, indexTipPoint: VNRecognizedPoint, middleDIPPoint: VNRecognizedPoint, ringTipPoint: VNRecognizedPoint, littleDIPPoint: VNRecognizedPoint) {
        
        // Ignore low confidence points.
        guard thumbTipPoint.confidence > 0.9 && indexTipPoint.confidence > 0.9 && middleDIPPoint.confidence > 0.9 && ringTipPoint.confidence > 0.85 && littleDIPPoint.confidence > 0.89
        else {
            return
        }
        
        guard let thumbTipUIKitPoint = videoPreviewLayer?.layerPointConverted(fromCaptureDevicePoint: thumbTipPoint.toAVFoundationPoint) else {
            return
        }
        
        guard let indexTipUIKitPoint = videoPreviewLayer?.layerPointConverted(fromCaptureDevicePoint: indexTipPoint.toAVFoundationPoint) else {
            return
        }
        
        guard let middleDIPUIKitPoint = videoPreviewLayer?.layerPointConverted(fromCaptureDevicePoint: middleDIPPoint.toAVFoundationPoint) else {
            return
        }
        
        guard let ringTipUIKitPoint = videoPreviewLayer?.layerPointConverted(fromCaptureDevicePoint: ringTipPoint.toAVFoundationPoint) else {
            return
        }
        
        guard let littleDIPUIKitPoint = videoPreviewLayer?.layerPointConverted(fromCaptureDevicePoint: littleDIPPoint.toAVFoundationPoint) else {
            return
        }

        let state = handGestureProcessor.getHandState(thumbTip: thumbTipUIKitPoint, indexTip: indexTipUIKitPoint, middleDIP: middleDIPUIKitPoint, ringTip: ringTipUIKitPoint, littleDIP: littleDIPUIKitPoint)
        
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
        
        let startVid = handGestureProcessor.getHandState(thumbTip: thumbTipUIKitPoint, indexTip: indexTipUIKitPoint, middleDIP: middleDIPUIKitPoint, ringTip: ringTipUIKitPoint, littleDIP: littleDIPUIKitPoint)

        switch startVid {
        case .pinchedVidRec:
            if isTimerRunning == false {
                runTimer(seconds: 3, completion: {
                    print("pinched to start vid")
                    VideoRecorder().startRecording()
                    
                })
            }
        case .unknown:
            break
        case .pinchedPhoto:
            break
        case .pinchedVidStop:
            break
        }
        let stopVid = handGestureProcessor.getHandState(thumbTip: thumbTipUIKitPoint, indexTip: indexTipUIKitPoint, middleDIP: middleDIPUIKitPoint, ringTip: ringTipUIKitPoint, littleDIP: littleDIPUIKitPoint)

        switch stopVid {
        case .pinchedVidStop:
            if isTimerRunning == false {
                runTimer(seconds: 3, completion: {
                    print("pinched to stop vid")
                    VideoRecorder().stopRecording()
                    
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

