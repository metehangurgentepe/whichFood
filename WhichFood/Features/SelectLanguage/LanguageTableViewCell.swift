//
//  LanguageTableViewCell.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 7.11.2023.
//

import UIKit

class LanguageTableViewCell: UITableViewCell {
    static let identifier = "LanguageCell"
    let languageNameLabel : UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.numberOfLines = 1
        return label
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        

    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(languageNameLabel)
        contentView.clipsToBounds = true
        accessoryType = .disclosureIndicator
        updateColors()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        languageNameLabel.frame = CGRect(
            x: 25,
            y: 0,
            width: contentView.frame.size.width - 20,
            height: contentView.frame.size.height)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        languageNameLabel.text = nil
    }
    
    public func configure(with model: LanguageModel) {
        languageNameLabel.text = model.title
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        updateColors()
    }
    
    func updateColors() {
        if traitCollection.userInterfaceStyle == .dark {
            languageNameLabel.textColor = .white
        } else {
            languageNameLabel.textColor = Colors.text.color
        }
    }
}
