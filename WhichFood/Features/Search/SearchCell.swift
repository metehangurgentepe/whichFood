//
//  SearchCell.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 6.03.2024.
//

import UIKit

import UIKit

class SearchCell: UICollectionViewCell {
    
    static let identifier = "SearchCell"
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Images.background
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        imageView.layer.cornerRadius = 16
        imageView.backgroundColor = .systemGray6
        return imageView
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = .systemFont(ofSize: 15, weight: .semibold) // Increased font size and weight
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 2
        label.textAlignment = .left
        return label
    }()
    
    let cookTimeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textAlignment = .left
        return label
    }()
    
    let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.systemGray5.cgColor
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(recipe: Recipe) {
        nameLabel.text = recipe.name
        if let url = URL(string: recipe.imageUrl ?? "") {
            imageView.sd_setImage(with: url)
        }
        // Add cooking time with a clock emoji
        cookTimeLabel.text = "🕒 \(recipe.cookTime ?? "N/A")"
    }
    
    private func setupUI() {
        let width = ScreenSize.width
        let padding: CGFloat = 16
        let minimumItemSpacing: CGFloat = 16
        let availableWidth = width - (padding * 2) - (minimumItemSpacing)
        let itemWidth = availableWidth / 2 - 8
        
        contentView.addSubview(containerView)
        containerView.addSubview(imageView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(cookTimeLabel)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        cookTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            imageView.heightAnchor.constraint(equalToConstant: itemWidth),
            
            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            cookTimeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            cookTimeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            cookTimeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            cookTimeLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
    }
}
