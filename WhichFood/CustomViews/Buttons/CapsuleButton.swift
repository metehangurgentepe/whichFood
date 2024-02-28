//
//  CapsuleButton.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 27.02.2024.
//

import Foundation
import UIKit

/// Button Desing
public class CapsuleButton: UIButton {
    public override func layoutSubviews() {
        super.layoutSubviews()
        let cornerRadius: CGFloat = bounds.height / 2
        let path = UIBezierPath(roundedRect: bounds,
                                byRoundingCorners: [.topLeft, .topRight, .bottomLeft, .bottomRight],
                                cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        layer.mask = maskLayer
    }
}
