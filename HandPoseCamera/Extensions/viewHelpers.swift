//
//  viewHelpers.swift
//  HGCam
//
//  Created by Aly Salman on 10/07/23.
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

extension UILabel {
    var padding: UIEdgeInsets {
        get {
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
        set {
            let padding = newValue
            let rect = self.bounds.inset(by: padding)
            self.drawText(in: rect)
        }
    }
}
