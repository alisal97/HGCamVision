//
//  helperFunc.swift
//  HGCam
//
//  Created by Aly Salman on 28/02/23.
//  Copyright © 2023 CB Gang. All rights reserved.
//
import UIKit
import AVKit
import Foundation
import AVFoundation
import Vision
import Photos
import SnapKit

//
//
//extension CameraViewController {
//    
//    // view for countdown timer for when taking a photo or a video
//        func prepareTimerView() {
//            let timerLabel = UILabel()
//            timerLabel.textAlignment = .center
//            timerLabel.font = UIFont.systemFont(ofSize: 41)
//            
//            view.addSubview(timerLabel)
//            timerLabel.snp.makeConstraints { maker in
//                maker.center.equalToSuperview()
//            }
//            
//            self.timerLabel = timerLabel
//        }
//
//    
//    func playShutter() {
//        
//        if let sound = Bundle.main.path(forResource: "shutter", ofType: "mp3") {
//            do {
//                audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: sound))
//            } catch {
//                print("Error loading sound file: \(error.localizedDescription)")
//            }
//            
//        }
//
//    }
//    
//    func addUILabels(){
//        view.addSubview(recordLabel)
//        recordLabel.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            recordLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -16),
//            recordLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
//        ])
//        
//        view.addSubview(switchCameraButton)
//
//        switchCameraButton.translatesAutoresizingMaskIntoConstraints = false
//
//        NSLayoutConstraint.activate([
//            switchCameraButton.widthAnchor.constraint(equalToConstant: 44),
//            switchCameraButton.heightAnchor.constraint(equalToConstant: 44),
//            switchCameraButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
//            switchCameraButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
//        ])
//        
//        
//        switchCameraButton.addTarget(self, action: #selector(toggleCamera), for: .touchUpInside)
//
//        
//        view.addSubview(galleryButton)
//
//        NSLayoutConstraint.activate([
//            galleryButton.widthAnchor.constraint(equalToConstant: 44),
//            galleryButton.heightAnchor.constraint(equalToConstant: 44),
//            galleryButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//            galleryButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
//        ])
//
//        galleryButton.addTarget(self, action: #selector(openPhotosApp), for: .touchUpInside)
//        
//        flashButton.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(flashButton)
//
//        // Add constraints to position the flash button in the top right corner
//        NSLayoutConstraint.activate([
//            flashButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -16),
//            flashButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
//        ])
//        flashButton.addTarget(self, action: #selector(toggleFlash), for: .touchUpInside)
//
//
//
//
//    }
//    //function to get the most recent media from the photos app
//    @objc func openPhotosApp() {
//        PHPhotoLibrary.requestAuthorization { status in
//            switch status {
//            case .authorized:
//                let fetchOptions = PHFetchOptions()
//                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
//                let allAssets = PHAsset.fetchAssets(with: fetchOptions)
//                guard let mostRecentAsset = allAssets.firstObject else { return }
//                
//                if mostRecentAsset.mediaType == .image {
//                    PHImageManager.default().requestImageDataAndOrientation(for: mostRecentAsset, options: nil) { (data, _, _, info) in
//                        if let imageData = data, let image = UIImage(data: imageData) {
//                            DispatchQueue.main.async {
//                                let imageView = UIImageView(image: image)
//                                imageView.frame = self.view.bounds
//                                imageView.contentMode = .scaleAspectFit
//                                imageView.backgroundColor = .black
//                                imageView.isUserInteractionEnabled = true
//                                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissImageView))
//                                imageView.addGestureRecognizer(tapGesture)
//                                self.view.addSubview(imageView)
//                            }
//                        }
//                    }
//                } else if mostRecentAsset.mediaType == .video {
//                    let requestOptions = PHVideoRequestOptions()
//                    requestOptions.version = .original
//                    
//                    PHImageManager.default().requestAVAsset(forVideo: mostRecentAsset, options: requestOptions) { (asset, audioMix, info) in
//                        if let urlAsset = asset as? AVURLAsset {
//                            let videoURL = urlAsset.url
//                            DispatchQueue.main.async {
//                                let player = AVPlayer(url: videoURL)
//                                let playerViewController = AVPlayerViewController()
//                                playerViewController.player = player
//                                self.present(playerViewController, animated: true) {
//                                    playerViewController.player?.play()
//                                }
//                            }
//                        }
//                    }
//                }
//            case .denied, .restricted:
//                print("Access to photo library is denied or restricted")
//            case .notDetermined:
//                print("Access to photo library has not been determined")
//            case .limited:
//                print("Allow access to all photos")
//            @unknown default:
//                fatalError("Unexpected case occurred while requesting photo library authorization")
//            }
//        }
//    }
//    //  function to exit the gallery view defined in the function above, you can use by clicking on the black borders
//       @objc func dismissImageView() {
//           for subview in self.view.subviews {
//               if let imageView = subview as? UIImageView {
//                   imageView.removeFromSuperview()
//               }
//           }
//           self.setNeedsStatusBarAppearanceUpdate()
//           self.navigationController?.setNavigationBarHidden(false, animated: true)
//       }
//       
//   //  function to get a thumbnail of the most recent media for the gallery button.
//       func setupGalleryButton() {
//           let fetchOptions = PHFetchOptions()
//           fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
//           let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
//
//           guard let latestAsset = fetchResult.firstObject else {
//               // There are no assets in the user's library
//               return
//           }
//
//           let imageManager = PHImageManager.default()
//           let requestOptions = PHImageRequestOptions()
//           requestOptions.deliveryMode = .fastFormat
//           requestOptions.isSynchronous = true
//
//           imageManager.requestImage(for: latestAsset, targetSize: CGSize(width: 75, height: 75), contentMode: .aspectFill, options: requestOptions) { (image, info) in
//               if let image = image {
//                   DispatchQueue.main.async {
//                       self.galleryButton.setImage(image, for: .normal)
//                   }
//               }
//           }
//       }
//
//    //  timer to start counting seconds and minutes when recording starts
//        func startTimer() {
//            recordLabel.isHidden = false
//            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
//                self?.counter += 1
//                self?.recordLabel.text = self?.formattedTime()
//            }
//        }
//
//        // Stop the timer when recording ends
//        func stopTimer() {
//            timer?.invalidate()
//            timer = nil
//            counter = 0
//            recordLabel.isHidden = true
//            recordLabel.text = "00:00"
//        }
//    // for every 60 seconds it will add a minute
//        func formattedTime() -> String {
//            let minutes = counter / 60
//            let seconds = counter % 60
//            return String(format: "%02d:%02d", minutes, seconds)
//        }
//    // also to add support for landscape mode.
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        if let connection =  self.videoPreviewLayer?.connection {
//            let currentDevice: UIDevice = UIDevice.current
//            let orientation: UIDeviceOrientation = currentDevice.orientation
//            let previewLayerConnection : AVCaptureConnection = connection
//
//            if previewLayerConnection.isVideoOrientationSupported {
//                switch (orientation) {
//                case .portrait:
//                    previewLayerConnection.videoOrientation = .portrait
//                case .landscapeRight:
//                    previewLayerConnection.videoOrientation = .landscapeLeft
//                case .landscapeLeft:
//                    previewLayerConnection.videoOrientation = .landscapeRight
//                case .portraitUpsideDown:
//                    previewLayerConnection.videoOrientation = .portraitUpsideDown
//                default:
//                    previewLayerConnection.videoOrientation = .portrait
//                }
//                self.videoPreviewLayer?.frame = self.view.bounds
//            }
//        }
//    }
//    
//    // activity indicator / loading icon for when the video is saving.
//    // since we are cutting the last 3 seconds of the recorded videos it takes a while to save.
//
//         func setupActivityIndicator() {
//            activityIndicator = UIActivityIndicatorView(style: .large)
//            activityIndicator.transform = CGAffineTransform(scaleX: 3.5, y: 3.5)
//            activityIndicator.color = UIColor.darkGray
//            activityIndicator.center = view.center
//            activityIndicator.hidesWhenStopped = true
//            DispatchQueue.main.async { [self] in
//                view.addSubview(activityIndicator)
//            }
//        }
//
//    func cameraUI() {
//        // Create a new view for the grey rectangle
//        let topView = UIView()
//        topView.translatesAutoresizingMaskIntoConstraints = false
//        topView.backgroundColor = UIColor.black.withAlphaComponent(0.79) // set the background color to transparent grey
//        view.addSubview(topView)
//
//        // Add constraints to position the top view at the top of the screen, taking up 9% of the screen height
//        topView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
//        topView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
//        topView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
//        topView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.15).isActive = true
//
//        // Create a new view for the grey rectangle
//        let bottomView = UIView()
//        bottomView.translatesAutoresizingMaskIntoConstraints = false
//        bottomView.backgroundColor = UIColor.black.withAlphaComponent(0.79) // set the background color to transparent grey
//        view.addSubview(bottomView)
//
//        // Add constraints to position the bottom view at the bottom of the screen, taking up 17% of the screen height
//        bottomView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
//        bottomView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
//        bottomView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
//        bottomView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.17).isActive = true
//            
//    }
//
//
//

////    // Declare a variable to keep track of whether recording is currently paused
////    var isRecordingPaused = false
////
////    // Declare a variable to store the current recording file URL
////    var currentRecordingFileURL: URL?
////
////    // Declare a variable to store the current recording start time
////    var currentRecordingStartTime: CMTime?
////
////    // Start recording
////    func startRecording() {
///if !movieOutput.isRecording {
////        let fileOutput = AVCaptureMovieFileOutput()
////
////        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
////        let fileName = "\(UUID().uuidString).mp4"
////        let fileURL = documentsURL.appendingPathComponent(fileName)
////        fileOutput.startRecording(to: fileURL, recordingDelegate: self)
////        currentRecordingFileURL = fileURL
////        currentRecordingStartTime = CMClockGetTime(CMClockGetHostTimeClock())
/////    startTimer()
////    }
///}
////
////    // Pause recording
////    func pauseRecording() {
////        guard let currentRecordingStartTime = currentRecordingStartTime, let currentRecordingFileURL = currentRecordingFileURL else { return }
////
////        let fileOutput = AVCaptureMovieFileOutput()
////        fileOutput.stopRecording()
////
////        let asset = AVAsset(url: currentRecordingFileURL)
////        let currentTime = CMClockGetTime(CMClockGetHostTimeClock())
////        let recordedDuration = CMTimeSubtract(currentTime, currentRecordingStartTime)
////
////        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else { return }
////
////        let outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("trimmedVideo.mp4")
////
////        if FileManager.default.fileExists(atPath: outputURL.path) {
////            do {
////                try FileManager.default.removeItem(at: outputURL)
////            } catch {
////                print("Error removing file at path: \(outputURL.path)")
////            }
////        }
////
////        let startTime = CMTime.zero
////        let endTime = CMTimeAdd(startTime, recordedDuration)
////        let timeRange = CMTimeRangeFromTimeToTime(start: startTime, end: endTime)
////        exportSession.timeRange = timeRange
////        exportSession.outputURL = outputURL
////        exportSession.outputFileType = .mp4
////
////        exportSession.exportAsynchronously {
////            switch exportSession.status {
////            case .completed:
////                print("Export completed: \(outputURL)")
////            case .failed:
////                print("Export failed: \(exportSession.error?.localizedDescription ?? "unknown error")")
////            case .cancelled:
////                print("Export cancelled")
////            default:
////                print("Export in progress...")
////            }
////        }
////
////        isRecordingPaused = true
////    }
////
////    // Resume recording
////    func resumeRecording() {
////        guard let currentRecordingFileURL = currentRecordingFileURL else { return }
////
////        let fileOutput = AVCaptureMovieFileOutput()
////        fileOutput.startRecording(to: currentRecordingFileURL, recordingDelegate: self)
////        isRecordingPaused = false
////    }
////
//
//}
