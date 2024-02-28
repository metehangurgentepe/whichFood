//
//  SettingsVC.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 22.09.2023.
//

import UIKit
import SwiftUI
import MessageUI

struct SettingsOption {
    let title: String
    let icon: UIImage?
    let iconBackgroundColor: UIColor
    let handler: (() -> Void)
}

class SettingsVC: UIViewController, MFMailComposeViewControllerDelegate {
    private lazy var icon : UIImageView = {
        let icon = UIImageView()
        icon.image = SFSymbols.copy
        icon.image?.withTintColor(.white)
        return icon
    }()
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.register(SettingsTableViewCell.self, forCellReuseIdentifier: SettingsTableViewCell.identifier)
        return table
    }()
    private lazy var viewModel = SettingsViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
        viewModel.delegate = self
        viewModel.appendRowTableview()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func configure() {
        view.backgroundColor = .systemBackground
        title = LocaleKeys.Settings.title.rawValue.locale()
        setupTableView()
    }
}

extension SettingsVC: SettingsViewModelDelegate {
    func handleViewModelOutput(_ output: SettingsViewModelOutput) {
        switch output {
        case .makeAlertDarkMode:
            makeAlert()
        case .navigate(vc: let vc):
            self.navigationController?.pushViewController(vc, animated: true)
        case .present(vc: let vc):
            self.present(vc, animated: true)
        case.sendMail:
            viewModel.sendMail()
        case .showError(_):
            let alert = showAlert(title: "error", message: "error", buttonTitle: "OK", secondButtonTitle: nil)
            self.present(alert, animated: true)
        case .popVC:
            self.navigationController?.popViewController(animated: true)
        }
    }
}

extension SettingsVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.models.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingsTableViewCell.identifier, for: indexPath) as! SettingsTableViewCell
        let model = viewModel.models[indexPath.row]
        cell.configure(with: model)
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let function = viewModel.models[indexPath.row].handler
        function()
    }
    
    
}
// MARK: DESIGN SETTINGS VİEW CONTROLLER
extension SettingsVC {
    @objc func rateApp() {
        if let appStoreURL = URL(string: Constants.Links.appStoreLink.rawValue) {
            UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
        }
    }
    func makeAlert() {
        let alert = UIAlertController(title: LocaleKeys.Settings.selectTheme.rawValue.locale(), message: "", preferredStyle: .alert)
        
        let darkMode = UIAlertAction(title: LocaleKeys.Settings.darkModeButton.rawValue.locale(), style: .default) { (action) in
            UIApplication.shared.windows.forEach { window in
                window.overrideUserInterfaceStyle = .dark
            }
            UserDefaults.standard.set("dark", forKey: "themeMode")
        }
        
        let lightMode = UIAlertAction(title: LocaleKeys.Settings.lightModeButton.rawValue.locale(), style: .default) { (action) in
            UIApplication.shared.windows.forEach { window in
                window.overrideUserInterfaceStyle = .light
            }
            UserDefaults.standard.set("light", forKey: "themeMode")
        }
        
        // Add the action to the alert controller
        alert.addAction(darkMode)
        alert.addAction(lightMode)
        self.present(alert, animated: true, completion: nil)
    }
    func setupTableView() {
        view.addSubview(tableView)
        
        tableView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
    }
}
