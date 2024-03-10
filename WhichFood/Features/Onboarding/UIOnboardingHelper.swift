//
//  UIOnboardingHelper.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 25.10.2023.
//

import UIKit
import UIOnboarding

struct UIOnboardingHelper {
    static func setUpIcon() -> UIImage {
        Bundle.main.appIcon ?? .init(named: "onboarding-icon")!
    }
    
    // First Title Line
    // Welcome Text
    static func setUpFirstTitleLine() -> NSMutableAttributedString {
        .init(string: NSLocalizedString(LocaleKeys.Onboarding.welcome.rawValue, comment: ""), attributes: [.foregroundColor: UIColor.label])
    }
    
    // Second Title Line
    // App Name
    static func setUpSecondTitleLine() -> NSMutableAttributedString {
        .init(string: Bundle.main.displayName ?? "WhichFood", attributes: [
            .foregroundColor: Colors.primary.color
        ])
    }
    
    static func setUpFeatures() -> Array<UIOnboardingFeature> {
        .init([
            .init(icon: roundImage(.init(named: "feature_1")!),
                  title: NSLocalizedString(LocaleKeys.Onboarding.feature1Title.rawValue, comment: ""),
                  description: NSLocalizedString(LocaleKeys.Onboarding.feature1.rawValue, comment: "")),
            .init(icon: roundImage(.init(named: "feature_2")!),
                  title: NSLocalizedString(LocaleKeys.Onboarding.feature2Ttitle.rawValue, comment: ""),
                  description: NSLocalizedString(LocaleKeys.Onboarding.feature2.rawValue, comment: "")),
            .init(icon: roundImage(.init(named: "feature_3")!),
                  title: NSLocalizedString(LocaleKeys.Onboarding.feature3Title.rawValue, comment: ""),
                  description: NSLocalizedString(LocaleKeys.Onboarding.feature3.rawValue, comment: ""))
        ])
    }
    
    static func setUpNotice() -> UIOnboardingTextViewConfiguration {
        .init(icon: .init(named: "onboarding-notice-icon"),
              text: NSLocalizedString(LocaleKeys.Onboarding.footer.rawValue, comment: ""),
              linkTitle: NSLocalizedString(LocaleKeys.Onboarding.more.rawValue, comment: ""),
              link: "https://superlative-bienenstitch-1a1e1f.netlify.app/",
              tint: Colors.primary.color)
    }
    
    static func setUpButton() -> UIOnboardingButtonConfiguration {
        .init(title: NSLocalizedString(LocaleKeys.Onboarding.button.rawValue, comment: ""),
              backgroundColor: Colors.primary.color)
    }
}

extension UIOnboardingViewConfiguration {
    static func setUp() -> UIOnboardingViewConfiguration {
        .init(appIcon: UIOnboardingHelper.setUpIcon(),
              firstTitleLine: UIOnboardingHelper.setUpFirstTitleLine(),
              secondTitleLine: UIOnboardingHelper.setUpSecondTitleLine(),
              features: UIOnboardingHelper.setUpFeatures(),
              textViewConfiguration: UIOnboardingHelper.setUpNotice(),
              buttonConfiguration: UIOnboardingHelper.setUpButton())
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
