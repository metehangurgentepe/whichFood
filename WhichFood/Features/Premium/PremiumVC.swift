//
//  PremiumVC.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 27.09.2023.
//

import UIKit
import RevenueCat
import SwiftUI


class PremiumVC: UIViewController {
    weak var coordinator: PremiumCoordinator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPaywallView()
    }
    
    private func setupPaywallView() {
        let paywallView = SubscriptionView()
        
        let hostingController = UIHostingController(rootView: paywallView)
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

protocol PremiumCoordinator: AnyObject {
    func start()
    func dismiss()
}

class DefaultPremiumCoordinator: PremiumCoordinator {
    private let navigationController: UINavigationController
    private var premiumVC: PremiumVC?
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let vc = PremiumVC()
        vc.coordinator = self
        premiumVC = vc
        navigationController.present(vc, animated: true)
    }
    
    func dismiss() {
        premiumVC?.dismiss(animated: true)
    }
}
