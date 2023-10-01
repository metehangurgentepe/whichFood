//
//  RecipeCell.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 15.09.2023.
//

import UIKit

class RecipeCell: UITableViewCell {
    
    let foodName = UILabel()
    let containerView = UIView()
    
    let createdTime = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            
            // ContainerView'ı hücreye ekleyin
            addSubview(containerView)
            containerView.translatesAutoresizingMaskIntoConstraints = false
            containerView.backgroundColor = UIColor.gray.withAlphaComponent(0.2)
            
            // Diğer labelları containerView'a ekleyin
            containerView.addSubview(foodName)
            containerView.addSubview(createdTime)
        
            
            foodName.textColor = .black
            foodName.font = UIFont.preferredFont(forTextStyle: .headline)
            
            createdTime.textColor = .gray
            createdTime.font =  UIFont.preferredFont(forTextStyle: .caption1)
            
            foodName.translatesAutoresizingMaskIntoConstraints = false
            createdTime.translatesAutoresizingMaskIntoConstraints = false
        
            containerView.layer.cornerRadius = 12
            containerView.layer.shadowRadius = 10
            
            NSLayoutConstraint.activate([
                containerView.leadingAnchor.constraint(equalTo: self.leadingAnchor,constant: 30),
                containerView.trailingAnchor.constraint(equalTo: self.trailingAnchor,constant: -30),
                containerView.topAnchor.constraint(equalTo: self.topAnchor,constant: 0),
                containerView.bottomAnchor.constraint(equalTo: self.bottomAnchor,constant: -10)
            ])
//            containerView.anchor(topPadding: 20,leftPadding:20, rightPadding:20, bottomPadding: 20)
        
            // Diğer UILabel'ların constraints'lerini containerView'a göre ayarlayın
            NSLayoutConstraint.activate([
                foodName.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
                foodName.topAnchor.constraint(equalTo: containerView.topAnchor),
                foodName.heightAnchor.constraint(equalToConstant: 30),
                foodName.widthAnchor.constraint(equalToConstant: 300)
            ])
            
            NSLayoutConstraint.activate([
                createdTime.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
                createdTime.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                createdTime.heightAnchor.constraint(equalToConstant: 30),
                createdTime.widthAnchor.constraint(equalToConstant: 300)
            ])
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

}
