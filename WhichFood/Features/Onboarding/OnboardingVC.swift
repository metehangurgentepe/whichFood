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
    
    func isAppOpenBefore() {
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
//        navigationItem.rightBarButtonItem = .init(image: .init(systemName: "rectangle"), style: .plain, target: self, action: #selector(presentOnboarding))
    }
}
extension OnboardingVC: UIOnboardingViewControllerDelegate {
    func didFinishOnboarding(onboardingViewController: UIOnboardingViewController) {
        onboardingViewController.modalTransitionStyle = .crossDissolve
        onboardingViewController.dismiss(animated: true) {
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                UserDefaults.standard.set(true,forKey: "isFirstLaunch")
        }
        let homeVC = HomeViewController()
        self.navigationController?.pushViewController(homeVC, animated: true)
    }
}

//#if DEBUG
//struct ViewControllerContainer: UIViewControllerRepresentable {
//    func makeUIViewController(context: Context) -> UINavigationController {
//        return .init(rootViewController: OnboardingVC.init())
//    }
//    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
//}
//
//struct ContentViewController_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {
//            ViewControllerContainer()
//                .preferredColorScheme(.dark)
//        }
//    }
//}
//#endif
