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
        
        if distanceY <= 23 && distanceIM >= 9 {
            return .pinchedPhoto
            
        } else if distanceX <= 15 && distanceRM <= 19 && distanceRL > 3 && isRec == false {
            return .pinchedVidRec
            
        } else if distanceZ <= 15 && distanceRL <= 19 && distanceRM > 3 && isRec == true {
            return .pinchedVidStop
            
        } else if distanceY >= 25 || distanceX + distanceRM >= 35 || distanceZ + distanceRL >= 35
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
