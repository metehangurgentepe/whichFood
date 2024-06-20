//
//  AccountTableViewCell.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 10.11.2023.
//

import UIKit

struct AccountInfo {
    let title: String
    let content: String
    let handler: (() -> Void)
}

class AccountTableViewCell: UITableViewCell {
    static let identifier = "AccountTable"
    
    var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = .preferredFont(forTextStyle: .headline)
        return label
    }()
    
    var contentLabel: UILabel = {
        let label = UILabel()
        label.textColor = .gray.withAlphaComponent(0.8)
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.isUserInteractionEnabled = true
        return label
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(titleLabel)
        contentView.addSubview(contentLabel)
        contentView.clipsToBounds = true
        accessoryType = .disclosureIndicator
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(contentLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,constant: 16),
            titleLabel.topAnchor.constraint(equalTo:contentView.topAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 30),
            titleLabel.widthAnchor.constraint(equalToConstant: contentView.frame.width)
        ])
        
        NSLayoutConstraint.activate([
            contentLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,constant: 16),
            contentLabel.bottomAnchor.constraint(equalTo:contentView.bottomAnchor),
            contentLabel.heightAnchor.constraint(equalToConstant: 20),
            contentLabel.widthAnchor.constraint(equalToConstant: contentView.frame.width)
        ])
    }
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        contentLabel.text = nil
    }
    
    
    public func configure(with model: AccountInfo) {
        titleLabel.text = model.title
        contentLabel.text = model.content
    }
    
}
