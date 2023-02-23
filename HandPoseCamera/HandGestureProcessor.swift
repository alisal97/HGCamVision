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
        let distanceX = abs((thumbTip.y - middleDIP.y) + (ringDIP.x - middleDIP.x))
        let distanceZ = abs((thumbTip.y - ringDIP.y) + (ringDIP.x - littleDIP.x))
        
        let isRec = CameraViewController.isRecording
        
        if distanceY < 30 {
            print (isRec)
            return .pinchedPhoto
                
        } else if distanceX < 35 && isRec == false {
            return .pinchedVidRec
             
        } else if distanceZ < 37 && isRec == true {
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
