//
//  OnboardingPage.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 13.01.2025.
//

import Foundation

struct OnboardingPage: Identifiable {
    let id = UUID()
    let image: String
    let titleKey: String // Localization key for title
    let descriptionKey: String // Localization key for description
    let buttonTitleKey: String // Localization key for button title
    
    var title: String {
        NSLocalizedString(titleKey, comment: "")
    }
    
    var description: String {
        NSLocalizedString(descriptionKey, comment: "")
    }
    
    var buttonTitle: String {
        NSLocalizedString(buttonTitleKey, comment: "")
    }
}
