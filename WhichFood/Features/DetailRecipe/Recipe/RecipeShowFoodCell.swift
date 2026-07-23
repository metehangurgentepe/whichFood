//
//  RecipeShowFoodCell.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 19.09.2024.
//

import UIKit

class RecipeShowFoodCell: UICollectionViewCell {
    static let identifier = "RecipeShowFoodCell"
    
    private let stepsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.distribution = .fill
        stack.alignment = .fill
        return stack
    }()
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = true
        return scrollView
    }()
    
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
        scrollView.addSubview(stepsStackView)
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        stepsStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
            make.width.equalTo(scrollView.frameLayoutGuide.snp.width).offset(-32)
        }
    }
    
    func configure(recipe: RecipeResponseModel) {
        stepsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        recipe.recipe.enumerated().forEach { index, step in
            let stepContainer = createStepContainer(step: step, number: index + 1, isLast: index == recipe.recipe.count - 1)
            stepsStackView.addArrangedSubview(stepContainer)
        }
    }
    
    private func createStepContainer(step: String, number: Int, isLast: Bool) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let stepContentView = UIView()
        stepContentView.backgroundColor = .secondarySystemBackground
        stepContentView.layer.cornerRadius = 12
        stepContentView.translatesAutoresizingMaskIntoConstraints = false
        
        let numberLabel = UILabel()
        numberLabel.text = "\(number)"
        numberLabel.font = .systemFont(ofSize: 16, weight: .bold)
        numberLabel.textColor = Colors.primary.color
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let stepLabel = UILabel()
        stepLabel.text = step
        stepLabel.font = .preferredFont(forTextStyle: .headline)
        stepLabel.numberOfLines = 0
        stepLabel.textColor = .label
        stepLabel.lineBreakMode = .byWordWrapping
        stepLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let verticalLine = UIView()
        verticalLine.backgroundColor = Colors.containerBackgroundColor.color
        verticalLine.translatesAutoresizingMaskIntoConstraints = false
        verticalLine.isHidden = isLast
        
        // View hiyerarşisi
        containerView.addSubview(stepContentView)
        stepContentView.addSubview(numberLabel)
        stepContentView.addSubview(stepLabel)
        containerView.addSubview(verticalLine)
        
        // Number içeriğinin merkezini bulmak için stack kullanımı
        let numberContainer = UIStackView(arrangedSubviews: [numberLabel])
        numberContainer.translatesAutoresizingMaskIntoConstraints = false
        numberContainer.alignment = .center
        stepContentView.addSubview(numberContainer)
        
        NSLayoutConstraint.activate([
            // Step content view
            stepContentView.topAnchor.constraint(equalTo: containerView.topAnchor),
            stepContentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            stepContentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            // Number container
            numberContainer.leadingAnchor.constraint(equalTo: stepContentView.leadingAnchor, constant: 12),
            numberContainer.topAnchor.constraint(equalTo: stepContentView.topAnchor, constant: 12),
            numberContainer.widthAnchor.constraint(equalToConstant: 24),
            
            // Step label
            stepLabel.topAnchor.constraint(equalTo: stepContentView.topAnchor, constant: 12),
            stepLabel.leadingAnchor.constraint(equalTo: numberContainer.trailingAnchor, constant: 8),
            stepLabel.trailingAnchor.constraint(equalTo: stepContentView.trailingAnchor, constant: -12),
            stepLabel.bottomAnchor.constraint(equalTo: stepContentView.bottomAnchor, constant: -12),
            
            // Vertical line - numberContainer'ın leading'ini baz alıyoruz ve offset ekliyoruz
            verticalLine.leadingAnchor.constraint(equalTo: stepContentView.leadingAnchor, constant: 23),  // 12 (container leading) + 11 (line konumu için offset)
            verticalLine.topAnchor.constraint(equalTo: stepContentView.bottomAnchor),
            verticalLine.widthAnchor.constraint(equalToConstant: 2),
            verticalLine.heightAnchor.constraint(equalToConstant: 24),
            verticalLine.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            // Container bottom anchor
            containerView.bottomAnchor.constraint(equalTo: isLast ? stepContentView.bottomAnchor : verticalLine.bottomAnchor)
        ])
        
        return containerView
    }
}
