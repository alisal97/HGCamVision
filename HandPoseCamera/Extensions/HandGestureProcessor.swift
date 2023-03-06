//
//  HandGestureProcessor.swift
//  HGCam
//
//  Created by Aly Salman on 20/02/23.
//  Copyright © 2023 CB Gang. All rights reserved.
//

import UIKit

class HandGestureProcessor: UIViewController {
    var timer: Timer?
    var currentState: State = .unknown
    
    enum State {
        case capturePhoto
        case vidRec
        case vidStop
        case pauseVid
        case unpauseVid
        
        case unknown
        
    }
    override func viewDidLoad() {
    }
    func getHandState(thumbTip: CGPoint, indexTip: CGPoint, littleDIP: CGPoint, ringDIP: CGPoint, middleDIP: CGPoint, ringTip: CGPoint, littleTip: CGPoint) -> State {
        let distanceIT = abs(indexTip.y - thumbTip.y) // index and thumb
        let distanceTM = abs(thumbTip.y - middleDIP.y)// middle finger and thumb
        let distanceRM = abs(ringDIP.y - middleDIP.y) // ring finger and ring finger
        let distanceTR = abs(thumbTip.y - ringTip.y) // thumb and ring finger
        let distanceRL = abs(ringDIP.y - littleDIP.y) // ring finger and little finger
        let distanceIM = abs(indexTip.y - middleDIP.y) // index and middle finger
        let distanceTL = abs(thumbTip.y - littleTip.y) // thumb and little finger
        let distanceIR = abs(middleDIP.y - indexTip.y) // middle finger and index finger
        let isRec = CameraViewController.isRecording
        let isPaused = CameraViewController.isRecordingPaused
        timer?.invalidate()
        
        //        for _ in 1...3 {
        //            print(distanceTR)
        //        }
        
        if distanceIT <= 9 && distanceIM >= 5 && distanceRM >= 5 && distanceRL >= 5 && isRec == false {
            if currentState != .capturePhoto {
                currentState = .capturePhoto
                timer = Timer.scheduledTimer(withTimeInterval: 0.3 , repeats: false) { _ in
                    DispatchQueue.main.async {
                        self.timer = nil
                        self.currentState = .capturePhoto
                    }
                }
            }
        } else if distanceIM >= 11 && distanceTM <= 7 && distanceRL <= 11 && distanceRM <= 9 && isRec == false {
            if currentState != .vidRec {
                currentState = .vidRec
                timer = Timer.scheduledTimer(withTimeInterval: 0.3 , repeats: false) { _ in
                    DispatchQueue.main.async {
                        self.timer = nil
                        self.currentState = .vidRec
                    }
                }
            }
        } else if distanceIR >= 11 && distanceRL <= 19 && distanceTL <= 21 && distanceTR <= 19 && isRec == true {
            if currentState != .vidStop {
                currentState = .vidStop
                timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                    DispatchQueue.main.async {
                        self.timer = nil
                        self.currentState = .vidStop
                    }
                }
            }
//        } else if distanceTR <= 15 && isPaused == false {
//            if currentState != .pauseVid {
//                currentState = .pauseVid
//                timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
//                    DispatchQueue.main.async {
//                        self.timer = nil
//                        self.currentState = .pauseVid
//                    }
//                }
//            }
//        } else if distanceRL <= 17 && distanceIT >= 15 && distanceRM >= 15 && isPaused == true {
//            if currentState != .unpauseVid {
//                currentState = .unpauseVid
//                timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
//                    DispatchQueue.main.async {
//                        self.timer = nil
//                        self.currentState = .unpauseVid
//                    }
//                }
//            }
        } else if distanceIT >= 13 || distanceTM >= 11 || distanceTL >= 23 || distanceTR >= 23 {
            currentState = .unknown
        } else {
            currentState = .unknown
        }
        
        return currentState
    }
}

// MARK: - CGPoint helpers
extension CGPoint {
    
    func distance(from point: CGPoint) -> CGFloat {
        return hypot(point.x - x, point.y - y)
    }
}
