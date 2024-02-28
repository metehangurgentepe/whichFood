//
//  SettingsViewModel.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 26.09.2023.
//

import Foundation
import UIKit
import MessageUI

enum SettingsViewModelOutput {
    case sendMail
    case navigate(vc: UIViewController)
    case showError(Error)
    case present(vc: UIViewController)
    case makeAlertDarkMode
    case popVC
}

protocol SettingsViewModelDelegate: AnyObject {
    func handleViewModelOutput(_ output: SettingsViewModelOutput)
}

class SettingsViewModel:NSObject, MFMailComposeViewControllerDelegate{
    weak var delegate: SettingsViewModelDelegate?
    
    private(set) var userId: String = ""
    
    var models: [SettingsOption] = []
    
    func getUserId() -> String {
        let userId = UIDevice.current.identifierForVendor?.uuidString
        let string = "\(LocaleKeys.Settings.userId.rawValue.locale()) \(userId ?? "")"
        return string
    }
    
    func appendRowTableview() {
        models.append(SettingsOption(
            title: LocaleKeys.AccountScreen.title.rawValue.locale(),
            icon: SFSymbols.person,
            iconBackgroundColor: Colors.accent.color,
            handler: {
                let vc = AccountViewController()
                self.delegate?.handleViewModelOutput(.navigate(vc: vc))
        }))
        
        models.append(SettingsOption(
            title: LocaleKeys.Settings.premium.rawValue.locale(),
            icon: Images.premium,
            iconBackgroundColor:  Colors.accent.color,
            handler: {
                let vc = PremiumVC()
                self.delegate?.handleViewModelOutput(.present(vc: vc))
            }))
        models.append(SettingsOption(
            title: LocaleKeys.Settings.language.rawValue.locale(),
            icon: Images.network,
            iconBackgroundColor: Colors.accent.color,
            handler: {
                let alert = showAlert(
                    title: LocaleKeys.Settings.errorTitle.rawValue.locale(),
                    message: LocaleKeys.Settings.errorMessage.rawValue.locale(),
                    buttonTitle: LocaleKeys.Settings.continueButton.rawValue.locale(),
                    secondButtonTitle: LocaleKeys.Settings.closeButton.rawValue.locale(),
                    completionHandler: {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
                    }
                }) {
                    self.delegate?.handleViewModelOutput(.popVC)
                }
                self.delegate?.handleViewModelOutput(.present(vc: alert))
                
            }))
        models.append(SettingsOption(
            title: LocaleKeys.Settings.darkMode.rawValue.locale(),
            icon: Images.darkMode,
            iconBackgroundColor: Colors.accent.color,
            handler: {
                self.delegate?.handleViewModelOutput(.makeAlertDarkMode)
            }))
        
        models.append(SettingsOption(title: LocaleKeys.Settings.writeMe.rawValue.locale(), icon: Images.email, iconBackgroundColor: Colors.accent.color, handler: {
            self.delegate?.handleViewModelOutput(.sendMail)
        }))
    }
    
    func sendMail() {
        if MFMailComposeViewController.canSendMail() {
            let mailComposeVC = MFMailComposeViewController()
            mailComposeVC.mailComposeDelegate = self
            mailComposeVC.setToRecipients([Constants.Links.email.rawValue])
            mailComposeVC.setSubject(NSLocalizedString(LocaleKeys.Settings.aboutApp.rawValue, comment: "About mail"))
            mailComposeVC.setMessageBody(NSLocalizedString(LocaleKeys.Settings.hello.rawValue, comment: "Hello"), isHTML: false)
            
            self.delegate?.handleViewModelOutput(.present(vc: mailComposeVC))
        } else {
            let alertController = UIAlertController(title: LocaleKeys.Settings.mailTitleError.rawValue.locale(), message: LocaleKeys.Settings.mailMessageError.rawValue.locale(), preferredStyle: .alert)
            let okAction = UIAlertAction(title: LocaleKeys.Settings.okButton.rawValue.locale(), style: .default, handler: nil)
            alertController.addAction(okAction)
            self.delegate?.handleViewModelOutput(.present(vc: alertController))
        }
    }
}
