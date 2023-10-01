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
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubview(foodName)
        addSubview(checkboxImageView)
        
        foodName.translatesAutoresizingMaskIntoConstraints = false
        
        checkboxImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(checkboxImageView)

        NSLayoutConstraint.activate([
            checkboxImageView.trailingAnchor.constraint(equalTo: self.trailingAnchor,constant: -16),
            checkboxImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            checkboxImageView.heightAnchor.constraint(equalToConstant: 30),
            checkboxImageView.widthAnchor.constraint(equalToConstant: 30)
        ])
                
        // UILabel için constraints
        NSLayoutConstraint.activate([
            foodName.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16), // Sola 16 birim mesafe
            foodName.centerYAnchor.constraint(equalTo: self.centerYAnchor), // Dikey hizalama
            foodName.heightAnchor.constraint(equalToConstant: 30), // Yükseklik sınırlaması
            foodName.widthAnchor.constraint(equalToConstant: 120) // Genişlik sınırlaması
        ])

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateCheckbox(_ isSelected: Bool) {
        if isSelected {
            checkboxImageView.image = UIImage(systemName: "checkmark.square.fill")
        } else {
            checkboxImageView.image = UIImage(systemName: "rectangle")
        }
    }
}
