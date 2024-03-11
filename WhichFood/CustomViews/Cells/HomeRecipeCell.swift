//
//  HomeRecipeCell.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 5.03.2024.
//

import UIKit
import SDWebImage

protocol HomeRecipeCellDelegate: AnyObject {
    func deleteRecipe(recipe: Recipe)
    func showError(error: Error)
}

class HomeRecipeCell: UICollectionViewCell {
    static let identifier = "HomeRecipeCell"
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 14)
        label.textColor = .black
        label.lineBreakMode = .byClipping
        label.textAlignment = .right
        return label
    }()
    
    let container: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 15
        view.clipsToBounds = true
        return view
    }()
    
    var favButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(addFavoritesRecipe), for: .touchUpInside)
        return button
    }()
    
    
    
    var longPressGesture: UILongPressGestureRecognizer!
    var delegate: HomeRecipeCellDelegate?
    var recipe: Recipe?
    
    let favImage = SFSymbols.favorites?.withTintColor(Colors.primary.color).withRenderingMode(.alwaysOriginal)
    let selectedFavImage = SFSymbols.selectedFavorites?.withTintColor(Colors.primary.color).withRenderingMode(.alwaysOriginal)
    
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
        
        let confirmAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.delegate?.deleteRecipe(recipe: recipe)
            self?.isHighlighted = false
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
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
            nameLabel.heightAnchor.constraint(equalToConstant: 20),
            nameLabel.widthAnchor.constraint(equalToConstant: itemWidth - 10)
        ])
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor,constant: 5),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5),
            container.heightAnchor.constraint(equalToConstant: 30),
            container.widthAnchor.constraint(equalToConstant: 30)
        ])
        
        NSLayoutConstraint.activate([
            favButton.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            favButton.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
    }
    
    
    func configure(recipe: Recipe) {
        self.recipe = recipe
        
        if let imageUrl = recipe.imageUrl{
            let url = URL(string: imageUrl)
            imageView.sd_setImage(with: url)
        }
        imageView.image = Images.background
        nameLabel.text = recipe.name
        
        checkIsSaved(recipe: recipe)
        setupSubviews()
    }
    
    
    @objc func addFavoritesRecipe() {
        checkIsSaved(recipe: recipe!)
        
        PersistenceManager.isSaved(favorite: recipe!, completion: { result in
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
        PersistenceManager.updateWith(favorite: recipe!, actionType: .add) { error in
            if let error = error {
                self.delegate?.showError(error: error as WFError)
            }
        }
    }
    
    
    func removeFav() {
        PersistenceManager.updateWith(favorite: recipe!, actionType: .remove) { error in
            if let error = error {
                self.delegate?.showError(error: error as WFError)
            }
        }
    }
    
    
    func checkIsSaved(recipe: Recipe) {
        PersistenceManager.isSaved(favorite: recipe, completion: {[weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let success):
                if success {
                    self.favButton.setImage(self.selectedFavImage, for: .normal)
                } else {
                    self.favButton.setImage(self.favImage, for: .normal)
                }
                
            case .failure(let error):
                self.delegate?.showError(error: error as WFError)
            }
        })
    }
}
