//
//  UIImage+Ext.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 27.02.2024.
//

import Foundation
import UIKit

extension UIImage {
    func resize(toSize targetSize: CGSize) -> UIImage {
        let size = self.size

        let widthScale = targetSize.width / size.width
        let heightScale = targetSize.height / size.height

        let newSize: CGSize
        if widthScale > heightScale {
            newSize = CGSize(width: size.width * heightScale, height: size.height * heightScale)
        } else {
            newSize = CGSize(width: size.width * widthScale, height: size.height * widthScale)
        }

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage ?? self
    }
}
