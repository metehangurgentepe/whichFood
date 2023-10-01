//
//  ThemeColors.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 27.09.2023.
//

import Foundation
import UIKit

enum Colors: String{
    case primary
    case accent
    case text
    case secondAccent
    case opacWhite
    
    var color: UIColor{
        switch self {
        case .primary: return UIColor(hex: 0xFF5722)
        case .accent: return UIColor(hex:0xFFC107)
        case .secondAccent: return UIColor(hex:0x916400)
        case .text: return .black
        case .opacWhite: return UIColor(hex: 0xfffbf5)
        }
    }
}

extension UIColor {
    convenience init(hex: Int, alpha: CGFloat = 1.0) {
        self.init(
            red: CGFloat((hex & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((hex & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(hex & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }
}
