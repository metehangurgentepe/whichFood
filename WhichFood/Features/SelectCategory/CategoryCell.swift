//
//  CategoryCell.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 13.03.2024.
//

import UIKit

class CategoryCell: UICollectionViewCell {
    let label = CapsuleLabel()
    
    static let identifier = "CategoryCell"
    var title: String?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override var isSelected: Bool {
        didSet {
            configure(title: title!)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateCapsuleShape()
    }
    
    
    func setupUI() {
        label.translatesAutoresizingMaskIntoConstraints = false

        // iOS 26 Glass Effect Implementation
        if #available(iOS 26.0, *) {
            setupGlassEffect()
        } else {
            // Fallback on earlier versions - use existing design
            setupFallbackDesign()
            addSubview(label)

            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: topAnchor),
                label.leadingAnchor.constraint(equalTo: leadingAnchor),
                label.trailingAnchor.constraint(equalTo: trailingAnchor),
                label.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        }
    }

    @available(iOS 26.0, *)
    private func setupGlassEffect() {
        // Create glass effect view
        let effectView = UIVisualEffectView()
        effectView.layer.cornerRadius = 20
        effectView.clipsToBounds = true
        effectView.translatesAutoresizingMaskIntoConstraints = false
        effectView.overrideUserInterfaceStyle = .dark

        // Add the effect view to cell
        addSubview(effectView)

        // Set up constraints for effect view
        NSLayoutConstraint.activate([
            effectView.topAnchor.constraint(equalTo: topAnchor),
            effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            effectView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        // Add label to glass effect content view
        label.backgroundColor = .clear
        label.textColor = .secondaryLabel
        effectView.contentView.addSubview(label)

        // Set up constraints for label inside content view
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: effectView.contentView.topAnchor),
            label.leadingAnchor.constraint(equalTo: effectView.contentView.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: effectView.contentView.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: effectView.contentView.bottomAnchor),
        ])
    }

    private func setupFallbackDesign() {
        // Use the existing modern design for iOS < 26
        label.layer.cornerRadius = 20
        label.clipsToBounds = true
    }
    
    
    func configure(title: String) {
        self.title = title
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.text = title
        label.textAlignment = .center

        if #available(iOS 26.0, *) {
            configureWithGlassEffect()
        } else {
            configureWithFallbackDesign()
        }
    }

    @available(iOS 26.0, *)
    private func configureWithGlassEffect() {
        guard let glassEffectView = subviews.first(where: { $0 is UIVisualEffectView }) as? UIVisualEffectView else {
            print("⚠️ Glass effect view not found!")
            return
        }

        if isSelected {
            // Selected state with glass effect
            label.textColor = .white

            // Create stronger glass effect for selected state
            let selectedGlassEffect = UIGlassEffect()
            selectedGlassEffect.tintColor = Colors.primary.color

            // Animate the glass effect change
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut) {
                glassEffectView.effect = selectedGlassEffect
            }

            // Add enhanced shadow for glass effect
            layer.shadowColor = Colors.primary.color.cgColor
            layer.shadowOffset = CGSize(width: 0, height: 4)
            layer.shadowRadius = 12
            layer.shadowOpacity = 0.4

            // Scale animation
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1) {
                self.transform = CGAffineTransform(scaleX: 1.0, y: 1.00)
            }
        } else {
            // Unselected state with subtle glass effect
            label.textColor = .label

            // Reset to subtle glass effect
            let unselectedGlassEffect = UIGlassEffect()
            unselectedGlassEffect.tintColor = .systemGray3

            // Animate the glass effect change
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut) {
                glassEffectView.effect = unselectedGlassEffect
            }

            // Remove shadow
            layer.shadowOpacity = 0

            // Reset scale
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1) {
                self.transform = CGAffineTransform.identity
            }
        }
    }

    private func configureWithFallbackDesign() {
        if isSelected {
            // Selected state - gradient background with white text
            label.textColor = .white
            label.backgroundColor = Colors.primary.color

            // Add subtle shadow
            layer.shadowColor = Colors.primary.color.cgColor
            layer.shadowOffset = CGSize(width: 0, height: 2)
            layer.shadowRadius = 8
            layer.shadowOpacity = 0.3

            // Scale animation
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1) {
                self.transform = CGAffineTransform(scaleX: 1.00, y: 1.00)
            }
        } else {
            // Unselected state - white text on gray background
            label.textColor = .white
            label.backgroundColor = UIColor.systemGray4

            // Remove shadow
            layer.shadowOpacity = 0

            // Reset scale
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1) {
                self.transform = CGAffineTransform.identity
            }
        }

        // Ensure perfect capsule shape is set after layout
        updateCapsuleShape()
    }

    private func updateCapsuleShape() {
        guard label.frame.height > 0 else { return }

        label.layer.cornerRadius = label.frame.height / 2
        label.clipsToBounds = true

        // Also update glass effect view if available
        if #available(iOS 26.0, *),
           let glassEffectView = subviews.first(where: { $0 is UIVisualEffectView }) {
            glassEffectView.layer.cornerRadius = label.frame.height / 2
        }
    }
}
