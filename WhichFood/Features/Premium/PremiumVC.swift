//
//  PremiumVC.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 27.09.2023.
//

import UIKit

struct Property{
    let icon: UIImage
    let title: String
    let subtitle: String
}

class PremiumVC: UIViewController {
    let label : UILabel = {
        let label = UILabel()
        label.text = "Hello world"
        label.textColor = .red
        return label
    }()
    var properties: [Property] = []
    var isSelected: Bool = false
    
    let weekButton: UIButton = {
        let button = UIButton()
        let title = NSLocalizedString(LocaleKeys.Premium.weekButton.rawValue, comment: "")
        button.setTitle(title, for: .normal)
        button.backgroundColor = button.isSelected ? Colors.accent.color : Colors.accent.color.withAlphaComponent(0.5)
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        return button
    }()
    
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.register(PremiumTableViewCell.self, forCellReuseIdentifier: PremiumTableViewCell.identifier)
        return table
    }()
    
    let checkIcon : UIImageView = {
        let imageview = UIImageView()
        imageview.image = UIImage(named: "check")
        imageview.contentMode = .scaleAspectFit
        return imageview
    }()
    
    let weekPriceLabel : UILabel = {
        let label = UILabel()
        label.text = "₺14.99"
        label.textColor = .white
        label.textAlignment = .right
        label.font = .preferredFont(forTextStyle: .callout) // İstenilen yazı tipi ve boyutunu ayarlayın
        return label
    }()
    
    let lifetimePriceLabel : UILabel = {
        let label = UILabel()
        label.text = "₺199.99"
        label.textColor = .white
        label.textAlignment = .right
        label.font = .preferredFont(forTextStyle: .callout) // İstenilen yazı tipi ve boyutunu ayarlayın
        return label
    }()
    
    let continueButton: UIButton = {
        let button = UIButton()
        let title = NSLocalizedString(LocaleKeys.Premium.continueButton.rawValue, comment: "")
        button.setTitle(title, for: .normal)
        button.backgroundColor = Colors.secondAccent.color
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        return button
    }()
    
    let lifetimeButton: UIButton = {
        let button = UIButton()
        let title = NSLocalizedString(LocaleKeys.Premium.lifetimeButton.rawValue, comment: "")
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.backgroundColor = button.isSelected ? Colors.accent.color : Colors.accent.color.withAlphaComponent(0.5)
        button.layer.cornerRadius = 12
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Premium"
        tableView.delegate = self
        tableView.dataSource = self
        setupButtons()
        setupContinueButton()
        setupWeekPriceLabel()
        setupLifetimeIcon()
        setupLifetimePriceLabel()
        setupTable()
        configure()
        tableView.separatorStyle = .none
       
        
    }
    func setupContinueButton() {
        view.addSubview(continueButton)
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            continueButton.bottomAnchor.constraint(equalTo: view.bottomAnchor,constant: -view.bounds.height * 0.05),
            continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            continueButton.heightAnchor.constraint(equalToConstant: view.bounds.height * 0.06),
            continueButton.widthAnchor.constraint(equalToConstant: view.bounds.width * 0.85),
        ])
    }
    
    func setupTable() {
        tableView.rowHeight = view.bounds.height * 0.10
        tableView.allowsSelection = false
        view.addSubview(tableView)
        tableView.layer.cornerRadius = 12
        tableView.backgroundColor = Colors.accent.color.withAlphaComponent(0.2)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.tableHeaderView = UIView(frame: CGRect(x: 15, y: 0, width: tableView.frame.width, height: 0.01))
        tableView.bounces = false
        tableView.contentSize = CGSize(width: tableView.frame.size.width, height: view.bounds.height * 0.3)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,constant: view.bounds.height * 0.1),
            tableView.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            tableView.heightAnchor.constraint(equalToConstant: view.bounds.height * 0.3),
            tableView.widthAnchor.constraint(equalToConstant: view.bounds.width * 0.85)
        ])
    }
    
    func setupButtons() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        
        stack.addArrangedSubview(weekButton)
        stack.addArrangedSubview(lifetimeButton)
        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor,constant: -view.bounds.height * 0.3),
            weekButton.heightAnchor.constraint(equalToConstant: view.bounds.height * 0.07),
            weekButton.widthAnchor.constraint(equalToConstant: view.bounds.width * 0.85),
            lifetimeButton.heightAnchor.constraint(equalToConstant: view.bounds.height * 0.07),
            lifetimeButton.widthAnchor.constraint(equalToConstant: view.bounds.width * 0.85)
        ])
        
        weekButton.addTarget(self, action: #selector(tapWeekButton), for: .touchUpInside)
        lifetimeButton.addTarget(self, action: #selector(tapLifetimeButton), for: .touchUpInside)
    }
    
    func setupIcon(button: UIButton,hidden:Bool) {
        checkIcon.isHidden = hidden
        button.addSubview(checkIcon) // Her iki düğmenin üst düzey view'ına ekliyoruz
      //  lifetimeButton.addSubview(checkIcon)
        checkIcon.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            checkIcon.leadingAnchor.constraint(equalTo: button.leadingAnchor,constant: 5),
            checkIcon.centerYAnchor.constraint(equalTo: button.centerYAnchor),
        ])
    }
    
    func setupLifetimeIcon() {
        checkIcon.isHidden = true
        lifetimeButton.addSubview(checkIcon)
        checkIcon.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            checkIcon.leadingAnchor.constraint(equalTo: lifetimeButton.leadingAnchor,constant: 5),
            checkIcon.centerYAnchor.constraint(equalTo: lifetimeButton.centerYAnchor),
        ])
    }
    
    func setupWeekPriceLabel() {
        weekButton.addSubview(weekPriceLabel)
        weekPriceLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            weekPriceLabel.bottomAnchor.constraint(equalTo: weekPriceLabel.superview!.bottomAnchor, constant: -8), // Sağ alt köşeye yerleştirme
            weekPriceLabel.trailingAnchor.constraint(equalTo: weekPriceLabel.superview!.trailingAnchor, constant: -8)
        ])
    }
    
    func setupLifetimePriceLabel() {
        lifetimeButton.addSubview(lifetimePriceLabel)
        lifetimePriceLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            lifetimePriceLabel.bottomAnchor.constraint(equalTo: lifetimePriceLabel.superview!.bottomAnchor, constant: -8), // Sağ alt köşeye yerleştirme
            lifetimePriceLabel.trailingAnchor.constraint(equalTo: lifetimePriceLabel.superview!.trailingAnchor, constant: -8)
        ])
    }
    
    @objc func tapWeekButton() {
        weekButton.isSelected = true
        lifetimeButton.isSelected = false
        switch weekButton.isSelected {
        case true:
            weekButton.backgroundColor = Colors.accent.color
            lifetimeButton.backgroundColor = Colors.accent.color.withAlphaComponent(0.5)
            setupIcon(button: weekButton, hidden: false)
        case false:
            weekButton.backgroundColor = Colors.accent.color.withAlphaComponent(0.5)
            lifetimeButton.backgroundColor = Colors.accent.color
            setupIcon(button: weekButton, hidden: true)
        }
    }
    
    @objc func tapLifetimeButton() {
        lifetimeButton.isSelected = true
        weekButton.isSelected = false
        switch lifetimeButton.isSelected {
        case true:
            lifetimeButton.backgroundColor = Colors.accent.color
            weekButton.backgroundColor = Colors.accent.color.withAlphaComponent(0.5)
            setupIcon(button: lifetimeButton, hidden: false)
        case false:
            weekButton.backgroundColor = Colors.accent.color
            lifetimeButton.backgroundColor = Colors.accent.color.withAlphaComponent(0.5)
            setupIcon(button: lifetimeButton, hidden: true)
        }
    }
}

extension PremiumVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return properties.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PremiumTableViewCell.identifier, for: indexPath) as! PremiumTableViewCell
        let model = properties[indexPath.row]
        cell.configure(with: model)
        cell.accessoryType = .none
        return cell
    }
    
    func configure() {
        properties.append(Property(icon: UIImage(named: "infinity")!, title: "Sınırsız Tarif Ekle", subtitle: "Ekleme sınırı olmadan tariflerini ekle ve takip et"))
        properties.append(Property(icon: UIImage(named: "fork")!, title: "Ne yemek yapacağım diye düşünme", subtitle: "Yemeklerle kafanı doldurma"))
        properties.append(Property(icon: UIImage(systemName: "arrowshape.left.arrowshape.right")!, title: "Ne desem", subtitle: "yaptık oldu bak bakalım"))
    }
}

