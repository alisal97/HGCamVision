//
//  CamMicInputs.swift
//  HGCam
//
//  Created by Aly Salman on 01/03/23.
//  Copyright © 2023 CB Gang. All rights reserved.
//
import UIKit
import Foundation
import AVFoundation
import Vision
import Photos
import SnapKit


import AVKit
var audioPlayer: AVAudioPlayer? //for playing  sound
func loadAudioPlayer(fileName: String, fileType: String) -> AVAudioPlayer? {
    if let sound = Bundle.main.path(forResource: fileName, ofType: fileType) {
        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: sound))
            return audioPlayer
        } catch {
            print("Error loading sound file: \(error.localizedDescription)")
        }
    }
    return nil
}


//
//extension CameraViewController {
//    func prepareCaptureSession() {
//        captureSession?.beginConfiguration()
//        let captureSession = AVCaptureSession()
//
//        // Select a front facing camera, make an input.
//
//        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraPosition) else { return }
//        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
//
//        captureSession.addInput(input)
//
//        let videoOutput = AVCaptureVideoDataOutput()
//        videoOutput.setSampleBufferDelegate(self, queue: .main)
//        captureSession.addOutput(videoOutput)
//
//
//        let photoOutput = AVCapturePhotoOutput()
//        captureSession.addOutput(photoOutput)
//
//        // Add video input
//
//        do {
//            let videoDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
//            if captureSession.canAddInput(videoDeviceInput) {
//                captureSession.addInput(videoDeviceInput)
//            }
//        } catch {
//            fatalError("Could not create video device input: \(error.localizedDescription)")
//        }
//        // Add video output
//        if captureSession.canAddOutput(movieOutput) {
//            captureSession.addOutput(movieOutput)
//        }
//
//        self.captureSession?.sessionPreset = .high
//        self.captureSession = captureSession
//
//        DispatchQueue.global(qos: .background).async {
//            self.captureSession?.startRunning()
//        }
//
//        addAudioInput()
//        captureSession.commitConfiguration()
//
//    }
//

//
//    func prepareCaptureUI() {
//        guard let session = captureSession else { return }
//        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
//        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
//        videoPreviewLayer.frame = view.layer.bounds
//        view.layer.addSublayer(videoPreviewLayer)
//
//        self.videoPreviewLayer = videoPreviewLayer
//    }
//
//    //  function in objectiveC to switch the camera between back and front. we have to add audio input again after switching camera, otherwise it will not work.
//    @objc func toggleCamera() {
//
//        // Toggle the camera position
//        currentCameraPosition = (currentCameraPosition == .front) ? .back : .front
//
//        // Stop the capture session and remove the inputs
//        captureSession?.stopRunning()
//        for input in captureSession!.inputs {
//            captureSession?.removeInput(input)
//        }
//
//        // Re-add the inputs for the new camera position
//        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraPosition) else { return }
//        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
//        captureSession?.addInput(input)
//
//        // Add audio input
//        addAudioInput()
//        // Restart the capture session
//
//        DispatchQueue.global(qos: .background).async { [self] in
//            captureSession?.startRunning()
//        }
//
//    }
//    //  toggle the camera flash light
//    @objc func toggleFlash() {
//        guard let device = AVCaptureDevice.default(for: .video) else { return }
//        guard device.hasTorch else { return }
//        if currentCameraPosition == .back { // if statement to check if the back camera is in use before toggling on the flash
//            do {
//                try device.lockForConfiguration()
//
//                if device.torchMode == .off {
//                    device.torchMode = .on
//                    let config = UIImage.SymbolConfiguration(pointSize: 35)
//                    flashButton.setImage(UIImage(systemName:"bolt.circle.fill", withConfiguration: config), for: .normal)
//                } else {
//                    device.torchMode = .off
//                    let config = UIImage.SymbolConfiguration(pointSize: 35)
//                    flashButton.setImage(UIImage(systemName:"bolt.slash.circle", withConfiguration: config), for: .normal)
//                }
//
//                device.unlockForConfiguration()
//            } catch {
//                print("Error toggling flash: \(error.localizedDescription)")
//            }
//        }
//    }
//}
