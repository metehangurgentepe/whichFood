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
    
    func alpha(_ value:CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(at: CGPoint.zero, blendMode: .normal, alpha: value)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    func compress(toQuality quality: CGFloat) -> Data? {
        return jpegData(compressionQuality: quality)
    }
}

func roundImage(_ image: UIImage) -> UIImage {
    let imageView = UIImageView(image: image)
    imageView.contentMode = .scaleAspectFill
    imageView.layer.cornerRadius = imageView.frame.size.width / 2
    imageView.layer.masksToBounds = true
    
    UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, 0.0)
    defer { UIGraphicsEndImageContext() }
    guard let context = UIGraphicsGetCurrentContext() else { return UIImage() }
    
    imageView.layer.render(in: context)
    guard let roundedImage = UIGraphicsGetImageFromCurrentImageContext() else { return UIImage() }
    
    return roundedImage
}
