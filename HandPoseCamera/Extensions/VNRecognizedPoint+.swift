//
//  VNRecognizedPoint+.swift
//  HandPoseCamera
//
//  Created by Aly Salman on 20/02/23.
//  Copyright © 2023 CB Gang. All rights reserved.
//

import Vision

extension VNRecognizedPoint {
    
    var toAVFoundationPoint: CGPoint {
        return CGPoint(x: self.location.x, y: 1 - self.location.y)
    }
}
