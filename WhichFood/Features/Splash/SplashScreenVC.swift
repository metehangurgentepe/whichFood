//
//  SplashScreenVC.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 31.10.2023.
//

import UIKit
import RevenueCat
import SDWebImage

protocol SplashViewDelegate: AnyObject {
    func showError(_ error: Error)
    func navigate(vc: UIViewController)
    func navigateToOnboarding()
}

class SplashScreenVC: UIViewController, SplashViewDelegate {
    private lazy var errorLabel : UILabel = {
        let label = UILabel()
        label.textColor = .red
        label.isHidden = true
        label.font = .preferredFont(forTextStyle: .largeTitle)
        return label
    }()
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
        setupErrorLabel()
        setupPhoto()
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
            
            UIView.animate(withDuration: 0.5, delay: delay, options: .curveEaseInOut, animations: {
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
            
            self.rotatePhoto()
        }
    }
    
    func rotatePhoto() {
        let rotationTransform = CGAffineTransform(rotationAngle: .pi)
        
        UIView.animate(withDuration: 2.0, animations: {
            self.icon.transform = rotationTransform
        }) { (completed) in
            self.icon.transform = .identity
        }
    }
    
    
    func setupErrorLabel() {
        view.addSubview(errorLabel)
        
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            errorLabel.widthAnchor.constraint(equalToConstant: view.bounds.width - 100),
            errorLabel.widthAnchor.constraint(equalToConstant: 200),
        ])
    }
    
    
    func showError(_ error: Error){
        self.errorLabel.isHidden = false
        self.errorLabel.text = error.localizedDescription
    }
    
    
    func navigateToOnboarding() {
        let vc = OnboardingViewController()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.navigationController?.pushViewController(vc, animated: true)
            self.navigationController?.setNavigationBarHidden(true, animated: true)
        }
    }
    
    
    func navigate(vc: UIViewController) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self = self else { return }
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
            self?.navigationController?.viewControllers.remove(at: 0)
        }
    }
}
