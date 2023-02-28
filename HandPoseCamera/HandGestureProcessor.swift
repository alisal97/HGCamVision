//
//  HandGestureProcessor.swift
//  HGCam
//
//  Created by Aly Salman on 20/02/23.
//  Copyright © 2023 CB Gang. All rights reserved.
//

import UIKit

class HandGestureProcessor {
    
    enum State {
        case pinchedPhoto
        case pinchedVidRec
        case pinchedVidStop
//        case pinchedPause
//        case pinchedUnPause
        case unknown
    }

    func getHandState(thumbTip: CGPoint, indexTip: CGPoint, littleDIP: CGPoint, ringDIP: CGPoint, middleDIP: CGPoint) -> State {
        let distanceIT = abs(indexTip.y - thumbTip.y) // index and thumb
        let distanceTM = abs(thumbTip.y - middleDIP.y)// middle finger and thumb
        let distanceRM = abs(ringDIP.y - middleDIP.y) // ring finger and ring finger
        let distanceTR = abs(thumbTip.y - ringDIP.y) // thumb and ring finger
        let distanceRL = abs(ringDIP.y - littleDIP.y) // ring finger and little finger
        let distanceIM = abs(indexTip.y - middleDIP.y) // index and middle finger
        
        
        let isRec = CameraViewController.isRecording
        
        if distanceIT <= 9 && distanceIM >= 11 && distanceRM >= 5 && distanceRL >= 5 && isRec == false {
            return .pinchedPhoto
            
        } else if distanceTM <= 9 && distanceRM <= 7 && distanceRL >= 5 && distanceIM >= 5 && isRec == false {
            return .pinchedVidRec
            
        } else if distanceTR <= 9 && distanceRL <= 7 && distanceRM >= 5 && distanceIT >= 5 && isRec == true {
            return .pinchedVidStop
            
        } else if distanceIT >= 11 || distanceTM + distanceRM >= 19 || distanceTR + distanceRL >= 19
                    {
            return .unknown
                        } else {
            return .unknown
        }
    }
}

// MARK: - CGPoint helpers
extension CGPoint {
    
    func distance(from point: CGPoint) -> CGFloat {
        return hypot(point.x - x, point.y - y)
    }
}
