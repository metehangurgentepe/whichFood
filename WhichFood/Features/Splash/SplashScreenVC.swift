//
//  SplashScreenVC.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 31.10.2023.
//

import UIKit
import RevenueCat
import SDWebImage
import SwiftUI

protocol SplashViewDelegate: AnyObject {
    func navigate(vc: UIViewController)
    func navigateToOnboarding()
    func navigateToMainTabBar(isPremium: Bool, vendorID: String)
}

class SplashScreenVC: UIViewController {
    private lazy var icon: UIImageView = {
        let image = Images.recipe?.resize(toSize: .init(width: 300, height: 300))
        let view = UIImageView(image: image)
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "WhichFood"
        label.font = .systemFont(ofSize: 40, weight: .bold)
        if traitCollection.userInterfaceStyle == .dark {
            label.textColor = .white
        } else {
            label.textColor = .black
        }
        label.textAlignment = .center
        return label
    }()
    
    var viewModel: SplashViewModelProtocol! = SplashViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPhoto()
        
        viewModel.delegate = self
        Task{
            await viewModel.getKeychain()
            viewModel.signIn()
        }
        configure()
        self.view.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
    }
    
    
    func configure() {
        view.backgroundColor = .systemBackground
        setupTitleLabel()
    }
    
    
    func setupTitleLabel() {
        let letters = Array("WhichFood")
        var letterLabels: [UILabel] = []
        let fixedSpacing: CGFloat = 13.0
        
        var totalWidth: CGFloat = 0.0
        
        for (index, letter) in letters.enumerated() {
            let label = UILabel()
            label.text = String(letter)
            label.font = titleLabel.font
            label.textAlignment = .center
            if traitCollection.userInterfaceStyle == .dark {
                label.textColor = .orange
            } else{
                label.textColor = .black
            }
            
            label.translatesAutoresizingMaskIntoConstraints = false
            letterLabels.append(label)
            
            let letterWidth = label.intrinsicContentSize.width
            totalWidth += letterWidth
            
            if index < letters.count - 1 {
                totalWidth += fixedSpacing
            }
        }
        
        let initialOffset: CGFloat = (view.bounds.width - totalWidth + fixedSpacing) / 2
        
        
        for (index, letterLabel) in letterLabels.enumerated() {
            view.addSubview(letterLabel)
            
            NSLayoutConstraint.activate([
                letterLabel.leadingAnchor.constraint(
                    equalTo: (index == 0) ? view.leadingAnchor : letterLabels[index - 1].trailingAnchor,
                    constant: (index == 0) ? initialOffset : fixedSpacing
                ),
                letterLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 150),
            ])
            
            letterLabel.transform = CGAffineTransform(translationX: 0, y: -20)
            
            let delay = Double(index) * 0.1
            
            UIView.animate(withDuration: 2, delay: delay, options: .curveEaseInOut, animations: {
                letterLabel.transform = .identity
            }, completion: { _ in
                
            })
        }
    }
    
    
    func setupPhoto() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            if let imagePath = Bundle.main.path(forResource: "splash_logo", ofType: "png") {
                icon.image = UIImage(contentsOfFile: imagePath)!.resize(toSize: .init(width: 200, height: 200))
            }

            view.addSubview(icon)
            self.icon.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                self.icon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                self.icon.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),
            ])
        }
    }
}

extension SplashScreenVC: SplashViewDelegate {
    
    func navigateToOnboarding() {
        let onboardingView = OnboardingView { [weak self] in
            Task { [weak self] in
                let isPremium = await self?.viewModel.checkPremiumStatus() ?? false
                await MainActor.run {
                    self?.navigateToMainTabBar(isPremium: isPremium, vendorID: "")
                }
            }
        }

        let hostingController = UIHostingController(rootView: onboardingView)
        hostingController.modalPresentationStyle = .fullScreen

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.present(hostingController, animated: true)
        }
    }
    
    
    func navigate(vc: UIViewController) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true)
        }
    }
    
    func navigateToMainTabBar(isPremium: Bool, vendorID: String) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }

        let rootController = WFMainTabBarController(isPremium: isPremium)

        UIView.transition(with: window,
                          duration: 0.3,
                          options: .transitionCrossDissolve,
                          animations: {
            window.rootViewController = rootController
        }, completion: { _ in
            // Apply the saved light/dark preference to the new root window
            WFAppearanceManager.apply()
        })
    }
}
