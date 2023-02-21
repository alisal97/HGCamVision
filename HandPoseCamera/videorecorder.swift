//
//  videorecorder.swift
//  HandPoseCamera
//
//  Created by Aly Salman on 21/02/23.
//  Copyright © 2023 CB Gang. All rights reserved.

import AVFoundation
import Photos

class VideoRecorder: NSObject {
    
    private let captureSession = AVCaptureSession()
    private let movieOutput = AVCaptureMovieFileOutput()
    private var videoDeviceInput: AVCaptureDeviceInput!
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override init() {
        super.init()
        
        setupCaptureSession()
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

extension VideoRecorder: AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("Started recording to \(fileURL)")
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error recording video: \(error.localizedDescription)")
        } else {
            print("Finished recording to \(outputFileURL)")
            
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
                    }) { success, error in
                        if let error = error {
                            print("Error saving video to photo library: \(error.localizedDescription)")
                        } else {
                            print("Saved video to photo library")
                        }
                    }
                }
            }
        }
    }
}
