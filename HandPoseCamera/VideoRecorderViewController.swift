//
//  VideoRecorderViewController.swift
//  HGCam
//
//  Created by Aly Salman on 21/02/23.
//  Copyright © 2023 CB Gang. All rights reserved.
//

import AVFoundation
import SnapKit
import Photos
import SwiftUI
import Foundation
import UIKit

class VideoRecorderViewController: UIViewController {
    
    private let captureSession = AVCaptureSession()
    private let movieOutput = AVCaptureMovieFileOutput()
    private var videoDeviceInput: AVCaptureDeviceInput!
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let recordButton = UIButton()
    private var isRecording = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        setupCaptureSession()
        setupPreviewLayer()
        setupRecordButton()
    }
    
    private func setupCaptureSession() {
        captureSession.beginConfiguration()
        
        // Add video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            fatalError("Could not get video device")
        }
        
        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if captureSession.canAddInput(videoDeviceInput) {
                captureSession.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
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
        
        captureSession.commitConfiguration()
    }
    
    private func setupPreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = .resizeAspectFill
        
        view.layer.addSublayer(previewLayer!)
        
        
    }
    
    private func setupRecordButton() {
        recordButton.backgroundColor = .red
        recordButton.addTarget(self, action: #selector(recordButtonTapped), for: .touchUpInside)
        
        view.addSubview(recordButton)
        
        recordButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin).offset(-16)
            make.width.height.equalTo(80)
        }
    }
    
    @objc private func recordButtonTapped() {
        if !isRecording {
            startRecording()
            isRecording = true
            recordButton.backgroundColor = .green
        } else {
            stopRecording()
            isRecording = false
            recordButton.backgroundColor = .red
        }
    }
    
     func startRecording() {
        if !movieOutput.isRecording {
            let outputPath = NSTemporaryDirectory() + "output.mov"
            let outputFileURL = URL(fileURLWithPath: outputPath)
            
            movieOutput.startRecording(to: outputFileURL, recordingDelegate: self)
        }
    }
    
     func stopRecording() {
        if movieOutput.isRecording {
            movieOutput.stopRecording()
        }
    }
}

extension VideoRecorderViewController: AVCaptureFileOutputRecordingDelegate {
    
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
