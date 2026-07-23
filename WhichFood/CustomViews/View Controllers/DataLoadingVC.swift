import Foundation
import Lottie
import UIKit
import SDWebImage

class DataLoadingVC: UIViewController {
    var containerView: UIView!
    var alertIsShown = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func showAlert(title: String, message: String, buttonTitle: String, secondButtonTitle: String) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: buttonTitle, style: .default) { _ in
            self.alertIsShown = false
        }
        let cancelAction = UIAlertAction(title: secondButtonTitle, style: .cancel) { _ in
            self.alertIsShown = false
        }
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        return alertController
    }
    
    func showLoadingView() {
        containerView = UIView(frame: view.bounds)
        view.addSubview(containerView)
        
        containerView.backgroundColor = .systemBackground
        containerView.alpha = 0
        
        UIView.animate(withDuration: 0.25) {
            self.containerView.alpha = 0.8
        }
        
        let activityIndicator = UIActivityIndicatorView(style: .large)
        containerView.addSubview(activityIndicator)
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            activityIndicator.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor)
        ])
        
        activityIndicator.startAnimating()
    }
    
    func customLoadingView() {
        let animationView = LottieAnimationView()
        // Assuming your Lottie JSON file is named "loading"
        animationView.animation = LottieAnimation.named("loading")
        animationView.loopMode = .loop
        
        containerView = UIView(frame: view.bounds)
        view.addSubview(containerView)
        containerView.addSubview(animationView)
        
        containerView.backgroundColor = .systemBackground
        containerView.alpha = 0
        
        UIView.animate(withDuration: 0.25) {
            self.containerView.alpha = 0.8
        }
        
        animationView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            animationView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            animationView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            animationView.heightAnchor.constraint(equalToConstant: 150),
            animationView.widthAnchor.constraint(equalToConstant: 150)
        ])
        
        animationView.play()
    }
    
    func detailCustomLoadingView() {
        let animationView = LottieAnimationView()
        // Assuming your Lottie JSON file is named "loading"
        animationView.animation = LottieAnimation.named("feature_2")
        animationView.loopMode = .loop
        
        containerView = UIView(frame: view.bounds)
        view.addSubview(containerView)
        containerView.addSubview(animationView)
        
        containerView.backgroundColor = .systemBackground
        containerView.alpha = 0
        
        UIView.animate(withDuration: 0.25) {
            self.containerView.alpha = 0.8
        }
        
        animationView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            animationView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            animationView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            animationView.heightAnchor.constraint(equalToConstant: 150),
            animationView.widthAnchor.constraint(equalToConstant: 150)
        ])
        
        animationView.play()
    }
    
    func dismissLoadingView() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.25, animations: {
                self.containerView?.alpha = 0
            }) { _ in
                self.containerView?.removeFromSuperview()
                self.containerView = nil
            }
        }
    }
    
    func showEmptyStateView(with message: String, in view: UIView) {
        let emptyStateView = EmptyStateView(message: message)
        emptyStateView.frame = view.bounds
        view.addSubview(emptyStateView)
    }

    func showEmptyStateView(with title: String, subtitle: String, in view: UIView) {
        let emptyStateView = EmptyStateView(title: title, subtitle: subtitle)
        emptyStateView.frame = view.bounds
        view.addSubview(emptyStateView)
    }
    
    func dismissEmptyStateView(in view: UIView) {
        for subview in view.subviews {
            if let emptyStateView = subview as? EmptyStateView {
                emptyStateView.removeFromSuperview()
            }
        }
    }
    
    func hideEmptyStateView(in view: UIView) {
        for subview in view.subviews {
            if let emptyStateView = subview as? EmptyStateView {
                emptyStateView.removeFromSuperview()
            }
        }
    }
}
