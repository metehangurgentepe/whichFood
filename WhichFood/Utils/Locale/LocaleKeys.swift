//
//  LocaleKeys.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 12.09.2023.
//

import Foundation
import SwiftUI


struct LocaleKeys {
    enum Tab: String{
        case home = "tabHome"
        case receipes = "tabReceips"
    }
    enum Premium: String{
        case weekButton = "premiumWeekButton"
        case lifetimeButton = "lifetimeButton"
        case continueButton = "continueButton"
    }
}

extension String {
    func locale() -> LocalizedStringKey {
        return LocalizedStringKey(self)
    }
}
