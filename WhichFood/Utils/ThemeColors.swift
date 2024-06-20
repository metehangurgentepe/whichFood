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
    case crownColor
    case containerBackgroundColor
    
    var color: UIColor{
        switch self {
        case .primary: return UIColor(hex: 0xFF5722)
        case .accent: return UIColor(hex:0xFFC107)
        case .secondAccent: return UIColor(hex:0x916400)
        case .crownColor: return UIColor(hex:0xffbb48)
        case .text: return .black
        case .opacWhite: return UIColor(hex: 0xfffbf5)
        case .containerBackgroundColor : return UIColor(hex: 0x878a87)
        }
    }
}


