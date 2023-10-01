//
//  SettingsVC.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 22.09.2023.
//

import UIKit
import SwiftUI

struct SettingsOption {
    let title: String
    let icon: UIImage?
    let iconBackgroundColor: UIColor
    let handler: (() -> Void)
}

class SettingsVC: UIViewController {
    let userLabel = UILabel()
    private let viewModel = SettingsViewModel()
    var models: [SettingsOption] = []
    let container = UIView()
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.register(SettingsTableViewCell.self, forCellReuseIdentifier: SettingsTableViewCell.identifier)
        return table
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
        view.backgroundColor = .systemBackground
        title = "Settings"
        viewModel.delegate = self
        userLabel.text = viewModel.getUserId()
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
        setupUserLabel()
        
    }
    
    func setupUserLabel() {
        let icon = UIImageView()
        icon.image = UIImage(systemName: "doc.on.doc")
        icon.image?.withTintColor(.white)
        container.backgroundColor = .systemBackground.withAlphaComponent(2)
        container.layer.cornerRadius = 12
        view.addSubview(container)

        container.addSubview(userLabel)
        container.addSubview(icon)
        userLabel.font = .preferredFont(forTextStyle: .footnote)
        
        userLabel.translatesAutoresizingMaskIntoConstraints = false
        container.translatesAutoresizingMaskIntoConstraints = false
        icon.translatesAutoresizingMaskIntoConstraints = false
        
        userLabel.textColor = .black
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(labelDidGetTapped))

        userLabel.isUserInteractionEnabled = true
        userLabel.addGestureRecognizer(tapGesture)
        
        NSLayoutConstraint.activate([
            container.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,constant: -30),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.widthAnchor.constraint(equalToConstant: view.bounds.width),
            container.heightAnchor.constraint(equalToConstant: 30),
            
            icon.trailingAnchor.constraint(equalTo: container.trailingAnchor,constant: -20),
            icon.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            
            userLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            userLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor,constant: 20)
        ])
        let userId = UIDevice.current.identifierForVendor?.uuidString
        let string = "User ID: \(userId ?? "")"
        userLabel.text = string
    }
    
    @objc func labelDidGetTapped(sender: UITapGestureRecognizer) {
        guard let label = sender.view as? UILabel else {
            return
        }
        UIPasteboard.general.string = label.text
    }
}

extension SettingsVC: SettingsViewModelDelegate {
    func didFail(error: Error) {
        print(error)
    }
    
    func didFinish() {
        //userLabel.text = viewModel.getUserId()
    }
}

extension SettingsVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingsTableViewCell.identifier, for: indexPath) as! SettingsTableViewCell
        let model = models[indexPath.row]
        cell.configure(with: model)
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let function = models[indexPath.row].handler
        function()
    }
    
    func configure() {
        models.append(SettingsOption(title: "Premium", icon: UIImage(systemName: "medal"), iconBackgroundColor:  Colors.accent.color, handler: {
            let vc = PremiumVC()
            self.present(vc, animated: true)
        }))
//        models.append(SettingsOption(title: "Uygulamayı Oyla", icon: UIImage(systemName: "apple.logo"), iconBackgroundColor: .red, handler: {
//            self.rateApp()
//        }))
//        models.append(SettingsOption(title: "Paylaş", icon: UIImage(systemName: "square.and.arrow.up"), iconBackgroundColor: .red,handler: {
//            
//        }))
        
        models.append(SettingsOption(title: "Dil", icon: UIImage(systemName: "network"), iconBackgroundColor: Colors.accent.color, handler: {
            
        }))
        models.append(SettingsOption(title: "Kullanıcı ID", icon: UIImage(systemName: "person"), iconBackgroundColor:  Colors.accent.color,handler: {
            let vc = ShowUserID()
            self.navigationController?.pushViewController(vc, animated: true)
        }))
    }
    @objc func rateApp() {
        if let appStoreURL = URL(string: "https://apps.apple.com/tr/app/eventier/id6462756481?l=tr") {
            UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
        }
    }
}
