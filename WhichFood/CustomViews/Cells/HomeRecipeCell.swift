//
//  HomeRecipeCell.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 5.03.2024.
//

import UIKit
import SDWebImage

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
        label.font = .preferredFont(forTextStyle: .headline).withSize(12)
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
    
    var recipe: Recipe?
    
    let favImage = SFSymbols.favorites?.withTintColor(Colors.primary.color).withRenderingMode(.alwaysOriginal)
    let selectedFavImage = SFSymbols.selectedFavorites?.withTintColor(Colors.primary.color).withRenderingMode(.alwaysOriginal)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }
    
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
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
                
            case .failure(let failure):
                break
            }
        })
    }
    
    
    func addFav() {
        PersistenceManager.updateWith(favorite: recipe!, actionType: .add) { error in
        }
    }
    
    
    func removeFav() {
        PersistenceManager.updateWith(favorite: recipe!, actionType: .remove) { error in
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
                
            case .failure(let failure):
                break
            }
        })
    }
}
