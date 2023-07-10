//
//  viewHelpers.swift
//  HGCam
//
//  Created by Aly Salman on 10/07/23.
//  Copyright © 2023 CB Gang. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    func overlayWith(image: UIImage, offsetX: CGFloat, offsetY: CGFloat) -> UIImage? {
        let newSize = size
        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
        
        let circleRect = CGRect(origin: .zero, size: newSize)
        draw(in: circleRect)
        
        let imageRect = CGRect(x: (size.width - image.size.width) / 2.0 + offsetX,
                               y: (size.height - image.size.height) / 2.0 + offsetY,
                               width: image.size.width,
                               height: image.size.height)
        image.draw(in: imageRect)
        
        let combinedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return combinedImage
    }
}

