//
//  IngredientController.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 19.09.2024.
//

import UIKit

class IngredientCell: UICollectionViewCell {
    static let identifier = "IngredientCell"
    
    let recipeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .label
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()
    
    let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = true
        return scrollView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .systemBackground
        
        contentView.addSubview(scrollView)
        
        scrollView.addSubview(recipeLabel)
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }
        
        recipeLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(8)
            make.width.equalTo(scrollView.frameLayoutGuide.snp.width).offset(-16)
        }
    }
    
    override func layoutSubviews() {
        contentView.layoutIfNeeded()
        scrollView.contentSize = recipeLabel.intrinsicContentSize
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(recipe: RecipeResponseModel) {
        recipeLabel.text = recipe.ingredients.joined(separator: "\n")
        
        let contentSize = recipeLabel.sizeThatFits(CGSize(width: scrollView.frame.width, height: .greatestFiniteMagnitude))
        scrollView.contentSize = CGSize(width: scrollView.frame.width, height: contentSize.height + 10)
        
        recipeLabel.setNeedsLayout()
        recipeLabel.layoutIfNeeded()
    }
}
