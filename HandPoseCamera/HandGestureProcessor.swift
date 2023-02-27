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
        
        if distanceIT <= 15 && distanceIM >= 9 && isRec == false {
            return .pinchedPhoto
            
        } else if distanceTM <= 13 && distanceRM <= 13 && distanceRL >= 7 && distanceIM >= 9 && isRec == false {
            return .pinchedVidRec
            
        } else if distanceTR <= 13 && distanceRL <= 15 && distanceRM >= 7 && distanceIT >= 9 && isRec == true {
            return .pinchedVidStop
            
        } else if distanceIT >= 17 || distanceTM + distanceRM >= 27 || distanceTR + distanceRL >= 29
                    {
            //                if indexTip.y > middleTipDIP.y && indexTip.y > ringTip.y && indexTip.y > littleDIP.y {
            //                return .pinched
            //            } else {
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
