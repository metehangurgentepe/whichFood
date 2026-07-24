//
//  HomeRecipeCell.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 5.03.2024.
//

import UIKit
import SDWebImage

class PassThroughView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        if hitView == self {
            return nil
        }
        return hitView
    }
}

protocol HomeRecipeCellDelegate: AnyObject {
    func deleteRecipe(recipe: Recipe)
    func showError(error: Error)
    func favoriteStatusChanged(recipe: Recipe)
}

class HomeRecipeCell: UICollectionViewCell {
    static let identifier = "HomeRecipeCell"
    
    var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        imageView.alpha = 1.0
        return imageView
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 14)
        label.textColor = .white
        label.textAlignment = .right
        label.numberOfLines = 2
        return label
    }()
    
    let container: UIView = {
        let view = PassThroughView()
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
        return view
    }()
    
    var favButton: UIButton = {
        let button = UIButton()
        if #available(iOS 26.0, *) {
            button.configuration = .glass()
        }
        button.addTarget(self, action: #selector(addFavoritesRecipe), for: .touchUpInside)
        button.isUserInteractionEnabled = true
        return button
    }()

    // Bottom gradient for text readability
    private let bottomGradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        let topColor = UIColor.clear.cgColor
        let bottomColor = UIColor.black.withAlphaComponent(0.7).cgColor
        layer.colors = [topColor, bottomColor]
        layer.locations = [0.0, 1.0]
        return layer
    }()


    var longPressGesture: UILongPressGestureRecognizer!
    var delegate: HomeRecipeCellDelegate?
    var recipe: Recipe?
    
    let favImage = SFSymbols.favorites?.withTintColor(Colors.primary.color).withRenderingMode(.alwaysOriginal).withConfiguration(UIImage.SymbolConfiguration(pointSize: 16, weight: .medium))
    let selectedFavImage = SFSymbols.selectedFavorites?.withTintColor(Colors.primary.color).withRenderingMode(.alwaysOriginal).withConfiguration(UIImage.SymbolConfiguration(pointSize: 16, weight: .medium))
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                self.contentView.alpha = 0.7
            } else {
                self.contentView.alpha = 1.0
            }
        }
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
        setupLongPressGesture()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        bottomGradientLayer.frame = imageView.bounds
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Cancel any pending image download
        imageView.sd_cancelCurrentImageLoad()
        
        // Önemli: Temel bir placeholder görüntüsünü koruyun
        imageView.image = Images.background
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
    }
    
    
    private func setupLongPressGesture() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        addGestureRecognizer(longPressGesture)
    }
    
    
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            isHighlighted = true
        case .ended:
            showDeleteConfirmationAlert()
        default:
            break
        }
    }
    
    
    func showDeleteConfirmationAlert() {
        guard let recipe = self.recipe else { return }
        
        let alertController = UIAlertController(
            title: LocaleKeys.Home.deleteRecipe.rawValue.locale(),
            message: "\(LocaleKeys.Home.sureDelete.rawValue.locale()) \(recipe.name)?",
            preferredStyle: .alert
        )
        
        let confirmAction = UIAlertAction(title: LocaleKeys.Error.delete.rawValue.locale(), style: .destructive) { [weak self] _ in
            self?.delegate?.deleteRecipe(recipe: recipe)
            self?.isHighlighted = false
        }
        
        let cancelAction = UIAlertAction(title: LocaleKeys.Error.cancel.rawValue.locale(), style: .cancel, handler: nil)
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        if let topViewController = UIApplication.shared.keyWindow?.rootViewController?.topmostViewController {
            topViewController.present(alertController, animated: true, completion: nil)
        }
    }
    
    
    private func setupSubviews() {
        let width = ScreenSize.width
        let padding: CGFloat = 20
        let minimumItemSpacing: CGFloat = 10
        let availableWidth = width - (padding * 2) - (minimumItemSpacing)
        let itemWidth =  availableWidth / 2
        
        addSubview(imageView)
        addSubview(nameLabel)
        addSubview(container)
        container.addSubview(favButton)

        // Fallback background for iOS < 15 (when glass configuration is not available)
        if #unavailable(iOS 26.0) {
            container.backgroundColor = .white
        }

        // Add bottom gradient for text readability
        imageView.layer.addSublayer(bottomGradientLayer)
        
        
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        favButton.translatesAutoresizingMaskIntoConstraints = false
        container.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalToConstant: itemWidth),
            imageView.widthAnchor.constraint(equalToConstant: itemWidth),
        ])
        
        NSLayoutConstraint.activate([
            nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            nameLabel.heightAnchor.constraint(equalToConstant: 40),
            nameLabel.widthAnchor.constraint(equalToConstant: itemWidth - 10)
        ])
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor,constant: 8),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            container.heightAnchor.constraint(equalToConstant: 40),
            container.widthAnchor.constraint(equalToConstant: 40)
        ])
        
        NSLayoutConstraint.activate([
            favButton.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            favButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            favButton.widthAnchor.constraint(equalToConstant: 32),
            favButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }



    func configure(recipe: Recipe) {
        self.recipe = recipe
        nameLabel.text = recipe.name
        
        // Reset image state
        imageView.image = Images.background
        
        // Sadece URL varsa görüntü yükleme işlemi yap
        if let imageUrl = recipe.imageUrl, let url = URL(string: imageUrl) {
            // Önemli: kf.setImage yerine sd_setImage kullan (SDWebImage)
            imageView.sd_setImage(
                with: url,
                placeholderImage: Images.background,
                options: [.highPriority, .retryFailed],
                completed: { [weak self] (image, error, cacheType, url) in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("Image loading error: \(error.localizedDescription)")
                        self.imageView.image = Images.background
                    }
                }
            )
        }
        
        checkIsSaved(recipe: recipe)
    }
    
    
    @objc func addFavoritesRecipe() {
        guard let recipe else { return }

        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        PersistenceManager.isSaved(recipe: recipe.toRecipeResponseModel(), completion: { result in
            switch result {
            case .success(let success):
                if success {
                    self.removeFav()
                } else {
                    self.addFav()
                }

            case .failure(let error):
                self.delegate?.showError(error: error)
            }
        })
    }
    
    
    func addFav() {
        guard let recipe else { return }
        PersistenceManager.updateWith(favorite: recipe.toRecipeResponseModel(), actionType: .add) { error in
            if let error = error {
                self.delegate?.showError(error: error as WFError)
            } else {
                DispatchQueue.main.async {
                    self.delegate?.favoriteStatusChanged(recipe: recipe)
                }
            }
        }
    }
    
    
    func removeFav() {
        guard let recipe else { return }
        PersistenceManager.updateWith(favorite: recipe.toRecipeResponseModel(), actionType: .remove) { error in
            if let error = error {
                self.delegate?.showError(error: error as WFError)
            } else {
                DispatchQueue.main.async {
                    self.delegate?.favoriteStatusChanged(recipe: recipe)
                }
            }
        }
    }
    
    
    func checkIsSaved(recipe: Recipe) {
        PersistenceManager.isSaved(recipe: recipe.toRecipeResponseModel(), completion: {[weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let success):
                    if #available(iOS 26.0, *), self.favButton.configuration != nil {
                        // For glass configuration, update the image through configuration
                        var config = self.favButton.configuration ?? .glass()
                        config.image = success ? self.selectedFavImage : self.favImage
                        self.favButton.configuration = config
                    } else {
                        // For regular button, set image directly
                        if success {
                            self.favButton.setImage(self.selectedFavImage, for: .normal)
                        } else {
                            self.favButton.setImage(self.favImage, for: .normal)
                        }
                    }

                case .failure(let error):
                    self.delegate?.showError(error: error as WFError)
                }
            }
        })
    }
}
