//
//  CategoryButtonCell.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 27.02.2024.
//

import UIKit

class CapsuleLabel: UILabel {
    override func layoutSubviews() {
        super.layoutSubviews()
        let cornerRadius: CGFloat = bounds.height / 2
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = true
    }
}

class CategoryButtonCell: UICollectionViewCell {
    private let label = CapsuleLabel()
    
    static let identifier = "CategoryButtonCell"
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
    
    
    func setupUI() {
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    
    
    func configure(title: String) {
        self.title = title
        label.font = .preferredFont(forTextStyle: .caption2).withSize(12)
        label.text = title
        label.textColor = .label
        label.backgroundColor = isSelected ? Colors.primary.color : UIColor.secondarySystemBackground
        label.textAlignment = .center
    }
}
