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
        
        
        let isRec = CameraViewController.isRecording
        
        if distanceY <= 25 {
            return .pinchedPhoto
            
        } else if distanceX <= 11 && distanceRM <= 13 && distanceRL > 7 && isRec == false {
            return .pinchedVidRec
            
        } else if distanceZ <= 11 && distanceRL <= 15 && distanceRM > 7 && isRec == true {
            return .pinchedVidStop
            
        } else if distanceY >= 27 || distanceX + distanceRM >= 29 || distanceZ + distanceRL >= 29
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
