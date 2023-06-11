//
//  HandGestureProcessor.swift
//  HGCam
//
//  Created by Aly Salman on 20/02/23.
//  Copyright © 2023 CB Gang. All rights reserved.
//

import UIKit

class HandGestureProcessor: UIViewController {
    var timer: Timer?
    var currentState: State = .unknown
    
    enum State {
        case capturePhoto
        case vidRec
        case vidStop
        case pauseVid
        case unpauseVid
        
        case unknown
        
    }

    override func viewDidLoad() {
    }

