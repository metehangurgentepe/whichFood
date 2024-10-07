import Foundation
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
        let imageView = SDAnimatedImageView()
        let animatedImage = SDAnimatedImage(named: "loading.gif")
        imageView.image = animatedImage
        
        containerView = UIView(frame: view.bounds)
        view.addSubview(containerView)
        containerView.addSubview(imageView)
        
        containerView.backgroundColor = .systemBackground
        containerView.alpha = 0
        
        UIView.animate(withDuration: 0.25) {
            self.containerView.alpha = 0.8
        }
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 80),
            imageView.widthAnchor.constraint(equalToConstant: 80),
        ])
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
