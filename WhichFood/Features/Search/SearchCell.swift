//
//  SearchCell.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 6.03.2024.
//

import UIKit

class SearchCell: UICollectionViewCell {
    
    static let identifier = "SearchCell"
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Images.background
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        return imageView
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = .preferredFont(forTextStyle: .headline).withSize(12)
        label.lineBreakMode = .byTruncatingTail
        return label
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
    }
    
    private func setupUI() {
        let width = ScreenSize.width
        let padding: CGFloat = 20
        let minimumItemSpacing: CGFloat = 10
        let availableWidth = width - (padding * 2) - (minimumItemSpacing * 2)
        let itemWidth =  availableWidth / 3
        
        addSubview(imageView)
        addSubview(nameLabel)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,constant: -5),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalToConstant: itemWidth),
            imageView.widthAnchor.constraint(equalToConstant: itemWidth),
            
            
            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -2),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            nameLabel.widthAnchor.constraint(equalToConstant: itemWidth),
            nameLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
}
