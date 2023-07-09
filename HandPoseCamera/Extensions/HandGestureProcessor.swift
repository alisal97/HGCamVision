//
//  HandGestureProcessor.swift
//  HGCam
//
//  Created by Aly Salman on 20/02/23.
//  Copyright © 2023 CB Gang. All rights reserved.
//

import UIKit

class HandGestureProcessor: UIViewController {
    var currentState: State = .unknown
    
    enum State {
        case capturePhoto
        case quickPhoto
        case vidRec
        case vidStop
        case unknown
        
    }

    override func viewDidLoad() {
    }
    func getHandState(thumbTip: CGPoint, indexTip: CGPoint, littleDIP: CGPoint, ringDIP: CGPoint, middleDIP: CGPoint, ringTip: CGPoint, handBase: CGPoint, littleTip: CGPoint, indexPIP: CGPoint, littlePIP: CGPoint, ringPIP: CGPoint , middlePIP: CGPoint) -> State {
        let distanceIT = abs(indexTip.y - thumbTip.y) // index and thumb
        let distanceTM = abs(thumbTip.y - middleDIP.y)// middle finger and thumb
        let distanceRM = abs(ringDIP.y - middleDIP.y) // ring finger and middle finger
        let distanceTR = abs(ringTip.y - thumbTip.y) // thumb and ring finger tips
        let distanceRT = abs(ringDIP.y - thumbTip.y) // ringdip and thumb tip
        let distanceRL = abs(ringDIP.y - littleDIP.y) // ring finger and little finger
        let distanceIM = abs(indexTip.y - middleDIP.y) // index and middle finger
//        let distanceTL = abs(thumbTip.y - littleTip.y) // thumb and little finger
//        let distanceBL = abs(handBase.y - littleTip.y) // wrist and little finger tip
//        let distanceBR = abs(handBase.y - ringTip.y) // wrist and ring finger tip
        let distanceIR = abs(ringDIP.y - indexTip.y) // middle finger and index finger
        
        // pip distances for fist
//        let distanceIMP = abs(indexPIP.y - middlePIP.y)
//        let distanceMRP = abs(middlePIP.y - ringPIP.y)
//        let distanceRLP = abs(ringPIP.y - littlePIP.y)
//        let distanceTIP = abs(thumbTip.y - indexPIP.y)
//        let distanceTMP = abs(thumbTip.y - middlePIP.y)

        
        let isRec = CameraViewController.isRecording
        

        if distanceIT <= 13.5 && distanceIM >= 7 && distanceRM >= 7 && distanceRL >= 5 && isRec == false {
            currentState = .capturePhoto
            
        } else if distanceIT <= 13.5 && distanceIM >= 7 && distanceRM >= 7 && distanceRL >= 5 && isRec == true {
            currentState = .quickPhoto
        }
        else if (distanceTR <= 10.3 || distanceRT <= 10.3) && distanceRL <= 11 && distanceIR >= 11 && distanceRM >= 11 && distanceTM >= 11 && distanceIT >= 11 && isRec == false {
            currentState = .vidRec
            
        } else if (distanceTR <= 10.3 || distanceRT <= 10.3) && distanceRL <= 11 && distanceIR >= 11 && distanceRM >= 11 && distanceTM >= 11 && distanceIT >= 11 && isRec == true {
            currentState = .vidStop
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



    
