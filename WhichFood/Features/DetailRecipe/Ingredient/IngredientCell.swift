//
//  IngredientController.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 19.09.2024.
//

import UIKit

class IngredientCell: UICollectionViewCell {
    static let identifier = "IngredientCell"
    
    private let ingredientsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.distribution = .fillProportionally
        return stack
    }()
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = true
        return scrollView
    }()
    
    private var recipe: RecipeResponseModel?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .systemBackground
        
        contentView.addSubview(scrollView)
        scrollView.addSubview(ingredientsStackView)
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        ingredientsStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
            make.width.equalTo(scrollView.frameLayoutGuide.snp.width).offset(-32)
        }
    }
    
    func configure(recipe: RecipeResponseModel) {
        self.recipe = recipe
        ingredientsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        recipe.ingredients.forEach { ingredient in
            let ingredientView = createIngredientView(ingredient: ingredient)
            ingredientsStackView.addArrangedSubview(ingredientView)
        }
    }
    
    private func createIngredientView(ingredient: String) -> UIView {
        let container = UIView()
        
        let verticalLine = UIView()
        verticalLine.backgroundColor = Colors.containerBackgroundColor.color.withAlphaComponent(0.3)
        
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 12
        
        let bulletPoint = UIView()
        bulletPoint.backgroundColor = Colors.primary.color
        bulletPoint.layer.cornerRadius = 4
        
        let label = UILabel()
        label.text = ingredient
        label.font = .preferredFont(forTextStyle: .headline)
        label.numberOfLines = 0
        label.textColor = .label
        
        container.addSubview(verticalLine)
        container.addSubview(bulletPoint)
        container.addSubview(label)
        
        verticalLine.snp.makeConstraints { make in
            make.centerX.equalTo(bulletPoint)
            make.top.equalTo(container.snp.bottom)
            make.height.equalTo(10)
            make.width.equalTo(2)
        }
        
        bulletPoint.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(8)
        }
        
        label.snp.makeConstraints { make in
            make.leading.equalTo(bulletPoint.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.top.bottom.equalToSuperview().inset(12)
        }
        
        if ingredientsStackView.arrangedSubviews.count + 1 == recipe?.ingredients.count {
            verticalLine.isHidden = true
        }
        
        return container
    }
}
