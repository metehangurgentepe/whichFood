//
//  SplashScreenVC.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 31.10.2023.
//

import UIKit
import RevenueCat

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
        let image = Images.recipe
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
        guard let openSansFont = UIFont(name: "OpenSans-Regular", size: 20) else {
                // Handle the case where the font couldn't be loaded
                return
        }
        
        let letters = Array("WhichFood")
        var letterLabels: [UILabel] = []
        let fixedSpacing: CGFloat = 13.0  // Fixed spacing between letters

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
//            label.textColor = titleLabel.textColor
            label.translatesAutoresizingMaskIntoConstraints = false
            letterLabels.append(label)

            // Calculate the width of the letter and update the total width
            let letterWidth = label.intrinsicContentSize.width
            totalWidth += letterWidth

            // Add fixed spacing for all letters except the last one
            if index < letters.count - 1 {
                totalWidth += fixedSpacing
            }
        }

        // Adjust the initial offset for symmetry (considering 'W' and 'D')
        let initialOffset: CGFloat = (view.bounds.width - totalWidth + fixedSpacing) / 2

        // Add letter labels to the view with fixed spacing
        for (index, letterLabel) in letterLabels.enumerated() {
            view.addSubview(letterLabel)

            NSLayoutConstraint.activate([
                letterLabel.leadingAnchor.constraint(
                    equalTo: (index == 0) ? view.leadingAnchor : letterLabels[index - 1].trailingAnchor,
                    constant: (index == 0) ? initialOffset : fixedSpacing
                ),
                letterLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 150),
            ])

            // Set initial transform for rising effect
            letterLabel.transform = CGAffineTransform(translationX: 0, y: -20)

            // Calculate delay for each letter
            let delay = Double(index) * 0.1

            // Animate rising and falling
            UIView.animate(withDuration: 0.5, delay: delay, options: .curveEaseInOut, animations: {
                letterLabel.transform = .identity
            }, completion: { _ in
                // Add completion block if needed
            })
        }
    }
    
    func setupPhoto() {
        let size = CGSize(width: 300, height: 300)
        icon.image = Images.recipe!.resize(toSize: size)
        view.addSubview(icon)
        
        icon.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: view.centerYAnchor,constant: -30),
        ])
        rotatePhoto()
    }
    
    func rotatePhoto() {
        // Döndürme animasyonu için CGAffineTransform kullanılır
        let rotationTransform = CGAffineTransform(rotationAngle: .pi) // 180 derece döndürme
        
        UIView.animate(withDuration: 2.0, animations: {
            // Animasyon bloğunda döndürme transform'u uygulanır
            self.icon.transform = rotationTransform
        }) { (completed) in
//            // Animasyon tamamlandığında burada ek işlemler yapabilirsiniz
//            // Örneğin, orijinal konumuna geri döndürmek için:
//            UIView.animate(withDuration: 0.0, animations: {
//                self.icon.transform = .identity // Orijinal transform'a geri döndürme
//            })
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
        let vc = OnboardingVC()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.navigationController?.pushViewController(vc, animated: true)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.navigationController?.viewControllers.remove(at: 0)
        }
    }
    
    func navigate(vc: UIViewController){
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
               vc.modalPresentationStyle = .fullScreen
               self.present(vc, animated: true)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.navigationController?.viewControllers.remove(at: 0)
        }
    }
}


public extension UIColor {
    var isLight: Bool {
        var white: CGFloat = 0
        getWhite(&white, alpha: nil)
        return white > 0.5
    }
}