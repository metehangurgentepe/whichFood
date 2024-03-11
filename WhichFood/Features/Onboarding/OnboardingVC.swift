//
//  OnboardingVC.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 25.10.2023.
//

import UIKit
import UIOnboarding
import SwiftUI

class OnboardingVC: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
        presentOnboarding()
    }
    
    
    @objc private func presentOnboarding() {
        let onboardingController: UIOnboardingViewController = .init(withConfiguration: .setUp())
        onboardingController.delegate = self
        navigationController?.present(onboardingController, animated: false)
    }
}


extension OnboardingVC {
    private func setUp() {
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.tintColor = .init(named: "camou")
    }
}


extension OnboardingVC: UIOnboardingViewControllerDelegate {
    func didFinishOnboarding(onboardingViewController: UIOnboardingViewController) {
        onboardingViewController.modalTransitionStyle = .crossDissolve
        onboardingViewController.dismiss(animated: true) {
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                UserDefaults.standard.set(true,forKey: "isFirstLaunch")
        }
        
        let tabbar = MainTabBarController()
        tabbar.modalPresentationStyle = .fullScreen
        self.present(tabbar, animated: true)
    }
}
