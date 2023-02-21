//
//  VideoRec.swift
//  HandPoseCamera
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

    func getHandState(thumbTip: CGPoint, indexTip: CGPoint, middleDIP: CGPoint, ringTip: CGPoint, littleDIP: CGPoint) -> State {
        let distanceY = abs(indexTip.y - thumbTip.y)
        let distanceX = abs(ringTip.y - thumbTip.y)
        let distanceZ = abs(littleDIP.y - thumbTip.y)
//        
        if distanceY < 33 {
            return .pinchedPhoto
                
        } else if distanceX < 45 {
            return .pinchedVidRec
            
        } else if distanceZ < 51 {
            
            return .pinchedVidStop
            
                        } else if distanceY < 200 && distanceX < 200 && distanceZ < 200
                    {
            //                if indexTip.y > middleDIP.y && indexTip.y > ringTip.y && indexTip.y > littleDIP.y {
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
