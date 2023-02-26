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
        case unknown
    }

    func getHandState(thumbTip: CGPoint, indexTip: CGPoint, littleDIP: CGPoint, ringDIP: CGPoint, middleDIP: CGPoint) -> State {
        let distanceY = abs(indexTip.y - thumbTip.y)
        let distanceX = abs(thumbTip.y - middleDIP.y)
        let distanceRM = abs(ringDIP.y - middleDIP.y)
        let distanceZ = abs(thumbTip.y - ringDIP.y)
        let distanceRL = abs(ringDIP.y - littleDIP.y)
        let distanceIM = abs(indexTip.y - middleDIP.y)
        
        let isRec = CameraViewController.isRecording
        
        if distanceY <= 23 && distanceIM >= 9 && isRec == false {
            return .pinchedPhoto
            
        } else if distanceX <= 15 && distanceRM <= 23 && isRec == false {
            return .pinchedVidRec
            
        } else if distanceZ <= 15 && distanceRL <= 25 && isRec == true {
            return .pinchedVidStop
            
        } else if distanceY >= 25.5 || distanceX + distanceRM >= 39 || distanceZ + distanceRL >= 41
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
