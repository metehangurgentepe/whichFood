import UIKit

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