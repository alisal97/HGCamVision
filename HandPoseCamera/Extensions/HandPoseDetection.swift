//
//  HandPoseDetection.swift
//  HGCam
//
//  Created by Aly Salman on 06/07/23.
//  Copyright © 2023 CB Gang. All rights reserved.
//

import Foundation
import UIKit
import CoreML
import AVFoundation
import Vision

class HandPoseDetection {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .leftMirrored, options: [:])
        
        do {
            try handler.perform([CameraViewController.handPoseRequest])
        } catch {
            print(error)
        }
        
        guard let handPoses = CameraViewController.handPoseRequest.results, !handPoses.isEmpty else {
            return
        }
        
        guard let observation = handPoses.first else {return}
        
        CameraViewController.frameCounter += 1
        if CameraViewController.frameCounter % CameraViewController.handPosePredictionInterval == 0 {
            makePrediction(handPoseObservation: observation)
            CameraViewController.frameCounter = 0
        }
    }
    
    func makePrediction(handPoseObservation: VNHumanHandPoseObservation) {
        guard let keypointsMultiArray = try? handPoseObservation.keypointsMultiArray() else { fatalError() }
        do {
            let prediction = try CameraViewController.model!.prediction(poses: keypointsMultiArray)
            let label = prediction.label
            guard let confidence = prediction.labelProbabilities[label] else { return }
            print("label: \(prediction.label)\nconfidence: \(confidence)")

            if confidence > 0.95 {
                DispatchQueue.main.async { [self] in
                    let currentPrediction = try? CameraViewController.model!.prediction(poses: keypointsMultiArray)
                    let currentLabel = currentPrediction?.label

                    let isHandMoving = isHandPoseMoving(previous: CameraViewController.previousKeypointsMultiArray, current: keypointsMultiArray)

                    CameraViewController.previousKeypointsMultiArray = keypointsMultiArray

                    if currentLabel == label && confidence > 0.95 && !isHandMoving {
                        switch label {
                        case "ok":
                            if !CameraViewController.isTimerRunning && !CameraViewController.isRecording && !CameraViewController.isCap {
                                CameraViewController.runTimer(seconds: 3, completion: { [weak self] in
                                    guard let self else { return }
                                    CameraViewController.isCap = true
                                    CameraViewController.captureImage()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.95) {
                                        CameraViewController.isCap = false
                                    }
                                })
                            }
                            else if !CameraViewController.isTimerRunning && CameraViewController.isRecording && !CameraViewController.isCap {
                                
                                CameraViewController.runTimer(seconds: 1, completion: { [weak self] in
                                    guard let self else { return }
                                    
                                    CameraViewController.captureImage()
                                    CameraViewController.isCap = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        CameraViewController.isCap = false
                                    }
                                    
                                }
                                    )
                                         }
                        case "peace":
                            if !CameraViewController.isTimerRunning && !CameraViewController.isRecording {
                                CameraViewController.runTimer(seconds: 3, completion: { [weak self] in
                                    guard self != nil else { return }
                                    CameraViewController.finishedSaving = false
                                    CameraViewController.startRecording()
                                })
                            }
                            else if !CameraViewController.isTimerRunning && CameraViewController.isRecording {
                                CameraViewController.stopRecording()
                            }
                        
                        default:
                            break
                        }
                    }
                }
            }
        } catch {
            print("Prediction error")
        }
    }

    // Function to check if the hand pose is moving
    func isHandPoseMoving(previous: MLMultiArray?, current: MLMultiArray) -> Bool {
        guard let previous = previous else { return true }

        // Compare the previous and current hand pose arrays
        let poseDistance = calculatePoseDistance(previous, current)

        // Define a threshold for movement detection
        let movementThreshold: Double = 0.037
        
        // If the pose distance is above the threshold, consider it as moving
        return poseDistance > movementThreshold
    }
    
    
    func calculatePoseDistance(_ pose1: MLMultiArray, _ pose2: MLMultiArray) -> Double {
        let numKeypoints = 21

        var distanceSum: Double = 0.0

        for i in 0..<numKeypoints {
            let pose1X = pose1[i].doubleValue
            let pose1Y = pose1[i + numKeypoints].doubleValue
            let pose1Z = pose1[i + (2 * numKeypoints)].doubleValue

            let pose2X = pose2[i].doubleValue
            let pose2Y = pose2[i + numKeypoints].doubleValue
            let pose2Z = pose2[i + (2 * numKeypoints)].doubleValue

            // Calculate the Euclidean distance between the keypoints
            let distance = sqrt(pow(pose2X - pose1X, 2) + pow(pose2Y - pose1Y, 2) + pow(pose2Z - pose1Z, 2))

            // Add the distance to the sum
            distanceSum += distance
        }

        // Calculate the average distance
        let averageDistance = distanceSum / Double(numKeypoints)

        return averageDistance
    }


    
    
    
}
