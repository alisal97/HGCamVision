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
    func getHandState(thumbTip: CGPoint, indexTip: CGPoint, littleDIP: CGPoint, ringDIP: CGPoint, middleDIP: CGPoint, ringTip: CGPoint, handBase: CGPoint, littleTip: CGPoint) -> State {
        let distanceIT = abs(indexTip.y - thumbTip.y) // index and thumb
        let distanceTM = abs(thumbTip.y - middleDIP.y)// middle finger and thumb
        let distanceRM = abs(ringDIP.y - middleDIP.y) // ring finger and middle finger
        let distanceTR = abs(ringTip.y - thumbTip.y) // thumb and ring finger tips
        let distanceRT = abs(ringDIP.y - thumbTip.y) // ringdip and thumb tip
        let distanceRL = abs(ringDIP.y - littleDIP.y) // ring finger and little finger
        let distanceIM = abs(indexTip.y - middleDIP.y) // index and middle finger
        let distanceTL = abs(thumbTip.y - littleTip.y) // thumb and little finger
        let distanceBL = abs(handBase.y - littleTip.y) // wrist and little finger tip
        let distanceBR = abs(handBase.y - ringTip.y) // wrist and ring finger tip
        let distanceIR = abs(ringDIP.y - indexTip.y) // middle finger and index finger
        let isRec = CameraViewController.isRecording
        //        let isPaused = CameraViewController.isRecordingPaused
        timer?.invalidate()
        
                for _ in 1...3 {
                    print("wrist-littletip \(distanceBL)")
                }
                for _ in 1...3 {
                    print("wrist-ring \(distanceBR)")
                }
        
        
        if distanceIT <= 9 && distanceIM >= 9 && distanceRM >= 9 && distanceRL >= 9 && isRec == false {
            currentState = .capturePhoto
        } else if (distanceTR <= 14.7 || distanceRT <= 14.7) && distanceRL <= 15.3 && distanceIR >= 17 && distanceRM >= 17 && distanceTM >= 17 && distanceIT >= 17 && isRec == false {
            currentState = .vidRec
            guard (distanceTR <= 14.7 || distanceRT <= 14.7) && distanceRM >= 5 && distanceRL >= 5 && isRec == false else { return currentState }
        } else if distanceBL <= 27 && distanceBR <= 23 && distanceIM >= 17 && distanceIT >= 17 && distanceRL <= 7.7 && distanceRM <= 7.5 && isRec == true {
            currentState = .vidStop
            guard  distanceBL <= 27 && distanceBR <= 23 && distanceIM >= 17 && distanceIT >= 17 && distanceRL <= 7.7 && distanceRM <= 7.7 && isRec == true else { return currentState }
        } else {
            currentState = .unknown
        }
        
        return currentState
    }
    }


//        if distanceIT <= 9 && distanceIM >= 9 && distanceRM >= 9 && distanceRL >= 9 && isRec == false {
//            if currentState != .capturePhoto {
//                currentState = .capturePhoto
//                timer = Timer.scheduledTimer(withTimeInterval: 3.0 , repeats: false) { _ in
//                    if distanceIT <= 9 && distanceIM >= 5 && distanceRM >= 5 && distanceRL >= 5 && isRec == false {
//                        self.timer = nil
//                        self.currentState = .capturePhoto
//                    }
//                }
//            }
//        } else if (distanceTR <= 14.7 || distanceRT <= 14.7) && distanceRL <= 15.3 && distanceIR >= 17 && distanceRM >= 17 && distanceTM >= 17 && distanceIT >= 17 && isRec == false {
//            if currentState != .vidRec {
//                currentState = .vidRec
//                timer = Timer.scheduledTimer(withTimeInterval: 3.0 , repeats: false) { _ in
//                    if  (distanceTR <= 14.7 || distanceRT <= 14.7) && distanceRL <= 15.3 && distanceIR >= 17 && distanceRM >= 17 && distanceTM >= 17 && distanceIT >= 17 && isRec == false {
//                        self.timer = nil
//                        self.currentState = .vidRec
//                    }
//                }
//            }
//        } else if distanceIM >= 17 && distanceIT >= 17 && distanceTM <= 6.7 && distanceRL <= 7 && distanceRM <= 7 && isRec == true {
//            if currentState != .vidStop {
//                currentState = .vidStop
//                timer = Timer.scheduledTimer(withTimeInterval: 3.0 , repeats: false) { _ in
//                    if distanceIM >= 17 && distanceIT >= 17 && distanceTM <= 6.7 && distanceRL <= 7 && distanceRM <= 7 && isRec == true {
//                        self.timer = nil
//                        self.currentState = .vidStop
//                    }
//                }
//            }
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
//        } else if distanceIT >= 9.1 || distanceTM >= 7.3 || distanceTL >= 15.3 || distanceTR >= 15.3 {
//            currentState = .unknown
//        } else {
//            currentState = .unknown
//        }
//
//        return currentState
//    }
//}

// MARK: - CGPoint helpers
extension CGPoint {
    
    func distance(from point: CGPoint) -> CGFloat {
        return hypot(point.x - x, point.y - y)
    }
}
