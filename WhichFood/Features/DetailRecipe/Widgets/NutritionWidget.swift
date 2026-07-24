//
//  NutritionWidget.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 1.03.2025.
//

import Foundation
import UIKit


class NutritionWidget: UIView {
    private let titleLabel = UILabel()
    private let horizontalStackView = UIStackView()
    
    private let caloriesTile = NutritionTile(emoji: "🔥", title: "Calories".locale(), backgroundColor: UIColor.systemOrange.withAlphaComponent(0.1))
    private let carbsTile = NutritionTile(emoji: "🍞", title: "Carbs".locale(), backgroundColor: UIColor.systemYellow.withAlphaComponent(0.1))
    private let proteinTile = NutritionTile(emoji: "🍗", title: "Protein".locale(), backgroundColor: UIColor.systemBrown.withAlphaComponent(0.1))
    private let fatTile = NutritionTile(emoji: "🥑", title: "Fat".locale(), backgroundColor: UIColor.systemGreen.withAlphaComponent(0.1))
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = .systemBackground
        layer.cornerRadius = 12
        
        setupTitleLabel()
        setupHorizontalLayout()
    }
    
    private func setupTitleLabel() {
        titleLabel.text = "Nutrition".locale()
        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
    }
    
    private func setupHorizontalLayout() {
        // Tüm nutrition tile'ları yan yana olacak şekilde ayarlayalım
        horizontalStackView.axis = .horizontal
        horizontalStackView.distribution = .fillEqually
        horizontalStackView.spacing = 12
        
        // Tüm tile'ları tek bir yatay sıraya ekleyelim
        horizontalStackView.addArrangedSubview(caloriesTile)
        horizontalStackView.addArrangedSubview(carbsTile)
        horizontalStackView.addArrangedSubview(proteinTile)
        horizontalStackView.addArrangedSubview(fatTile)
        
        addSubview(horizontalStackView)
        horizontalStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            horizontalStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            horizontalStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            horizontalStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            horizontalStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
        ])
    }
    
    func configure(with calorieInfo: CalorieInfo) {
        let calories = Int(calorieInfo.totalCalories ?? "0") ?? 0
        
        // Değerleri daha güvenli bir şekilde parse edelim
        let carbsString = calorieInfo.carbs.replacingOccurrences(of: "g", with: "").trimmingCharacters(in: .whitespaces)
        let fatString = calorieInfo.fat.replacingOccurrences(of: "g", with: "").trimmingCharacters(in: .whitespaces)
        let proteinString = calorieInfo.protein.replacingOccurrences(of: "g", with: "").trimmingCharacters(in: .whitespaces)
        
        let carbsValue = Double(carbsString) ?? 0
        let fatValue = Double(fatString) ?? 0
        let proteinValue = Double(proteinString) ?? 0
        
        caloriesTile.configure(value: "\(calories)", unit: "")
        carbsTile.configure(value: "\(Int(carbsValue))", unit: "g")
        proteinTile.configure(value: "\(Int(proteinValue))", unit: "g")
        fatTile.configure(value: "\(Int(fatValue))", unit: "g")
        
        // Layoutu güncelleyelim
        setNeedsLayout()
        layoutIfNeeded()
    }
}

// İkon yerine emoji kullanan NutritionTile sınıfı
class NutritionTile: UIView {
    private let emojiLabel = UILabel()
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    
    init(emoji: String, title: String, backgroundColor: UIColor) {
        super.init(frame: .zero)
        
        // Configure emoji
        emojiLabel.text = emoji
        emojiLabel.font = .systemFont(ofSize: 30)
        emojiLabel.textAlignment = .center
        
        // Configure title
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 10)
        titleLabel.textColor = .secondaryLabel
        titleLabel.textAlignment = .center
        
        // Configure value label
        valueLabel.font = .boldSystemFont(ofSize: 28)
        valueLabel.textAlignment = .center
        
        setupView(backgroundColor: backgroundColor)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView(backgroundColor: UIColor) {
        self.backgroundColor = backgroundColor
        layer.cornerRadius = 16
        
        let textStack = UIStackView(arrangedSubviews: [emojiLabel, titleLabel, valueLabel])
        textStack.axis = .vertical
        textStack.alignment = .center
        textStack.spacing = 8
        textStack.setCustomSpacing(2, after: emojiLabel)
        
        addSubview(textStack)
        textStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            textStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            textStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            textStack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 8),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8),
            textStack.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 12),
            textStack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -12)
        ])
    }
    
    func configure(value: String, unit: String) {
        valueLabel.text = value + (unit.isEmpty ? "" : " " + unit)
    }
}
