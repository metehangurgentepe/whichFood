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
    
    var titleLabel = UILabel()
    var contentLabel = UILabel()
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(labelTapped))
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(titleLabel)
        contentView.addSubview(contentLabel)
        contentView.clipsToBounds = true
        accessoryType = .disclosureIndicator
        setupTitleLabel()
        setupContentView()
        updateTitleLabelColor()
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
    
    func setupTitleLabel() {
        titleLabel.textColor = .white
        titleLabel.font = .preferredFont(forTextStyle: .headline)
    }
    
    func setupContentView() {
        contentLabel.textColor = .gray.withAlphaComponent(0.5)
        contentLabel.font = .preferredFont(forTextStyle: .subheadline)
        contentLabel.isUserInteractionEnabled = true
        
        contentLabel.addGestureRecognizer(tapGesture)
    }
    
    @objc func labelTapped() {
        // Metin etiketi tıklandığında çağrılan işlev
        becomeFirstResponder()
        
        // UIMenuController'ı oluşturun
        let menuController = UIMenuController.shared
        
        // Kopyala seçeneğini ekleyin
        let copyMenuItem = UIMenuItem(title: "Kopyala", action: #selector(copyText))
        menuController.menuItems = [copyMenuItem]
        
        // Menüyü gösterin
        menuController.showMenu(from: contentView, rect: contentLabel.frame)
    }
    
    @objc func copyText() {
        // Kopyalanacak metni belirleyin
        guard let textToCopy = contentLabel.text else {
            return
        }
        
        // UIPasteboard kullanarak metni kopyalayın
        UIPasteboard.general.string = textToCopy
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
    func updateTitleLabelColor() {
        if self.traitCollection.userInterfaceStyle == .light {
            // Light tema için renk
            titleLabel.textColor = .black
        } else {
            // Dark tema için renk
            titleLabel.textColor = .white
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // Tema değişikliğini kontrol et
        if #available(iOS 13.0, *), traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateTitleLabelColor()
        }
    }
    
}
