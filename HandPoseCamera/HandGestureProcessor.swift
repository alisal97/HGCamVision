import UIKit

class HandGestureProcessor {
    
    enum State {
        case pinchedPhoto
        case pinchedVidRec
        case pinchedVidStop
        case unknown
    }

    func getHandState(thumbTip: CGPoint, indexTip: CGPoint, middleTip: CGPoint, ringDIP: CGPoint, middleDIP: CGPoint) -> State {
        let distanceY = abs(indexTip.y - thumbTip.y)
        let distanceX = abs((thumbTip.y - middleDIP.y) + (ringDIP.x - middleDIP.x))
        let distanceZ = abs(thumbTip.y - ringDIP.y)
        
        
        if distanceY < 35 {
            return .pinchedPhoto
                
        } else if distanceX < 69 {
            return .pinchedVidRec
             
        } else if distanceZ < 35 {
            
            return .pinchedVidStop
            
            } else if distanceY < 200 && distanceX < 200 && distanceZ < 200
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
