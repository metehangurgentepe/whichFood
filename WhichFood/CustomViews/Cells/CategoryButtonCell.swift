//
//  CategoryButtonCell.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 27.02.2024.
//

import UIKit

class CategoryButtonCell: UICollectionViewCell {
   
    private let button = CapsuleButton(type: .system)
    
    static let identifier = "CategoryButtonCell"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func setupUI() {
        addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: topAnchor),
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
    }
    
    
    func configure(title: String) {
        button.setTitle(title, for: .normal)
        button.backgroundColor = Colors.primary.color
        button.setTitleColor(.white, for: .normal)
    }
}
