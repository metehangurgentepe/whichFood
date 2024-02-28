//
//  CustomCell.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 12.09.2023.
//

import UIKit

class CustomCell: UITableViewCell {
    let foodName = UILabel()
    var checkboxImageView = UIImageView()
    
    func configure(with ingredient: Ingredient) {
        foodName.text = ingredient.name
        if ingredient.isSelected {
            checkboxImageView.image = UIImage(named: "checkmark.square.fill")
        } else {
            checkboxImageView.image = UIImage(named: "rectangle")
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubview(foodName)
        addSubview(checkboxImageView)
        addSubview(checkboxImageView)
        
        foodName.translatesAutoresizingMaskIntoConstraints = false
        checkboxImageView.translatesAutoresizingMaskIntoConstraints = false
    
        NSLayoutConstraint.activate([
            checkboxImageView.trailingAnchor.constraint(equalTo: self.trailingAnchor,constant: -16),
            checkboxImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            checkboxImageView.heightAnchor.constraint(equalToConstant: 30),
            checkboxImageView.widthAnchor.constraint(equalToConstant: 30)
        ])
                
        NSLayoutConstraint.activate([
            foodName.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            foodName.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            foodName.heightAnchor.constraint(equalToConstant: 30),
            foodName.widthAnchor.constraint(equalToConstant: 120)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
   
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
