//
//  ThemeFont.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 4.11.2023.
//

import Foundation
import UIKit

struct ThemeFont {
    let headlineFont: UIFont
    let bodyFont: UIFont
}

extension ThemeFont {
    static var defaultTheme: ThemeFont {
        return ThemeFont(
            headlineFont: .systemFont(ofSize: FontSize.headline),
            bodyFont: .systemFont(ofSize: FontSize.body))
    }
}
