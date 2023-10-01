//
//  PremiumTableViewCell.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 28.09.2023.
//

import UIKit

class PremiumTableViewCell: UITableViewCell {
    static let identifier = "PremiumTableViewCell"
    private let iconImageView: UIImageView = {
       let view = UIImageView()
        view.tintColor = .white
        view.contentMode = .scaleAspectFit
        return view
    }()
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = Colors.opacWhite.color
        label.font = .preferredFont(forTextStyle: .headline)
        label.numberOfLines = 1
        return label
    }()
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = Colors.opacWhite.color
        label.font = .preferredFont(forTextStyle: .footnote)
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
        contentView.addSubview(titleLabel)
        contentView.addSubview(iconImageView)
        contentView.clipsToBounds = true
        accessoryType = .disclosureIndicator
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let size: CGFloat = contentView.frame.size.height
        iconImageView.frame = CGRect(x: 10, y: contentView.bounds.height * 0.25, width: size/2, height: size/2)
        iconImageView.tintColor = .black
        contentView.backgroundColor = Colors.accent.color.withAlphaComponent(0.4)
        let stack = UIStackView()
        stack.axis = .vertical
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(subtitleLabel)
        contentView.addSubview(stack)
        
        stack.frame = CGRect(
            x: contentView.bounds.width * 0.2,
            y: contentView.bounds.height * 0.20,
            width: contentView.frame.size.width,
            height: contentView.frame.size.height / 2)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.image = nil
        titleLabel.text = nil
        subtitleLabel.text = nil
    }
    
    public func configure(with model: Property) {
        titleLabel.text = model.title
        subtitleLabel.text = model.subtitle
        iconImageView.image = model.icon
    }
    
}
