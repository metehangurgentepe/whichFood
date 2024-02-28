//
//  RecipeCell.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 15.09.2023.
//

import UIKit
import SkeletonView

class RecipeCell: UITableViewCell {
    lazy var foodName = UILabel()
    lazy var createdTime = UILabel()
    lazy var containerView = UIView()
    lazy var ingredientLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        createdTime.translatesAutoresizingMaskIntoConstraints = false
        foodName.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        ingredientLabel.translatesAutoresizingMaskIntoConstraints = false

       
        addSubview(containerView)
        containerView.addSubview(foodName)
        containerView.addSubview(createdTime)
        containerView.addSubview(ingredientLabel)
        
        foodName.numberOfLines = 1
        
        foodName.font = UIFont.preferredFont(forTextStyle: .headline)
        createdTime.font =  UIFont.preferredFont(forTextStyle: .caption2)
        ingredientLabel.font =  UIFont.preferredFont(forTextStyle: .caption1).withSize(14)
        
        containerView.layer.cornerRadius = 12
        containerView.layer.shadowRadius = 10
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: self.leadingAnchor,constant: 20),
            containerView.trailingAnchor.constraint(equalTo: self.trailingAnchor,constant: -20),
            containerView.topAnchor.constraint(equalTo: self.topAnchor,constant: 7),
            containerView.bottomAnchor.constraint(equalTo: self.bottomAnchor,constant: -7),
        ])
        
        NSLayoutConstraint.activate([
            foodName.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            foodName.topAnchor.constraint(equalTo: containerView.topAnchor,constant: 4),
//            foodName.heightAnchor.constraint(equalToConstant: 30),
            foodName.widthAnchor.constraint(equalToConstant: 300)
        ])
        
        NSLayoutConstraint.activate([
            ingredientLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            ingredientLabel.bottomAnchor.constraint(equalTo: containerView.centerYAnchor,constant: 10),
            ingredientLabel.heightAnchor.constraint(equalToConstant: 20),
            ingredientLabel.widthAnchor.constraint(equalToConstant: 300)
        ])
        
        NSLayoutConstraint.activate([
            createdTime.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            createdTime.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            createdTime.heightAnchor.constraint(equalToConstant: 20),
            createdTime.widthAnchor.constraint(equalToConstant: 300)
        ])
        updatetColorsWhenTraitColor()
//        showSkeleton()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updatetColorsWhenTraitColor()
    }
    
    private func updatetColorsWhenTraitColor() {
        if traitCollection.userInterfaceStyle == .dark {
            foodName.textColor = .white
            containerView.backgroundColor = .secondarySystemBackground
            createdTime.textColor = .gray
        } else {
            foodName.textColor = .black
            containerView.backgroundColor = .secondarySystemFill
            createdTime.textColor = .gray
        }
    }
}
