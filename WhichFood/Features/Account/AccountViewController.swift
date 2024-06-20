//
//  AccountViewController.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 10.11.2023.
//

import UIKit

protocol AccountViewModelDelegate: AnyObject {
    func handleViewModelOutput(_ output: AccountViewModelOutput)
}

class AccountViewController: DataLoadingVC {
    
    private lazy var tableView : UITableView = {
        let table = UITableView()
        table.register(AccountTableViewCell.self, forCellReuseIdentifier: AccountTableViewCell.identifier)
        table.rowHeight = 70
        return table
    }()
    
    var viewModel: AccountViewModelProtocol = AccountViewModel()
    var user: User?
    var models: [AccountInfo] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.delegate = self
        viewModel.getUser{
            self.viewModel.createTableView()
        }
        configure()
    }
    
    
    func configure(){
        view.backgroundColor = .systemBackground
        title = LocaleKeys.AccountScreen.title.rawValue.locale()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 50
        setupTable()
    }
    
    
    private func setupTable() {
        view.addSubview(tableView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            
            tableView.heightAnchor.constraint(equalToConstant: view.bounds.height),
            tableView.widthAnchor.constraint(equalToConstant: view.bounds.width)
        ])
    }
    
    
    @objc func copyText() {
        if var user = user {
            user.id = UIPasteboard.general.string ?? "nil"
        }
    }
    
    
    func makeContextMenu(for indexPath: IndexPath) -> UIMenu {
        let copyAction = UIAction(title: "Copy", image: SFSymbols.copy) { _ in
            self.copyText()
        }
        
        let contextMenu = UIMenu(title: "", children: [copyAction])
        return contextMenu
    }
}

extension AccountViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AccountTableViewCell.identifier, for: indexPath) as! AccountTableViewCell
        let model = self.models[indexPath.row]
        cell.configure(with: model)
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let function = models[indexPath.row].handler
        function()
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard indexPath.row == 0 else {
            return nil
        }
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { suggestedActions in
            return self.makeContextMenu(for: indexPath)
        })
    }
}

extension AccountViewController: AccountViewModelDelegate {
    func handleViewModelOutput(_ output: AccountViewModelOutput) {
        switch output {
        case .getUser(let user):
            self.user = user
            
        case .showError(let error):
            let alert = showAlert(title: LocaleKeys.Error.alert.rawValue.locale(), message: error.localizedDescription, buttonTitle: LocaleKeys.Error.okButton.rawValue.locale(), secondButtonTitle: LocaleKeys.Error.backButton.rawValue.locale(), completionSecondHandler:  {
                self.dismiss(animated: true)
            })
            self.present(alert, animated: true)
            
        case .setLoading(let isLoading):
            break
//            if isLoading {
//                showLoadingView()
//            } else {
//                dismissLoadingView()
//            }
            
        case .getTableViews(let models):
            self.models = models
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            
        case .tappedRow(let index):
            guard let user = user else {
                return
            }
            let textToCopy = user.id
            UIPasteboard.general.string = textToCopy
            let menuController = UIMenuController.shared
            let copyMenuItem = UIMenuItem(title: LocaleKeys.AccountScreen.copy.rawValue.locale(), action: #selector(copyText))
            menuController.menuItems = [copyMenuItem]
            if let selectedCell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) {
                menuController.showMenu(from: selectedCell, rect: selectedCell.bounds)
            }
            
        case .navigate(vc: let vc):
            self.present(vc, animated: true)
        }
    }
}
