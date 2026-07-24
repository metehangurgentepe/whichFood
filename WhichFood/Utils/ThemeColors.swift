//
//  ThemeColors.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 27.09.2023.
//

import Foundation
import UIKit

enum Colors: String {
    case primary
    case accent
    case text
    case secondAccent
    case opacWhite
    case crownColor
    case containerBackgroundColor
    case secondary
    
    var color: UIColor {
        switch self {
        case .primary:
            return UIColor { traitCollection in
                switch traitCollection.userInterfaceStyle {
                case .dark:
                    return UIColor(hex: 0xFF5722) // Daha açık bir turuncu
                default:
                    return UIColor(hex: 0xFF5722) // Mevcut turuncu
                }
            }
            
        case .accent:
            return UIColor { traitCollection in
                switch traitCollection.userInterfaceStyle {
                case .dark:
                    return UIColor(hex: 0xFFD54F) // Daha parlak sarı
                default:
                    return UIColor(hex: 0xFFC107) // Mevcut sarı
                }
            }
            
        case .secondAccent, .secondary:
            return UIColor { traitCollection in
                switch traitCollection.userInterfaceStyle {
                case .dark:
                    return UIColor(hex: 0xB78000) // Daha açık altın
                default:
                    return UIColor(hex: 0x916400) // Mevcut altın
                }
            }
            
        case .crownColor:
            return UIColor { traitCollection in
                switch traitCollection.userInterfaceStyle {
                case .dark:
                    return UIColor(hex: 0xFFCC6A) // Daha parlak altın
                default:
                    return UIColor(hex: 0xffbb48) // Mevcut altın
                }
            }
            
        case .text:
            return UIColor { traitCollection in
                switch traitCollection.userInterfaceStyle {
                case .dark:
                    return .white
                default:
                    return .black
                }
            }
            
        case .opacWhite:
            return UIColor { traitCollection in
                switch traitCollection.userInterfaceStyle {
                case .dark:
                    return UIColor(hex: 0x2C2C2C) // Koyu gri
                default:
                    return UIColor(hex: 0xfffbf5) // Mevcut beyaz
                }
            }
            
        case .containerBackgroundColor:
            return UIColor { traitCollection in
                switch traitCollection.userInterfaceStyle {
                case .dark:
                    return UIColor(hex: 0x4A4D4A) // Daha koyu gri
                default:
                    return UIColor(hex: 0x878a87) // Mevcut gri
                }
            }
        }
    }
}


