//
//  IngredientController.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 19.09.2024.
//

import UIKit

class IngredientDetailCell: UICollectionViewCell {
    static let identifier = "IngredientDetailCell"
    
    let textView: UITextView = {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 14)
        textView.textColor = .label
        textView.isEditable = false
        return textView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .systemBackground
        contentView.addSubview(textView)
    }
    
    override func layoutSubviews() {
        textView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(recipe: Recipe) {
        textView.text = recipe.recipe?.joined(separator: "\n")
        contentView.layoutIfNeeded()
    }
}
