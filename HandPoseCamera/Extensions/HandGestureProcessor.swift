//
//  HandGestureProcessor.swift
//  HGCam
//
//  Created by Aly Salman on 20/02/23.
//  Copyright © 2023 CB Gang. All rights reserved.
//

import UIKit
//        case pinchedPause
//        case pinchedUnPause

class HandGestureProcessor: UIViewController {
    var timer: Timer?
    var currentState: State = .unknown

    enum State {
        case pinchedPhoto
        case pinchedVidRec
        case pinchedVidStop
        case unknown
    
    }
    override func viewDidLoad() {
    }
    func getHandState(thumbTip: CGPoint, indexTip: CGPoint, littleDIP: CGPoint, ringDIP: CGPoint, middleDIP: CGPoint) -> State {
        let distanceIT = abs(indexTip.y - thumbTip.y) // index and thumb
        let distanceTM = abs(thumbTip.y - middleDIP.y)// middle finger and thumb
        let distanceRM = abs(ringDIP.y - middleDIP.y) // ring finger and ring finger
        let distanceTR = abs(thumbTip.y - ringDIP.y) // thumb and ring finger
        let distanceRL = abs(ringDIP.y - littleDIP.y) // ring finger and little finger
        let distanceIM = abs(indexTip.y - middleDIP.y) // index and middle finger
        let distanceTL = abs(thumbTip.y - littleDIP.y) // thumb and little finger
        let isRec = CameraViewController.isRecording
        timer?.invalidate()

//        for _ in 1...3 {
//            print(distanceTR)
//        }
    
        if distanceIT <= 9 && distanceIM >= 5 && distanceRM >= 5 && distanceRL >= 5 && isRec == false {
            if currentState != .pinchedPhoto {
                currentState = .pinchedPhoto
                timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                    DispatchQueue.main.async {
                        self.timer = nil
                        self.currentState = .pinchedPhoto
                    }
                }
            }
        } else if distanceIM >= 11 && distanceTM <= 9 && distanceRL <= 11 && distanceRM <= 9 && isRec == false {
            if currentState != .pinchedVidRec {
                currentState = .pinchedVidRec
                timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                    DispatchQueue.main.async {
                        self.timer = nil
                        self.currentState = .pinchedVidRec
                    }
                }
            }
        } else if distanceTM >= 11 && distanceRL >= 11 && distanceTL <= 11 && isRec == true {
            if currentState != .pinchedVidStop {
                currentState = .pinchedVidStop
                timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                    DispatchQueue.main.async {
                        self.timer = nil
                        self.currentState = .pinchedVidStop
                    }
                }
//                | distanceTM + distanceRM >= 19 || distanceTR + distanceRL >= 21
            } else if distanceIT >= 13  {
                currentState = .unknown
            }
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
