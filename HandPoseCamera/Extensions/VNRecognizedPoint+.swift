//
//  CameraViewController.swift
//  HGCam
//
//  Created by Aly Salman on 20/02/23.
//  Copyright © 2023 CB Gang. All rights reserved.
//

import Vision

extension VNRecognizedPoint {
    
    var toAVFoundationPoint: CGPoint {
        return CGPoint(x: self.location.x, y: 1 - self.location.y)
    }
}


//future implementation to pause recording

//// Declare a variable to keep track of whether recording is currently paused
//var isRecordingPaused = false
//
//// Declare a variable to store the current recording file URL
//var currentRecordingFileURL: URL?
//
//// Declare a variable to store the current recording start time
//var currentRecordingStartTime: CMTime?
//
//// Start recording
//func startRecording() {
//    let fileOutput = AVCaptureMovieFileOutput()
//
//    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//    let fileName = "\(UUID().uuidString).mp4"
//    let fileURL = documentsURL.appendingPathComponent(fileName)
//    fileOutput.startRecording(to: fileURL, recordingDelegate: self)
//    currentRecordingFileURL = fileURL
//    currentRecordingStartTime = CMClockGetTime(CMClockGetHostTimeClock())
//}
//
//// Pause recording
//func pauseRecording() {
//    guard let currentRecordingStartTime = currentRecordingStartTime, let currentRecordingFileURL = currentRecordingFileURL else { return }
//
//    let fileOutput = AVCaptureMovieFileOutput()
//    fileOutput.stopRecording()
//
//    let asset = AVAsset(url: currentRecordingFileURL)
//    let currentTime = CMClockGetTime(CMClockGetHostTimeClock())
//    let recordedDuration = CMTimeSubtract(currentTime, currentRecordingStartTime)
//
//    guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else { return }
//
//    let outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("trimmedVideo.mp4")
//
//    if FileManager.default.fileExists(atPath: outputURL.path) {
//        do {
//            try FileManager.default.removeItem(at: outputURL)
//        } catch {
//            print("Error removing file at path: \(outputURL.path)")
//        }
//    }
//
//    let startTime = CMTime.zero
//    let endTime = CMTimeAdd(startTime, recordedDuration)
//    let timeRange = CMTimeRangeFromTimeToTime(start: startTime, end: endTime)
//    exportSession.timeRange = timeRange
//    exportSession.outputURL = outputURL
//    exportSession.outputFileType = .mp4
//
//    exportSession.exportAsynchronously {
//        switch exportSession.status {
//        case .completed:
//            print("Export completed: \(outputURL)")
//        case .failed:
//            print("Export failed: \(exportSession.error?.localizedDescription ?? "unknown error")")
//        case .cancelled:
//            print("Export cancelled")
//        default:
//            print("Export in progress...")
//        }
//    }
//
//    isRecordingPaused = true
//}
//
//// Resume recording
//func resumeRecording() {
//    guard let currentRecordingFileURL = currentRecordingFileURL else { return }
//
//    let fileOutput = AVCaptureMovieFileOutput()
//    fileOutput.startRecording(to: currentRecordingFileURL, recordingDelegate: self)
//    isRecordingPaused = false
//}
//
