//
//  OnboardingVC.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 13.01.2025.
//

import Foundation
import UIKit
import SwiftUI

class OnboardingCoordinator {
    weak var parentViewController: UIViewController?
    private var onboardingViewController: UIViewController?
    
    init(parentViewController: UIViewController) {
        self.parentViewController = parentViewController
    }
    
    func startOnboarding() {
        let onboardingView = OnboardingView { [weak self] in
            self?.navigateToMainTabBar()
        }
        
        let hostingController = UIHostingController(rootView: onboardingView)
        hostingController.modalPresentationStyle = .fullScreen
        self.onboardingViewController = hostingController
        parentViewController?.present(hostingController, animated: true)
    }
    
    private func navigateToMainTabBar() {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else { return }
            
            let mainTabBar = MainTabBarController()
            
            UIView.transition(with: window,
                             duration: 0.3,
                             options: .transitionCrossDissolve,
                             animations: {
                window.rootViewController = mainTabBar
            }) { _ in
                // Dismiss the onboarding view controller after transition
                self.onboardingViewController?.dismiss(animated: false)
            }
        }
}
// MARK: - OnboardingCheckProtocol
protocol OnboardingCheckProtocol: AnyObject {
    func checkAndShowOnboardingIfNeeded()
}

// MARK: - OnboardingCheck Extension
extension OnboardingCheckProtocol where Self: UIViewController {
    func checkAndShowOnboardingIfNeeded() {
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        
//        if !hasCompletedOnboarding {
            let coordinator = OnboardingCoordinator(parentViewController: self)
            coordinator.startOnboarding()
//        }
    }
}

// MARK: - Örnek Kullanım
class OnboardingVC: UIViewController, OnboardingCheckProtocol {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkAndShowOnboardingIfNeeded()
    }
}
