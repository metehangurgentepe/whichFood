//
//  MenuCell.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 18.09.2024.
//

import UIKit
import SnapKit

class MenuCell: UICollectionViewCell {
    static let identifier: String = "MenuCell"
    
    let label: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline).withSize(14)
        label.textColor = .gray
        label.textAlignment = .center
        label.text = "Menu Item"
        label.textColor = .white
        return label
    }()
    
    override var isSelected: Bool {
        didSet {
            label.textColor = isSelected ? .systemPink : .white
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(label)
        
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
